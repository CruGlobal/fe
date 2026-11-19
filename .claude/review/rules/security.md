# Security — Focus Areas

Generic baseline. `/agent-review:init` appends the repo-specific concerns; keep both.

**Authentication & authorization boundaries**

- Every server endpoint, background job, and privileged action independently verifies the caller's
  identity — never trusts a user id, tenant id, or role passed in from the client
- Authorization is enforced at the data layer (row/tenant scoping, ACL check), not only by hiding UI
- Look for: endpoints added without a session/permission check; ownership checks that compare
  against client-supplied identifiers; policy changes that widen who can read or write a record

**Privileged clients & credentials**

- Admin/service-level clients that bypass normal access control must stay server-only and must never
  be importable from browser or otherwise untrusted code
- Look for: privileged clients imported into client-side modules; secrets read in code that ships to
  the browser; credentials committed to the repo or baked into build artifacts

**Secrets exposure**

- Server-only environment variables must not be exposed through client-visible prefixes, build-time
  inlining, or error payloads
- Look for: new environment-variable references; API keys or tokens in logs, error messages, HTTP
  responses, or analytics events

**Input validation & injection**

- Untrusted input (request bodies, query params, headers, webhooks, third-party payloads, file
  uploads) is validated against an explicit schema before use
- Look for: raw string interpolation into SQL/shell/HTML/templates; parsers fed unvalidated JSON;
  client-side validation with no server-side counterpart; unbounded sizes and counts

**Cross-site and browser-surface risks**

- Look for: raw-HTML injection sinks; unsanitized user content rendered as markup; open redirects
  where a redirect target comes from a query parameter without an allowlist check; missing CSRF
  protection on state-changing requests; weakened CSP or security headers

**Session & cookie handling**

- Look for: session cookies missing `HttpOnly`/`Secure`/`SameSite`; tokens stored where scripts can
  read them; sessions that are not invalidated on logout, password change, or privilege change;
  long-lived or non-rotating credentials

**Webhooks & third-party integrations**

- Look for: webhook handlers that parse and act on a payload before verifying the signature against
  the raw body; missing replay protection; secrets or tokens forwarded to the client

**Supply chain & CI**

- Look for: new dependencies (who maintains them, what they pull in); CI workflow changes that widen
  permission scopes, echo secrets, or let untrusted contributors trigger privileged jobs; changes to
  the review configuration itself that weaken risk scoring or strip checks

<!-- init: extend this file with repo-specific focus areas and evidence links -->

## fe (Form Engine): repo-specific focus

fe is a public Rails engine. It never decides who a person is: host apps answer that through
hooks, and from 2.4.0 fe refuses every request until they do. A gap here ships to every host app at
once, so judge a change by what any host would get, not only by the dummy app in `spec/dummy/`.

**Deny-by-default contract (`app/controllers/concerns/fe/access_control_concern.rb`, `lib/fe/access_control.rb`)**

- Every action that reads or changes an answer sheet runs `fe_authorize_answer_sheet!` (`:look` for
  `show`, `:change` for everything else). Every form-builder action runs `fe_require_admin!`.
  `index` and `create` on `Fe::AnswerSheetsController` run `fe_require_admin_for_own_action!`
- fe never defines `fe_can_use_answer_sheet?` or `fe_admin?` itself, not even a permissive default.
  `Fe.verify_access_hooks!` can only spot a missing host hook because fe has none of its own
- A denial must end the request: `fe_deny!` calls the host's optional `fe_access_denied(kind)`, then
  `head :forbidden unless performed?`
- The gate judges whatever is in `@answer_sheet` and calls `get_answer_sheet` itself when nothing has
  loaded it, so it holds even when a host re-declares callbacks and changes their order
- Look for: a new action missing from the `only:` list beside `fe_authorize_answer_sheet!` or
  `fe_require_admin!`; a new fe controller that doesn't include `Fe::AccessControlConcern` or isn't
  listed in `Fe::ANSWER_SHEET_CONTROLLERS` / `Fe::ADMIN_CONTROLLERS`; an action that loads a
  different sheet from params after the gate ran than the one the gate checked; `index` or `create`
  moved out of `Fe::AnswerSheetsControllerConcern` (the owner test in
  `fe_require_admin_for_own_action!` then skips them); a new `Fe::ReferenceSheetsController` action
  without a change to the `prepend_before_action :edit_only` exception list; child records (pages,
  elements, references, answers) found by a bare id in a respondent-facing action where they could
  be scoped through the checked sheet, the way `@answer_sheet.reference_sheets.find(id)` is

