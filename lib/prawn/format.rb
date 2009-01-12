require 'prawn/format/layout_builder'
require 'prawn/format/text_object'

module Prawn
  module Format
    DEFAULT_STYLES = {
      :b      => { :font_weight => :bold },
      :i      => { :font_style => :italic },
      :u      => { :text_decoration => :underline },
      :br     => { :display => :break },
      :page   => { :display => :page_break },
      :p      => { :display => :block, :text_indent => "3em" },
      :sup    => { :vertical_align => :super, :font_size => "70%" },
      :sub    => { :vertical_align => :sub, :font_size => "70%" },
      :a      => { :meta => { :name => :anchor, :href => :target }, :color => "0000ff", :text_decoration => :underline },
      :center => { :display => :block, :text_align => :center },
      :h1     => { :display => :block, :text_align => :center, :font_size => "3em", :font_weight => :bold, :margin_bottom => "1em" },
      :h2     => { :display => :block, :text_align => :center, :font_size => "2em", :font_weight => :bold, :margin_bottom => "1em" },
      :h3     => { :display => :block, :text_align => :center, :font_size => "1.2em", :font_weight => :bold, :margin_bottom => "1em" },
    }.freeze

    def styles(update={})
      @styles ||= DEFAULT_STYLES.dup
      @styles.update(update)
    end

    def default_style
      { :font_family => font.family || font.name,
        :font_size   => font.size,
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
            value.to_f * (options[:em] || font.size)
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
      real_x = x + bounds.absolute_left
      real_y = y + bounds.absolute_bottom

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

      return state
    end

    def layout(text, options={})
      helper = Format::LayoutBuilder.new(self, text, options)
      yield helper if block_given?
      return helper
    end

    def format(text, options={})
      layout(text, options) do |helper|
        self.y = helper.fill(bounds.left, y - bounds.absolute_bottom, options.merge(:width => bounds.width, :height => bounds.height))
      end
    end

    def paginate(text, options={})
      helper  = layout(text, options)

      columns = (options[:columns] || 1).to_i
      gap     = options[:gap]     || 18
      width   = bounds.width.to_f / columns
      column  = 0

      until helper.done?
        x = bounds.left + column * width
        y = self.y - bounds.absolute_bottom

        helper.fill(x, y, options.merge(:width => width - gap, :height => bounds.height))

        unless helper.done?
          column += 1
          if column >= columns
            start_new_page
            column = 0
          end
        end
      end
    end
  end
end

require 'prawn/document'
Prawn::Document.send(:include, Prawn::Format)
Prawn::Document.send(:include, Prawn::Format::TextObject)
