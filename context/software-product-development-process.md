# Process Specification: Creating Software with AI

> This document is the process. For each new product, drop the `context/` folder
> into the project root. The process lives inside it. Project-specific artifacts
> live in the other files in `context/` — you do not copy and fill in this
> document.

---

## What This Is

A repeatable, tool-agnostic process that takes any software product idea from
first sentence to a closed cycle, with explicit feedback loops at every level
that keep the product coherent as it evolves.

It is designed for solo developers and small product teams who can build
software and want to use AI as a force multiplier — not a replacement.

---

## Language

The terms below are binding vocabulary for this process. Use them exactly when
writing artifacts, naming modules, or grilling decisions. Substituting close
synonyms ("component," "service," "boundary," "wrapper") fragments understanding
across the codebase and across cycles. Full definitions are in the Appendix;
this section is the binding list.

**Architecture**

- **Module** — anything with an interface and an implementation. Scale-agnostic.
- **Interface** — everything a caller must know to use a module correctly.
- **Implementation** — the code inside a module. Distinct from adapter: a small
  adapter can wrap a large implementation, and vice versa.
- **Depth** — leverage a module provides at its interface. Deep over shallow.
- **Seam** — where an interface lives; the place behavior can be altered.
- **Adapter** — a concrete thing satisfying an interface at a seam.
- **Leverage** — capability gained per unit of interface learned.
- **Locality** — concentration of change at one place rather than across
  callers.
- **Deletion test** — if you delete the module, does complexity reappear across
  callers?
- **Design it twice** — generate interface alternatives before committing.
- **Dependency classification** — In-process / Local-substitutable / Remote but
  owned / Collaborator-owned / True external / Irreplaceable.
- **Generative core** — the product's durable product-making logic or principle;
  the logic engine may carry it, but does not replace it.
- **Logic engine** — core business logic, decoupled from any access surface.
- **Access surface** — CLI, API, SDK, GUI, document, or workflow surface where
  users or callers first encounter the product.

**Domain**

- **Bounded context** — a part of the system with its own ubiquitous language.
- **Ubiquitous language** — the canonical glossary for a context.
- **Qualifier smell** — a term that needs a qualifier to be unambiguous; signals
  a context split.
- **Context migration** — the procedure for splitting a single-context setup
  into multiple contexts.

**Process**

- **Cycle** — one full pass from elevator pitch to PRD closure.
- **Minimum honest process** — the smallest artifact set that still records
  scope, acceptance criteria, checks, and closure.
- **Focus** — the cycle's current center of attention.
- **Intention** — directional product effect; not itself closeable.
- **Goal** — closeable accomplishment for the cycle or product.
- **Vertical slice** — one thin piece of behavior end-to-end, mergeable alone.
- **Encounter statement** — optional experience-facing statement for how a user
  should meet a feature.
- **Tracer bullet** — first test of a TDD cycle; proves the smallest honest
  behavior through the intended interface or access surface.
- **First contact** — the first test or slice that proves the intended interface
  or access surface can carry the behavior.
- **Deepening** — structural improvement to coherence, leverage, locality, or
  testability.
- **Surface refinement** — polish to finish, wording, UI, docs, logs, or similar
  surfaces without changing core structure.
- **AAR** — structured retrospective at every closure.
- **ADR** — record for hard-to-reverse, surprising, real-trade-off decisions.
- **Flag** — risk signal in a parent artifact about a future sibling.
- **Outward pass** — second step of closure; scan affected artifacts.
- **Pre-activation** — first stage of Phase 6; resolve flags before coding.
- **Reframe** — required `product.md` revision after product identity changes.
- **Feature complete** — cycle decision: feature set complete for now; lifecycle
  indeterminate.

---

## The `context/` Folder

Drop `context/` into any project's root to activate the framework. It is
self-contained — nothing lives outside it that the process depends on.

### Structure

**Single context** (most projects — one product, one domain):

```
context/
  software-product-development-process.md  ← this document
  product.md                    ← pitch, intentions, goals, boundaries, coherence, constraints
  ubiquitous-language.md        ← canonical terms, relationships, example dialogue
  adr/                          ← architectural decisions, flat, sequentially numbered
    INDEX.md                    ← table of every ADR: scope, status, one-line summary
    0001-slug.md
  cycles/
    01-initial/
      pitch.md
      prd.md
      aar.md                    ← written at PRD closure
      issues/
        01-parent-name/
          sub-prd.md            ← product-level intent — user stories, dependencies
          issue.md              ← technical execution — acceptance criteria, Flags
          aar.md                ← written at parent issue closure
          01-sub-issue-name/
            sub-issue.md
            aar.md              ← written at sub-issue closure
          02-sub-issue-name/
            sub-issue.md
            aar.md
    02-feature-name/
      ...
```

**Multi-context** (monorepos with distinct bounded contexts):

When `context/context-map.md` exists, the repo has multiple bounded contexts.
Cycles remain product-level — features span contexts. Language and ADRs are
context-scoped.

```
context/
  software-product-development-process.md
  product.md                        ← overall product, unchanged
  context-map.md                    ← lists contexts and their relationships
  adr/                              ← all decisions, flat — scope recorded inside each ADR
    INDEX.md                        ← table of every ADR: scope, status, one-line summary
    0001-slug.md
  contexts/
    ordering/
      ubiquitous-language.md        ← ordering-specific terms
    billing/
      ubiquitous-language.md
  cycles/
    01-initial/
      ...                           ← same structure as single-context
```

**Inference rule:** if `context/context-map.md` exists → multi-context. If only
`context/ubiquitous-language.md` exists at the root → single context.

### Rules

- **One folder per closeable unit.** A sub-issue, a parent issue, and a cycle
  each get their own folder. When a unit closes, `aar.md` appears inside it. No
  `aar.md` means the unit is still open.
- **Sub-folders are created lazily.** Only
  `context/software-product-development-process.md`, `product.md`, and
  `ubiquitous-language.md` are created upfront. Everything else appears the
  moment it is needed: a cycle folder when its pitch is written, an issue folder
  when its sub-PRD is written, a sub-issue folder when its `sub-issue.md` is
  written, `adr/` and `adr/INDEX.md` with the first ADR, `context-map.md` and
  `contexts/` only when a qualifier smell triggers migration. Do not pre-create
  empty scaffolds — empty folders confuse future readers and lie about state.
- **The sub-PRD and the parent issue are complementary, not sequential.**
  `sub-prd.md` records _product-level intent_ — user stories and dependencies on
  other sub-PRDs. `issue.md` records _technical execution_ — acceptance
  criteria, implementation approach, flags. Both persist for the life of the
  project; neither replaces the other. They live in the same folder because they
  describe the same unit of scope at two levels of abstraction.
- **Once `issue.md` is created, `sub-prd.md` is ingested.** Its product-level
  framing has been translated into a technical execution plan. Add the ingested
  header (template below) to `sub-prd.md` at this point. From this point on,
  ongoing work updates `issue.md`; `sub-prd.md` is only edited if the underlying
  user stories themselves change.
- **`sub-prd.md` loads selectively.** When a parent issue is active, load
  `issue.md` plus its flags. Load `sub-prd.md` only when reasoning about
  user-facing motivation — grilling sessions, scope-drift checks, or when the
  underlying user stories are being revised. The ingested header makes this
  state explicit so a loader knows it can skip the file by default.
- **ADRs are flat. Scope is recorded in the ADR itself.** All architectural
  decisions live in `context/adr/` with sequential numbering. Each ADR declares
  its **scope** (`product`, a single context name, or two context names) and its
  **provenance** (which cycle, parent issue, or sub-issue produced it). An
  `INDEX.md` in the same folder lists every ADR with its scope, status, and a
  one-line summary so context-scoped work can pre-filter without opening every
  file. If a decision would apply to three or more contexts, default its scope
  to `product`.
- **Create an ADR only when all three conditions hold: hard to reverse,
  surprising without context, and the result of a real trade-off.** A decision
  is hard to reverse when changing your mind later carries meaningful cost. It
  is surprising without context when a future reader would wonder why. It is a
  real trade-off when genuine alternatives existed. A decision that fails any
  one of these does not need an ADR — most decisions don't. Example: choosing
  Postgres for the production data store is hard to swap, non-obvious without
  context, and had real alternatives — it qualifies. Deciding to name a function
  `createOrder` instead of `makeOrder` fails all three — it does not.
- **ADRs load in two stages.** For any work that consults ADRs, load
  `context/adr/INDEX.md` first. Fetch full ADRs only for index entries that look
  relevant. For context-scoped work (a sub-issue inside one context), filter the
  index to rows where `Scope = product` or `Scope` contains the current context.
- **`product.md` is the durable product-framing file.** It is updated additively
  on a new feature cycle and reframed after a pivot. Git history is the archive
  for past versions — no internal versioning is needed. A pivot is the strategic
  product event; a reframe is the document operation that revises `product.md`
  before the next cycle begins.
- **`product.md` and `ubiquitous-language.md` have non-overlapping roles.**
  `product.md` describes _what the product does for users_ — pitch, intentions,
  goals, access surface, work boundaries, generative core, coherence signals,
  and constraints. `ubiquitous-language.md` describes _how the system is named
  internally_ — terms, relationships, example dialogue. They never duplicate:
  `product.md` does not define domain terms; the glossary does not pitch the
  product or describe goals. In multi-context repos, the same boundary holds —
  `context-map.md` describes the structural breakdown of contexts, also not a
  glossary, also not a pitch.
