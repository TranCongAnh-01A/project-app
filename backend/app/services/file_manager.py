"""
Service: Quản lý lưu trữ file trên Cloud/Server.
Tầng trừu tượng giữa business logic và filesystem thực tế.
"""
import os
from pathlib import Path

# Thư mục gốc lưu trữ (mount bằng Docker volume)
STORAGE_ROOT = Path("/app/storage")


async def save_file(user_id: str, filename: str, data: bytes) -> str:
    """
    Lưu file vào storage theo cấu trúc: /storage/{user_id}/{filename}

    Tại sao tách riêng file_manager thay vì lưu trực tiếp trong service:
    - Dễ swap giữa local storage ↔ S3/MinIO sau này
    - Một nơi duy nhất quản lý path, tránh hardcode rải rác
    """
    # TODO: Tạo thư mục user → ghi file → trả về path
    raise NotImplementedError("Chưa triển khai file manager")


async def get_file_path(user_id: str, filename: str) -> Path:
    """Trả về đường dẫn tuyệt đối của file trong storage."""
    return STORAGE_ROOT / user_id / filename


async def delete_file(user_id: str, filename: str) -> bool:
    """Xóa file khỏi storage. Trả về True nếu xóa thành công."""
    # TODO: Kiểm tra tồn tại → xóa → trả về kết quả
    raise NotImplementedError("Chưa triển khai file deletion")
