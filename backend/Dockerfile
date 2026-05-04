# === PMKA Backend ===
# Python 3.12 + FFmpeg + yt-dlp (luôn bản mới nhất)
FROM python:3.12-slim

# Cài đặt ffmpeg qua apt-get cho xử lý audio
RUN apt-get update && apt-get install -y --no-install-recommends \
    ffmpeg \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy và cài đặt Python dependencies trước để tận dụng Docker cache layer
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Luôn nâng cấp yt-dlp lên bản mới nhất khi build image
# Vì YouTube thường xuyên thay đổi API, bản cũ sẽ bị chặn
RUN pip install -U yt-dlp

# Xác minh ffmpeg và yt-dlp đã sẵn sàng
RUN ffmpeg -version && yt-dlp --version

# Copy source code
COPY . .

# Tạo thư mục storage và cấp quyền ghi đầy đủ
RUN mkdir -p /app/storage && chmod -R 777 /app/storage

EXPOSE 8000

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]
