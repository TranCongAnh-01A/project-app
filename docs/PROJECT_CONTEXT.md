# MoneJour — Project Context (Bản Đồ Trí Nhớ)

> Cập nhật: 2026-05-08 21:50 | Phiên bản: v1.0.0 (MVP) | Platform: Android, iOS
> Quét toàn bộ codebase: **33 files source** | **~4,080 dòng code** (không tính generated `.g.dart`)

---

## 1. Tổng Quan Dự Án

**MoneJour (Money + Journal)** — Ứng dụng quản lý chi tiêu cá nhân kết hợp nhật ký cảm xúc.
100% offline, không cần server, không cần internet.

### Kiến Trúc

```
┌───────────────────────────────────────────────┐
│              Flutter Mobile App               │
│  ┌──────────────┐  ┌───────────┐  ┌────────┐  │
│  │  4 Cubits     │  │  4 Screens│  │ Charts │  │
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
| **Format** | intl 0.20.2 | Format tiền VND + ngày tháng |
| **Utilities** | path_provider, shared_preferences | File path + theme persist |
| **Equality** | equatable 2.x | Value equality cho States |

> ⚠️ `uuid: ^4.5.1` khai báo trong pubspec nhưng **CHƯA BAO GIỜ import/sử dụng** → nên xóa.

---

## 3. Cấu Trúc Thư Mục (Trạng Thái Thực Tế)

```
mone_jour/lib/
├── main.dart                              # Entry point + MultiBlocProvider (77 dòng)
├── core/
│   ├── constants/categories.dart          # 9 danh mục (ExpenseCategory + getCategoryById) — 87 dòng
│   ├── theme/app_theme.dart               # Minimalist Pastel Light/Dark — 366 dòng
│   └── utils/
│       ├── currency_formatter.dart        # formatVND(), formatVNDSigned() — 20 dòng
│       ├── currency_input_formatter.dart  # TextInputFormatter cho input tiền — 41 dòng
│       ├── date_formatter.dart            # formatDateShort/Full/MonthYear, isSameDay — 29 dòng
│       └── expense_grouper.dart           # groupExpensesByDate(), calculateDayBalance() — 34 dòng
├── data/
│   ├── models/                            # 4 Isar Collections + .g.dart generated
│   │   ├── expense.dart                   # Chi tiêu/thu nhập — 35 dòng
│   │   ├── journal_entry.dart             # Nhật ký cảm xúc — 35 dòng
│   │   ├── budget.dart                    # Hạn mức theo tháng — 28 dòng
│   │   └── fixed_expense.dart             # Template chi tiêu cố định — 32 dòng
│   └── repositories/                      # 4 Repository classes
│       ├── expense_repository.dart        # CRUD + thống kê + getCategorySpending — 112 dòng
│       ├── journal_repository.dart        # CRUD + filter mood + getAverageMood — 69 dòng
│       ├── budget_repository.dart         # upsert + getByMonth + getByCategoryMonth — 67 dòng
│       └── fixed_expense_repository.dart  # CRUD + executeFixedExpense — 61 dòng
├── logic/
│   ├── expense/    (cubit + state)        # ✅ Reactive + carriedOverBalance — 176 dòng
│   ├── budget/     (cubit + state)        # ✅ Dual watcher + BudgetProgress — 227 dòng
│   ├── fixed_expense/ (cubit + state)     # ✅ CRUD + execute — 116 dòng
│   ├── theme/      (cubit)               # ✅ Dark/Light + SharedPreferences — 27 dòng
│   ├── journal/                           # ❌ TRỐNG (Repo sẵn sàng, cần Cubit)
│   ├── stats/                             # ❌ TRỐNG
│   └── settings/                          # ❌ TRỐNG
├── services/
│   └── database_service.dart              # Isar Singleton (4 schemas) — 47 dòng
└── ui/
    ├── navigation/app_navigation.dart     # 4 tabs + IndexedStack — 126 dòng
    ├── screens/
    │   ├── home/home_screen.dart           # 🔴 1159 dòng — CẦN REFACTOR KHẨN CẤP
    │   ├── expense/
    │   │   ├── add_expense_screen.dart     # Form thêm (312 dòng) — chưa hỗ trợ Edit
    │   │   └── expense_list_screen.dart    # Danh sách + month selector — 211 dòng
    │   ├── journal/                       # ❌ TRỐNG
    │   ├── stats/                         # ❌ TRỐNG
    │   └── settings/settings_screen.dart  # Toggle Dark/Light — 76 dòng
    └── widgets/                           # 5 reusable widgets (đã xóa dead code)
        ├── summary_card.dart              # ✅ 143 dòng — theme-aware
        ├── budget_progress_card.dart      # ✅ 160 dòng — status color system
        ├── category_picker.dart           # ✅ 73 dòng — Wrap + ChoiceChip
        ├── fixed_expense_card.dart        # ✅ 98 dòng — ĐÃ FIX Dark Mode bug
        └── grouped_transaction_list.dart  # ✅ 270 dòng — Group by date, empty state
