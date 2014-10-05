(library (chez-r7b i23)
         (export error)
         (import (except (rnrs) error)
                 (rename (rnrs) (error error:r6)))
         (define (error msg . x)
           (apply error:r6 #f msg x)))