- **`ubiquitous-language.md` consolidates what some DDD tooling separates into
  two files.** A "context description" file (what the context is and why it
  exists) and a "glossary" file are common in DDD tooling.
  `software-product-development-process.md` collapses them: `product.md` already
  owns the context-description role in single-context repos, so
  `ubiquitous-language.md` needs only its one-sentence ownership header in
  multi-context repos. The extraction workflow (scanning artifacts for terms)
  and the durability workflow (updating inline as decisions crystallize) are
  both handled by the
  [Domain Validation Procedure](#domain-validation-procedure) — the two separate
  workflows from the two-file model become one in this process.
- **`product.md` and `ubiquitous-language.md` together are the full domain
  context.** Load both when doing high-level work (grilling sessions, PRD
  review, architecture decisions, product-coherence checks). Load only
  `ubiquitous-language.md` during implementation where the glossary is needed
  but the durable product framing is not. In multi-context repos, the equivalent
  is `product.md` + `context-map.md` + the relevant context's
  `ubiquitous-language.md`.
- **`context/` is only fully reliable at closure boundaries.** Between closures
  — mid-implementation — artifacts are working drafts. This is expected, not a
  failure.
- **A qualified term is a migration signal — act on it immediately.** During any
  domain validation pass, if you find yourself writing a definition that
  requires a qualifier to be unambiguous — "Customer (billing)" vs. "Customer
  (ordering)", "Order (placed)" vs. "Order (fulfillment)" — stop. Do not add the
  qualified term. Do not continue with the current phase. The glossary is
  telling you that the same word refers to genuinely different concepts in
  different parts of the system. This is called the **qualifier smell**.

  **How to recognize it.** You are writing a definition and one of these
  happens:
  - You add a parenthetical to disambiguate: "Customer (billing context)".
  - You write an exception into the definition: "Invoice — a request for
    payment, except in fulfillment where it means a packing list."
  - You find yourself thinking "this definition is only true for the [X] part of
    the system."
  - The same term appears with two different definitions anywhere in the
    glossary.

  Any one of these is the signal. If you feel the urge to add a parenthetical
  qualifier, treat that urge as a stop signal, not a formatting decision.
  Qualifier smell is strict by default.

  **Allowed dual meanings.** The same word may have two meanings only when each
  meaning is separated by bounded context. Define the term independently in each
  context glossary, and let the shared spelling be an accidental name collision,
  not a shared definition.

  **Rare unresolved ambiguity.** Intentional unresolved ambiguity is an
  exception for unresolved business/domain ambiguity or deliberately
  interpretive product experiences. It requires an ADR because it is surprising
  without context and future contributors will otherwise try to resolve it. The
  ADR must name why the ambiguity is being preserved, where it is allowed, and
  what signal would force a later resolution.

  **What to do when you see it:**
  1. Stop the current domain validation pass.
  2. Name the boundary: which parts of the system use the term differently?
     Write them down — these are your bounded contexts. Give each a short name
     (e.g. "ordering", "billing", "fulfillment").
  3. Create `context/context-map.md` (see template in
     [Artifact Templates](#artifact-templates)). List the contexts you have
     identified and describe how they relate to each other.
  4. Create `context/contexts/[name]/` for each bounded context.
  5. Move the existing `context/ubiquitous-language.md` into the context where
     most of its current terms belong. For example, if the majority of terms are
     about order placement, move it to
     `context/contexts/ordering/ubiquitous-language.md`.
  6. Create a new `ubiquitous-language.md` for each remaining context. Start it
     empty — terms will be added as the domain validation pass continues.
  7. Take the ambiguous term that triggered the migration and define it cleanly
     in each context's glossary, without qualifiers. Two contexts can use the
     same word with different definitions — that is expected and correct. They
     are different concepts that happen to share a name.

     When one context needs to reference a concept owned by another, it does so
     by identifier — a `CustomerId`, not the full `Customer`. The full
     definition stays inside its owning context; what crosses the boundary is a
     value with no definition attached. Importing the full concept couples the
     contexts: any change to the owning context's definition forces changes in
     every context that imported it.

     Example: the billing context needs to associate an invoice with a customer.
     It records a `CustomerId` — not a `Customer`. The billing context has no
     definition of `Customer`; it does not need one. If the ordering context
     later adds fields to `Customer`, billing is unaffected.

  8. Resume the domain validation pass. Going forward, all terms are resolved in
     the relevant context's glossary, not a shared root file.

  Migrate at the first qualifier. Every additional qualified term accumulated in
  a shared glossary increases the cost of the split. Do it early.

---

## Core Principles

- **Iterative within phases, gated between phases.** You can loop freely inside
  a phase. You do not move to the next phase until the current artifact meets
  its exit criteria.
- **Context over completeness.** Every artifact is sized to fit a focused
  context window. Narrowing context is a first-class concern, not an
  afterthought.
- **Fractal feedback loops.** The same closure pattern repeats at every level:
  after closing a unit of work, scan upward and sideward for drift.
- **Hypothesis over contract.** Plans are starting hypotheses. Reality diverges.
  The AAR is where divergence is documented, not hidden.
- **Artifacts over transcripts.** LLM interviews are disposable. Only decisions
  extracted into artifacts survive. A transcript is not documentation.
- **Existing artifacts first, people second.** Answer from existing code, docs,
  tests, ADRs, cycle artifacts, and product artifacts before asking a developer
  or team. Human attention is scarce and should be reserved for decisions the
  artifacts cannot answer.
- **Minimum honest process.** Collapse layers only when the remaining artifacts
  still preserve scope, acceptance criteria, testing or checking, and closure.
  Small cycles should be lightweight, not vague.
- **Generative core before implementation shape.** Name the durable product
  principle that makes the product itself before deciding how the software
  carries it. The logic engine may embody the generative core, but the two are
  not the same thing.
- **Logic engine first.** The core business logic is built decoupled from any
  access surface — CLI, API, SDK, GUI. The engine works the same regardless of
  how it is consumed. This is a strong default.
- **CLI-first as suggested access surface.** The CLI is the suggested first
  consumer of the logic engine because it is often the simplest honest access
  surface for pressure-testing the engine. It is fast, but speed is not the main
  reason: the CLI proves whether the intended behavior can pass through a clean
  interface before heavier surface investment. The first access surface is a
  product-level decision recorded in `product.md`; CLI is the default unless
  market-fit or product form demands otherwise. When choosing a different
  surface, record the reason briefly in `product.md` — what constraint made CLI
  the wrong starting point. Example: "API-first — the product is consumed
  exclusively by third-party integrators; a CLI has no users."
- **Qualifier smell triggers immediate migration.** When a domain term needs a
  qualifier to be unambiguous ("Customer (billing)" vs. "Customer (ordering)"),
  the smell is the signal of a bounded context boundary. Stop the current work,
  run the context migration procedure (see
  [`context/` folder Rules](#the-context-folder)), then resume. The smell is
  actionable in any phase — PRD, sub-PRD, implementation. Do not accumulate
  qualified terms. Preserve unresolved ambiguity only as a rare ADR-documented
  exception.
- **Interface before tests.** Design the module's public interface before
  writing the first test. Tests are written against the interface, not against
  an imagined implementation.
- **Deep modules over shallow modules.** Prefer a small interface behind which
  large behavior is hidden. The deletion test is the check: if you delete the
  module and complexity reappears across callers, the module was earning its
  keep.
- **The interface is the test surface.** Callers and tests cross the same seam.
  Tests written against the interface survive internal refactors; tests that
  reach past the interface break on refactors that change nothing observable.
  This is why design-it-twice, the deletion test, and replace-don't-layer all
  point the same direction.
- **One adapter is a hypothetical seam. Two adapters is a real one.** Do not
  introduce a port unless at least two adapters are justified — typically a
  production adapter and a test adapter. A single-adapter seam is indirection
  without a real seam.
- **Vertical slices over horizontal layers.** Each unit of implementation
  delivers one thin piece of behavior end-to-end. Never build all of one layer
  before moving to the next.
- **TDD, one test at a time.** Tracer bullet first, then one test per cycle.
  Tests describe behavior through the public interface, never implementation
  details.
- **Flags over edits.** When a closure surfaces a risk for a future artifact,
  write a flag in the parent. Never edit the sibling directly.

---

## Minimum Honest Process

Use the smallest process that remains honest about scope and closure. Small
cycles may collapse layers when separate artifacts would add ceremony without
adding decisions, but they must not hide missing thinking.

The minimum honest artifact set records:

1. **Scope** — what is in and out for this cycle or slice.
2. **Acceptance criteria** — what must be true before the work can close.
3. **Testing or checking** — how the work is verified. In software this is
   usually tests; in documentation or process work it may be assembly checks,
   manuscript review, link checks, or another explicit review surface.
4. **Closure** — an AAR or equivalent closure note that records what changed,
   what diverged from the plan, and what carries forward.

Minimum honest process is not permission to skip discipline. It is permission to
avoid artifact theater when one artifact can honestly do the work of several. If
a collapsed artifact can no longer answer scope, acceptance, checking, and
closure questions, split the layer back out.

For small documentation or process-deepening cycles, a cycle pitch, PRD,
affected source-note edits, assembly or review check, and PRD AAR may be enough.
For larger software work, keep the full pitch → PRD → sub-PRD → parent issue →
sub-issue structure unless the scope is plainly too small to justify it.

---

## The Process

### Process Flows

This process has two entry points.

#### Flow A — Feature development

The standard flow. Use when building something new. Start at Phase 1.

```
Phase 1 (Pitch) → Phase 2 (PRD) → Phase 3 (Sub-PRDs) → Phase 4 (Parent Issues)
→ Phase 5 (Sub-Issues) → Phase 6 (Implementation) → Closure
```

When the cycle is too small for every layer to add value, apply
[Minimum Honest Process](#minimum-honest-process). The collapsed path must still
record scope, acceptance criteria, testing or checking, and closure. If any of
those become implicit, return to the full flow.

---

#### Flow B — Refactor exploration

A refactor is a PRD cycle. Follow Flow A. The pitch describes architectural
friction rather than a user-facing feature. See the refactor notes in
[Phase 1](#phase-1-elevator-pitch) and [Phase 2](#phase-2-high-level-prd) for
how the standard sections adapt.

Flow B is for refactors that span multiple parent issues, restructure
cross-cutting concerns, or contradict an existing ADR. Smaller refactors that
surface during Stage 4 deepening of an active sub-issue are handled inline
within that stage — see the inline refactor criteria in
[Phase 6, Stage 4](#stage-4-deepen).

**Before writing the pitch:** Explore the codebase without a fixed goal. Note
where you experience friction:

- Where understanding one concept requires bouncing between many small modules.
- Where interfaces are nearly as complex as their implementations (shallow
  modules).
- Where tests break on refactors that don't change behavior.
- Where parts of the codebase are untested or hard to test through their current
  interface.

Apply the deletion test to each area of friction. This exploration plays the
same role a user interview plays in Flow A — it is the research that makes the
pitch concrete.

If `context/` does not exist on the repo, do not stop to set it up before
exploring. Proceed with codebase exploration. Create artifacts lazily as
decisions crystallize during the cycle, in the order the process specifies. Flow
B is the most likely entry point for adopting this framework on an existing
codebase, and a halt to scaffold the framework would block the work the
developer actually came for.

After exploring, generate a numbered candidate list before writing any pitch.
For each candidate: (a) affected artifacts, (b) friction — why this causes pain
today, stated concretely, (c) proposed change, (d) expected gain in **locality**
and **leverage**, (e) test improvement — how tests at the deepened interface
would be better than current tests. Use the same format as
[Phase 6 Stage 4](#stage-4-deepen). Present the list and ask the user which
candidate to pursue. The pitch is then written for the chosen candidate.

**ADR conflicts in the candidate list.** When generating candidates, surface a
candidate that contradicts an existing ADR only when the friction warrants
revisiting it. Mark such candidates explicitly:
`contradicts ADR-NNNN — worth revisiting because [reason]`. Do not list every
theoretical refactor an existing ADR forbids.

---

### Phase 1 — Elevator Pitch

**Purpose:** Articulate the core problem, who has it, why existing solutions
fall short, what makes this product distinct, and what form or access surface
carries it. This is the root context for everything that follows.

**Required content:**

1. The core problem — one sentence.
2. Who has the problem.
3. Why existing solutions fall short.
4. The product's distinction — what makes this product unlike alternatives.
5. The form or access surface — how users or callers first encounter it.

**Exit criteria:**

- [ ] The core problem is stated in one sentence.
- [ ] The target user is identified.
- [ ] The gap in existing solutions is named.
- [ ] The distinction is named without collapsing into implementation detail.
- [ ] The form or access surface is named.
- [ ] Someone unfamiliar with the idea could understand the _why_ behind the
      product from this pitch alone.

> **Refactor cycles:** "Someone unfamiliar" means a future maintainer
> encountering this change in git history. The pitch explains why the
> architecture had to change — in terms a technical reader can evaluate without
> knowing the original codebase. The fourth exit criterion still applies.

**Where it lives:** `context/cycles/XX-name/pitch.md`

---

### Phase 2 — High-Level PRD

**Purpose:** Define _what_ the product does and _for whom_, without specifying
_how_. Expand the elevator pitch into a structured artifact that can be
decomposed. Separate directional product effect from closeable cycle
accomplishments.

**Required sections:**

1. **Focus** — one short statement naming this cycle's current center of
   attention.
2. **Intentions** — a numbered list of directional product effects. Intentions
   describe the change you want in the product or user's world; they are not
   themselves closeable.
3. **Goals** — a numbered list of closeable accomplishments. Goals define what
   will be true when this cycle is done.
4. **Non-goals** — a numbered list of what is explicitly out of scope.
5. **User stories** — a numbered list. Each with a clear actor, action, and
   outcome. For refactor cycles, the actor is a maintainer or future developer:
   "As a maintainer, I want [architectural property] so that [consequence for
   future work]."
6. **Encounter statements** — optional for user-facing or experience-critical
   work. Use them to state how the feature should be encountered, felt, or
   understood through the access surface. User stories remain the default
   software format; encounter statements supplement them, not replace them.
7. **Constraints and assumptions** — a numbered list of known limits and things
   taken as true.
8. **Success metrics** — a numbered list of how you will know the product is
   working. For refactor cycles, success metrics are architectural compliance
   checks — binary conditions a test suite can verify. Example: "The full test
   suite for the logic engine runs without instantiating any access surface."
9. **Success signals** — optional qualitative signals that would indicate the
   cycle is working but are not cleanly measurable.
10. **Open questions** — a numbered list. Each classified as either:

- `MUST RESOLVE` — cannot build without an answer.
- `RESOLVE THROUGH IMPLEMENTATION` — unknowable until something is built.

**Domain validation pass** — Before checking exit criteria, run the
[Domain Validation Procedure](#domain-validation-procedure) (defined below,
before the Closure Procedure) against this PRD. The artifact under review is the
PRD; walk Focus, Intentions, Goals, Non-goals, User stories, and optional
Encounter statements. The exit criteria below cannot be checked until the
procedure's exit condition is met for every term used in the PRD.

**Exit criteria:**

- [ ] Focus is narrow enough to guide decomposition.
- [ ] Intentions describe directional product effect and are not treated as
      closeable completion criteria.
- [ ] Goals and non-goals are clear enough to reject an out-of-scope feature
      proposal.
- [ ] Goals are closeable accomplishments.
- [ ] Every user story has an identifiable actor and outcome.
- [ ] Encounter statements, when present, are tied to an access surface and do
      not replace acceptance criteria or tests.
- [ ] All open questions are classified.
- [ ] Every domain term in the PRD is defined in the relevant
      `ubiquitous-language.md`.

**Where it lives:** `context/cycles/XX-name/prd.md`

---

### Phase 3 — Sub-PRDs

**Purpose:** Break the PRD into focused context units. Each sub-PRD is a group
of related user stories that can be reasoned about in isolation, without
cross-referencing other sub-PRDs.

**Grouping principle:** Stories that share the same domain context — same data,
same user flow, or same system boundary — belong together. The test: if you
handed only this sub-PRD to an AI with no other context, would it have
everything it needs to reason about those stories?

**Soft cap:** 5 user stories per sub-PRD. This is a recommendation, not a law.
The grouping test above is the real decision rule — if a sub-PRD passes the test
with 5, that is fine; if it fails with 2, split. The soft cap exists as a
context-window guardrail: a sub-PRD plus its supporting context (glossary,
parent decomposition, dependencies) must fit in a focused window at activation
time. If it does not at 5, split before reaching the cap. If a developer has a
specific reason to override — for example, a tightly-coupled set of stories that
genuinely belong together — they may, provided the sub-PRD still fits in a
focused context window.

**Required content per sub-PRD:**

1. The user stories it contains.
2. Any encounter statements from the PRD that materially affect this scope.
3. Its dependencies on other sub-PRDs — explicit and directional (A → B).

**Dependency rule:** A dependency means this sub-PRD assumes something another
produces — a data model, a behavior, an interface. Dependencies are strict
blockers. A sub-PRD does not move to execution until all its dependencies are
closed.

**Domain validation pass** — Run the
[Domain Validation Procedure](#domain-validation-procedure) against each
sub-PRD's user stories. Any new terms introduced during decomposition must be
resolved before the sub-PRD closes.

**Exit criteria:**

- [ ] All dependencies are identified, directional, and sequenced.
- [ ] Each story has a clear actor, action, and outcome.
- [ ] Any encounter statements are preserved only where they affect product or
      acceptance decisions.
- [ ] The sub-PRD is narrow enough to reason about entirely within a single
      focused context window.
- [ ] Any new domain terms introduced are defined in the relevant
      `ubiquitous-language.md`.

**Where it lives:** `context/cycles/XX-name/issues/XX-parent-name/sub-prd.md`

---

### Phase 4 — Parent Issues

**Purpose:** Translate each sub-PRD's product-level intent into a trackable
technical unit of work. The parent issue is the technical counterpart of the
sub-PRD — it does not replace it. Both persist for the life of the project.

**What a parent issue adds over the sub-PRD:**

1. **Acceptance criteria** — specific, testable conditions that define "done"
   for the whole issue.
2. **Dependency links** — the dependency map as explicit issue references.
3. **Implementation approach constraint** — the architectural defaults that
   apply to this issue.
4. **Flags section** — cross-sibling signals written by prior closures, reviewed
   before activating any sub-issue.

**Structure:**

- `sub-prd.md` and `issue.md` live in the same folder. They are complementary
  artifacts describing the same scope at different levels of abstraction —
  `sub-prd.md` is product-level (user stories, dependencies); `issue.md` is
  technical (acceptance criteria, flags, implementation approach). Both persist;
  neither replaces the other.
- When `issue.md` is created, add the ingested header (template below) to
  `sub-prd.md` to mark its lifecycle state and instruct future loaders.
- Each sub-issue gets its own subfolder inside the parent issue folder.

**Ingested header for `sub-prd.md` (added when `issue.md` is created):**

> Translated to `issue.md`. This sub-PRD records the product-level intent — user
> stories and dependencies. Update `issue.md` for ongoing technical work. Update
> this file only if the underlying user stories themselves change.

**Sequencing:** Plan and execute parent issues in dependency order. Plan the
next parent issue only after the previous one is closed, incorporating what its
AAR reveals. Do not plan all parent issues before executing any — earlier AARs
change later plans.

**Where it lives:** `context/cycles/XX-name/issues/XX-parent-name/issue.md`

---

### Phase 5 — Sub-Issues

**Purpose:** Break each parent issue into mergeable vertical slices of
implementation work.

**What makes a good sub-issue:**

- It is a vertical slice — touches every layer needed to deliver one thin piece
  of behavior end-to-end.
- It is mergeable on its own — after merging, the codebase is in a valid,
  working state, even if the feature is not complete.
- It takes no more than one day to implement.

**Required content:**

1. **Description** — what behavior this slice delivers.
2. **Dependency classification** — Before designing the interface, classify each
   dependency this module relies on. The category determines the testing
   strategy for this slice:
   - **In-process** — pure computation or in-memory state, no I/O. Test directly
     through the interface; no adapter needed.
   - **Local-substitutable** — has a local test stand-in (PGLite, in-memory
     filesystem). Test with the stand-in running in the test suite; no port at
     the module's external interface.
   - **Remote but owned** — your own services across a network boundary. Define
     a **port** (interface) at the seam; inject an HTTP adapter for production
     and an in-memory adapter for testing.
   - **Collaborator-owned** — controlled by another person or team inside your
     collaboration boundary, but not by this slice's implementer. Treat the seam
     as a contract: prefer contract tests, documented test fixtures, or a stable
     local adapter agreed with the collaborator.
   - **True external** — third-party services you don't control (Stripe, Twilio,
     etc.). Inject as a port; tests provide a mock adapter.
   - **Irreplaceable** — a dependency whose real behavior is part of product
     truth and cannot be honestly substituted by a fake without changing what is
     being verified. Use the real dependency in a narrow characterization,
     contract, or acceptance check, and keep unit tests focused around stable
     seams where substitution remains honest.

   Record the classification for each dependency in the sub-issue.

3. **Interface design** — what callers must know to use this module: entry
   points, inputs, outputs, error modes. This is the surface the tests are
   written against. Keep it small and constrained — not a full technical spec.

   Apply **design it twice**: generate at least two alternatives with
   meaningfully different shapes before committing. Minimum contrasts:
   - **Minimal surface** — fewest possible entry points, maximum **leverage**
     per call. Callers learn less; each call does more.
   - **Common caller** — shaped around the most frequent use case. Friction at
     the call site is as low as possible.
   - **Strongest intended encounter** — optional for experience-heavy
     user-facing work. Shape the interface around the encounter the user most
     needs to have through the access surface.

   Compare on **leverage** (capability per unit of interface learned),
   **locality** (where change will concentrate), and **testability** — which
   design makes the acceptance criteria in item 4 verifiable through the
   interface alone, without requiring tests to reach past the seam. Record the
   chosen design and the rejected alternative with a one-sentence reason. If
   both required alternatives collapse to the same shape, that shape is probably
   right.

   **On flexibility.** The default contrast deliberately omits a "maximize
   flexibility" alternative — designed-in flexibility tends to grow surface area
   without adding leverage. If you want to explore a flexibility- maximizing
   design explicitly, spawn it as an additional constraint in the opt-in
   parallel sub-agent path below. It is an opt-in choice, not a default.

   > **Opt-in: parallel sub-agent design.** This path is always opt-in by
   > judgment, never by default. Consider triggering it when **all** of these
   > hold: (a) the chosen design will be hard to revise after tests are written
   > — for example, the interface sits at a seam many callers will lock in, or
   > tests at this seam will be the most expensive to redo; (b) the dependency
   > classification includes a **Remote but owned** or **True external**
   > dependency, _or_ the in-process module is genuinely tricky and a third
   > shape would meaningfully break the binary; (c) the budget is justified by
   > the stakes — this strategy is expensive, and a tricky in-process module
   > with no external deps can still earn it.
   >
   > Default to the two-alternative pair above. Reach for parallel sub-agents
   > deliberately, with a stated reason recorded in the sub-issue.
   >
   > **Step 1 — Frame the problem space.** Before spawning agents, write a
   > user-facing explanation: (1) the constraints any new interface must
   > satisfy, (2) the dependency category for this candidate and what it means
   > for testing, (3) a rough code sketch to make the constraints concrete — not
   > a proposal, just a way to ground them. Show this to the user, then
   > immediately proceed to Step 2. The user reads while the agents work.
   >
   > **Step 2 — Spawn sub-agents.** Spawn sub-agents in parallel. Each agent
   > must work with an independent context — no agent sees another's output
   > before producing its own. This independence is the forcing function:
   > designs produced in the same context window converge on the first idea;
   > designs produced in separate contexts diverge and expose genuine
   > trade-offs.
   >
   > Always include: **(1) minimize entry points** and **(3) optimize for the
   > common caller**. Add the following only when they apply:
   >
   > - **(2) maximize flexibility** — explicit opt-in. Designed-in flexibility
   >   tends to grow surface area without adding leverage; add this agent only
   >   when the developer or team judges a flexibility-maximizing shape worth
   >   exploring.
   > - **(4) design around ports and adapters for cross-seam dependencies** —
   >   required when the dependency classification includes **Remote but
   >   owned**, **Collaborator-owned**, **True external**, or **Irreplaceable**;
   >   opt-in otherwise.
   >
   > Each agent produces: (a) the interface — entry points, inputs, outputs,
   > invariants, error modes; (b) a usage example showing how callers use it;
   > (c) what the implementation hides behind the seam; (d) the dependency
   > strategy — which adapters are needed for production and for testing; (e)
   > trade-offs — where leverage is high, where it's thin.
   >
   > **Step 3 — Compare and recommend.** Present designs sequentially so the
   > user can absorb each one, then compare in prose — contrast by depth
   > (leverage at the interface), locality (where change concentrates), and seam
   > placement. Then give an opinionated recommendation: which design is
   > strongest and why. If elements from different designs combine well, propose
   > a hybrid. A balanced menu with no recommendation is the wrong output.

   **Seam discipline check:** Before introducing a port (an interface for an
   injected dependency), confirm you have at least two justified adapters —
   typically production and test. A single-adapter seam is indirection without a
   real seam. If you only have one adapter, fold the dependency into the
   implementation rather than defining a port. Also confirm something external
   actually varies across this seam — if only internal implementation parts
   vary, the seam is internal and belongs inside the implementation, not in the
   public interface. Don't promote an internal seam to a port just to make it
   easier to test; that pushes an internal design choice into the public
   interface.

4. **Acceptance criteria** — specific, testable conditions for this slice,
   written against the designed interface.
5. **Proposed tests** — a list of candidate tests, each with a title and a brief
   description of what behavior it verifies. This list is a prioritized
   selection, not an exhaustive inventory: focus on critical paths and complex
   logic. You cannot test everything — the proposed tests should reflect which
   behaviors matter most, not every possible edge case.
6. **Affected artifacts** — code, docs, schemas, config, fixtures, generated
   artifacts, release surfaces, or other files this sub-issue touches or
   creates.
7. **Dependencies** — other sub-issues this one depends on.

The interface design, proposed tests, and affected artifacts are a **starting
hypothesis**, not a contract. They force upfront reasoning about scope. Reality
will diverge — document that divergence in the AAR.

**Where it lives:**
`context/cycles/XX-name/issues/XX-parent-name/XX-sub-issue-name/sub-issue.md`

---

### Phase 6 — Implementation (TDD)

**Purpose:** Build the sub-issue slice using test-driven development.

**Testing boundaries** — Mock only at system boundaries:

- External APIs (payment, email, SMS, analytics)
- Databases, when no local stand-in exists — prefer a test database over a mock
- Time and randomness
- Filesystem, when no in-memory alternative exists

Never mock your own modules, internal collaborators, or anything you control. If
you find yourself mocking your own code, the module boundaries are wrong — fix
the design, not the test.

Pass external dependencies in rather than instantiating them inside the module
(dependency injection). Prefer SDK-style interfaces — one specific function per
external operation — over generic fetchers with conditional logic. Each
operation should be independently mockable with a single return value, no
conditions.

**If the qualifier smell emerges during any implementation stage** — a domain
term in code requires a qualifier to be unambiguous — stop. Do not use a
qualified term in code. Run the context migration procedure (see
[`context/` folder Rules](#the-context-folder)). Resume implementation after the
migration is complete.

---

#### Stage 1 — Pre-activation

Before writing any code:

1. Read the parent issue (`issue.md`).
2. Read `context/ubiquitous-language.md` (or the relevant context's glossary in
   multi-context repos). Confirm you can name every concept in this sub-issue
   using canonical terms before writing any code.
3. Find all unchecked flags in the Flags section that target this sub-issue.
4. Resolve each flag: confirm the artifact is still valid, or update it. Check
   the box with a one-line resolution note.
5. You cannot proceed with an open flag against this sub-issue.
6. **Confirm the interface.** Re-read the interface design recorded in
   `sub-issue.md`. If AI authored the sub-issue, the developer reviews and
   approves the interface before Stage 2 begins. The first test will be written
   against this interface — material changes after Stage 2 require revising
   `sub-issue.md`, not improvising during implementation. The cost of pausing to
   confirm here is one minute; the cost of discovering the interface is wrong
   after writing five tests is far higher.

---

#### Stage 2 — Tracer bullet

1. Write one test that proves the smallest honest behavior through the intended
   interface or access surface. It must fail.
2. Write the minimum implementation to make it pass.
3. The tracer bullet is complete when it passes for the right reason — the code
   works, not a misconfigured environment.

This is the **First Contact** check: the first slice should prove that the
intended caller or user can actually encounter the behavior through the surface
chosen for the slice. For a logic-engine slice, that surface is the module
interface. For a CLI, API, SDK, GUI, or documentation feature, it is the access
surface named by the acceptance criteria.

Do not write more than one test before passing it.

---

#### Stage 3 — Incremental loop

Work through the candidate test list one test at a time:

1. Write the next test. It must fail.
2. Write the minimum implementation to make it pass.
3. Let the implementation inform whether the next candidate test still makes
   sense, needs revision, or a new test is needed first.

Rules:

- One test at a time. Never write all tests before implementing.
- Tests describe behavior through the public interface, not implementation
  details. A test that breaks when you refactor but behavior hasn't changed is
  testing the wrong thing.
- Reorder, add, or drop candidate tests as the code informs you.

**Anti-pattern: horizontal slices.** Do not write all tests first, then all
implementation. This is "horizontal slicing" — treating Stage 2 as "write all
tests" and Stage 3 as "write all code." It produces unreliable tests: tests
written in bulk verify imagined behavior, not actual behavior. They end up
testing the _shape_ of things — data structures, function signatures — rather
than user-facing behavior. They become insensitive to real changes: passing when
behavior breaks, failing when behavior is fine. You outrun your headlights,
committing to test structure before understanding the implementation.

```
Wrong (horizontal):
  RED:   test1, test2, test3, test4, test5
  GREEN: impl1, impl2, impl3, impl4, impl5

Right (vertical):
  RED→GREEN: test1→impl1
  RED→GREEN: test2→impl2
  RED→GREEN: test3→impl3
  ...
```

Each test responds to what the previous implementation revealed. Because you
just wrote the code, you know exactly what behavior matters and how to verify
it.

**Per-test checklist.** Before moving on from any test in this stage, confirm:

- [ ] The test describes behavior, not implementation.
- [ ] The test uses the public interface only.
- [ ] The test would survive an internal refactor that preserves behavior.
- [ ] The code written is the minimum needed for this test.
- [ ] No speculative features have been added in anticipation of future tests.

Simple cleanup — extracting duplication, renaming for clarity — happens inline
during Stage 3, not here. Stage 4 is exclusively for deepening: changing the
shape of interfaces to concentrate complexity.

---

#### Stage 4 — Deepen

Once all tests pass, distinguish **deepening** from **surface refinement**
before changing anything.

Deepening changes structure, coherence, leverage, locality, or testability. It
changes where responsibility lives or which seam callers and tests cross.
Surface refinement improves finish, wording, UI polish, docs, logs, names, or
similar surfaces without changing core structure. Surface refinement is useful,
but it must not compensate for unresolved core structure.

Then:

1. **Generate candidates.** Apply the deletion test to every module built in
   this slice. Also scan laterally: does this slice reveal friction in an
   adjacent module that was previously below the threshold? For each deepening
   candidate, note: (a) affected artifacts, (b) friction — why this is causing
   pain today, stated concretely, (c) proposed change, (d) expected gain in
   **locality** and **leverage**, (e) test improvement — how tests at the
   deepened interface would be better than current tests.

2. **Grilling loop.** Pick the highest-leverage candidate. This is a relentless
   interview about every aspect of the candidate — walk down each branch of the
   design tree until a shared understanding is reached, resolving constraints
   one at a time — one question, then wait for the answer before moving to the
   next:
   - Re-verify the dependency classification for this candidate. The Phase 5
     classification was a hypothesis — implementation may have revealed
     different dependencies. A changed classification changes the testing
     strategy.
   - What sits behind the seam?
   - Apply **design it twice** to the deepened interface.
   - If the grilling session names the deepened module after a concept not yet
     in `ubiquitous-language.md`, add the term now — don't defer to the outward
     pass. If a fuzzy term sharpens during the conversation, update the glossary
     right there.
   - **Rejected candidate with a load-bearing reason?** Write the ADR
     immediately — the reasoning is sharpest in the moment. Record why this
     approach was considered and why it was rejected. Skip ephemeral reasons
     ("not worth it right now") and self-evident ones; only write it when a
     future explorer would otherwise re-suggest the same thing and arrive at the
     same rejection without knowing why.
   - **Testing strategy: replace, don't layer.** Old tests on shallow modules
     become waste once tests at the deepened interface exist. Delete them — do
     not port them. A ported test describes the old implementation in new
     clothes. Write fresh tests at the deepened interface that describe
     behavior, not structure.
   - Run the full test suite after each change.

   Surface refinement can happen after deepening candidates are resolved or
   explicitly deferred. Keep it proportional and do not use polish to hide a
   weak seam, shallow module, unclear acceptance criterion, or unresolved
   glossary ambiguity.

3. **Inline refactor criteria.** A deepening change is handled inline within
   this Stage 4 — now, in this sub-issue — when **all** of these hold:
   - Contained within this sub-issue's files plus immediately adjacent modules.
   - Does not require revisiting a closed sub-issue.
   - Does not contradict an existing ADR.
   - The full test suite stays green at every step.

   If any condition fails, do not handle it inline. Write a flag in the parent
   issue describing the deepening opportunity. Flags that span multiple parent
   issues, restructure cross-cutting concerns, or contradict an existing ADR are
   candidates for a dedicated refactor cycle
   ([Flow B](#flow-b-refactor-exploration)). Review all such flags when the
   parent issue closes.

4. **Repeat** for remaining candidates, highest leverage first. Stop when the
   inline criteria stop being satisfied — write a flag instead.

5. If a deepening opportunity contradicts an existing ADR, surface it
   explicitly: "This contradicts ADR-XXXX — worth reopening because [reason]."
   Do not silently override it. By the inline criteria above, this also routes
   the work out of inline and into a flag.

Never refactor while a test is failing.

**Architecture defaults:**

- Build the logic engine first, decoupled from any access surface.
- Build the simplest honest access surface chosen in `product.md` as the first
  consumer of the logic engine. CLI is the suggested default when it can
  pressure-test the engine without misrepresenting the product form.

---

### Domain Validation Procedure

This procedure is invoked from Phase 2 (PRD), Phase 3 (Sub-PRDs), and any moment
in any later phase where new domain terms enter the conversation (grilling
sessions, deepening loops, sub-issue authoring). It is the standard way to
challenge a body of text or code against the relevant `ubiquitous-language.md`.
The structure is the same at every level; only the artifact under review
changes.

**Existing artifacts first, people second.** During any grilling pass, answer
from existing code, docs, tests, ADRs, cycle artifacts, product artifacts, and
repository state before asking a developer or team. Only ask when the answer
cannot be derived from existing artifacts. Human attention is scarce — questions
are budget-intensive and should be reserved for things only people can answer.

#### Steps

1. Read the existing `ubiquitous-language.md`. For each term already defined,
   check whether the artifact under review uses it consistently with that
   definition. If not, call it out before introducing any new terms: "The
   glossary defines [term] as X, but you've used it here to mean Y — which is
   right?"
2. Walk through the artifact. Extract every domain noun, verb, and concept used.
3. For each term not in `ubiquitous-language.md`: add it with a canonical
   definition and aliases to avoid, or replace it with an existing canonical
   term. When multiple words exist for the same concept, pick one and commit —
   list the others as aliases to avoid. Do not leave synonyms in active use: if
   "Order" is the canonical term, "Purchase" belongs under aliases to avoid, not
   alongside it. A definition is one sentence maximum; state what the term IS,
   not what it does — "Invoice: a request for payment" not "Invoice: represents
   a billing event and triggers the payment flow." Do not couple the glossary to
   implementation details — only include terms meaningful to a domain expert.
   Module names, class names, and general programming concepts do not belong
   unless they carry domain-specific meaning. The failure mode is a glossary
   that documents the code rather than the domain.
4. For each term used ambiguously: call it out and propose a canonical term — do
   not just present options and wait. "You're saying 'account' — do you mean the
   **Customer** or the **User**? Those are different things. I'd use
   **Customer** here." The user confirms, corrects, or proposes a different
   name.
5. Ask one question at a time. Do not batch resolutions.
6. Update the relevant `ubiquitous-language.md` as each term is resolved — not
   at the end. Place each term in the cluster it belongs to — lifecycle, actor,
   or concept. If no existing cluster fits, start a new one with a name that
   reflects what the terms share. If all terms belong to a single cohesive area,
   one table is fine. Example: Customer and User are actors; Order and Invoice
   are lifecycle terms — placing them in separate tables keeps each cluster
   scannable and makes relationships within a cluster visible. In single-context
   repos this is `context/ubiquitous-language.md`; in multi-context repos it is
   `context/contexts/[name]/ubiquitous-language.md` for the context the artifact
   primarily lives in.
7. **Stress-test with boundary scenarios.** Construct 2–3 concrete edge cases
   that probe relationships between the resolved terms — what happens at the
   limit, what happens when two terms collide, what happens with the empty case,
   what happens when a single entity sits between two terms. Walk through each
   scenario using the names you have settled on. If a scenario surfaces an
   undefined or ambiguous term, return to step 3.
8. **Verify against existing code.** Where code already exists for any term in
   the artifact, check whether the code agrees with the glossary definition. A
   named module, function, or type that disagrees with its glossary definition
   is itself a problem to resolve — either the definition is wrong or the code
   is wrong. Note discrepancies and resolve before proceeding. For greenfield
   work this step is a no-op.
9. After resolving all terms, scan for the **qualifier smell**: did any term
   require a qualifier to be unambiguous ("Customer (billing)" vs. "Customer
   (ordering)")? If yes, do not proceed. Run the context migration procedure in
   the `context/` folder Rules section first. Dual meanings are acceptable only
   after they are separated by bounded context. Intentional unresolved ambiguity
   is a rare ADR-documented exception for unresolved business/domain ambiguity
   or deliberately interpretive product experiences.
10. Update the example dialogue in `ubiquitous-language.md` to demonstrate how
    newly resolved terms interact with existing ones. Write 3–5 exchanges —
    enough to show terms in natural use and clarify at least one boundary that
    is non-obvious from the definitions alone. Fewer than three exchanges rarely
    surface a real boundary; more than five starts describing implementation.

    > **Dev:** "When does an Invoice get created?" **Domain expert:** "When the
    > customer confirms an Order — not before. We don't invoice until there's a
    > confirmed Order."
    >
    > **Dev:** "One Invoice per Order?" **Domain expert:** "Always. The Invoice
    > is how we tell the customer what they owe for that Order."
    >
    > **Dev:** "What if the customer cancels after the Invoice is issued?"
    > **Domain expert:** "The Order is cancelled. The Invoice is not — it stays
    > as a record of what was owed."
    >
    > **Dev:** "So how does the customer know they don't owe anything?" **Domain
    > expert:** "We issue a credit note against the Invoice. That zeroes it out.
    > The Invoice and the credit note are both permanent records."
    >
    > **Dev:** "Does the Order track the Invoice?" **Domain expert:** "No. The
    > Invoice references the Order. The Order doesn't know about the Invoice."

    The third exchange is where the non-obvious boundary appears: a cancelled
    Order does not cancel its Invoice. The fourth surfaces a new term — credit
    note — that now belongs in the glossary. The fifth fixes a dependency
    direction that definitions alone would leave ambiguous.

#### Exit condition

The artifact passes domain validation when every term used in it exists in the
relevant glossary with an unambiguous, qualifier-free definition or an explicit
bounded-context separation, no unauthorized unresolved ambiguity remains, and no
discrepancy remains between code and glossary for terms already implemented.

---

### Closure Procedure

This procedure is invoked at the end of every phase that closes a unit of work.
The structure is the same at every level; only the nouns and the AAR depth
change. The AAR template scales with closure level — sub-issue AARs are short,
parent issue AARs synthesize across sub-issues, PRD AARs are the full
retrospective and the only place the cycle decision is recorded. See the AAR
template in Artifact Templates.

**Parameters by level:**

| Parameter | Sub-issue                           | Parent issue                          | PRD          |
| --------- | ----------------------------------- | ------------------------------------- | ------------ |
| Siblings  | Other sub-issues in the same parent | Other parent issues in the same cycle | —            |
| Parent    | Parent issue                        | Cycle (PRD + pitch)                   | `product.md` |
| Upstream  | Sub-issues that depend on this one  | Parent issues that depend on this one | —            |

#### Step 1 — Inward pass

Close the unit:

- Record any ADRs made during this unit's execution. For each new ADR, also add
  its row to `context/adr/INDEX.md`. If this unit superseded or deprecated an
  existing ADR, update its status field and the corresponding index row. ADRs
  are authored here — the AAR's "ADRs made" field is a reference list pointing
  back to these entries, not the place where ADR content is written. Include the
  title alongside the number for context. Example: the AAR records "ADRs made:
  ADR-0003: Event-sourced order write model" — not the decision text itself.
- Write the AAR.
- Update inline and technical docs to reflect what this unit changed.
- Mark the unit as closed.

#### Step 2 — Outward pass

For every artifact that referenced what this unit changed:

| Artifact state                         | Action                                                        |
| -------------------------------------- | ------------------------------------------------------------- |
| **Active** — currently being worked on | Update it now.                                                |
| **Future** — not yet started           | Write a flag in its parent. Do not edit the sibling directly. |
| **Closed** — already done              | Note the divergence in this unit's AAR. Do not reopen.        |

#### Step 3 — Outward pass checklist

**Siblings:**

- [ ] Does any sibling assume something my AAR changed?
- [ ] If yes: is it active (update), future (flag in parent), or closed (note in
      AAR)?

**Parent:**

- [ ] Do my changes still satisfy the parent's acceptance criteria?
- [ ] Did scope expand or shrink — does the parent need amending?
- [ ] Are there new open questions to add to the parent's context?

**Upstream:**

- [ ] Did I change any interface, data model, or behavior that a dependent unit
      relies on?
- [ ] If yes: is that unit active, future, or closed?

**Ubiquitous language:**

- [ ] Did any term's meaning evolve during this unit's execution — even
      informally?
- [ ] If yes: update `ubiquitous-language.md` now. If the example dialogue no
      longer demonstrates the term correctly, update it too.

**Product coherence:**

- [ ] Did this unit change the product's problem, user, gap, distinction, form,
      intentions, work boundaries, generative core, coherence signals, or
      constraints?
- [ ] If yes: update active product artifacts now, write flags for future work,
      or record the divergence in this AAR according to the artifact-state
      table.

---

### Flags

A flag is written in the parent artifact when a closure surfaces a risk for a
future sibling. It is never written directly into the sibling.

**Format:**

```
## Flags

- [ ] [source → target]

  Description of what changed and why the target's assumptions may no longer
  hold. Long enough that the activator does not need to read the source AAR to
  understand the concern.

  Files to review:
  - context/cycles/.../target/sub-issue.md
  - src/relevant/file.ts

  (See source AAR for full context)
```

**Lifecycle:**

- Written at closure, in the parent artifact's Flags section.
- Reviewed at pre-activation (Stage 1 of Phase 6).
- Resolved by checking the box with a one-line note: "confirmed valid" or brief
  description of what was updated.
- A flag blocks the activation of its named target only. It does not block any
  other sibling.

---

### Phase 7 — Sub-Issue Closure

**Purpose:** Close the sub-issue, document what happened, and propagate
learnings.

**Exit criteria:**

- [ ] All proposed tests pass, or deviations are documented in the AAR.
- [ ] The codebase is in a valid, mergeable state.
- [ ] Inline and technical docs are updated.
- [ ] The AAR is written.
- [ ] The outward pass is complete — no unresolved flags or updates outstanding.
- [ ] **Logic engine compliance.** If this sub-issue introduced or modified
      business logic, the logic engine's tests can run without instantiating the
      access surface (CLI, API, SDK, or GUI). If they cannot, the seam is in the
      wrong place — business logic has leaked into the access surface. Revise
      before closing. For sub-issues that touch only the access surface itself
      (a new CLI command wrapping existing engine behavior, a new API route),
      this criterion is a no-op.
- [ ] **Generative core / product-coherence check.** If this sub-issue changed
      product behavior, experience, or framing, confirm it still supports the
      generative core and coherence signals in `product.md`. If not, either
      revise the work, update active product artifacts, or flag the divergence
      for the parent closure.

Run the [Closure Procedure](#closure-procedure) at sub-issue level.

---

### Phase 8 — Parent Issue Closure

**Purpose:** Close the parent issue once all its sub-issues are done, and
propagate learnings upward.

**Exit criteria:**

- [ ] All sub-issues are closed with their AARs written.
- [ ] Higher-level docs are updated.
- [ ] The AAR is written, including synthesized patterns from sub-issue AARs.
- [ ] The outward pass is complete.
- [ ] Any product-coherence drift from sub-issues is resolved, flagged, or noted
      for PRD closure.

Run the [Closure Procedure](#closure-procedure) at parent issue level.

---

### Phase 9 — PRD Closure

**Purpose:** Close the cycle. The strategic cycle decision — pivot, new feature,
or feature complete — is recorded in the PRD AAR before the cycle is fully
closed.

**Exit criteria:**

- [ ] All parent issues are closed with their AARs written.
- [ ] All docs are current.
- [ ] `product.md` is updated for any durable product framing that changed.
- [ ] The PRD AAR is written.
- [ ] The cycle decision is recorded in the PRD AAR.

Run the [Closure Procedure](#closure-procedure) at PRD level, perform the cycle
decision below, then record the outcome in the PRD AAR's Cycle decision field.
The cycle is not fully closed until that field is complete.

#### Cycle decision

Performed during Phase 9 closure. Answer these questions in order:

**1. Does the product as built still match the elevator pitch in `product.md`?**

- Yes → proceed to question 2.
- No → **Pivot.** A pivot is the strategic product event. Perform a **Reframe**
  before the next cycle: revise `product.md`, then write the next cycle's pitch.
  Record what specifically changed: problem, user, gap, distinction, form,
  intentions, work boundaries, generative core, coherence signals, or
  constraints.

**2. Is there a next feature that advances the product's goal?**

- Yes → **New feature.** Write the next cycle's pitch. Update `product.md`
  additively.
- No → **Feature complete.** No active cycle. Resume when a new feature is
  identified.

The product's lifecycle is indeterminate. Feature complete is not an ending — it
is an honest statement that the current feature set is ready and there is
nothing to add right now.

Feature complete does not imply deployment readiness, launch readiness,
marketing readiness, release readiness, or public availability. If deployment,
release, launch, or distribution carries meaningful risk, coordination, quality
gates, or product-surface work, open it as its own cycle.

---

## Artifact Templates

Templates are the artifact representation of the process — they are how the
process's rules appear in practice. They can be edited as project needs evolve:
sections can be added, prompts adjusted, fields reordered. The constraint is
compatibility: no template should contradict or omit a rule stated in the
structural document. The structural document is the authority; templates are
instantiations of it. If a template is revised, verify that every principle it
encodes is still stated somewhere in the structure above — not only in the
template itself.

---

### Elevator Pitch

```
Problem: [one sentence]
Who: [target user]
Gap: [why existing solutions fall short]
Distinction: [what makes this product unlike alternatives]
Form / access surface: [how users or callers first encounter it]
```

---

### product.md

```markdown
> Describes what the product does for users. Domain terms and naming live in
> `ubiquitous-language.md` (or per-context glossaries in multi-context repos).
> This file does not define domain terms.

## Elevator pitch

Problem: [one sentence] Who: [target user] Gap: [why existing solutions fall
short] Distinction: [what makes this product unlike alternatives] Form / access
surface: [how users or callers first encounter it]

## Intentions

[Directional product effects that should guide future cycles; not closeable by
themselves]

## Goals

[What success looks like for this product across all cycles]

## Access surface

[The first access surface for this product — CLI, API, SDK, GUI, document, or
workflow surface. CLI is the suggested default when it is the simplest honest
way to pressure-test the logic engine. Choose differently when market-fit or
product form demands it. Record the reason briefly. The logic engine is built
decoupled from this choice; the surface is an adapter.]

## Work boundaries

[Durable boundaries that say what kinds of work belong in this product and what
should stay out]

## Generative core

[The durable product-making principle this product must keep expressing. The
logic engine may carry this core, but does not replace it.]

## Coherence signals

[Qualitative signs that future work still fits the product's identity]

## Constraints

[Known limits that apply across all cycles — technical, legal, resource, or
user-facing]
```

---

### prd.md

```markdown
## Focus

[One short statement naming this cycle's center of attention]

## Intentions

1. [Directional product effect]

## Goals

1. [Closeable accomplishment]

## Non-goals

1. [Explicitly out of scope]

## User stories

1. As a [actor], I want [action] so that [outcome].

## Encounter statements

1. [Optional for user-facing or experience-critical work: when the user reaches
   [access surface], they should encounter [experience or product effect].]

## Constraints and assumptions

1. [Known limit or assumption]

## Success metrics

1. [How you will know the product is working]

## Success signals

1. [Optional qualitative signal that the cycle is working]

## Open questions

1. [Question] — `MUST RESOLVE` / `RESOLVE THROUGH IMPLEMENTATION`
```

---

### ubiquitous-language.md

```markdown
# [Context Name]

> Canonical glossary for this context — terms, relationships, example dialogue.
> The product pitch, goals, and constraints live in `product.md`. The structural
> breakdown of contexts (in multi-context repos) lives in `context-map.md`. This
> file does not pitch the product.

[One sentence: what this context owns and why it exists. Omit in single-context
repos — `product.md` provides that description.]

## [Domain cluster]

<!-- Rules for every entry:
  - Be opinionated: when multiple words exist for the same concept, pick one and
    list the rest under "Aliases to avoid".
  - Only include terms a domain expert would use. Skip module names, class names,
    and general programming concepts unless they carry domain-specific meaning.
    The failure mode is a glossary that documents the code rather than the domain.
    Test: would a domain expert use this term when describing the business, or
    only a developer when describing the code?
  - Definitions are one sentence max. Define what the term IS, not what it does.
  - Group terms by natural cluster (lifecycle, actor, concept). One table per
    cluster. If all terms belong to a single cohesive area, one table is fine.
  - Flag conflicts in "Flagged ambiguities" with a clear resolution.
-->

| Term     | Definition                                  | Aliases to avoid |
| -------- | ------------------------------------------- | ---------------- |
| **Term** | One sentence. What it IS, not what it does. | synonym, alias   |

## Relationships

- A **Term** belongs to exactly one **OtherTerm**

## Example dialogue

<!-- Write 3–5 exchanges that show how terms interact naturally and clarify
     at least one boundary that is non-obvious from the definitions alone. -->

> **Dev:** "..." **Domain expert:** "..."

## Flagged ambiguities

- "word" was used to mean both **X** and **Y** — resolved: [resolution]
```

---

### context-map.md

Created when the first qualifier smell triggers a migration from single-context
to multi-context. Lives at `context/context-map.md`.

```markdown
> Describes the structural breakdown of bounded contexts and how they relate.
> Domain terms live in each context's `ubiquitous-language.md`. The product
> pitch lives in `product.md`. This file is neither a glossary nor a pitch.

# Context Map

## Contexts

- **[Name]** (`context/contexts/[name]/`) — [one sentence: what this context
  owns and why it exists as a separate context]

## Relationships

- **[A] → [B]**: [A] produces X (e.g. emits an event, writes a record); [B]
  consumes it
- **[A] ↔ [B]**: Shared types — [list what crosses the boundary, e.g.
  `CustomerId`, `Money`]

## Shared types

[Any types or identifiers that multiple contexts reference. These cross context
boundaries by value (an ID), not by structure (not the full object).]
```

---

### issue.md (Parent Issue)

```markdown
## Acceptance criteria

- [ ]

## Implementation approach

[Architectural defaults and constraints for this issue]

## Dependencies

[Other parent issues this one depends on, directional]

## Flags

[Written by sub-issue closures. Reviewed before activating any sub-issue.]
```

---

### sub-issue.md

```markdown
## Description

[What behavior this slice delivers]

## Dependency classification

| Dependency | Category | Testing strategy |
| ---------- | -------- | ---------------- |
|            |          |                  |

## Interface design

**Alternative A — minimal surface:** [Entry points, inputs, outputs, error
modes]

**Alternative B — optimized for common caller:** [Entry points, inputs, outputs,
error modes]

**Alternative C — strongest intended encounter:** [Optional for experience-heavy
user-facing work]

**Chosen:** A / B / C — [one sentence: why this wins on leverage, locality,
testability, or intended encounter]

## Acceptance criteria

- [ ]

## Proposed tests

| Title | What it verifies |
| ----- | ---------------- |
|       |                  |

## Affected artifacts

-

## Dependencies

[Other sub-issues this one depends on]
```

---

### AAR

The AAR scales with closure level. A sub-issue AAR is short — three lines if
nothing surprised you. A parent issue AAR adds synthesis across its sub-issues.
A PRD AAR is the full retrospective and is the only one that records the cycle
decision. Recording ADRs (and updating `context/adr/INDEX.md`) happens during
the Inward pass before the AAR is written — the AAR's "ADRs made" field is a
reference list, not the place where ADRs are authored.

#### Sub-issue AAR

```markdown
1. Did it go as planned? [Yes / No] — one-line summary.

2. What changed from the sub-issue plan:

3. Carry-forward — flags to write in the parent, divergence to note for future
   siblings, notes for the parent issue's AAR:
```

#### Parent issue AAR

```markdown
1. Did it go as planned? [Yes / No] — summary across sub-issues.

2. What changed from the parent issue plan:

3. ADRs made during this parent issue (reference INDEX.md rows):

4. New considerations or constraints surfaced:

5. Patterns across sub-issue AARs — repeated friction, shared learnings,
   recurring divergence:

6. Carry-forward — flags to write in the cycle, notes for the PRD AAR:
```

#### PRD AAR

```markdown
1. Did it go as planned? [Yes / No] — summary across the cycle.

2. What changed from the PRD plan:

3. ADRs made during this cycle (reference INDEX.md rows):

4. New considerations or constraints surfaced:

5. Proposed future features or ideas — candidates for the next cycle's pitch:

6. Patterns across parent issue AARs — what recurred, what was unique:

7. Carry-forward to the next cycle — additive updates to `product.md`, open
   questions promoted from the cycle, notes for the next cycle's pitch:

8. Cycle decision: pivot / new feature / feature complete — with reason. If
   pivot, record the required reframe and what changed: problem, user, gap,
   distinction, form, intentions, work boundaries, generative core, coherence
   signals, or constraints.
```

---

### ADR

```markdown
# [Short title]

_Made during: [cycle name] / [parent issue, if applicable] / [sub-issue, if
applicable]_ _Scope: product | [context-name] | [context-a, context-b]_ _Status:
accepted | superseded by ADR-NNNN | deprecated_

[1-3 sentences: what's the context, what did we decide, and why.]
```

The provenance, scope, and status lines are mandatory.

- **Provenance.** Fields after the cycle name are optional — an ADR made at
  cycle level has no issue to reference. Use only the levels that apply.
- **Scope.** Use `product` for decisions that apply across the whole product, a
  single context name for context-specific decisions, or two context names for
  decisions that span exactly those contexts. If a decision would apply to three
  or more contexts, default to `product`.
- **Status.** Defaults to `accepted`. Update to `superseded by ADR-NNNN` or
  `deprecated` when applicable. The index row must be updated in the same step.

**Optional sections.** Most ADRs need nothing beyond the 1–3 sentences. Add a
**Considered Options** section only when the rejected alternative is worth
remembering — for example, when someone six months later might re-suggest it and
the original reasoning would otherwise be lost. Add a **Consequences** section
only when non-obvious downstream effects need to be called out. If you are
tempted to add either section to satisfy a template, skip it.

ADRs live in `context/adr/` with sequential numbering: `0001-slug.md`. Create
only when all three are true:

1. **Hard to reverse** — the cost of changing your mind later is meaningful.
2. **Surprising without context** — a future reader will wonder why.
3. **The result of a real trade-off** — there were genuine alternatives.

**What qualifies.** Concrete categories that tend to meet all three criteria:

- **Architectural shape.** "We're using a monorepo." "The write model is
  event-sourced, the read model is projected into Postgres."
- **Integration patterns between contexts.** "Ordering and Billing communicate
  via domain events, not synchronous HTTP."
- **Technology choices that carry lock-in.** Database, message bus, auth
  provider, deployment target. Not every library — just the ones that would take
  a quarter to swap out.
- **Boundary and scope decisions.** "Customer data is owned by the Customer
  context; other contexts reference it by ID only." The explicit no-s are as
  valuable as the yes-s.
- **Deliberate deviations from the obvious path.** "We're using manual SQL
  instead of an ORM because X." Anything where a reasonable reader would assume
  the opposite. These stop the next engineer from "fixing" something that was
  deliberate.
- **Constraints not visible in the code.** "We can't use AWS because of
  compliance requirements." "Response times must be under 200ms because of the
  partner API contract."
- **Rejected alternatives when the rejection is non-obvious.** If you considered
  GraphQL and picked REST for subtle reasons, record it — otherwise someone will
  suggest GraphQL again in six months.

---

### ADR INDEX.md

A single table at `context/adr/INDEX.md` listing every ADR. Maintained as part
of the inward pass of the closure procedure — when an ADR is created,
superseded, or deprecated, its index row is updated in the same step.

```markdown
# ADR Index

| #    | Title                           | Scope             | Status                 | Summary                                     |
| ---- | ------------------------------- | ----------------- | ---------------------- | ------------------------------------------- |
| 0001 | Event-sourced order write model | ordering          | accepted               | Order writes go through an event log.       |
| 0002 | Postgres for read models        | product           | accepted               | All contexts project to a single Postgres.  |
| 0003 | Stripe for payments             | billing           | accepted               | Stripe over Adyen — covers initial markets. |
| 0004 | Shared CustomerId across writes | ordering, billing | superseded by ADR-0009 | Both contexts referenced customers by ID.   |
```

Loading discipline: scan the index first; fetch full ADRs only for rows that
look relevant. For context-scoped work, pre-filter to `Scope = product` or
`Scope` containing the current context name.

---

## Appendix: Test patterns

Concrete examples of the testing principles in Phase 6. Code is illustrative —
the patterns are language-agnostic.

### Mocking only at boundaries

**Bad — mocking your own collaborator:**

```ts
// OrderService and PricingService are both your modules.
// PricingService is not a system boundary. Do not mock it.
const mockPricing = { computeTotal: () => 42 };
const order = new OrderService(mockPricing);
expect(order.checkout(...)).toEqual(...);
```

If `PricingService` is unwieldy enough to make tests painful, the issue is the
boundary between `OrderService` and `PricingService`, not the test. Fix the
design.

**Good — mocking only at a true external seam:**

```ts
// Stripe is a true external dependency.
// PaymentGateway is the port. StripeAdapter and InMemoryAdapter are adapters.
const order = new OrderService(
  new PricingService(),
  new InMemoryPaymentAdapter(),
);
expect(order.checkout(...)).toEqual(...);
```

`PricingService` is real. The `InMemoryPaymentAdapter` is the only stand-in, and
it sits at a true external seam.

---

### SDK-style over generic-fetcher

Prefer SDK-style interfaces — one named function per operation — over generic
fetchers with conditional logic. Each operation must be independently mockable
with a single return value.

**Bad — generic fetcher:**

```ts
interface ApiClient {
  call(method: string, params: any): Promise<any>;
}

// Test setup must encode "if method is X, return Y" logic. Mocks become
// mini-implementations of the API itself. Adapter shape is hidden from the
// caller.
mockApi.call.mockImplementation((method, params) => {
  if (method === "charge") return { id: "ch_1" };
  if (method === "refund") return { id: "re_1" };
});
```

**Good — SDK-style:**

```ts
interface PaymentGateway {
  charge(amount: Money, customerId: CustomerId): Promise<ChargeResult>;
  refund(chargeId: ChargeId): Promise<RefundResult>;
}

// Each operation is independently mockable with a single return value.
// The interface tells the caller what operations exist. No conditional
// branching in test stubs.
const gateway: PaymentGateway = {
  charge: async () => ({ id: "ch_1" }),
  refund: async () => ({ id: "re_1" }),
};
```

---

### Behavior, not structure

**Bad — testing implementation details:**

```ts
test("OrderService calls pricingService.computeTotal once", () => {
  const spy = jest.spyOn(pricing, "computeTotal");
  service.checkout(...);
  expect(spy).toHaveBeenCalledTimes(1);
});
```

This breaks when you refactor — even if behavior is unchanged. It is testing the
implementation, not the public contract.

**Good — testing behavior through the interface:**

```ts
test("checkout returns the total including tax", () => {
  expect(service.checkout(items)).toEqual({ total: ..., tax: ... });
});
```

The test survives any refactor of how the total is computed, as long as the
behavior is unchanged.

---

### Verification through the interface

A test that reaches past the public interface to verify state — querying the
database directly instead of using the module's own read path — is testing the
wrong surface. It breaks the same invariant as an over-mocked test: tests and
callers must cross the same seam.

**Bad — bypasses interface to verify:**

```ts
test("createUser saves to database", async () => {
  await createUser({ name: "Alice" });
  const row = await db.query("SELECT * FROM users WHERE name = ?", ["Alice"]);
  expect(row).toBeDefined();
});
```

**Good — verifies through the interface:**

```ts
test("createUser makes user retrievable", async () => {
  const user = await createUser({ name: "Alice" });
  const retrieved = await getUser(user.id);
  expect(retrieved.name).toBe("Alice");
});
```

---

### Dependency injection at construction

**Bad — instantiating dependencies inside the module:**

```ts
class OrderService {
  private pricing = new PricingService();
  private payments = new StripePaymentGateway(...);
}
```

Tests cannot substitute either dependency without monkey-patching the module.

**Good — passed in at construction:**

```ts
class OrderService {
  constructor(
    private pricing: PricingService,
    private payments: PaymentGateway,
  ) {}
}
```

Tests construct the service with whatever combination of real and adapter
collaborators they need. The seam is explicit at the boundary the constructor
defines.

---

### Tracer bullet vs incremental tests

**Tracer bullet** — first test of a TDD cycle. Proves the smallest honest
behavior through the intended interface or access surface. Minimal assertion,
maximum coverage of the call graph:

```ts
test("checkout produces a confirmed order", async () => {
  const result = await service.checkout(itemsFixture);
  expect(result.status).toBe("confirmed");
});
```

**Incremental tests** — added one at a time, each focused on a specific behavior
surfaced by the implementation:

```ts
test("checkout applies tax to subtotal", async () => { ... });
test("checkout rejects empty cart", async () => { ... });
test("checkout fails when payment is declined", async () => { ... });
```

Never write all of these before the tracer bullet passes. The tracer bullet's
job is to prove the path and first contact are real; incremental tests describe
the behavior along that path.

---

## Appendix: Terminology

### Process terms

**AAR (After-Action Review)** A structured retrospective written at every
closure. It documents what happened, what changed from the plan, decisions made,
and what carries forward.

_Why it's here:_ Plans are starting hypotheses. The AAR is where divergence is
documented rather than hidden. Without it, the gap between what was planned and
what was built becomes invisible to future cycles.

---

**ADR (Architectural Decision Record)** A short document recording a
hard-to-reverse, surprising, trade-off decision. Written only when all three
criteria are met: hard to reverse, surprising without context, the result of a
real trade-off.

_Why it's here:_ Most decisions don't need to be recorded — they're obvious,
reversible, or self-evident from the code. ADRs exist for the ones that aren't.
A future reader should never wonder "why on earth did they do it this way?" and
find no answer.

---

**Minimum honest process** The smallest artifact set that still records scope,
acceptance criteria, testing or checking, and closure. It allows small cycles to
collapse process layers without pretending the missing layers were completed.

_Why it's here:_ Lightweight work still needs honesty. The failure mode is not
small process; it is implicit process where nobody can later tell what was in
scope, how it was checked, or why it closed.

---

**Focus** The cycle's current center of attention, stated narrowly enough to
guide decomposition and reject distracting work.

_Why it's here:_ A PRD can contain many valid goals. Focus names the center of
gravity so AI-assisted work does not optimize every true statement equally.

---

**Intention** A directional product effect the team wants to create. Intentions
are durable guidance, but they are not closeable completion criteria.

_Why it's here:_ Product work needs direction that is larger than a checklist.
Separating intentions from goals keeps the product's desired effect visible
without confusing it with what can close this cycle.

---

**Goal** A closeable accomplishment. A goal says what will be true when the
cycle, product phase, or artifact is done.

_Why it's here:_ Goals create closure. If a statement cannot be closed, it is
probably an intention, constraint, signal, or open question instead.

---

**Vertical slice** A unit of implementation work that touches every layer needed
to deliver one thin piece of behavior end-to-end. Mergeable on its own — after
merging, the codebase is in a valid, working state.

_Why it's here:_ The alternative is horizontal layers — build all the database
code, then all the logic, then all the interface. Horizontal layers delay the
moment when anything actually works. A vertical slice delivers a working
behavior immediately, even if the behavior is thin.

---

**Encounter statement** An optional PRD statement for user-facing or
experience-critical work. It describes how a user should encounter the feature
through the access surface. It supplements user stories; it does not replace
them.

_Why it's here:_ Some features can pass the usual actor/action/outcome story but
still fail the intended experience. Encounter statements make that experience
testable enough to influence acceptance criteria without turning the whole PRD
into design prose.

---

**Tracer bullet** The first test in a TDD cycle. It proves the smallest honest
behavior through the intended interface or access surface before incremental
work begins. It must fail before the implementation exists, and pass after the
minimum code is written.

_Why it's here:_ Without a tracer bullet, early tests might pass for the wrong
reason — a misconfigured environment, a mocked path that doesn't exist in
production. The tracer bullet fails loud and clearly, proving the path is real
before you build anything on top of it.

---

**First contact** The first test or slice that proves the intended caller or
user can actually encounter the behavior through the chosen interface or access
surface.

_Why it's here:_ Early tests can accidentally prove an internal path while the
real access surface remains untested. First contact keeps the tracer bullet tied
to the product's actual form.

---

**TDD (Test-Driven Development)** A development discipline with four stages per
slice: pre-activation, tracer bullet, incremental loop, deepen. One test at a
time. Tests describe behavior through the public interface, never implementation
details.

_Why it's here:_ Writing code and testing it afterward produces tests that
verify what the code does, not what it should do. TDD inverts this: the test
defines the expected behavior, and the code is written to satisfy it. Tests
written this way survive refactors because they don't care about internal
structure.

---

**Flag** A signal written into a parent artifact when a closure surfaces a risk
for a future sibling. It blocks the sibling's activation until resolved. Never
written directly into the sibling.

_Why it's here:_ The temptation after a closure is to edit sibling artifacts
based on what you just learned. This is wrong — you don't have the sibling's
full context, and you'd be making decisions at the wrong level. A flag defers
the decision to the moment the sibling is activated, when the right context
exists to make it.

---

**Outward pass** The second step of the closure procedure. After closing a unit,
scan every artifact that referenced what changed. Update active artifacts, write
flags for future artifacts in their parent, note closed artifacts in the AAR.

_Why it's here:_ A closure that only updates its own artifact leaves the rest of
`context/` stale. The outward pass is what keeps the folder reliable — every
closure takes responsibility for the artifacts it affected.

---

**Pre-activation** The first stage of Phase 6. Before writing any code, read the
parent artifact and resolve all flags targeting the current sub-issue. A
sub-issue with an open flag cannot be activated.

_Why it's here:_ Flags written by prior closures represent risks that may
invalidate the sub-issue's assumptions. Activating without reviewing them means
building on a foundation that may have already shifted.

---

**Deepening** Structural improvement that changes coherence, leverage, locality,
or testability. It changes where responsibility lives or which seam callers and
tests cross.

_Why it's here:_ Deepening is not generic cleanup. It is the architectural work
that makes future behavior easier to add, verify, and understand.

---

**Surface refinement** Finish work that improves wording, UI polish, docs, logs,
names, formatting, or similar surfaces without changing core structure.

_Why it's here:_ Polish matters, but it cannot compensate for weak seams,
unclear responsibility, or unresolved domain structure. Naming it separately
prevents finish work from masquerading as architecture.

---

**Feature complete** The third cycle decision outcome. The feature set for this
product is complete for now. No active cycle. Resume when a new feature is
identified. The product is not closed, deployed, launched, or release-ready by
definition — its lifecycle is indeterminate.

_Why it's here:_ "Done" implies finality. "Pause" implies something external
interrupted the work. Feature complete is the honest statement: what was planned
has been built, and there is nothing to add right now.

---

**Pivot** A strategic product event where the product as built no longer matches
the durable product framing.

_Why it's here:_ Pivot names the business/product event, not the file edit. It
keeps strategic change visible at cycle closure.

---

**Reframe** The required document operation after a pivot: revise `product.md`
before the next cycle so the durable product framing matches the new identity.

_Why it's here:_ Without a reframe, teams keep building against stale product
identity. Pivot decides that identity changed; reframe makes the durable
artifact tell the truth.

---

**Cycle** One complete pass through the process, from elevator pitch to PRD
closure. A product's life is made up of cycles. Each cycle has its own pitch,
PRD, and issues. Product-level artifacts (`product.md`, `adr/`) span all cycles.
In single-context repos, `ubiquitous-language.md` is also product-level. In
multi-context repos, each context's `ubiquitous-language.md` is context-level —
it spans all cycles for that context, but not across contexts.

_Why it's here:_ The process is recursive by design — a "pitch" can be the
original product pitch or a new feature pitch. Cycle disambiguates: it refers to
one complete pass, not the product as a whole.

---

### Architecture terms

**Generative core** The durable product-making principle that defines what the
product must keep producing or preserving across cycles. It belongs to product
framing before implementation shape.

The logic engine may carry the generative core, especially in software products
where the core behavior is computational. But the generative core is not the
logic engine: it can also be expressed through access surface choices,
documentation structure, interaction design, defaults, constraints, or workflow
shape.

_Why it's here:_ Products can stay technically correct while drifting away from
what made them worth building. Naming the generative core gives closure checks a
product-coherence target that is broader than code architecture.

---

**Logic engine** The core business logic of the product, built and tested
independently of any access surface. The engine works the same whether consumed
by a CLI, API, SDK, or GUI.

The logic engine is the primary **deep module** in the system — a large amount
of behavior sits behind a small, stable interface. The access surface (CLI, API,
GUI) is an **adapter** at the outermost **seam**. It calls the logic engine; it
does not own it.

The compliance check is concrete: can you run the full test suite for the logic
engine without the CLI, API, or GUI being present? If yes, the engine is
decoupled. If no, the seam is in the wrong place — business logic has leaked
into the access surface.

_Why it's here:_ The most common early failure mode is business logic coupled to
the interface that happens to be built first. When the interface changes, the
logic changes with it. A decoupled logic engine is immune to this — the surface
can change without touching what the product actually does.

---

**CLI-first** A strategy in which the command-line interface is the first
consumer built for the logic engine because it is often the simplest honest
access surface for pressure-testing the engine. Fast feedback is useful, but the
main point is proving behavior through a clean interface before investing in a
heavier surface.

_Why it's here:_ Building a GUI or API first delays feedback — you invest in the
surface before knowing if the logic is right. The CLI is often the cleanest path
from "logic engine exists" to "behavior is verified through an honest surface."
It is the suggested default; the actual first access surface is recorded in
`product.md` and may differ when market-fit or product form demands it.

---

**Module** Anything with an interface and an implementation. Scale-agnostic —
applies equally to a function, class, package, or tier-spanning slice.

_Why it's here:_ "Module" replaces "component," "service," "unit," and "piece" —
terms that mean different things in different contexts. Consistent vocabulary is
how a process stays coherent across a codebase.

---

**Interface** Everything a caller must know to use a module correctly: entry
points, inputs, outputs, invariants, error modes, ordering constraints, and
performance characteristics. Not just the type signature.

_Why it's here:_ The narrower definition — "the type signature" — misses the
facts a caller needs to use the module safely. A function that must be called
before another, a parameter that cannot be null after initialization, an error
that silently swallows input: these are interface facts, not implementation
details.

---

**Implementation** The code inside a module — its body. Distinct from
**Adapter**: a thing can be a small adapter with a large implementation (a
Postgres repository), or a large adapter with a small implementation (an
in-memory fake). Reach for "adapter" when the seam is the topic;
"implementation" otherwise.

_Why it's here:_ Conflating implementation with adapter produces bad interface
design. The size and shape of what's inside a module does not determine its role
at the seam — a trivial implementation can fill a critical adapter slot, and a
large implementation can sit entirely behind a narrow external interface.

---

**Depth** The leverage a module provides at its interface. A module is deep when
a large amount of behavior sits behind a small interface. A module is shallow
when the interface is nearly as complex as the implementation.

Depth is a property of the interface, not the implementation. A deep module can
be internally composed of many small, swappable parts — they just aren't part of
the interface. Measuring depth by lines of code or internal complexity misses
the point: what matters is how much a caller gets per unit of interface they
have to learn.

_Why it's here:_ Depth is the measurable property that distinguishes a
well-designed module from a pass-through. It is not about lines of code — it is
about how much a caller gets per unit of interface they have to learn.

---

**Seam** The location at which a module's interface lives — the place where
behavior can be altered without editing in that place. A module has one
**external seam** at its interface (the surface callers and tests cross) and may
have **internal seams** private to its implementation (used for internal
decomposition, never exposed through the interface).

The distinction matters at design time: an internal seam exists because
implementation parts vary internally. An external seam exists because something
external varies — a different adapter for production vs. test, a different
runtime, a different caller. Don't expose an internal seam through the public
interface just because tests want to reach inside; that is a sign the external
interface is the wrong shape, not that the internal seam should be promoted.

_Why it's here:_ Knowing where a seam is tells you where to test, where to
inject alternatives, and where to draw the line between inside and outside a
module. "Boundary" is avoided because it is overloaded with DDD's bounded
context.

---

**Adapter** A concrete thing that satisfies an interface at a seam. Describes
role — what slot it fills — not substance. The same seam can have multiple
adapters: a production adapter (HTTP, Postgres, Stripe) and a test adapter
(in-memory, fake, mock). Two adapters at a seam is the signal the seam is real.
One adapter is the signal it may not be.

_Why it's here:_ The dependency classification in Phase 5 determines which
adapters a module needs. Remote but owned dependencies get an HTTP adapter for
production and an in-memory adapter for tests. True external dependencies get a
mock adapter for tests. Naming the role "adapter" keeps the seam discipline
check concrete — you can count adapters, which tells you whether the seam is
justified.

---

**Deletion test** A check for module depth: imagine deleting the module. If
complexity vanishes, the module was a pass-through and may not be earning its
keep. If complexity reappears across callers, the module was hiding something
real.

_Why it's here:_ Shallow modules are easy to identify in theory and hard to spot
in practice. The deletion test is a concrete mental operation that makes the
question answerable without requiring measurement.

---

**Leverage** What callers get from a deep module. More capability per unit of
interface they must learn. One implementation pays back across many call sites
and tests.

_Why it's here:_ Depth without leverage is complexity hidden for its own sake.
Leverage is the user-facing benefit of depth — it is why depth is worth
pursuing.

---

**Locality** What maintainers get from a deep module. Change, bugs, knowledge,
and verification concentrate at one place rather than spreading across callers.
Fix once, fixed everywhere.

_Why it's here:_ Shallow modules distribute responsibility across their callers.
When a behavior needs to change, every caller changes. A deep module centralizes
that responsibility — locality is what makes a codebase maintainable as it
grows.

---

**Bounded context** A part of the system with its own ubiquitous language — a
region where every term has exactly one unambiguous definition. Terms can cross
context boundaries, but their definitions do not travel with them: "Customer" in
the ordering context and "Customer" in the billing context may share a name and
a `CustomerId`, but they are distinct concepts with distinct definitions.

_Why it's here:_ The most common source of glossary ambiguity is not bad
definitions — it is forcing one definition to serve two different contexts. A
bounded context is the structural answer to that problem.

---

**Qualifier smell** The observable signal that a bounded context boundary has
emerged: a term in `ubiquitous-language.md` cannot be defined without a
qualifier ("Customer (billing)" vs. "Customer (ordering)"), or its definition
contains exceptions for specific parts of the system. The smell indicates that
the term is doing two different jobs — one per context — and the glossary needs
to be split, not expanded.

_Why it's here:_ Context boundaries are invisible until they surface in
language. The qualifier smell is the earliest, cheapest moment to act. Waiting
until the code is built means the boundary costs a refactor to draw.

---

**Context migration** The procedure of moving from a single-context setup to a
multi-context setup, triggered by the qualifier smell. Creates
`context/context-map.md`, splits `ubiquitous-language.md` along the identified
boundary, and resumes work with per-context glossaries. See the migration
procedure in the `context/` folder Rules section.

_Why it's here:_ Migration is not a project — it is a short procedure executed
at the moment the signal appears. Naming it and scripting it removes the
temptation to defer it.

---

**Design it twice** The discipline of generating at least two interface designs
with meaningfully different shapes before committing to one. Compare on
**leverage** and **locality**. Record the chosen design and the rejected
alternative with a one-sentence reason.

_Why it's here:_ The first interface design is rarely the best one. The exercise
of generating a second forces the designer to question assumptions made in the
first. The rejected alternative is itself documentation — it records a decision
that might otherwise be re-litigated later.

---

**Dependency classification** A categorization of a module's dependencies that
determines its testing strategy: In-process (test directly), Local-substitutable
(test with local stand-in), Remote but owned (inject port with in-memory adapter
for tests), Collaborator-owned (contract with another person or team), True
external (inject port with mock adapter for tests), Irreplaceable (verify the
real dependency through narrow characterization, contract, or acceptance
checks).

_Why it's here:_ The testing strategy for a module is not a style choice — it
follows from what the module depends on. Classifying dependencies before
designing the interface prevents the mismatch between "how we planned to test
this" and "what this actually touches."
