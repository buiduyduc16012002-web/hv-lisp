;;; Lenh: SUMHATCH (ten ngan), HVSUMHATCH
;;; Muc dich: cong nhanh dien tich cac HATCH duoc chon. In so hatch, tong dien tich,
;;;           chia theo layer; tu doi ra m2 theo INSUNITS (mm, cm, m). Khong sua ban ve.
;;; Cach dung: go SUMHATCH -> quet chon vung (chi lay HATCH, doi tuong khac tu bo qua)
;;;            -> Enter. Neu dang co tap chon san thi tinh ngay tap do.
;;; SPDX-License-Identifier: GPL-3.0-or-later

(vl-load-com)

;;; He so doi (don vi ve)^2 -> m2 theo INSUNITS; nil neu khong ro don vi.
(defun HV:sumhatch-m2-factor (/ units)
  (setq units (getvar "INSUNITS"))
  (cond
    ((= units 4) 1e-6)   ; mm
    ((= units 5) 1e-4)   ; cm
    ((= units 14) 0.01)  ; dm
    ((= units 6) 1.0)    ; m
  )
)

(defun HV:sumhatch-text (area factor)
  (if factor
    (strcat (rtos (* area factor) 2 3) " m2")
    (strcat (rtos area 2 3) " (don vi ve)^2")
  )
)

(defun C:HVSUMHATCH (/ set index entity obj area total count failed stats pair key factor)
  (prompt "\nSUMHATCH: quet chon cac vung hatch (chi lay HATCH).")
  (setq set (ssget '((0 . "HATCH"))))
  (if (not set)
    (prompt "\nSUMHATCH: khong chon duoc hatch nao.")
    (progn
      (setq index 0 total 0.0 count 0 failed 0 stats nil factor (HV:sumhatch-m2-factor))
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
          (prompt (strcat "\n  Layer " (car pair) " : " (HV:sumhatch-text (cdr pair) factor)))
        )
      )
      (prompt (strcat "\n  So hatch: " (itoa count)))
      (prompt (strcat "\n  TONG DIEN TICH: " (HV:sumhatch-text total factor)))
      (if (not factor)
        (prompt "\n  (INSUNITS chua dat mm/cm/m nen de nguyen don vi ve: ve mm thi chia 1.000.000 ra m2)")
      )
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
