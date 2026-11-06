# game-test

Game 3D thử nghiệm làm bằng Godot 4. Bạn điều khiển một nhân vật đi dạo trong khu đất có ngôi nhà 2 tầng vào được hai khu vườn để chăm cây, thu hoạch, ba chuồng nuôi gà, bò, cừu, và xóm có hai nhà hàng xóm. Camera nhìn chéo từ trên xuống. Hình hiện tại chỉ là khối cơ bản, chưa có model thật.

Repo được phát triển chủ yếu bằng coding agent (Claude Code), chạy trong bộ harness `vtinter-harness`: luật, hook và subagent kiểm tra giúp agent làm đúng quy trình. Phần [Cách AI làm việc](#cách-ai-làm-việc-trong-repo) bên dưới mô tả quy trình đó.

## Chạy game

Cần Godot 4.5 trở lên (máy dev dùng 4.7.2).

```sh
godot --path .              # mở cửa sổ game
godot --path . --editor     # mở Godot Editor (bấm F5 để chạy)
godot --headless --path .   # chạy không cửa sổ, dùng cho script kiểm tra
```

Scene chính là `scenes/world.tscn`. Muốn lưu game theo tài khoản (chơi ở máy khác vẫn tiếp tục được) thì copy `supabase.example.cfg` thành `supabase.cfg` và điền URL + publishable key của project Supabase; không có file này game chỉ lưu trên máy. Lần đầu mở, hoặc sau khi thêm script có `class_name` mới, nên chạy `godot --headless --path . --import` để Godot cập nhật cache class.

### Điều khiển

| Phím | Việc |
|---|---|
| WASD / phím mũi tên | Di chuyển |
| E | Tương tác với vật gần nhất: mở/đóng cửa, bật/tắt đèn và TV, thắp/tắt hương, tưới cây, bón phân, thu hoạch, cho ăn, nhặt trứng, vắt sữa, cắt lông, nói chuyện với hàng xóm |

Góc trên bên trái hiện tên khu vực đang đứng, góc trên bên phải đếm số rau, hoa, trứng, sữa, len đã thu được. Khi đứng gần vật tương tác được, gợi ý `[E] ...` hiện ở dưới màn hình.

### Có gì trong map

- **Sân nhà**: lối đi nối nhà với vườn rau, vườn hoa và khu chăn nuôi phía nam nhà.
- **Vườn rau, vườn hoa**: mỗi cây chăm riêng (xem [Làm vườn](#làm-vườn)).
- **Chuồng gà, chuồng bò, chuồng cừu**: ba ô rào riêng, cổng quay về phía nhà (xem [Chăn nuôi](#chăn-nuôi)).
- **Xóm**: đi theo đường chính sang phía đông, qua giữa hai vườn, tới nhà bác Ba và nhà cô Lan nằm cạnh nhau phía bắc đường. Xem [Hàng xóm](#hàng-xóm).
- **Nhà, tầng 1**: phòng khách (sofa, TV, kệ sách, đèn cây), bếp và bàn ăn, phòng ngủ, phòng tắm. Cầu thang nằm trong phòng ngủ.
- **Nhà, tầng 2**: phòng thờ phía trước, sảnh cầu thang ở giữa, hai phòng ngủ hai bên, nhà vệ sinh phía sau.

### Làm vườn

Đứng gần một cây và bấm E. Mỗi lần bấm làm một việc, theo thứ tự ưu tiên:

1. **Thu hoạch** nếu cây đã chín: rau có quả đỏ, hoa nở bông. Cây quay về mầm và mọc lại, HUD cộng thêm 1.
2. **Tưới cây** nếu đất khô. Cây chỉ lớn khi đất ẩm (sẫm màu); một lần tưới giữ ẩm 30 giây.
3. **Bón phân** nếu chưa có phân. Cây lớn nhanh gấp đôi trong 30 giây, trên đất có hạt phân trắng.

Tưới đều thì cây chín sau khoảng 90 giây, có bón phân thì nhanh hơn. Cây lớn qua 4 giai đoạn: mầm, đang lớn, sắp chín (rau có quả xanh, hoa có nụ), chín. Trạng thái vườn chưa được lưu khi thoát game.

### Chăn nuôi

Gà (5 con), bò (2 con) và cừu (3 con) tự đi lang thang trong chuồng; chúng chắn đường nên bạn không đi xuyên qua được. Đứng gần một con và bấm E:

1. **Cho ăn** nếu con vật đang đói. Sau đó nó cần thời gian: gà 30 giây, cừu 45 giây, bò 60 giây. Lúc này bấm E không có tác dụng.
2. Khi xong, sản phẩm xoay trên đầu con vật: quả trứng, chai sữa hoặc cuộn len (lông cừu cũng dày dần lên). Bấm **Nhặt trứng**, **Vắt sữa** hoặc **Cắt lông** để thu; HUD cộng thêm 1 và con vật lại đói.

Trạng thái chuồng chưa được lưu khi thoát game.

### Hàng xóm

Nhà hàng xóm chỉ nhìn từ ngoài, không vào được. Mỗi nhà có một người đi lại trong sân trước. Đứng gần và bấm E để **nói chuyện**: hộp thoại hiện ở dưới màn hình với câu của người hàng xóm và các câu trả lời đánh số. Chọn bằng phím số 1–4, bấm chuột, hoặc mũi tên lên/xuống rồi E / Enter; bấm **Esc** để thôi nói chuyện bất cứ lúc nào. Mỗi câu trả lời dẫn sang nhánh chuyện khác (hỏi thăm, mẹo làm vườn, chuyện gà, nồi chè, xin hoa...); chọn câu chào về thì kết thúc. Trong lúc nói chuyện bạn và người hàng xóm đều đứng yên.

Kịch bản viết sẵn trong `scripts/dialogues.gd`, không dùng AI. Muốn sửa lời hoặc thêm nhánh: mỗi nút có `text` (câu người hàng xóm nói) và `options` (tối đa 4 cặp [câu trả lời, tên nút tiếp theo]); tên nút tiếp theo là `END` thì kết thúc. Nút sai tên sẽ báo lỗi ở Output khi chạy game từ editor.

### Lưu game

- **Đăng nhập**: mở game (đã có `supabase.cfg`) sẽ hiện màn đăng nhập. Lần đầu bấm **Đăng ký** bằng email + mật khẩu (ít nhất 6 ký tự); lần sau game nhớ và tự vào. Ở máy khác (công ty / nhà) đăng nhập cùng tài khoản là chơi tiếp đúng chỗ cũ.
- **Lưu**: bấm nút đóng cửa sổ → game dừng và hỏi **Lưu và thoát / Thoát không lưu / Huỷ**. Không có tự lưu.
- **Lưu gì**: cây trong vườn (lớn tới đâu, còn ẩm, còn phân), con vật (đói / đang làm / có sản phẩm) và số rau, hoa, trứng, sữa, len. Vị trí nhân vật, cửa, đèn không lưu. Thời gian trong game dừng khi tắt.
- **Mất mạng**: game luôn lưu một bản trên máy trước. Gửi lên server lỗi thì báo và cho thử lại; lần sau mở game có mạng sẽ tự gửi. Mở game lúc mất mạng thì có nút **Chơi offline** dùng bản trên máy.
- **Chơi ở 2 máy**: luôn bấm **Lưu và thoát** ở máy này trước khi mở máy kia. Chưa xử lý xung đột: bản nào gửi lên server sau cùng thì thắng — kể cả bản "chờ gửi" cũ của máy từng mất mạng, nó sẽ đè lên tiến độ mới hơn của máy kia khi có mạng lại.

### Nhìn trong nhà

Khi bạn vào nhà, mái và nửa trên tường tầng đang đứng được ẩn đi để nhìn thấy bên trong. Đứng ở tầng 1 thì cả tầng 2 cũng ẩn. Ra sân thì nhà hiện lại đầy đủ.

## Cấu trúc

```
scenes/          world (map + HUD), house, garden, pen, player
scripts/         logic từng scene + helper dựng hình (mesh_kit, named_area, interactable, fence)
docs/            tri thức của dự án, agent đọc trước khi làm (xem bảng dưới)
.claude/         cấu hình harness cho repo (rule bị tắt, pack đang bật)
.github/         CI chạy cùng bộ kiểm tra với hook ở máy
AGENTS.md        mục lục cho mọi coding agent, trỏ tới docs/
CLAUDE.md        phần riêng cho Claude Code
ARCHITECTURE.md  domain, layer, collision layer, entry point
```

| File / thư mục trong `docs/` | Chứa gì |
|---|---|
| `exec-plans/active/`, `exec-plans/completed/` | Plan của việc lớn: đang làm / đã xong |
| `PLANS.md` | Khung một plan và giao thức mỗi phiên làm việc |
| `golden-principles.md` | Nguyên tắc bất biến, mỗi cái kèm cách kiểm |
| `QUALITY_SCORE.md` | Điểm chất lượng từng domain |
| `tech-debt-tracker.md` | Nợ kỹ thuật, chỗ rule và code đang lệch nhau |
| `design-docs/`, `product-specs/`, `references/` | Quyết định thiết kế lớn (ADR), spec sản phẩm, tài liệu ngoài |

## Cách AI làm việc trong repo

### Nguồn tri thức

Agent bắt đầu từ `AGENTS.md`. File này chỉ là mục lục: nó trỏ tới `ARCHITECTURE.md`, các file trong `docs/` và skill cần load cho từng loại việc. Có hai nguồn tri thức:

- **Fact riêng của dự án** (map rộng bao nhiêu, nhà có mấy phòng, vì sao chọn cách này) nằm trong repo.
- **Convention chung của stack** (viết GDScript có type, chọn signal hay gọi trực tiếp, test bằng GUT) nằm trong skill của plugin, ví dụ `godot-development`.

Hai nguồn lệch nhau thì repo và code thật thắng.

### Một việc đi qua những bước nào

1. **Phân loại việc.** Việc nhỏ (1–2 file, yêu cầu rõ) thì làm luôn. Việc lớn (nhiều file, nhiều quyết định, có thể kéo qua nhiều phiên) thì viết exec plan ở `docs/exec-plans/active/<ngày>-<tên>.md` trước khi code.
2. **Viết plan.** Plan có: acceptance criteria kiểm chứng được, các bước, quyết định kèm lý do, tiến độ, câu hỏi còn mở. Plan là bộ nhớ giữa các phiên: phiên sau, kể cả agent khác với context trống, phải làm tiếp được chỉ từ plan và `git log`.
3. **Load skill rồi code.** Sửa file thuộc domain có skill mà chưa load thì hook nhắc một lần mỗi phiên.
4. **Tự kiểm tra.** Agent chạy game hoặc smoke test để xem thay đổi hoạt động thật, không chỉ đọc code.
5. **Hook kiểm tra khi agent dừng.** Rule fail thì agent phải sửa, không được bỏ qua.
6. **Evaluator kiểm lại.** Trước khi báo xong việc lớn, subagent `evaluator` kiểm độc lập từng acceptance criteria (chạy test, chạy game, xem ảnh chụp, đọc log). Kết quả ghi vào mục `## Evaluator` của plan.
7. **Reviewer review trước PR.** Subagent `reviewer` review diff. Sau đó mới mở PR.
8. **Đóng plan.** Khi đạt hết tiêu chí, chuyển plan sang `docs/exec-plans/completed/`.

Nếu agent sai vì thiếu context, bổ sung vào `docs/`. Nếu một lỗi lặp lại, đề xuất thêm rule cho harness.

### Hook tự chạy

| Lúc | Hook làm gì |
|---|---|
| Mở phiên | Nhắc đọc `AGENTS.md`, báo plan đang dở và bước tiếp theo |
| Sau mỗi lần sửa file | Chạy rule của pack godot trên file vừa sửa (xem bảng dưới) |
| Trước lệnh shell | Chặn ghi file generated (`.uid`, `.import`, `.godot/`); hỏi trước `--no-verify`, `push --force`, `reset --hard` |
| Khi agent dừng | `gdlint`, `gdformat`, docs-check, GUT cho test liên quan (khi có `addons/gut`), kiểm plan có kết quả evaluator |

## Kiểm tra code, docs và plan

### Code

Rule của pack godot:

| Rule | Bắt lỗi gì |
|---|---|
| `gd_print` | `print` còn sót. Lỗi thật thì dùng `push_warning()` / `push_error()` |
| `gd_untyped_var` | Biến không có type |
| `gd_parent_path` | Đường dẫn node đi ngược lên cha (`get_node("../...")`, `get_parent().get_parent()`). Dùng `@export` hoặc signal lên cha |
| `gd_find_node` | Tìm node theo tên trên cả cây (`find_child`). Dùng `@export`, unique name `%Name` hoặc group |
| `gd_process_alloc` | `load`/`preload` trong `_process` / `_physics_process`. `preload` ở đầu file hoặc cache vào biến |
| `gd_secret` | Key hoặc secret viết thẳng trong code (client game là public) |
| `gdlint`, `gdformat` | Lint và format GDScript (gdtoolkit) |

Chạy lint/format ở máy:

```sh
pip install gdtoolkit
gdlint scripts/
gdformat --check scripts/
```

Repo chưa có test tự động. Khi cần, cài GUT vào `addons/gut`; hook sẽ tự chạy test liên quan. Hiện các tính năng được kiểm bằng smoke test chạy headless (`godot --headless --path . -s <script>`) và ảnh chụp từ game.

### Docs

`docs-check.sh` kiểm docs có lệch với code không. Ví dụ: mọi đường dẫn viết trong backtick ở `AGENTS.md` và `ARCHITECTURE.md` phải tồn tại thật. Đổi tên hay xoá file thì phải sửa docs theo. `AGENTS.md` giữ dưới 150 dòng; chi tiết để trong `docs/`.

### Plan

Rule `plan_eval`: nếu plan đã tick hết tiêu chí, hoặc đã nằm trong `completed/`, mà mục `## Evaluator` chưa có dòng `<ngày> đạt hết`, thì hook chặn. Agent không được sửa hay xoá tiêu chí cho dễ đạt. Tiêu chí sai thì ghi vào "Còn mở" để người quyết định.

### CI

Workflow `.github/workflows/harness.yml` chạy trên mỗi PR và mỗi lần push vào `main`. Nó dùng harness ở tag cố định (`HARNESS_REF`), nên khi harness ra bản mới thì CI của dự án không tự nhiên đỏ.

- **Rule check**: chỉ chạy trên các dòng PR thêm hoặc sửa. Nợ cũ để skill `harness-gardening` dọn dần.
- **Docs drift**: chạy `docs-check.sh`.
- **`gdlint` + `gdformat --check`**: chạy trên mọi file `.gd`.

Muốn tắt một rule cho cả dự án thì thêm rule id vào `HARNESS_DISABLE` trong `.claude/harness.env`, rồi ghi lý do ở mục "Ngoại lệ đã chấp nhận" của `AGENTS.md`.
