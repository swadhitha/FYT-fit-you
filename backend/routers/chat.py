"""
Chat API endpoints with explainable AI.
"""

import json
from fastapi import APIRouter, HTTPException
from database import get_connection
from models.schemas import ChatMessage, ChatResponse
from services.chatbot_engine import classify_intent, generate_response
from services.preference_learner import learn_from_message

router = APIRouter(prefix="/api/chat", tags=["Chat"])


@router.post("/{user_id}", response_model=ChatResponse)
async def send_message(user_id: int, chat: ChatMessage):
    """Send a message and get AI stylist response."""
    conn = get_connection()
    cursor = conn.cursor()

    # Verify user
    user = cursor.execute("SELECT * FROM users WHERE id = ?", (user_id,)).fetchone()
    if not user:
        conn.close()
        raise HTTPException(status_code=404, detail="User not found.")

    # Get body type for context
    body = cursor.execute(
        "SELECT body_type FROM body_profile WHERE user_id = ?", (user_id,)
    ).fetchone()
    body_type = body["body_type"] if body else None

    # Classify intent
    intent = classify_intent(chat.message)

    # Generate response
    current_outfit = chat.context  # Optional context from frontend
    response_text, suggestion_chips = generate_response(
        intent=intent,
        message=chat.message,
        current_outfit=current_outfit,
        body_type=body_type,
        user_name=user["name"],
    )

    # Learn preferences from message
    extracted = learn_from_message(user_id, chat.message, intent)

    # Save chat logs
    cursor.execute("""
        INSERT INTO chat_logs (user_id, role, message, context_data, extracted_preferences)
        VALUES (?, 'user', ?, ?, ?)
    """, (user_id, chat.message,
          json.dumps(chat.context) if chat.context else None,
          json.dumps(extracted) if extracted else None))

    cursor.execute("""
        INSERT INTO chat_logs (user_id, role, message, context_data)
        VALUES (?, 'assistant', ?, ?)
    """, (user_id, response_text, json.dumps({"intent": intent})))

    conn.commit()
    conn.close()

    return ChatResponse(
        response=response_text,
        intent=intent,
        extracted_preferences=extracted,
        suggestions=suggestion_chips,
    )


@router.get("/{user_id}/history")
async def chat_history(user_id: int):
    """Get chat history for a user."""
    conn = get_connection()
    rows = conn.execute(
        "SELECT * FROM chat_logs WHERE user_id = ? ORDER BY created_at ASC LIMIT 100",
        (user_id,)
    ).fetchall()
    conn.close()

    return [
        {
            "id": r["id"],
            "role": r["role"],
            "message": r["message"],
            "created_at": r["created_at"],
        }
        for r in rows
    ]
