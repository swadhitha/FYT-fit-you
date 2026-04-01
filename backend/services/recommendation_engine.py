"""
recommendation_engine.py
========================
Rule-based outfit recommendation engine.
Combines body profile, occasion, mood, climate, wardrobe items, and user preferences
to generate scored outfit combinations.
"""

from __future__ import annotations
import re
from typing import List, Dict, Optional, Set
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


MOOD_PREFERENCES = {
    "Relaxed": ["Casual"],
    "Confident": ["Smart Casual", "Semi-Formal"],
    "Bold": ["Semi-Formal", "Formal"],
    "Minimal": ["Casual", "Smart Casual"],
    "Playful": ["Casual", "Smart Casual"],
}


def _signature(items: List[dict]) -> str:
    ids = sorted(str(item.get("id", "")) for item in items)
    return "-".join(ids)


def _note_tokens(additional_notes: Optional[str]) -> Set[str]:
    if not additional_notes:
        return set()
    return {
        t
        for t in re.findall(r"[a-zA-Z]+", additional_notes.lower())
        if len(t) >= 3
    }


def generate_recommendations(
    wardrobe: List[dict],
    body_type: Optional[str],
    occasion: str,
    mood: Optional[str],
    climate: Optional[str],
    preferences: Optional[dict],
    additional_notes: Optional[str] = None,
    recent_signatures: Optional[set[str]] = None,
    top_n: int = 3,
) -> List[dict]:
    """
    Generate top-N outfit recommendations.

    Returns list of dicts: {items, scores, explanation}
    """
    if not wardrobe:
        return []

    acceptable = OCCASION_FORMALITY.get(occasion, ["Casual", "Smart Casual"])

    tops = [w for w in wardrobe if w["category"] == "Top"]
    bottoms = [w for w in wardrobe if w["category"] == "Bottom"]
    dresses = [w for w in wardrobe if w["category"] == "Dress"]
    outerwear = [w for w in wardrobe if w["category"] == "Outerwear"]

    combos: List[List[dict]] = []

    for top, bottom in product(tops, bottoms):
        combos.append([top, bottom])
        for outer in outerwear:
            combos.append([top, bottom, outer])

    for dress in dresses:
        combos.append([dress])
        for outer in outerwear:
            combos.append([dress, outer])

    if not combos:
        return []

    recent = recent_signatures or set()
    note_tokens = _note_tokens(additional_notes)

    scored = []
    for combo in combos:
        scores = _score_outfit(
            items=combo,
            body_type=body_type,
            occasion=occasion,
            climate=climate,
            mood=mood,
            preferences=preferences,
            acceptable_formality=acceptable,
            note_tokens=note_tokens,
            recent_signatures=recent,
        )
        explanation = _generate_explanation(
            items=combo,
            body_type=body_type,
            occasion=occasion,
            scores=scores,
            mood=mood,
        )
        scored.append(
            {
                "items": combo,
                "scores": scores,
                "explanation": explanation,
                "signature": _signature(combo),
            }
        )

    scored.sort(key=lambda x: x["scores"]["total"], reverse=True)

    selected = []
    used_item_ids: set[int] = set()
    for candidate in scored:
        candidate_ids = {int(i["id"]) for i in candidate["items"]}
        overlap = len(used_item_ids.intersection(candidate_ids))
        if selected and overlap == len(candidate_ids):
            continue
        selected.append(candidate)
        used_item_ids.update(candidate_ids)
        if len(selected) >= top_n:
            break

    if not selected:
        selected = scored[:top_n]

    results = []
    for rank, outfit in enumerate(selected, start=1):
        results.append(
            {
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
            }
        )

    return results


