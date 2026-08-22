# Model 3 — Assets

Create an asset only when both conditions are true:

1. an action in the explicitly agreed plan requires it;
2. the founder explicitly asks for that asset or approves its short brief.

Plan approval alone is never asset approval. A weekly priority or a deliverable
named in the plan is not asset approval either.

Before Calm-originated asset work, show one short conversational brief with the
linked Action ID, deliverable, purpose, audience, and material scope or target
paths. Ask the founder to approve or change it. Do not persist this brief as a
new model and do not create `assets.csv` yet. A founder's direct instruction to
create a sufficiently specified asset counts as explicit approval.

After approval, produce the finished deliverable, not a prompt describing how
someone else could produce it.

## Asset index and identity

Create `.calm/assets.csv` with exactly:

```csv
Asset ID,Asset Name,Category,Purpose,Linked Action ID,File,Status
```

- IDs use `ASSET-001`, `ASSET-002`, and so on; they are monotonic and never
  reused.
- `Linked Action ID` must exist in `action-plan.csv`.
- `File` points to the real primary file, not an imagined destination.
- `Status` is `Draft`, `Final`, or `Superseded`.
- Keep prior rows so the index preserves what was produced. IDs and rows remain
  addressable; lifecycle status may change.

Every asset file or manifest starts with:

```markdown
<!-- calm:asset-id=ASSET-001 -->
<!-- calm:linked-action-id=ACT-003 -->
```

A material revision receives a new ID and a new file. Mark the prior row
`Superseded`; never delete it. The new file additionally declares:

```markdown
<!-- calm:supersedes=ASSET-001 -->
```

Never silently overwrite a materially different local asset.

## Where to build the asset

Use the coding agent's project access when the deliverable is a real product or
site artifact:

- a landing page is implemented in the target application;
- a directory is implemented in the target project;
- a blog or newsletter structure is created in the appropriate project
  folders;
- code, copy, styles, tests, and supporting files are updated when the agreed
  action and approved asset brief actually require them.

For a code asset spanning multiple files, `assets.csv` points to the primary
real file and `.calm/assets/<asset-id>.md` is a manifest containing the asset
metadata and every affected project path. The manifest is an index, not a copy
of the implementation.

Use a prompt only when the founder explicitly asks for one or, after asset
approval, when the current agent cannot access the target system. State the
limitation honestly.

For text deliverables that do belong in Calm's local memory—outreach copy,
sales scripts, interview guides, campaign briefs—save the finished asset under
`.calm/assets/`.

## Finished text asset format

```markdown
<!-- calm:asset-id=ASSET-001 -->
<!-- calm:linked-action-id=ACT-003 -->

**Purpose:** [why this exists]
**Audience:** [exact agreed audience]
**Desired action:** [what should happen next]
**Message:** [the central idea]

---

[finished deliverable]
```

Every asset inherits the agreed ICP, positioning, offer, motion, proof level,
and tone. Do not invent evidence or reinvent strategy inside an asset.

Typical categories include Messaging, Website, Sales, Paid acquisition, and
Content. A directory, blog, newsletter, owned vertical distribution asset, or
search asset is never a default; it exists only when the agreed motion and an
agreed action require it and the founder explicitly approves it.
