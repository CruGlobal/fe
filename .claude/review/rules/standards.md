# Standards — Checklist

Generic baseline. Every item here is mandatory unless the repo's own conventions override it —
`/agent-review:init` appends the repo-specific checklist, and both layers are kept.

This is an explicit checklist: report compliance for each **bold group below** in the
`### Rule Checklist Results` section of your output (✅ / ⚠️ / ❌ / N/A), and raise anything
non-compliant as a finding at the severity its impact warrants.

**Exports & Naming**

- [ ] Export style matches the repo's convention (named vs default) — don't introduce a second style
- [ ] File and directory naming follows the existing convention (casing, suffixes, special filenames
      the framework requires)
- [ ] Public identifiers are descriptive; abbreviations match ones already used in the codebase
- [ ] Imports use the repo's alias/path convention rather than deep relative traversal

**Types**

- [ ] No escape hatches that disable type checking in new code (untyped `any`-equivalents, suppression
      comments) without an inline comment explaining why
- [ ] No non-null/force-unwrap assertions on values that can legitimately be absent — check explicitly
- [ ] Types are derived from a single source of truth rather than hand-duplicated alongside it

**Input & Forms**

- [ ] User input is validated with the repo's established validation approach, not ad-hoc checks
- [ ] Every client-side validation rule has a server-side counterpart
- [ ] Submit/confirm actions are disabled or guarded while in flight so they can't double-fire

**Data**

- [ ] Writes invalidate or update the cached data they affect
- [ ] Cache/query keys are stable, descriptive, and scoped to the resource and its inputs
- [ ] Queries rely on the real authorization boundary, not on a client-side filter

**Dates & Numbers**

- [ ] Date math uses the repo's chosen date library and format conventions, not ad-hoc arithmetic
- [ ] Numeric formatting and rounding happen at the display boundary, consistently

**Testing**

- [ ] Every new function, hook, and non-trivial component has a test in the repo's conventional
      location
- [ ] Tests use the repo's runner and mocking idioms
- [ ] Test code is typed as strictly as production code

**Code Quality**

- [ ] Lint, type-check, and format commands pass
- [ ] No debug output left behind (console/print statements, debuggers, `TODO` without a tracked issue
      reference)
- [ ] No unused imports, variables, or dead parameters
- [ ] No commented-out code blocks (delete, don't comment)
- [ ] No empty catch blocks that swallow errors silently
- [ ] Package-manager usage matches the repo's lockfile (don't mix tools)

<!-- init: extend this file with repo-specific focus areas and evidence links -->

## fe (Form Engine): repo-specific checklist

Report each bold group below in `### Rule Checklist Results` too. For the generic groups: **Types**
is N/A (plain Ruby and jQuery, no type checker); "imports use the alias convention" and "package
manager matches the lockfile" mean Bundler only; there is no linter, type checker, formatter, or
CI, so the spec suite is the gate.

**Names and file layout**

- [ ] Everything lives under `Fe::`: `app/models/fe/`, `app/controllers/fe/`,
      `app/controllers/fe/admin/` (`Fe::Admin::`), `app/helpers/fe/`, `app/jobs/fe/`,
      `app/mailers/fe/`, views in `app/views/fe/<controller>/`, library code in `lib/fe/`
- [ ] Concerns are named `<Thing>Concern` in `app/controllers/concerns/fe/<thing>_concern.rb` or
      `app/models/concerns/fe/<thing>_concern.rb`. The filename must end in `_concern.rb`: both
      `lib/fe/engine.rb` and `spec/rails_helper.rb` load concerns with an `app/**/*_concern.rb` glob
- [ ] Module style matches the neighbors: `module Fe::AnswerPagesControllerConcern` for controller
      concerns, nested `module Fe` / `module AnswerSheetConcern` for model concerns, and
      `class Fe::AnswerSheetsController < ApplicationController` for controllers
