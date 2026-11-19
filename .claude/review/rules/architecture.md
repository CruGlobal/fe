# Architecture — Focus Areas

Generic baseline. `/agent-review:init` appends the repo-specific concerns; keep both.

**Layering & boundaries**

- Business logic lives in testable modules, not inline in entry points (route/page/controller/CLI
  handlers). Entry points compose and delegate
- Server-only code stays out of code paths that ship to a client or untrusted runtime
- Look for: domain math embedded in view code; a module reaching across layers it shouldn't know
  about; new circular dependencies

**Placement & structure**

- New files land where the existing convention says they belong; shared code goes to the shared
  location only when it is genuinely used by more than one feature
- Look for: one-off code dropped into a "shared"/"common"/"utils" bucket; parallel structures that
  duplicate an existing module instead of extending it; new top-level directories

**Pattern consistency**

- The change should look like the code around it. Deviating is fine when the existing pattern is
  what's being fixed — but then it should be fixed consistently, not forked
- Look for: a second way of doing something the codebase already does one way (data fetching, error
  handling, configuration, logging); framework features reimplemented by hand

**State & data flow**

- Cached/derived state has a clear owner, and writes invalidate or update what they affect
- Look for: the same state maintained in two places; refetching in an effect what a cache already
  owns; values threaded through three or more layers that would be better read closer to use

**Effects & lifecycle**

- Look for: effects whose dependency list omits referenced values (stale closures); work in an
  effect that belongs in an event handler or a derived value; subscriptions and timers without
  cleanup

**Concurrency & performance shape**

- Look for: sequential awaits on independent work that could run concurrently; N+1 query patterns;
  unbounded loops over remote calls; work done per-item that could be batched

**Error handling & resilience**

- Look for: swallowed errors (empty catch, error logged and ignored); failures that leave state
  half-written; missing error/loading boundaries on user-facing surfaces; retries without backoff or
  idempotency

**Technical debt**

- Weigh debt added against debt removed. A refactor that only moves code without improving clarity
  is neutral, not positive. When a convention is ambiguous, raise it as a question rather than a
  blocking finding

<!-- init: extend this file with repo-specific focus areas and evidence links -->

## fe (Form Engine): repo-specific focus

**Thin controllers, logic in concerns**

- `Fe::AnswerSheetsController`, `Fe::AnswerPagesController`, and
  `Fe::Admin::QuestionSheetsController` are two-line classes that include a concern from
  `app/controllers/concerns/fe/`. Hosts replace these classes and include the concern, so new
  actions, callbacks, and helpers for them go in the concern. The other controllers
  (`Fe::Admin::ElementsController`, `QuestionPagesController`, `EmailTemplatesController`,
  `Fe::SubmitPagesController`, `ReferencePagesController`, `ReferencesController`,
  `ReferenceSheetsController`) keep their logic in the class
- Model concerns in `app/models/concerns/fe/` exist so a host's own class can share fe's behavior:
  `Fe::AnswerSheetConcern` is included by `Fe::AnswerSheet`, `Fe::ReferenceSheet`, and host answer
  sheet classes named in `Fe.answer_sheet_class`
- Look for: logic added to a two-line shell instead of its concern; behavior moved between a class
  and its concern (it changes what a replacement controller gets; see `host-compat`); a callback that
  assumes another one ran first (hosts re-declare callbacks, which moves them to the end of the chain)

**Engine-to-host boundary**

- `isolate_namespace` is off on purpose (`lib/fe/engine.rb`). fe controllers inherit the host's
  `ApplicationController`, so host filters run on fe actions, and fe opts out of a host filter with
  `skip_before_action <name>, raise: false`
- fe calls host-provided methods: the access hooks, `current_user`, `current_person`,
  `next_custom_page(application, page_name)`, and `completed?` / `submitted?` on the answer sheet
  class (`Fe::Application` raises until the host defines them)
- Look for: a new call into the host with no README entry and no `respond_to?` fallback or boot
  check; fe code that reaches into one host's own models or columns; behavior that lives only in a
  view (hosts override `app/views/fe/**`, so anything that must always run belongs in the controller
  or JS, the way `inject_answers_digest_script` adds the digest in an `after_action`)

**The answer save path**

- `Fe::AnswerPagesControllerConcern#update` loads the page's answers once (`load_answers_for_page`)
  and passes them to `answers_digest(page, page_answers)` and to `Fe::QuestionSet#post`, which hands
  each question its slice through `Fe::Question#set_response(values, answer_sheet, cached_answers)`.
  `Fe::QuestionSet#save` writes inside one `AnswerSheet.transaction`
- Look for: per-question queries added on that path instead of reading `page_answers`; answer writes
  outside the transaction; a new rejection status from `update` (today 409 for a stale digest, 422
  for a blank-form overwrite) without a matching branch in `savePage`'s `error:` handler, which
  otherwise counts it as a failed save and reloads the page after three

**Derived state and who owns it**

- `Fe::Page#all_element_ids` is a stored, comma-separated list of every element on the page,
  including grid and choice-field children. `Fe::Element`'s `after_save`, `Fe::PageElement`'s
  `after_destroy`, and `Fe::Page#copy_to` rebuild it through `rebuild_all_element_ids`
- `Fe::Page` memoizes `hidden?` and `all_hidden_elements` per instance;
  `Fe::Question#save_response` clears the latter. `Fe::Element#visibility_affecting_element_ids` and
  `Fe::AnswerSheetConcern#question_sheets_all_reference_elements` use `Rails.cache` keys built from
  the most recently updated `Fe::Element`. `Fe::ReferenceSheet#update_visible` compares
  `visibility_cache_key`, refreshed by `Fe::UpdateReferenceSheetVisibilityJob`
- Look for: element or page structure changed through `update_column`, `update_all`, `delete`, or
  raw SQL (that skips the rebuild and leaves `updated_at` alone, so the `Rails.cache` keys never
  change); a new nesting relationship that `Fe::Element#all_elements` doesn't walk; visibility worked
  out somewhere other than `Fe::Page#hidden?` / `Fe::Element#hidden?`

**Don't grow the duplicates**

- `Fe::ReferencesController` and `Fe::ReferenceSheetsController` overlap (each has a TODO saying so).
  Extend one; don't add a third reference path
- `Fe::AnswerPagesPresenter` builds the page list and next/previous links for every controller that
  renders answer pages; reuse it instead of building page lists in a controller or view

**Rails range**

- The gemspec allows Rails `>= 5.0.7, < 9`, but the dummy app runs only Rails 8.0. Version-specific
  code branches on `Rails.gem_version < "7.1.0"` (the `serialize` calls in `Fe::Element`,
  `Fe::Page`, `Fe::QuestionSheet`, `Fe::ChoiceFieldConcern`). Look for: an API newer than the floor
  used with no branch and no gemspec change
