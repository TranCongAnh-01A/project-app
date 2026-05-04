"""
API Endpoints: Dành riêng cho trang quản trị Admin-Web.
Bao gồm: thống kê hệ thống, quản lý user, quản lý nội dung.
"""
from fastapi import APIRouter

router = APIRouter(prefix="/admin", tags=["Admin"])


@router.get("/stats")
async def system_stats():
    """Thống kê CPU, RAM, dung lượng ổ cứng Server."""
    # TODO: Gọi admin_service để lấy metrics hệ thống
    return {"cpu": 0, "ram": 0, "disk": 0}


@router.get("/users")
async def list_users():
    """Lấy danh sách tất cả tài khoản người dùng."""
    # TODO: Query DB → trả về danh sách users
    return {"users": []}


@router.delete("/content/{content_id}")
async def delete_content(content_id: str):
    """Xóa nội dung cụ thể khỏi hệ thống."""
    # TODO: Xóa record DB + file storage
    return {"message": "deleted", "content_id": content_id}
