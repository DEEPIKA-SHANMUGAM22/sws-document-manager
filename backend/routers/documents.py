from fastapi import APIRouter, HTTPException
from fastapi.responses import FileResponse
import os
from database import get_db

router = APIRouter()
UPLOAD_DIR = "uploads"

@router.get("/documents")
def list_documents():
    conn = get_db()
    docs = conn.execute("SELECT * FROM documents ORDER BY upload_date DESC").fetchall()
    conn.close()
    return [dict(d) for d in docs]

@router.delete("/documents/{doc_id}")
def delete_document(doc_id: int):
    conn = get_db()
    doc = conn.execute("SELECT * FROM documents WHERE id=?", (doc_id,)).fetchone()
    if not doc:
        raise HTTPException(status_code=404, detail="Document not found")
    try:
        os.remove(os.path.join(UPLOAD_DIR, doc["filename"]))
    except FileNotFoundError:
        pass
    conn.execute("DELETE FROM documents WHERE id=?", (doc_id,))
    conn.commit()
    conn.close()
    return {"message": "Deleted"}

@router.get("/documents/{doc_id}/download")
def download_document(doc_id: int):
    conn = get_db()
    doc = conn.execute("SELECT * FROM documents WHERE id=?", (doc_id,)).fetchone()
    conn.close()
    if not doc:
        raise HTTPException(status_code=404, detail="Not found")
    path = os.path.join(UPLOAD_DIR, doc["filename"])
    return FileResponse(path, filename=doc["original_name"])