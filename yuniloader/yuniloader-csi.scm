;; Uses same options as yunifake:
;; 
;;  -VERBOSE
;;  -MOD <str>
;;  -I <str>
;; 
;; Currently, only for chicken interpreter(csi)
(define ERRPORT current-error-port)
(define (PCK . obj)
  (if %verbose
    (begin
      (if #t ;; (not DEBUGGING)
        (begin
          (display "-> " (ERRPORT))
          (for-each (lambda (e)
                      (write e (ERRPORT))
                      (display " " (ERRPORT)))
                    obj)
          (newline (ERRPORT)))))))

(define (init-ffi-stub!)
  (define (tryload fn)
    (PCK 'TRY-FFI-STUB fn)
    ;; FIXME: It seems we cannot catch exceptions on load..
    ;; FIXME: Findout more precise method on this
    (with-exception-handler
      (lambda (x) #f)
      (lambda () 
        (and (file-exists? fn)
             (load fn) 
             (provide 'yuniffi-chicken)
             #t))))
  (let ((fn-dll (string-append STUBDIR "/yuniffi-chicken.dll"))
        (fn-so (string-append STUBDIR "/yuniffi-chicken.so")))
    (let ((loaded? (or (tryload fn-so)
                       (tryload fn-dll))))
      (when loaded?
        (PCK 'PREFIX: STUBDIR)
        (%%yuniffi-module-prefix-set! STUBDIR)))))

(define (run filename)

  (define (make-library-path base nam)
    ;(PCK 'make-library-path: base nam)
    (if (pair? nam)
      (make-library-path (string-append (string-append base "/") 
                                        (symbol->string (car nam))) 
                         (cdr nam))
      (string-append base ".scm")))
  (define loaded-libraries '())
  (define (library-loaded? nam)
    (define (itr rest)
      (and (pair? rest)
           (or (equal? nam (caar rest))
               (itr (cdr rest)))))
    (itr loaded-libraries))
  (define (mark-as-loaded! nam filename)
    (set! loaded-libraries (cons (cons nam filename) loaded-libraries)))
  (define (builtin-library? nam)
    (and (pair? nam)
         (let ((prefix (car nam)))
          (case prefix
            ((scheme chicken matchable lolevel numbers yuniffi-chicken posix) #t)
            ((srfi) (number? (cadr nam)))
            (else #f)))))

  (define (library-name->path name)
    (define (itr rest)
      (if (pair? rest)
        (or (let ((name (make-library-path (car rest) name)))
              (PCK 'TRYING: name)
              (and (file-exists? name)
                   name))
            (itr (cdr rest)))
        (error "library-name->path: Cannot find library for" name)))
    (PCK 'LOOKUP: name)
    (itr import-dirs))

  (define (realize-library name)
    (unless (or (builtin-library? name) (library-loaded? name))
      (let ((path (library-name->path name)))
       (load-library-file path)
       (mark-as-loaded! name path))))

  (define (process-import-clause lis)
    (cond ((pair? lis)
           (if (or (eq? (car lis) 'only)
                   (eq? (car lis) 'except)
                   (eq? (car lis) 'rename))
             (process-import-clause (cadr lis))
             (realize-library lis)))
          (else (error "process-import-clause: Wrong format" lis))))

  (define (load-library-file path)
    (call-with-input-file 
      path
      (lambda (p)
        (let ((x (read p)))
         (PCK 'READING: path)
         (unless (and (pair? x) (eq? (car x) 'define-library))
           (error "load-library-file: Malformed library" path))
         (let ((import-clause (cdr (cadddr x))))
          (PCK 'PROC: import-clause)
          (for-each process-import-clause import-clause))))))

  (init-ffi-stub!)

  (PCK 'RUN: filename)

  (unless (and (string? filename) (file-exists? filename))
    (error "run: File not found" filename))

  ;; Lookup for import clause
  (call-with-input-file
    filename
    (lambda (p)
      ;; Read (import ...)
      (let ((x (read p)))
       (unless (and (pair? x) (eq? (car x) 'import))
         (error "run: Malformed program" filename))
       (for-each process-import-clause (cdr x)))))

  ;; Do actual load process in reverse order
  (let ((files (map cdr (reverse loaded-libraries))))
   (for-each (lambda (filename) 
               (PCK 'LOADING: filename)
               (load filename)) files))

  ;(PCK 'LIBS: (map cdr (reverse loaded-libraries)))

  ;; Load R7RS program
  ;; FIXME: WHY can't we use just a (load filename) ???
  (call-with-input-file
    filename
    (lambda (p)
      (define (port->list p)
        (define (itr cur)
          (let ((r (read p)))
           (if (eof-object? r) 
             (reverse cur)
             (itr (cons r cur)))))
        (itr '()))
      (define (translate-imports lis)
        (define (xclause cls)
          ;(PCK 'CLAUSE: cls)
          (cond ((pair? cls)
                 (case (car cls)
                   ((only except rename)
                    (cons (car cls)
                          (cons 
                            (xclause (cadr cls))
                            (cddr cls))))
                   ((srfi)
                    (error "SRFI??" cls))
                   (else
                     (let loop ((str "") (rest cls))
                      (if (pair? rest)
                        (let ((a (car rest))
                              (d (cdr rest)))
                          (loop
                            (string-append
                              str
                              (if (string=? "" str) "" ".")
                              (symbol->string a))
                            d))
                        (string->symbol str))))))
                (else
                  (error "Invalid clause: " cls))))
        (cons 'import
              (map xclause (cdr lis))))
      (let ((prog (port->list p)))
       (unless (pair? prog)
         (error "run: Fatal"))
       (let ((imports (translate-imports (car prog)))
             (body (cdr prog)))
         (PCK 'IMPORTS: imports)
         (eval `(module YUNI-PROGRAM () ,imports ,@body)))))))

(define ARG (command-line-arguments))
(define STUBDIR #f)
(define %verbose #t)
(define import-dirs '())

(define (procargs!)
  (cond
    ((pair? ARG)
     (let ((a (car ARG))
           (d (cdr ARG)))
       (cond
         ((string=? "-VERBOSE" a)
          (set! %verbose #t)
          (set! ARG d)
          (procargs!))
         ((string=? "-I" a)
          (let ((pth (car d))
                (next (cdr d)))
            (set! import-dirs (cons pth import-dirs))
            (set! ARG next)
            (procargs!)))
         ((string=? "-MOD" a)
          (let ((pth (car d))
                (next (cdr d)))
            (set! STUBDIR pth)
            (set! ARG next)
            (procargs!))))))))


(PCK 'CMD: ARG)
(procargs!)
(PCK 'ARG: ARG)

(run (car ARG))

