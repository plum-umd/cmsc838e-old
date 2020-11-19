#lang racket
(provide (all-defined-out))

;; type Asm = [Listof Instruction]
;; type Instruction =
;; | (Label Symbol)
;; | (Ret)
;; | (Mov Arg Arg)
;; | (Add Arg Arg)
;; | (Sub Arg Arg)
;; | (Cmp Arg Arg)
;; | (Jmp Symbol)
;; | (Je  Symbol)
;; | (Jne Symbol)
;; | (And Arg Arg)
;; | (Call Symbol)
;; | (Push Reg)
;; | (Pop Reg)
;; type Arg =
;; | Reg
;; | Number
;; type Reg =
;; | 'rax
;; | 'rbx
;; | 'rsp
(struct Label (x) #:prefab)
(struct Ret () #:prefab)
(struct Mov (a1 a2) #:prefab)
(struct Add (a1 a2) #:prefab)
(struct Sub (a1 a2) #:prefab)
(struct Cmp (a1 a2) #:prefab)
(struct Jmp (x) #:prefab)
(struct Je (x) #:prefab)
(struct Jne (x) #:prefab)
(struct And (a1 a2) #:prefab)
(struct Call (x) #:prefab)
(struct Push (r) #:prefab)
(struct Pop (r) #:prefab)

(struct Offset (r i) #:prefab)