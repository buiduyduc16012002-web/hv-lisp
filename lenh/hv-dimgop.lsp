;;; Lenh: DIMGOP (ten ngan), HVDIMGOP
;;; Muc dich: gom cac kich thuoc lien tiep BANG NHAU thanh 1 kich thuoc, ghi dang
;;;           "5x5.00=25.00" (so doan x gia tri = tong; tong do AutoCAD tu do).
;;;           Chon nhieu chuoi cung luc duoc: moi doan cac kich thuoc lien nhau, cung
;;;           duong kich thuoc va cung gia tri hien thi duoc gom rieng; kich thuoc le
;;;           giu nguyen. Vd 5,5,5,3,3 -> "3x5.00=15.00" va "2x3.00=6.00".
;;; Cach dung: go DIMGOP -> quet chon cac kich thuoc -> Enter.
;;;            Kich thuoc dau moi nhom duoc keo dai va doi chu, cac kich thuoc con lai
;;;            bi xoa. Chi gom kich thuoc thang (aligned, linear/rotated). Hoan tac: U.
;;; SPDX-License-Identifier: GPL-3.0-or-later

(vl-load-com)

;;; Huong do (vecto don vi) cua kich thuoc: aligned theo 13->14, rotated theo goc 50.
(defun HV:dimgop-dir (data / p13 p14 dx dy len ang)
  (if (= (logand (cdr (assoc 70 data)) 7) 1)
    (progn
      (setq p13 (cdr (assoc 13 data)) p14 (cdr (assoc 14 data)))
      (if (and p13 p14)
        (progn
          (setq dx (- (car p14) (car p13)) dy (- (cadr p14) (cadr p13)) len (sqrt (+ (* dx dx) (* dy dy))))
          (if (> len 1e-9) (list (/ dx len) (/ dy len)))
        )
      )
    )
    (progn
      (setq ang (cdr (assoc 50 data)))
      (if (numberp ang) (list (cos ang) (sin ang)))
    )
  )
)

