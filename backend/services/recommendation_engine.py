"""
recommendation_engine.py
========================
Rule-based outfit recommendation engine.
Combines body profile, occasion, mood, climate, wardrobe items, and user preferences
to generate scored outfit combinations.
"""

from __future__ import annotations
import json
import random
from typing import List, Dict, Optional, Tuple
from itertools import product


# ─── Color Harmony Rules ──────────────────────────────────────

COLOR_FAMILIES = {
    "Neutral": ["Black", "White", "Grey", "Cream", "Beige", "Khaki", "Dark Grey", "Charcoal"],
    "Cool": ["Navy", "Blue", "Light Blue", "Teal", "Purple", "Lavender"],
    "Warm": ["Maroon", "Red", "Rust", "Orange", "Mustard", "Brown", "Tan"],
    "Earth": ["Olive", "Forest Green", "Burgundy", "Camel", "Terracotta"],
    "Pastel": ["Pink", "Peach", "Mint", "Sky Blue", "Lilac"],
}

HARMONIOUS_PAIRS = {
    "Neutral": ["Neutral", "Cool", "Warm", "Earth", "Pastel"],
    "Cool": ["Neutral", "Cool", "Pastel"],
    "Warm": ["Neutral", "Warm", "Earth"],
    "Earth": ["Neutral", "Warm", "Earth"],
    "Pastel": ["Neutral", "Cool", "Pastel"],
}


def _get_color_family(color: str) -> str:
    for family, colors in COLOR_FAMILIES.items():
        if color.lower() in [c.lower() for c in colors]:
            return family
    return "Neutral"


def _colors_harmonize(c1: str, c2: str) -> bool:
    f1, f2 = _get_color_family(c1), _get_color_family(c2)
    return f2 in HARMONIOUS_PAIRS.get(f1, ["Neutral"])


# ─── Formality Rules ──────────────────────────────────────────

OCCASION_FORMALITY = {
    "College": ["Casual", "Smart Casual"],
    "Office": ["Smart Casual", "Semi-Formal"],
    "Wedding": ["Semi-Formal", "Formal"],
    "Casual": ["Casual"],
    "Date": ["Smart Casual", "Semi-Formal"],
    "Presentation": ["Semi-Formal", "Formal"],
    "Party": ["Smart Casual", "Semi-Formal"],
    "Interview": ["Semi-Formal", "Formal"],
}

FORMALITY_RANK = {"Casual": 1, "Smart Casual": 2, "Semi-Formal": 3, "Formal": 4}


# ─── Fabric Climate Rules ─────────────────────────────────────

CLIMATE_FABRICS = {
    "Hot": {"good": ["Cotton", "Linen", "Rayon"], "avoid": ["Wool", "Fleece", "Leather"]},
    "Warm": {"good": ["Cotton", "Linen", "Polyester"], "avoid": ["Wool", "Fleece"]},
    "Cool": {"good": ["Cotton", "Denim", "Polyester", "Wool"], "avoid": []},
    "Cold": {"good": ["Wool", "Fleece", "Denim", "Leather"], "avoid": ["Linen"]},
}


# ─── Body Type Flattery Rules ─────────────────────────────────

BODY_TYPE_TIPS = {
    "Rectangle": {
        "good_categories": ["Outerwear"],
        "tip": "Structured layers at the waist create definition.",
    },
    "Triangle": {
        "good_categories": ["Top", "Outerwear"],
        "tip": "Structured tops balance broader hips.",
    },
    "Inverted Triangle": {
        "good_categories": ["Bottom"],
        "tip": "Fuller bottoms balance broader shoulders.",
    },
    "Hourglass": {
        "good_categories": ["Top", "Bottom"],
        "tip": "Fitted pieces that follow your natural contours work best.",
    },
}


