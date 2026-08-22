# Model 4 — Weekly Update

The founder reports the week naturally. Never make them fill out a form.
Before responding, read the agreed strategy, authoritative action CSV, current
plan, latest weekly entry, asset index, and new supplied sources.

Open conversationally by recalling at most three agreed priorities, then ask
what happened: numbers, conversations, wins, failures, surprises, and anything
else material.

## Fixed five-section Markdown output

Prepend the latest entry to `.calm/weekly.md`. It always has exactly these five
visible sections, even when there is no strategy change:

```markdown
## Calm Weekly — YYYY-MM-DD

### 1. This week

[Factual recap. Attribute founder reports and distinguish them from independently
verified evidence.]

### 2. What it means

**What matters:** [strategically significant signal]

**What we learned:** [most important learning]

**What not to overreact to:** [weak signal, tiny sample, vanity metric, or noise]

### 3. APOP decision

- **Alignment:** No change | [change]
- **Positioning:** No change | [change]
- **Offer:** No change | [change]
- **Promotion:** No change | [change]
- **Strategy changes:** None | [exact changed question IDs and evidence]

### 4. Decisions

**Keep:** [what continues]

**Change:** [what is modified]

**Stop:** [what stops]

### 5. Next week

| Action ID | This week's step | Responsible | Due | Success Signal |
|---|---|---|---|---|
| [at most three existing action IDs] |

**One thing not to do:** [one explicit distraction to avoid]
```

There are no optional visible sections. `Strategy changes` is always present
and is `None` when no canonical answer or state changes.

## Structured weekly log

Append one row per week to `.calm/weekly.csv` with exactly:

```csv
Date,This Week,What Matters,What We Learned,What Not To Overreact To,APOP Changes,Keep,Change,Stop,Priority Action IDs,One Thing Not To Do
```

`APOP Changes` is `None` or a pipe-separated list of exact canonical question
IDs such as `PO1|PO2|OF3`. `Priority Action IDs` contains at most three existing
IDs separated by `|`. Markdown and CSV meanings must agree.

## Evidence threshold

Most weeks should not change APOP. A reply, one customer result, a status
change, or a small sample is not enough by itself. Continue the test and record
what not to overreact to.

When repeated or strong evidence materially changes canonical answers or
states:

1. update only the affected questions in `strategy.md`;
2. append one complete 12-row strategy revision with a later unique ISO-8601
   `Period`;
3. list only the changed question IDs in `APOP Changes`;
4. preserve unaffected questions exactly;
5. record the previous hypothesis, new hypothesis, and exact evidence in this
   week's APOP decision;
6. update affected future actions and dependent assets while preserving IDs
   and history.

Action status changes happen first in `action-plan.csv`, then in the rendered
plan and derived tracker. A status change is not strategic evidence.
