"""
User management API endpoints.
"""

from fastapi import APIRouter, HTTPException
import hashlib
from database import get_connection
from models.schemas import UserCreate, UserLogin, UserResponse, UserUpdate

router = APIRouter(prefix="/api/users", tags=["Users"])


def _hash_password(password: str) -> str:
    """Simple SHA-256 hash for academic purposes."""
    return hashlib.sha256(password.encode()).hexdigest()


@router.post("/register", response_model=UserResponse)
async def register(user: UserCreate):
    """Register a new user."""
    conn = get_connection()
    cursor = conn.cursor()

    # Check if email exists
    existing = cursor.execute(
        "SELECT id FROM users WHERE email = ?", (user.email,)
    ).fetchone()
    if existing:
        conn.close()
        raise HTTPException(status_code=400, detail="Email already registered.")

    cursor.execute(
        """INSERT INTO users (name, email, password_hash, style_preference, climate_region)
           VALUES (?, ?, ?, ?, ?)""",
        (user.name, user.email, _hash_password(user.password),
         user.style_preference, user.climate_region),
    )
    user_id = cursor.lastrowid

    # Create default preferences
    cursor.execute(
        "INSERT INTO user_preferences (user_id) VALUES (?)", (user_id,)
    )
    conn.commit()

    result = cursor.execute(
        "SELECT * FROM users WHERE id = ?", (user_id,)
    ).fetchone()
    conn.close()

    return UserResponse(
        id=result["id"], name=result["name"], email=result["email"],
        style_preference=result["style_preference"],
        climate_region=result["climate_region"],
        created_at=result["created_at"],
    )


@router.post("/login", response_model=UserResponse)
async def login(credentials: UserLogin):
    """Login with email and password."""
    conn = get_connection()
    cursor = conn.cursor()

    user = cursor.execute(
        "SELECT * FROM users WHERE email = ? AND password_hash = ?",
        (credentials.email, _hash_password(credentials.password)),
    ).fetchone()
    conn.close()

    if not user:
        raise HTTPException(status_code=401, detail="Invalid email or password.")

    return UserResponse(
        id=user["id"], name=user["name"], email=user["email"],
        style_preference=user["style_preference"],
        climate_region=user["climate_region"],
        created_at=user["created_at"],
    )


@router.get("/{user_id}", response_model=UserResponse)
async def get_user(user_id: int):
    """Get user profile by ID."""
    conn = get_connection()
    user = conn.execute("SELECT * FROM users WHERE id = ?", (user_id,)).fetchone()
    conn.close()

    if not user:
        raise HTTPException(status_code=404, detail="User not found.")

    return UserResponse(
        id=user["id"], name=user["name"], email=user["email"],
        style_preference=user["style_preference"],
        climate_region=user["climate_region"],
        created_at=user["created_at"],
    )


@router.put("/{user_id}", response_model=UserResponse)
async def update_user(user_id: int, update: UserUpdate):
    """Update user profile."""
    conn = get_connection()
    cursor = conn.cursor()

    user = cursor.execute("SELECT * FROM users WHERE id = ?", (user_id,)).fetchone()
    if not user:
        conn.close()
        raise HTTPException(status_code=404, detail="User not found.")

    updates = {}
    if update.name is not None:
        updates["name"] = update.name
    if update.style_preference is not None:
        updates["style_preference"] = update.style_preference
    if update.climate_region is not None:
        updates["climate_region"] = update.climate_region

    if updates:
        set_clause = ", ".join(f"{k} = ?" for k in updates.keys())
        cursor.execute(
            f"UPDATE users SET {set_clause} WHERE id = ?",
            (*updates.values(), user_id),
        )
        conn.commit()

    user = cursor.execute("SELECT * FROM users WHERE id = ?", (user_id,)).fetchone()
    conn.close()

    return UserResponse(
        id=user["id"], name=user["name"], email=user["email"],
        style_preference=user["style_preference"],
        climate_region=user["climate_region"],
        created_at=user["created_at"],
    )
