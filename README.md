# ⚽ FootballAI (Tử Vi Sân Cỏ) - Monorepo Workspace

FootballAI là ứng dụng di động hỗ trợ dự đoán tỷ số miễn phí (Luồng A) và tổ chức phòng đặt cược nhóm riêng tư thời gian thực (Luồng B - Core) dành cho những người yêu thích bóng đá. Dự án được phát triển theo mô hình Monorepo chứa cả mã nguồn Frontend và Backend phục vụ cho đồ án môn **PRM393** (Kỳ 8).

---

## 📂 Cấu Trúc Thư Mục Dự Án (Project Directory Tree)

Dưới đây là sơ đồ tổ chức thư mục của dự án để các thành viên dễ dàng định vị mã nguồn:

```text
tuvisanco/
├── tuvisanco-backend/             # API Server NestJS
│   ├── prisma/                    # Cấu hình CSDL & Schema Prisma
│   │   └── schema.prisma          # Thực thể DB (User, BettingRoom, BetMarket...)
│   ├── src/
│   │   ├── prisma/                # Prisma Service kết nối CSDL toàn cục
│   │   ├── modules/               # Các phân hệ nghiệp vụ chính (Full-Stack)
│   │   │   ├── auth/              # Xác thực Firebase Token & Đăng nhập Google
│   │   │   ├── users/             # Quản lý Profile & BXH Global
│   │   │   ├── matches/           # Đồng bộ lịch thi đấu (API-Football)
│   │   │   ├── predictions/       # Dự đoán miễn phí & Streak Points Engine
│   │   │   ├── lobbies/           # Phòng cược & Socket.io WebSockets Gateway
│   │   │   ├── ai/                # Nhận định phân tích Gemini AI
│   │   │   └── news/              # Bản tin bóng đá News Feed
│   │   ├── app.module.ts          # Đăng ký kết nối toàn bộ các module
│   │   └── main.ts                # Điểm khởi chạy API Server
│   ├── docker-compose.yml         # Container PostgreSQL & pgAdmin
│   ├── package.json
│   └── tsconfig.json
├── tuvisanco-frontend/            # Mobile App Client (Flutter)
│   ├── android/                   # Cấu hình Native Android (Gradle, Keystore)
│   ├── lib/
│   │   ├── app/                   # Cấu hình cốt lõi (Giao diện Theme, GoRouter)
│   │   ├── core/                  # Thư viện dùng chung (Dio HTTP Client, Widgets)
│   │   ├── features/              # Các phân hệ tính năng theo chiều dọc (UI/UX)
│   │   │   ├── auth/              # Login/Register UI & Firebase Auth Client
│   │   │   ├── matches/           # Tab Lịch thi đấu & Màn chi tiết trận đấu
│   │   │   ├── predictions/       # Phiếu cược (Bet Slip) & Form nhập dự đoán
│   │   │   ├── lobbies/           # Phòng cược nhóm & Socket.io Client
│   │   │   ├── leaderboard/       # Giao diện Bảng xếp hạng Top 50 toàn cầu
│   │   │   └── news/              # Giao diện danh sách & chi tiết tin tức
│   │   └── main.dart              # Khởi chạy app bọc trong Riverpod ProviderScope
│   ├── pubspec.yaml               # Quản lý dependencies & tài nguyên của App
│   └── README.md
└── README.md                      # Tài liệu hướng dẫn tổng quan Monorepo
```

---

## 🛠️ Công Nghệ Sử Dụng (Technology Stack)

*   **Frontend Mobile:** Flutter SDK, Riverpod (Quản lý trạng thái), GoRouter (Định tuyến màn hình), Dio (REST Client), Socket.io Client (Realtime), Firebase Auth & Google Sign-In SDK.
*   **Backend Server:** NestJS framework, Prisma ORM, Socket.io (WebSockets Gateway), Firebase Admin SDK.
*   **Database & DevOps:** PostgreSQL 15, pgAdmin 4, Docker, Docker Compose.
*   **AI Integration:** Google Gemini API (`gemini-1.5-flash`).

