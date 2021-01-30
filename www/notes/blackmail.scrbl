#lang scribble/manual

@(require (for-label (except-in racket compile ...) a86))
@(require scribble/examples
          redex/pict
	  "../fancyverb.rkt"
	  "../utils.rkt"
	  "../../langs/blackmail/semantics.rkt"
	  "utils.rkt"
	  "ev.rkt")

@(define codeblock-include (make-codeblock-include #'here))

@(ev '(require rackunit a86))
@(for-each (λ (f) (ev `(require (file ,(path->string (build-path notes "blackmail" f))))))
	   '("interp.rkt" "compile.rkt" "random.rkt" "ast.rkt"))

@(define (shellbox . s)
   (parameterize ([current-directory (build-path notes "blackmail")])
     (filebox (emph "shell")
              (fancyverbatim "fish" (apply shell s)))))

@(require (for-syntax "../utils.rkt" racket/base "utils.rkt"))
@(define-syntax (shell-expand stx)
   (syntax-case stx ()
     [(_ s ...)
      (parameterize ([current-directory (build-path notes "blackmail")])
        (begin (apply shell (syntax->datum #'(s ...)))
	       #'(void)))]))

@;{ Have to compile 42.s (at expand time) before listing it }
@(shell-expand "racket -t compile-file.rkt -m add1-add1-40.rkt > add1-add1-40.s")

@title[#:tag "Blackmail"]{Blackmail: incrementing and decrementing}

@emph{Let's Do It Again!}

@table-of-contents[]

@section{Refinement, take one}

We've seen all the essential peices (a grammar, an AST data type
definition, an operational semantics, an interpreter, a compiler,
etc.) for implementing a programming language, albeit for an amazingly
simple language.

We will now, through a process of @bold{iterative refinement}, grow
the language to have an interesting set of features.


Our second language, which subsumes Abscond, is @bold{Blackmail}.
Expressions in Blackmail include integer literals and increment and
decrement operations.  It's still a dead simple language, but at least
programs @emph{do} something.

@section{Concrete syntax for Blackmail}

A Blackmail program consists of @tt{#lang racket} line and a
single expression, and the grammar of concrete expressions
is:

@centered{@render-language[B-concrete]}

So, @racket[0], @racket[120], and @racket[-42] are Blackmail expressions,
but so are @racket[(add1 0)], @racket[(sub1 120)], @racket[(add1
(add1 (add1 -42)))].

An example concrete program:

@codeblock-include["blackmail/add1-add1-40.rkt"]

@section{Abstract syntax for Blackmail}

The grammar of abstract Backmail expressions is:

@centered{@render-language[B]}

So, @racket[(Int 0)], @racket[(Int 120)], and
@racket[(Int -42)] are Blackmail AST expressions, but so are
@racket[(Prim1 'add1 (Int 0))], @racket[(Sub1 (Int 120))],
@racket[(Prim1 'add1 (Prim1 'add1 (Prim1 'add1 (Int -42))))].

A datatype for representing expressions can be defined as:

@codeblock-include["blackmail/ast.rkt"]

The parser is more involved than Abscond, but still
straightforward:

@codeblock-include["blackmail/parse.rkt"]


@section{Meaning of Blackmail programs}

The meaning of a Blackmail program depends on the form of the expression:

@itemlist[
@item{the meaning of an integer literal is just the integer itself,}
@item{the meaning of an increment expression is one more than the meaning of its subexpression, and}
@item{the meaning of a decrement expression is one less than the meaning of its subexpression.}]

The operational semantics reflects this dependence on the form of the
expression by having three rules, one for each kind of expression:

@(define ((rewrite s) lws)
   (define lhs (list-ref lws 2))
   (define rhs (list-ref lws 3))
   (list "" lhs (string-append " " (symbol->string s) " ") rhs ""))

@(with-unquote-rewriter
   (lambda (lw)
     (build-lw (lw-e lw) (lw-line lw) (lw-line-span lw) (lw-column lw) (lw-column-span lw)))
   (with-compound-rewriters (['+ (rewrite '+)]
                             ['- (rewrite '–)])
     (centered (begin (judgment-form-cases '(0)) (render-judgment-form 𝑩))
               (hspace 4)
               (begin (judgment-form-cases '(1)) (render-judgment-form 𝑩))
	       (hspace 4)
	       (begin (judgment-form-cases '(2)) (render-judgment-form 𝑩)))))

The first rule looks familiar; it's exactly the semantics of integers
from Abscond.  The second and third rule are more involved.  In
particular, they have @bold{premises} above the line.  If the premises
are true, the @bold{conclusion} below the line is true as well.  These
rules are @emph{conditional} on the premises being true.  This is in
contrast to the first rule, which applies unconditionally.

We can understand these rules as saying the following:
@itemlist[
@item{For all integers @math{i}, @math{((Int i),i)} is in @render-term[B 𝑩].}

@item{For expressions @math{e_0} and all integers @math{i_0} and
@math{i_1}, if @math{(e_0,i_0)} is in @render-term[B 𝑩] and @math{i_1
= i_0 + 1}, then @math{(@RACKET[(Prim1 'add1 (UNSYNTAX @math{e_0}))], i_1)}
is in @render-term[B 𝑩].}

@item{For expressions @math{e_0} and all integers @math{i_0} and
@math{i_1}, if @math{(e_0,i_0)} is in @render-term[B 𝑩] and @math{i_1
= i_0 - 1}, then @math{(@RACKET[(Prim1 'sub1 (UNSYNTAX @math{e_0}))], i_1)}
is in @render-term[B 𝑩].}
]

These rules are @bold{inductive}.  We start from the meaning of
integers and if we have the meaning of an expression, we can construct
the meaning of a larger expression.

This may seem a bit strange at the moment, but it helps to view the
semantics through its correspondence with an interpreter, which given
an expression @math{e}, computes an integer @math{i}, such that
@math{(e,i)} is in @render-term[B 𝑩].

Just as there are three rules, there will be three cases to the
interpreter, one for each form of expression:

@codeblock-include["blackmail/interp.rkt"]

@examples[#:eval ev
(interp (Int 42))
(interp (Int -7))
(interp (Prim1 'add1 (Int 42)))
(interp (Prim1 'sub1 (Int 8)))
(interp (Prim1 'add1 (Prim1 'add1 (Prim1 'add1 (Int 8)))))
]

Here's how to connect the dots between the semantics and interpreter:
the interpreter is computing, for a given expression @math{e}, the
integer @math{i}, such that @math{(e,i)} is in @render-term[B 𝑩].  The
interpreter uses pattern matching to determine the form of the
expression, which determines which rule of the semantics applies.

@itemlist[

@item{if @math{e} is an integer @math{(Int i)}, then we're done: this is the
right-hand-side of the pair @math{(e,i)} in @render-term[B 𝑩].}

@item{if @math{e} is an expression @RACKET[(Prim1 'add1 (UNSYNTAX
@math{e_0}))], then we recursively use the interpreter to compute
@math{i_0} such that @math{(e_0,i_0)} is in @render-term[B 𝑩].  But
now we can compute the right-hand-side by adding 1 to @math{i_0}.}

@item{if @math{e} is an expression @RACKET[(Prim1 'sub1 (UNSYNTAX
@math{e_0}))], then we recursively use the interpreter to compute
@math{i_0} such that @math{(e_0,i_0)} is in @render-term[B 𝑩].  But
now we can compute the right-hand-side by substracting 1 from @math{i_0}.}

]

This explaination of the correspondence is essentially a proof by
induction of the interpreter's correctness:

@bold{Interpreter Correctness}: @emph{For all Blackmail expressions
@racket[e] and integers @racket[i], if (@racket[e],@racket[i]) in
@render-term[B 𝑩], then @racket[(interp e)] equals
@racket[i].}

@section{An Example of Blackmail compilation}

Just as we did with Abscond, let's approach writing the compiler by
first writing an example.

Suppose we want to compile @racket[(add1 (add1 40))].  We already
know how to compile the @racket[40]: @racket[(Mov 'rax 40)].  To do
the increment (and decrement) we need to know a bit more x86-64.  In
particular, the @tt{add} (and @tt{sub}) instruction is relevant.  It
increments the contents of a register by some given amount.

Concretely, the program that adds 1 twice to 40 looks like:

@filebox-include[fancy-nasm "blackmail/add1-add1-40.s"]

The runtime stays exactly the same as before.

@shellbox["make add1-add1-40.run" "./add1-add1-40.run"]

@section{A Compiler for Blackmail}

To compile Blackmail, we make use of two more a86
instructions, @racket[Add] and @racket[Sub]:

@ex[
(displayln
 (asm-string
  (list (Label 'entry)
        (Mov 'rax 40)
        (Add 'rax 1)
        (Add 'rax 1)
        (Ret))))
]

The compiler consists of two functions: the first, which is given a
program, emits the entry point and return instructions, invoking
another function to compile the expression:

@codeblock-include["blackmail/compile.rkt"]

Notice that @racket[compile-e] is defined by structural
recursion, much like the interpreter.


We can now try out a few examples:

@ex[
(compile (Prim1 'add1 (Prim1 'add1 (Int 40))))
(compile (Prim1 'sub1 (Int 8)))
(compile (Prim1 'add1 (Prim1 'add1 (Prim1 'sub1 (Prim1 'add1 (Int -8))))))
]

And give a command line wrapper for parsing, checking, and compiling
files in @link["code/blackmail/compile-file.rkt"]{@tt{compile-file.rkt}},
we can compile files as follows:

@shellbox["racket -t compile-file.rkt -m add1-add1-40.rkt"]

And using the same @link["code/blackmail/Makefile"]{@tt{Makefile}}
setup as in Abscond, we capture the whole compilation process with a
single command:

@void[(shellbox "touch add1-add1-40.rkt")]
@shellbox["make add1-add1-40.run" "./add1-add1-40.run"]

Likewise, to test the compiler from within Racket, we use
the same @racket[asm-interp] function to encapsulate running
assembly code:

@ex[
(asm-interp (compile (Prim1 'add1 (Prim1 'add1 (Int 40)))))
(asm-interp (compile (Prim1 'sub1 (Int 8))))
(asm-interp (compile (Prim1 'add1 (Prim1 'add1 (Prim1 'add1 (Prim1 'add1 (Int -8)))))))
]

@section{Correctness and random testing}

We can state correctness similarly to how it was stated for Abscond:

@bold{Compiler Correctness}: @emph{For all expressions @racket[e] and
integers @racket[i], if (@racket[e],@racket[i]) in @render-term[B
𝑩], then @racket[(asm-interp (compile e))] equals
@racket[i].}


And we can test this claim by comparing the results of running
compiled and interpreted programs, leading to the following property,
which hopefully holds:

@ex[
(define (check-compiler e)
  (check-eqv? (interp e)
              (asm-interp (compile e))))]

The problem, however, is that generating random Blackmail programs is
less obvious compared to generating random Abscond programs
(i.e. random integers).  Randomly generating programs for testing is
its own well studied and active research area.  To side-step this
wrinkle, we have provided a small utility for generating random
Blackmail programs (@link["code/blackmail/random.rkt"]{random.rkt}),
which you can use, without needing the understand how it was
implemented.

@ex[
(eval:alts (require "random.rkt") (void))
(random-expr)
(random-expr)
(random-expr)
(random-expr)
(random-expr)
(displayln (asm-string (compile (random-expr))))
(for ([i (in-range 10)])
  (check-compiler (random-expr)))
]

It's now probably time to acknowledge a short-coming in our
compiler. Although it's great that random testing is
confirming the correctness of the compiler on
@emph{specific} examples, the compiler is unfortunately not
correct in general.  Neither was the Abscond compiler.

To see why, recall that integers in Blackmail are
represented as 64-bit values in the compiled code. The
problem arises when 64 bits isn't enough. Since the run-time
system interprets the 64-bit values as a @emph{signed}
integer, we have 1 bit devoted to the sign and 63 bits
devoted to the magnitude of the integer. So the largest
number we can represent is @racket[(sub1 (expt 2 63))] and
the smallest number is @racket[(- (expt 2 63))]. What
happens if a program exceeds these bounds? Well, whatever
x86 does.  Let's see:


@ex[
(define max-int (sub1 (expt 2 63)))
(define min-int (- (expt 2 63)))
(asm-interp (compile (Int max-int)))
(asm-interp (compile (Prim1 'add1 (Int max-int))))
(asm-interp (compile (Int min-int)))
(asm-interp (compile (Prim1 'sub1 (Int min-int))))]

Now there's a fact you didn't learn in grade school: in the
first example, adding 1 to a number made it smaller; in the
second, subtracting 1 made it bigger!

This problem doesn't exist in the interpreter:

@ex[
(interp (Int max-int))
(interp (Prim1 'add1 (Int max-int)))
(interp (Int min-int))
(interp (Prim1 'sub1 (Int min-int)))
]

So we have found a counter-example to the claim of compiler
correctness:

@ex[
(check-compiler (Prim1 'add1 (Int max-int)))
(check-compiler (Prim1 'sub1 (Int min-int)))
]

What can we do? This is the basic problem of a program not
satisfying its specification.  We have two choices:

@itemlist[
 @item{change the spec (i.e. the semantics and interpreter)}
 @item{change the program (i.e. the compiler)}
]

We could change the spec to make it match the behaviour of
the compiler. This would involve writing out definitions
that match the ``wrapping'' behavior we see in the compiled
code. Of course if the specification is meant to capture
what Racket actually does, taking this route would be a
mistake. Even independent of Racket, this seems like a
questionable design choice. Wouldn't it be nice to reason
about programs using the usual laws of mathematics (or at
least something as close as possible to what we think of as
math)? For example, wouldn't you like know that
@racket[(< i (add1 i))] for all integers @racket[i]?

Unforunately, the other choice seems to paint us in to a
corner. How can we ever hope to represent all possible
integers in just 64 bits? We can't. We need some new tricks.
So in the meantime, our compiler is not correct, but writing
down what it means to be correct is half the battle. We will
get to correctness, but for the time being, we view the
specification aspirationally.


@section{Looking back, looking forward}

We've now built two compilers; enough to start observing a pattern.

Recall the phases of a compiler described in
@secref["What does a Compiler look like?"]. Let's identify
these pieces in the two compilers we've written:

@itemlist[
@item{@bold{Parsed} into a data structure called an @bold{Abstract Syntax Tree}

@itemlist[@item{we use @racket[read] to parse text into a s-expression}]

@itemlist[@item{we use @racket[parse] to convert an s-expression into an AST}]}

@item{@bold{Checked} to make sure code is well-formed (and well-typed)}

@item{@bold{Simplified} into some convenient @bold{Intermediate Representation}

@itemlist[@item{we don't do any; the AST is the IR}]}

@item{@bold{Optimized} into (equivalent) but faster program

@itemlist[@item{we don't do any}]}

@item{@bold{Generated} into assembly x86

@itemlist[@item{we use @racket[compile] to generate assembly (in AST form),
  and use @racket[asm-string] to obtain printable concrete X86-64 code}]}

@item{@bold{Linked} against a run-time (usually written in C)

@itemlist[@item{we link against our run-time written in @tt{main.c}}]}

]

Our recipe for building compiler involves:

@itemlist[#:style 'ordered
@item{Build intuition with @bold{examples},}
@item{Model problem with @bold{data types},}
@item{Implement compiler via @bold{type-transforming-functions},}
@item{Validate compiler via @bold{tests}.}
]

As we move forward, the language we are compiling will grow.  As the
language grows, you should apply this recipe to grow the compiler
along with the language.
