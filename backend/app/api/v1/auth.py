"""
API Endpoints: Xác thực người dùng (Đăng ký, Đăng nhập).
"""
from fastapi import APIRouter

router = APIRouter(prefix="/auth", tags=["Auth"])


@router.post("/register")
async def register():
    """Đăng ký tài khoản mới."""
    # TODO: Triển khai logic đăng ký
    return {"message": "register endpoint"}


@router.post("/login")
async def login():
    """Đăng nhập và trả về JWT token."""
    # TODO: Triển khai logic đăng nhập
    return {"message": "login endpoint"}
