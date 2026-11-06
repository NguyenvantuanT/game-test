# ADR: Lưu game theo tài khoản trên Supabase

- Ngày: 2026-11-06 · Trạng thái: chấp nhận · Plan: `2026-11-06-save-game.md` trong `docs/exec-plans/`

## Bối cảnh

Người chơi chơi ở công ty rồi về nhà chơi tiếp → bản lưu phải theo tài khoản, không theo máy. Game một người chơi, chưa có server riêng.

## Quyết định

- **Supabase** (project `Kora`, ref `xiecmrdddnexfqswyptw`, us-east-1): Auth email + mật khẩu, 1 bảng `public.saves` (1 dòng / tài khoản, cột `data jsonb`). Godot gọi thẳng REST bằng `HTTPRequest` — không thêm addon.
- **Khoá trong game**: chỉ publishable key (`sb_publishable_...`), để ở `supabase.cfg` (gitignore; mẫu `supabase.example.cfg`). Không có file → game chỉ lưu trên máy. Không bao giờ đưa secret / service_role key vào game.
- **Phân quyền ở server (RLS)**, không tin game: mỗi người chỉ select / insert / update dòng có `user_id = auth.uid()`; update có cả `using` + `with check` (không đổi được chủ dòng); `anon` không có quyền gì; không có delete.
- **Luôn giữ bản trên máy** (`user://saves/<user_id>.json`) với cờ `pending_upload`: ghi máy trước, gửi server được thì bỏ cờ; mở game có cờ → gửi lên trước khi tải. Mất mạng lúc mở → chơi offline bằng bản trên máy của tài khoản gần nhất.
- **Phiên đăng nhập** (refresh token) ở `user://session.json` để lần sau tự vào; access token hết hạn → tự làm mới, thử lại 1 lần.
- **Chỉ lưu khi đã nạp**: đóng cửa sổ lúc chưa nạp bản lưu (đang đăng nhập / đang tải / tải lỗi) thì thoát luôn, không lưu — lưu lúc đó sẽ ghi thế giới mới đè lên tiến độ thật. Tải lỗi thì không cho chơi online; chơi offline thì bỏ access token, chỉ lưu máy + chờ gửi.
- **`updated_at` do server đặt** (trigger `saves_set_updated_at`), không tin đồng hồ máy người chơi.
- **Xung đột 2 máy**: chưa xử lý — bản *gửi lên* sau cùng thắng, kể cả bản chờ gửi cũ từ máy từng mất mạng (có thể đè tiến độ mới hơn của máy kia). User chấp nhận tạm; xem "Còn mở" trong plan.

## Schema

Nguồn sự thật: `supabase/migrations/` — mỗi file `<version>_<tên>.sql` trùng version + nội dung đã áp lên project (`list_migrations` của MCP / `supabase migration list`):

- `supabase/migrations/20261106090854_create_game_saves.sql` — bảng `saves`, RLS, grant, 3 policy.
- `supabase/migrations/20261106092343_saves_server_updated_at.sql` — trigger đặt `updated_at` bằng giờ server.

Sửa schema = thêm file migration mới (không sửa file cũ), áp lên project với đúng version đó, commit cùng code dùng nó.

Kiểm bằng 2 tài khoản thật: B không đọc (rỗng), không ghi đè / PATCH (403 / 0 dòng), không đổi `user_id` sang A (403); anon đọc → 401.

## Cấu hình project cần làm tay (dashboard)

- Authentication → Email: tắt **Confirm email** (đăng ký xong vào được ngay) — đang tắt.
- Gói Free tự tạm dừng project sau ~1 tuần không dùng → vào dashboard bấm Restore.
- Project còn 5 bảng demo cũ của Kora (`circle_posts`, `favorites`, `pieces`, `practice_logs`, `profiles`) — không liên quan game; xoá được bằng SQL Editor: `drop table public.circle_posts, public.favorites, public.pieces, public.practice_logs, public.profiles cascade;`

## Hệ quả

- `supabase.cfg` không phải resource nên **không vào bản export** mặc định: khi export phải thêm `*.cfg` vào filter include của preset, không thì bản export chỉ lưu trên máy.
- Không cần server riêng, không tốn phí ở gói Free; phụ thuộc Supabase còn sống / không bị tạm dừng.
- Muốn đổi sang nhà cung cấp khác: chỉ thay `scripts/cloud_save.gd` (SaveFlow / SaveGame không đổi).
