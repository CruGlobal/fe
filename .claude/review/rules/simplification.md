# Simplification & Reuse — Focus Areas

Generic baseline. `/agent-review:init` appends the repo-specific concerns; keep both.

This is an advisory lane. Its job is to make this diff smaller and simpler — not to restyle the
codebase, and not to propose generalizations. Report only cleanups the author can act on inside
this PR.

**Lane boundary** — neighboring lanes own the adjacent ground:

- Layering, placement, and pattern-consistency judgments belong to `architecture`
- Lint-level hygiene (unused imports, debug output, commented-out code) belongs to `standards`
- This lane owns code that need not exist: additions duplicating something the repo already has,
  abstractions with no second caller, computation the data path doesn't need, and code the PR
  adds but never exercises

**Severity cap — cleanups never block**

- Rate pure reuse/simplification/efficiency findings 1–4
- Use 5–6 only for substantial reimplementation of an existing, tested helper, or a demonstrable
  algorithmic problem on a data path that grows with users or records
- Never rate a pure cleanup ≥ 7 — the blocker machinery is for defects. The cross-cutting duty
  still applies: a real bug noticed while reading is reported at its honest severity

**Proof requirements** — every finding cites evidence the author can check, using your discovery
grep budget:

- A reuse claim names the existing helper at file:line, after you have read it and confirmed its
  semantics actually match this call site (arguments, edge cases, error behavior). A name-alike
  with different behavior is not a finding
- A duplication claim points at duplication this diff introduces; pre-existing duplication the
  change does not worsen is out of scope
- An efficiency claim names where the data comes from and why it can be large; no
  micro-optimizations, no complexity pedantry on collections that are bounded in practice
- A dependency-reuse claim cites the manifest entry for a library the repo already ships that
  does what the new code hand-rolls

**Reuse**

- Look for: a new helper, validator, formatter, or client wrapper that reimplements one that
  already exists in the repo's shared locations; a sibling file copy-pasted and lightly edited
  instead of extended; utility code hand-rolled despite an already-carried dependency that
  provides it

**Simplification**

- Look for: an abstraction with exactly one caller or one implementation (interface, base class,
  factory, registry) introduced by this diff; boolean parameters or config options no current
  caller sets; indirection added for cases that do not exist; a hand-rolled mechanism where the
  language or framework has a direct construct

**Efficiency**

- Look for: invariant work recomputed inside a loop; a query or fetch issued per item where the
  surrounding code already batches; a full-collection load used to read one row; repeated linear
  scans that a single keyed lookup structure would remove — on data that actually grows

**Dead weight**

- Look for: exports nothing imports, parameters no caller passes, branches no current input can
  reach — when this PR introduces them. Confirm with a repo-wide grep before flagging; absence
  from the diff is not absence from the codebase

**Finding budget.** Report at most 5 findings — the ones with the largest net line savings or
clearest wins. Suggestion density is what gets an advisory lane dismissed; if you found more than
5, keep the best and drop the rest silently.

<!-- init: extend this file with the repo's shared-helper locations (where utilities, validators, and formatters live — the directories to grep before accepting new ones) -->

## fe (Form Engine): where shared helpers live

Grep these before accepting a new helper:

- `lib/fe.rb`: `Fe.next_label(prefix, labels)` for "Page N" / "Untitled form N" labels;
  `Fe.verbose_logging?`, `Fe.verbose_js_logging?`
- `lib/fe/access_control.rb` (2.4+): `Fe.answer_sheet_class_for`, `Fe.element_class_for`,
  `Fe.allowed_answer_sheet_types`, `Fe.access_key_matches?`
- `lib/access_key_generator.rb`: `Fe::AccessKeyGenerator#generate_access_key`
- `app/controllers/concerns/fe/access_control_concern.rb` (2.4+): `fe_authorize_answer_sheet!`,
  `fe_require_admin!`, `fe_deny!`
- `app/helpers/fe/application_helper.rb`: `tip`, `spinner`, `link_to_function`,
  `error_messages_for`, `calendar_date_select_tag`, `flatten_hash`;
  `app/helpers/fe/answer_pages_helper.rb`: `load_page_js`, `li_page_active_if`
- `app/models/concerns/fe/answer_pages_presenter_concern.rb`: `questions_for_page`,
  `all_questions_for_page`, `questions_for_all_pages`, `active_page_link`, `prev_page`, page list
  building
- `Fe::QuestionSet` (`app/models/fe/question_set.rb`): `post`, `save`, `set_filter`
- `Fe::AnswerSheetConcern`: `answers_by_question`, `load_answers_for_page`, `answers_digest`,
  `percent_complete`, `completely_filled_out?`, `has_answer_for?`, `languages`
- `Fe::Page`: `all_elements`, `all_element_ids_arr`, `all_questions`, `questions_before_position`,
  `hidden?`, `complete?`, `copy_to`, scope `visible`
- `Fe::Element`: scopes `questions`, `shared`, `active`, `grid_kinds`, `reference_kinds`;
  `pages_on`, `all_elements`, `duplicate`, `previous_element`, `visible?` / `hidden?` / `required?`,
  `label(locale)` / `content(locale)` / `tooltip(locale)`
- `Fe::Question`: `responses`, `response`, `display_response`, `has_response?`, `set_response`,
  `save_response`
- `Fe::QuestionSheet`: `all_elements`, `questions`, `duplicate`, `export_to_yaml`, `new_with_page`
- `Fe::Notifier.notification(to, from, template_name, params)` for every email
- JS: `fe.pageHandler` (`loadPage`, `savePage`, `savePages`, `captureForm`, `validatePage`,
  `handleSaveConflict`), `fe.debugLog`, `setUpCalendars`

Repo-specific look-fors:

- Look for: a new `Fe::Answer.where(...)` lookup on the save path when `page_answers` or
  `answers_by_question` already holds the rows; a hand-written walk of the element tree instead of
  `all_elements` / `all_element_ids_arr`; another copy of the reference contact-field permit list or
  of page-list logic the presenter already has; a `respond_to?` guard around a method fe itself
  always defines (the guards around `fe_can_use_answer_sheet?`, `fe_admin?`, and
  `fe_access_denied` are on purpose: those are host methods)

**Mined from merged PR history**

- Prefer the engine's existing methods and plain Rails idioms (`elements_to_pages`, scopes, `reload`) over a hand-rolled version.
  <!-- evidence: PR #106, #110, #112 -->
- AI: flag changes the stated fix doesn't need: speculative version caps, `Gemfile.lock` churn, a committed `spec/dummy/db/fe_test.sqlite3`.
  <!-- evidence: PR #160, #168 -->
