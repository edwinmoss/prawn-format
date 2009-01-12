require 'prawn/format/instructions/base'

module Prawn
  module Format
    module Instructions

      class Text < Base
        attr_reader :text

        def initialize(state, text)
          super(state)
          @text = text
          state.font.normalize_encoding(@text)
        end

        def append(text)
          @text << text
        end

        def spaces
          @spaces ||= @text.scan(/ /).length
        end

        def height(ignore_discardable=false)
          if ignore_discardable && discardable?
            0
          else
            @height
          end
        end

        def break?
          return @break if defined?(@break)
          @break = @text =~ /[-—\s]/
        end

        def discardable?
          return @discardable if defined?(@discardable)
          @discardable = (@text =~ /\s/)
        end

        def width(type=:all)
          @width ||= @state.font.width_of(@text, :size => @state.font_size, :kerning => @state.kerning?)

          case type
          when :discardable then discardable? ? @width : 0
          when :nondiscardable then discardable? ? 0 : @width
          else @width
          end
        end

        def to_s
          @text
        end

        def draw(document, draw_state, options={})
          if options[:force] 
            draw!(document, draw_state)
          else
            if draw_state[:accumulator] && draw_state[:accumulator].state != state
              flush(document, draw_state)
            end
            draw_state[:accumulator] ||= self.class.new(state, "")
            draw_state[:accumulator].append(@text)
          end
        end

        def draw!(document, draw_state)
          @state.apply!(draw_state[:text], draw_state[:cookies])

          encoded_text = @state.font.encode_text(@text, :kerning => @state.kerning?)
          encoded_text.each do |subset, chunk|
            @state.apply_font!(draw_state[:text], draw_state[:cookies], subset)
            draw_state[:text].show(chunk)
          end
          draw_state[:dx] += width

          if state.text_align == :justify && draw_state[:padding]
            draw_state[:dx] += draw_state[:padding] * spaces
          end
        end
      end

    end
  end
end
