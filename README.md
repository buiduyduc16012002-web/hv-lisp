# HVLisp

Bộ Lisp riêng dựa trên AutoLISP Civil Tools Community (GPL-3.0-or-later). Giữ nguyên 7 lệnh `CT` gốc, thêm lệnh riêng tiền tố `HV` trong thư mục `lenh/`, có lệnh tự cập nhật từ GitHub ngay trong AutoCAD.

- Repo: https://github.com/buiduyduc16012002-web/hv-lisp
- Thư mục cài trên máy: `C:\HVLisp`
- Phiên bản: xem file [VERSION](VERSION)

## Cài đặt HVLisp (lần đầu)

1. Mở **PowerShell** trên máy Windows, dán nguyên dòng dưới rồi Enter. Lệnh tải bộ HVLisp mới nhất từ GitHub vào `C:\HVLisp`:

   ```powershell
   [Net.ServicePointManager]::SecurityProtocol='Tls12'; $r='buiduyduc16012002-web/hv-lisp'; $f="$env:TEMP\cai-lisp.ps1"; iwr -UseBasicParsing "https://raw.githubusercontent.com/$r/main/update.ps1" -OutFile $f; powershell -NoProfile -ExecutionPolicy Bypass -File $f -Repo $r -Dest 'C:\HVLisp'
   ```

   Hiện `Updated C:\HVLisp from ...` là xong.
