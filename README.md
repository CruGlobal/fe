## Fe (Form Engine)

This project rocks and uses MIT-LICENSE.

Supports rails >= 5

### Development

### Testing

Note: The tests need ruby 2 to run, and is set up with rails 5.

Setup the testing db

    Configure spec/dummy/config/database.yml

    $ RAILS_ENV=test bundle exec rake app:db:environment:set db:create db:schema:load

Run specs:
    
    $ bundle exec rake spec
    
Run a specific spec:

    bundle exec rspec spec/models/fe/element_spec.rb

### Example enclosing app

    rails new 

## install devise

# add to gemfile

    gem 'devise'

# run

    bundle install
    rails generate devise:install
    rails generate devise User

# add to gemfile

    github: 'CruGlobal/qe', branch: 'fe'

# run

    bundle exec rake fe_engine:install:migrations

# add example user

    bundle exec rails console

    User.new({ :email => 'user@example.com', :password => 'password', :password_confirmation => 'password'}).save

# start server

    bundle exec rails server

## Access control

fe denies access by default. It never decides who a person is or what they may
see. The host app answers two questions, and until it does, fe refuses every
request. fe also checks at boot: the app raises `Fe::MissingAccessHook` and
won't start until both hooks exist.

### Required hooks

Define both on `ApplicationController`, or on the fe controllers themselves.
Private, protected and public methods all count, and so do methods added by a
module you include or prepend in `config.to_prepare`.

    class ApplicationController < ActionController::Base
      private

      # May the current person use this answer sheet?
      # access is :look (viewing it) or :change (anything else).
      def fe_can_use_answer_sheet?(answer_sheet, access)
        if answer_sheet.is_a?(Fe::ReferenceSheet)
          # Reference writers open their sheet from a link that carries its key.
          Fe.access_key_matches?(answer_sheet, params[:a])
        else
          current_user.present? && answer_sheet.owner == current_user
        end
      end

      # May the current person use fe's admin screens (the form builder)?
      def fe_admin?
        current_user&.admin?
      end
    end

`fe_can_use_answer_sheet?(answer_sheet, access)`

- `:look` is used by the `show` actions. `:change` covers every other action
  that works on an answer sheet (saving answers, submitting, and so on).
- It judges whatever is in `@answer_sheet` when the check runs. If nothing has
  loaded the sheet yet, fe calls `get_answer_sheet` first (yours, if you
  override it), so moving, re-declaring or skipping that callback doesn't skip
  the check. To change how the sheet loads, override `get_answer_sheet`. If the
  loader renders or redirects, that is the response. If there is still no
  sheet (for example a reference link with a wrong key), fe leaves the
  response to the action.
- Reference sheets reach the same hook as `Fe::ReferenceSheet` records. A hook
  that only checks the signed-in user locks reference writers out, so give
  them their own branch, as in the example. The reference's access key is in
  `params[:a]`, and `Fe.access_key_matches?(answer_sheet, params[:a])` is the
  safe way to check it. Whether a key alone is enough is up to your app.

`fe_admin?` takes no arguments. It guards the admin controllers
(`Fe::Admin::QuestionSheetsController`, `QuestionPagesController`,
`ElementsController`, `EmailTemplatesController`) and the `index` and `create`
actions of `Fe::AnswerSheetsController`. The `index` and `create` rule follows
fe's own code for those actions, so it also covers any controller of yours that
inherits them without defining its own. If you define `index` or `create`
yourself (in a subclass, a reopened class or a prepended module), even one that
only calls `super`, fe's admin check skips it and your action owns its check.

The boot check needs `fe_can_use_answer_sheet?` on every class in
`Fe::ANSWER_SHEET_CONTROLLERS` and `fe_admin?` on every class in
`Fe::ADMIN_CONTROLLERS` plus `Fe::AnswerSheetsController`. Defining both on
`ApplicationController` covers all of them.

### Changing fe's controllers

