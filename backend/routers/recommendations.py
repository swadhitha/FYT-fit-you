"""
Recommendation API endpoints.
"""

import json
from fastapi import APIRouter, HTTPException
from database import get_connection
from models.schemas import (
    RecommendationRequest, RecommendationResponse,
    OutfitSuggestion, OutfitItem, SavedRecommendation,
)
from services.recommendation_engine import generate_recommendations

router = APIRouter(prefix="/api/recommendations", tags=["Recommendations"])


@router.post("/{user_id}", response_model=RecommendationResponse)
async def get_recommendations(user_id: int, req: RecommendationRequest):
    """Generate outfit recommendations for a user."""
    conn = get_connection()
    cursor = conn.cursor()

    # Verify user
    user = cursor.execute("SELECT * FROM users WHERE id = ?", (user_id,)).fetchone()
    if not user:
        conn.close()
        raise HTTPException(status_code=404, detail="User not found.")

    # Get body profile
    body = cursor.execute(
        "SELECT * FROM body_profile WHERE user_id = ?", (user_id,)
    ).fetchone()
    body_type = body["body_type"] if body else None

    # Get wardrobe
    wardrobe_rows = cursor.execute(
        "SELECT * FROM wardrobe_items WHERE user_id = ?", (user_id,)
    ).fetchall()
    wardrobe = [dict(r) for r in wardrobe_rows]

    if not wardrobe:
        conn.close()
        raise HTTPException(
            status_code=400,
            detail="No wardrobe items found. Please add items to your closet first."
        )

    # Get preferences
    pref_row = cursor.execute(
        "SELECT * FROM user_preferences WHERE user_id = ?", (user_id,)
    ).fetchone()

    preferences = None
    if pref_row:
        preferences = {
            "preferred_colors": json.loads(pref_row["preferred_colors"] or "[]"),
            "disliked_colors": json.loads(pref_row["disliked_colors"] or "[]"),
            "preferred_styles": json.loads(pref_row["preferred_styles"] or "[]"),
            "preferred_formality": pref_row["preferred_formality"],
            "comfort_priority": pref_row["comfort_priority"],
            "confidence_priority": pref_row["confidence_priority"],
        }

    # Generate recommendations
    climate = req.climate or user["climate_region"]
    recent_rows = cursor.execute(
        "SELECT outfit_items FROM recommendations WHERE user_id = ? ORDER BY created_at DESC LIMIT 30",
        (user_id,),
    ).fetchall()
    recent_signatures: set[str] = set()
    for row in recent_rows:
        try:
            items = json.loads(row["outfit_items"] or "[]")
            ids = sorted(str(i.get("id", "")) for i in items if isinstance(i, dict))
            if ids:
                recent_signatures.add("-".join(ids))
        except Exception:
            continue

    results = generate_recommendations(
        wardrobe=wardrobe,
        body_type=body_type,
        occasion=req.occasion,
        mood=req.mood,
        climate=climate,
        preferences=preferences,
        additional_notes=req.additional_notes,
        recent_signatures=recent_signatures,
        top_n=3,
    )

    # Save recommendations to database
    for result in results:
        cursor.execute("""
            INSERT INTO recommendations (user_id, occasion, mood, climate,
                                         outfit_items, scores, explanation)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        """, (
            user_id, req.occasion, req.mood, climate,
            json.dumps(result["items"]),
            json.dumps(result["scores"]),
            json.dumps(result["explanation"]),
        ))

    conn.commit()
    conn.close()

    # Format response
    outfits = []
    for r in results:
        outfits.append(OutfitSuggestion(
            rank=r["rank"],
            items=[OutfitItem(**item) for item in r["items"]],
            scores=r["scores"],
            explanation=r["explanation"],
        ))

    return RecommendationResponse(
        occasion=req.occasion,
        mood=req.mood,
        climate=climate,
        outfits=outfits,
        body_type=body_type,
    )


@router.get("/{user_id}/history", response_model=list[SavedRecommendation])
async def recommendation_history(user_id: int):
    """Get past recommendations for a user."""
    conn = get_connection()
    rows = conn.execute(
        "SELECT * FROM recommendations WHERE user_id = ? ORDER BY created_at DESC LIMIT 20",
        (user_id,)
    ).fetchall()
    conn.close()

    return [
        SavedRecommendation(
            id=r["id"],
            occasion=r["occasion"],
            outfit_items=json.loads(r["outfit_items"]),
            scores=json.loads(r["scores"]),
            explanation=(
                (
                    "\n".join(parsed)
                    if isinstance((parsed := json.loads(r["explanation"])), list)
                    else str(parsed)
                )
                if r["explanation"] else None
            ),
            saved=bool(r["saved"]),
            created_at=r["created_at"],
        )
        for r in rows
    ]


@router.put("/{rec_id}/save")
async def toggle_save(rec_id: int):
    """Toggle save/unsave a recommendation."""
    conn = get_connection()
    cursor = conn.cursor()

    rec = cursor.execute("SELECT * FROM recommendations WHERE id = ?", (rec_id,)).fetchone()
    if not rec:
        conn.close()
        raise HTTPException(status_code=404, detail="Recommendation not found.")

    new_saved = 0 if rec["saved"] else 1
    cursor.execute("UPDATE recommendations SET saved = ? WHERE id = ?", (new_saved, rec_id))
    conn.commit()
    conn.close()

    return {"message": "Saved" if new_saved else "Unsaved", "saved": bool(new_saved)}
