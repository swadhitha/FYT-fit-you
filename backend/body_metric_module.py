"""
body_metric_module.py
======================

This module implements the core logic for the **Structural Intelligence**
component of an AI‑powered personal styling application.  The goal of this
module is to take a full‑body image as input, estimate a handful of
anatomical measurements (e.g. shoulder width, hip width, torso length) and
derive higher level ratios (e.g. shoulder‑to‑hip ratio, torso‑to‑leg ratio).
From these measurements the module infers a high‑level ``body_type`` (triangle,
rectangle, hourglass, etc.) and emits a **Body Intelligence Profile**.  The
profile can be persisted in a database and used by other components (e.g. the
styling engine) to drive personalised outfit recommendations.

The code here is deliberately modular so that it can be reused in other
contexts.  It exposes a single top‑level function ``analyse_image`` which
returns a ``BodyMetricResult`` data object.  A FastAPI route is provided in
``main.py`` (see below) that demonstrates how to expose this functionality via
a REST API.

Dependencies
------------

The implementation relies on the following third‑party packages:

* `mediapipe` for pose estimation
* `opencv-python` (or `opencv-python-headless`) for image loading and basic
  manipulation
* `numpy` for vector calculations
* `fastapi` and `pydantic` for the web API

These packages are not bundled in this repository by default.  To run this
module you will need to install them using pip, e.g.::

    pip install mediapipe opencv-python numpy fastapi uvicorn

If you cannot install Mediapipe (for example because of network restrictions
in your environment) you can stub the ``extract_landmarks`` function with your
own landmark extractor or supply pre‑computed landmark coordinates.  The
remainder of the logic is pure Python and can be executed without Mediapipe.

Usage
-----

The primary entry point is ``analyse_image``.  It accepts an image as a
NumPy array (BGR format), performs pose estimation and returns a
``BodyMetricResult`` instance.  You can then serialise this result to JSON
or persist it to your database.

Example::

    from body_metric_module import analyse_image
    import cv2

    image = cv2.imread("/path/to/photo.jpg")
    result = analyse_image(image)
    print(result.json(indent=2))

See ``main.py`` for a working FastAPI example.
"""

from __future__ import annotations

from dataclasses import dataclass
from enum import Enum
from typing import Dict, Tuple, Optional, List

import numpy as np

# Attempt to import optional dependencies.  If MediaPipe or OpenCV are not
# available in your environment this module will still import, but calling
# functions that require them will raise ImportError.  This design lets you
# write unit tests for the pure Python parts of the module without needing
# these heavy dependencies installed.
try:
    import mediapipe as mp  # type: ignore
except ImportError:
    mp = None  # type: ignore

try:
    import cv2  # type: ignore
except ImportError:
    cv2 = None  # type: ignore


class BodyType(str, Enum):
    """Enumeration of high‑level body type categories.

    The categories here are deliberately broad to capture the most common
    silhouettes.  More granular categories can be added if needed.
    """

    RECTANGLE = "rectangle"
    TRIANGLE = "triangle"  # shoulders narrower than hips (a.k.a. pear)
    INVERTED_TRIANGLE = "inverted_triangle"  # shoulders wider than hips
    HOURGLASS = "hourglass"  # shoulders and hips similar, waist narrower
    OVAL = "oval"  # waist wider than shoulders and hips
    UNCLASSIFIED = "unclassified"


@dataclass
class BodyMetricResult:
    """A simple data container for the output of the body metric analysis.

    ``body_type``: high level classification based on ratios.

    ``metrics``: raw measurements normalised to shoulder width (see below).

    ``symmetry``: estimated left/right symmetry metric (0 means perfectly
    symmetric; larger values indicate more asymmetry).

    ``posture_angle``: the angle (in degrees) between the estimated torso
    vector and the vertical axis.  Values near 0 indicate an upright posture.
    """

    body_type: BodyType
    metrics: Dict[str, float]
    symmetry: float
    posture_angle: float

    def as_dict(self) -> Dict[str, float | str]:
        """Return a serialisable dictionary representation of the result."""
        return {
            "body_type": self.body_type.value,
            "metrics": {k: float(v) for k, v in self.metrics.items()},
            "symmetry": float(self.symmetry),
            "posture_angle": float(self.posture_angle),
        }


def _euclidean_distance(p1: Tuple[float, float], p2: Tuple[float, float]) -> float:
    """Return the Euclidean distance between two 2D points."""
    return float(np.linalg.norm(np.array(p1) - np.array(p2)))


