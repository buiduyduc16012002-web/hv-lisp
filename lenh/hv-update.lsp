;;; Lenh: UPDATE (ten goi nhanh), HVUPDATE, HVHELP
;;; Muc dich: HVUPDATE tai ban moi nhat cua HVLisp tu GitHub (nhanh main) ve thu muc goc
;;;           roi nap lai; HVHELP in danh sach lenh trong lenh\danh-sach.txt.
;;; Cach dung: go UPDATE hoac HVUPDATE (can Internet, repo de public). Go HVHELP de xem lenh.
;;; Day la file DUY NHAT duoc phep goi mang (WScript.Shell + PowerShell).
;;; SPDX-License-Identifier: GPL-3.0-or-later

(vl-load-com)

(setq HV:repo "buiduyduc16012002-web/hv-lisp")

;;; Chay lenh trong cua so an, cho chay xong, tra ve ma thoat (so nguyen) hoac nil.
(defun HV:run-hidden-wait (cmdline / shell result)
  (setq shell (vl-catch-all-apply 'vlax-create-object (list "WScript.Shell")))
  (if (and shell (not (vl-catch-all-error-p shell)))
    (progn
      (setq result (vl-catch-all-apply 'vlax-invoke-method (list shell 'Run cmdline 0 :vlax-true)))
      (vl-catch-all-apply 'vlax-release-object (list shell))
      (cond
        ((vl-catch-all-error-p result) nil)
        ((= (type result) 'VARIANT) (vlax-variant-value result))
        (T result)
      )
    )
  )
)

(defun C:HVUPDATE (/ root script loader cmdline code old new loaded)
  (setq root (if ACT:root-dir (ACT:root-dir)))
  (if root (setq script (findfile (strcat root "\\update.ps1"))))
  (cond
    ((not root)
      (prompt "\nHVUPDATE: khong tim thay thu muc goc HVLisp. Hay APPLOAD lai src\\act-load.lsp.")
    )
    ((not script)
      (prompt (strcat "\nHVUPDATE: thieu file " root "\\update.ps1. Hay tai lai bo HVLisp tu GitHub."))
    )
    (T
      (setq old (if ACT:version ACT:version "?"))
      (setq cmdline
        (strcat "powershell -NoProfile -ExecutionPolicy Bypass -File \"" script
                "\" -Repo \"" HV:repo "\" -Dest \"" root "\""))
      (prompt (strcat "\nHVUPDATE: dang tai ban moi tu GitHub " HV:repo " ..."))
      (princ)
      (setq code (HV:run-hidden-wait cmdline))
      (if (= code 0)
        (progn
          (setq loader (findfile (strcat root "\\src\\act-load.lsp")))
          (setq loaded (if loader (vl-catch-all-apply 'load (list loader))))
          (if (or (not loader) (vl-catch-all-error-p loaded))
            (prompt (strcat "\nHVUPDATE: da tai xong nhung nap lai bi loi"
                            (if (vl-catch-all-error-p loaded) (strcat ": " (vl-catch-all-error-message loaded)) "")
                            ". Hay APPLOAD lai src\\act-load.lsp."))
            (progn
              (setq new (if ACT:version ACT:version "?"))
              (if (= old new)
                (prompt (strcat "\nDang la ban moi nhat (v" new ")."))
                (prompt (strcat "\nCap nhat: v" old " -> v" new))
              )
            )
          )
        )
        (progn
          (prompt (strcat "\nHVUPDATE: cap nhat THAT BAI"
                          (if (numberp code) (strcat " (ma loi " (itoa code) ")") " (khong chay duoc PowerShell)")
                          "."))
          (prompt "\n  Kiem tra: 1) may co Internet, vao duoc github.com;")
          (prompt (strcat "\n            2) repo " HV:repo " de PUBLIC va co nhanh main;"))
          (prompt (strcat "\n            3) co quyen ghi vao thu muc " root "."))
        )
      )
    )
  )
  (princ)
)

;;; Ten goi nhanh cua HVUPDATE (nguoi dung yeu cau). Neu bo Lisp khac cung dinh nghia
;;; C:UPDATE va nap sau thi UPDATE thuoc ve bo kia; HVUPDATE van luon dung.
(defun C:UPDATE ()
  (C:HVUPDATE)
)

(defun C:HVHELP (/ root path handle line)
  (setq root (if ACT:root-dir (ACT:root-dir)))
  (if root (setq path (findfile (strcat root "\\lenh\\danh-sach.txt"))))
  (if path (setq handle (open path "r")))
  (if handle
    (progn
      (prompt (strcat "\n=== " (if ACT:suite-name ACT:suite-name "HVLisp") " v" (if ACT:version ACT:version "?") " - danh sach lenh ==="))
      (while (setq line (read-line handle))
        (if (> (strlen (vl-string-trim " \t\r\n" line)) 0)
          (prompt (strcat "\n  " line))
        )
      )
      (close handle)
    )
    (prompt "\nHVHELP: khong tim thay lenh\\danh-sach.txt. Go HVUPDATE de tai lai.")
  )
  (princ)
)

(princ)