- [ ] A new element type brings all its parts: the class in `app/models/fe/`; STI `kind` stored as
      the full class name (`'Fe::TextField'`); a partial at
      `app/views/fe/questions/fe/_<underscored>.html.erb` (from `Fe::Element#ptemplate`); a builder
      panel at `app/views/fe/admin/panels/_prop_<underscored>.html.erb`; a default style in
      `Fe::Element#set_defaults`; a factory in `spec/factories/elements.rb`; and an entry in the
      `Fe.element_types` default list (2.4+)

**Concern pattern**

- [ ] An `included do` block is wrapped like the others:

      ```ruby
      begin
        included do
          before_action :get_answer_sheet, only: [:show, :edit]
        end
      rescue ActiveSupport::Concern::MultipleIncludedBlocks
      end
      ```

      Concern files can load more than once (the engine's `to_prepare` glob, `spec/rails_helper.rb`,
      reloads), and a second `included` block raises without the guard
- [ ] Methods meant for hosts to override have a safe default and a one-line comment saying so
      (`get_filter`, `extra_element_params`)

**Tables and stored data**

- [ ] Models take their table from the prefix:
      `self.table_name = self.table_name.sub('fe_', Fe.table_name_prefix)` or
      `"#{Fe.table_name_prefix}references"`. No literal `fe_` table names in models, migrations, or SQL
- [ ] SQL fragments name tables through the model: `"#{Fe::Element.table_name}.kind"`,
      `Fe::PageElement.table_name + '.position'`, or `pf = Fe.table_name_prefix` as in
      `AnswerSheetsControllerConcern#show`
- [ ] `serialize` uses the version branch: `serialize col, Hash` when
      `Rails.gem_version < "7.1.0"`, otherwise `serialize col, type: Hash, coder: YAML`
- [ ] Migrations subclass `ActiveRecord::Migration[4.2]` like the rest (the version must be one the
      gemspec's Rails 5.0.7 floor knows) and use `Fe::<Model>.table_name`. The unversioned
      `20181218201130_increase_slug_length.rb` is not one to copy

**Config and host hooks**

- [ ] New settings are `mattr_accessor`s in `lib/fe.rb` (access settings in
      `lib/fe/access_control.rb`), with the default set on the next line and documented in
      `README.md`
- [ ] Boolean settings get a `?` reader (`def self.verbose_logging?; !!verbose_logging; end`), and
      callers use it
- [ ] Host filters are skipped with `raise: false` (as in `Fe::ReferencesController`), since a host
      may not define them
- [ ] Access checks use `fe_authorize_answer_sheet!` / `fe_require_admin!`, and denials go through
      `fe_deny!`; no hand-rolled `head :forbidden` or redirects for access

**Params and responses**

- [ ] Params are permitted in a private `*_params` method (`element_params`, `page_params`,
      `email_template_params`); translation hashes as `{label_translations: Fe::LANGUAGES.keys}`
- [ ] No new `permit!`, and no `constantize` on params (use `Fe.answer_sheet_class_for` /
      `Fe.element_class_for`)
- [ ] Builder and answer-page actions answer `format.js` with a matching `<action>.js.erb` (and
      `error.js.erb` on failure), following the controller's existing `respond_to` shape

**Logging and leftovers**

- [ ] Server debug logging is tagged and gated:
      `Rails.logger.info("[fe concurrency] ...") if Fe.verbose_logging?`. JS uses
      `fe.debugLog('[fe ...] ...')`, which prints only when `fe._verboseLogging` is set
- [ ] No new `puts`, `byebug`, `binding.pry`, or bare `console.log`. Older import code
      (`Fe::Element.create_from_import`, `Fe::Page.create_from_import`,
      `Fe::QuestionSheet.create_from_yaml`) has some; don't add to it
- [ ] No new commented-out code or `=begin`/`=end` blocks (the ones in `Fe::ReferenceSheet` and
      `Fe::Question` are not a pattern)
- [ ] Comments state what the code can't: an invariant, a hazard, or a host contract (see the
      comments in `Fe::AccessControlConcern`). Bug history and ticket or help-desk numbers go in the
      commit and PR text, not in `app/` or `lib/`; specs may name the regression they pin