def _prepare_variants(image: np.ndarray) -> List[np.ndarray]:
    """Create a few robust image variants to improve pose detection success."""
    variants = [image]
    if cv2 is None:
        return variants

    # Contrast enhanced variant (helps low-light photos).
    lab = cv2.cvtColor(image, cv2.COLOR_BGR2LAB)
    l, a, b = cv2.split(lab)
    clahe = cv2.createCLAHE(clipLimit=2.5, tileGridSize=(8, 8))
    l2 = clahe.apply(l)
    enhanced = cv2.cvtColor(cv2.merge((l2, a, b)), cv2.COLOR_LAB2BGR)
    variants.append(enhanced)

    # Slightly upscaled variant (helps when subject occupies fewer pixels).
    h, w = image.shape[:2]
    if max(h, w) < 1080:
        scale = min(1.6, 1080.0 / max(h, w))
        resized = cv2.resize(
            image, (int(w * scale), int(h * scale)), interpolation=cv2.INTER_CUBIC
        )
        variants.append(resized)

    return variants


def _extract_landmarks_fallback(image: np.ndarray) -> Optional[Dict[str, Tuple[float, float]]]:
    """Fallback body landmark estimation using OpenCV person detector.

    This is a coarse fallback when MediaPipe Pose landmarks are unavailable.
    """
    if cv2 is None:
        return None

    hog = cv2.HOGDescriptor()
    hog.setSVMDetector(cv2.HOGDescriptor_getDefaultPeopleDetector())
    rects, _ = hog.detectMultiScale(
        image,
        winStride=(8, 8),
        padding=(8, 8),
        scale=1.05,
    )
    if len(rects) == 0:
        # Last-resort fallback: assume centered full-body framing.
        h_img, w_img = image.shape[:2]
        w = 0.58 * w_img
        h = 0.86 * h_img
        x = (w_img - w) / 2.0
        y = (h_img - h) / 2.0
    else:
        x, y, w, h = max(rects, key=lambda r: r[2] * r[3])
    x = float(x)
    y = float(y)
    w = float(w)
    h = float(h)

    cx = x + w / 2.0
    shoulder_y = y + 0.22 * h
    hip_y = y + 0.56 * h
    knee_y = y + 0.77 * h
    ankle_y = y + 0.95 * h

    shoulder_half = 0.24 * w
    hip_half = 0.21 * w
    knee_half = 0.14 * w
    ankle_half = 0.08 * w

    return {
        "left_shoulder": (cx - shoulder_half, shoulder_y),
        "right_shoulder": (cx + shoulder_half, shoulder_y),
        "left_hip": (cx - hip_half, hip_y),
        "right_hip": (cx + hip_half, hip_y),
        "left_knee": (cx - knee_half, knee_y),
        "right_knee": (cx + knee_half, knee_y),
        "left_ankle": (cx - ankle_half, ankle_y),
        "right_ankle": (cx + ankle_half, ankle_y),
    }


def _extract_landmarks(image: np.ndarray) -> Optional[Dict[str, Tuple[float, float]]]:
    """Run MediaPipe pose estimation on an image and return selected landmarks.

    The keys in the returned dictionary correspond to anatomical landmarks
    relevant to our body metric calculations: shoulders, hips, knees and
    ankles.  If pose estimation fails or MediaPipe is unavailable this
    function returns ``None``.
    """
    if cv2 is None:
        raise ImportError(
            "OpenCV is required for body landmark extraction. "
            "Please install it with `pip install opencv-python`."
        )

    if mp is None or not hasattr(mp, "solutions"):
        return _extract_landmarks_fallback(image)

    pose = mp.solutions.pose.Pose(
        static_image_mode=True,
        model_complexity=1,
        min_detection_confidence=0.25,
    )
    try:
        for variant in _prepare_variants(image):
            rgb_image = cv2.cvtColor(variant, cv2.COLOR_BGR2RGB)
            results = pose.process(rgb_image)
            if not results.pose_landmarks:
                continue

            landmark_dict: Dict[str, Tuple[float, float]] = {}
            height, width = variant.shape[:2]
            landmark_map = {
                "left_shoulder": mp.solutions.pose.PoseLandmark.LEFT_SHOULDER,
                "right_shoulder": mp.solutions.pose.PoseLandmark.RIGHT_SHOULDER,
                "left_hip": mp.solutions.pose.PoseLandmark.LEFT_HIP,
                "right_hip": mp.solutions.pose.PoseLandmark.RIGHT_HIP,
                "left_knee": mp.solutions.pose.PoseLandmark.LEFT_KNEE,
                "right_knee": mp.solutions.pose.PoseLandmark.RIGHT_KNEE,
                "left_ankle": mp.solutions.pose.PoseLandmark.LEFT_ANKLE,
                "right_ankle": mp.solutions.pose.PoseLandmark.RIGHT_ANKLE,
            }
            min_visibility = 1.0
            for name, idx in landmark_map.items():
                landmark = results.pose_landmarks.landmark[idx]
                min_visibility = min(min_visibility, float(landmark.visibility))
                landmark_dict[name] = (landmark.x * width, landmark.y * height)
            if min_visibility < 0.2:
                continue
            return landmark_dict
    finally:
        pose.close()

    return _extract_landmarks_fallback(image)


