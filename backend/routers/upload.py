from fastapi import APIRouter, UploadFile, File, BackgroundTasks, HTTPException
from typing import List
import os, aiofiles, uuid, asyncio
from datetime import datetime
from database import get_db
from routers.notifications import create_notification

router = APIRouter()
UPLOAD_DIR = "uploads"

async def process_files(file_data_list: list, manager):
    conn = get_db()
    names = []
    upload_ids = []

    for file_data in file_data_list:
        filename, original_name, size = file_data
        upload_date = datetime.now().isoformat()
        cursor = conn.execute(
            "INSERT INTO documents (filename, original_name, size, upload_date, status) VALUES (?,?,?,?,?)",
            (filename, original_name, size, upload_date, 'processing')
        )
        upload_ids.append(cursor.lastrowid)
        names.append(original_name)

    conn.commit()
    await asyncio.sleep(1)

    for uid in upload_ids:
        conn.execute("UPDATE documents SET status='complete' WHERE id=?", (uid,))
    conn.commit()
    conn.close()

    msg = f"{len(names)} files uploaded successfully"
    create_notification(msg, "success")
    await manager.broadcast({
        "type": "upload_complete",
        "message": msg,
        "timestamp": datetime.now().isoformat(),
        "count": len(names)
    })

@router.post("/upload")
async def upload_files(
    background_tasks: BackgroundTasks,
    files: List[UploadFile] = File(...)
):
    saved = []
    file_data_list = []

    for file in files:
        ext = os.path.splitext(file.filename)[1]
        unique_name = f"{uuid.uuid4()}{ext}"
        path = os.path.join(UPLOAD_DIR, unique_name)
        content = await file.read()
        async with aiofiles.open(path, 'wb') as f:
            await f.write(content)
        size = len(content)
        file_data_list.append((unique_name, file.filename, size))
        saved.append({"filename": file.filename, "status": "queued"})

    from main import manager

    if len(files) > 3:
        background_tasks.add_task(process_files, file_data_list, manager)
        return {"bulk": True, "count": len(files), "files": saved}
    else:
        await process_files(file_data_list, manager)
        upload_ids = []
        conn = get_db()
        for s in saved:
            doc = conn.execute(
                "SELECT id FROM documents WHERE original_name=? ORDER BY id DESC LIMIT 1",
                (s["filename"],)
            ).fetchone()
            if doc:
                upload_ids.append(doc["id"])
        conn.close()
        return {"bulk": False, "count": len(files), "files": saved, "upload_ids": upload_ids}

@router.get("/upload/{upload_id}/status")
def get_upload_status(upload_id: int):
    conn = get_db()
    doc = conn.execute(
        "SELECT id, original_name, status FROM documents WHERE id=?",
        (upload_id,)
    ).fetchone()
    conn.close()
    if not doc:
        raise HTTPException(status_code=404, detail="Upload not found")
    return {
        "id": doc["id"],
        "filename": doc["original_name"],
        "status": doc["status"]
    }