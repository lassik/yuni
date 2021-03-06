
;; FIXME: Legacy Selfboot API for yuniappjs

(define (error . x)
  (raise x))

(define (%%extract-program-args args* entrypth)
  (if (string=? (car args*) entrypth)
    (cdr args*)
    (%%extract-program-args (cdr args*) entrypth)))

(define (%%extract-entrypoint-path args*)
  (define (checkone s)
    (and (string? s) 
         (let ((len (string-length s)))
          (and (< 4 len)
               (string=? (substring s (- len 4) len) ".scm")
               s))))
  (and (pair? args*)
       (or (checkone (car args*))
           (%%extract-entrypoint-path (cdr args*)))))

(define (%%pathslashfy pth)
  (let* ((l (string->list pth))
         (x (map (lambda (c) (if (char=? #\\ c) #\/ c)) l)))
    (list->string x)))

(define (%%pathsimplify pth)
  (define (pathcompose acc l)
    (if (pair? l)
      (pathcompose (if (string=? (car l) "")
                     acc
                     (string-append acc "/" (car l))) 
                   (cdr l))
      acc))
  (define (pathcomponent acc cur strq)
    (if (string=? strq "")
      (if (null? acc)
        (reverse cur)
        (reverse (cons (list->string (reverse acc)) cur)))
      (let ((c (string-ref strq 0))
            (r (substring strq 1 (string-length strq))))
        (if (char=? c #\/)
          (pathcomponent '() (cons (list->string (reverse acc)) cur) r)
          (pathcomponent (cons c acc) cur r)))))
  (define (simple cur m q)
    (if (null? q)
      (if (null? cur)
        (reverse (cons m cur))
        (reverse (cdr cur)))
      (let ((a (car q))
            (d (cdr q)))
        (if (string=? ".." a)
          (let ((next-cur (if (null? cur)
                            (list "..")
                            (cdr cur))))
            (if (null? d)
              (reverse next-cur)
              (simple next-cur (car d) (cdr d))))
          (simple (cons m cur) a d)))))

  (let ((r (pathcomponent '() '() pth)))
   (pathcompose "" (simple '() (car r) (cdr r)))))


(define (%%locate-yuniroot-fromscmpath scmpath)
  (define MYNAME "selfboot-entry.scm")
  (let ((npth (%%pathslashfy scmpath)))
   (%%pathsimplify (string-append npth "/../../../.."))))

(define %%selfboot-orig-command-line (or (command-line) '()))
(define %%selfboot-mypath (%%extract-entrypoint-path %%selfboot-orig-command-line))
(define %%selfboot-yuniroot 
  (let ((c (yuni/js-import "yuniroot")))
   (if (js-undefined? c)
     (%%locate-yuniroot-fromscmpath %%selfboot-mypath) 
     c)))
(define %%selfboot-program-args 
  (or (and %%selfboot-mypath
           (%%extract-program-args %%selfboot-orig-command-line
                                   %%selfboot-mypath))
      '()))
(define %%selfboot-impl-type 'biwascheme)
(define %%selfboot-core-libs '((yuni scheme)))

(define %%biwasyuni-load-runtime-only?
  (let ((c (yuni/js-import "biwasyuni-load-runtime-only")))
   (and (not (js-undefined? c))
        c)))

(load (string-append %%selfboot-yuniroot "/lib-runtime/selfboot/biwascheme/selfboot-runtime.scm"))
(load (string-append %%selfboot-yuniroot "/lib-runtime/selfboot/common/common.scm"))

(unless %%biwasyuni-load-runtime-only?
  (load (string-append %%selfboot-yuniroot "/lib-runtime/selfboot/common/run-program.scm")))