```

---

## 4. Trạng Thái Module

### ✅ Hoàn thành (~65% MVP)

- Isar Database (4 collections + Singleton)
- 4 Data Models + 4 Repositories (full CRUD + thống kê)
- 4 Cubits (Expense, Budget, FixedExpense, Theme)
- Home Dashboard (summary + fixed expense actions + budget progress + recent transactions)
- CRUD Chi tiêu (thêm/xóa — **thiếu sửa**)
- CRUD Chi tiêu cố định (thêm/sửa/xóa + thanh toán 1 chạm + action sheet)
- Hạn mức chi tiêu (thêm/sửa/xóa + progress bar + cảnh báo vượt ngưỡng)
- Bottom Navigation 4 tabs + Dark/Light toggle
- Theme System (Light + Dark complete)
- Formatters (VND + date VN) + ExpenseGrouper

### 🛠️ Đã sửa từ đợt audit trước

- ✅ `fixed_expense_card.dart` — Đã sửa hardcode `Colors.white` → `Theme.of(context).colorScheme.surface`
- ✅ `expense_card.dart` — Dead code đã bị XÓA khỏi project
- ✅ Fixed expense — Đã thêm action sheet 3 chức năng (Thanh toán / Sửa / Xóa)
- ✅ `currency_input_formatter.dart` — Regex đã đúng (`r'[^\d]'`)

### ⏳ Chưa làm (~35% MVP)

- JournalCubit + Journal Screen (CRUD + mood picker)
- StatsCubit + Stats Screen (pie + bar chart dùng fl_chart)
- Edit Expense (chỉnh sửa giao dịch — cubit method sẵn, thiếu UI)
- Refactor `home_screen.dart` (1159 dòng → tách files)
- Unit Tests

---

## 5. Bug Matrix (Trạng Thái Hiện Tại)

### 🔴 CRITICAL

| # | File | Vấn đề | Tác động |
|---|------|--------|---------| 
| 1 | `home_screen.dart` | **1159 dòng** — chứa 1 main widget + 1 StatefulWidget + 8 dialog/sheet functions | Không bảo trì được, vi phạm SRP cực kỳ nghiêm trọng. **Tệ hơn lần audit trước** (975→1159) |

### 🟠 HIGH

| # | File | Vấn đề | Tác động |
|---|------|--------|---------|
| 2 | `home_screen.dart:121-122` | `onTap` và `onLongPress` đều gọi `_confirmDelete` cho giao dịch thường | UX tệ — người dùng tap = xóa thay vì xem/sửa |
| 3 | `expense_list_screen.dart:131-132` | Cùng vấn đề — cả tap lẫn longpress đều delete | Thiếu chức năng Edit Expense hoàn toàn |

### 🟡 MEDIUM

| # | File | Vấn đề | Tác động |
|---|------|--------|---------|
| 4 | Nhiều file | **Hai hệ màu "đỏ" xung đột** — `AppTheme.expenseRed` = `0xFFE17055` (cam pastel) nhưng nhiều nơi dùng `Color(0xFFEF4444)` (đỏ Tailwind) | Giao diện không thống nhất, 2 màu đỏ khác nhau cho cùng ngữ nghĩa "nguy hiểm/xóa" |
| 5 | `home_screen.dart` + `expense_list_screen.dart` | `_confirmDelete()` duplicate code gần 100% | Vi phạm DRY — nên extract thành shared utility |
| 6 | `expense_cubit.dart:44` | `DateTime(2000)` hardcode cho carried balance | Nên dùng constant có ý nghĩa hơn |
| 7 | `main.dart:24-27` | `print()` cho error handler | Production không nên dùng print |
| 8 | `pubspec.yaml` | `uuid: ^4.5.1` khai báo nhưng **KHÔNG BAO GIỜ import** | Tăng kích thước app thừa |
| 9 | `app_theme.dart` | `minimalistLight` và `minimalistDark` duplicate ~200 dòng config | Nên extract common theme builder |
| 10 | `budget_state.dart:37` | `BudgetProgress.props` không bao gồm `budgetId` | Có thể gây Equatable so sánh sai khi budgetId thay đổi |

### 🔵 LOW

| # | File | Vấn đề |
|---|------|--------|
| 11 | `logic/journal/`, `stats/`, `settings/` | Thư mục trống — cần implement |
| 12 | `test/` | 0 unit test |
| 13 | `currency_formatter.dart` | `formatVNDSigned()` định nghĩa nhưng chưa sử dụng |
| 14 | Navigation tab "Nhật ký" | Placeholder, chưa có chức năng |

---

## 6. Chi Tiết Hardcoded Colors (Bug #4)

Vấn đề: Dự án sử dụng **2 hệ màu đỏ khác nhau** không nhất quán:

| Màu | Hex | Nơi sử dụng |
|-----|-----|-------------|
| `AppTheme.expenseRed` | `#E17055` (cam-đỏ pastel) | summary_card, budget_progress_card, fixed_expense_card, expense_list_screen delete button |
| Hardcode | `#EF4444` (đỏ Tailwind) | home_screen delete dialog, budget dialog delete, template save error, add_expense error snackbar |
| Hardcode | `#10B981` (xanh lá) | add_expense save button, template sheet save button (thay vì dùng `AppTheme.incomeGreen = #00B894`) |

