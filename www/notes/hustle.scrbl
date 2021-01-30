#lang scribble/manual

@(require (for-label (except-in racket ...)))
@(require redex/pict
          racket/runtime-path
          scribble/examples
	  "../../langs/hustle/semantics.rkt"
	  "utils.rkt"
	  "ev.rkt"
  	  "../fancyverb.rkt"
	  "../utils.rkt")

@(define codeblock-include (make-codeblock-include #'h))

@(for-each (λ (f) (ev `(require (file ,(path->string (build-path notes "hustle" f))))))
	   '() #;'("interp.rkt" "ast.rkt" "parse.rkt" "compile.rkt" "asm/interp.rkt" "asm/printer.rkt"))

@title[#:tag "Hustle"]{Hustle: heaps and lists}


@emph{A little and a little, collected together, become a great deal;
the heap in the barn consists of single grains, and drop and drop
makes an inundation.}

@table-of-contents[]

@verbatim|{
TODO:
* Add section introducing '()
* Describe new use of 'rbx for heap pointer
  - picked a callee-saved register, therefore
    save once on entry, restore once on exit (use empty stack-alignment word)
    no need to do anything at C prim calls
}|

@section{Inductive data}

So far all of the data we have considered can fit in a single machine
word (64-bits).  Well, integers can't, but we truncated them and only
consider, by fiat, those integers that fit into a register.

In the @bold{Hustle} language, we will add two @bold{inductively
defined data types}, boxes and pairs, which will require us to relax
this restriction.

Boxes are like unary pairs, they simply hold a value, which can be
projected out.  Pairs hold two values which each can be projected out.

The new operations include constructors @racket[(box _e)] and
@racket[(cons _e0 _e1)] and projections @racket[(unbox _e)],
@racket[(car _e)], and @racket[(cdr _e)].

@margin-note{Usually boxes are @emph{mutable} data structures, like
OCaml's @tt{ref} type, but we will examine this aspect later.  For now,
we treat boxes as immutable data structures.}

These features will operate like their Racket counterparts:
@ex[
(unbox (box 7))
(car (cons 3 4))
(cdr (cons 3 4))
]


We use the following grammar for Hustle:

@centered[(render-language H)]

We can model this as an AST data type:

@filebox-include-fake[codeblock "hustle/ast.rkt"]{
#lang racket
;; type Op1 = ...
;;          | 'box | 'car | 'cdr | 'unbox
;; type Op2 = ...
;;          | 'cons
}

@section{Meaning of Hustle programs, implicitly}

The meaning of Hustle programs is just a slight update to Grift
programs, namely we add a few new primitives.

The update to the semantics is just an extension of the semantics of
primitives:

@(judgment-form-cases #f)

@;centered[(render-judgment-form 𝑯-𝒆𝒏𝒗)]

@centered[(render-metafunction 𝑯-𝒑𝒓𝒊𝒎 #:contract? #t)]

The interpreter similarly has an update to the @racket[interp-prims]
module:

@codeblock-include["hustle/interp-prims.rkt"]

Inductively defined data is easy to model in the semantics and
interpreter because we can rely on inductively defined data at the
meta-level in math or Racket, respectively.

In some sense, the semantics and interpreter don't shed light on
how constructing inductive data works because they simply use
the mechanism of the defining language to construct inductive data.
Let's try to address that.

@section{Meaning of Hustle programs, explicitly}

Let's develop an alternative semantics and interpreter that
describes constructing inductive data without itself
constructing inductive data.

The key here is to describe explicitly the mechanisms of
memory allocation and dereference. Abstractly, memory can be
thought of as association between memory addresses and
values stored in those addresses. As programs run, there is
a current state of the memory, which can be used to look up
values (i.e. dereference memory) or to extend by making a
new association between an available address and a value
(i.e. allocating memory). Memory will be assumed to be
limited to some finite association, but we'll always assume
programs are given a sufficiently large memory to run to
completion.

In the semantics, we can model memory as a finite function
from addresses to values. The datatype of addresses is left
abstract. All that matters is we can compare them for
equality.

We now change our definition of values to make it
non-recursive:

@centered{@render-language[Hm]}

We define an alternative semantic relation equivalent to 𝑯 called
𝑯′:

@centered[(render-judgment-form 𝑯′)]

Like 𝑯, it is defined in terms of another relation. Instead
of 𝑯-𝒆𝒏𝒗, we define a similar relation 𝑯-𝒎𝒆𝒎-𝒆𝒏𝒗 that has an
added memory component both as input and out:

@centered[(render-judgment-form 𝑯-𝒎𝒆𝒎-𝒆𝒏𝒗)]

For most of the relation, the given memory σ is simply
threaded through the judgment. When interpreting a primitive
operation, we also thread the memory through a relation
analagous to 𝑯-𝒑𝒓𝒊𝒎 called 𝑯-𝒎𝒆𝒎-𝒑𝒓𝒊𝒎. The key difference
for 𝑯-𝒎𝒆𝒎-𝒑𝒓𝒊𝒎 is that @racket[cons] and @racket[box]
operations allocate memory by extending the given memory σ
and the @racket[car], @racket[cdr], and @racket[unbox]
operations dereference memory by looking up an association
in the given memory σ:

@centered[(render-metafunction 𝑯-𝒎𝒆𝒎-𝒑𝒓𝒊𝒎 #:contract? #t)]


There are only two unexplained bits at this point:

@itemlist[
 @item{the metafunction
@render-term[Hm (alloc σ (v ...))] which consumes a memory
and a list of values. It produces a memory and an address
@render-term[Hm (σ_′ α)] such that @render-term[Hm σ_′] is
like @render-term[Hm σ] except it has a new association for
some @render-term[Hm α] and @render-term[Hm α] is @bold{
 fresh}, i.e. it does not appear in the domain of
@render-term[Hm σ].}

 @item{the metafunction @render-term[Hm (unload σ a)] used
  in the conclusion of @render-term[Hm 𝑯′]. This function does
  a final unloading of the answer and memory to obtain a answer
  in the style of 𝑯.}]


The definition of @render-term[Hm (alloc σ (v ...))] is
omitted, since it depends on the particular representation
chosen for @render-term[Hm α], but however you choose to
represent addresses, it will be easy to define appropriately.

The definition of @render-term[Hm (unload σ a)] just traces
through the memory to reconstruct an inductive piece of data:

@centered[(render-metafunction unload #:contract? #t)]
                         

With the semantics of explicit memory allocation and
dereference in place, we can write an interepreter to match
it closely.

We could define something @emph{very} similar to the
semantics by threading through some representation of a
finite function serving as the memory, just like the
semantics. Or we could do something that will produce the
same result but using a more concrete mechanism that is like
the actual memory on a computer.  Let's consider the latter
approach.

We can use a Racket @racket[list] to model the memory.

@;{
We will use a @racket[vector] of some size to model the
memory used in a program's evaluation. We can think of
@racket[vector] as giving us a continguous array of memory
that we can read and write to using natural number indices
as addresses. The interpreter keeps track of both the
@racket[vector] and an index for the next available memory
address. Every time the interpreter allocates, it writes in
to the appropriate cell in the @racket[vector] and bumps the
current address by 1.}

@codeblock-include["hustle/interp-heap.rkt"]



The real trickiness comes when we want to model such data in an
impoverished setting that doesn't have such things, which of course is
the case in assembly.

The problem is that a value such as @racket[(box _v)] has a value
inside it.  Pairs are even worse: @racket[(cons _v0 _v1)] has
@emph{two} values inside it.  If each value is represented with 64
bits, it would seem a pair takes @emph{at a minimum} 128-bits to
represent (plus we need some bits to indicate this value is a pair).
What's worse, those @racket[_v0] and @racket[_v1] may themselves be
pairs or boxes.  The great power of inductive data is that an
arbitrarily large piece of data can be constructed.  But it would seem
impossible to represent each piece of data with a fixed set of bits.

The solution is to @bold{allocate} such data in memory, which can in
principle be arbitrarily large, and use a @bold{pointer} to refer to
the place in memory that contains the data.

@;{ Really deserves a "bit" level interpreter to bring this idea across. }


@;codeblock-include["hustle/interp.rkt"]

@section{Representing Hustle values}

The first thing do is make another distinction in the kind of values
in our language.  Up until now, each value could be represented in a
register.  We now call such values @bold{immediate} values.

We introduce a new category of values which are @bold{pointer} values.
We will (for now) have two types of pointer values: boxes and pairs.

So we now have a kind of hierarchy of values:

@verbatim{
- values
  + pointers (non-zero in last 3 bits)
    * boxes
    * pairs
  + immediates (zero in last three bits)
    * integers
    * characters
    * booleans
    * ...
}

We will represent this hierarchy by shifting all the immediates over 3
bits and using the lower 3 bits to tag things as either being
immediate (tagged @code[#:lang "racket"]{#b000}) or a box or pair.
To recover an immediate value, we just shift back to the right 3 bits.

The pointer types will be tagged in the lowest three bits.  A box
value is tagged @code[#:lang "racket"]{#b001} and a pair is tagged
@code[#:lang "racket"]{#b010}.  The remaining 61 bits will hold a
pointer, i.e. an integer denoting an address in memory.

The idea is that the values contained within a box or pair will be
located in memory at this address.  If the pointer is a box pointer,
reading 64 bits from that location in memory will produce the boxed
value.  If the pointer is a pair pointer, reading the first 64 bits
from that location in memory will produce one of the value in the pair
and reading the next 64 bits will produce the other.  In other words,
constructors allocate and initialize memory.  Projections dereference
memory.

The representation of pointers will follow a slightly different scheme
than that used for immediates.  Let's first talk a bit about memory
and addresses.

A memory location is represented (of course, it's all we have!) as a
number.  The number refers to some address in memory.  On an x86
machine, memory is @bold{byte-addressable}, which means each address
refers to a 1-byte (8-bit) segment of memory.  If you have an address
and you add 1 to it, you are refering to memory starting 8-bits from the
original address.

We will make a simplifying assumption and always store things in
memory in multiples of 64-bit chunks.  So to go from one memory
address to the next @bold{word} of memory, we need to add 8 (1-byte
times 8 = 64 bits) to the address.

What is 8 in binary?  @code[#:lang "racket"]{#b1000}

What's nice about this is that if we start from a memory location that
is ``word-aligned,'' i.e. it ends in @code[#:lang "racket"]{#b000},
then every 64-bit index also ends in @code[#:lang "racket"]{#b000}.

What this means is that @emph{every} address we'd like to represent
has @code[#:lang "racket"]{#b000} in its least signficant bits.  We
can therefore freely uses these three bits to tag the type of the
pointer @emph{without needing to shift the address around}.  If we
have a box pointer, we can simply zero out the box type tag to obtain
the address of the boxes content.  Likewise with pairs.






So for example the following creates a box containing the value 7:

@#reader scribble/comment-reader
(racketblock
(seq (Mov 'rax (arithmetic-shift 7 imm-shift))  
     (Mov (Offset 'rdi 0) 'rax) ; write '7' into address held by rdi
     (Mov 'rax 'rdi)            ; copy pointer into return register
     (Or 'rax type-box)         ; tag pointer as a box
     (Add 'rdi 8))              ; advance rdi one word
)

If @racket['rax] holds a box value, we can ``unbox'' it by erasing the
box tag, leaving just the address of the box contents, then
dereferencing the memory:

@#reader scribble/comment-reader
(racketblock
(seq (Xor 'rax type-box)         ; erase the box tag
     (Mov 'rax (Offset 'rax 0))) ; load memory into rax
)

Pairs are similar.  Suppose we want to make @racket[(cons 3 4)]:

@#reader scribble/comment-reader
(racketblock
(seq (Mov 'rax (arithmetic-shift 3 imm-shift))
     (Mov (Offset 'rdi 0) 'rax) ; write '3' into address held by rdi
     (Mov 'rax (arithmetic-shift 4 imm-shift))
     (Mov (Offset 'rdi 1) 'rax) ; write '4' into word after address held by rdi
     (Mov 'rax rdi)             ; copy pointer into return register
     (Or 'rax type-pair)        ; tag pointer as a pair
     (Add 'rdi 16))             ; advance rdi 2 words
)

If @racket['rax] holds a pair value, we can project out the elements
by erasing the pair tag, leaving just the address of the pair contents,
then dereferencing either the first or second word of memory:

@#reader scribble/comment-reader
(racketblock
(seq (Xor 'rax type-pair)         ; erase the pair tag
     (Mov 'rax (Offset 'rax 0))   ; load car into rax
     (Mov 'rax (Offset 'rax 1)))  ; or... load cdr into rax
)

From here, writing the compiler for @racket[box], @racket[unbox],
@racket[cons], @racket[car], and @racket[cdr] is just a matter of
putting together pieces we've already seen such as evaluating multiple
subexpressions and type tag checking before doing projections.

@section{Allocating Hustle values}

We use a register, @racket['rdi], to hold the address of the next free
memory location in memory.  To allocate memory, we simply increment
the content of @racket['rdi] by a multiple of 8.  To initialize the
memory, we just write into the memory at that location.  To contruct a
pair or box value, we just tag the unused bits of the address.


... will have to coordinate with the run-time system to
initialize @racket['rdi] appropriately.
@secref["hustle-run-time"]

@section{A Compiler for Hustle}


The complete compiler is given below.

@codeblock-include["hustle/compile.rkt"]

@section[#:tag "hustle-run-time"]{A Run-Time for Hustle}

The run-time system for Hustle is more involved for two main reasons:

The first is that the compiler relies on a pointer to free memory
residing in @racket['rdi].  The run-time system will be responsible
for allocating this memory and initializing the @racket['rdi]
register.  To allocate memory, it uses @tt{malloc}.  It passes the
pointer returned by @tt{malloc} to the @tt{entry} function.  The
protocol for calling functions in C says that the first argument will
be passed in the @racket['rdi] register.  Since @tt{malloc} produces
16-byte aligned addresses on 64-bit machines, @racket['rdi] is
initialized with an address that ends in @code[#:lang
"racket"]{#b000}, satisfying our assumption about addresses.

The second complication comes from printing.  Now that values include
inductively defined data, the printer must recursively traverse these
values to print them.

The complete run-time system is below.

@filebox-include[fancy-c "hustle/main.c"]
