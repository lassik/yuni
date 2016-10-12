;; Library directories
(*library-directories*
  "lib"
  "lib-r6rs"
  "lib-compat")

(*library-groups*
  ;; Yuni
  (yuni yuni yuniffi yuniconfig)
  (yunifake yunifake-util)
  (yuni-r6rs yuni-r6rs)
  ;; FIXME: Hack. We don't have any convention for generated libraries yet.
  ;; R7RS
  (compat-chicken
    (chicken-yuni => yuni)) 
  (compat-chibi
    (chibi-yuni => yuni))
  (compat-gauche
    (gauche-yuni => yuni))
  (compat-sagittarius
    (sagittarius-yuni => yuni))
  (compat-picrin
    (picrin-yuni => yuni))
  (compat-kawa
    (kawa-yuni => yuni))
  (r7rs-common
    (r7rs-common-yuni => yuni))
  ;; R6RS
  ;;; R7RS-bridge: R7RS library for R6RS implementations
  (r7rs-bridge ;; Some R6RS might not need this tough
    r7b-util
    (r7b-impl => scheme))
  (compat-guile
    (guile-yuni => yuni)
    (guile-r7b => r7b-compat))
  (compat-racket
    (racket-yuni => yuni)
    (racket-r7b => r7b-compat))
  (compat-chez
    (chez-yuni => yuni)
    (chez-r7b => r7b-compat))
  (compat-ironscheme
    (ironscheme-yuni => yuni)
    (ironscheme-r7b => r7b-compat))
  (compat-nmosh
    (nmosh-yuni => yuni)
    (nmosh-r7b => r7b-compat)
    (nmosh-r7b-util => r7b-util))
  (compat-larceny
    (larceny-yuni => yuni))
  (compat-vicare
    (vicare-r7b => r7b-compat)
    (vicare-yuni => yuni))
  (compat-rapid-gambit
    (rapid-gambit-yuni => yuni))
  (r6rs-common
    (r6rs-common-yuni => yuni))
  ;; Experimental Gambit R5RS
  (compat-gambit
    (gambit-yuni => yuni)
    (gambit-compat-scheme => scheme))
  ;; Experimental MIT/GNU Scheme R5RS
  (compat-mit-scheme
    (mit-scheme-yuni => yuni)
    (mit-scheme-compat-scheme => scheme))
  )

(GenRacket
  ;; Racket-styled library generator
  (racket
    yuni
    yunisrfi
    yuni-r6rs
    r7rs-bridge
    r6rs-common
    compat-racket
    )
  ;; Guile can import R6RS-light but no R7RS
  (guile
    yuni
    yunisrfi
    yuni-r6rs
    compat-guile
    r7rs-bridge
    r6rs-common)) 

(GenR7RS
  ;; R7RS library generator
  (gauche
    compat-gauche
    r7rs-common
    yuni) 
  (chibi
    compat-chibi
    r7rs-common
    yuni)
  (picrin
    compat-picrin
    r7rs-common
    yuni)
  (chicken
    compat-chicken
    r7rs-common
    yuni)
  (kawa
    yuni
    r7rs-common
    compat-kawa)
  ;; Sagittarius requires keyword syntax shim.
  (sagittarius
    compat-sagittarius
    yuni
    r7rs-common
    r6rs-common
    yuni-r6rs)
  ;; experimental
  (rapid-gambit
    yuni
    r7rs-common
    compat-rapid-gambit)) 

(GenR6RSCommon
  ;; R6RS-common assumes target can import R6RS-light libraries directly
  ;; Thus, it just renames the libraries
  ;; Larceny has R7RS libraries
  (larceny
    yuni
    compat-larceny
    yuni-r6rs
    r6rs-common)
  (ironscheme
    yuni
    compat-ironscheme
    yuni-r6rs
    r6rs-common
    r7rs-bridge)
  (chez
    yuni
    compat-chez
    yuni-r6rs
    r7rs-bridge
    r6rs-common)
  (vicare
    yuni
    compat-vicare
    yuni-r6rs
    r7rs-bridge
    r6rs-common)
  ;; Of course, we should do some dog-food
  (nmosh
    yuni
    compat-nmosh
    yuni-r6rs
    r7rs-bridge
    r6rs-common)
  ;; Experimental Gambit R5RS
  (gambit
    yuni
    compat-gambit
    yunifake
    r7rs-common)
  ;; Experimental MIT/GNU Scheme R5RS
  (mit-scheme
    yuni
    compat-mit-scheme
    yunifake
    r7rs-common)
  )