def generate_recommendations(
    wardrobe: List[dict],
    body_type: Optional[str],
    occasion: str,
    mood: Optional[str],
    climate: Optional[str],
    preferences: Optional[dict],
    top_n: int = 3,
) -> List[dict]:
    """
    Generate top-N outfit recommendations.
    
    Returns list of dicts: {items, scores, explanation}
    """
    if not wardrobe:
        return []

    # Get acceptable formality levels
    acceptable = OCCASION_FORMALITY.get(occasion, ["Casual", "Smart Casual"])

    # Separate wardrobe by category
    tops = [w for w in wardrobe if w["category"] == "Top"]
    bottoms = [w for w in wardrobe if w["category"] == "Bottom"]
    dresses = [w for w in wardrobe if w["category"] == "Dress"]
    outerwear = [w for w in wardrobe if w["category"] == "Outerwear"]

    # Generate outfit combinations
    combos = []

    # Top + Bottom combos
    for top, bottom in product(tops, bottoms):
        combo = [top, bottom]
        # Optionally add outerwear
        for outer in outerwear:
            combos.append([top, bottom, outer])
        combos.append(combo)

    # Dress combos
    for dress in dresses:
        combos.append([dress])
        for outer in outerwear:
            combos.append([dress, outer])

    if not combos:
        return []

    # Score each combo
    scored = []
    for combo in combos:
        scores = _score_outfit(combo, body_type, occasion, climate, preferences, acceptable)
        explanation = _generate_explanation(combo, body_type, occasion, scores)
        scored.append({
            "items": combo,
            "scores": scores,
            "explanation": explanation,
        })

    # Sort by total score descending
    scored.sort(key=lambda x: x["scores"]["total"], reverse=True)

    # Return top N
    results = []
    for rank, outfit in enumerate(scored[:top_n], start=1):
        results.append({
            "rank": rank,
            "items": [
                {
                    "id": item["id"],
                    "name": item.get("name"),
                    "category": item["category"],
                    "color": item["color"],
                    "formality": item["formality"],
                }
                for item in outfit["items"]
            ],
            "scores": outfit["scores"],
            "explanation": outfit["explanation"],
        })

    return results


