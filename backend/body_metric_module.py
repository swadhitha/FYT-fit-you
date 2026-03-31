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
from typing import Dict, Tuple, Optional

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
            "metrics": self.metrics,
            "symmetry": self.symmetry,
            "posture_angle": self.posture_angle,
        }


def _euclidean_distance(p1: Tuple[float, float], p2: Tuple[float, float]) -> float:
    """Return the Euclidean distance between two 2D points."""
    return float(np.linalg.norm(np.array(p1) - np.array(p2)))


def _extract_landmarks(image: np.ndarray) -> Optional[Dict[str, Tuple[float, float]]]:
    """Run MediaPipe pose estimation on an image and return selected landmarks.

    The keys in the returned dictionary correspond to anatomical landmarks
    relevant to our body metric calculations: shoulders, hips, knees and
    ankles.  If pose estimation fails or MediaPipe is unavailable this
    function returns ``None``.
    """
    if mp is None or cv2 is None:
        raise ImportError(
            "MediaPipe and OpenCV are required for landmark extraction. "
            "Please install them with `pip install mediapipe opencv-python`."
        )
    # Convert to RGB because MediaPipe expects RGB images
    rgb_image = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
    pose = mp.solutions.pose.Pose(static_image_mode=True, model_complexity=1)
    results = pose.process(rgb_image)
    pose.close()
    if not results.pose_landmarks:
        return None
    landmark_dict: Dict[str, Tuple[float, float]] = {}
    # Mediapipe returns normalised coordinates (x,y) in [0,1] relative to image
    # width/height.  Multiply by actual width/height to get pixel coordinates.
    height, width = image.shape[:2]
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
    for name, idx in landmark_map.items():
        landmark = results.pose_landmarks.landmark[idx]
        landmark_dict[name] = (landmark.x * width, landmark.y * height)
    return landmark_dict


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
    metrics: Dict[str, float] = {
        "shoulder_width": 1.0,
        "hip_width": hip_width / shoulder_width,
        "waist_ratio": hip_width / shoulder_width,
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
    hip_ratio = metrics["hip_width"]
    waist_ratio = metrics["waist_ratio"]
    torso_leg_ratio = metrics["torso_to_leg_ratio"]
    # Example heuristic thresholds; these may need tuning with real data.
    # Inverted triangle: shoulders significantly wider than hips (>15%)
    if hip_ratio < 0.85:
        return BodyType.INVERTED_TRIANGLE
    # Triangle (pear): hips significantly wider than shoulders (>15%)
    if hip_ratio > 1.15:
        return BodyType.TRIANGLE
    # Hourglass: hips and shoulders similar, waist smaller
    if 0.85 <= hip_ratio <= 1.15 and waist_ratio < 0.95:
        return BodyType.HOURGLASS
    # Oval: waist wider than shoulders and hips
    if waist_ratio > 1.05:
        return BodyType.OVAL
    # Rectangle: otherwise
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