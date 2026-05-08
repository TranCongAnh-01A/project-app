# MoneJour — Project Context (Bản Đồ Trí Nhớ)

> Cập nhật: 2026-05-08 | Phiên bản: v1.0.0 (MVP) | Platform: Android, iOS
> Quét toàn bộ codebase: 36 files source | ~3,500+ dòng code (không tính generated)

---

## 1. Tổng Quan Dự Án

**MoneJour (Money + Journal)** — Ứng dụng quản lý chi tiêu cá nhân kết hợp nhật ký cảm xúc.
100% offline, không cần server, không cần internet.

### Kiến Trúc

```
┌───────────────────────────────────────────────┐
│              Flutter Mobile App               │
│  ┌──────────────┐  ┌───────────┐  ┌────────┐  │
│  │  4 Cubits     │  │  5 Screens│  │ Charts │  │
│  │  (State Mgmt) │  │  (UI)     │  │(fl_ch) │  │
│  └──────┬────────┘  └───────────┘  └────────┘  │
│         │                                      │
│  ┌──────▼───────────────────────┐              │
│  │     4 Repositories           │              │
│  │  Expense | Journal | Budget  │              │
│  │  FixedExpense                │              │
│  └──────┬───────────────────────┘              │
│         │                                      │
│  ┌──────▼──────┐                               │
│  │ Isar DB     │ ← Local NoSQL (4 Collections) │
│  └─────────────┘                               │
└───────────────────────────────────────────────┘
```

**KHÔNG CÓ:** Backend, Server, API, Docker, Cloud Database.

---

## 2. Tech Stack

| Tầng | Công nghệ | Vai trò |
|------|-----------|---------|
| **Framework** | Flutter 3.19+ / Dart 3.3+ | Cross-platform mobile |
| **Database** | Isar 3.1 (NoSQL) | Local storage, offline-first, 4 collections |
| **State Mgmt** | flutter_bloc 9.x (Cubit) | 4 Cubits + sealed states |
| **Charts** | fl_chart 0.69 | Biểu đồ (chưa implement) |
| **Format** | intl 0.19 | Format tiền VND + ngày tháng |
| **Utilities** | path_provider, uuid, shared_preferences | File path + ID + theme persist |
| **Equality** | equatable 2.x | Value equality cho States |

---

## 3. Cấu Trúc Thư Mục

```
mone_jour/lib/
├── main.dart                              # Entry point + MultiBlocProvider (4 cubits)
├── core/
│   ├── constants/categories.dart          # 9 danh mục (ExpenseCategory + getCategoryById)
│   ├── theme/app_theme.dart               # Minimalist Pastel Light/Dark (366 dòng)
│   └── utils/
│       ├── currency_formatter.dart        # formatVND(), formatVNDSigned()
│       ├── currency_input_formatter.dart   # TextInputFormatter cho input tiền
│       ├── date_formatter.dart            # formatDateShort/Full/MonthYear, isSameDay
│       └── expense_grouper.dart           # groupExpensesByDate(), calculateDayBalance()
├── data/
│   ├── models/                            # 4 Isar Collections + .g.dart generated
│   │   ├── expense.dart                   # Chi tiêu/thu nhập
│   │   ├── journal_entry.dart             # Nhật ký cảm xúc
│   │   ├── budget.dart                    # Hạn mức theo tháng
│   │   └── fixed_expense.dart             # Template chi tiêu cố định
│   └── repositories/                      # 4 Repository classes
│       ├── expense_repository.dart        # CRUD + thống kê + getCategorySpending
│       ├── journal_repository.dart        # CRUD + filter mood + getAverageMood
│       ├── budget_repository.dart         # upsert + getByMonth + getByCategoryMonth
│       └── fixed_expense_repository.dart  # CRUD + executeFixedExpense
├── logic/
│   ├── expense/    (cubit + state)        # ✅ Reactive + carriedOverBalance
│   ├── budget/     (cubit + state)        # ✅ Dual watcher + BudgetProgress
│   ├── fixed_expense/ (cubit + state)     # ✅ CRUD + execute
│   ├── theme/      (cubit)               # ✅ Dark/Light + SharedPreferences
│   ├── journal/                           # ⚠️ TRỐNG
│   ├── stats/                             # ⚠️ TRỐNG
│   └── settings/                          # ⚠️ TRỐNG
├── services/
│   └── database_service.dart              # Isar Singleton (4 schemas)
└── ui/
    ├── navigation/app_navigation.dart     # 4 tabs + IndexedStack
    ├── screens/
    │   ├── home/home_screen.dart           # ⚠️ 982 dòng — cần refactor
    │   ├── expense/
    │   │   ├── add_expense_screen.dart     # Form thêm (302 dòng)
    │   │   └── expense_list_screen.dart    # Danh sách + month selector
    │   ├── journal/                       # ⚠️ TRỐNG
    │   ├── stats/                         # ⚠️ TRỐNG
    │   └── settings/settings_screen.dart  # Toggle Dark/Light
    └── widgets/                           # 6 reusable widgets
        ├── summary_card.dart
        ├── budget_progress_card.dart
        ├── category_picker.dart
        ├── expense_card.dart              # ⚠️ DEAD CODE
        ├── fixed_expense_card.dart
        └── grouped_transaction_list.dart
```

---

## 4. Trạng Thái Module

### ✅ Hoàn thành (~65% MVP)
- Isar Database (4 collections + Singleton)
- 4 Data Models + 4 Repositories (full CRUD + thống kê)
- 4 Cubits (Expense, Budget, FixedExpense, Theme)
- Home Dashboard (summary + fixed expense + budget + recent transactions)
- CRUD Chi tiêu (thêm/xóa — **thiếu sửa**)
- CRUD Chi tiêu cố định (thêm/sửa/xóa + thanh toán 1 chạm)
- Hạn mức chi tiêu (thêm/sửa/xóa + progress bar + cảnh báo)
- Bottom Navigation 4 tabs + Dark/Light toggle
- Theme System (Light + Dark complete)
- Formatters (VND + date VN) + ExpenseGrouper

### ⏳ Chưa làm (~35% MVP)
- JournalCubit + Journal Screen (CRUD + mood picker)
- StatsCubit + Stats Screen (pie + bar chart dùng fl_chart)
- Edit Expense (chỉnh sửa giao dịch)
- Refactor `home_screen.dart` (982 dòng → tách files)
- Fix 3 Critical bugs (Dark Mode, UX, button color)
- Unit Tests

---

## 5. Lưu Ý Quan Trọng

1. **`home_screen.dart` cần refactor #1** — 982 dòng, chứa 7 hàm dialog/sheet
2. **`expense_card.dart` là dead code** — thay bởi `grouped_transaction_list.dart`
3. **Journal + Stats: Repo sẵn sàng**, chỉ cần Cubit + Screen
4. **Dark Mode bug**: `FixedExpenseCard` hardcode `Colors.white`
5. **Không có Edit Expense** — chỉ thêm + xóa
6. **`fl_chart` + `uuid` khai báo nhưng chưa dùng**
