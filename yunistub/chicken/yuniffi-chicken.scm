(foreign-declare 
  "#include <stdint.h>"
  "#include \"../common/bootstrap.inc.c\"")

(module 
  yuniffi-chicken
  (export %%yuniffi-nccc-bootstrap
          %%yuniffi-nccc-call
          %%yuniffi-module-prefix-set!-inner
          %%yuniffi-module-prefix
          %%yuniffi-ptr64-ref/ptr
          %%yuniffi-ptr64-ref/bv
          %%yuniffi-ptr64-set!/bv)
  (import scheme chicken foreign lolevel)

;;

(define %%yuniffi-module-dir #f)

(define (%%yuniffi-module-prefix)
  %%yuniffi-module-dir)

(define %%yuniffi-nccc-bootstrap 
  (foreign-value "(void*)yuniffi_bootstrap0" c-pointer))

(define (%%yuniffi-module-prefix-set!-inner str)
  (set! %%yuniffi-module-dir str))

(define (%%yuniffi-nccc-call func in in_offset in_len out out_offset out_len)
  ;(display (list 'nccc-call: in)) (newline)
  (%%%yuniffi-nccc-call
    func in in_offset in_len out out_offset out_len))

(define %%yuniffi-ptr64-ref/ptr
  (foreign-lambda*
    c-pointer
    ((c-pointer ptr)
     (size_t off))
    "void* in;
     in = ptr + off;
     C_return((void*)(uintptr_t)(*(uint64_t*)in));"))

(define %%yuniffi-ptr64-ref/bv
  (foreign-lambda*
    c-pointer
    ((nonnull-u8vector in)
     (size_t off))
    "void* in0;
     in0 = in + off;
     C_return((void*)(uintptr_t)(*(uint64_t*)in0));"))

(define %%yuniffi-ptr64-set!/bv
  (foreign-lambda*
    void
    ((nonnull-u8vector in)
     (size_t off)
     (c-pointer v))
    "void* in0;
     in0 = in + off;
     *(uint64_t *)in0 = (uintptr_t)v;"))

(define %%%yuniffi-nccc-call
  (foreign-safe-lambda* 
    void 
    ((c-pointer func)
     (nonnull-u8vector in)
     (int in_offset)
     (int in_len)
     (nonnull-u8vector out)
     (int out_offset)
     (int out_len)) 
    "uint64_t* in0;
     uint64_t* out0;
     yuniffi_nccc_func_t callee;
     int x;
     int y;
     
     callee = (yuniffi_nccc_func_t)func;
     in0 = (uint64_t*)in;
     out0 = (uint64_t*)out;

     if(0){
     //printf(\"in0 = %p\\n\", in0);
     for(x=0; x!= in_len; x++){
             printf(\"in %02d: %lx\\n\",x+in_offset,in0[x+in_offset]);
     }
     }
     
     callee(&in0[in_offset], in_len, &out0[out_offset], out_len);

     if(0){
     //printf(\"out0 = %p\\n\", out0);
     for(y=0; y!= out_len; y++){
             printf(\"out%02d: %lx\\n\",y+out_offset,out0[y+out_offset]);
     }
     }
     ")))

(import yuniffi-chicken)

;; Exported to yuniloader
(define %%yuniffi-module-prefix-set! %%yuniffi-module-prefix-set!-inner)
