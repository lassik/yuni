(library (mit-scheme-compat-scheme cxr)
         (export 
           caaaar caaadr caaar caadar caaddr caadr 
           cadaar cadadr cadar caddar cadddr caddr
           cdaaar cdaadr cdaar cdadar cdaddr cdadr 
           cddaar cddadr cddar cdddar cddddr cdddr)
         (import)

(define-primitive-names/yunifake
  caaaar caaadr caaar caadar caaddr caadr 
  cadaar cadadr cadar caddar cadddr caddr
  cdaaar cdaadr cdaar cdadar cdaddr cdadr 
  cddaar cddadr cddar cdddar cddddr cdddr))