Reopening an fe controller (with `class_eval`, or a module you include or
prepend) keeps fe's checks. Replacing one with your own class of the same name
doesn't: your class gets only the checks it includes or inherits. The checks
for answer sheets, answer pages and question sheets live in fe concerns
(`Fe::AnswerSheetsControllerConcern`, `Fe::AnswerPagesControllerConcern`,
`Fe::Admin::QuestionSheetsControllerConcern`), so a replacement that includes
the concern keeps them. fe's other controllers declare their checks in the
class itself, so a replacement for one of them loses those checks unless you
add them. The boot check only looks for the hook methods, so it can't tell.

### Optional: `fe_access_denied(kind)`

When a check fails, fe sends `403 Forbidden`. To do something else, define
`fe_access_denied(kind)`. `kind` is `:answer_sheet` or `:admin`.

    def fe_access_denied(kind)
      redirect_to root_path, alert: 'You do not have access to that.'
    end

If it renders or redirects, that replaces the 403. If it does neither, fe still
sends 403. Exceptions raised in your hooks are not rescued.

### Other settings

- `Fe.answer_sheet_types`: the answer sheet classes fe accepts in the
  `answer_sheet_type` param. Any other class is refused as not found. It
  defaults to `nil`, which means `Fe.answer_sheet_class` plus
  `Fe::ReferenceSheet`. Setting it replaces that default, so list every class
  your app uses, including your `Fe.answer_sheet_class` and
  `Fe::ReferenceSheet`. Because the default is `nil`, `+=` raises on it. Set it
  where you set `Fe.answer_sheet_class` (for example in a `config.to_prepare`
  block, if that's where your app sets the class):

      Fe.answer_sheet_class = 'Fe::Application'
      Fe.answer_sheet_types = %w[Fe::Application Fe::ReferenceSheet MyOtherSheet]

- `Fe.element_types`: the element classes the form builder accepts in the
  `element_type` param. It defaults to fe's own element classes, so add yours
  to it:

      Fe.element_types += %w[MyRatingField]

- `Fe.access_key_matches?(answer_sheet, key)`: constant-time comparison of a
  key against the sheet's `access_key`. False for a blank or non-string key,
  and false when the sheet's own `access_key` is blank.
- `Fe.verify_access_hooks_on_boot` (default `true`): set to `false` to turn off
  the boot check. It is meant only for fe's own test app. Leave it on in a real
  app.

### Upgrading to 2.4

- fe no longer calls `check_valid_user`. Move that logic into
  `fe_can_use_answer_sheet?` and `fe_admin?`.
- fe accepts only the classes in `Fe.answer_sheet_types` in the
  `answer_sheet_type` param, and by default that is just
  `Fe.answer_sheet_class` and `Fe::ReferenceSheet`. Every other sheet class is
  refused as not found. fe's pages send the sheet's class in that param on
  every page load and save, so if your app has any other answer sheet classes,
  set `Fe.answer_sheet_types` to list all of them (see above).
- The form builder accepts only the element classes in `Fe.element_types`. Add
  any element classes of your own.
- `index` and `create` on `Fe::AnswerSheetsController` are admin-only
  (`fe_admin?`), and so are those actions in any controller of yours that
  inherits them without defining its own.
- `Fe::ReferenceSheetsController` allows only `edit`, `show` and `done`. Other
  actions return 404. `show` is checked with `:look`, and a `show` link with a
  wrong or missing key now gets the not-found page with a 404 instead of an
  error.
- If your app overrides `fe/questions/fe/_attachment_field.html.erb`, add
  `a: params[:a]` to its upload, delete and page reload URLs, as fe's own
  partial now does. Without the key, reference writers get 403 when they
  attach a file.
- Define both hooks before deploying, or the app won't boot.

## Changelog

### 2.4

- **Deny by default**: fe refuses answer sheets and its admin screens unless the host app allows them, and the app won't boot until it defines fe's access hooks. See [Upgrading to 2.4](#upgrading-to-24).

### 2.2

- **Accidental overwrite protection**: When multiple tabs/windows have the same form open, autosave could silently overwrite another tab's answers. Now an MD5 digest of the current answers is tracked, and saves are rejected if the answers have changed since the page was loaded.
