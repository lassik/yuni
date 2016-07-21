;; Library build script for chibi-scheme

(import (scheme base) 
        (scheme write)
        (scheme read)
        (scheme r5rs)
        (chibi filesystem)
        (chibi match))

(define pp write)

(define (fold-left1 proc init lis)
  (define (itr cur rest)
    (if (pair? rest)
      (let ((a (car rest))
            (d (cdr rest)))
        (let ((c (proc cur a)))
         (itr c d)))
      cur))
  (itr init lis))

(define (put-string port str)
  (display str port))

(define (assertion-violation obj msg . x)
  (apply error msg obj x))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; (yuni files) excerpt
;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define directory-list directory-files)

(define (pathfilter str) str) ;; only for POSIX paths

(define (path-append dir name) ;;FIXME: need canon.
  (string-append dir "/" name))

(define (split-dir+base pth)
  (define (itr cur rest)
    (if (pair? rest)
      (if (char=? (car rest) #\/)
        (cons
          (list->string (reverse (cdr rest)))
          (list->string cur)) ;basename
        (itr (cons (car rest) cur) (cdr rest)))
      (cons "" pth)))
  (let ((p (pathfilter pth)))
    (itr '() (reverse  (string->list p)))))



(define (path-basename pth)
  (cdr (split-dir+base pth)))

(define (path-dirname pth)
  (car (split-dir+base pth)))

(define (file->list proc pth)
  (write pth) (newline)
  (with-input-from-file
    pth
    (lambda ()
      (define (itr cur)
        (let ((r (proc (current-input-port))))
          (if (eof-object? r)
            (reverse cur)
            (itr (cons r cur)))))
      (itr '()))))

(define (file->sexp-list pth)
  (file->list read pth))

(define (path-extension pth)
  (define (itr cur rest)
    (if (pair? rest)
      (let ((a (car rest))
            (d (cdr rest)))
        (cond
          ((char=? a #\.)
           (list->string cur))
          ((char=? a #\/)
           #f)
          (else
            (itr (cons a cur) d))))
      #f))
  (itr '() (reverse (string->list pth))))

;; tree walk
(define (directory-walk pth proc)
  (define (do-walk base cur)
    (define my-path (path-append base cur))
    (cond
      ((and (file-directory? my-path)
            (not (string=? cur ".."))
            (not (string=? cur ".")))
       (directory-walk my-path proc))
      ((and (file-regular? my-path)
            (not (file-directory? my-path)))
       (proc my-path))))
  (for-each (lambda (e) (do-walk pth e)) (directory-list pth)))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Library reader/generator main
;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define STUBTOP "lib-stub")
(define (generate libraries gen recipe)
  (define (genbody dirsym groups)
    (define dirname (path-append STUBTOP (symbol->string dirsym)))
    (define (gengroup group)
      (for-each (lambda (m)
                  (match m
                         ((grp srcpath (name . alias) code)
                          (when (eq? grp group)
                            (gen name alias code srcpath dirname dirsym)))
                         (else
                           (display (list "WARNING: ignored " (cadr m)))
                           (newline))))
        *library-map*))
    (when (not (file-exists? STUBTOP))
      (create-directory STUBTOP))
    (when (not (file-exists? dirname))
      (create-directory dirname))
    (for-each gengroup groups))
  (for-each (lambda (e) (genbody (car e) (cdr e)))
            recipe))

(define (read-library pth) ;; => (pth library-name . body)
  (define (realize sexp)
    (match sexp
           ((('library libname data ...))
            (cons libname sexp))
           (else
             (assertion-violation #f
                                  "invalid library format"
                                  sexp))))
  (cons pth
        (realize (file->sexp-list pth))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Library generators
;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


(define (call-with-output-file-force file proc)
  (define (mkdirp cur)
    (define dir (path-dirname cur))
    (unless (string=? "" dir)
      (unless (file-exists? dir)
        (mkdirp dir)
        (create-directory dir))))
  (when (file-exists? file)
    (delete-file file))
  (mkdirp file)
  (write (list 'GENERATING: file))(newline)
  (call-with-output-file file proc))

(define (calc-libpath basepath sexp ext)
  (string-append (fold-left1 (lambda (cur e)
                              (path-append cur (symbol->string e)))
                            basepath
                            sexp)
                 "."
                 ext))

(define (strip-rename lis)
  (fold-left1 (lambda (cur e)
               (match e
                      (('rename renames ...)
                       (append (map cadr renames) cur))
                      (otherwise
                        (cons otherwise cur))))
             '()
             lis))

(define (calc-relative libname libpath)
  (define dots (fold-left1 (lambda (cur e)
                            (string-append cur "../"))
                          ""
                          (cdr libname)))
  (string-append dots "../../" libpath))

;; GenRacket: R6RS library generator for Racket

(define (libgen-racket-body libname exports imports libpath flavor)
  `(library ,libname
             (export ,@exports)
             (import ,@imports
                     (yuni-runtime ,flavor))
    (%%internal-paste ,libpath)))

(define (libgen-racket-alias from to syms)
  `(library ,to
            (export ,@syms)
            (import ,from)))

(define (libgen-racket name alias libcode libpath basepath flavor)
  (define (base0filter/racket sexp)
    ;; Duh! Racket has (scheme base)!!!
    (if (equal? sexp '(scheme base))
      '(scheme base0)
      ;; Oh, (scheme file)..
      (if (equal? sexp '(scheme file))
        '(scheme file0)
        sexp)))
  (define (base0filter sexp) (if (eq? flavor 'racket)
                               (base0filter/racket sexp)
                               sexp))
  (define LIBEXT (case flavor 
                   ((racket) "mzscheme.sls") 
                   ((guile) "guile.sls")
                   (else 'Huh?)))
  (define (may-strip-specials lis)
    (define (standard-aux-keyword? sym)
      (case sym
        ((_ ... => else unquote unquote-splicing) #t)
        (else #f)))
    (fold-left1 (lambda (cur e) 
                 (if (and (eq? flavor 'guile) (standard-aux-keyword? e)) 
                   cur 
                   (cons e cur)))
               '()
               lis))
  (define outputpath (calc-libpath basepath name LIBEXT))
  (define aliaspath (and alias (calc-libpath 
                                 basepath (base0filter alias) LIBEXT)))
  (match libcode
         (('library libname 
           ('export exports ...)
           ('import imports ...) 
           body ...)
          (let ((ex (may-strip-specials exports)))
           (when (or (eq? flavor 'racket)
                     (not (= (length exports) (length ex)))) 
             (call-with-output-file-force
               outputpath
               (lambda (p)
                 (define body (libgen-racket-body name ex
                                                  (map base0filter imports) 
                                                  libpath flavor))
                 (put-string p "#!r6rs\n")
                 (pp body p))))
           (when alias
             (call-with-output-file-force
               aliaspath
               (lambda (p)
                 (define body (libgen-racket-alias name alias 
                                                   (strip-rename ex)))
                 (put-string p "#!r6rs\n")
                 (pp body p))))))
         (else
           (assertion-violation #f "Invalid library format" libcode))))

;; GenR7RS: R7RS library generator 
(define (libgen-r7rs-body libname exports imports libpath flavor)
  (define calclibpath (if (or (eq? flavor 'gauche)
                              (eq? flavor 'chicken)
                              (eq? flavor 'picrin))
                        (lambda (_ x) x)
                        calc-relative))
  (if (eq? flavor 'picrin)
    ;; Picrin requires reversed export...
    `(define-library ,libname
                     (import ,@imports (yuni-runtime picrin))
                     (include ,(calclibpath libname libpath))
                     (export ,@exports))
    ;; Generic R7RS
    `(define-library ,libname
                     (export ,@exports)
                     (import ,@imports (yuni-runtime r7rs))
                     (include ,(calclibpath libname libpath)))   ))

(define (libgen-r7rs-alias from to syms flavor)
  (if (eq? flavor 'picrin)
    ;; Picrin
    `(define-library ,to
                     (import ,from)
                     (export ,@syms)) 
    ;; Generic R7RS
    `(define-library ,to
                     (export ,@syms)
                     (import ,from))))

(define (libgen-r7rs name alias libcode libpath basepath flavor)
  (define LIBEXT (case flavor 
                   ((gauche picrin chicken) "scm")
                   ((sagittarius) "sls") 
                   (else "sld")))
  (define outputpath (calc-libpath basepath name LIBEXT))
  (define aliaspath (and alias (calc-libpath 
                                 basepath alias LIBEXT)))
  (define (keyword-symbol? sym)
    (let ((c (string-ref (symbol->string sym) 0)))
     (char=? #\: c)))
  (define (may-strip-specials lis)
    (define (standard-aux-keyword? sym)
      (case sym
        ((_ ... => else unquote unquote-splicing) #t)
        (else #f)))

    (define (strip-target? e)
      (case flavor
        ((gauche sagittarius) (keyword-symbol? e))
        ((chicken) (standard-aux-keyword? e))
        (else #f)))

    (fold-left1 (lambda (cur e) (if (strip-target? e) cur (cons e cur)))
               '()
               lis))

  (define (require-filtered-library? exports)
    (case flavor
      ((sagittarius)
       ;; The implementation R6RS-lite capable.
       ;; Alias only, if it had no keyword symbol 
       (let ((have-keyword-symbols? (fold-left1 (lambda (cur e)
                                                 (or cur (keyword-symbol? e)))
                                               #f
                                               exports)))
         have-keyword-symbols?))
      (else
        #t)))

  (match libcode
         (('library libname 
           ('export exports ...)
           ('import imports ...) 
           body ...)
          (when (require-filtered-library? exports)
            (call-with-output-file-force
              outputpath
              (lambda (p)
                (define body (libgen-r7rs-body name 
                                               (may-strip-specials exports) 
                                               imports
                                               libpath
                                               flavor))
                (pp body p))))
          (when alias
            (call-with-output-file-force
              aliaspath
              (lambda (p)
                (define body (libgen-r7rs-alias name alias 
                                                (may-strip-specials
                                                  (strip-rename exports))
                                                flavor))
                (pp body p)))))))

;; GenR6RSCommon: R6RS library generator 
(define (libgen-r6rs-common-alias from to syms)
  `(library ,to
            (export ,@syms)
            (import ,from)))

(define (libgen-r6rs-common name alias libcode libpath basepath flavor)
  (define LIBEXT "sls")
  (define outputpath (calc-libpath basepath name LIBEXT))
  (define aliaspath (and alias (calc-libpath 
                                 basepath alias LIBEXT)))
  (define (may-strip-keywords lis)
    ;; FIXME: Do we have to do this?
    lis)

  (match libcode
         (('library libname 
           ('export exports ...)
           ('import imports ...) 
           body ...)
          ;; Only for alias library
          (when alias
            (call-with-output-file-force
              aliaspath
              (lambda (p)
                (define body (libgen-r6rs-common-alias name alias 
                                                (may-strip-keywords
                                                  (strip-rename exports))))
                (pp body p)))))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Main
;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define config (file->sexp-list "config/config.scm"))

(define *library-directories* '())
(define *library-groups* '())
(define GenRacket '())
(define GenR7RS '())
(define GenR6RSCommon '())
(define libraries '())

(define-syntax read-var
  (syntax-rules () 
    ((_ var)
     (for-each (lambda (e) 
                 (match e
                        (('var . obj) 
                         (set! var obj))
                        (else 'do-nothing)))
               config))))

(read-var *library-directories*)
(read-var *library-groups*)
(read-var GenRacket)
(read-var GenR7RS)
(read-var GenR6RSCommon)

;; Collect libraries
(define (collect-libraries dir)
  (define files '())
  (define (library? pth)
    (let ((e (path-extension pth)))
      ;; FIXME: Do we need more?
      (and e
           (or (string=? e "sls")))))
  (when (file-exists? dir)
    ;; Recursively collect files on the dir
    (directory-walk dir (lambda (file) 
                          (when (library? file) 
                            (set! files (cons file files)))))
    (set! libraries (append libraries
                            (map read-library files)))))

(for-each (lambda (dir)
            (collect-libraries dir))
          *library-directories*)

;; Map library files
;;    map = (groupsym sourcepath (outname . aliased) . libcode)
(define (libname->groupname libname)
  (define libsym (car libname))
  (define (matchnames ret names)
    (and (pair? names)
         (let ((name (car names))
               (next (cdr names)))
           (or (and (eq? (if (pair? name) (car name) name)
                         libsym)
                    ret)
               (matchnames ret next)))))
  (define (itr cur)
    (match cur
           (((name . groups) . next)
            (or (matchnames name groups)
                (itr next)))
           (else #f)))
  (itr *library-groups*))

(define (libname->outname+aliased? libname)
  (define libsym-top (car libname))
  (define libsym-sub (cdr libname))
  (define (ret name alias)
    (cons (cons name libsym-sub) 
          (and alias (cons alias libsym-sub))))
  (define (alias entries)
    (match entries
           (((name '=> truename) . next)
            (or (and (eq? name libsym-top)
                     (ret name truename))
                (alias next)))
           ((name . next)
            (or (and (eq? name libsym-top)
                     (ret name #f))
                (alias next) ))
           (else #f)))
  (define (itr cur)
    (and (pair? cur)
         (let ((entries (cdar cur))
               (next (cdr cur)))
           (or (alias entries)
               (itr next)))))
  (itr *library-groups*))

(define *library-map*
  (map 
    (lambda (lib) 
      (match lib
             ((pth libname . code)
              (cons (libname->groupname libname)
                    (cons pth
                          (cons (libname->outname+aliased? libname)
                                code))))))
    libraries))

;; Generate !
(generate libraries libgen-racket GenRacket)
(generate libraries libgen-r7rs GenR7RS)
(generate libraries libgen-r6rs-common GenR6RSCommon)

;; Generate library list for _sanity.sps

(call-with-output-file-force
  "_testing_liblist.txt"
  (lambda (p)
    (for-each (lambda (e) (let ((pth (car e))
                                (libname (cadr e)))
                            (when (eq? 'yuni (car libname))
                              (display pth p)
                              (newline p))))
              libraries)))