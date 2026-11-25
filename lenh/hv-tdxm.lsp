;;; Lenh: TDXM (ten ngan), HVTDXM
;;; Muc dich: thong ke coc tru dat xi mang (TDXM) ve bang vong tron CIRCLE co TAM nam
;;;           trong mot duong bao kin (polyline). In tong so coc, chia theo layer va
;;;           duong kinh, so coc cat duong bao; to sang cac coc dem duoc; tuy chon ghi
;;;           so luong vao ban ve (layer CHU).
;;; Cach dung: go TDXM -> chon polyline bao -> chon 1 vong tron TDXM mau (cung layer,
;;;            cung ban kinh moi duoc dem; Enter = dem moi vong tron) -> xem ket qua
;;;            -> chon diem ghi chu (Enter = khong ghi).
;;; Gioi han: chi dem CIRCLE ve truc tiep trong layout hien hanh, khong dem vong tron
;;;           nam trong block.
;;; SPDX-License-Identifier: GPL-3.0-or-later

(vl-load-com)

;;; Danh sach dinh WCS cua duong bao. Doan cong cua polyline duoc chia nho.
(defun HV:tdxm-boundary (entity / kind data endp result bulges bulge k m j pt total step)
  (setq kind (ACT:entity-kind entity) result nil)
  (setq endp (ACT:safe-call 'vlax-curve-getEndParam (list entity)))
  (cond
    ((not (numberp endp)) nil)
    ((member kind '("LWPOLYLINE" "POLYLINE"))
      (setq bulges nil)
      (if (= kind "LWPOLYLINE")
        (progn
          (setq data (entget entity))
          (foreach item data
            (if (= (car item) 42) (setq bulges (cons (cdr item) bulges)))
          )
          (setq bulges (reverse bulges))
        )
      )
      (setq k 0)
      (while (< k (fix (+ endp 0.5)))
        (setq bulge (nth k bulges))
        ;; LWPOLYLINE: doan thang 1 diem, doan cong 16 diem; POLYLINE cu: luon 8 diem.
        (setq m (cond ((= kind "POLYLINE") 8) ((and bulge (> (abs bulge) 1e-9)) 16) (T 1)) j 0)
        (repeat m
          (setq pt (ACT:safe-call 'vlax-curve-getPointAtParam (list entity (+ k (/ (float j) m)))))
          (if pt (setq result (cons pt result)))
          (setq j (1+ j))
        )
        (setq k (1+ k))
      )
      (setq pt (ACT:safe-call 'vlax-curve-getPointAtParam (list entity endp)))
      (if pt (setq result (cons pt result)))
    )
    (T
      ;; Spline, ellipse, circle...: chia 360 diem deu theo chieu dai.
      (setq total (ACT:safe-call 'vlax-curve-getDistAtParam (list entity endp)))
      (if (and (numberp total) (> total 0.0))
        (progn
          (setq step (/ total 360.0) k 0)
          (repeat 361
            (setq pt (ACT:safe-call 'vlax-curve-getPointAtDist (list entity (min total (* k step)))))
            (if pt (setq result (cons pt result)))
            (setq k (1+ k))
          )
        )
      )
    )
  )
  (reverse result)
)

;;; Diem (x, y) nam trong da giac poly (danh sach diem) hay khong - thuat toan tia.
(defun HV:tdxm-inside-p (x y poly / inside a xa ya xb yb)
  (setq inside nil a (last poly))
  (foreach b poly
    (setq xa (car a) ya (cadr a) xb (car b) yb (cadr b))
    (if (and (not (eq (> ya y) (> yb y)))
             (< x (+ xa (/ (* (- xb xa) (- y ya)) (- yb ya)))))
      (setq inside (not inside))
    )
    (setq a b)
  )
  inside
)

(defun HV:tdxm-count-add (key stats / pair)
  (if (setq pair (assoc key stats))
    (subst (cons key (1+ (cdr pair))) pair stats)
    (cons (cons key 1) stats)
  )
)

(defun C:HVTDXM (/ *error* document boundary poly sample sdata layer radius all index
                   entity data center r count cut inside-set stats minx maxx miny maxy
                   closest key point height pair)
  (defun *error* (message) (ACT:report-error message document))
  (setq document (ACT:undo-start))
  (setq boundary (car (entsel "\nChon polyline bao vung TDXM: ")))
  (cond
    ((not boundary) (prompt "\nTDXM: chua chon duong bao."))
    ((not (ACT:curve-p boundary)) (prompt "\nTDXM: doi tuong vua chon khong phai polyline/duong cong."))
    ((< (length (setq poly (HV:tdxm-boundary boundary))) 3)
      (prompt "\nTDXM: duong bao qua it dinh, khong tinh duoc."))
    (T
      (if (not (ACT:safe-call 'vlax-curve-isClosed (list boundary)))
        (prompt "\nTDXM: duong bao chua kin - tu noi diem cuoi ve diem dau.")
      )
      ;; Vong tron mau: loc theo layer va ban kinh.
      (setq sample (car (entsel "\nChon 1 vong tron TDXM mau <Enter = dem moi vong tron>: ")))
      (cond
        ((and sample (= (ACT:entity-kind sample) "CIRCLE"))
          (setq sdata (entget sample) layer (cdr (assoc 8 sdata)) radius (cdr (assoc 40 sdata)))
          (prompt (strcat "\nTDXM: chi dem vong tron layer " layer ", D=" (rtos (* 2.0 radius) 2 3)))
        )
        (sample (prompt "\nTDXM: doi tuong mau khong phai CIRCLE - dem moi vong tron."))
      )
      (setq minx (apply 'min (mapcar 'car poly)) maxx (apply 'max (mapcar 'car poly))
            miny (apply 'min (mapcar 'cadr poly)) maxy (apply 'max (mapcar 'cadr poly)))
      (setq all (ssget "_X" (list '(0 . "CIRCLE") (cons 410 (getvar "CTAB")))))
      (setq index 0 count 0 cut 0 stats nil inside-set (ssadd) height nil)
      (if all
        (repeat (sslength all)
          (setq entity (ssname all index) data (entget entity) r (cdr (assoc 40 data)))
          (setq center (ACT:safe-call 'trans (list (cdr (assoc 10 data)) entity 0)))
          (if (and center
                   (numberp r)
                   (or (not layer) (= (strcase (cdr (assoc 8 data))) (strcase layer)))
                   (or (not radius) (equal r radius (* 0.001 radius)))
                   (<= minx (car center) maxx)
                   (<= miny (cadr center) maxy)
                   (HV:tdxm-inside-p (car center) (cadr center) poly))
            (progn
              (setq count (1+ count))
              (ssadd entity inside-set)
              (setq key (strcat (cdr (assoc 8 data)) "  D=" (rtos (* 2.0 r) 2 3)))
              (setq stats (HV:tdxm-count-add key stats))
              (if (or (not height) (> (* 2.0 r) height)) (setq height (* 2.0 r)))
              (setq closest (ACT:safe-call 'vlax-curve-getClosestPointTo (list boundary center)))
              (if (and closest (< (distance (list (car center) (cadr center)) (list (car closest) (cadr closest))) r))
                (setq cut (1+ cut))
              )
            )
          )
          (setq index (1+ index))
        )
      )
      (if (= count 0)
        (prompt (strcat "\nTDXM: khong co vong tron nao co tam nam trong duong bao."
                        (if layer " Kiem tra lai vong tron mau (layer, duong kinh)." "")))
        (progn
          (prompt "\n=== THONG KE TDXM TRONG VUNG ===")
          (foreach pair (reverse stats)
            (prompt (strcat "\n  Layer " (car pair) " : " (itoa (cdr pair)) " coc"))
          )
          (prompt (strcat "\n  TONG CONG: " (itoa count) " coc"))
          (if (> cut 0)
            (prompt (strcat "\n  (trong do " (itoa cut) " coc cat duong bao, tam van nam trong)"))
          )
          (setq point (getpoint "\nDiem ghi so luong vao ban ve <Enter = khong ghi>: "))
          (if point
            (progn
              (ACT:make-text (ACT:ucs-to-wcs point) (strcat "TDXM: " (itoa count) " coc")
                             (ACT:ensure-layer "CHU" 4) (if height (* 1.5 height) (getvar "TEXTSIZE")))
              (prompt "\nTDXM: da ghi so luong (layer CHU).")
            )
          )
          (sssetfirst nil inside-set)
          (prompt "\nTDXM: cac coc dem duoc dang duoc chon (to sang). Nhan Esc de bo chon.")
        )
      )
    )
  )
  (ACT:undo-end document)
  (setq document nil)
  (princ)
)

;;; Ten goi nhanh (nguoi dung yeu cau).
(defun C:TDXM ()
  (C:HVTDXM)
)

(princ)
