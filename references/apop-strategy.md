# Model 1 — APOP Strategy

The strategy has one fixed output structure. Conversation can be flexible;
the persisted strategy cannot. Clarifying questions may continue until the
strategy is clear, but they never create additional strategy fields.

Before producing this output, read `references/apop-questions.csv` in full.
Those 12 IDs, areas, and questions are immutable. Never replace, paraphrase,
reorder, add, or remove a question.

## Evidence discipline

Read all founder-supplied links and documents first. Separate:

- `Known`: supported by founder-supplied facts or observed evidence, with its
  provenance retained in the answer;
- `Hypothesis`: a proposed strategic choice or an unvalidated claim;
- `Unknown`: information that is still missing.

A website statement is evidence of what the website claims, not validation.
A founder report is founder-supplied evidence, not independent verification.
Never invent market size, traction, conversion, willingness to pay, product
capabilities, quotes, or customer results. Numerical success signals in a later
plan are decision thresholds, not facts.

## Approval and revision state

Write the current strategy to `.calm/strategy.md`. A proposal begins with:

```markdown
<!-- calm:strategy-status=proposed -->
<!-- calm:strategy-updated-at=YYYY-MM-DD -->
<!-- calm:strategy-agreed-at= -->
```

Ask for agreement in the conversation, not inside `strategy.md`. Do not create
an action plan yet.

After explicit agreement, change only the metadata to:

```markdown
<!-- calm:strategy-status=agreed -->
<!-- calm:strategy-updated-at=YYYY-MM-DD -->
<!-- calm:strategy-agreed-at=YYYY-MM-DD -->
```

Approval alone does not change an answer and does not append another revision.

Create `.calm/strategy.csv` with exactly this header:

```csv
Period,Question ID,Area,Question,Answer,State
```

Append exactly 12 rows when the strategy is first written or materially
revised. `Period` is one unique ISO-8601 timestamp such as
`2026-08-22T18:00:00+02:00`; all 12 rows in that revision share it. `Question
ID`, `Area`, and `Question` must equal `references/apop-questions.csv` byte for
byte. `Answer` and `State` must equal the current Markdown after normalizing
line wrapping. Never delete prior revision rows.

## Fixed Markdown output

The document contains one thesis followed by the 12 canonical questions. It
contains no alternative strategy headings or supplementary strategy sections.
Fold ICP detail, founder advantage, proof required, channel choice, exclusions,
and other useful reasoning into the matching answers.

```markdown
## [Localized title for Calm GTM Strategy]

### [Localized GTM thesis label]

[One short synthesis of the 12 answers. This is not a thirteenth question.]

## A — Alignment

### What do you want this company to bring you?

**Answer:** [answer in the founder's language]

**State:** Known | Hypothesis | Unknown

### What are you particularly good at, and how do you know?

**Answer:** [...]

**State:** Known | Hypothesis | Unknown

### What constraints are you working with right now: time, money, energy?

**Answer:** [...]

**State:** Known | Hypothesis | Unknown

## P — Positioning

[Repeat the exact PO1, PO2, and PO3 questions from the canonical CSV, each
with exactly one Answer and one State.]

## O — Offer

[Repeat the exact OF1, OF2, and OF3 questions from the canonical CSV, each
with exactly one Answer and one State.]

## P — Promotion

[Repeat the exact PR1, PR2, and PR3 questions from the canonical CSV, each
with exactly one Answer and one State.]
```

The primary promotion motion is a strategic choice, not a universal default.
Choose the motion that fits the ICP, stage, buying behavior, constraints, and
evidence. Founder-led sales, owned vertical distribution, and search are all
possible; do not force owned distribution or search without evidence. Choose
one primary motion and at most one supporting motion by default.

After persisting the proposal, ask naturally whether the founder agrees,
challenges a point, or wants a change. The approval question belongs only to
the conversation.

## Material revisions

Weak signals do not rewrite strategy. When repeated or strong evidence changes
one or more canonical answers or states:

1. update only those questions in `strategy.md`;
2. append a complete new 12-row block to `strategy.csv` with a later unique
   `Period`;
3. list the exact changed question IDs in that week's `APOP Changes` field;
4. preserve all unchanged answers;
5. record previous hypothesis, new hypothesis, and evidence in `weekly.md`.

If a revision happens outside the weekly rhythm, create a weekly decision entry
for it rather than creating another decision system.
