module Prawn
  module Format

    class Line
      attr_reader :instructions
      attr_reader :box

      def initialize(instructions, hard_break, box)
        @instructions = instructions
        @length = instructions.length
        @length -= 1 while @length > 0 && @instructions[@length-1].discardable?

        @hard_break = hard_break
        @box = box

        @spaces = @instructions[0,@length].inject(0) { |sum, instruction| sum + instruction.spaces }
        @spaces = [1, @spaces].max
      end

      def hard_break?
        @hard_break
      end

      def width
        instructions[0,@length].inject(0) { |sum, instruction| sum + instruction.width }
      end

      # distance from top of line to baseline
      def ascent
        instructions.map { |instruction| instruction.ascent }.max || 0
      end

      # distance from bottom of line to baseline
      def descent
        instructions.map { |instruction| instruction.descent }.min || 0
      end

      def height(include_blank=false)
        h = font_height(include_blank)
        h += box.margin_top if start_of_box?
        h += box.margin_bottom if end_of_box?
        return h
      end

      def font_height(include_blank=false)
        instructions.map { |instruction| instruction.height(include_blank) }.max
      end

      def each
        instructions[0,@length].each { |instruction| yield instruction }
      end

      def start_of_box?
        instructions.first.start_box?
      end

      def end_of_box?
        instructions.last.end_box?
      end

      def page_break?
        instructions.last.page_break?
      end

      def draw_on(document, state, options={})
        return if @length.zero?

        format_state = instructions.first.state

        case(box.text_align)
        when :left
          state[:dx] = 0
        when :center
          state[:dx] = (box.width - width) / 2.0
        when :right
          state[:dx] = box.width - width
        when :justify
          state[:dx] = 0
          state[:padding] = hard_break? ? 0 : (box.width - width) / @spaces
          state[:text].word_space(state[:padding])
        end

        state[:dy] -= box.margin_top if start_of_box?
        state[:dy] -= ascent
        state[:dx] += box.margin_left

        state[:text].move_to(state[:dx], state[:dy])
        state[:line] = self

        state[:accumulator] = nil

        each { |instruction| instruction.draw(document, state, options) }

        state[:accumulator].flush(document, state) if state[:accumulator]
        state[:pending_effects].each { |effect| effect.wrap(document, state) }

        state[:dy] -= (options[:spacing] || 0) + (font_height - ascent)
        state[:dy] -= box.margin_bottom if end_of_box?
      end
    end

  end
end
