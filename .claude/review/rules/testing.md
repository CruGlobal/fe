# Testing — Focus Areas

Generic baseline. `/agent-review:init` appends this repo's test conventions (runner, layout,
mocking idioms); keep both.

**Prefer pure-function unit tests**

- Business and domain logic should be extracted out of UI/handler code into plain functions and
  tested directly, rather than asserted through a rendered surface or an HTTP round trip
- Look for: new logic that is only reachable through a component or endpoint, with no seam to test

**Use the repo's existing test framework and idioms**

- Match the repo's test runner, assertion style, mocking helpers, and import conventions. Do not
  assume a framework, rendering harness, or helper library that the repo does not already depend on
- Look for: tests introducing a second runner or harness; imports of libraries absent from the
  manifest

**Mock at module/external boundaries**

- External services (databases, third-party APIs, mail, payments, LLMs) are mocked at the module
  boundary, not by patching global network primitives ad hoc
- Look for: real network or filesystem access in unit tests; mocks that drift from the real
  signature; over-mocking that leaves the logic under test unexercised

**Determinism**

- Time-dependent logic uses the runner's fake-timer/clock control rather than real system time.
  Random values are seeded or injected
- Look for: tests that depend on the current date, timezone, ordering of a map/set, or on another
  test having run first

**Coverage of the shape of the input**

- Every new test should exercise: empty, zero / one / many, boundary values, and at least one happy
  path
- Look for: tests that only assert the happy path; parameters whose invalid values are never tested

**Error paths**

- Validation rejections, rejected promises, timeouts, and the failure branches of domain functions
  are tested, not just success
- Look for: `catch` branches with no covering test

**Test placement and naming**

- Follow the repo's convention for where tests live and how they're named
- Test names describe the behavior asserted, not the function name alone

**Quality gates**

