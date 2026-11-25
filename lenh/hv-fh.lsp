;;; Lenh: FH (ten ngan), HVFH
;;; Muc dich: hatch dac (SOLID) ben trong tung vong tron (coc TDXM) duoc chon. Moi coc
;;;           mot hatch rieng, lien ket voi vong tron (keo/sua vong tron thi hatch theo).
;;;           Coc da co hatch lien ket thi bo qua, khong hatch chong.
;;; Cach dung: go FH -> quet chon vung (chi lay CIRCLE, doi tuong khac tu bo qua) -> Enter.
;;;            Neu dang co tap chon san (vd vua chay TDXM) thi FH hatch ngay tap do.
;;; Hatch dat tren layer HATCH (mau 9). Hoan tac: go U mot lan.
;;; SPDX-License-Identifier: GPL-3.0-or-later

(vl-load-com)

;;; T neu vong tron da co hatch lien ket (reactor 330 tro toi mot HATCH).
(defun HV:fh-hatched-p (entity / result)
  (setq result nil)
  (foreach item (entget entity)
    (if (and (= (car item) 330) (= (ACT:entity-kind (cdr item)) "HATCH"))
      (setq result T)
    )
  )
  result
)

;;; Tao 1 hatch SOLID lien ket cho vong tron. Tra ve T neu thanh cong.
(defun HV:fh-hatch-circle (entity layer document / data obj space hatch loop center normal result)
  (setq data (entget entity)
        obj (vlax-ename->vla-object entity)
        center (cdr (assoc 10 data))
        normal (cdr (assoc 210 data)))
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
      (if (and center (numberp (caddr center)))
        (ACT:safe-call 'vla-put-Elevation (list hatch (caddr center)))
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

(defun C:HVFH (/ *error* document set layer index entity count skipped failed)
  (defun *error* (message) (ACT:report-error message document))
  (setq document (ACT:undo-start))
  (prompt "\nFH: quet chon cac coc TDXM can hatch (chi lay vong tron CIRCLE).")
  (setq set (ssget '((0 . "CIRCLE"))))
  (cond
    ((not set) (prompt "\nFH: khong chon duoc vong tron nao."))
    ((not document) (prompt "\nFH: khong mo duoc ban ve hien hanh (ActiveX)."))
    (T
      (setq layer (ACT:ensure-layer "HATCH" 9) index 0 count 0 skipped 0 failed 0)
      (prompt (strcat "\nFH: dang hatch " (itoa (sslength set)) " vong tron..."))
      (repeat (sslength set)
        (setq entity (ssname set index))
        (cond
          ((HV:fh-hatched-p entity) (setq skipped (1+ skipped)))
          ((HV:fh-hatch-circle entity layer document) (setq count (1+ count)))
          (T (setq failed (1+ failed)))
        )
        (setq index (1+ index))
      )
      (prompt (strcat "\nFH: da hatch " (itoa count) " coc (SOLID, layer HATCH)."))
      (if (> skipped 0) (prompt (strcat "\n    Bo qua " (itoa skipped) " coc da co hatch.")))
      (if (> failed 0) (prompt (strcat "\n    Loi " (itoa failed) " coc khong hatch duoc (layer khoa?).")))
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
