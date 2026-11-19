# Data Integrity — Focus Areas

Generic baseline. This is where domain-specific data invariants belong once `/agent-review:init`
appends them; keep both.

**Access scoping at the data layer**

- Every query and mutation is scoped to the authenticated user/tenant/household. New tables,
  columns, or collections need matching access policies
- Look for: policy changes that widen a `where`/`using`/`with check` clause; queries filtered only
  in application code where a shared or admin connection bypasses the policy

**Validation at external boundaries**

- Payloads from HTTP requests, webhooks, queues, and third-party APIs are parsed against an explicit
  schema before use
- Look for: external JSON consumed without validation; fields read off an untyped/`any` value; types
  that have drifted from the actual storage shape

**Cache correctness**

- Every write that changes displayed data invalidates or updates the cache entry that serves it
- Look for: mutations with no invalidation; cache keys that omit an input which changes the result
  (filter, tenant/account id, date range), which serves stale or cross-scope data; optimistic
  updates that don't match the server's response shape or don't roll back on error

**Idempotency & retries**

- Sync jobs, webhook handlers, and queue consumers must not double-apply work on retry or replay
- Look for: blind inserts where an upsert on a stable external id is needed; no dedupe key; partial
  writes with no transaction or compensating action

**Numeric precision**

- Values where exactness matters (money, quantities, percentages) must not accumulate floating-point
  drift; round at the display boundary, never mid-calculation
- Look for: repeated rounding inside a pipeline; mixing units or currencies without conversion;
  aggregate totals recomputed differently in two places

**Date & time handling**

- Look for: non-deterministic "now" inside calculations (makes behavior untestable and
  timezone-fragile); naive local-time arithmetic across DST; inconsistent serialization formats
  across boundaries

**Null, undefined, and partial writes**

- An omitted field, an explicit null, and an empty string are three different writes. Be intentional
- Look for: whole objects spread into an insert/update without an explicit field allowlist; defaults
  applied in one code path but not another

**Aggregation over partial data**

- Look for: totals summed client-side over a paginated or filtered subset, silently ignoring rows
  beyond the page — prefer a server-computed aggregate

<!-- init: extend this file with repo-specific focus areas and evidence links -->

## fe (Form Engine): repo-specific invariants

**Answers belong to one sheet**

- `Fe::AnswerSheetConcern#answers` is limited to element ids on the sheet's question sheets' pages
  (from `Fe::Page#all_element_ids`) and returns `where('false')` when there are none.
  `Fe::Question#check_answer_sheet_matches_set_response_answer_sheet` fails a save aimed at a
  different sheet than the one `set_response` loaded for. A reference's answers live on its
  `Fe::ReferenceSheet`, under its own `question_sheet_ref`
- Look for: answers written with an `answer_sheet_id` from params instead of the checked
  `@answer_sheet`; `Fe::Answer.where(question_id: ...)` with no `answer_sheet_id`; a reference's
  question sheet read through `AnswerSheetConcern#question_sheet` instead of `question_sheet_ref`
  (ids in the references table can collide with answer sheet ids)

**Destroys with wide reach**

- `Fe::Question has_many :sheet_answers, dependent: :destroy`: destroying a question deletes every
  answer to it on every sheet. Shared elements (`share: true`, `Fe::Element#reuseable?`,
  `Fe.never_reuse_elements`) can sit on many question sheets, so
  `Fe::Admin::ElementsController#destroy` only detaches a reusable element that is still on another
  page or `has_response?`
- `Fe::Application has_many :references, dependent: :destroy`, and each `Fe::ReferenceSheet`
  `after_destroy` emails the reference (`notify_reference_of_deletion`) if an invite went out.
  `reset_reference` destroys a reference's answers when its email changes, and
  `notify_old_reference_not_needed` emails the old address
- Look for: a new element destroy path without the `reuseable?` / `has_response?` check;
  `Fe::QuestionSheet#duplicate` or `Fe::Page#copy_to` changes that clone a shared question (its
  answers stop lining up across sheets) or share a non-question; bulk deletes or cleanup jobs that
  set off reference emails; an email-change path that resets a completed reference

