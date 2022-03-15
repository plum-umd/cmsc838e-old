#lang scribble/manual
@(require "defns.rkt")
@title[#:style '(unnumbered)]{Project}

There will be a final course project to be completed over the last several weeks
of the course. The project will involve conducting a research project on the
design and implementation of programming languages.

@section{Project Proposal}

Due: March 29

The project proposal is a short (2-4 page) document that sketches out the
problem and proposed solution which will be investigated in your research
project.

The project proposal should have a descriptive title and list all of the
co-authors contributing to this project. You may work individually or with any
number of collabatorators.

The project proposal should motivate a problem within the field of programming
languages (or within another field that can be solved with programming language
techniques). Your project does NOT need to be novel, although a novel project
has a better chance of leading to a publishable result. You should take
inspiration from papers published in reputable conferences or journals. For PL,
the main conferences are PLDI, ICFP, POPL, and OOPSLA, but there are many more.
If you'd like guidance on other venues, please ask.

The best way to motivate and discuss a problem is to use concrete examples
to bolster the discussion.

The final deliverables for you project will include:

@itemlist[

@item{A full project report, which should look more or less like a conference or
workshop paper (but will not be evaluated based on novelty).}

@item{A software artifact that provides support for the claims made in the
report.}

]

The project proposal should sketch a proposed approach to the problem identified
in the proposal. Describe what methods or techniques will be used. The proposal
should also describe how the success of the proposed solution will be measured.
This may include things like proving theorems, conducting empirical evaluations,
or other metrics.

The proposal should include a discussion of related work from the literature and
cite each reference that is discussed. The proposal should identify a few
(between 1 and 3) primary references which will closely guide the approach of
the project, but also discuss several (at least two, but potentially many more)
secondary references that are closely related by not directly guiding the
proposed work.

Projects should be scoped in a way that at least preliminary results can be
achieved and reported on by the end of the course. Good projects proposals have
incremental milestones so that results can still be shown even if the work isn't
fully completed by the deadline (and it's often good to think about a larger
scope for a project in case you're interested in continuing with it after the
semester ends.)

All final projects must be accompanied by a software "artifact." Often these
artifacts are prototype implementations of a language design or feature. You may
build your project's artifact from scratch or you may modify or extend an
existing software (subject to that software's license). You may use the 430
materials as a basis if you'd like, although you are not required to do so.

@subsection{Project ideas}

This list of project ideas is intended to help get you started if you're not
sure what to work on.  It is not meant to be exhaustive.

@itemlist[

@item{Macros and modules. Using
@emph{@link["https://www.cs.utah.edu/plt/publications/popl16-f.pdf"]{Binding as
Sets of Scope}} as the basis, implement a macro system for the 430
compiler. You can start by implementing this for one of the earlier language
(e.g. Iniquity), but try to scale it up to Outlaw. You can also start with the
early expander from the Flatt paper and try to work up to the more sophisticated
versions, ideally getting up to the version with a module system.}

@item{Occurrence typing. Using
@emph{@link["https://www2.ccs.neu.edu/racket/pubs/icfp10-thf.pdf"]{Logical Types
for Untyped Languages}} as the basis, implement
a type system for the 430 language. You can start by implementing this for the
Iniquity language and trying to scale it up to later languages.}

@item{Program analysis based optimizations. Using
@emph{@link["https://arxiv.org/pdf/1007.4446.pdf"]{Abstracting Abstract
Machines}} as the basis, implement a program analysis tool for the 430 language.
After implementing the analyzer, integrate it into the compiler to justify
optimizations such as direct function calls, run-time type tag checking
elimination, constant propagation, or other optimizations.}

@item{Efficient multiple return values. Using
@emph{@link["https://dl.acm.org/doi/10.1145/182590.156784"]{An Efficient
Implementation of Multiple Return Values in Scheme}}, implement multiple return
values in the 430 compiler. This is particularly well-suited for students who
did multiple return values as a 430 project and want to explore a more
sophisticated approach.}

@item{Gradual typing. Using
@emph{@link["https://akuhlens.github.io/paper/pldi19.pdf"]{Toward Efficient
Gradual Typing for Structural Types via Coercions}}, implement a gradual type
system for the 430 compiler. Modify the run-time implementation to take
advantage of the new type invariants.}

]

@section{Artifact}

Due: end of semester



@section{Project Report}

Due: end of semester


