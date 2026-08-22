# Derived local tracker

`overview.md` and the optional `dashboard.html` are disposable views of the
four models, not a fifth model. They never introduce, paraphrase, or preserve
independent GTM state.

## Authority

- strategy thesis and approval: `.calm/strategy.md`;
- actions, objectives, due dates, and statuses: `.calm/action-plan.csv`;
- asset IDs, names, links, files, and statuses: `.calm/assets.csv`;
- latest weekly fields: `.calm/weekly.csv`;
- priority labels: resolve `Priority Action IDs` to exact Action values from
  `.calm/action-plan.csv`.

## `overview.md`

Regenerate it whenever a source model changes. Show only fields available at
the current gate:

1. phase and explicit strategy/plan approval state from metadata;
2. the thesis copied exactly from `strategy.md`;
3. the Now objective and rows copied exactly from `action-plan.csv`;
4. asset ID, name, status, and linked Action ID copied exactly from
   `assets.csv`, grouping `Draft` and `Final` as current assets and
   `Superseded` as asset history;
5. from the latest weekly row: `This Week`, `What Matters`, `APOP Changes`,
   resolved priority IDs, and `One Thing Not To Do`.

Do not create summaries such as “main unknown,” rewrite action wording, or
infer a proof that does not exist in a source model.

Recognize these gates separately:

- intake pending;
- intake complete;
- strategy proposed;
- strategy agreed, no plan;
- plan proposed, execution locked;
- plan agreed, execution active;
- unknown approval metadata, clearly labeled rather than guessed.

## Optional `dashboard.html`

Create it only on explicit request or `calm status --html`. It is a static HTML
rendering of the regenerated overview with:

- HTML escaping for every founder-controlled value;
- a restrictive Content Security Policy;
- no server, account, authentication, database, CRM, analytics, telemetry, or
  synchronization;
- no remote script, font, image, stylesheet, or other network resource;
- no editable state.

Deleting either derived view loses no source information.
