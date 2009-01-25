# encoding: utf-8

require 'prawn/format/layout_builder'
require 'prawn/format/text_object'

module Prawn
  module Format
    def self.included(mod)
      mod.send :alias_method, :text_without_formatting, :text
      mod.send :alias_method, :text, :text_with_formatting
    end

    def text_with_formatting(text, options={})
      plain = options.key?(:plain) ? options[:plain] : text !~ /<|&(?:#x?)?\w+;/

      if plain
        text_without_formatting(text, options)
      else
        format(text, options)
      end
    end

    DEFAULT_TAGS = {
      :a      => { :meta => { :name => :anchor, :href => :target }, :color => "0000ff", :text_decoration => :underline },
      :b      => { :font_weight => :bold },
      :br     => { :display => :break },
      :strong => { :display => :break },
      :center => { :display => :block, :text_align => :center },
      :div    => { :display => :block },
      :font   => { :meta => { :face => :font_family, :color => :color, :size => :font_size } },
      :h1     => { :display => :block, :text_align => :center, :font_size => "3em", :font_weight => :bold, :margin_bottom => "1em" },
      :h2     => { :display => :block, :text_align => :center, :font_size => "2em", :font_weight => :bold, :margin_bottom => "1em" },
      :h3     => { :display => :block, :text_align => :center, :font_size => "1.2em", :font_weight => :bold, :margin_bottom => "1em" },
      :i      => { :font_style => :italic },
      :p      => { :display => :block, :text_indent => "3em" },
      :page   => { :display => :page_break },
      :pre    => { :display => :block, :white_space => :pre, :font_family => "Courier" },
      :span   => {},
      :sub    => { :vertical_align => :sub, :font_size => "70%" },
      :sup    => { :vertical_align => :super, :font_size => "70%" },
      :u      => { :text_decoration => :underline },
    }.freeze

    def tags(update={})
      @tags ||= DEFAULT_TAGS.dup
      @tags.update(update)
    end

    def styles(update={})
      @styles ||= {}
      @styles.update(update)
    end

    def default_style
      { :font_family => font.family || font.name,
        :font_size   => font_size,
        :color       => fill_color }
    end

    def evaluate_measure(measure, options={})
      case measure
      when nil then nil
      when Numeric then return measure
      when Symbol then
        mappings = options[:mappings] || {}
        raise ArgumentError, "unrecognized value #{measure.inspect}" unless mappings.key?(measure)
        return evaluate_measure(mappings[measure], options)
      when String then
        operator, value, unit = measure.match(/^([-+]?)(\d+(?:\.\d+)?)(.*)$/)[1,3]

        value = case unit
          when "%" then
            relative = options[:relative] || 0
            relative * value.to_f / 100
          when "em" then
            # not a true em, but good enough for approximating. patches welcome.
            value.to_f * (options[:em] || font_size)
          when "", "pt" then return value.to_f
          when "pc" then return value.to_f * 12
          when "in" then return value.to_f * 72
          else raise ArgumentError, "unsupport units in style value: #{measure.inspect}"
          end

        current = options[:current] || 0
        case operator
        when "+" then return current + value
        when "-" then return current - value
        else return value
        end
      else return measure.to_f
      end
    end

    def draw_lines(x, y, width, lines, options={})
      real_x, real_y = translate(x, y)

      state = options[:state] || {}
      return options[:state] if lines.empty?

      options[:align] ||= :left

      state = state.merge(:width => width,
        :x => x, :y => y,
        :real_x => real_x, :real_y => real_y,
        :dx => 0, :dy => 0)

      state[:cookies] ||= {}
      state[:pending_effects] ||= []

      text_object do |text|
        text.rotate(real_x, real_y, options[:rotate] || 0)
        state[:text] = text
        lines.each { |line| line.draw_on(self, state, options) }
      end

      state.delete(:text)

      #rectangle [x, y+state[:dy]], width, state[:dy]
      #stroke

      return state
    end

    def layout(text, options={})
      helper = Format::LayoutBuilder.new(self, text, options)
      yield helper if block_given?
      return helper
    end

    def format(text, options={})
      if options[:at]
        x, y = options[:at]
        format_positioned_text(text, x, y, options)
      else
        format_wrapped_text(text, options)
      end
    end

    def format_positioned_text(text, x, y, options={})
      helper = layout(text, options)
      helper.width = 1_000_000 # large number to prevent wrapping
      line = helper.next
      draw_lines(x, y+line.ascent, line.width, [line], options)
    end

    def format_wrapped_text(text, options={})
      helper  = layout(text, options)

      columns = (options[:columns] || 1).to_i
      gap     = columns > 1 ? (options[:gap] || 18) : 0
      width   = bounds.width.to_f / columns
      column  = 0
      top     = self.y

      until helper.done?
        x = column * width
        y = self.y - bounds.absolute_bottom
        height = bounds.height > 0 ? bounds.height : bounds.absolute_top
        self.y = helper.fill(x, y, options.merge(:width => width - gap, :height => height)) + bounds.absolute_bottom

        unless helper.done?
          column += 1
          self.y = top
          if column >= columns
            start_new_page
            column = 0
            top = self.y
          end
        end
      end
    end

    def text_object
      object = TextObject.new

      if block_given?
        yield object.open
        add_content(object.close)
      end

      return object
    end

  end
end

require 'prawn/document'
Prawn::Document.send(:include, Prawn::Format)
