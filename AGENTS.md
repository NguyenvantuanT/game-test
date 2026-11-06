# AGENTS.md

Mục lục cho mọi coding agent (Claude Code, Codex, Cursor, Copilot...). Giữ ngắn (hook báo khi > 150 dòng): chi tiết ở `docs/`, ở đây chỉ trỏ tới. Đường dẫn trong backtick được `docs-check.sh` kiểm tra tồn tại.

Fact riêng của dự án nằm trong repo này; convention chung của stack nằm trong skill. Lệch nhau → repo này + code thật thắng.

## Dự án

- **Là gì**: game 3D thử nghiệm (`game-test`): nhà, vườn, chuồng, hàng xóm có hội thoại, lưu game theo tài khoản — chi tiết `ARCHITECTURE.md`.
- **Stack**: Godot 4 + GDScript. `project.godot` khai feature 4.5; máy dev cài Godot 4.7.2 (macOS `/opt/homebrew/bin/godot`, Windows qua winget).
- **Supabase** (lưu game): schema ở `supabase/migrations/` là nguồn sự thật — sửa schema = thêm file migration mới, áp lên project cùng version, không sửa trên dashboard. Cấu hình máy: `supabase.example.cfg` → `supabase.cfg` (gitignore). Quyết định: `docs/design-docs/2026-11-06-cloud-save.md`.
- **Lệnh riêng của dự án**: chưa có. Lint/format cần `pip install gdtoolkit`; test cần cài GUT vào `addons/gut`.

## Làm việc

- Sửa nhỏ (1–2 file, yêu cầu rõ) → làm trực tiếp, load đúng skill theo bảng ở mục Stack.
- Việc lớn (> 1 PR, nhiều quyết định hoặc nhiều phiên) → viết exec plan ở `docs/exec-plans/active/` trước khi code (format: `docs/PLANS.md`).
- Tiếp tục việc dở ở phiên mới → đọc plan active, `git log --oneline -10`, chạy test nhanh trước khi sửa tiếp.
- Xong việc → hook chạy check + docs-check + verify của từng stack. Fail thì sửa, không bỏ qua.
- Trước khi báo xong việc lớn → subagent `evaluator` kiểm acceptance criteria; trước PR → subagent `reviewer` review diff.
- Sai vì thiếu context → bổ sung vào `docs/`; sai lặp lại → đề xuất rule mới cho harness.

## Bản đồ tri thức

| Cần biết | Đọc |
|---|---|
| Domain, layer, entry point | `ARCHITECTURE.md` |
| Nguyên tắc bất biến | `docs/golden-principles.md` |
| Chất lượng từng domain, gap đang theo dõi | `docs/QUALITY_SCORE.md` |
| Nợ kỹ thuật, xung đột rule ↔ code | `docs/tech-debt-tracker.md` |
| Việc đang làm / đã xong | `docs/exec-plans/active/`, `docs/exec-plans/completed/` |
| Spec sản phẩm | `docs/product-specs/` |
| Thiết kế kỹ thuật, quyết định lớn (ADR) | `docs/design-docs/` |
| Tài liệu ngoài cho agent (API bên thứ 3, llms.txt, spec chuẩn) | `docs/references/` |
| Doc sinh tự động (schema DB, API) — không sửa tay | `docs/generated/` |
| Rule bị tắt, pack đang bật | `.claude/harness.env` |

## Skill dùng chung

| Việc | Skill |
|---|---|
| Thiết kế UI/UX, bảng màu, font | `ui-ux-pro-max` · reskin có chủ đích: `frontend-design` |
| Giờ, múi giờ, lịch, giá, tiền | `datetime-and-money` |
| Sửa dữ liệu lúc offline rồi đồng bộ | `offline-sync` |
| Hợp đồng API client ↔ server (lỗi, phân trang, version) | `api-contract` |
| Thiết kế bảng, index, migration | `database-design` |
| Log, metric, alert, health check | `observability` |
| Bug khó, test fail khó hiểu, lỗi production | `systematic-debugging` |
| Branch, commit, PR, conflict | `git-workflow` |
| Review diff do agent viết | `ai-code-review` (subagent `reviewer`) |

## Stack

Khối dưới do `harness-init` sinh theo pack đang bật: đừng sửa tay, chạy lại init để cập nhật.

<!-- harness:stack:start -->

### Godot 4

- Chạy: `godot --path .` · headless: `godot --headless --path .`. Hook Stop chạy `gdlint`/`gdformat` (gdtoolkit) và GUT cho test liên quan nếu có `addons/gut`.
- File `.godot/`, `.import`, `.uid` do editor sinh — không sửa tay.

| Việc | Skill (plugin) |
|---|---|
| Scene/node, signal, resource, GDScript typed, GUT | `godot-development` (agent `godot-engineer`) |
| Kiến trúc game: loop, ECS, event bus, state stack | `game-arch-patterns` (plugin `game-architecture`) |
| Chạy project, đọc lỗi runtime qua MCP | plugin `godot-mcp` |
<!-- harness:stack:end -->

## Ngoại lệ đã chấp nhận

Mỗi ngoại lệ = 1 dòng + rule id trong `HARNESS_DISABLE` nếu tắt cả rule.

- Chưa có.
