FastGettext.add_text_domain 'app', path: 'locale', type: :po
FastGettext.default_available_locales = ['en', 'fr'] #all you want to allow
FastGettext.default_text_domain = 'app'
FastGettext.locale = 'en'
I18n.backend = I18n::Backend::Chain.new(GettextI18nRails::Backend.new, I18n.backend)
