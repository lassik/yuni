;; this file is an alias-library.
;;  alias of:
;;   lib/r7b-impl/base.sls
(library (scheme base)
         (export
             zero?
             write-u8
             write-string
             write-char
             write-bytevector
             with-exception-handler
             when
             vector?
             vector-set!
             vector-ref
             vector-map
             vector-length
             vector-for-each
             vector-fill!
             vector-copy!
             vector-copy
             vector-append
             vector->string
             vector->list
             vector
             values
             utf8->string
             unquote-splicing
             unquote
             unless
             u8-ready?
             truncate/
             truncate-remainder
             truncate-quotient
             truncate
             textual-port?
             syntax-rules
             syntax-error
             symbol?
             symbol=?
             symbol->string
             substring
             string?
             string>?
             string>=?
             string=?
             string<?
             string<=?
             string-set!
             string-ref
             string-map
             string-length
             string-for-each
             string-fill!
             string-copy!
             string-copy
             string-append
             string->vector
             string->utf8
             string->symbol
             string->number
             string->list
             string
             square
             set-cdr!
             set-car!
             set!
             round
             reverse
             remainder
             real?
             read-u8
             read-string
             read-line
             read-error?
             read-char
             read-bytevector!
             read-bytevector
             rationalize
             rational?
             raise-continuable
             raise
             quotient
             quote
             quasiquote
             procedure?
             positive?
             port?
             peek-u8
             peek-char
             parameterize
             pair?
             output-port?
             output-port-open?
             or
             open-output-string
             open-output-bytevector
             open-input-string
             open-input-bytevector
             odd?
             numerator
             number?
             number->string
             null?
             not
             newline
             negative?
             modulo
             min
             memv
             memq
             member
             max
             map
             make-vector
             make-string
             make-parameter
             make-list
             make-bytevector
             list?
             list-tail
             list-set!
             list-ref
             list-copy
             list->vector
             list->string
             list
             letrec-syntax
             letrec*
             letrec
             let-values
             let-syntax
             let*-values
             let*
             let
             length
             lcm
             lambda
             integer?
             integer->char
             input-port?
             input-port-open?
             inexact?
             inexact
             include-ci
             include
             import
             if
             guard
             get-output-string
             get-output-bytevector
             gcd
             for-each
             flush-output-port
             floor/
             floor-remainder
             floor-quotient
             floor
             file-error?
             features
             expt
             exact?
             exact-integer?
             exact-integer-sqrt
             exact
             even?
             error-object?
             error-object-message
             error-object-irritants
             error
             eqv?
             equal?
             eq?
             eof-object?
             eof-object
             else
             dynamic-wind
             do
             denominator
             define-values
             define-syntax
             define-record-type
             define
             current-output-port
             current-input-port
             current-error-port
             cons
             cond-expand
             cond
             complex?
             close-port
             close-output-port
             close-input-port
             char?
             char>?
             char>=?
             char=?
             char<?
             char<=?
             char-ready?
             char->integer
             ceiling
             cdr
             cddr
             cdar
             case
             car
             call/cc
             call-with-values
             call-with-port
             call-with-current-continuation
             cadr
             caar
             bytevector?
             bytevector-u8-set!
             bytevector-u8-ref
             bytevector-length
             bytevector-copy!
             bytevector-copy
             bytevector-append
             bytevector
             boolean?
             boolean=?
             binary-port?
             begin
             assv
             assq
             assoc
             apply
             append
             and
             abs
             >=
             >
             =>
             =
             <=
             <
             /
             ...
             -
             +
             *
             _
         )
         (import
             (r7b-impl base)
         )
) ;; library (scheme base)