**Overwrite protection**

- `answers_digest(page, cached_answers)` is an MD5 of `[question_id, id, value]` triples sorted by
  question id, then id. The query path (`pluck`) and the in-memory path (`cached_answers`) must give
  the same JSON, or every save gets a 409. The check runs only when `Fe.md5_overwrite_protection` is
  on and the client sent `answers_digest`
- `Fe.blank_overwrite_protection` rejects a save that would blank two or more non-blank
  `Fe::TextField` answers on the page
- Look for: an answer value type, ordering, or filter changed on one digest path but not the other;
  a new answer write (file upload, reference fields) that doesn't hand back a fresh
  `X-Answers-Digest`; a changed blank threshold or set of counted classes without a spec

**Stored formats**

- YAML-serialized: `label_translations`, `tip_translations`, `content_translations`,
  `rating_before_label_translations`, `rating_after_label_translations`,
  `rating_na_label_translations` (Hash) and `Fe::QuestionSheet#languages` (Array).
  `conditional_answer` holds `;`-separated values (`Fe::Element#conditional_answers`, since
  `20151021181928_switch_conditional_answer_separator_to_semicolon.rb`). `Fe::Page#all_element_ids`
  is `,`-separated text
- Look for: a separator or format change with no data migration; a serialized class other than Hash
  or Array (hosts would need to add it to `yaml_column_permitted_classes`; see the note in
  `Fe::Page`); `languages` read without dropping the blank entry the builder's multi-select posts
  (`select(&:present?)`)

**Writes that skip validations or callbacks**

- `save(validate: false)`, `update_column`, and `update_all` are used on purpose (reference contact
  fields saved from the answer page, `Fe::ReferenceSheet#update_visible`, element reordering,
  `rebuild_all_element_ids`). Look for: a new one that skips a callback something depends on
  (`rebuild_all_element_ids`, `set_conditional_element`, `update_any_previous_conditional_elements`,
  `reset_reference`)
- `Fe::Application` has `has_paper_trail on: [], ignore: [:updated_at]`, so fe writes no versions on
  its own. Look for: changes to those options (they start or stop `versions` rows in every host)

**Migrations run on host data**

- `db/migrate/*` is copied into each host and runs on its full tables, on MySQL, PostgreSQL, or
  SQLite. Table names come from the model (`Fe::Element.table_name`,
  `Fe.answer_sheet_class.constantize.table_name`) so the host's prefix and answer sheet class apply
- Look for: a data migration that loads every row through model callbacks (prefer `update_column` or
  `update_all` in batches); a literal `fe_` table name; dropping, renaming, or narrowing a column with
  no upgrade note; adapter-specific SQL

**Dates**

- `Fe::Question#set_response` parses date answers with `Date.strptime(value, '%Y-%m-%d')`,
  `Fe::QuestionSet#posted_values` builds `'%Y-%m-%d'` from month/year selects, and the date picker
  writes `Fe.date_format` (jQuery UI syntax, default `'yy-mm-dd'`). Look for: one of the three
  changed without the others. Existing model code stamps times with `Time.now`; new code uses
  `Time.current`

**Mined from merged PR history**

- Honor visibility everywhere: queries and completeness/required checks use the `visible` scope for pages, elements and references, and a page whose visibility depends on an answer bypasses the page cache. Add a spec for the hidden case.
  <!-- evidence: PR #102, #103, #112, #131 -->
- Methods called once per question while a page renders (`required?`, `validation_class`) reuse the loaded page or elements. Flag a new per-element query on the render path.
  <!-- evidence: PR #132, #133, #134 -->
- When a fix narrows a shared condition (`Question#locked?`, the lock and save paths), check the sibling paths that share it (nil presenter, AJAX edit, Save Now, pages loaded after the lock) and add a regression spec.
  <!-- evidence: PR #148, #150, #155, #156, #166, #167 -->
- Never edit a migration already in `db/migrate/`; hosts have already run it. Add a new migration.
  <!-- evidence: PR #146, #147 -->
