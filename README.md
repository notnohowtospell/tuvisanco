# FootballAI (Tử Vi Sân Cỏ) - Football Prediction & Betting App

Dự án này là không gian làm việc chính (monorepo-style) của nhóm cho đồ án môn **PRM393** (Kì 8). Thư mục này bao gồm cả **Frontend (Flutter)** và **Backend (NestJS + Docker PostgreSQL + WebSockets + Gemini AI)**.

---

## 📂 Cấu Trúc Thư Mục Dự Án

*   **`tuvisanco-frontend/`**: Ứng dụng di động (Android-only) viết bằng Flutter + Riverpod + GoRouter + Firebase Auth.
*   **`tuvisanco-backend/`**: Hệ thống API Server viết bằng NestJS + Prisma ORM + PostgreSQL + Socket.io + Firebase Admin.

---

## 🚀 Hướng Dẫn Khởi Chạy Nhanh Cho Cả Nhóm (Khi Pull Code Về)

### 1. Khởi động CSDL PostgreSQL (qua Docker)
Yêu cầu bật sẵn **Docker Desktop**.
1.  Mở terminal tại thư mục backend:
    ```bash
    cd tuvisanco-backend
    ```
2.  Chạy container cơ sở dữ liệu:
    ```bash
    docker-compose up -d
    ```
    *   pgAdmin sẽ khả dụng tại: `http://localhost:5050` (Email: `admin@tuvisanco.com` / Pass: `admin`).

### 2. Khởi chạy API Server NestJS
1.  Đảm bảo đã dừng (stop) API Server nếu đang chạy để không bị khóa file trong quá trình đồng bộ (EPERM error).
2.  Cấu hình tệp `.env` dựa theo tệp `.env.example`.
3.  Đẩy cấu hình DB schema mới cập nhật vào PostgreSQL và sinh client:
    ```bash
    npx prisma db push
    npx prisma generate
    ```
4.  Khởi chạy server ở chế độ phát triển:
    ```bash
    npm run start:dev
    ```
    *   *Mách nhỏ:* Kiểm tra kết nối database bằng cách truy cập `http://localhost:3000/matches` trên trình duyệt, nếu ra mảng `[]` là thành công.

### 3. Khởi chạy Ứng Dụng Flutter
1.  Di chuyển vào thư mục frontend:
    ```bash
    cd ../tuvisanco-frontend
    ```
2.  Đảm bảo máy ảo Android hoặc thiết bị thật đã được kết nối.
3.  Tải các thư viện và chạy ứng dụng:
    ```bash
    flutter pub get
    flutter run
    ```

---

## 🛠️ Quy Chuẩn & Mã Mẫu Đã Dựng Sẵn

Để giúp nhóm phát triển nhanh và đồng nhất, tôi đã viết sẵn các tệp tin nền móng quan trọng sau:

### Phía Backend (`tuvisanco-backend/`)
*   **Kết nối CSDL**: Module Prisma dùng chung tại `src/prisma/`.
*   **Đăng ký & Xác thực Firebase Auth**: Lớp xử lý token của Google tại **[auth.service.ts](file:///D:/tuvisanco/tuvisanco-backend/src/modules/auth/auth.service.ts)**.
*   **Thuật toán tính điểm dự đoán bóng đá**: Logic tính điểm chính xác, hiệu số và kết quả theo quy chuẩn website được lập trình tại **[predictions.service.ts](file:///D:/tuvisanco/tuvisanco-backend/src/modules/predictions/predictions.service.ts)**.
*   **WebSockets Realtime Gateway**: Khung Socket.io room điều khiển realtime trong phòng chờ nhóm bạn bè tại **[lobbies.gateway.ts](file:///D:/tuvisanco/tuvisanco-backend/src/modules/lobbies/lobbies.gateway.ts)**.
*   **Phân tích Gemini AI**: Nhận định xác suất tự động lưu cache được lập trình tại **[ai.service.ts](file:///D:/tuvisanco/tuvisanco-backend/src/modules/ai/ai.service.ts)**.

### Phía Frontend (`tuvisanco-frontend/`)
*   **Định tuyến & Trang Mock**: Khai báo GoRouter và 5 màn hình mock ban đầu tại **[router.dart](file:///D:/tuvisanco/tuvisanco-frontend/lib/app/router.dart)**.
*   **Bảng màu Dark/Light Mode**: Màu xanh sân cỏ Material 3 cấu hình tại **[theme.dart](file:///D:/tuvisanco/tuvisanco-frontend/lib/app/theme.dart)**.
*   **Dio Client (HTTP)**: Tệp gọi API cấu hình tại **[dio_client.dart](file:///D:/tuvisanco/tuvisanco-frontend/lib/core/network/dio_client.dart)**.
*   **Socket.io Client**: Tệp kết nối realtime trong phòng chờ nhóm bạn bè viết tại **[socket_service.dart](file:///D:/tuvisanco/tuvisanco-frontend/lib/features/lobbies/data/socket_service.dart)**.
