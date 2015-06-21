(import (yuni scheme)
        (scheme time)
        (scheme complex)
        (scheme inexact)
        (scheme write)
        (scheme lazy)
        (yuni testing testeval)
        (yuni async) (yuni core) (yuni base shorten)
        (yuni base match))

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
              (reverse failed-forms))))

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

(check-equal 10 ((^a (+ 1 a)) 9))
(check-equal 10 ((^ (form) (+ 2 form)) 8))
(check-equal 10 (match '(1 10 11) ((a b c) b)))

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

(check-finish)
