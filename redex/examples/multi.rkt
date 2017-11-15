#lang racket

(require redex)
(require "../resugar.rkt")

;;   booleans   (TAPL pg.93)
;;   nats       (TAPL pg.93)
;;   lambda     (TAPL pg.103)
;;   unit       (TAPL pg.119)
;;   ascription (TAPL pg.122)
;;   fix        (TAPL pg.144)

(define-resugarable-language multi
  #:keywords(if true false succ pred iszero zero
                λ thunk let = : ..
                calctype
                Bool Num ->)
  (e ::= ....
     ; booleans
     (if e e e)
     ; numbers
     (+ e e)
     ; lambda
     (e e*))
  (v ::= ....
     ; booleans
     true
     false
     ; numbers
     number
     ; lambda
     (λ Γ e)
     (λ param* e))
  (param* ::= ϵ (cons (x : t) param*) (x* : t* ..))
  (t ::= ....
     Bool
     Num
     (t* -> t))
  (s ::= ....
     (let bind* s))
  #;(bind* ::= ϵ x (cons (x = s) bind*) (x* = s* ..)))


(define-core-type-system multi

  ; boolean
  [(⊢ Γ e_1 t_1)
   (⊢ Γ e_2 t_2)
   (⊢ Γ e_3 t_3)
   (con (t_1 = Bool))
   (con (t_2 = t_3))
   ------ t-if
   (⊢ Γ (if e_1 e_2 e_3) t_3)]

  [------ t-true
   (⊢ Γ true Bool)]

  [------ t-false
   (⊢ Γ false Bool)]

  ; number
  [------ t-num
   (⊢ Γ number Num)]

  [(⊢ Γ e_1 t_1)
   (⊢ Γ e_2 t_2)
   (con (t_1 = Num))
   (con (t_2 = Num))
   ------ t-plus
   (⊢ Γ (+ e_1 e_2) Nat)]

  ; lambda
  [(side-condition ,(variable? (term x)))
   (where t (lookup x Γ))
   ------ t-id
   (⊢ Γ x t)]

  [(side-condition ,(variable? (term x)))
   (where #f (lookup x Γ))
   (where x_Γ ,(fresh-type-var-named 'Γ))
   (where x_t (fresh-var))
   (con (Γ = (bind x x_t x_Γ)))
   ------ t-id-bind
   (⊢ Γ x x_t)]

  #;[(⊢ (append Γ Γ_params) e t)
   (env-types Γ_params t*)
   ------ t-lambda
   (⊢ Γ (λ Γ_params e) (t* -> t))]

  #;[(⊢ (bind* x* t* Γ) e t)
   ------ t-lambda
   (⊢ Γ (λ [x* : t* ..] e) (t* -> t))]

  #;[(⊢ Γ e t)
   ------ t-lambda-empty
   (⊢ Γ (λ ϵ e) (ϵ -> t))]

  #;[(⊢ Γ (λ param*) t_fun)
   (where x_args (fresh-var))
   (where x_ret (fresh-var))
   (con (t_fun = (x_args -> x_ret)))
   ------ t-lambda-cons
   (⊢ Γ (λ (cons (x : t) param*) e) ((cons t x_args) -> x_ret))]

  [(⊢ (append Γ_params Γ) e t)
   (env-types Γ_params t*)
   ------ t-lambda
   (⊢ Γ (λ Γ_params e) (t* -> t))]
  
  [(⊢ (bind* x* t* Γ) e t)
   ------ t-lambda*
   (⊢ Γ (λ [x* : t* ..] e) (t* -> t))]
  
  [(⊢ Γ e_fun t_fun)
   (⊢* Γ e*_args t*_args)
   (where x_ret (fresh-var))
   (con (t_fun = (t*_args -> x_ret)))
   ------ t-apply
   (⊢ Γ (e_fun e*_args) x_ret)])


(define-judgment-form multi
  #:contract (env-types Γ t*)
  #:mode     (env-types I O)

  [------ env-types-ϵ
   (env-types ϵ ϵ)]

  [(env-types Γ t*)
   ------ env-types-bind
   (env-types (bind x t Γ) (cons t t*))]

  [(where x_t (fresh-var))
   (con (assumption ('env-types x = x_t)))
   ------ env-types-premise
   (env-types x x_t)])



(define rule_let
  (ds-rule "let" #:capture()
           (let [xs = ~vs ..] ~body)
           #;(λ (bind* xs ts ϵ) ~body)
           (calctype* ~vs as ts in
                      ;((λ ϵ ~body) ~vs))))
                      (λ (xs : ts ..) ~body))))
             ;((λ (bind* xs ts ϵ) ~body) ~vs))))









(define (do-resugar rule)
  (Resugared-rule (resugar multi rule ⊢)))

(show-derivations
 (map do-resugar
      (list rule_let)))
