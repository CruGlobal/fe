module Fe
  module ApplicationHelper
    include AnswerPagesHelper
    def pretty_tag(txt)
      txt.to_s.gsub(/\s/, "_").gsub(/(?!-)\W/, "").downcase
    end

    def flatten_hash(hash = params, ancestor_names = [])
      flat_hash = {}
      hash.each do |k, v|
        names = Array.new(ancestor_names)
        names << k
        if v.is_a?(Hash)
          flat_hash.merge!(flatten_hash(v, names))
        else
          key = flat_hash_key(names)
          key += "[]" if v.is_a?(Array)
          flat_hash[key] = v
        end
      end

      flat_hash
    end

    def flat_hash_key(names)
      names = Array.new(names)
      name = names.shift.to_s.dup
      names.each do |n|
        name << "[#{n}]"
      end
      name
    end

    def calendar_date_select_tag(name, value = nil, options = {})
      options.merge!({'data-calendar' => true})
      text_field_tag(name, value, options )
    end

    def tip(t)
      image_tag('fe/icons/question-balloon.png', :title => t, :class => 'tip')
    end

    def spinner(extra = nil)
      e = extra ? "spinner_#{extra}" : 'spinner'
      image_tag('spinner.gif', :id => e, :style => 'display:none', :class => 'spinner')
    end

    def link_to_function(name, *args, &block)
       html_options = args.extract_options!.symbolize_keys

       function = block_given? ? update_page(&block) : args[0] || ''
       onclick = "#{"#{html_options[:onclick]}; " if html_options[:onclick]}#{function}; return false;"
       href = html_options[:href] || '#'

       content_tag(:a, name, html_options.merge(:href => href, :onclick => onclick))
    end

    def error_messages_for(model)
      record = instance_variable_get(:"@#{model}")
      render "layouts/fe/error_messages_for", record: record
    end
  end
end
