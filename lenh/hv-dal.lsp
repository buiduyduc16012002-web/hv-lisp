;;; Lenh: DAL (ten ngan, thay alias DAL = DIMALIGNED), HVDAL
;;; Muc dich: ghi kich thuoc lien tiep khong phai goi lai lenh. Chu kich thuoc luon dat
;;;           chinh giua duong kich thuoc. Hai che do:
;;;             DAL : moi doan mot kich thuoc aligned theo huong cua doan do (di theo
;;;                   duong gay khuc), cung khoang cach va cung phia voi kich thuoc dau.
;;;             CON : DIM lien tiep thang hang voi kich thuoc truoc (nhu DIMCONTINUE):
;;;                   cung mot duong kich thuoc, duong gong vuong goc, do hinh chieu.
;;;                   MAC DINH TU VUONG GOC: click vao doi tuong (line, polyline, cung,
;;;                   truc... ke ca nam trong block/xref) la tu bat chan duong vuong goc
;;;                   tu diem cuoi xuong doi tuong do va ghi luon. Click cho trong = dung
;;;                   diem click.
;;; Cach dung: go DAL -> diem dau -> diem thu hai -> vi tri duong kich thuoc.
;;;            Sau do lap lai (chi ESC moi thoat):
;;;              click diem : ghi tiep theo che do dang dung
;;;              C (Con)    : chuyen sang DIM lien tiep thang hang (vuong goc); trong CON:
;;;                           click doi tuong = tu vuong goc; T (Tudo) = lan click sau
;;;                           lay dung diem click (vd dau mut), khong vuong goc
;;;              D (Dal)    : chuyen ve che do aligned theo tung doan
;;;              M (Moi)    : bat dau chuoi moi (Enter cung vay)
;;;              U (Undo)   : xoa kich thuoc vua ghi, quay lai diem truoc
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

;;; Do dai hinh chieu cua a->b len huong ang.
(defun HV:dal-projected (a b ang)
  (abs (+ (* (- (car b) (car a)) (cos ang)) (* (- (cadr b) (cadr a)) (sin ang))))
)

;;; Doi tuong duoi diem click pt (UCS): ket qua nentselp, hoac nil neu khong co /
;;; la kich thuoc (bo qua chinh cac DIM vua ghi).
(defun HV:dal-pick-at (pt / hit bad)
  (setq hit (nentselp pt))
  (if hit
    (progn
      (if (= (ACT:entity-kind (car hit)) "DIMENSION") (setq bad T))
      (if (= (length hit) 4)
        (foreach parent (nth 3 hit)
          (if (= (ACT:entity-kind parent) "DIMENSION") (setq bad T))
        )
      )
      (if (not bad) hit)
    )
  )
)

