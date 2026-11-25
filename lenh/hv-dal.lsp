;;; Lenh: DAL (ten ngan, thay alias DAL = DIMALIGNED), HVDAL
;;; Muc dich: ghi kich thuoc thang hang (aligned) lien tiep khong phai goi lai lenh.
;;;           Sau moi kich thuoc, click diem tiep theo la ghi tiep 1 kich thuoc noi tu
;;;           diem cuoi truoc do, cung khoang cach va cung phia voi duong kich thuoc
;;;           dau tien (di theo duong gay khuc cung duoc).
;;; Cach dung: go DAL -> diem dau -> diem thu hai -> vi tri duong kich thuoc.
;;;            Sau do lap lai (chi ESC moi thoat):
;;;              click diem  : DIM lien tiep tu diem cuoi
;;;              M (Moi)     : bat dau chuoi moi (Enter cung vay)
;;;              U (Undo)    : xoa kich thuoc vua ghi, quay lai diem truoc
;;; Dung DimStyle va layer hien hanh. Moi kich thuoc la 1 buoc Undo rieng.
;;; SPDX-License-Identifier: GPL-3.0-or-later

(vl-load-com)

;;; Khoang cach co dau tu loc den duong a-b (ben trai chieu a->b la duong).
(defun HV:dal-offset (a b loc / dx dy len)
  (setq dx (- (car b) (car a)) dy (- (cadr b) (cadr a)) len (sqrt (+ (* dx dx) (* dy dy))))
  (if (> len 1e-9)
    (/ (- (* dx (- (cadr loc) (cadr a))) (* dy (- (car loc) (car a)))) len)
  )
)

;;; Vi tri duong kich thuoc cho doan a-b, lech d theo phap tuyen trai.
(defun HV:dal-location (a b d / dx dy len)
  (setq dx (- (car b) (car a)) dy (- (cadr b) (cadr a)) len (sqrt (+ (* dx dx) (* dy dy))))
  (if (and (numberp d) (> len 1e-9))
    (list (+ (/ (+ (car a) (car b)) 2.0) (* d (/ (- dy) len)))
          (+ (/ (+ (cadr a) (cadr b)) 2.0) (* d (/ dx len)))
          (if (numberp (caddr a)) (caddr a) 0.0))
  )
)

;;; Ghi 1 kich thuoc aligned (diem theo UCS). Tra ve ename hoac nil.
(defun HV:dal-make (p1 p2 loc / before ent)
  (setq before (entlast))
  (command "_.DIMALIGNED" "_non" p1 "_non" p2 "_non" loc)
  (setq ent (entlast))
  (if (and ent (not (equal ent before)) (= (ACT:entity-kind ent) "DIMENSION")) ent)
)

(defun C:HVDAL (/ *error* document old-cmdecho history top p1 p2 loc d ent answer)
  (defun *error* (message)
    (if old-cmdecho (setvar "CMDECHO" old-cmdecho))
    (ACT:report-error message document)
  )
  (setq old-cmdecho (getvar "CMDECHO") history nil)
  (setvar "CMDECHO" 0)
  (prompt "\nDAL: ghi kich thuoc lien tiep. Nhan ESC de thoat.")
  ;; history: danh sach (diem-dau diem-cuoi khoang-cach ename), moi nhat o dau.
  (while T
    (if (not history)
      ;; Chuoi moi.
      (progn
        (setq p1 (getpoint "\nDAL - diem dau: ") p2 nil loc nil)
        (if p1 (setq p2 (getpoint p1 "\nDiem thu hai: ")))
        (if p2 (setq loc (getpoint p2 "\nVi tri duong kich thuoc: ")))
        (if (and p1 p2 loc)
          (progn
            (setq d (HV:dal-offset p1 p2 loc))
            (setq document (ACT:undo-start))
            (setq ent (if d (HV:dal-make p1 p2 loc)))
            (setq document (ACT:undo-end document))
            (if ent
              (setq history (list (list p1 p2 d ent)))
              (prompt "\nDAL: khong ghi duoc kich thuoc (2 diem trung nhau?).")
            )
          )
        )
      )
      ;; DIM lien tiep.
      (progn
        (setq top (car history))
        (initget "Moi Undo")
        (setq answer (getpoint (cadr top) "\nDiem tiep theo (DIM lien tiep) hoac [Moi/Undo] <Moi>: "))
        (cond
          ((or (null answer) (= answer "Moi"))
            (setq history nil)
          )
          ((= answer "Undo")
            (if (entget (nth 3 top)) (entdel (nth 3 top)))
            (setq history (cdr history))
            (prompt (if history "\nDAL: da xoa kich thuoc vua ghi." "\nDAL: da xoa - bat dau chuoi moi."))
          )
          ((listp answer)
            (setq loc (HV:dal-location (cadr top) answer (caddr top)))
            (setq document (ACT:undo-start))
            (setq ent (if loc (HV:dal-make (cadr top) answer loc)))
            (setq document (ACT:undo-end document))
            (if ent
              (setq history (cons (list (cadr top) answer (caddr top) ent) history))
              (prompt "\nDAL: diem trung diem truoc, chon diem khac.")
            )
          )
        )
      )
    )
  )
)

;;; Ten goi nhanh (nguoi dung yeu cau). Ghi de alias DAL cua AutoCAD khi HVLisp duoc nap;
;;; lenh goc van goi duoc bang DIMALIGNED.
(defun C:DAL ()
  (C:HVDAL)
)

(princ)