---

## 🚀 Hướng Dẫn Cài Đặt & Khởi Chạy (Quick Start)

### 📋 Yêu Cầu Hệ Thống (Prerequisites)
Đảm bảo máy tính của bạn đã cài đặt sẵn:
*   [Docker Desktop](https://www.docker.com/products/docker-desktop/) (Đã mở chạy)
*   [Node.js](https://nodejs.org/) (Phiên bản v18 trở lên)
*   [Flutter SDK](https://docs.flutter.dev/get-started/install) (Phiên bản 3.22+ trở lên)
*   Thiết bị di động Android hoặc máy ảo Android (Emulator)

---

### Bước 1: Khởi động Database PostgreSQL (Docker)
1.  Mở Terminal tại thư mục gốc dự án và di chuyển vào thư mục backend:
    ```bash
    cd tuvisanco-backend
    ```
2.  Chạy container PostgreSQL dưới nền:
    ```bash
    docker-compose up -d
    ```
    *   *pgAdmin* sẽ khả dụng tại địa chỉ: `http://localhost:5050` (Email: `admin@tuvisanco.com` / Pass: `admin`).

---

### Bước 2: Đồng bộ CSDL & Chạy Server NestJS
1.  Tạo tệp cấu hình `.env` từ tệp `.env.example` và điều chỉnh các API keys cần thiết.
2.  Đẩy cấu hình bảng dữ liệu vào PostgreSQL và sinh mã nguồn Prisma Client:
    ```bash
    npx prisma db push
    npx prisma generate
    ```
3.  Khởi chạy máy chủ phát triển NestJS:
    ```bash
    npm run start:dev
    ```
    *(Mặc định máy chủ sẽ chạy tại cổng `3000`)*.

---

### Bước 3: Khởi chạy Ứng dụng di động Flutter
1.  Mở một cửa sổ Terminal mới và di chuyển vào thư mục frontend:
    ```bash
    cd tuvisanco-frontend
    ```
2.  Tải các gói thư viện Flutter cần thiết:
    ```bash
    flutter pub get
    ```
3.  Kết nối thiết bị và chạy ứng dụng:
    ```bash
    flutter run
    ```

---

## 🤝 Quy Tắc Đóng Góp Code & Làm Việc Nhóm (Git Workflow)

Để tránh xung đột code (conflict) khi 4 thành viên cùng làm việc, nhóm thống nhất tuân thủ quy chuẩn sau:

### 1. Quy tắc đặt tên Nhánh (Branch Naming Convention)
Mỗi thành viên làm việc trên một nhánh riêng biệt được đặt tên theo cú pháp:
*   `feature/<tên-thành-viên>-<tên-chức-năng>` (Ví dụ: `feature/huy-room-betting`, `feature/cuong-ai-matches`)
*   `fix/<tên-thành-viên>-<tên-lỗi>` (Ví dụ: `fix/duc-auth-token`)

### 2. Quy chuẩn thông điệp Commit (Conventional Commits)
Thông điệp commit cần ngắn gọn và chỉ rõ mục đích chỉnh sửa theo chuẩn:
*   `feat: <nội dung>` (Thêm một tính năng mới)
*   `fix: <nội dung>` (Sửa một lỗi biên dịch/chạy thử)
*   `docs: <nội dung>` (Cập nhật tài liệu README hoặc comment)
*   `refactor: <nội dung>` (Tái cấu trúc mã nguồn không thay đổi logic chạy)

### 3. Quy trình Merge Code
1.  Hoàn thành tính năng ở nhánh local của mình.
2.  Chạy thử dự án trên máy local đảm bảo không phát sinh lỗi biên dịch (`0 errors`).
3.  Push nhánh lên GitHub và tạo **Pull Request (PR)** để Trưởng nhóm (Huy) duyệt trước khi gộp vào nhánh chính `main`.
