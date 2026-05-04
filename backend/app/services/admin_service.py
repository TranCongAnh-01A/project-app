"""
Service: Thống kê hệ thống và dọn dẹp storage.
Cung cấp dữ liệu cho trang Admin Dashboard.
"""
import os


async def get_system_stats() -> dict:
    """
    Thu thập metrics: CPU, RAM, dung lượng ổ cứng.
    Admin Dashboard dùng endpoint /admin/stats gọi hàm này.
    """
    # TODO: Dùng psutil để lấy CPU%, RAM%, disk usage
    # hoặc đọc từ /proc trên Linux container
    raise NotImplementedError("Chưa triển khai system stats")


async def cleanup_storage(older_than_days: int = 30) -> dict:
    """
    Dọn dẹp file audio/text cũ không ai truy cập.
    Admin có thể trigger thủ công hoặc chạy theo cron.
    """
    # TODO: Quét thư mục storage → xóa file quá hạn
    raise NotImplementedError("Chưa triển khai storage cleanup")
