# Host App Compatibility: Focus Areas

fe has no users of its own. Every change lands in host apps that override its methods, include its
concerns, skip its callbacks by name, copy its migrations and JavaScript, load its factories into
their test suites, and set its config. The dummy app in `spec/dummy/` is one stand-in host; passing
specs there doesn't show a real host still works. This lane asks of every change: what does a host
have to do now, and will it find out before production?

A change that breaks a host quietly (wrong data, an open action, a skipped check) is a blocker. A
change that breaks a host loudly, at boot or in its test suite, is acceptable when it ships with a
version bump and an "Upgrading to X.Y" note in `README.md`; without them it is a finding.

**Methods hosts override or call**

- Controller methods hosts override: `get_answer_sheet`, `get_filter`, `answer_sheet_type`,
  `extra_element_params`, `use_existing` / `copy_existing` (the in-code NOTE invites it), and whole
  actions in subclasses. Model methods: `Fe::Question#locked?(params, answer_sheet, presenter,
  current_person)`, `Fe::Element#ptemplate`, `Fe::Application#completed?` / `#submitted?` (they
  raise until a host defines them)
- Host methods fe calls: `fe_can_use_answer_sheet?(answer_sheet, access)`, `fe_admin?`, optional
  `fe_access_denied(kind)` (2.4+), `current_user`, `current_person`,
  `next_custom_page(application, page_name)`
- Methods hosts call: `Fe::Notifier.notification`, `Fe::ReferenceSheet#send_invite(host)`,
  `answers_digest`, `percent_complete`, `completely_filled_out?`, `Fe::QuestionSheet#duplicate`,
  `export_to_yaml` / `create_from_yaml`, `Fe.access_key_matches?`
- Look for: a renamed or removed method from these lists; changed arity or argument order (host
  overrides that call `super` with the old arguments, or old-signature overrides fe now calls with
  new ones); a new required host method with no `respond_to?` fallback, boot check entry, and README
  section; behavior moved out of an overridable method into one hosts don't override, so their
  override quietly stops mattering

**Callbacks hosts skip, re-declare, or rely on**

- Names in use: `get_answer_sheet`, `fe_authorize_answer_sheet!`, `fe_require_admin!`,
  `fe_require_admin_for_own_action!`, `set_quiet_reference_email_change`, `edit_only` (prepended),
  `setup`, `get_page`, `get_sheet`, `get_question_sheet`, the `inject_answers_digest_script`
  `after_action`, and `set_locale` from `Fe::ApplicationControllerConcern`
- Hosts `skip_before_action` these by name and re-declare them, which moves them to the end of the
  chain
- Look for: a renamed callback (a host's `skip_before_action :old_name` raises at load, or with
  `raise: false` silently stops skipping); a changed `only:` / `except:` list; an access check that
  depends on running after another callback (fe's gate must load what it needs itself, as
  `fe_authorize_answer_sheet!` does); a check moved between a controller class and its concern (per
  the README's "Changing fe's controllers", a host that replaces the class keeps only what the
  concern carries)

**Concerns and decorators**

- Hosts replace `Fe::AnswerSheetsController`, `Fe::AnswerPagesController`, and
  `Fe::Admin::QuestionSheetsController` with their own class that includes the matching concern;
  include `Fe::AnswerSheetConcern` in their own answer sheet class; include
  `Fe::ApplicationControllerConcern` in their `ApplicationController`; and `class_eval` fe classes
  from `app/decorators/**/*_decorator.rb`, loaded in `config.to_prepare` in `lib/fe/engine.rb`
- Look for: a concern that starts depending on a method or instance variable only fe's own class
  sets; a new `included do` block without the `MultipleIncludedBlocks` guard; a renamed or moved
  concern module; a change to the `to_prepare` load order or the decorator glob

**Config defaults**

- In `lib/fe.rb` (and `lib/fe/access_control.rb` from 2.4), `table_name_prefix` and
  `answer_sheet_class` use `||=` so a host can set them first. The rest (`from_email`,
  `never_reuse_elements`, `date_format`, `bootstrap`, `verbose_logging`, `verbose_js_logging`,
  `md5_overwrite_protection`, `blank_overwrite_protection`, `answer_sheet_types`, `element_types`,
  `verify_access_hooks_on_boot`) use `=` and are the value for every host that never sets them.
  `Fe::LANGUAGES` is a constant hosts can't extend
