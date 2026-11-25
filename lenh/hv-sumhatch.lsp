;;; Lenh: SUMHATCH (ten ngan), HVSUMHATCH
;;; Muc dich: tinh nhanh dien tich HATCH. Ghi dien tich len giua tung vung hatch
;;;           ("S=12.35 m2"), in tong tren dong lenh, roi click 1 diem de ghi TONG dien
;;;           tich vao ban ve. Chu dat tren layer CHU.
;;;           Chay lai tren hatch da ghi: nhan cu duoc cap nhat, khong ghi chong.
;;; Cach dung: go SUMHATCH -> chon don vi ban ve M hoac MM (nho lan truoc, Enter = giu)
;;;            -> quet chon vung (chi lay HATCH) -> Enter -> click diem ghi tong
;;;            (Enter = khong ghi). Hoan tac: go U mot lan.
;;; Khong dua vao INSUNITS: nhieu binh do ve theo m nhung INSUNITS van la mm.
;;; SPDX-License-Identifier: GPL-3.0-or-later

(vl-load-com)

(setq HV:sumhatch-app "HVSUMHATCH")

;;; Don vi ban ve da chon lan truoc (luu trong registry), mac dinh "M".
(defun HV:sumhatch-unit-get (/ value)
  (setq value (getenv "HVLisp_DonViVe"))
  (if (member value '("M" "MM")) value "M")
)

;;; Bao chu nhat cua doi tuong: (min max) hoac nil.
(defun HV:sumhatch-box (obj / result minp maxp)
  (setq result (vl-catch-all-apply 'vla-GetBoundingBox (list obj 'minp 'maxp)))
  (if (and (not (vl-catch-all-error-p result)) minp maxp)
    (list (vlax-safearray->list minp) (vlax-safearray->list maxp))
  )
)

;;; Nhan da ghi truoc day: danh sach (handle-hatch . ename-text).
(defun HV:sumhatch-old-labels (/ set index entity xdata handle result)
  (setq set (ssget "_X" (list '(0 . "TEXT") (list -3 (list HV:sumhatch-app)))) index 0 result nil)
  (if set
    (repeat (sslength set)
      (setq entity (ssname set index))
      (setq xdata (cdr (assoc HV:sumhatch-app (cdr (assoc -3 (entget entity (list HV:sumhatch-app)))))))
      (setq handle (cdr (assoc 1005 xdata)))
      (if handle (setq result (cons (cons handle entity) result)))
      (setq index (1+ index))
    )
  )
  result
)

;;; Tao hoac cap nhat chu can giua tai point. tag = handle hatch, hoac nil cho nhan tong.
(defun HV:sumhatch-label (point text height layer tag old / data xdata)
  (if old
    (progn
      (setq data (entget old))
      (setq data (subst (cons 1 text) (assoc 1 data) data))
      (setq data (subst (cons 40 height) (assoc 40 data) data))
      (setq data (subst (cons 10 point) (assoc 10 data) data))
      (setq data (subst (cons 11 point) (assoc 11 data) data))
      (entmod data)
      (entupd old)
    )
    (progn
      (setq xdata (list -3 (list HV:sumhatch-app (if tag (cons 1005 tag) (cons 1000 "TONG")))))
      (entmakex
        (list
          (cons 0 "TEXT")
          (cons 8 layer)
          (cons 10 point)
          (cons 11 point)
          (cons 40 height)
          (cons 1 text)
          (cons 7 (getvar "TEXTSTYLE"))
          (cons 50 0.0)
          (cons 72 1)
          (cons 73 2)
          xdata
        )
      )
    )
  )
)

(defun C:HVSUMHATCH (/ *error* document unit answer factor set index entity obj area total
                       count failed stats pair key box w h height heights layer old-labels
                       handle center labelled updated point total-height sorted)
  (defun *error* (message) (ACT:report-error message document))
  (setq document (ACT:undo-start))
  ;; 1. Don vi ban ve.
  (setq unit (HV:sumhatch-unit-get))
  (initget "M MM")
  (setq answer (getkword (strcat "\nDon vi ban ve [M/MM] <" unit ">: ")))
  (if answer (setq unit answer))
  (setenv "HVLisp_DonViVe" unit)
  (setq factor (if (= unit "MM") 1e-6 1.0))
  ;; 2. Chon hatch.
  (prompt "\nSUMHATCH: quet chon cac vung hatch (chi lay HATCH).")
  (setq set (ssget '((0 . "HATCH"))))
  (if (not set)
    (prompt "\nSUMHATCH: khong chon duoc hatch nao.")
    (progn
      (regapp HV:sumhatch-app)
      (setq layer (ACT:ensure-layer "CHU" 4)
            old-labels (HV:sumhatch-old-labels)
            index 0 total 0.0 count 0 failed 0 stats nil heights nil labelled 0 updated 0)
      (repeat (sslength set)
        (setq entity (ssname set index)
              obj (vlax-ename->vla-object entity)
              area (ACT:safe-call 'vla-get-Area (list obj)))
        (if (numberp area)
          (progn
            (setq area (* area factor) total (+ total area) count (1+ count))
            (setq key (cdr (assoc 8 (entget entity))))
            (if (setq pair (assoc key stats))
              (setq stats (subst (cons key (+ (cdr pair) area)) pair stats))
              (setq stats (cons (cons key area) stats))
            )
            ;; Nhan dien tich giua vung (tam bao chu nhat), chu cao 1/6 canh ngan.
            (setq box (HV:sumhatch-box obj))
            (if box
              (progn
                (setq w (- (car (cadr box)) (car (car box)))
                      h (- (cadr (cadr box)) (cadr (car box)))
                      height (/ (min w h) 6.0)
                      center (list (/ (+ (car (car box)) (car (cadr box))) 2.0)
                                   (/ (+ (cadr (car box)) (cadr (cadr box))) 2.0)
                                   (/ (+ (caddr (car box)) (caddr (cadr box))) 2.0))
                      handle (cdr (assoc 5 (entget entity))))
                (if (> height 0.0)
                  (progn
                    (setq heights (cons height heights))
                    (if (assoc handle old-labels) (setq updated (1+ updated)) (setq labelled (1+ labelled)))
                    (HV:sumhatch-label center (strcat "S=" (rtos area 2 2) " m2") height layer
                                       handle (cdr (assoc handle old-labels)))
                  )
                )
              )
            )
          )
          (setq failed (1+ failed))
        )
        (setq index (1+ index))
      )
      ;; 3. Ket qua tren dong lenh.
      (prompt (strcat "\n=== TONG DIEN TICH HATCH (ban ve theo " unit ") ==="))
      (if (> (length stats) 1)
        (foreach pair (reverse stats)
          (prompt (strcat "\n  Layer " (car pair) " : " (rtos (cdr pair) 2 3) " m2"))
        )
      )
      (prompt (strcat "\n  So hatch: " (itoa count)))
      (prompt (strcat "\n  TONG DIEN TICH: " (rtos total 2 3) " m2"))
      (prompt (strcat "\n  Da ghi " (itoa labelled) " nhan moi, cap nhat " (itoa updated) " nhan cu (layer CHU)."))
      (if (> failed 0)
        (prompt (strcat "\n  Bo qua " (itoa failed) " hatch khong doc duoc dien tich (hatch loi bien)."))
      )
      ;; 4. Click ghi tong. Chu cao 1,5 lan chu nhan trung vi.
      (if (> count 0)
        (progn
          (setq sorted (vl-sort heights '<))
          (setq total-height (* 1.5 (if sorted (nth (/ (length sorted) 2) sorted) (getvar "TEXTSIZE"))))
          (setq point (getpoint "\nClick diem ghi TONG dien tich <Enter = khong ghi>: "))
          (if point
            (progn
              (HV:sumhatch-label (ACT:ucs-to-wcs point)
                                 (strcat "TONG S=" (rtos total 2 2) " m2 (" (itoa count) " vung)")
                                 total-height layer nil nil)
              (prompt "\nSUMHATCH: da ghi tong dien tich.")
            )
          )
        )
      )
    )
  )
  (ACT:undo-end document)
  (setq document nil)
  (princ)
)

;;; Ten goi nhanh (nguoi dung yeu cau).
(defun C:SUMHATCH ()
  (C:HVSUMHATCH)
)

(princ)
