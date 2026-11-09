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

### Access control

fe denies access by default. It never decides who a person is or what they may
see. The host app answers two questions, and until it does, fe refuses every
request. fe also checks at boot: the app raises `Fe::MissingAccessHook` and
won't start until both hooks exist.

#### Required hooks

Define both on `ApplicationController`, or on the fe controllers themselves.
Private, protected and public methods all count, and so do methods added by a
module you include or prepend in `config.to_prepare`.

    class ApplicationController < ActionController::Base
      private

      # May the current person use this answer sheet?
      # access is :look (viewing it) or :change (anything else).
      def fe_can_use_answer_sheet?(answer_sheet, access)
        current_user.present? && answer_sheet.owner == current_user
      end

      # May the current person use fe's admin screens (the form builder)?
      def fe_admin?
        current_user&.admin?
      end
    end

`fe_can_use_answer_sheet?(answer_sheet, access)`

- `:look` is used by the `show` action. `:change` covers every other action
  that works on an answer sheet (saving answers, submitting, and so on).
- It runs right after fe loads the sheet (`get_answer_sheet`) and judges
  whatever is in `@answer_sheet`. If no sheet was loaded (for example a
  reference link with a wrong key), fe leaves the response to the action. A
  host that skips `get_answer_sheet` and loads `@answer_sheet` some other way
  doesn't get this check on that action.
- Reference sheets reach the hook as `Fe::ReferenceSheet` records. The
  reference's access key is in `params[:a]`, and
  `Fe.access_key_matches?(answer_sheet, params[:a])` is the safe way to check
  it. Whether a key alone is enough is up to your app.

`fe_admin?` takes no arguments. It guards the admin controllers
(`Fe::Admin::QuestionSheetsController`, `QuestionPagesController`,
`ElementsController`, `EmailTemplatesController`) and the `index` and `create`
actions of `Fe::AnswerSheetsController`.

The boot check needs `fe_can_use_answer_sheet?` on every class in
`Fe::ANSWER_SHEET_CONTROLLERS` and `fe_admin?` on every class in
`Fe::ADMIN_CONTROLLERS` plus `Fe::AnswerSheetsController`. Defining both on
`ApplicationController` covers all of them.

#### Optional: `fe_access_denied(kind)`

When a check fails, fe sends `403 Forbidden`. To do something else, define
`fe_access_denied(kind)`. `kind` is `:answer_sheet` or `:admin`.

    def fe_access_denied(kind)
      redirect_to root_path, alert: 'You do not have access to that.'
    end

If it renders or redirects, that replaces the 403. If it does neither, fe still
sends 403. Exceptions raised in your hooks are not rescued.

#### Other settings

- `Fe.answer_sheet_types`: class names fe accepts from request params for
  answer sheets. Defaults to `Fe.answer_sheet_class` plus `Fe::ReferenceSheet`.
- `Fe.element_types`: class names fe accepts from request params for elements.
  Set it to add your own element classes.
- `Fe.access_key_matches?(answer_sheet, key)`: constant-time comparison of a
  key against the sheet's `access_key`. False for a blank or non-string key.
- `Fe.verify_access_hooks_on_boot` (default `true`): turns off the boot check.
  It is meant only for fe's own test app. Leave it on in a real app.

#### Upgrading to 2.4

- fe no longer calls `check_valid_user`. Move that logic into
  `fe_can_use_answer_sheet?` and `fe_admin?`.
- `index` and `create` on `Fe::AnswerSheetsController` are admin-only
  (`fe_admin?`).
- `Fe::ReferenceSheetsController` allows only `edit` and `done`.
- Define both hooks before deploying, or the app won't boot.

### Changelog

#### 2.2

- **Accidental overwrite protection**: When multiple tabs/windows have the same form open, autosave could silently overwrite another tab's answers. Now an MD5 digest of the current answers is tracked, and saves are rejected if the answers have changed since the page was loaded.
