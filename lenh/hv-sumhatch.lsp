;;; Lenh: SUMHATCH (ten ngan), HVSUMHATCH
;;; Muc dich: cong nhanh dien tich cac HATCH duoc chon. In so hatch, tong dien tich
;;;           theo don vi ve (giong o Area cua PROPERTIES), chia theo layer, kem dong doi
;;;           ra m2 cho 2 truong hop ve theo m va ve theo mm. Khong sua ban ve.
;;;           (Khong dua vao INSUNITS: nhieu binh do ve theo m nhung INSUNITS van la mm.)
;;; Cach dung: go SUMHATCH -> quet chon vung (chi lay HATCH, doi tuong khac tu bo qua)
;;;            -> Enter. Neu dang co tap chon san thi tinh ngay tap do.
;;; SPDX-License-Identifier: GPL-3.0-or-later

(vl-load-com)

;;; Dien tich theo don vi ve, giu 3 chu so le.
(defun HV:sumhatch-text (area)
  (rtos area 2 3)
)

(defun C:HVSUMHATCH (/ set index entity obj area total count failed stats pair key)
  (prompt "\nSUMHATCH: quet chon cac vung hatch (chi lay HATCH).")
  (setq set (ssget '((0 . "HATCH"))))
  (if (not set)
    (prompt "\nSUMHATCH: khong chon duoc hatch nao.")
    (progn
      (setq index 0 total 0.0 count 0 failed 0 stats nil)
      (repeat (sslength set)
        (setq entity (ssname set index)
              obj (vlax-ename->vla-object entity)
              area (ACT:safe-call 'vla-get-Area (list obj)))
        (if (numberp area)
          (progn
            (setq total (+ total area) count (1+ count))
            (setq key (cdr (assoc 8 (entget entity))))
            (if (setq pair (assoc key stats))
              (setq stats (subst (cons key (+ (cdr pair) area)) pair stats))
              (setq stats (cons (cons key area) stats))
            )
          )
          (setq failed (1+ failed))
        )
        (setq index (1+ index))
      )
      (prompt "\n=== TONG DIEN TICH HATCH ===")
      (if (> (length stats) 1)
        (foreach pair (reverse stats)
          (prompt (strcat "\n  Layer " (car pair) " : " (HV:sumhatch-text (cdr pair))))
        )
      )
      (prompt (strcat "\n  So hatch: " (itoa count)))
      (prompt (strcat "\n  TONG DIEN TICH: " (HV:sumhatch-text total) " (don vi ve)^2"))
      (prompt (strcat "\n    = " (rtos total 2 3) " m2 neu ban ve theo m (binh do, mat bang tong the)"))
      (prompt (strcat "\n    = " (rtos (* total 1e-6) 2 3) " m2 neu ban ve theo mm"))
      (if (> failed 0)
        (prompt (strcat "\n  Bo qua " (itoa failed) " hatch khong doc duoc dien tich (hatch loi bien)."))
      )
    )
  )
  (princ)
)

;;; Ten goi nhanh (nguoi dung yeu cau).
(defun C:SUMHATCH ()
  (C:HVSUMHATCH)
)

(princ)
