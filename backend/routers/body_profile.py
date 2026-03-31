"""
Body profile API endpoints.
Supports both manual measurement input and image-based analysis.
"""

import json
from fastapi import APIRouter, HTTPException, File, UploadFile
import numpy as np
from database import get_connection
from models.schemas import BodyProfileCreate, BodyProfileResponse

router = APIRouter(prefix="/api/body-profile", tags=["Body Profile"])


def _analyze_measurements(data: BodyProfileCreate) -> dict:
    """Analyze body measurements and return classification.
    
    This mirrors the Dart BodyMetricAnalyzer logic on the backend.
    """
    height_m = data.height_cm / 100
    bmi = data.weight_kg / (height_m * height_m)
    waist_to_hip = data.waist_cm / data.hip_cm
    shoulder_to_hip = data.shoulder_cm / data.hip_cm
    leg_to_height = data.inseam_cm / data.height_cm
    chest_to_hip = data.chest_cm / data.hip_cm

    # Body type classification
    waist_ref = min(data.shoulder_cm, data.hip_cm)
    has_defined_waist = data.waist_cm <= waist_ref * 0.75

    if has_defined_waist and 0.95 <= shoulder_to_hip <= 1.05:
        body_type = "Hourglass"
    elif shoulder_to_hip > 1.05 or chest_to_hip > 1.05:
        body_type = "Inverted Triangle"
    elif shoulder_to_hip < 0.95 or chest_to_hip < 0.95:
        body_type = "Triangle"
    else:
        body_type = "Rectangle"

    # BMI category
    if bmi < 18.5:
        bmi_cat = "Underweight"
    elif bmi < 25:
        bmi_cat = "Healthy"
    elif bmi < 30:
        bmi_cat = "Overweight"
    else:
        bmi_cat = "Obese"

    # Proportion summary
    if shoulder_to_hip > 1.05:
        sh_text = "Shoulders read broader than hips"
    elif shoulder_to_hip < 0.95:
        sh_text = "Hips read broader than shoulders"
    else:
        sh_text = "Shoulders and hips are balanced"

    waist_text = ("with a defined waistline" if waist_to_hip <= 0.8
                  else "with a softer waist transition")
    leg_text = ("Leg proportion is longer relative to total height."
                if leg_to_height >= 0.46
                else "Torso proportion is slightly longer relative to legs.")

    summary = f"{body_type} profile. {sh_text}, {waist_text}. {leg_text}"

    # Styling suggestions
    suggestions_map = {
        "Hourglass": [
            "Highlight the waist with structured or wrap silhouettes.",
            "Choose balanced shoulder and hip detailing.",
            "Prefer mid to high-rise bottoms for proportion continuity.",
        ],
        "Inverted Triangle": [
            "Use softer shoulder lines and avoid heavy shoulder pads.",
            "Add visual weight in bottoms with pleats or fuller cuts.",
            "Keep necklines open to reduce upper-body width emphasis.",
        ],
        "Triangle": [
            "Add structure or detail to the upper body and shoulders.",
            "Use darker, cleaner lines for bottoms.",
            "A-line and fit-and-flare shapes keep visual balance.",
        ],
        "Rectangle": [
            "Create shape with belted layers and tailored jackets.",
            "Use monochrome columns to visually elongate the frame.",
            "Mix texture strategically at waist level for definition.",
        ],
    }

    return {
        "body_type": body_type,
        "bmi": round(bmi, 1),
        "bmi_category": bmi_cat,
        "shoulder_to_hip_ratio": round(shoulder_to_hip, 3),
        "waist_to_hip_ratio": round(waist_to_hip, 3),
        "leg_to_height_ratio": round(leg_to_height, 3),
        "proportion_summary": summary,
        "styling_suggestions": suggestions_map.get(body_type, suggestions_map["Rectangle"]),
    }


