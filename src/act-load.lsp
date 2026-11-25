;;; HVLisp loader (based on AutoLISP Civil Tools Community loader).
;;; Copyright (C) 2026 Truong Hoa and contributors.
;;; Modified 2026-11-25 for HVLisp: install-folder root, VERSION file, lenh\ folder.
;;; SPDX-License-Identifier: GPL-3.0-or-later

(vl-load-com)

;;; Cau hinh bo HVLisp
(setq ACT:suite-name "HVLisp")
(setq ACT:install-dir "C:\\HVLisp")

;;; Thu muc goc cua bo Lisp (chua VERSION, src\, lenh\, update.ps1).
;;; Uu tien thu muc cai; neu khong co thi tim act-load.lsp theo findfile.
(defun ACT:root-dir (/ path dir)
  (cond
    ((findfile (strcat ACT:install-dir "\\src\\act-load.lsp")) ACT:install-dir)
    ((setq path (findfile "act-load.lsp"))
      (setq dir (vl-filename-directory path))
      (if (and dir (= (strcase (vl-filename-base dir)) "SRC"))
        (vl-filename-directory dir)
        dir
      )
    )
  )
)

(defun ACT:src-dir (/ root)
  (setq root (ACT:root-dir))
  (if root
    (if (findfile (strcat root "\\src\\act-load.lsp")) (strcat root "\\src") root)
  )
)

(defun ACT:read-version (/ root path handle line)
  (setq root (ACT:root-dir))
  (if root (setq path (findfile (strcat root "\\VERSION"))))
  (if path (setq handle (open path "r")))
  (if handle
    (progn
      (setq line (read-line handle))
      (close handle)
    )
  )
  (if (and line (> (strlen (vl-string-trim " \t\r\n" line)) 0))
    (vl-string-trim " \t\r\n" line)
    "?"
  )
)

(defun ACT:load-module (name / dir path)
  (setq dir (ACT:src-dir))
  (if dir (setq path (findfile (strcat dir "\\" name))))
  (if path
    (load path)
    (prompt (strcat "\nACT missing module: " name))
  )
)

;;; Nap moi file .lsp trong lenh\ ; file loi thi bao va nap tiep.
(defun ACT:load-lenh (/ root dir files result count)
  (setq root (ACT:root-dir) count 0)
  (if root (setq dir (strcat root "\\lenh")))
  (if dir (setq files (vl-directory-files dir "*.lsp" 1)))
  (foreach name (if files (acad_strlsort files))
    (setq result (vl-catch-all-apply 'load (list (strcat dir "\\" name))))
    (if (vl-catch-all-error-p result)
      (prompt (strcat "\n" ACT:suite-name " loi nap lenh\\" name ": " (vl-catch-all-error-message result)))
      (setq count (1+ count))
    )
  )
  count
)

(setq ACT:version (ACT:read-version))

(ACT:load-module "act-core.lsp")
(ACT:load-module "act-coord.lsp")
(ACT:load-module "act-export.lsp")
(ACT:load-module "act-import.lsp")
(ACT:load-module "act-elev.lsp")
(ACT:load-module "act-chainage.lsp")
(ACT:load-module "act-interp.lsp")
(ACT:load-module "act-profile.lsp")
(ACT:load-lenh)
(prompt (strcat "\n" ACT:suite-name " v" ACT:version " - go HVHELP de xem lenh"))
(princ)