**Tác động:** Nút "Xóa" ở home_screen là màu đỏ `#EF4444`, nhưng nút "Xóa" ở expense_list_screen lại là cam-đỏ `#E17055`. Không đồng bộ.

**Giải pháp:** Thống nhất toàn bộ về `AppTheme.expenseRed` và `AppTheme.incomeGreen`, hoặc thêm `AppTheme.dangerRed` mới nếu cần tách biệt "chi tiêu" vs "hành động nguy hiểm".

---

## 7. Điểm Mạnh Của Dự Án

1. **Kiến trúc phân tầng rõ ràng:** Data → Logic → UI tách biệt chuẩn
2. **Reactive system:** Isar `watchLazy()` → Cubit auto-reload → UI tự động cập nhật
3. **Sealed class state:** Type-safe, compiler bắt lỗi tại build-time
4. **Repository pattern:** Dễ swap DB engine, dễ mock test
5. **Theme system:** Light/Dark hoàn chỉnh, persist SharedPreferences
6. **Comment tiếng Việt xuất sắc:** Giải thích "tại sao" chứ không chỉ "cái gì"
7. **Fixed Expense workflow tốt:** Action sheet gộp 3 chức năng (Pay/Edit/Delete) rất UX
8. **Budget warning system:** 3 trạng thái (safe/warning/exceeded) với màu tương ứng

---

## 8. Ưu Tiên Tiếp Theo (Roadmap)

### Phase 1: 🚨 Hotfix (1-2 ngày)
- [ ] Fix onTap/onLongPress giao dịch thường → tách tap (edit) vs longpress (options)
- [ ] Thống nhất hệ màu hardcoded → dùng AppTheme constants
- [ ] Xóa `uuid` dependency thừa
- [ ] Thêm Edit Expense UI (tái sử dụng AddExpenseScreen)

### Phase 2: 🔧 Refactor (3-5 ngày)
- [ ] Tách `home_screen.dart` (1159 dòng) → 6-8 files nhỏ
- [ ] Extract duplicate `_confirmDelete()` → shared dialog utility
- [ ] Giảm duplicate trong `app_theme.dart` (extract common theme builder)
- [ ] Thêm `BudgetProgress.props` bao gồm `budgetId`

### Phase 3: ✨ Hoàn thiện MVP (5-7 ngày)
- [ ] JournalCubit + JournalScreen (CRUD + mood picker)
- [ ] StatsCubit + StatsScreen (pie + bar chart dùng fl_chart)
- [ ] Unit tests cho Repositories + Cubits

### Phase 4: 🚀 Production Ready
- [ ] Performance profiling (IndexedStack + large lists)
- [ ] App icon + splash screen
- [ ] Export/backup data (JSON/CSV)

---

## 9. Lưu Ý Cho AI Tương Lai

1. **`home_screen.dart` = file lớn nhất + nhiều bug nhất** — ưu tiên refactor #1
2. **2 màu đỏ khác nhau** — `0xFFE17055` (theme) vs `0xFFEF4444` (hardcode) → cần thống nhất
3. **Journal + Stats: Repo sẵn sàng**, chỉ cần Cubit + Screen
4. **`updateExpense()` trong cubit sẵn sàng** — chỉ thiếu UI gọi nó
5. **`fl_chart` sẽ dùng khi làm Stats Screen** — giữ lại
6. **`uuid` KHÔNG dùng ở đâu** — xóa an toàn
7. **Isar watcher pattern hoạt động tốt** — không cần emit thủ công sau add/delete