**JavaScript (`app/assets/javascripts/fe/`)**

- [ ] Answer-page code lives on `fe.pageHandler` in `fe.public.nojquery.js.erb`; builder code in
      `fe.admin.js`; shared setup (`setUpCalendars`) in `fe.common.js.erb`
- [ ] jQuery style; `let`/`const` in new code; `if` bodies in braces on their own lines, not
      one-liners
- [ ] Page setup binds on `$(document).on('ready turbo:load', ...)` and guards against binding twice
      (`window.feEventHandlersBound`); cleanup before Turbo caches a page goes in a
      `turbo:before-cache` listener
- [ ] Events meant for hosts are triggered on `document` with an `fe` prefix (`fePageLoaded`,
      `fePageSaved`)

**Version and README**

- [ ] A PR that changes shipped code (`app/`, `lib/`, `config/`, `db/`, `spec/factories/`) bumps
      `Fe::VERSION` in `lib/fe/version.rb`: patch for fixes, minor for new features or anything a
      host must act on (2.3.0 allowed Rails 8; 2.4.0 made access deny-by-default)
- [ ] After a bump, `bundle install` brings the `fe (x.y.z)` line under `PATH` in `Gemfile.lock` up to
      match (it has lagged before)
- [ ] `README.md`'s Changelog gets a version entry for anything a host would notice, and a change a
      host must act on gets an "Upgrading to X.Y" section with the exact hook, setting, or rake task
      (the 2.4 "Access control" and "Upgrading to 2.4" sections are the model)

**Tests and commands**

- [ ] Specs mirror the code path and end in `_spec.rb` (`app/models/fe/element.rb` goes with
      `spec/models/fe/element_spec.rb`; `lib/fe/access_control.rb` with
      `spec/lib/fe/access_control_spec.rb`). The Rakefile runs only `spec/**/*_spec.rb`
- [ ] Commands, from the Rakefile:
      - `bundle exec rake setup_db`: drop, create, and migrate the dummy test database (SQLite by
        default; `DB=mysql` or `DB=postgresql` picks another adapter from
        `spec/dummy/config/database.yml`)
      - `bundle exec rake spec`: the whole suite, with coverage
      - `bundle exec rspec spec/models/fe/element_spec.rb:42`: one file or example
- [ ] Ruby `3.3.10` (`.ruby-version`, `.tool-versions`). Gems only the dummy app needs go in
      `Gemfile` (Rails `~> 8.0.0` there); fe's runtime needs go in `fe.gemspec`

**Mined from merged PR history**

- When a PR fixes a class of bug (nested quotes, an escaped path, a selector, a function whose signature changed), it fixes every occurrence in the engine. Grep the views and JS for the pattern and check every caller.
  <!-- evidence: PR #103, #104, #105, #137, #138, #149, #150, #155, #156, #161, #164 -->
- In ERB, don't nest unescaped double quotes inside a double-quoted attribute or Ruby string (inline `onclick` handlers, SQL fragments). Use single quotes inside, or `%|...|` outside.
  <!-- evidence: PR #137, #138, #139 -->
- A path helper interpolated into an inline `<script>` in an `.erb` view gets HTML-escaped (`&amp;` in query strings). Use `j`/`to_json`, or `html_safe` on purpose, at every occurrence in the file.
  <!-- evidence: PR #161, #164 -->
- Build HTML class strings with explicit spacing so appended classes (`validation_class`) don't run together, and keep tabs and whitespace-only churn out of the diff.
  <!-- evidence: PR #149, #151, #154 -->
- AI: in an AI-authored diff, check each claim in the PR body against the code on every call path ("no-op without the widget", "safe for host apps"). Claims like these were wrong or only half true in several PRs.
  <!-- evidence: PR #166, #168, #169, #170 -->