- Some config is read once at load: `self.table_name` from `Fe.table_name_prefix`;
  `Fe::ReferenceSheet`'s `belongs_to :applicant_answer_sheet, class_name: "::#{Fe.answer_sheet_class}"`;
  `Fe.date_format` and `Fe.bootstrap` in the `.js.erb` assets at precompile
- Look for: a changed default (it changes behavior for every host relying on it: changelog line,
  plus an upgrade note if hosts must act); `||=` switched to `=` or back; a new setting read at class
  load that hosts would set in `to_prepare` (too late); a `nil` default that hosts will `+=` onto
  (the README warns about `Fe.answer_sheet_types`); a new setting with no README entry

**Routes and URLs**

- `config/routes.rb` draws into `Rails.application.routes` (no `isolate_namespace`, no mount), so
  fe's route names (`edit_fe_answer_sheet_path`, `fe_admin_question_sheets_path`,
  `edit_fe_reference_sheet_url`, and the rest) are host route helpers, and fe views can call host
  helpers. Reference invite emails carry `edit_fe_reference_sheet_url(sheet, a: access_key)`; those
  links sit in inboxes after fe changes
- Submit page, reference page, and references actions have no routes in fe; hosts draw them
- Look for: a changed path, route name, or param name (`:a`, `:answer_sheet_type`,
  `:answer_sheet_id`); a removed route; a new route name likely to collide with a host's; a new
  action hosts must route themselves with no README note

**Views hosts override**

- Hosts override partials under `app/views/fe/**` by path, and the `fe/application` and `fe/fe_admin`
  layouts. Element partials come from `Fe::Element#ptemplate` (`fe/questions/fe/_text_field.html.erb`)
- Look for: a renamed partial or layout; new required locals; instance variables views rely on
  (`@answer_sheet`, `@presenter`, `@page`, `@elements`, `@question_sheet`) renamed or no longer set;
  a new behavior that only works on fe's own view (put it in the controller or an `after_action`, as
  `inject_answers_digest_script` does)

**Installed migrations**

- Hosts copy `db/migrate/*` with `rake fe_engine:install:migrations` and run them on their own
  databases (MySQL, PostgreSQL, or SQLite), with their own `Fe.table_name_prefix` and answer sheet
  class (`20150714220730_add_locale_to_answer_sheet.rb` alters
  `Fe.answer_sheet_class.constantize.table_name`)
- Look for: an edit to a migration that already shipped (hosts ran their copy; ship a new
  migration); a missing `ActiveRecord::Migration[4.2]`-style version
  (`20181218201130_increase_slug_length.rb` has none, which Rails 5.1+ rejects); a literal `fe_` table
  name; a dropped or renamed column hosts may read; a new migration with no copy in
  `spec/dummy/db/migrate/` (named `<timestamp>_<name>.fe_engine.rb`) and no
  `spec/dummy/db/schema.rb` update; a schema change with no upgrade note telling hosts to install
  migrations

**Shipped factories**

- `fe.gemspec` ships `spec/factories/**`, and the `model_core.factories` initializer in
  `lib/fe/engine.rb` adds that path to every host's `FactoryBot.definition_file_paths`. Factory names
  are global in a host's suite: `:answer_sheet`, `:application`, `:page`, `:element`, `:answer`,
  `:question_sheet`, `:reference_sheet`, `:paragraph`, `:section`, and the rest
