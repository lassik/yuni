(import (yuni scheme)
        (yunitest mini))

(check-equal #t #t)
(check-equal #f #f)
(check-equal 1234 1234)
(check-equal (bytevector 0 1 2 3) (bytevector 0 1 2 3))
(check-equal #\newline #\newline)
(check-equal (eof-object) (eof-object))
(let ((a (lambda () 'ok)))
 (check-equal a a))
(check-equal 'symbol (string->symbol "symbol"))
(check-equal "symbol" (symbol->string 'symbol))
(check-equal "abc" (list->string (list #\a #\b #\c)))
(check-equal #\\ #\\)

(check-finish)
