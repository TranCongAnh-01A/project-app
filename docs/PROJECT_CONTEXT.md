# MoneJour — Project Context (Bản Đồ Trí Nhớ)

> Cập nhật: 2026-05-07 | Phiên bản: v1.0.0 (MVP) | Platform: Android, iOS

---

## 1. Tổng Quan Dự Án

**MoneJour (Money + Journal)** — Ứng dụng quản lý chi tiêu cá nhân kết hợp nhật ký cảm xúc.
100% offline, không cần server, không cần internet.

### Kiến Trúc

```
┌───────────────────────────────────────────┐
│            Flutter Mobile App             │
│  ┌──────────┐  ┌──────────┐  ┌────────┐  │
│  │  Cubits   │  │   UI     │  │ Charts │  │
│  │ (State)   │  │ (Screen) │  │(fl_ch) │  │
│  └─────┬─────┘  └──────────┘  └────────┘  │
│        │                                   │
│  ┌─────▼──────────────────────┐            │
│  │     Repositories           │            │
│  │  (ExpenseRepo, JournalRepo)│            │
│  └─────┬──────────────────────┘            │
│        │                                   │
│  ┌─────▼─────┐                             │
│  │ Isar DB   │ ← Local NoSQL (on-device)   │
│  └───────────┘                             │
└───────────────────────────────────────────┘
```

**KHÔNG CÓ:** Backend, Server, API, Docker, Cloud Database.

---

## 2. Tech Stack

| Tầng | Công nghệ | Vai trò |
|------|-----------|---------|
| **Framework** | Flutter 3.19+ / Dart 3.3+ | Cross-platform mobile |
| **Database** | Isar 3.1 (NoSQL) | Local storage, offline-first |
| **State Mgmt** | flutter_bloc (Cubit) | Quản lý state theo Cubit pattern |
| **Charts** | fl_chart | Biểu đồ tròn/cột thống kê chi tiêu |
| **Format** | intl | Format tiền VND + ngày tháng |
| **Utilities** | path_provider, uuid | File path + unique ID |

---

## 3. Cấu Trúc Thư Mục

```
mone_jour/
├── lib/
│   ├── main.dart                          # Entry point + Isar init
│   ├── core/
│   │   ├── constants/
│   │   │   └── categories.dart            # 9 danh mục chi tiêu mặc định
│   │   ├── theme/
│   │   │   └── app_theme.dart             # Dark/Light theme, Material 3
│   │   └── utils/
│   │       ├── currency_formatter.dart    # Format VND (1.500.000 ₫)
│   │       └── date_formatter.dart        # Format ngày tiếng Việt
│   ├── data/
│   │   ├── models/
│   │   │   ├── expense.dart               # Isar Collection: chi tiêu
│   │   │   ├── expense.g.dart             # Generated
│   │   │   ├── journal_entry.dart         # Isar Collection: nhật ký
│   │   │   └── journal_entry.g.dart       # Generated
│   │   └── repositories/
│   │       ├── expense_repository.dart    # CRUD + thống kê chi tiêu
│   │       └── journal_repository.dart    # CRUD + filter nhật ký
│   ├── logic/                             # Cubits (TODO — Phase tiếp)
│   │   ├── expense/
│   │   ├── journal/
│   │   ├── stats/
│   │   └── settings/
│   ├── services/
│   │   └── database_service.dart          # Isar Singleton
│   └── ui/                                # Screens + Widgets (TODO)
│       ├── screens/
│       │   ├── home/
│       │   ├── expense/
│       │   ├── journal/
│       │   ├── stats/
│       │   └── settings/
│       ├── widgets/
│       └── navigation/
├── pubspec.yaml
└── test/
```

---

## 4. Data Models

### Expense (Chi tiêu)
| Field | Type | Ghi chú |
|-------|------|---------|
| id | int (auto) | Isar auto-increment |
| amount | double | Số tiền VND |
| category | String (indexed) | Mã danh mục (food, transport...) |
| note | String? | Ghi chú tùy chọn |
| date | DateTime (indexed) | Ngày giao dịch |
| isIncome | bool | true = thu nhập, false = chi tiêu |
| createdAt | DateTime | Thời điểm tạo |