- The repo's test, type-check, lint, and format commands must all pass
- Look for: skipped or `.only` tests left behind; loosely-typed mocks that defeat type checking;
  assertions that can never fail (e.g. asserting on the mock's own return)

<!-- init: extend this file with repo-specific focus areas and evidence links -->

## fe (Form Engine): repo-specific conventions

**Runner and setup**

- RSpec (`rspec-rails`) with shoulda-matchers, factory_bot_rails, DatabaseCleaner (truncation,
  `use_transactional_fixtures = false`), SimpleCov, and `rails-controller-testing` (for `assigns` and
  `render_template`). Random order. `config.render_views` is on for every spec; turn it off in one
  file with `render_views false` only when the views need a host helper the dummy app lacks
- `bundle exec rake setup_db` builds the test database from `spec/dummy/db/migrate/`;
  `bundle exec rake spec` runs everything; `bundle exec rspec <path>[:line]` runs one file or example
- `rake spec` sets `SKIP_CONCERNS=true`, so `lib/fe/engine.rb` skips its concern and decorator globs
  and `spec/rails_helper.rb` loads `app/**/*_concern.rb` after SimpleCov starts. A spec that passes
  under only one of `rake spec` and plain `rspec` points at load-order trouble
- Only files ending in `_spec.rb` run (the old `spec/controllers/fe/reference_pages_controller.rb`
  never did)

**Layout and the stand-in host**

- Specs mirror `app/` and `lib/`: `spec/models/fe/`, `spec/controllers/fe/`,
  `spec/controllers/fe/admin/`, `spec/jobs/fe/`, `spec/mailers/fe/`, `spec/lib/fe/`. A cross-cutting
  behavior of one controller can get its own file with a label
  (`describe Fe::AnswerPagesController, 'optimistic concurrency'` in
  `spec/controllers/fe/optimistic_concurrency_spec.rb`)
- `spec/dummy/` plays the host: `Application < Fe::Application`, `Person < Fe::Person`, an
  `ApplicationController` whose access hooks allow everything, and `config/initializers/fe.rb` (turns
  off the boot check). Host-style decorators are `class_eval`ed in the `before(:suite)` block of
  `spec/rails_helper.rb`

**Controller spec idioms**

- `describe Fe::X, type: :controller`; `get`/`put :action, params: {...}, xhr: true` for AJAX
  actions (most builder and answer-page actions respond to `format.js`); assert with `assigns(:x)`,
  `render_template`, `have_http_status`
- fe's `config/routes.rb` doesn't route every action (submit pages, reference pages, references,
  and some reference sheet actions). Route them in the spec:

  ```ruby
  def draw_routes
    with_routing do |set|
      set.draw { get 'fe/submit_pages/:application_id/edit' => 'fe/submit_pages#edit' }
      self.routes = set
      yield
    end
  end
  ```

- To test refusal, stub the host hook per example:
  `allow(controller).to receive(:fe_can_use_answer_sheet?).and_return(false)` or
  `allow(controller).to receive(:fe_admin?).and_return(false)`; check arguments with
  `expect(controller).to receive(:fe_can_use_answer_sheet?).with(answer_sheet, :look)`. Act like a
  host subclass with an anonymous controller:
  `controller(Fe::AnswerSheetsController) { before_action :get_answer_sheet }`
- Jobs use the `:test` adapter; assert with
  `have_enqueued_job(Fe::UpdateReferenceSheetVisibilityJob)`

**Factories**

- Use the shipped factories in `spec/factories/`: `create(:answer_sheet)` (an `Fe::Application`),
  `:question_sheet`, `:question_sheet_with_pages`, `:page`, `:page_element`,
  `:answer_sheet_question_sheet`, `:text_field_element` and the other `*_element` factories,
  `:reference_sheet`, `:reference_question`, `:fe_person`
- Put elements on a page with `create(:page_element, element: element, page: page)` (or
  `page.elements << element`) and tie the sheet to the form with
  `create(:answer_sheet_question_sheet, answer_sheet: answer_sheet, question_sheet: question_sheet)`;
  without that, `answers` scopes to nothing. Call `page.rebuild_all_element_ids` when a spec builds
  structure in a way that skips the callbacks
- These factories ship to host apps (naming is a `host-compat` concern), so a helper only one spec
  needs belongs in that spec, not in `spec/factories/`

**Assertions that can't fail, and leaks**

- `it { expect belong_to :question }` (52 of these in `spec/models/fe/`) passes no matter what:
  `expect` with no `.to` asserts nothing. New shoulda lines use
  `it { is_expected.to belong_to(:question) }`; don't copy the old form
- A spec that sets an `Fe.*` setting resets it in `after` (`after { Fe.answer_sheet_types = nil }`):
  `mattr_accessor` state outlives the example and the order is random
- No time helpers are set up. Include `ActiveSupport::Testing::TimeHelpers` and use `travel_to`
  rather than comparing against `Time.now`

**What needs a spec here**

- Access control: allowed, refused (403, and a `fe_access_denied` redirect), and hook missing, for
  each new action or controller
- The save path: each rejection branch (409 stale digest, 422 blank form) and its allowed twin
- Schema: the dummy schema (`spec/dummy/db/schema.rb`) stops at `2018_11_08_201746` and lacks the
  columns from `20160805221415_add_rating_extra_labels.rb` and the 128-character slug from
  `20181218201130_increase_slug_length.rb`. A spec that touches those needs the dummy migration and
  schema brought up to date in the same PR
- JS in `app/assets/javascripts/fe/` has no automated tests; the PR should say how it was checked by
  hand (autosave, the conflict dialog, a Turbo visit and Back)

**Mined from merged PR history**

- A fix to model or controller logic adds a spec for the case that failed.
  <!-- evidence: PR #116, #128, #148, #150 -->
- A JS change (page handler, autosave, upload, submit blocking, locking) comes with a spec or a written manual test plan that covers saving, Save Now, the first page, and a Turbo visit.
  <!-- evidence: PR #103, #104, #105, #106, #107, #148, #154, #159, #161, #164, #165, #169 -->