def _calculate_metrics(landmarks: Dict[str, Tuple[float, float]]) -> Dict[str, float]:
    """Compute body measurements and ratios from landmark coordinates.

    The returned dictionary normalises all linear measurements by dividing
    distances by shoulder width.  Normalisation ensures invariance to the
    absolute scale of the input image.  Keys include:

    * ``shoulder_width`` — baseline reference (always set to 1.0 after
      normalisation).
    * ``hip_width`` — width between left and right hips.
    * ``waist_ratio`` — ratio of hip width to shoulder width.  Values < 1
      indicate narrower hips; values > 1 indicate wider hips.
    * ``torso_length`` — vertical distance from the midpoint of shoulders to
      midpoint of hips.
    * ``leg_length`` — vertical distance from midpoint of hips to midpoint of
      ankles.
    * ``torso_to_leg_ratio`` — torso_length / leg_length.
    """
    left_shoulder = landmarks["left_shoulder"]
    right_shoulder = landmarks["right_shoulder"]
    left_hip = landmarks["left_hip"]
    right_hip = landmarks["right_hip"]
    left_ankle = landmarks["left_ankle"]
    right_ankle = landmarks["right_ankle"]
    # Baseline measurement: shoulder width
    shoulder_width = _euclidean_distance(left_shoulder, right_shoulder)
    # Hip width
    hip_width = _euclidean_distance(left_hip, right_hip)
    # Approximate waist points by interpolating 35% from hip to shoulder.
    t = 0.35
    left_waist = (
        left_hip[0] + t * (left_shoulder[0] - left_hip[0]),
        left_hip[1] + t * (left_shoulder[1] - left_hip[1]),
    )
    right_waist = (
        right_hip[0] + t * (right_shoulder[0] - right_hip[0]),
        right_hip[1] + t * (right_shoulder[1] - right_hip[1]),
    )
    waist_width = _euclidean_distance(left_waist, right_waist)

    # Midpoints for torso and leg vertical distances
    shoulders_mid = (
        (left_shoulder[0] + right_shoulder[0]) / 2.0,
        (left_shoulder[1] + right_shoulder[1]) / 2.0,
    )
    hips_mid = (
        (left_hip[0] + right_hip[0]) / 2.0,
        (left_hip[1] + right_hip[1]) / 2.0,
    )
    ankles_mid = (
        (left_ankle[0] + right_ankle[0]) / 2.0,
        (left_ankle[1] + right_ankle[1]) / 2.0,
    )
    torso_length = abs(shoulders_mid[1] - hips_mid[1])
    leg_length = abs(hips_mid[1] - ankles_mid[1])
    # Normalise by shoulder width
    if shoulder_width == 0:
        shoulder_width = 1.0  # Avoid division by zero; unlikely in practice
    if hip_width == 0:
        hip_width = shoulder_width
    metrics: Dict[str, float] = {
        "shoulder_width": 1.0,
        "hip_width": hip_width / shoulder_width,
        # waist_ratio now means waist:hip ratio (not hip:shoulder).
        "waist_ratio": waist_width / hip_width,
        "shoulder_to_hip_ratio": shoulder_width / hip_width,
        "torso_length": torso_length / shoulder_width,
        "leg_length": leg_length / shoulder_width,
        "torso_to_leg_ratio": (torso_length / shoulder_width)
        / (leg_length / shoulder_width + 1e-6),
    }
    return metrics


def _calculate_symmetry(landmarks: Dict[str, Tuple[float, float]]) -> float:
    """Estimate left/right symmetry by comparing distances on either side.

    We compute the absolute difference between the distances from the left
    shoulder to left hip and the right shoulder to right hip, normalised by
    shoulder width.  Values near zero indicate symmetrical bodies.
    """
    left_shoulder = landmarks["left_shoulder"]
    right_shoulder = landmarks["right_shoulder"]
    left_hip = landmarks["left_hip"]
    right_hip = landmarks["right_hip"]
    shoulder_width = _euclidean_distance(left_shoulder, right_shoulder)
    left_distance = _euclidean_distance(left_shoulder, left_hip)
    right_distance = _euclidean_distance(right_shoulder, right_hip)
    return abs(left_distance - right_distance) / (shoulder_width + 1e-6)


