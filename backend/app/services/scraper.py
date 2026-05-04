"""
Service: Cào nội dung truyện chữ từ URL.
Dùng BeautifulSoup + lxml để parse HTML → trích xuất văn bản.
"""
import httpx
from bs4 import BeautifulSoup


async def scrape_text_content(url: str) -> dict:
    """
    Cào nội dung chữ từ URL.
    Luồng: Fetch HTML → Parse DOM → Trích xuất text chính → Trả về dict.

    Tại sao dùng httpx thay requests:
    - httpx hỗ trợ async, phù hợp với FastAPI async ecosystem
    - Tránh block event loop khi cào nhiều trang đồng thời
    """
    # TODO: Triển khai logic cào nội dung
    # 1. Fetch HTML bằng httpx (async)
    # 2. Parse bằng BeautifulSoup + lxml
    # 3. Xác định vùng nội dung chính (tránh cào header/footer/ads)
    # 4. Trả về: title, content, chapter_list (nếu là truyện nhiều chương)
    raise NotImplementedError("Chưa triển khai scraper")
