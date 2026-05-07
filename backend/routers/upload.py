from fastapi import APIRouter, UploadFile, File, BackgroundTasks
from typing import List
import os, aiofiles, uuid
from datetime import datetime
from database import get_db
from routers.notifications import create_notification
from main import manager  # WebSocket manager

router = APIRouter()
UPLOAD_DIR = "uploads"

async def process_files(file_data_list: list):
    """Background task: saves files and pushes WS notification for bulk uploads"""
    conn = get_db()
    names = []
    for file_data in file_data_list:
        filename, original_name, size = file_data
        upload_date = datetime.now().isoformat()
        conn.execute(
            "INSERT INTO documents (filename, original_name, size, upload_date, status) VALUES (?,?,?,?,?)",
            (filename, original_name, size, upload_date, 'complete')
        )
        names.append(original_name)
    conn.commit()
    conn.close()

    # Create notification
    msg = f"{len(names)} files uploaded successfully"
    create_notification(msg, "success")

    # Push via WebSocket
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

    if len(files) > 3:
        # Bulk: process in background, return immediately
        background_tasks.add_task(process_files, file_data_list)
        return {"bulk": True, "count": len(files), "files": saved}
    else:
        # Small batch: process immediately
        await process_files(file_data_list)
        return {"bulk": False, "count": len(files), "files": saved}