**Reference writers and access keys**

- People who fill out a reference are signed out. The sheet's `access_key`, sent as `params[:a]`, is
  their only credential
- Decide access with `Fe.access_key_matches?(sheet, key)` (constant-time; false for a blank or
  non-String key and for a sheet with a blank key), not `==`
- Keys come from `Fe::AccessKeyGenerator#generate_access_key` (`SecureRandom.hex`, retried until
  unique). `Fe::ReferenceSheet#reset_reference` makes a new key when the reference's email changes;
  `allow_quiet_reference_email_changes` skips that only for the reference writer editing their own
  sheet (`set_quiet_reference_email_change`)
- Look for: keys made any other way; an email-change path that keeps the old key; a key in a log
  line, flash, JSON response, or anywhere other than the invite URL built in `send_invite`

**Class names from params**

- `answer_sheet_type` and `element_type` resolve through `Fe.answer_sheet_class_for` and
  `Fe.element_class_for`, which check `Fe.answer_sheet_types` / `Fe.element_types` and raise
  `ActiveRecord::RecordNotFound` for anything else
- Look for: a new `constantize`, `safe_constantize`, `const_get`, or `send` fed from params.
  `Fe::QuestionSheet.create_from_yaml` (`Psych.unsafe_load_file`) and
  `Fe::Element.create_from_import` (`element_data['kind'].constantize`) are for trusted files run
  from a console or rake task; never wire them to an upload or an action

**Builder content is trusted; respondent content is not**

- Element and page `label`, `content`, `tooltip` and their `*_translations` render with `raw` in
  `app/views/fe/questions/fe/` and `app/views/fe/answer_pages/_element.html.erb`. That is safe only
  because `fe_admin?` gates every write to them
- `object_name` and `attribute_name` go through `eval` in `Fe::Question#responses`,
  `Fe::Question#set_response`, and `Fe::Element#limit`. `source`, `text_xpath`, and `value_xpath`
  make the server open a file or fetch a URL in `Fe::ChoiceFieldConcern#choices`
- Look for: any path that lets a non-admin write those columns (respondent-facing strong params, an
  import, an action outside `Fe::Admin::*`); respondent data (`response`, `display_response`,
  `Fe::Answer#value`, reference names and emails) rendered with `raw` or `html_safe` instead of
  `simple_format` or a tag helper; a new `eval` or `instance_eval` on element fields
- `Fe::Notifier.notification` renders `Fe::EmailTemplate` subject and content with Liquid, which
  does not escape HTML. When a caller passes `format: 'html'`, escape applicant- and
  reference-supplied values in `template_params` first

**Strong params and CSRF**

- `answer_params` is `permit!`. That is safe only because `Fe::QuestionSet#post` skips any id that is
  not a question in the current page's set; keep that filter. Reference contact fields are permitted
  one by one (`:relationship, :title, :first_name, :last_name, :phone, :email, :is_staff`) in both
  `AnswerPagesControllerConcern#update` and `AnswerSheetsControllerConcern#send_reference_invite`.
  Hosts add element attributes through `extra_element_params`, not by widening `element_params`
- `skip_before_action :verify_authenticity_token, only: :save_file` exists for the Flash uploader
  fallback. Look for: that skip widened to more actions; `savePage` in
  `app/assets/javascripts/fe/fe.public.nojquery.js.erb` no longer appending `authenticity_token`

**Public repo, vendored fixes**

- The repo is public. Look for: code, comments, or specs that spell out an unpatched hole, name an
  internal host or URL, or hold a credential
- A security fix in `app/assets/javascripts/fe/` reaches host apps that vendor fe's JS only when they
  copy it again. A fix that needs hosts to change config or hooks needs an "Upgrading to X.Y" entry
  in `README.md`