def _score_outfit(
    items: List[dict],
    body_type: Optional[str],
    occasion: str,
    climate: Optional[str],
    mood: Optional[str],
    preferences: Optional[dict],
    acceptable_formality: List[str],
    note_tokens: Set[str],
    recent_signatures: set[str],
) -> dict:
    """Score an outfit on appropriateness, confidence, and comfort."""

    pref = preferences or {}

    appropriateness = 0.0

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

    mood_targets = MOOD_PREFERENCES.get(mood or "", [])
    if mood_targets:
        mood_hits = sum(1 for item in items if item["formality"] in mood_targets)
        appropriateness += min(10, (mood_hits / len(items)) * 10)
    else:
        appropriateness += 5

    colors = [item["color"] for item in items]
    if len(colors) >= 2:
        harmony_count = sum(
            1
            for i in range(len(colors))
            for j in range(i + 1, len(colors))
            if _colors_harmonize(colors[i], colors[j])
        )
        total_pairs = len(colors) * (len(colors) - 1) / 2
        appropriateness += (harmony_count / total_pairs) * 20 if total_pairs > 0 else 20
    else:
        appropriateness += 18

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
                fabric_score += 4
            else:
                fabric_score += 12
    appropriateness += (fabric_score / fabric_count) if fabric_count > 0 else 12

    if body_type and body_type in BODY_TYPE_TIPS:
        tips = BODY_TYPE_TIPS[body_type]
        has_good = any(item["category"] in tips["good_categories"] for item in items)
        appropriateness += 20 if has_good else 10
    else:
        appropriateness += 12

    confidence = 0.0
    preferred_colors = pref.get("preferred_colors", [])
    disliked_colors = pref.get("disliked_colors", [])

    if preferred_colors:
        color_match = sum(1 for item in items if item["color"] in preferred_colors)
        confidence += min(30, (color_match / len(items)) * 30)
    else:
        confidence += 15

    if disliked_colors:
        has_disliked = any(item["color"] in disliked_colors for item in items)
        confidence += 0 if has_disliked else 20
    else:
        confidence += 20

    usage_scores = []
    for item in items:
        usage = item.get("usage_count", 0)
        if usage <= 1:
            usage_scores.append(20)
        elif usage <= 4:
            usage_scores.append(12)
        else:
            usage_scores.append(5)
    confidence += sum(usage_scores) / len(usage_scores) if usage_scores else 10

    if note_tokens:
        matches = 0
        for item in items:
            search_blob = " ".join(
                [
                    str(item.get("name", "")).lower(),
                    str(item.get("category", "")).lower(),
                    str(item.get("color", "")).lower(),
                    str(item.get("fabric", "")).lower(),
                ]
            )
            if any(tok in search_blob for tok in note_tokens):
                matches += 1
        confidence += min(20, (matches / len(items)) * 20)
    else:
        confidence += 8

    comfort = 0.0
    comfort += (fabric_score / fabric_count * 2) if fabric_count > 0 else 30

    avg_formality = sum(FORMALITY_RANK.get(i["formality"], 2) for i in items) / len(items)
    max_acceptable = max(FORMALITY_RANK.get(f, 2) for f in acceptable_formality)
    if avg_formality <= max_acceptable:
        comfort += 30
    else:
        comfort += max(0, 30 - (avg_formality - max_acceptable) * 10)

    comfort_priority = pref.get("comfort_priority", 0.5)
    comfort += 15 + comfort_priority * 15

    novelty = 0.0
    if _signature(items) not in recent_signatures:
        novelty += 15.0
    else:
        novelty += 2.0

    total = 0.36 * appropriateness + 0.34 * confidence + 0.23 * comfort + 0.07 * novelty

    return {
        "appropriateness": round(appropriateness, 1),
        "confidence": round(confidence, 1),
        "comfort": round(comfort, 1),
        "novelty": round(novelty, 1),
        "total": round(total, 1),
    }


def _generate_explanation(
    items: List[dict],
    body_type: Optional[str],
    occasion: str,
    scores: dict,
    mood: Optional[str],
) -> List[str]:
    """Generate 'Why this works' explanation bullets."""
    explanations = []

    formalities = [item["formality"] for item in items]
    primary = max(set(formalities), key=formalities.count)
    explanations.append(
        f"The {primary.lower()} formality aligns with your {occasion.lower()} context."
    )

    if mood:
        explanations.append(
            f"This combination supports a {mood.lower()} mood through fit and formality balance."
        )

    colors = [item["color"] for item in items]
    if len(set(colors)) == 1:
        explanations.append(
            f"A monochrome {colors[0].lower()} palette creates a clean, premium look."
        )
    elif all(
        _colors_harmonize(colors[i], colors[j])
        for i in range(len(colors))
        for j in range(i + 1, len(colors))
    ):
        explanations.append(
            f"The {' and '.join(colors)} combination creates harmonious color contrast."
        )

    if body_type and body_type in BODY_TYPE_TIPS:
        explanations.append(BODY_TYPE_TIPS[body_type]["tip"])

    if scores["novelty"] >= 10:
        explanations.append("This look introduces less-used pieces to improve wardrobe variety.")

    return explanations[:4]
