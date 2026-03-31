"""
Wardrobe management API endpoints.
"""

import json
import os
import uuid
from fastapi import APIRouter, HTTPException, File, UploadFile, Form
from typing import Optional
from database import get_connection
from models.schemas import WardrobeItemCreate, WardrobeItemResponse, WardrobeStats

router = APIRouter(prefix="/api/wardrobe", tags=["Wardrobe"])

UPLOAD_DIR = os.path.join(os.path.dirname(__file__), "..", "uploads")
os.makedirs(UPLOAD_DIR, exist_ok=True)


def _row_to_response(row) -> WardrobeItemResponse:
    return WardrobeItemResponse(
        id=row["id"], user_id=row["user_id"], name=row["name"],
        category=row["category"], color=row["color"], fabric=row["fabric"],
        formality=row["formality"], image_path=row["image_path"],
        usage_count=row["usage_count"], last_worn_at=row["last_worn_at"],
        created_at=row["created_at"],
    )


@router.post("/{user_id}", response_model=WardrobeItemResponse)
async def add_wardrobe_item(
    user_id: int,
    category: str = Form(...),
    color: str = Form(...),
    formality: str = Form(...),
    name: Optional[str] = Form(None),
    fabric: Optional[str] = Form(None),
    image: Optional[UploadFile] = File(None),
):
    """Add a wardrobe item with optional image upload."""
    conn = get_connection()
    cursor = conn.cursor()

    user = cursor.execute("SELECT id FROM users WHERE id = ?", (user_id,)).fetchone()
    if not user:
        conn.close()
        raise HTTPException(status_code=404, detail="User not found.")

    image_path = None
    if image and image.filename:
        ext = os.path.splitext(image.filename)[1] or ".jpg"
        filename = f"{uuid.uuid4().hex}{ext}"
        filepath = os.path.join(UPLOAD_DIR, filename)
        content = await image.read()
        with open(filepath, "wb") as f:
            f.write(content)
        image_path = f"/uploads/{filename}"

    cursor.execute("""
        INSERT INTO wardrobe_items (user_id, name, category, color, fabric, formality, image_path)
        VALUES (?, ?, ?, ?, ?, ?, ?)
    """, (user_id, name, category, color, fabric, formality, image_path))
    item_id = cursor.lastrowid
    conn.commit()

    row = cursor.execute("SELECT * FROM wardrobe_items WHERE id = ?", (item_id,)).fetchone()
    conn.close()
    return _row_to_response(row)


@router.get("/{user_id}", response_model=list[WardrobeItemResponse])
async def list_wardrobe(user_id: int):
    """List all wardrobe items for a user."""
    conn = get_connection()
    rows = conn.execute(
        "SELECT * FROM wardrobe_items WHERE user_id = ? ORDER BY created_at DESC",
        (user_id,)
    ).fetchall()
    conn.close()
    return [_row_to_response(r) for r in rows]


@router.get("/{user_id}/stats", response_model=WardrobeStats)
async def wardrobe_stats(user_id: int):
    """Get wardrobe usage statistics."""
    conn = get_connection()
    cursor = conn.cursor()

    all_items = cursor.execute(
        "SELECT * FROM wardrobe_items WHERE user_id = ? ORDER BY usage_count DESC",
        (user_id,)
    ).fetchall()

    if not all_items:
        conn.close()
        return WardrobeStats(
            total_items=0, most_used=[], least_used=[], category_breakdown={}
        )

    most_used = [_row_to_response(r) for r in all_items[:3]]
    least_used = [_row_to_response(r) for r in all_items[-3:]]

    # Category breakdown
    categories = {}
    for item in all_items:
        cat = item["category"]
        categories[cat] = categories.get(cat, 0) + 1

    conn.close()
    return WardrobeStats(
        total_items=len(all_items),
        most_used=most_used,
        least_used=least_used,
        category_breakdown=categories,
    )


@router.put("/item/{item_id}", response_model=WardrobeItemResponse)
async def update_item(item_id: int, item: WardrobeItemCreate):
    """Update wardrobe item details."""
    conn = get_connection()
    cursor = conn.cursor()

    existing = cursor.execute(
        "SELECT * FROM wardrobe_items WHERE id = ?", (item_id,)
    ).fetchone()
    if not existing:
        conn.close()
        raise HTTPException(status_code=404, detail="Item not found.")

    cursor.execute("""
        UPDATE wardrobe_items SET name=?, category=?, color=?, fabric=?, formality=?
        WHERE id=?
    """, (item.name, item.category, item.color, item.fabric, item.formality, item_id))
    conn.commit()

    row = cursor.execute("SELECT * FROM wardrobe_items WHERE id = ?", (item_id,)).fetchone()
    conn.close()
    return _row_to_response(row)


@router.delete("/item/{item_id}")
async def delete_item(item_id: int):
    """Delete a wardrobe item."""
    conn = get_connection()
    cursor = conn.cursor()

    existing = cursor.execute("SELECT * FROM wardrobe_items WHERE id = ?", (item_id,)).fetchone()
    if not existing:
        conn.close()
        raise HTTPException(status_code=404, detail="Item not found.")

    # Delete image file if exists
    if existing["image_path"]:
        filepath = os.path.join(os.path.dirname(__file__), "..", existing["image_path"].lstrip("/"))
        if os.path.exists(filepath):
            os.remove(filepath)

    cursor.execute("DELETE FROM wardrobe_items WHERE id = ?", (item_id,))
    conn.commit()
    conn.close()
    return {"message": "Item deleted successfully."}
