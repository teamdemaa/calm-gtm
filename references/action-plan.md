# Model 2 — Action Plan

Create this output only after `.calm/strategy.md` is explicitly `agreed`.
Derive every action from one or more exact canonical APOP question IDs.

The plan has three fixed horizons:

- `Now`: the next 30 days, concrete and immediately executable;
- `Next`: days 31–90, clear objectives and deliverables;
- `Later`: months 4–6, milestones and decision points without fake precision.

Keep the plan calm: use at most three actions in each horizon. The `Now`
actions are the founder's only immediate priorities; sequence additional work
into `Next` or `Later` instead of presenting a longer active list.

## Approval state

The first plan is a proposal. Begin `.calm/action-plan.md` with:

```markdown
<!-- calm:plan-status=proposed -->
<!-- calm:plan-updated-at=YYYY-MM-DD -->
<!-- calm:plan-agreed-at= -->
```

Ask for agreement in the conversation, not inside the persisted file. Do not
execute actions or create assets while the plan is proposed.

After explicit agreement, change only the metadata to `plan-status=agreed` and
set `plan-agreed-at`. Approval alone does not rewrite actions and does not
authorize generation of any asset.

## Authoritative CSV

`.calm/action-plan.csv` is authoritative for actions and statuses. Use exactly:

```csv
Action ID,Horizon,Objective,Action,Why,APOP Link,Responsible,Due,Deliverable,Success Signal,Status
```

Rules:

- IDs use `ACT-001`, `ACT-002`, and so on; they are monotonic, never reused or
  renumbered.
- A status change or small wording correction keeps the ID.
- A materially new action receives a new ID.
- An abandoned action remains addressable with `Status=Stopped`.
- `Horizon` is exactly `Now`, `Next`, or `Later`.
- `APOP Link` contains one or more canonical question IDs separated by `|`.
- `Status` is exactly `Not started`, `In progress`, `Done`, `Blocked`, or
  `Stopped`.
- A numerical `Success Signal` is a threshold used for a later decision, never
  a claim that the result already exists.

Replacing the current CSV is allowed when rendering the current plan, but do
not silently discard stopped actions or reuse their IDs. Weekly history records
prior priorities and strategic decisions.

## Fixed Markdown output

Render `.calm/action-plan.md` from the same row values. Use exactly one section
for each horizon, in order:

```markdown
## Now — [period]

### [Localized Objective label]

[Objective, textually identical to the CSV after normalizing line wrapping.]

### Actions

| Action | Why | Responsible | Due | Deliverable | Success Signal | Status |
|---|---|---|---|---|---|---|
| [exact CSV values] |

## Next — [period]

[Same structure.]

## Later — [period]

[Same structure.]
```

The human-readable action fields must match the CSV exactly. Do not append an
approval call-to-action to the file.

## Assets

An asset may be named only when an agreed action needs it. After the plan is
agreed, follow `references/assets.md` and wait for the founder to explicitly
ask for or approve that asset before creating it. Do not create speculative
landing pages, directories, blogs, newsletters, campaigns, or prompts merely
because they might be useful later.
