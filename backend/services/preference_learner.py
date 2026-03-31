"""
preference_learner.py
=====================
Extracts and updates user preferences from chat messages.
"""

from __future__ import annotations
import json
from typing import Dict, List, Optional
from database import get_connection
from services.chatbot_engine import extract_colors_from_message, extract_sentiment


def learn_from_message(user_id: int, message: str, intent: str) -> Optional[Dict]:
    """
    Analyze a chat message and update user_preferences accordingly.
    
    Returns dict of extracted preferences, or None if nothing was learned.
    """
    extracted = {}
    msg_lower = message.lower()

    conn = get_connection()
    cursor = conn.cursor()

    # Get current preferences
    pref_row = cursor.execute(
        "SELECT * FROM user_preferences WHERE user_id = ?", (user_id,)
    ).fetchone()

    if not pref_row:
        cursor.execute("INSERT INTO user_preferences (user_id) VALUES (?)", (user_id,))
        conn.commit()
        pref_row = cursor.execute(
            "SELECT * FROM user_preferences WHERE user_id = ?", (user_id,)
        ).fetchone()

    preferred_colors = json.loads(pref_row["preferred_colors"] or "[]")
    disliked_colors = json.loads(pref_row["disliked_colors"] or "[]")
    preferred_styles = json.loads(pref_row["preferred_styles"] or "[]")
    preferred_formality = pref_row["preferred_formality"]

    colors = extract_colors_from_message(message)
    sentiment = extract_sentiment(message)
    updated = False

    # Color preference learning
    if intent == "dislike_color" and colors:
        for c in colors:
            if c not in disliked_colors:
                disliked_colors.append(c)
            if c in preferred_colors:
                preferred_colors.remove(c)
        extracted["disliked_colors_added"] = colors
        updated = True

    elif intent == "prefer_color" and colors:
        for c in colors:
            if c not in preferred_colors:
                preferred_colors.append(c)
            if c in disliked_colors:
                disliked_colors.remove(c)
        extracted["preferred_colors_added"] = colors
        updated = True

    elif colors and sentiment == "negative":
        for c in colors:
            if c not in disliked_colors:
                disliked_colors.append(c)
        extracted["disliked_colors_added"] = colors
        updated = True

    elif colors and sentiment == "positive":
        for c in colors:
            if c not in preferred_colors:
                preferred_colors.append(c)
        extracted["preferred_colors_added"] = colors
        updated = True

    # Formality preference learning
    if intent == "make_more_casual":
        formality_order = ["Casual", "Smart Casual", "Semi-Formal", "Formal"]
        idx = formality_order.index(preferred_formality) if preferred_formality in formality_order else 1
        if idx > 0:
            preferred_formality = formality_order[idx - 1]
            extracted["formality_adjusted"] = preferred_formality
            updated = True

    elif intent == "make_more_formal":
        formality_order = ["Casual", "Smart Casual", "Semi-Formal", "Formal"]
        idx = formality_order.index(preferred_formality) if preferred_formality in formality_order else 1
        if idx < len(formality_order) - 1:
            preferred_formality = formality_order[idx + 1]
            extracted["formality_adjusted"] = preferred_formality
            updated = True

    # Style preference learning
    style_keywords = {
        "Minimal": ["minimal", "minimalist", "simple", "clean"],
        "Classic": ["classic", "traditional", "timeless", "elegant"],
        "Bold": ["bold", "colorful", "vibrant", "statement"],
        "Casual": ["casual", "relaxed", "comfortable", "laid back"],
        "Formal": ["formal", "professional", "polished", "structured"],
    }
    for style, keywords in style_keywords.items():
        if any(kw in msg_lower for kw in keywords) and sentiment == "positive":
            if style not in preferred_styles:
                preferred_styles.append(style)
                extracted["style_added"] = style
                updated = True

    # Save updates
    if updated:
        cursor.execute("""
            UPDATE user_preferences SET
                preferred_colors = ?,
                disliked_colors = ?,
                preferred_styles = ?,
                preferred_formality = ?,
                updated_at = CURRENT_TIMESTAMP
            WHERE user_id = ?
        """, (
            json.dumps(preferred_colors),
            json.dumps(disliked_colors),
            json.dumps(preferred_styles),
            preferred_formality,
            user_id,
        ))
        conn.commit()

    conn.close()
    return extracted if extracted else None