@router.post("/{user_id}", response_model=BodyProfileResponse)
async def save_body_profile(user_id: int, data: BodyProfileCreate):
    """Save or update body profile from manual measurements."""
    conn = get_connection()
    cursor = conn.cursor()

    user = cursor.execute("SELECT id FROM users WHERE id = ?", (user_id,)).fetchone()
    if not user:
        conn.close()
        raise HTTPException(status_code=404, detail="User not found.")

    analysis = _analyze_measurements(data)

    # Upsert body profile
    existing = cursor.execute(
        "SELECT id FROM body_profile WHERE user_id = ?", (user_id,)
    ).fetchone()

    suggestions_json = json.dumps(analysis["styling_suggestions"])

    if existing:
        cursor.execute("""
            UPDATE body_profile SET
                height_cm=?, weight_kg=?, shoulder_cm=?, chest_cm=?,
                waist_cm=?, hip_cm=?, inseam_cm=?, body_type=?,
                bmi=?, bmi_category=?, shoulder_to_hip_ratio=?,
                waist_to_hip_ratio=?, leg_to_height_ratio=?,
                proportion_summary=?, styling_suggestions=?,
                updated_at=CURRENT_TIMESTAMP
            WHERE user_id=?
        """, (data.height_cm, data.weight_kg, data.shoulder_cm, data.chest_cm,
              data.waist_cm, data.hip_cm, data.inseam_cm,
              analysis["body_type"], analysis["bmi"], analysis["bmi_category"],
              analysis["shoulder_to_hip_ratio"], analysis["waist_to_hip_ratio"],
              analysis["leg_to_height_ratio"], analysis["proportion_summary"],
              suggestions_json, user_id))
    else:
        cursor.execute("""
            INSERT INTO body_profile (user_id, height_cm, weight_kg, shoulder_cm,
                chest_cm, waist_cm, hip_cm, inseam_cm, body_type, bmi, bmi_category,
                shoulder_to_hip_ratio, waist_to_hip_ratio, leg_to_height_ratio,
                proportion_summary, styling_suggestions)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, (user_id, data.height_cm, data.weight_kg, data.shoulder_cm,
              data.chest_cm, data.waist_cm, data.hip_cm, data.inseam_cm,
              analysis["body_type"], analysis["bmi"], analysis["bmi_category"],
              analysis["shoulder_to_hip_ratio"], analysis["waist_to_hip_ratio"],
              analysis["leg_to_height_ratio"], analysis["proportion_summary"],
              suggestions_json))

    conn.commit()

    row = cursor.execute(
        "SELECT * FROM body_profile WHERE user_id = ?", (user_id,)
    ).fetchone()
    conn.close()

    return BodyProfileResponse(
        id=row["id"], user_id=row["user_id"],
        height_cm=row["height_cm"], weight_kg=row["weight_kg"],
        shoulder_cm=row["shoulder_cm"], chest_cm=row["chest_cm"],
        waist_cm=row["waist_cm"], hip_cm=row["hip_cm"],
        inseam_cm=row["inseam_cm"], body_type=row["body_type"],
        bmi=row["bmi"], bmi_category=row["bmi_category"],
        shoulder_to_hip_ratio=row["shoulder_to_hip_ratio"],
        waist_to_hip_ratio=row["waist_to_hip_ratio"],
        leg_to_height_ratio=row["leg_to_height_ratio"],
        proportion_summary=row["proportion_summary"],
        styling_suggestions=json.loads(row["styling_suggestions"]),
    )


@router.post("/{user_id}/scan")
async def scan_body(user_id: int, file: UploadFile = File(...)):
    """Upload image for MediaPipe-based body analysis."""
    try:
        import cv2
        from body_metric_module import analyse_image
    except ImportError:
        raise HTTPException(
            status_code=500,
            detail="OpenCV/MediaPipe not available. Use manual measurements instead."
        )

    conn = get_connection()
    user = conn.execute("SELECT id FROM users WHERE id = ?", (user_id,)).fetchone()
    if not user:
        conn.close()
        raise HTTPException(status_code=404, detail="User not found.")
    conn.close()

    image_bytes = await file.read()
    image_np = np.frombuffer(image_bytes, dtype=np.uint8)
    image = cv2.imdecode(image_np, cv2.IMREAD_COLOR)

    if image is None:
        raise HTTPException(status_code=400, detail="Invalid image file.")

    try:
        result = analyse_image(image)
    except RuntimeError as e:
        raise HTTPException(status_code=400, detail=str(e))

    return result.as_dict()


@router.get("/{user_id}", response_model=BodyProfileResponse)
async def get_body_profile(user_id: int):
    """Get saved body profile for a user."""
    conn = get_connection()
    row = conn.execute(
        "SELECT * FROM body_profile WHERE user_id = ?", (user_id,)
    ).fetchone()
    conn.close()

    if not row:
        raise HTTPException(status_code=404, detail="Body profile not found. Please complete body analysis first.")

    return BodyProfileResponse(
        id=row["id"], user_id=row["user_id"],
        height_cm=row["height_cm"], weight_kg=row["weight_kg"],
        shoulder_cm=row["shoulder_cm"], chest_cm=row["chest_cm"],
        waist_cm=row["waist_cm"], hip_cm=row["hip_cm"],
        inseam_cm=row["inseam_cm"], body_type=row["body_type"],
        bmi=row["bmi"], bmi_category=row["bmi_category"],
        shoulder_to_hip_ratio=row["shoulder_to_hip_ratio"],
        waist_to_hip_ratio=row["waist_to_hip_ratio"],
        leg_to_height_ratio=row["leg_to_height_ratio"],
        proportion_summary=row["proportion_summary"],
        styling_suggestions=json.loads(row["styling_suggestions"] or "[]"),
    )