;;; Ban sao tam cua doi tuong trong block, bien doi ra WCS bang ma tran 4x4 cua nentselp.
(defun HV:dal-temp-copy (ent matrix / clean new result)
  (setq clean nil)
  (foreach item (entget ent)
    (cond
      ((member (car item) '(-1 -2 5 102 330 360 410)) nil)
      ((= (car item) 8) (setq clean (cons (cons 8 (getvar "CLAYER")) clean)))
      (T (setq clean (cons item clean)))
    )
  )
  (setq new (entmakex (reverse clean)))
  (if new
    (progn
      (setq result (vl-catch-all-apply 'vla-TransformBy (list (vlax-ename->vla-object new) (vlax-tmatrix matrix))))
      (if (vl-catch-all-error-p result)
        (progn (entdel new) nil)
        new
      )
    )
  )
)

;;; Chan duong vuong goc tu diem from (UCS) xuong doi tuong hit (ket qua nentselp).
;;; Line ngan thi keo dai tuong tuong. Tra ve diem UCS hoac nil.
(defun HV:dal-perp-foot-at (hit from / ent matrix copy foot)
  (setq ent (car hit))
  ;; Dinh cua POLYLINE cu -> lay polyline cha.
  (if (= (ACT:entity-kind ent) "VERTEX") (setq ent (cdr (assoc 330 (entget ent)))))
  (if (= (length hit) 4) (setq matrix (caddr hit)))
  (cond
    ((not (ACT:curve-p ent)) nil)
    ((not matrix)
      (setq foot (ACT:safe-call 'vlax-curve-getClosestPointTo (list ent (trans from 1 0) T)))
    )
    ((member (ACT:entity-kind ent) '("LINE" "LWPOLYLINE" "ARC" "CIRCLE" "ELLIPSE" "SPLINE" "XLINE" "RAY"))
      (setq copy (HV:dal-temp-copy ent matrix))
      (if copy
        (progn
          (setq foot (ACT:safe-call 'vlax-curve-getClosestPointTo (list copy (trans from 1 0) T)))
          (entdel copy)
        )
      )
    )
  )
  (if foot (trans foot 0 1))
)

;;; Dua chu kich thuoc ve chinh giua duong kich thuoc.
(defun HV:dal-center-text (ent)
  (if ent (vl-catch-all-apply 'vl-cmdf (list "_.DIMTEDIT" ent "_C")))
  ent
)

;;; Ghi 1 kich thuoc aligned (diem theo UCS). Tra ve ename hoac nil.
(defun HV:dal-make-aligned (p1 p2 loc / before ent)
  (setq before (entlast))
  (command "_.DIMALIGNED" "_non" p1 "_non" p2 "_non" loc)
  (setq ent (entlast))
  (if (and ent (not (equal ent before)) (= (ACT:entity-kind ent) "DIMENSION"))
    (HV:dal-center-text ent)
  )
)

;;; Ghi 1 kich thuoc xoay goc ang (radian, theo UCS), duong kich thuoc qua linept.
;;; Tam dat ANGBASE/ANGDIR/AUNITS = 0 de goc nhap vao dung (khoi phuc ngay sau do).
(defun HV:dal-make-rotated (p1 p2 ang linept / before ent saved)
  (setq saved (mapcar 'getvar '("ANGBASE" "ANGDIR" "AUNITS")))
  (setq HV:dal-saved-angle saved)
  (setvar "ANGBASE" 0.0)
  (setvar "ANGDIR" 0)
  (setvar "AUNITS" 0)
  (setq before (entlast))
  (command "_.DIMLINEAR" "_non" p1 "_non" p2 "_R" (rtos (* ang (/ 180.0 pi)) 2 8) "_non" linept)
  (mapcar 'setvar '("ANGBASE" "ANGDIR" "AUNITS") saved)
  (setq HV:dal-saved-angle nil)
  (setq ent (entlast))
  (if (and ent (not (equal ent before)) (= (ACT:entity-kind ent) "DIMENSION"))
    (HV:dal-center-text ent)
  )
)

(defun C:HVDAL (/ *error* document old-cmdecho history top p1 p2 loc d ent answer mode free hit foot)
  (defun *error* (message)
    (if HV:dal-saved-angle
      (progn
        (mapcar 'setvar '("ANGBASE" "ANGDIR" "AUNITS") HV:dal-saved-angle)
        (setq HV:dal-saved-angle nil)
      )
    )
    (if old-cmdecho (setvar "CMDECHO" old-cmdecho))
    (ACT:report-error message document)
  )
  (setq old-cmdecho (getvar "CMDECHO") history nil mode "DAL" HV:dal-saved-angle nil)
  (setvar "CMDECHO" 0)
  (prompt "\nDAL: ghi kich thuoc lien tiep. Nhan ESC de thoat.")
  ;; history: danh sach (diem-dau diem-cuoi khoang-cach ename goc-duong-dim diem-tren-duong-dim),
  ;; moi nhat o dau. Diem theo UCS.
  (while T
    (if (not history)
      ;; Chuoi moi: kich thuoc aligned dau tien.
      (progn
        (setq mode "DAL")
        (setq p1 (getpoint "\nDAL - diem dau: ") p2 nil loc nil)
        (if p1 (setq p2 (getpoint p1 "\nDiem thu hai: ")))
        (if p2 (setq loc (getpoint p2 "\nVi tri duong kich thuoc: ")))
        (if (and p1 p2 loc)
          (progn
            (setq d (HV:dal-offset p1 p2 loc))
            (setq document (ACT:undo-start))
            (setq ent (if d (HV:dal-make-aligned p1 p2 loc)))
            (setq document (ACT:undo-end document))
            (if ent
              (setq history (list (list p1 p2 d ent (angle p1 p2) loc)))
              (prompt "\nDAL: khong ghi duoc kich thuoc (2 diem trung nhau?).")
            )
          )
        )
      )
      ;; DIM lien tiep.
      (progn
        (setq top (car history))
        (if (= mode "CON")
          (progn
            ;; Click: trung doi tuong -> tu tinh chan duong vuong goc tu diem cuoi;
            ;; cho trong (hoac sau T) -> dung diem click.
            (initget "Tudo Dal Moi Undo")
            (setq answer (getpoint (cadr top)
                           (if free
                             "\nCON - click diem (lay dung diem, khong vuong goc) hoac [Dal/Moi/Undo] <Moi>: "
                             "\nCON - click doi tuong (tu vuong goc) hoac [Tudo/Dal/Moi/Undo] <Moi>: ")))
            (cond
              ((= answer "Tudo")
                (setq free T answer "Lai")
              )
              ((and answer (listp answer))
                (if free
                  (setq free nil)
                  (progn
                    (if (not document) (setq document (ACT:undo-start)))
                    (setq hit (HV:dal-pick-at answer) foot nil)
                    (if hit (setq foot (HV:dal-perp-foot-at hit (cadr top))))
                    (cond
                      (foot (setq answer foot))
                      (hit (prompt "\nDAL: doi tuong nay khong bat vuong goc duoc - dung diem click."))
                    )
                  )
                )
              )
            )
          )
          (progn
            (initget "Con Moi Undo")
            (setq answer (getpoint (cadr top) "\nDiem tiep theo hoac [Con/Moi/Undo] <Moi>: "))
          )
        )
        (cond
          ((= answer "Lai") nil)
          ((or (null answer) (= answer "Moi"))
            (setq history nil)
          )
          ((= answer "Con")
            (setq mode "CON")
            (prompt "\nDAL: CON - DIM lien tiep thang hang, vuong goc voi kich thuoc truoc.")
          )
          ((= answer "Dal")
            (setq mode "DAL")
            (prompt "\nDAL: ve che do aligned theo tung doan.")
          )
          ((= answer "Undo")
            (if (entget (nth 3 top)) (entdel (nth 3 top)))
            (setq history (cdr history))
            (prompt (if history "\nDAL: da xoa kich thuoc vua ghi." "\nDAL: da xoa - bat dau chuoi moi."))
          )
          ((and (listp answer) (= mode "CON"))
            ;; Cung goc va cung duong kich thuoc voi kich thuoc truoc.
            (if (> (HV:dal-projected (cadr top) answer (nth 4 top)) 1e-9)
              (progn
                (if (not document) (setq document (ACT:undo-start)))
                (setq ent (HV:dal-make-rotated (cadr top) answer (nth 4 top) (nth 5 top)))
                (setq document (ACT:undo-end document))
                (if ent
                  (setq history (cons (list (cadr top) answer (caddr top) ent (nth 4 top) (nth 5 top)) history))
                  (prompt "\nDAL: khong ghi duoc kich thuoc.")
                )
              )
              (progn
                (setq document (ACT:undo-end document))
                (prompt "\nDAL: diem nay khong lech theo huong kich thuoc, chon diem khac.")
              )
            )
          )
          ((listp answer)
            (setq loc (HV:dal-location (cadr top) answer (caddr top)))
            (setq document (ACT:undo-start))
            (setq ent (if loc (HV:dal-make-aligned (cadr top) answer loc)))
            (setq document (ACT:undo-end document))
            (if ent
              (setq history (cons (list (cadr top) answer (caddr top) ent (angle (cadr top) answer) loc) history))
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