2. Cách tay (nếu không dùng PowerShell): lấy file `hvlisp-v<phiên bản>.zip`, chuột phải → *Extract All* → chọn `C:\` (chỉ `C:\`, không thêm tên thư mục). Bên trong ZIP có sẵn thư mục `HVLisp`, nên sẽ được `C:\HVLisp\src\act-load.lsp`.
3. AutoCAD: `OPTIONS` → tab Files → *Trusted Locations* → thêm `C:\HVLisp\...` (dấu `...` để tin cả thư mục con), tránh cảnh báo bảo mật khi nạp.
4. Gõ `APPLOAD` → chọn `C:\HVLisp\src\act-load.lsp` → Load. Muốn tự nạp mỗi lần mở AutoCAD: trong `APPLOAD` bấm *Contents...* (Startup Suite) → Add file đó.
5. Dòng lệnh hiện `HVLisp v<phiên bản> - go HVHELP de xem lenh` là xong.

## Cập nhật

Gõ `UPDATE` (hoặc `HVUPDATE`) trong AutoCAD. Lệnh chạy `update.ps1` (PowerShell, cửa sổ ẩn) tải nhánh `main` của repo về và chép đè vào `C:\HVLisp`, rồi nạp lại. Kết quả: `Cap nhat: v<cũ> -> v<mới>` hoặc `Dang la ban moi nhat`. Cần Internet và repo để **public**.

`UPDATE`/`HVUPDATE` là lệnh duy nhất gọi mạng; các lệnh khác không kết nối Internet.

## Danh sách lệnh

| Lệnh | Việc làm |
| --- | --- |
| `CTCOORD` | Ghi số hiệu và tọa độ X/Y/Z cho điểm POINT |
| `CTEXPORT` | Xuất điểm POINT và chữ TEXT ra CSV |
| `CTIMPORT` | Nhập điểm POINT từ CSV có cột x, y, z |
| `CTELEV` | Tạo hoặc cập nhật nhãn cao độ tại điểm |
| `CTCHAINAGE` | Ghi lý trình và khoảng cách tới đường tim |
| `CTINTERP` | Nội suy cao độ giữa 2 điểm khống chế |
| `CTPROFILE` | Lập bảng lý trình, cao độ, tọa độ, khoảng cách tới tim |
| `TDXM` | Thống kê cọc trụ đất xi măng (vòng tròn) có tâm nằm trong polyline bao; chọn vòng tròn mẫu để lọc theo layer và đường kính ; xong lệnh các cọc đếm được đang được chọn, gõ `P` để chọn lại (tên ngắn của `HVTDXM`) |
| `HVTDXM` | Giống `TDXM` |
| `FH` | Quét chọn, hatch đặc (SOLID, layer HATCH) từng vùng kín: vòng tròn, polyline kín, ellipse, spline, region; bỏ qua đối tượng hở và đối tượng đã có hatch; chạy ngay sau `TDXM` thì hatch đúng các cọc vừa đếm (tên ngắn của `HVFH`) |
| `HVFH` | Giống `FH` |
| `SUMHATCH` | Chọn đơn vị bản vẽ (M/MM, nhớ lần trước), quét chọn hatch, ghi `S=… m2` lên giữa từng vùng, click 1 điểm ghi tổng diện tích (layer CHU); chạy lại thì cập nhật nhãn cũ (tên ngắn của `HVSUMHATCH`) |
| `HVSUMHATCH` | Giống `SUMHATCH` |
| `DAL` | Kích thước liên tiếp, chữ luôn chính giữa: ghi xong 1 kích thước thì click điểm tiếp để DIM nối tiếp theo từng đoạn (cùng khoảng cách, cùng phía); `C` (CON) DIM liên tiếp thẳng hàng, gióng vuông góc như DIMCONTINUE; `D` về chế độ theo đoạn; `M` chuỗi mới; `U` xóa cái vừa ghi; ESC thoát. Thay alias DAL của AutoCAD (lệnh gốc vẫn gọi bằng `DIMALIGNED`) (tên ngắn của `HVDAL`) |
| `HVDAL` | Giống `DAL` |
| `UPDATE` | Cập nhật HVLisp bản mới nhất từ GitHub (tên ngắn của `HVUPDATE`) |
| `HVUPDATE` | Cập nhật HVLisp bản mới nhất từ GitHub |
| `HVHELP` | Xem danh sách lệnh (đọc `lenh/danh-sach.txt`) |

Thêm lệnh mới: xem quy tắc trong [CLAUDE.md](CLAUDE.md).

---

Phần dưới là tài liệu của bộ gốc.

## AutoLISP Civil Tools Community

Small, auditable GPL-3.0-or-later tools for civil-survey work in AutoCAD-compatible CAD software.

**Status:** v0.2.0 source is ready for community CAD testing. This is an independent public project and contains no code or data from private commercial toolkits.

[Huong dan tieng Viet khong dau](docs/README.vi.md) | [Command reference](docs/COMMANDS.md) | [Roadmap](ROADMAP.md)

## Commands

| Command | Purpose |
| --- | --- |
| `CTCOORD` | Label selected POINT entities with ID and WCS X/Y/Z coordinates. |
| `CTEXPORT` | Export selected POINT and TEXT entities to a WCS CSV file. |
| `CTIMPORT` | Import POINT entities from a CSV file with `x`, `y`, and `z` columns. |
| `CTELEV` | Create or update an elevation label at a selected POINT. |
| `CTCHAINAGE` | Label station and absolute offset for POINT entities along a selected curve. |
| `CTINTERP` | Interpolate clamped elevation labels between two control POINT entities. |
| `CTPROFILE` | Create a station/elevation/offset table for POINT entities along a selected curve. |

## Install

1. Download the release ZIP and verify it with `CHECKSUMS.txt`.
2. Extract it to a writable local folder.
3. In AutoCAD or BricsCAD, run `APPLOAD` and load `src/act-load.lsp`.
4. Confirm that the command line reports the version in `VERSION`, then run a command above.

The loader makes no network calls and collects no telemetry. In HVLisp, only the `UPDATE`/`HVUPDATE` command downloads from GitHub, and only when you run it.

## Coordinate and data policy

All exported/imported coordinates and calculation inputs are WCS values. Entity DXF points are converted from OCS to WCS, and interactive table placement is converted from the current UCS to WCS. CSV files use the host CAD text encoding; UTF-8 output is not claimed until verified in supported Windows CAD versions.

`CTCHAINAGE` uses the selected curve start as station zero. Offsets are unsigned distances. `CTINTERP` projects targets in the WCS XY plane and clamps values to the elevation range between the two controls.

## Compatibility and test status

The target is AutoCAD and BricsCAD on Windows with Visual LISP curve/ActiveX support. Static QA and package validation run on every push. Interactive behavior has **not yet been verified in a real CAD runtime** because this Linux VPS has no AutoCAD, BricsCAD, or Wine installation. See [TEST_REPORT.md](TEST_REPORT.md) and the reproducible Windows checklist in [docs/CAD_TEST_MATRIX.md](docs/CAD_TEST_MATRIX.md).

Never rely on generated labels or CSV files as the sole source for production survey decisions. Review units, coordinate system, alignment direction, and results in the drawing.

## Development

```bash
python3 tests/check_repo.py
bash scripts/package_release.sh
unzip -t "dist/hvlisp-v$(cat VERSION).zip"
```

Please read [CONTRIBUTING.md](CONTRIBUTING.md). Report vulnerabilities privately using [SECURITY.md](SECURITY.md), not a public issue.

## License

Copyright (C) 2026 Truong Hoa and contributors. HVLisp changes (lenh/, update.ps1, loader) 2026. Licensed under [GPL-3.0-or-later](LICENSE).
