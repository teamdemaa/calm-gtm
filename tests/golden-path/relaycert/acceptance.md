# RelayCert acceptance contract

## Conversation

- The opening sentence matches the approved product copy exactly.
- The founder can answer in unstructured, multiline prose.
- Both supplied files are read before Calm asks follow-up questions.
- Calm asks only questions that can materially change the strategy; the number
  of clarification turns is not fixed.
- The conversation continues in French after the founder answers in French.
- Clarification questions never create new strategy fields.
- `intake.md` preserves the opening response and material clarifications. It
  does not duplicate strategy approval, plan approval, or weekly reports.

## Stable language tokens

- Narrative answers, explanations, assets, and derived views follow the
  founder's language.
- The 12 canonical questions, question and record IDs, CSV headers, `Now` /
  `Next` / `Later`, `Known` / `Hypothesis` / `Unknown`, action status values,
  and the five weekly section titles remain in English in every project.
- Stable English tokens are structural fields, not additional founder-facing
  questions.

## Strategy contract

- The immutable question contract is `contract/apop-questions.csv`.
- `strategy.md` contains one GTM thesis followed by exactly the 12 canonical
  questions, in canonical order, with no alternative strategy headings.
- Every question has an answer and a state: `Known`, `Hypothesis`, or `Unknown`.
- `strategy.csv` contains the same 12 questions, IDs, answers, and states.
  After normalizing Markdown line wrapping, every answer is textually
  identical in the two files; the CSV is never a shorter parallel strategy.
- `Period` is a unique ISO-8601 timestamp for one strategy revision. All 12
  rows in that revision share it. Approval-only state changes do not append a
  duplicate 12-row block.
- The GTM thesis is a synthesis of the 12 answers, not a thirteenth question.
- Seven years of domain experience is founder-supplied evidence, not an
  independently verified credential.
- Founder-supplied notes about two free pilots support product access and
  observed workflow problems, not traction or willingness to pay.
- The website's €149/month price is a claim and an unvalidated hypothesis.
- The founder's report that one owner might pay €300 is not recorded as a sale
  or commitment.
- No market size, conversion rate, ROI, customer quote, or product capability
  is invented.

## Approval gates

- `strategy.md` is absent before the strategy is proposed.
- A proposed strategy is marked `proposed`.
- `action-plan.md`, `action-plan.csv`, `assets.csv`, and generated assets are
  absent before explicit strategy agreement.
- Strategy agreement is a separate founder turn. It changes the strategy state
  to `agreed` without changing its answers or appending a duplicate revision.
- The action plan is first marked `proposed`; no asset exists in that snapshot.
- The founder explicitly approves the proposed plan before execution starts.
- Plan approval changes only the plan state to `agreed`; it does not rewrite
  action content or create an asset.
- Every horizon contains at most three actions, so the plan remains focused
  while preserving Now / Next / Later.
- After normalizing Markdown table formatting, every human-readable action row
  matches the authoritative CSV values exactly.
- Every action has a stable `Action ID` and an `APOP Link` to one or more exact
  canonical questions.
- Action IDs are monotonic and are never reused or renumbered. A status change
  or small edit keeps the existing ID; a materially new action receives a new
  ID. An abandoned action remains in history with `Status=Stopped`.
- Allowed action status tokens are exactly `Not started`, `In progress`,
  `Done`, `Blocked`, and `Stopped`.
- Numeric success signals are decision thresholds for the action, not claims
  that the result or evidence already exists.
- The agreed plan snapshot contains no `assets.csv`: plan agreement alone is
  never asset approval.
- The outreach asset exists only because the agreed action `ACT-003` requires
  it and the founder explicitly approved its short brief in a separate turn.

## Asset behavior

- Calm produces a finished outreach message, not a prompt describing how to
  write one.
- A direct, sufficiently specified request from the founder counts as asset
  approval. Otherwise Calm summarizes deliverable, purpose, audience, and
  material scope, then waits for explicit approval before writing files.
- The short approval exchange is conversational; it does not create a fifth
  source model or a separate approval file.
- The asset index links the asset to `ACT-003` and its real local file.
- Asset IDs are monotonic and never reused. A material revision receives a new
  ID and file, marks the prior row `Superseded`, and declares `calm:asset-id`,
  `calm:linked-action-id`, and `calm:supersedes` metadata. `assets.csv` keeps
  every unique ID and its history.
- For code assets that change multiple project files, the `File` column points
  to the primary real file and `.calm/assets/<asset-id>.md` records every
  affected path. A prompt remains only a fallback or an explicit request.
- A larger asset such as a landing page, directory, blog, or newsletter would
  be decomposed into agreed actions and built in the target project when the
  coding agent has access. A prompt is only a fallback or an explicit request.
- RelayCert does not receive a speculative directory or newsletter because its
  agreed immediate motion is founder-led sales.

## Tracker

- `action-plan.csv` is authoritative for action status.
- `overview.md` is derived and contains no independent decisions.
- The thesis, action objective, action text, due dates, statuses, asset records,
  and weekly fields shown in `overview.md` are copied exactly from their source
  models rather than paraphrased.
- Changing a status in `action-plan.csv` and regenerating status changes the
  overview without rewriting strategy.
- The weekly overview includes the latest meaningful evidence and priorities.
- `dashboard.html` is absent by default and exists only in the opt-in snapshot.
- The HTML view uses only local data, loads no remote resource, and contains no
  authentication, CRM, analytics, or synchronization code.

## Weekly contract

- The founder reports the week naturally rather than filling out a form.
- Every weekly entry has exactly five visible sections: `This week`, `What it
  means`, `APOP decision`, `Decisions`, and `Next week`.
- `What it means` contains what matters, what was learned, and what not to
  overreact to.
- `APOP decision` always names all four areas and always includes `Strategy
  changes`, using `None` when no answer changes.
- In `weekly.csv`, `APOP Changes` is either `None` or a pipe-separated list of
  changed canonical question IDs such as `PO1|OF3`.
- `Decisions` always contains `Keep`, `Change`, and `Stop`.
- `Next week` contains at most three priorities linked to existing Action IDs
  plus one thing not to do.
- The entry records 12 messages, 4 replies, 2 calls, one faster dossier, and
  zero paid pilots.
- It identifies the faster dossier as a weak, single-case signal.
- Alignment, Positioning, Offer, and Promotion all remain unchanged.
- `strategy.md` and `strategy.csv` remain unchanged.
- A status change by itself never counts as strategic evidence.

## Mechanical checks

- CSV headers exactly match the Phase 1 golden schemas.
- Strategy CSV contains exactly 12 data rows for the single strategy revision.
- The 12 question IDs, areas, and literal questions equal the immutable
  contract byte for byte and in the same order.
- CSV fields are single-line, UTF-8, and correctly quoted where needed.
- Plan proposal and approval contain identical action rows, and both contain
  no asset.
- No horizon contains more than three actions.
- Weekly CSV contains one data row and references existing Action IDs.
- Every strategy revision has one unique ISO-8601 `Period`, shared by exactly
  its 12 canonical rows.
- Action and asset IDs remain monotonic across revisions, and stopped actions
  remain addressable in history.
- `sources.md` is append-only from initialization and records only supplied
  links and documents. Founder intake lives in `intake.md`; weekly reported
  evidence lives in `weekly.md`.
- All fixture paths work when the repository path contains spaces.
