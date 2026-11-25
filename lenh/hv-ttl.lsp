;;; Lenh: TTL (ten ngan), HVTTL
;;; Muc dich: tinh tong chieu dai (Total Length) cac LINE, LWPOLYLINE, POLYLINE (2D, 3D)
;;;           duoc quet chon. Hien hop thoai Alert: so doi tuong theo loai, tong chieu dai
;;;           dinh dang de doc (nhom hang nghin bang dau cach), theo don vi ban ve hien
;;;           hanh (LUNITS, LUPREC; ten don vi theo INSUNITS). Khong sua ban ve.
;;; Cach dung: go TTL -> quet chon (doi tuong khac tu bo qua) -> Enter -> doc Alert.
;;;            Neu dang co tap chon san thi tinh ngay tap do.
;;; SPDX-License-Identifier: GPL-3.0-or-later

(vl-load-com)

;;; Nhom phan nguyen theo hang nghin: "1234567.891" -> "1 234 567.891".
(defun HV:ttl-group (text / sign dot int frac result)
  (setq sign "")
  (if (= (substr text 1 1) "-") (setq sign "-" text (substr text 2)))
  (setq dot (vl-string-search "." text))
  (if dot
    (setq int (substr text 1 dot) frac (substr text (1+ dot)))
    (setq int text frac "")
  )
  (setq result "")
  (while (> (strlen int) 3)
    (setq result (strcat " " (substr int (- (strlen int) 2)) result)
          int (substr int 1 (- (strlen int) 3)))
  )
  (strcat sign int result frac)
)

;;; Dinh dang so theo LUNITS/LUPREC hien hanh; he thap phan thi nhom hang nghin.
(defun HV:ttl-format (value)
  (if (= (getvar "LUNITS") 2)
    (HV:ttl-group (rtos value 2 (getvar "LUPREC")))
    (rtos value)
  )
)

;;; Ten don vi theo INSUNITS (chi de hien thi).
(defun HV:ttl-unit-name (/ units)
  (setq units (getvar "INSUNITS"))
  (cond
    ((= units 4) "mm")
    ((= units 5) "cm")
    ((= units 14) "dm")
    ((= units 6) "m")
    ((= units 1) "inch")
    ((= units 2) "feet")
    (T "don vi ve")
  )
)

(defun C:HVTTL (/ *error* old-dimzin set index entity kind len total count failed kinds pair unit text)
  (defun *error* (message)
    (if old-dimzin (setvar "DIMZIN" old-dimzin))
    (if (not (ACT:cancelled-error-p message)) (prompt (strcat "\nTTL loi: " message)))
    (princ)
  )
  (prompt "\nTTL: quet chon LINE, LWPOLYLINE, POLYLINE can tinh tong chieu dai.")
  ;; Bo qua POLYLINE dang luoi (mesh 16, polyface 64).
  (setq set (ssget '((-4 . "<OR")
                       (0 . "LINE")
                       (0 . "LWPOLYLINE")
                       (-4 . "<AND") (0 . "POLYLINE") (-4 . "<NOT") (-4 . "&") (70 . 80) (-4 . "NOT>") (-4 . "AND>")
                     (-4 . "OR>"))))
  (if (not set)
    (prompt "\nTTL: khong chon duoc LINE/POLYLINE nao.")
    (progn
      (setq old-dimzin (getvar "DIMZIN"))
      (setvar "DIMZIN" 0) ; giu du so le theo LUPREC, khong cat so 0
      (setq index 0 total 0.0 count 0 failed 0 kinds nil)
      (repeat (sslength set)
        (setq entity (ssname set index) kind (ACT:entity-kind entity))
        (setq len (ACT:safe-call 'vlax-curve-getDistAtParam
                    (list entity (ACT:safe-call 'vlax-curve-getEndParam (list entity)))))
        (if (numberp len)
          (progn
            (setq total (+ total len) count (1+ count))
            (if (setq pair (assoc kind kinds))
              (setq kinds (subst (list kind (1+ (cadr pair)) (+ (caddr pair) len)) pair kinds))
              (setq kinds (cons (list kind 1 len) kinds))
            )
          )
          (setq failed (1+ failed))
        )
        (setq index (1+ index))
      )
      (setq unit (HV:ttl-unit-name))
      (setq text (strcat "TONG CHIEU DAI (TTL)\n\n"))
      (foreach pair (reverse kinds)
        (setq text (strcat text (car pair) ": " (itoa (cadr pair)) " doi tuong = "
                           (HV:ttl-format (caddr pair)) " " unit "\n"))
      )
      (setq text (strcat text "\nSo doi tuong: " (itoa count)
                         "\nTONG: " (HV:ttl-format total) " " unit))
      (if (= unit "mm")
        (setq text (strcat text "\n      = " (HV:ttl-group (rtos (/ total 1000.0) 2 3)) " m (neu ban ve thuc ve theo mm)"))
      )
      (if (> failed 0)
        (setq text (strcat text "\n\nBo qua " (itoa failed) " doi tuong khong doc duoc chieu dai."))
      )
      (prompt (strcat "\nTTL: " (itoa count) " doi tuong, TONG = " (HV:ttl-format total) " " unit))
      (setvar "DIMZIN" old-dimzin)
      (setq old-dimzin nil)
      (alert text)
    )
  )
  (princ)
)

;;; Ten goi nhanh (nguoi dung yeu cau).
(defun C:TTL ()
  (C:HVTTL)
)

(princ)