def _score_outfit(
    items: List[dict],
    body_type: Optional[str],
    occasion: str,
    climate: Optional[str],
    preferences: Optional[dict],
    acceptable_formality: List[str],
) -> dict:
    """Score an outfit on appropriateness, confidence, and comfort."""

    # ─── Appropriateness (0–100) ───
    appropriateness = 0.0

    # Formality match (0–40)
    formality_scores = []
    for item in items:
        if item["formality"] in acceptable_formality:
            formality_scores.append(40.0)
        else:
            diff = abs(
                FORMALITY_RANK.get(item["formality"], 2)
                - max(FORMALITY_RANK.get(f, 2) for f in acceptable_formality)
            )
            formality_scores.append(max(0, 40 - diff * 15))
    appropriateness += sum(formality_scores) / len(formality_scores) if formality_scores else 0

    # Color harmony (0–20)
    colors = [item["color"] for item in items]
    if len(colors) >= 2:
        harmony_count = sum(
            1 for i in range(len(colors)) for j in range(i + 1, len(colors))
            if _colors_harmonize(colors[i], colors[j])
        )
        total_pairs = len(colors) * (len(colors) - 1) / 2
        appropriateness += (harmony_count / total_pairs) * 20 if total_pairs > 0 else 20
    else:
        appropriateness += 20

    # Climate suitability (0–20)
    climate_key = climate or "Warm"
    climate_rules = CLIMATE_FABRICS.get(climate_key, CLIMATE_FABRICS["Warm"])
    fabric_score = 0
    fabric_count = 0
    for item in items:
        fabric = item.get("fabric", "")
        if fabric:
            fabric_count += 1
            if fabric in climate_rules["good"]:
                fabric_score += 20
            elif fabric in climate_rules["avoid"]:
                fabric_score += 5
            else:
                fabric_score += 12
    appropriateness += (fabric_score / fabric_count) if fabric_count > 0 else 15

    # Body type flattery (0–20)
    if body_type and body_type in BODY_TYPE_TIPS:
        tips = BODY_TYPE_TIPS[body_type]
        has_good = any(item["category"] in tips["good_categories"] for item in items)
        appropriateness += 20 if has_good else 10
    else:
        appropriateness += 15

    # ─── Confidence (0–100) ───
    confidence = 0.0
    pref = preferences or {}
    preferred_colors = pref.get("preferred_colors", [])
    disliked_colors = pref.get("disliked_colors", [])
    preferred_styles = pref.get("preferred_styles", [])

    # Preferred colors (0–30)
    if preferred_colors:
        color_match = sum(1 for item in items if item["color"] in preferred_colors)
        confidence += min(30, (color_match / len(items)) * 30) if items else 0
    else:
        confidence += 15

    # Avoid disliked colors (0–20)
    if disliked_colors:
        has_disliked = any(item["color"] in disliked_colors for item in items)
        confidence += 0 if has_disliked else 20
    else:
        confidence += 20

    # Style match (0–30)
    confidence += 20  # Base score since we don't have per-item style tags

    # Usage recency bonus (0–20) — boost underused items
    usage_scores = []
    for item in items:
        usage = item.get("usage_count", 0)
        if usage <= 2:
            usage_scores.append(20)
        elif usage <= 5:
            usage_scores.append(12)
        else:
            usage_scores.append(5)
    confidence += sum(usage_scores) / len(usage_scores) if usage_scores else 10

    # ─── Comfort (0–100) ───
    comfort = 0.0

    # Fabric breathability (0–40)
    comfort += (fabric_score / fabric_count * 2) if fabric_count > 0 else 30

    # Not over-dressed (0–30)
    avg_formality = sum(FORMALITY_RANK.get(i["formality"], 2) for i in items) / len(items)
    max_acceptable = max(FORMALITY_RANK.get(f, 2) for f in acceptable_formality)
    if avg_formality <= max_acceptable:
        comfort += 30
    else:
        comfort += max(0, 30 - (avg_formality - max_acceptable) * 10)

    # Comfort priority weighting (0–30)
    comfort_priority = pref.get("comfort_priority", 0.5)
    comfort += 15 + comfort_priority * 15

    # ─── Total weighted score ───
    total = 0.4 * appropriateness + 0.35 * confidence + 0.25 * comfort

    return {
        "appropriateness": round(appropriateness, 1),
        "confidence": round(confidence, 1),
        "comfort": round(comfort, 1),
        "total": round(total, 1),
    }


def _generate_explanation(
    items: List[dict],
    body_type: Optional[str],
    occasion: str,
    scores: dict,
) -> List[str]:
    """Generate 'Why this works' explanation bullets."""
    explanations = []

    # Formality explanation
    formalities = [item["formality"] for item in items]
    primary = max(set(formalities), key=formalities.count)
    explanations.append(
        f"The {primary.lower()} formality matches the {occasion.lower()} setting."
    )

    # Color explanation
    colors = [item["color"] for item in items]
    if len(set(colors)) == 1:
        explanations.append(f"A monochrome {colors[0].lower()} palette creates a sleek, unified look.")
    elif all(_colors_harmonize(colors[i], colors[j])
             for i in range(len(colors)) for j in range(i + 1, len(colors))):
        explanations.append(
            f"The {' and '.join(colors)} combination creates a harmonious color story."
        )

    # Body type explanation
    if body_type and body_type in BODY_TYPE_TIPS:
        explanations.append(BODY_TYPE_TIPS[body_type]["tip"])

    # Score-based explanation
    if scores["comfort"] > 70:
        explanations.append("This outfit prioritizes comfort while maintaining polish.")
    if scores["confidence"] > 70:
        explanations.append("This combination aligns well with your style preferences.")

    return explanations[:4]  # Max 4 bullets