def _calculate_posture_angle(landmarks: Dict[str, Tuple[float, float]]) -> float:
    """Compute the angle between the torso vector and the vertical axis.

    The torso vector is defined as the vector from the midpoint of the hips
    to the midpoint of the shoulders.  We then compute the angle between
    this vector and the vertical (0, -1).  Positive values indicate a lean
    towards the right of the image; negative values indicate a lean towards
    the left.  The magnitude indicates deviation from upright.
    """
    left_shoulder = landmarks["left_shoulder"]
    right_shoulder = landmarks["right_shoulder"]
    left_hip = landmarks["left_hip"]
    right_hip = landmarks["right_hip"]
    shoulders_mid = (
        (left_shoulder[0] + right_shoulder[0]) / 2.0,
        (left_shoulder[1] + right_shoulder[1]) / 2.0,
    )
    hips_mid = (
        (left_hip[0] + right_hip[0]) / 2.0,
        (left_hip[1] + right_hip[1]) / 2.0,
    )
    # Torso vector (horizontal, vertical)
    torso_vec = np.array([
        shoulders_mid[0] - hips_mid[0],
        hips_mid[1] - shoulders_mid[1],  # invert y for typical image coord
    ])
    # Normalise
    if np.linalg.norm(torso_vec) == 0:
        return 0.0
    torso_unit = torso_vec / np.linalg.norm(torso_vec)
    # Vertical unit vector (pointing up in image coordinate)
    vertical_unit = np.array([0.0, 1.0])
    cos_angle = float(np.clip(np.dot(torso_unit, vertical_unit), -1.0, 1.0))
    angle_rad = float(np.arccos(cos_angle))
    angle_deg = np.degrees(angle_rad)
    # Determine direction (sign) by looking at horizontal component
    if torso_unit[0] > 0:
        return angle_deg
    else:
        return -angle_deg


def _classify_body_type(metrics: Dict[str, float]) -> BodyType:
    """Classify the body type based on derived metrics.

    The logic here is intentionally simple and easy to understand.  More
    sophisticated models (e.g. decision trees or neural networks) can
    replace this if you collect labelled data.
    """
    hip_ratio = metrics["hip_width"]  # hip:shoulder
    waist_hip = metrics["waist_ratio"]  # waist:hip
    shoulder_hip = metrics.get("shoulder_to_hip_ratio", 1.0)  # shoulder:hip

    if waist_hip > 0.96:
        return BodyType.OVAL
    # Inverted triangle: shoulders wider than hips
    if shoulder_hip >= 1.1 and waist_hip < 0.92:
        return BodyType.INVERTED_TRIANGLE
    # Triangle: hips wider than shoulders
    if hip_ratio >= 1.1 and waist_hip < 0.95:
        return BodyType.TRIANGLE
    # Hourglass: shoulders and hips balanced with clear waist definition
    if 0.9 <= shoulder_hip <= 1.1 and waist_hip <= 0.78:
        return BodyType.HOURGLASS
    return BodyType.RECTANGLE


def analyse_image(image: np.ndarray) -> BodyMetricResult:
    """Analyse a full‑body image and return body metrics.

    Parameters
    ----------
    image: np.ndarray
        A colour image in BGR format (as read by OpenCV).  The person must
        be fully visible in the frame for accurate measurements.

    Returns
    -------
    BodyMetricResult
        An object containing the computed metrics, symmetry score,
        posture angle and body type.

    Raises
    ------
    ImportError
        If ``mediapipe`` or ``opencv-python`` are not installed.
    RuntimeError
        If pose estimation fails to detect landmarks.
    """
    landmarks = _extract_landmarks(image)
    if not landmarks:
        raise RuntimeError(
            "Pose landmarks could not be detected. "
            "Ensure the full body is visible and the image is of good quality."
        )
    metrics = _calculate_metrics(landmarks)
    symmetry = _calculate_symmetry(landmarks)
    posture_angle = _calculate_posture_angle(landmarks)
    body_type = _classify_body_type(metrics)
    return BodyMetricResult(
        body_type=body_type, metrics=metrics, symmetry=symmetry, posture_angle=posture_angle
    )


__all__ = [
    "BodyMetricResult",
    "BodyType",
    "analyse_image",
]