- Look for: a renamed or removed factory or attribute; a new factory with a generic name a host
  likely already has (FactoryBot raises `DuplicateDefinitionError` and the host suite won't load); a
  factory that needs a class only the dummy app has (`dummy_applications.rb`, `dummy_people.rb`,
  `dummy_users.rb` already assume `Application`, `Person`, `User`)

**Vendored JavaScript and the JS/server protocol**

- Some hosts vendor copies of `app/assets/javascripts/fe/*.js`; they get changes only when they copy
  again, so the server must keep working with older JS. The autosave protocol: every page load and
  save sends `answer_sheet_type`; saves send `answers_digest` and `authenticity_token`; responses
  carry `X-Answers-Digest` and `X-Fe-Verbose-Logging`; the server answers 409 for a stale digest and
  422 for a blank-form overwrite. `AnswerPagesControllerConcern#update` already accepts a save with
  no `answers_digest` from older JS
- Host-facing JS API: `feShowPage`, `fePageLoaded`, `fePageSaved`, `fePageValid`, `fePageInvalid`
  events on `document`; the `no-validation` and `no-ongoing-validation` form classes; `fe.pageHandler`
- Look for: a server change that rejects what older JS still sends; a renamed or removed event,
  class, param, or header; a JS change with no README note telling hosts that vendor it to copy it
  again; a new asset that needs adding to the `fe.asset_precompile_paths` initializer

**Rails, Ruby, and dependency range**

- `fe.gemspec`: `rails >= 5.0.7, < 9` plus runtime deps (`acts_as_list`, `aasm >= 4, < 6`,
  `carmen ~> 0.2.12`, `gettext_i18n_rails`, `paper_trail >= 10`, `libxml-ruby`, `liquid`, `sass`,
  `jquery-rails`, `jquery-ui-rails`, `validates_email_format_of`). `Gemfile` and `Gemfile.lock` pin
  the dummy app only (Rails `~> 8.0.0`) and never reach hosts
- Look for: a new runtime dep in the gemspec (it lands in every host's bundle); a raised floor or
  lowered ceiling (version bump and upgrade note); an API newer than the floor used without a
  `Rails.gem_version` branch; a gem added to `Gemfile` that fe's runtime code needs (it belongs in
  the gemspec)

**Version and upgrade notes**

- `Fe::VERSION` lives in `lib/fe/version.rb`. Patch for fixes hosts don't act on; minor for a new
  contract or anything a host must act on (2.4.0 made access deny-by-default). `README.md`'s
  Changelog gets a version entry for anything a host would notice, and an "Upgrading to X.Y" section
  lists the exact steps for anything a host must do

**Checklist**

- [ ] No overridden or called method, callback name, route, param, partial, factory, JS event, or
      config default changed without an upgrade note
- [ ] New host obligations are documented, and either enforced at boot or fail closed
- [ ] Shipped migrations untouched; new ones versioned, prefix-safe, and mirrored in the dummy app
- [ ] The server still accepts what older vendored JS sends
- [ ] Gemspec range and runtime deps unchanged, or changed with a bump and a note
- [ ] `lib/fe/version.rb` bumped to match the size of the change

**Mined from merged PR history**

- Bump `Fe::VERSION` in `lib/fe/version.rb` in any PR that changes shipped code (`app/`, `lib/`, `config/`, `db/`, the JS). Hosts only get a change through a new release.
  <!-- evidence: PR #148, #149, #150, #151, #152, #154, #155, #156, #158, #159, #160, #161, #163, #164, #165, #166, #167, #169, #170 -->
- Gate Rails-version branches on `Rails.gem_version` against the release that added the API (`"7.1.0"` for `serialize ..., type:, coder:`), never `Rails::VERSION::MAJOR`, and change every model that shares the pattern in the same PR.
  <!-- evidence: PR #152, #154, #158 -->
- Use `&.` or `try` on objects a host supplies (the presenter, `current_person`, optional columns like `css_class`). Hosts pass nil or don't define them.
  <!-- evidence: PR #148, #150, #151 -->
- Engine JS must survive Turbo and jQuery 3: guard `ready`/`turbo:load` handlers against binding twice (`feEventHandlersBound`), tear widgets down on `turbo:before-cache`, put code both bundles need in `fe.common.js.erb`, and mark links fe loads itself `data-turbo="false"`.
  <!-- evidence: PR #143, #147, #148, #149, #155, #156, #159, #165, #169 -->
- Engine JS declares every variable (`let`/`const`), adds no generic globals (hang intentional ones on `window.fe`), and uses only the jQuery API the engine ships (no Prototype helpers like `$F`).
  <!-- evidence: PR #138, #139, #143, #148, #154 -->
- A change to the gemspec's Rails range, a Gemfile pin, or `.ruby-version` states why and shows the suite passing on the newly allowed versions. No `ruby` directive and no speculative caps.
  <!-- evidence: PR #102, #110, #115, #116, #136, #144, #146, #147, #160, #168 -->
