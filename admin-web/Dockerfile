# === PMKA Admin Web ===
# Node 22 LTS + React dev server
FROM node:22-alpine

WORKDIR /app

# Cài đặt dependencies trước để tận dụng Docker cache layer
COPY package.json package-lock.json* ./
RUN npm install

# Copy source code
COPY . .

EXPOSE 5173

# Khởi chạy Vite dev server, mở host 0.0.0.0 để Docker có thể expose port
CMD ["npm", "run", "dev", "--", "--host", "0.0.0.0"]
