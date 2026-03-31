"""
FastAPI server exposing the Body Metric analysis endpoint.

This script defines a simple REST API that allows clients to upload a
photograph of a person and receive a JSON response containing body
measurements and classification.  The API relies on the logic defined in
``body_metric_module.py`` and illustrates how to integrate the module into a
web service.  For persistence (e.g. storing the resulting profile in a
database) you can extend the endpoint to insert ``BodyMetricResult`` into
MySQL or another storage system.

To run this API locally install the dependencies and start Uvicorn::

    pip install fastapi uvicorn mediapipe opencv-python numpy
    uvicorn main:app --reload

Then send a POST request to ``/body-metrics`` with an image file.  A
successful response will look like::

    {
        "body_type": "rectangle",
        "metrics": {
            "shoulder_width": 1.0,
            "hip_width": 0.98,
            "waist_ratio": 0.98,
            "torso_length": 0.82,
            "leg_length": 1.14,
            "torso_to_leg_ratio": 0.72
        },
        "symmetry": 0.03,
        "posture_angle": -1.5
    }

If the pose cannot be detected the server will return a 400 error.  The
endpoint is synchronous for simplicity; for production you may wish to run
landmark extraction in a thread pool.
"""

from __future__ import annotations

import io
from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.middleware.cors import CORSMiddleware
import numpy as np

try:
    import cv2  # type: ignore
except ImportError:
    cv2 = None  # type: ignore

from body_metric_module import analyse_image, BodyMetricResult

app = FastAPI(title="Body Metric API", description="Analyse body metrics from full‑body images.")

# Allow CORS from any origin (for development).  Adjust as needed for your
# production environment.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.post("/body-metrics", response_model=None)
async def body_metrics(file: UploadFile = File(...)) -> dict:
    """Analyse a user‑uploaded image and return body metrics.

    This endpoint expects a multipart/form‑data request with a single file field
    named ``file``.  The server reads the image bytes, decodes them with
    OpenCV and feeds the result into ``analyse_image``.  If the pose
    extraction fails (e.g. because the person is not fully visible) a 400
    response is returned.
    """
    # Ensure we have OpenCV available.  Without it we cannot decode images.
    if cv2 is None:
        raise HTTPException(status_code=500, detail="OpenCV is not installed on the server.")
    # Read file into bytes and convert to numpy array
    image_bytes = await file.read()
    image_np = np.frombuffer(image_bytes, dtype=np.uint8)
    image = cv2.imdecode(image_np, cv2.IMREAD_COLOR)
    if image is None:
        raise HTTPException(status_code=400, detail="Uploaded file is not a valid image.")
    try:
        result: BodyMetricResult = analyse_image(image)
    except ImportError as e:
        # Mediapipe not installed or another import issue
        raise HTTPException(status_code=500, detail=str(e))
    except RuntimeError as e:
        raise HTTPException(status_code=400, detail=str(e))
    return result.as_dict()


@app.get("/healthz")
async def health() -> dict:
    """Simple health check endpoint for monitoring."""
    return {"status": "ok"}