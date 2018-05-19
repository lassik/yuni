(import (yuni scheme)
        (yuni testing testeval)
        (yuni async) (yuni core) 
        ; FIXME: Disable shorten library for now...
        ; (yuni base shorten)
        (yuni compat ident)
        (yuni base match)
        (yuni core)
        (yuni base dispatch)
        (yuni miniread reader)
        (yuni miniobj minidispatch)
        (yuni minife environments)
        (yuni minife interfacelib)
        (yuni minife expander)
        (yuniconfig build))

(define test-counter 0)
(define success-counter 0)
(define failed-forms '())

(define (check-finish)
  (display "Test: ")
  (display success-counter)
  (display "/")
  (display test-counter)
  (display " passed.")(newline)
  (unless (null? failed-forms)
    (newline)
    (display "Failed: ")
    (newline)
    (for-each (lambda x 
                (display "    ")
                (write x)
                (newline))
              (reverse failed-forms)))
  (flush-output-port (current-output-port))
  (exit (if (null? failed-forms) 0 1)))

(define-syntax check-equal
  (syntax-rules ()
    ((_ obj form)
     (begin
       (set! test-counter (+ 1 test-counter))
       (let ((e form))
       (cond ((equal? obj e)
              (set! success-counter (+ 1 success-counter)))
             (else
               (set! failed-forms (cons 'form failed-forms)))))))))


(check-equal #t (let ((m (lambda () #t))) (m)))
(check-equal '#(0 1 2 3 4)
             (do ((vec (make-vector 5))
                  (i 0 (+ i 1)))
               ((= i 5) vec)
               (vector-set! vec i i)))

(define-values (va vb vc) (values 10 20 30))
(define-values (vva vvb . vvc) (values 10 20 30 40))
(define-values vvva (values 10 20 30 40))

(check-equal 10 va)
(check-equal 20 vb)
(check-equal 30 vc)
(check-equal 10 vva)
(check-equal 20 vvb)
(check-equal '(30 40) vvc)
(check-equal '(10 20 30 40) vvva)

(let ()
 (define-values (va vb vc) (values 1 2 3))
 (define-values (vva vvb . vvc) (values 1 2 3 4))
 (define-values vvva (values 1 2 3 4))

 (check-equal 1 va)
 (check-equal 2 vb)
 (check-equal 3 vc)
 (check-equal 1 vva)
 (check-equal 2 vvb)
 (check-equal '(3 4) vvc)
 (check-equal '(1 2 3 4) vvva))

;(check-equal 10 ((^a (+ 1 a)) 9))
;(check-equal 10 ((^ (form) (+ 2 form)) 8))
(check-equal 10 (match '(1 10 11) ((a b c) b)))

#| 
(let-values (((ex f?) (testeval 111 '((yuni scheme) (scheme time)))))
            (check-equal ex 111)
            (check-equal #t (not (failure? f?))))

(let-values (((ex f?) (testeval 111 '((only (yuni scheme) define)))))
            (check-equal ex 111)
            (check-equal #t (not (failure? f?))))

(let-values (((ex f?) (testeval 111 '((except (yuni scheme) define)))))
            (check-equal ex 111)
            (check-equal #t (not (failure? f?))))

(let-values (((ex f?) (testeval 'cons2 '((rename (yuni scheme) (cons cons2))))))
            (check-equal #t (procedure? ex))
            (check-equal #t (not (failure? f?))))

(let-values (((ex f?) (testeval 222 '((NEVERLAND)))))
            (check-equal #t (failure? f?)))
|#

;; (yuni minife)

(define (test-minife sexp)
  (define cnt 0)
  (define (copy-sexp sexp)
    (cond
      ((pair? sexp)
       (cons (copy-sexp (car sexp))
             (copy-sexp (cdr sexp))))
      (else sexp)))
  (define (gensym pair symname global?)
    (set! cnt (+ 1 cnt))
    (string->symbol
      (string-append
        (symbol->string symname)
        "_"
        (number->string cnt))))
  (let ((xlib (interfacelib))
        (xenv (env-new))
        (forms (copy-sexp sexp)))
    (envframe-import! (env-current-frame xenv) (cdr xlib))
    (expand-forms! forms xenv gensym)
    forms))

(define-syntax check-minife
  (syntax-rules ()
    ((_ frm ex)
     (check-equal 'ex (test-minife 'frm)))))

(check-minife ((hello)) 
              ((hello)))
(check-minife (($define/primitive a))
              ((begin)))
(check-minife (($define-aux-syntax a))
              ((begin)))
(check-minife (($define/primitive a) 1 2 3)
              (1 2 3))
(check-minife (($define-aux-syntax a) 1 2 3)
              (1 2 3))
(check-minife (($bind-variable hoge))
              (hoge))
(check-minife (($bind-definition hoge))
              (hoge_1))
(check-minife (($extend-env () a b c))
              (a b c))
(check-minife (($inject hoge))
              ((hoge)))
(check-minife (($inject hoge a b c))
              ((hoge a b c)))
(check-minife (($inject hoge a b c 1234 "hoge"))
              ((hoge a b c 1234 "hoge")))
(check-minife (($inject/splice hoge))
              ((hoge)))
(check-minife (($inject/splice hoge a b c))
              ((hoge a b c)))
(check-minife (($inject/form hoge a b c))
              ((hoge a b c)))
(check-minife (($quote hoge))
              (hoge))
(check-minife (($quote (hoge 1 2 3)))
              ((hoge 1 2 3)))
(check-minife (($extend-env (a) ($alias a b ) b))
              (a))
(check-minife (($inject def ($bind-definition abc)
                        ($extend-env (abc) a abc))
               abc)
              ((def abc_1 a abc_1) abc_1))
(check-minife (($inject def ($bind-definition abc)
                        ($extend-env (abc) ($inject let ($extend-env (abc)
                                                                     abc))
                                     abc)))
              ((def abc_1 (let abc) abc_1)))

;; (yuni core)

(define* testtype (entry-a entry-b))
(define* testtype2 (entry-a entry-b))

(define testobj0 (make testtype (entry-a 10)))

(begin
  (check-equal #t (is-a? testobj0 testtype))
  (check-equal #f (is-a? testobj0 testtype2))
  (check-equal 10 (~ testobj0 'entry-a))
  (~ testobj0 'entry-a := 1)
  (check-equal 1 (~ testobj0 'entry-a))
  (~ testobj0 'entry-b := 2)
  (check-equal 2 (~ testobj0 'entry-b))
  (touch! testobj0
    (entry-a 'a)
    (entry-b 'b))
  (let-with testobj0 (entry-a entry-b)
    (check-equal 'a entry-a)
    (check-equal 'b entry-b)))

(define (testfunc . param)
  (match param
         (('ref slot obj)
          (check-equal 'testme slot)
          (cdr obj))
         (('set! slot obj v)
          (check-equal 'testme slot)
          (set-cdr! obj v))))

(define-minidispatch-class testclass testfunc)

(define obj0 (make-minidispatch-obj testclass (cons #t #t)))

(~ obj0 'testme := "hoge")
(check-equal "hoge" (~ obj0 'testme))

(let-with obj0 (testme)
  (check-equal "hoge" testme))

(check-equal #t (is-a? obj0 testclass))

;; (yuni base dispatch)

(define dispatch0 (dispatch-lambda
                    (('pass1 x)
                     (check-equal x 1)
                     "OKAY")
                    (('pass1alt x)
                     (check-equal x 2)
                     "OKAYalt")
                    (('pass2-2 x y)
                     (check-equal x 2)
                     (check-equal y 2)
                     "OKAY")
                    (('passnone)
                     "OKAY")
                    ((pass str)
                     (check-equal #t (string? pass))
                     (check-equal #t (string? str))
                     "OKAY")))

(check-equal "OKAY" (dispatch0 'pass1 1))
(check-equal "OKAYalt" (dispatch0 'pass1alt 2))
(check-equal "OKAY" (dispatch0 'pass2-2 2 2))
(check-equal "OKAY" (dispatch0 'passnone))
(check-equal "OKAY" (dispatch0 "str" "str"))

;; (yuni miniread reader) and base reader

(define (equal-check-deep sexp0 sexp1)
  (define (comp ctx s0 s1)
    (cond
      ((pair? s0)
       (if (pair? s1)
         (and (comp (cons s0 ctx) (car s0) (car s1))
              (comp (cons s0 ctx) (cdr s0) (cdr s0)))
         (error "pair-unmatch!" s0 s1)))
      (else
        (let ((e (equal? s0 s1)))
         #|
         (when e
           (write (list 'MATCH: ctx s0 s1))(newline))
         |#
         (unless e
           (error "datum-unmatch!" ctx (list s0 s1)))
         e))))
  (check-equal #t (comp '() sexp0 sexp1)))

(define (port->sexp p)
  (define (itr cur)
    (let ((r (read p)))
     (if (eof-object? r)
       (reverse cur)
       (itr (cons r cur))) )) 
  (itr '()))

(define (file->sexp pth)
  (define p (open-input-file pth))
  (let ((obj (port->sexp p)))
   (close-port p)
   obj)) 

(define (textfile->bytevector pth)
  (define p (open-input-file pth))
  (define (itr cur)
    (let ((l (read-line p)))
     (if (eof-object? l)
       (string->utf8 cur)
       (itr (if (string=? "" cur) 
              l
              (string-append cur "\n" l))))))
  (itr ""))

(define (verify-file pth)
  (let ((x (file->sexp pth))
        (y (utf8-read (textfile->bytevector pth))))
    (equal-check-deep x y)))

#|
(define yuni-compat-libs
  (begin
    (unless (file-exists? "_testing_liblist.txt")
      (error "_testing_liblist.txt was not found. Generate it with CMake first."))
    (let ((p (open-input-file "_testing_liblist.txt")))
     (define (itr cur)
       (let ((l (read-line p)))
        (if (eof-object? l) 
          cur
          (itr (cons l cur)))))
     (itr '()))))
|#

(define test-files (append '("_sanity.sps")))

(define (miniread-tests)
  (define (checkobj str obj)
    (let* ((bv (string->utf8 str))
           (obj1 (utf8-read bv)))
      (check-equal obj1 obj)))
  (define (check str)
    (let* ((p (open-input-string str))
           (obj0 (port->sexp p)))
      (checkobj str obj0)))
  (define-syntax check2
    (syntax-rules ()
      ((_ obj ...)
       (let* ((p (open-output-string))
              (gen (lambda (e) (write e p) (write-char #\space p))))
         (for-each gen '(obj ...))
        (let* ((str (get-output-string p))
               (bv (string->utf8 str))
               (obj1 (utf8-read bv)))
          ;(write (list 'str: str))(newline)
          ;(write (list 'bv: bv))(newline)
          ;(write (list 'obj: '(obj ...)))(newline)
          ;(write (list 'obj1: obj1 ))(newline)
          ;(newline)
          (check-equal obj1 '(obj ...)))))))
  (check "#| # |# hoge")
  (check "...")
  (check "(...)")
  (check "(a . b)")
  (check "(a b . c)")
  (check2 a)
  (check2 a b c d)
  (check2 #\a "hoge")
  (check2 "\"")
  (check2 "hoge" "hoge")
  (check2 "hoge" fuga "hoge")
  (check2 ("hoge\"" fuga "\"hoge")) ;; FIXME: Same as the case just below
  ;(check "\"hoge \\n hoge\"") ;; FIXME: WHY??
  (check "`(hoge ,fuga)")
  (check "`(hoge ,@fuga)")
  (check "a b c")
  (check "#\\a")
  ;(check "#\\linefeed")
  (check "#;(hoge) fuga")
  (check "#| hoge |# fuga")
  (check ";; fuga\nhoge")
  (check "(100 () (1 2 3) 100)")
  (check "'abc")
  (check ",abc")
  (check ",()")
  (check ",(,abc)")
  (check ",(,@abc)")
  (check "100\n")
  (check "")
  (check "100")
  (check "(100 100)")
  (check "(\"ABC\")")
  (check "(100 \"ABC\")")
  (check "#(100 100)")
  (check "#()")

  (checkobj "#vu8(1 2 3 4)" (list (bytevector 1 2 3 4)))
  (checkobj "#u8(1 2 3 4)" (list (bytevector 1 2 3 4)))
  (checkobj "#u8()" (list (bytevector)))
  (checkobj "#vu8(0)" (list (bytevector 0)))
  )

(miniread-tests)
(for-each verify-file test-files)

(define (gen-configscm pth)
  (check-equal #t (string? pth))
  (and 
    (string? pth)
    (string-append pth "/" (symbol->string (ident-impl)) 
                   "/yuniconfig/build.sls")))

(check-equal #t (symbol? (ident-impl)))
(check-equal #t (string? (yuniconfig-platform)))
(check-equal #t (file-exists? (gen-configscm (yuniconfig-runtime-rootpath))))
(check-equal #t (file-exists? (yuniconfig-executable-path (ident-impl))))

(check-finish)
