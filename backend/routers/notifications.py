from fastapi import APIRouter
from datetime import datetime
from database import get_db

router = APIRouter()

def create_notification(message: str, type: str):
    conn = get_db()
    conn.execute(
        "INSERT INTO notifications (message, type, timestamp, is_read) VALUES (?,?,?,0)",
        (message, type, datetime.now().isoformat())
    )
    conn.commit()
    conn.close()

@router.get("/notifications")
def get_notifications():
    conn = get_db()
    rows = conn.execute(
        "SELECT * FROM notifications ORDER BY timestamp DESC"
    ).fetchall()
    conn.close()
    return [dict(r) for r in rows]

@router.get("/notifications/unread-count")
def unread_count():
    conn = get_db()
    count = conn.execute(
        "SELECT COUNT(*) FROM notifications WHERE is_read=0"
    ).fetchone()[0]
    conn.close()
    return {"count": count}

@router.patch("/notifications/read-all")
def mark_all_read():
    conn = get_db()
    conn.execute("UPDATE notifications SET is_read=1")
    conn.commit()
    conn.close()
    return {"message": "All marked as read"}

@router.patch("/notifications/{notif_id}/read")
def mark_read(notif_id: int):
    conn = get_db()
    conn.execute(
        "UPDATE notifications SET is_read=1 WHERE id=?", (notif_id,)
    )
    conn.commit()
    conn.close()
    return {"message": "Marked as read"}