;;; Lenh: FH (ten ngan), HVFH
;;; Muc dich: hatch dac (SOLID) ben trong tung doi tuong KIN duoc chon: vong tron, polyline
;;;           kin, ellipse, spline kin, region. Moi doi tuong mot hatch rieng, lien ket voi
;;;           no (keo/sua doi tuong thi hatch theo). Doi tuong da co hatch lien ket thi bo
;;;           qua; doi tuong ho (khong kin) tu bo qua.
;;; Cach dung: go FH -> quet chon vung -> Enter.
;;;            Neu dang co tap chon san (vd vua chay TDXM) thi FH hatch ngay tap do.
;;; Hatch dat tren layer HATCH (mau 9). Hoan tac: go U mot lan.
;;; SPDX-License-Identifier: GPL-3.0-or-later

(vl-load-com)

;;; T neu doi tuong da co hatch lien ket (reactor 330 tro toi mot HATCH).
(defun HV:fh-hatched-p (entity / result)
  (setq result nil)
  (foreach item (entget entity)
    (if (and (= (car item) 330) (= (ACT:entity-kind (cdr item)) "HATCH"))
      (setq result T)
    )
  )
  result
)

;;; T neu doi tuong la vung kin hatch duoc.
(defun HV:fh-closed-p (entity / kind start end)
  (setq kind (ACT:entity-kind entity))
  (cond
    ((member kind '("CIRCLE" "REGION")) T)
    ((ACT:safe-call 'vlax-curve-isClosed (list entity)) T)
    ;; Polyline/spline khong danh dau kin nhung diem dau trung diem cuoi.
    ((and (setq start (ACT:safe-call 'vlax-curve-getStartPoint (list entity)))
          (setq end (ACT:safe-call 'vlax-curve-getEndPoint (list entity)))
          (equal start end 1e-6))
      T)
  )
)

;;; Tao 1 hatch SOLID lien ket cho doi tuong kin. Tra ve T neu thanh cong.
(defun HV:fh-hatch-object (entity layer document / data obj space hatch loop center normal elevation result)
  (setq data (entget entity)
        obj (vlax-ename->vla-object entity)
        center (cdr (assoc 10 data))
        normal (cdr (assoc 210 data)))
  ;; Cao do: LWPOLYLINE luu o ma 38, doi tuong khac lay Z cua ma 10.
  (setq elevation
    (if (= (cdr (assoc 0 data)) "LWPOLYLINE")
      (cdr (assoc 38 data))
      (if (and center (numberp (caddr center))) (caddr center))
    )
  )
  (setq space
    (if (= (strcase (cdr (assoc 410 data))) "MODEL")
      (vla-get-ModelSpace document)
      (vla-get-PaperSpace document)
    )
  )
  ;; 1 = acHatchPatternTypePreDefined
  (setq hatch (ACT:safe-call 'vla-AddHatch (list space 1 "SOLID" :vlax-true)))
  (if hatch
    (progn
      (if normal (ACT:safe-call 'vla-put-Normal (list hatch (vlax-3d-point normal))))
      (if (numberp elevation)
        (ACT:safe-call 'vla-put-Elevation (list hatch elevation))
      )
      (setq loop (vlax-make-safearray vlax-vbObject '(0 . 0)))
      (vlax-safearray-fill loop (list obj))
      (setq result (vl-catch-all-apply 'vla-AppendOuterLoop (list hatch loop)))
      (if (vl-catch-all-error-p result)
        (progn
          (ACT:safe-call 'vla-Delete (list hatch))
          nil
        )
        (progn
          (ACT:safe-call 'vla-put-Layer (list hatch layer))
          (ACT:safe-call 'vla-Evaluate (list hatch))
          T
        )
      )
    )
  )
)

(defun C:HVFH (/ *error* document set layer index entity count skipped failed opened kinds pair kind)
  (defun *error* (message) (ACT:report-error message document))
  (setq document (ACT:undo-start))
  (prompt "\nFH: quet chon cac vung kin can hatch (vong tron, polyline kin, ellipse, spline, region).")
  (setq set (ssget '((0 . "CIRCLE,LWPOLYLINE,POLYLINE,ELLIPSE,SPLINE,REGION"))))
  (cond
    ((not set) (prompt "\nFH: khong chon duoc doi tuong kin nao."))
    ((not document) (prompt "\nFH: khong mo duoc ban ve hien hanh (ActiveX)."))
    (T
      (setq layer (ACT:ensure-layer "HATCH" 9) index 0 count 0 skipped 0 failed 0 opened 0 kinds nil)
      (prompt (strcat "\nFH: dang xu ly " (itoa (sslength set)) " doi tuong..."))
      (repeat (sslength set)
        (setq entity (ssname set index) kind (ACT:entity-kind entity))
        (cond
          ((not (HV:fh-closed-p entity)) (setq opened (1+ opened)))
          ((HV:fh-hatched-p entity) (setq skipped (1+ skipped)))
          ((HV:fh-hatch-object entity layer document)
            (setq count (1+ count))
            (if (setq pair (assoc kind kinds))
              (setq kinds (subst (cons kind (1+ (cdr pair))) pair kinds))
              (setq kinds (cons (cons kind 1) kinds))
            )
          )
          (T (setq failed (1+ failed)))
        )
        (setq index (1+ index))
      )
      (prompt (strcat "\nFH: da hatch " (itoa count) " vung kin (SOLID, layer HATCH)."))
      (foreach pair (reverse kinds)
        (prompt (strcat "\n    " (car pair) ": " (itoa (cdr pair))))
      )
      (if (> skipped 0) (prompt (strcat "\n    Bo qua " (itoa skipped) " doi tuong da co hatch.")))
      (if (> opened 0) (prompt (strcat "\n    Bo qua " (itoa opened) " doi tuong ho (khong kin).")))
      (if (> failed 0) (prompt (strcat "\n    Loi " (itoa failed) " doi tuong khong hatch duoc (layer khoa, polyline tu cat?).")))
    )
  )
  (ACT:undo-end document)
  (setq document nil)
  (princ)
)

;;; Ten goi nhanh (nguoi dung yeu cau).
(defun C:FH ()
  (C:HVFH)
)

(princ)
