module ActionView::Helpers
  class FormBuilder

    def locale
      @@active_locale
    end

    def convert_reform_class(object)
      object.class.superclass.name == 'Reform::Form' ? object.sync : object
    end

    def globalize_fields_for_locale(locale, *args, &proc)
      raise ArgumentError, "Missing block" unless block_given?
      @@active_locale = locale
      @index = (@index.present? && @index.is_a?(Integer)) ? @index + 1 : 1
      object_name = "#{@object_name}[translations_attributes][#{@index}]"
      object = convert_reform_class(@object).translation_for(locale.to_s, true)
      @template.concat(@template.hidden_field_tag("#{object_name}[id]", object.id)) unless object.new_record?
      @template.concat(@template.hidden_field_tag("#{object_name}[locale]", locale))
      if @template.respond_to? :simple_fields_for
        @template.concat @template.simple_fields_for(object_name, object, *args, &proc)
      else
        @template.concat @template.fields_for(object_name, object, *args, &proc)
      end
    end

    def globalize_fields_for_locales(locales = [], *args, &proc)
      locales.each do |locale|
        globalize_fields_for_locale(locale, *args, &proc)
      end
    end

    # Added "globalize_inputs" that uses standard Twitter Bootstrap tabs.
    def globalize_inputs(*args, &proc)
      index = options[:child_index] || "#{self.object.class.to_s}-#{self.object.object_id}"
      linker = ActiveSupport::SafeBuffer.new
      fields = ActiveSupport::SafeBuffer.new

      ::I18n.available_locales.each do |locale|
        active_class = ::I18n.locale == locale ? "in active" : ""
        url          = "lang-#{locale}-#{index}"
        linker << self.template.content_tag(:li,
          self.template.content_tag(:a,
            ::I18n.t("translation.#{locale}"),
            :href => "##{url}",
            :"data-toggle" => "tab"
          ),
          class: "#{active_class}",
        )
        fields << self.template.content_tag(:div,
          self.semantic_fields_for(*(args.dup << convert_reform_class(self.object).translation_for(locale)), &proc),
          :id => "#{url}",
          class: "tab-pane fade #{active_class}"
        )
      end

      linker = self.template.content_tag(:ul, linker, class: "nav nav-tabs language-selection")
      fields = self.template.content_tag(:div, fields, class: "tab-content")

      html = self.template.content_tag(:div,
        linker + fields,
        id: "language-tabs-#{index}",
        class: "tabbable tabs-left"
      )
    end
  end
end
