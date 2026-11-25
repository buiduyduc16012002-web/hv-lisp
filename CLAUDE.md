# HVLisp – hướng dẫn cho AI

Repo này là bộ Lisp riêng **HVLisp**, fork của `ankaibua-spec/autolisp-civil-tools` (GPL-3.0-or-later).

## THÔNG TIN CỦA MÌNH

- Tên bộ Lisp: **HVLisp**
- Tiền tố lệnh: **HV** (ví dụ `HVUPDATE`, file `lenh/hv-update.lsp`)
- Repo GitHub: **buiduyduc16012002-web/hv-lisp** (remote `origin`; `upstream` là repo gốc)
- Thư mục cài trên máy Windows (AutoCAD nạp từ đây): **`C:\HVLisp`**
- Các giá trị này nằm ở: `src/act-load.lsp` (`ACT:suite-name`, `ACT:install-dir`), `lenh/hv-update.lsp` (`HV:repo`), `tests/check_repo.py` (`PREFIX`, `NETWORK_ALLOWED`). Đổi thì đổi cả ba.

## Cấu trúc

- `src/`: 7 lệnh CT gốc và hàm `ACT:*`. `src/act-load.lsp` là file nạp: tìm thư mục gốc, đọc `VERSION`, nạp `src/` rồi mọi `.lsp` trong `lenh/`.
- `lenh/`: lệnh riêng tiền tố HV. `lenh/danh-sach.txt`: danh sách `TENLENH - mo ta ngan` cho `HVHELP`.
- `update.ps1`: tải nhánh `main` từ GitHub, chép đè vào thư mục cài (dùng bởi `HVUPDATE`). Chỉ ký tự ASCII.
- `VERSION`: phiên bản duy nhất; loader và test đọc từ đây.

## QUY TẮC VIẾT LISP

1. Lệnh mới bắt đầu bằng tiền tố HV, mỗi lệnh một file trong `lenh\` (ngoại lệ có sẵn: `lenh/hv-update.lsp` chứa cả `HVUPDATE` và `HVHELP`). Đầu file chú thích: tên lệnh, mục đích, cách dùng.
2. Không sửa các module trong `src/` trừ khi người dùng yêu cầu rõ.
3. Chữ hiện trên dòng lệnh dùng tiếng Việt KHÔNG DẤU (file trong `lenh/` chỉ ký tự ASCII).
4. Khai báo đủ biến cục bộ; kiểm tra nil trước `strcat`, `rtos`, `car`; `(vl-load-com)` trước `vlax-*`; `vlax-curve-*` bọc `vl-catch-all-apply`; lệnh có sửa bản vẽ dùng `ACT:undo-start` / `ACT:undo-end` và `*error*` trả lại biến hệ thống.
5. Dùng lại hàm `ACT:*` có sẵn trong `src/act-core.lsp`; ưu tiên `entmake`; vòng lặp dùng `cons` + `reverse`.
6. Trước khi commit chạy `python3 tests/check_repo.py` phải PASS.
7. Mỗi lần thêm/sửa lệnh: tăng `VERSION` (sửa lỗi +0.0.1, thêm lệnh +0.1.0), cập nhật `lenh\danh-sach.txt`, README, CHANGELOG, commit mô tả tiếng Việt, push lên `main`.
8. Không đưa mật khẩu, token, bản vẽ hay số liệu dự án vào repo.

## Ghi chú

- Chỉ `lenh/hv-update.lsp` được gọi mạng (WScript.Shell, PowerShell); test chặn mọi file khác.
- `scripts/package_release.sh` dùng `git archive HEAD`: file mới phải commit rồi mới vào ZIP.
- VPS không có AutoCAD: thử lệnh thật qua MCP `autocad` (nếu nối được) hoặc nhờ người dùng thử trên Windows.