### JournalEntry (Nhật ký)
| Field | Type | Ghi chú |
|-------|------|---------|
| id | int (auto) | Isar auto-increment |
| title | String | Tiêu đề |
| content | String | Nội dung nhật ký |
| mood | int (1-5, indexed) | 1=Rất tệ → 5=Tuyệt vời |
| date | DateTime (indexed) | Ngày viết |
| imagePath | String? | Ảnh đính kèm (Phase 2) |
| createdAt | DateTime | Thời điểm tạo |

---

## 5. Danh Mục Chi Tiêu Mặc Định

| ID | Tên | Icon | Color |
|----|-----|------|-------|
| food | Ăn uống | 🍽️ restaurant | #FF6B6B |
| transport | Di chuyển | 🚗 directions_car | #4ECDC4 |
| shopping | Mua sắm | 🛍️ shopping_bag | #FFE66D |
| entertainment | Giải trí | 🎬 movie | #A78BFA |
| bills | Hóa đơn | 🧾 receipt_long | #60A5FA |
| health | Sức khỏe | ❤️ favorite | #F472B6 |
| education | Học tập | 🎓 school | #34D399 |
| income | Thu nhập | 💰 account_balance_wallet | #10B981 |
| other | Khác | ··· more_horiz | #94A3B8 |

---

## 6. Trạng Thái Module

### ✅ Hoàn thành (Nền tảng)
| Module | File | Ghi chú |
|--------|------|---------|
| Flutter Project | `mone_jour/` | Khởi tạo sạch, 0 lỗi analyze |
| Isar Database | `database_service.dart` | Singleton, auto-init |
| Expense Model | `expense.dart` + `.g.dart` | Collection + Code gen OK |
| Journal Model | `journal_entry.dart` + `.g.dart` | Collection + Code gen OK |
| Expense Repository | `expense_repository.dart` | CRUD + thống kê + watch |
| Journal Repository | `journal_repository.dart` | CRUD + filter mood + watch |
| Categories | `categories.dart` | 9 danh mục mặc định |
| Theme | `app_theme.dart` | Dark/Light, Material 3 |
| Formatters | `currency_formatter.dart`, `date_formatter.dart` | VND + ngày VN |

### ⏳ Tiếp theo (Cần làm)
| Module | Thư mục | Mô tả |
|--------|---------|-------|
| Cubits | `logic/` | State management cho từng feature |
| Màn hình | `ui/screens/` | 7 screens MVP |
| Widgets | `ui/widgets/` | Cards, pickers, charts |
| Navigation | `ui/navigation/` | Bottom nav bar |

---

## 7. Roadmap

### Phase 1: MVP
- [x] Khởi tạo project + Isar database
- [x] Data models + Repositories
- [x] Theme system + Formatters
- [ ] Cubits (Expense, Journal, Stats, Settings)
- [ ] Home Dashboard
- [ ] CRUD Chi tiêu (thêm/sửa/xóa)
- [ ] CRUD Nhật ký (thêm/sửa/xóa + mood)
- [ ] Biểu đồ thống kê (tròn + cột)
- [ ] Bottom Navigation
- [ ] Dark/Light theme toggle

### Phase 2: Nâng cao
- [ ] Export/Import JSON backup
- [ ] Local notifications nhắc ghi chép
- [ ] Ảnh đính kèm nhật ký
- [ ] Custom categories
- [ ] PIN/Biometrics lock
- [ ] Search + Filter nâng cao
- [ ] Android Widget

---

## 8. State Management: Cubit (flutter_bloc)

**Tại sao chọn Cubit thay vì Riverpod hoặc GetX:**

| Tiêu chí | Cubit | Riverpod | GetX |
|----------|-------|----------|------|
| Quen thuộc (từ PMKA) | ✅ Đã dùng | ❌ Phải học mới | ❌ Phải học mới |
| Tách biệt logic/UI | ✅ Rõ ràng | ✅ Rõ ràng | ⚠️ Dễ trộn lẫn |
| Testability | ✅ Dễ mock | ✅ Dễ mock | ❌ Khó test |
| Boilerplate | ⚠️ Trung bình | ✅ Ít | ✅ Ít |
| Cộng đồng | ✅ Lớn | ✅ Lớn | ⚠️ Gây tranh cãi |
| Phù hợp CRUD app | ✅ Hoàn hảo | ✅ Tốt | ⚠️ Overkill |

**Kết luận:** Cubit là lựa chọn tối ưu — bạn đã quen, clean architecture, dễ test.
