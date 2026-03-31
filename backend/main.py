"""
FastAPI server for the FYT AI Personal Styling Application.

Registers all API routers and initializes the database on startup.

To run:
    cd backend
    pip install -r requirements.txt
    uvicorn main:app --reload --host 0.0.0.0 --port 8000
"""

from __future__ import annotations

import os
from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
import numpy as np

try:
    import cv2  # type: ignore
except ImportError:
    cv2 = None  # type: ignore

from database import init_database, insert_sample_data, get_connection
from body_metric_module import analyse_image, BodyMetricResult

# Import routers
from routers import users, body_profile, wardrobe, recommendations, chat, preferences

# ─── App Setup ────────────────────────────────────────────────

app = FastAPI(
    title="FYT — AI Personal Styling API",
    description="Backend API for the FYT personal styling mobile application. "
                "Provides body metric analysis, wardrobe management, outfit recommendations, "
                "and an explainable AI chatbot.",
    version="1.0.0",
)

# CORS — allow all origins for development
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Static file serving for uploaded wardrobe images
UPLOAD_DIR = os.path.join(os.path.dirname(__file__), "uploads")
os.makedirs(UPLOAD_DIR, exist_ok=True)
app.mount("/uploads", StaticFiles(directory=UPLOAD_DIR), name="uploads")

# ─── Register Routers ────────────────────────────────────────

app.include_router(users.router)
app.include_router(body_profile.router)
app.include_router(wardrobe.router)
app.include_router(recommendations.router)
app.include_router(chat.router)
app.include_router(preferences.router)

# ─── Startup Event ────────────────────────────────────────────

@app.on_event("startup")
async def startup():
    """Initialize database and insert sample data on startup."""
    init_database()
    insert_sample_data()


# ─── Legacy Endpoint (kept for backward compatibility) ────────

@app.post("/body-metrics", response_model=None)
async def body_metrics(file: UploadFile = File(...)) -> dict:
    """Legacy endpoint: Analyse a user-uploaded image and return body metrics."""
    if cv2 is None:
        raise HTTPException(status_code=500, detail="OpenCV is not installed on the server.")

    image_bytes = await file.read()
    image_np = np.frombuffer(image_bytes, dtype=np.uint8)
    image = cv2.imdecode(image_np, cv2.IMREAD_COLOR)

    if image is None:
        raise HTTPException(status_code=400, detail="Uploaded file is not a valid image.")

    try:
        result: BodyMetricResult = analyse_image(image)
    except ImportError as e:
        raise HTTPException(status_code=500, detail=str(e))
    except RuntimeError as e:
        raise HTTPException(status_code=400, detail=str(e))

    return result.as_dict()


@app.get("/healthz")
async def health() -> dict:
    """Health check endpoint."""
    return {"status": "ok", "service": "FYT API", "version": "1.0.0"}


@app.get("/diagnostics")
async def diagnostics() -> dict:
    """Runtime diagnostics for DB, modules, and dataset availability."""
    table_counts: dict[str, int] = {}
    db_ok = True
    db_error = None

    try:
        conn = get_connection()
        cursor = conn.cursor()
        for table in [
            "users",
            "body_profile",
            "wardrobe_items",
            "user_preferences",
            "recommendations",
            "chat_logs",
        ]:
            table_counts[table] = cursor.execute(
                f"SELECT COUNT(*) FROM {table}"
            ).fetchone()[0]
        conn.close()
    except Exception as e:
        db_ok = False
        db_error = str(e)

    try:
        import mediapipe  # type: ignore
        mediapipe_available = True
    except ImportError:
        mediapipe_available = False

    return {
        "service": "FYT API",
        "db": {"ok": db_ok, "error": db_error, "table_counts": table_counts},
        "modules": {
            "opencv_available": cv2 is not None,
            "mediapipe_available": mediapipe_available,
        },
        "datasets": {
            "external_pretrained": ["MediaPipe Pose landmarks"],
            "application_data_sources": [
                "user profile data",
                "user wardrobe metadata",
                "chat feedback and preference signals",
                "recommendation history logs",
            ],
        },
    }


@app.get("/")
async def root():
    """Root endpoint with API info."""
    return {
        "message": "FYT — AI Personal Styling API",
        "docs": "/docs",
        "health": "/healthz",
        "endpoints": {
            "users": "/api/users",
            "body_profile": "/api/body-profile",
            "wardrobe": "/api/wardrobe",
            "recommendations": "/api/recommendations",
            "chat": "/api/chat",
            "preferences": "/api/preferences",
        },
    }
