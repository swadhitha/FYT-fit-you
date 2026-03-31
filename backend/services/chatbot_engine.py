"""
chatbot_engine.py
=================
Explainable AI chatbot with intent classification, template responses,
and preference extraction.
"""

from __future__ import annotations
import re
from typing import Optional, Dict, List, Tuple


# ─── Color vocabulary for extraction ──────────────────────────

ALL_COLORS = [
    "black", "white", "grey", "gray", "cream", "beige", "khaki", "charcoal",
    "navy", "blue", "light blue", "teal", "purple", "lavender",
    "maroon", "red", "rust", "orange", "mustard", "brown", "tan",
    "olive", "green", "burgundy", "camel", "terracotta",
    "pink", "peach", "mint", "sky blue", "lilac", "yellow",
    "gold", "silver", "neon", "coral", "mauve",
]


# ─── Intent Classification ───────────────────────────────────

def classify_intent(message: str) -> str:
    """Classify user message into an intent category."""
    msg = message.lower().strip()

    # Greeting
    if any(w in msg for w in ["hi", "hello", "hey", "good morning", "good evening"]):
        if len(msg.split()) <= 4:
            return "greeting"

    # Why / explanation
    if any(w in msg for w in ["why", "explain", "how does", "reason", "tell me why"]):
        return "why_this_outfit"

    # Make more casual
    if any(w in msg for w in ["casual", "relaxed", "comfortable", "chill", "laid back"]):
        if any(w in msg for w in ["more", "make", "want", "prefer", "too formal"]):
            return "make_more_casual"

    # Make more formal
    if any(w in msg for w in ["formal", "professional", "dressy", "elegant", "polished"]):
        if any(w in msg for w in ["more", "make", "want", "prefer", "too casual"]):
            return "make_more_formal"

    # Dislike color
    if any(w in msg for w in ["don't like", "dont like", "hate", "dislike", "not a fan", "remove"]):
        for color in ALL_COLORS:
            if color in msg:
                return "dislike_color"

    # Prefer color
    if any(w in msg for w in ["prefer", "love", "like", "want more", "favorite"]):
        for color in ALL_COLORS:
            if color in msg:
                return "prefer_color"

    # Try alternative
    if any(w in msg for w in ["alternative", "another", "different", "other", "else", "change", "swap"]):
        return "try_alternative"

    # Style query
    if any(w in msg for w in ["what should", "suggest", "recommend", "advice", "tip", "style"]):
        return "general_style_qa"

    return "general_style_qa"


def extract_colors_from_message(message: str) -> List[str]:
    """Extract color names mentioned in a message."""
    msg = message.lower()
    found = []
    for color in sorted(ALL_COLORS, key=len, reverse=True):  # Match longer names first
        if color in msg:
            found.append(color.title())
            msg = msg.replace(color, "")  # Avoid double-matching
    return found


def extract_sentiment(message: str) -> str:
    """Detect positive/negative sentiment."""
    msg = message.lower()
    negative = ["don't", "dont", "hate", "dislike", "not", "never", "remove", "no", "awful", "ugly"]
    positive = ["love", "like", "prefer", "want", "great", "amazing", "perfect", "beautiful"]

    neg_count = sum(1 for w in negative if w in msg)
    pos_count = sum(1 for w in positive if w in msg)

    if neg_count > pos_count:
        return "negative"
    elif pos_count > neg_count:
        return "positive"
    return "neutral"


def generate_response(
    intent: str,
    message: str,
    current_outfit: Optional[dict] = None,
    body_type: Optional[str] = None,
    user_name: Optional[str] = None,
) -> Tuple[str, List[str]]:
    """
    Generate a chatbot response and suggestion chips.
    
    Returns (response_text, suggestion_chips)
    """
    suggestions = ["Why this outfit?", "Make it casual", "Try alternative"]

    if intent == "greeting":
        name = user_name or "there"
        response = (
            f"Hi {name}! 👋 I'm your AI stylist. I can explain outfit choices, "
            f"adjust recommendations, or help you refine your style. What would you like?"
        )
        suggestions = ["Show my outfit", "Style tips", "Update preferences"]

    elif intent == "why_this_outfit":
        if current_outfit and "explanation" in current_outfit:
            bullets = current_outfit["explanation"]
            response = "Here's why this outfit works for you:\n\n"
            for bullet in bullets:
                response += f"• {bullet}\n"
            if body_type:
                response += f"\nThis is optimized for your {body_type} body type."
        else:
            response = (
                "This outfit was selected based on your body proportions, "
                "the occasion you chose, and your style preferences. "
                "Each piece was scored on appropriateness, comfort, and confidence."
            )
        suggestions = ["Make it casual", "Change colors", "Try alternative"]

    elif intent == "make_more_casual":
        response = (
            "Got it! I'll dial down the formality. "
            "I'm looking for more relaxed pieces in your wardrobe — "
            "think cotton, softer fabrics, and less structured cuts. "
            "Let me regenerate your outfit with a casual focus."
        )
        suggestions = ["Make it formal", "Why this outfit?", "Change colors"]

    elif intent == "make_more_formal":
        response = (
            "Understood! I'll elevate the look. "
            "I'm searching for structured pieces, refined fabrics, "
            "and polished combinations. "
            "Let me regenerate with a more formal approach."
        )
        suggestions = ["Make it casual", "Why this outfit?", "Change colors"]

    elif intent == "dislike_color":
        colors = extract_colors_from_message(message)
        if colors:
            color_str = ", ".join(colors)
            response = (
                f"Noted! I'll avoid {color_str} in future recommendations. "
                f"Your preference has been saved. Let me find alternatives without those colors."
            )
        else:
            response = (
                "I understand you don't like certain colors. "
                "Could you tell me which specific colors to avoid?"
            )
        suggestions = ["Prefer warm tones", "Prefer cool tones", "Try alternative"]

    elif intent == "prefer_color":
        colors = extract_colors_from_message(message)
        if colors:
            color_str = ", ".join(colors)
            response = (
                f"Great taste! I'll prioritize {color_str} in your recommendations. "
                f"Your preference has been saved."
            )
        else:
            response = (
                "I'd love to know your favorite colors! "
                "Tell me which colors make you feel confident."
            )
        suggestions = ["Show outfits", "Why this color?", "Try alternative"]

    elif intent == "try_alternative":
        response = (
            "Let me find a different combination from your wardrobe. "
            "I'll keep the same occasion and preferences but mix up the pieces."
        )
        suggestions = ["Why this outfit?", "Make it casual", "Save this look"]

    else:  # general_style_qa
        if body_type:
            tips = {
                "Rectangle": "For a Rectangle body type, creating waist definition is key. Try belted pieces, layered outfits, and textured fabrics at the waist.",
                "Triangle": "For a Triangle body type, draw attention upward with structured shoulders, interesting necklines, and lighter-colored tops.",
                "Inverted Triangle": "For an Inverted Triangle body type, balance wider shoulders with fuller bottoms, A-line skirts, and V-necklines.",
                "Hourglass": "For an Hourglass body type, embrace your curves with fitted pieces that follow your natural waistline.",
            }
            response = tips.get(body_type,
                "I can help you with style advice! Try asking about specific outfits, colors, or occasions.")
        else:
            response = (
                "I'm here to help with styling! You can ask me:\n"
                "• Why a particular outfit was recommended\n"
                "• To adjust formality (more casual or formal)\n"
                "• To avoid or prefer certain colors\n"
                "• For general style tips"
            )
        suggestions = ["Show my body type tips", "Color advice", "Occasion styling"]

    return response, suggestions
