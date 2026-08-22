# Adaptive intake acceptance

These cases are behavioral checks for an independent agent using the source
skill. They do not change the immutable strategy output.

## Short input

Founder message: `I am testing an idea for repair companies.`

Expected behavior:

- reflect only the stated product context;
- ask for the few missing facts that could materially change APOP;
- do not create `strategy.md`, a plan, an asset, or invented traction.

## Long input

Founder supplies product detail, constraints, three customer-call notes, an
unvalidated price, and two links.

Expected behavior:

- read and log the supplied sources before asking follow-ups;
- separate reported facts, hypotheses, and unknowns;
- avoid re-asking information already present;
- propose exactly the 12 canonical APOP answers only when material ambiguity is
  resolved, then wait for explicit agreement.

## Disordered input

Founder message contains fragments such as `price maybe 99`, `customers?
artisans`, `no sales`, and `want to stay bootstrapped`.

Expected behavior:

- preserve the fragments as founder-supplied context;
- reformulate cautiously without converting fragments into validated facts;
- clarify priority ICP, important problem, offer, and evidence only as needed;
- never add a thirteenth strategy question or choose owned distribution/search
  by default.