;;; Thong tin 1 kich thuoc theo truc u (ux, uy) goc (ox, oy):
;;; (ename obj tmin tmax diem-min diem-max offset nhan p13-la-min) hoac nil.
(defun HV:dimgop-info (ent ux uy ox oy / data p13 p14 p10 obj meas lfac prec t13 t14 dir)
  (setq data (entget ent)
        p13 (cdr (assoc 13 data)) p14 (cdr (assoc 14 data)) p10 (cdr (assoc 10 data))
        obj (vlax-ename->vla-object ent))
  (setq meas (ACT:safe-call 'vla-get-Measurement (list obj))
        lfac (ACT:safe-call 'vla-get-LinearScaleFactor (list obj))
        prec (ACT:safe-call 'vla-get-PrimaryUnitsPrecision (list obj)))
  (if (and p13 p14 p10 (numberp meas))
    (progn
      (setq dir (HV:dimgop-dir data))
      (setq t13 (+ (* (- (car p13) ox) ux) (* (- (cadr p13) oy) uy))
            t14 (+ (* (- (car p14) ox) ux) (* (- (cadr p14) oy) uy)))
      ;; Chi lay kich thuoc song song truc u (cung chuoi).
      (if (and dir (< (abs (- (* ux (cadr dir)) (* uy (car dir)))) 1e-3) (> (abs (- t14 t13)) 1e-9))
        (list ent obj (min t13 t14) (max t13 t14)
              (if (< t13 t14) p13 p14) (if (< t13 t14) p14 p13)
              (- (* ux (- (cadr p10) oy)) (* uy (- (car p10) ox)))
              (rtos (* meas (if (numberp lfac) lfac 1.0)) 2 (if (numberp prec) prec 2))
              (< t13 t14))
      )
    )
  )
)

;;; Gom 1 nhom (>= 2 kich thuoc da sap xep). Tra ve chu da ghi.
(defun HV:dimgop-merge (group / base n start end override)
  (setq base (car group) n (length group)
        start (nth 4 base) end (nth 5 (last group)))
  (if (nth 8 base)
    (progn
      (vla-put-ExtLine1Point (nth 1 base) (vlax-3d-point start))
      (vla-put-ExtLine2Point (nth 1 base) (vlax-3d-point end))
    )
    (progn
      (vla-put-ExtLine1Point (nth 1 base) (vlax-3d-point end))
      (vla-put-ExtLine2Point (nth 1 base) (vlax-3d-point start))
    )
  )
  (setq override (strcat (itoa n) "x" (nth 7 base) "=<>"))
  (vla-put-TextOverride (nth 1 base) override)
  (foreach rec (cdr group) (entdel (car rec)))
  (vl-catch-all-apply 'vla-Update (list (nth 1 base)))
  ;; Chu ve chinh giua.
  (vl-catch-all-apply 'vl-cmdf (list "_.DIMTEDIT" (car base) "_C"))
  override
)

(defun C:HVDIMGOP (/ *error* document old-cmdecho set index ent data first p13 dir len
                     ux uy ox oy infos rec skipped tol sorted groups group prev merged removed)
  (defun *error* (message)
    (if old-cmdecho (setvar "CMDECHO" old-cmdecho))
    (ACT:report-error message document)
  )
  (prompt "\nDIMGOP: quet chon cac kich thuoc lien tiep can gom.")
  (setq set (ssget '((0 . "DIMENSION"))))
  (cond
    ((not set) (prompt "\nDIMGOP: khong chon duoc kich thuoc nao."))
    (T
      (setq old-cmdecho (getvar "CMDECHO"))
      (setvar "CMDECHO" 0)
      (setq document (ACT:undo-start))
      ;; Lay kich thuoc thang (70 & 7 = 0 rotated, 1 aligned).
      (setq index 0 infos nil skipped 0 first nil)
      (repeat (sslength set)
        (setq ent (ssname set index) data (entget ent))
        (if (member (logand (cdr (assoc 70 data)) 7) '(0 1))
          (progn
            (if (not first)
              (progn
                (setq first ent p13 (cdr (assoc 13 data)) dir (HV:dimgop-dir data)
                      len (ACT:safe-call 'vla-get-Measurement (list (vlax-ename->vla-object ent))))
                (if (and dir p13 (numberp len))
                  (setq ux (car dir) uy (cadr dir) ox (car p13) oy (cadr p13) tol (+ 1e-6 (* 1e-4 len)))
                  (setq first nil)
                )
              )
            )
            (setq rec (if first (HV:dimgop-info ent ux uy ox oy)))
            (if rec (setq infos (cons rec infos)) (setq skipped (1+ skipped)))
          )
          (setq skipped (1+ skipped))
        )
        (setq index (1+ index))
      )
      ;; Sap xep theo duong kich thuoc (offset) roi theo vi tri doc truc.
      (setq sorted
        (vl-sort infos
          '(lambda (a b)
             (if (> (abs (- (nth 6 a) (nth 6 b))) (* 100.0 tol))
               (< (nth 6 a) (nth 6 b))
               (< (nth 2 a) (nth 2 b))
             )
           )
        )
      )
      ;; Chia nhom: lien nhau, cung duong kich thuoc, cung gia tri hien thi.
      (setq groups nil group nil prev nil)
      (foreach rec sorted
        (if (and prev
                 (<= (abs (- (nth 6 rec) (nth 6 prev))) (* 100.0 tol))
                 (<= (abs (- (nth 2 rec) (nth 3 prev))) tol)
                 (= (nth 7 rec) (nth 7 prev)))
          (setq group (cons rec group))
          (progn
            (if group (setq groups (cons (reverse group) groups)))
            (setq group (list rec))
          )
        )
        (setq prev rec)
      )
      (if group (setq groups (cons (reverse group) groups)))
      ;; Gom cac nhom >= 2.
      (setq merged 0 removed 0)
      (foreach group (reverse groups)
        (if (> (length group) 1)
          (progn
            (prompt (strcat "\n  Gom " (itoa (length group)) " kich thuoc -> " (HV:dimgop-merge group)))
            (setq merged (1+ merged) removed (+ removed (1- (length group))))
          )
        )
      )
      (if (= merged 0)
        (prompt "\nDIMGOP: khong co kich thuoc lien tiep nao bang nhau de gom.")
        (prompt (strcat "\nDIMGOP: da gom " (itoa merged) " nhom, xoa " (itoa removed) " kich thuoc thua. (<> = tong do tu dong)"))
      )
      (if (> skipped 0)
        (prompt (strcat "\n  Bo qua " (itoa skipped) " kich thuoc khong cung huong / khong phai kich thuoc thang."))
      )
      (setq document (ACT:undo-end document))
      (setvar "CMDECHO" old-cmdecho)
      (setq old-cmdecho nil)
    )
  )
  (princ)
)

;;; Ten goi nhanh (nguoi dung yeu cau).
(defun C:DIMGOP ()
  (C:HVDIMGOP)
)

(princ)
