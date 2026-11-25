;;; Lenh: TTL (ten ngan), HVTTL
;;; Muc dich: tinh tong chieu dai (Total Length) cac LINE, LWPOLYLINE, POLYLINE (2D, 3D)
;;;           duoc quet chon. Hien hop thoai Alert: so doi tuong theo loai, tong chieu dai
;;;           dinh dang de doc (nhom hang nghin bang dau cach), theo don vi ban ve hien
;;;           hanh (LUNITS, LUPREC; ten don vi theo INSUNITS).
;;;           Ghi chieu dai "L=..." len giua tung doi tuong, xoay theo huong doi tuong,
;;;           chu cao bang chu kich thuoc (DIMTXT x DIMSCALE), layer CHU. Chay lai tren
;;;           doi tuong da ghi: nhan cu duoc cap nhat, khong ghi chong. Hoan tac: U.
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

(setq HV:ttl-app "HVTTL")

;;; Nhan da ghi truoc day: danh sach (handle-doi-tuong . ename-text).
(defun HV:ttl-old-labels (/ set index entity xdata handle result)
  (setq set (ssget "_X" (list '(0 . "TEXT") (list -3 (list HV:ttl-app)))) index 0 result nil)
  (if set
    (repeat (sslength set)
      (setq entity (ssname set index))
      (setq xdata (cdr (assoc HV:ttl-app (cdr (assoc -3 (entget entity (list HV:ttl-app)))))))
      (setq handle (cdr (assoc 1005 xdata)))
      (if handle (setq result (cons (cons handle entity) result)))
      (setq index (1+ index))
    )
  )
  result
)

;;; Chu cao bang chu kich thuoc hien hanh; DIMSCALE = 0 hoac khong hop le thi TEXTSIZE.
(defun HV:ttl-text-height (/ scale size)
  (setq scale (getvar "DIMSCALE") size (getvar "DIMTXT"))
  (if (and (numberp scale) (> scale 0.0) (numberp size) (> size 0.0))
    (* scale size)
    (getvar "TEXTSIZE")
  )
)

;;; Ghi/cap nhat nhan chieu dai tai giua doi tuong. Tra ve "moi", "cu" hoac nil.
(defun HV:ttl-label (entity len height layer old-labels / mid param deriv ang point handle old data)
  (setq mid (ACT:safe-call 'vlax-curve-getPointAtDist (list entity (/ len 2.0))))
  (if mid (setq param (ACT:safe-call 'vlax-curve-getParamAtPoint (list entity mid))))
  (if param (setq deriv (ACT:safe-call 'vlax-curve-getFirstDeriv (list entity param))))
  (if (and mid deriv)
    (progn
      (setq ang (angle '(0.0 0.0) (list (car deriv) (cadr deriv))))
      ;; Xoay chu cho de doc (khong lon nguoc).
      (if (and (> ang (* 0.5 pi)) (<= ang (* 1.5 pi))) (setq ang (+ ang pi)))
      ;; Dat chu phia tren doi tuong, cach 0.7 chieu cao chu.
      (setq point (polar mid (+ ang (* 0.5 pi)) (* 0.7 height)))
      (setq handle (cdr (assoc 5 (entget entity))) old (cdr (assoc handle old-labels)))
      (if old
        (progn
          (setq data (entget old))
          (foreach pair (list (cons 1 (strcat "L=" (HV:ttl-format len))) (cons 10 point) (cons 11 point)
                              (cons 40 height) (cons 50 ang))
            (setq data (subst pair (assoc (car pair) data) data))
          )
          (entmod data)
          (entupd old)
          "cu"
        )
        (if (entmakex
              (list
                (cons 0 "TEXT") (cons 8 layer) (cons 10 point) (cons 11 point) (cons 40 height)
                (cons 1 (strcat "L=" (HV:ttl-format len))) (cons 7 (getvar "TEXTSTYLE"))
                (cons 50 ang) (cons 72 1) (cons 73 2)
                (list -3 (list HV:ttl-app (cons 1005 handle)))
              )
            )
          "moi"
        )
      )
    )
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

(defun C:HVTTL (/ *error* document old-dimzin set index entity kind len total count failed kinds pair unit text
                  height layer old-labels result labelled updated)
  (defun *error* (message)
    (if old-dimzin (setvar "DIMZIN" old-dimzin))
    (ACT:report-error message document)
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
      (setq document (ACT:undo-start))
      (regapp HV:ttl-app)
      (setq height (HV:ttl-text-height) layer (ACT:ensure-layer "CHU" 4)
            old-labels (HV:ttl-old-labels) labelled 0 updated 0)
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
            (setq result (HV:ttl-label entity len height layer old-labels))
            (cond ((= result "moi") (setq labelled (1+ labelled)))
                  ((= result "cu") (setq updated (1+ updated))))
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
      (setq text (strcat text "\n\nDa ghi chieu dai len " (itoa labelled) " doi tuong moi, cap nhat "
                         (itoa updated) " nhan cu (layer CHU)."))
      (if (> failed 0)
        (setq text (strcat text "\n\nBo qua " (itoa failed) " doi tuong khong doc duoc chieu dai."))
      )
      (prompt (strcat "\nTTL: " (itoa count) " doi tuong, TONG = " (HV:ttl-format total) " " unit))
      (setvar "DIMZIN" old-dimzin)
      (setq old-dimzin nil)
      (setq document (ACT:undo-end document))
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
