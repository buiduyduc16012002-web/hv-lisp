# Changelog

## 0.8.0 - 2026-11-25

- `SUMHATCH`: ghi diện tích `S=… m2` lên giữa từng vùng hatch, click 1 điểm ghi tổng diện tích (layer CHU); hỏi đơn vị bản vẽ M/MM một lần (nhớ cho lần sau); chạy lại thì cập nhật nhãn cũ thay vì ghi chồng; có Undo.

## 0.7.1 - 2026-11-25

- Sửa `SUMHATCH` báo 0.000 m2: bản vẽ vẽ theo m nhưng INSUNITS = mm nên bị chia 1.000.000. Giờ in diện tích theo đơn vị vẽ (giống ô Area của PROPERTIES), kèm số m² cho cả hai trường hợp vẽ theo m và theo mm.
- `FH` hatch được mọi đối tượng kín: vòng tròn, polyline kín (kể cả polyline điểm đầu trùng điểm cuối), ellipse, spline kín, region; báo số đã hatch theo loại, số đối tượng hở bị bỏ qua.

## 0.7.0 - 2026-11-25

- Thêm lệnh `SUMHATCH` / `HVSUMHATCH`: quét chọn hatch, cộng tổng diện tích, chia theo layer, tự đổi ra m² theo INSUNITS (mm, cm, dm, m); không sửa bản vẽ.

## 0.6.0 - 2026-11-25

- Thêm lệnh `FH` / `HVFH`: quét chọn cọc TĐXM (CIRCLE), tạo hatch SOLID liên kết cho từng vòng tròn trên layer HATCH, bỏ qua cọc đã có hatch; dùng được ngay tập chọn sẵn của `TDXM`.

## 0.5.1 - 2026-11-25

- `TDXM`: thống kê xong tự chọn các cọc đếm được (chọn sẵn để dùng ngay MOVE/COPY/PROPERTIES) và lưu làm tập chọn Previous (gõ `P` ở dòng Select objects).

## 0.5.0 - 2026-11-25

- Thêm lệnh `TDXM` / `HVTDXM`: đếm cọc TĐXM (CIRCLE) có tâm nằm trong polyline bao (cả polyline có đoạn cong), lọc theo vòng tròn mẫu (layer + đường kính), thống kê theo layer/đường kính, báo số cọc cắt đường bao, tô sáng cọc đếm được, tùy chọn ghi số lượng vào bản vẽ (layer CHU).

## 0.4.0 - 2026-11-25

- Thêm lệnh `UPDATE`: tên ngắn, dễ nhớ của `HVUPDATE` (vẫn giữ `HVUPDATE`).
- `tests/check_repo.py`: cho phép danh sách tên ngắn không tiền tố `ALIASES`.

## 0.3.1 - 2026-11-25

- Sửa đóng gói: file ZIP tên `hvlisp-v<phiên bản>.zip`, thư mục bên trong tên `HVLisp`; giải nén thẳng vào `C:\` là được `C:\HVLisp`.

## 0.3.0 - 2026-11-25

- Bắt đầu bộ **HVLisp** (fork của AutoLISP Civil Tools Community, giữ nguyên 7 lệnh CT và các module trong `src/`).
- `src/act-load.lsp`: thư mục gốc ưu tiên `C:\HVLisp`, đọc phiên bản từ file `VERSION`, tự nạp mọi file `.lsp` trong `lenh\` (file lỗi được báo tên và bỏ qua).
- Thêm `update.ps1` (tải nhánh `main` từ GitHub, chép đè vào thư mục cài).
- Thêm lệnh `HVUPDATE` (tự cập nhật trong AutoCAD) và `HVHELP` (xem danh sách lệnh) trong `lenh/hv-update.lsp`.
- Thêm `lenh/danh-sach.txt`; đóng gói ZIP có thêm `lenh/` và `update.ps1`.
- `tests/check_repo.py`: kiểm tra `lenh/` (ngoặc, tiền tố HV, trùng lệnh, chỉ ASCII, Undo khi sửa bản vẽ), chỉ cho phép gọi mạng trong `lenh/hv-update.lsp`, so phiên bản với file `VERSION`.

## 0.2.0 - 2026-09-04

- Adds WCS CSV point import with quoted-field parsing and invalid-row reporting.
- Adds curve-based chainage and absolute-offset labels.
- Adds clamped linear elevation interpolation between two control points.
- Changes `CTPROFILE` to calculate real curve stations instead of row numbers.
- Converts entity OCS points and interactive UCS points to WCS before calculations.
- Adds command-level Undo marks and error cleanup, including closing CSV handles.
- Adds versioned release packaging, SHA-256 checksums, CI artifacts, and tag asset publishing.
- Adds bilingual onboarding, a command reference, a CAD test matrix, a roadmap, and contribution templates.
- Retains an explicit limitation: interactive AutoCAD/BricsCAD testing is still pending.

## 0.1.1 - 2026-08-08

- Clarifies that CSV output uses the host CAD text encoding; UTF-8 conversion is not claimed until verified on Windows CAD.
- Records the VPS QA limitation: no AutoCAD, BricsCAD, or Wine runtime is installed here.

## 0.1.0 - 2026-08-08

- First independent community release.
- Adds coordinate labels, CSV export, elevation labels, and a basic profile table.
- Adds static repository checks and original sample fixtures.
