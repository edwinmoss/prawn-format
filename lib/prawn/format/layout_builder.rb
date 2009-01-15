# encoding: utf-8

require 'prawn/format/box'
require 'prawn/format/line'
require 'prawn/format/parser'

module Prawn
  module Format
    class LayoutBuilder
      attr_reader :document, :options

      def initialize(document, text, options={})
        @document = document
        @options  = options
        @tags     = document.tags.merge(options[:tags] || {})
        @styles   = document.styles.merge(options[:styles] || {})
        style     = document.default_style.merge(options[:default_style] || {})

        translate_prawn_options(style, options)

        @parser   = Parser.new(@document, text,
                      :tags => @tags, :styles => @styles, :style => style)

        @state    = {}
        @box      = Box.new(nil, @parser.state)
      end

      def done?
        @parser.eos?
      end

      def word_wrap(height=nil, &block)
        if height && block
          raise ArgumentError, "cannot specify both height and a block"
        elsif height
          block = Proc.new { |l, h| h > height }
        elsif block.nil?
          block = Proc.new { |l, h| false }
        end

        lines = []
        total_height = 0

        while (line = self.next)
          if block[line, total_height + line.height]
            @box = lines.last.box if lines.any?
            unget(line)
            break
          end

          total_height += line.height
          lines.push(line)

          break if line.page_break?
        end

        return lines
      end

      def fill(x, y, fill_options={}, &block)
        @box.resize!(fill_options[:width]) if fill_options[:width]
        lines = word_wrap(fill_options[:height], &block)
        draw_options = options.merge(fill_options).merge(:state => @state)
        @state = document.draw_lines(x, y, @box.full_width, lines, draw_options)
        @state.delete(:cookies)
        return @state[:dy] + y
      end

      def width=(width)
        @box.resize!(width)
      end

      def next
        line = []
        width = 0
        break_at = nil
        force_break = false
        line_width = @box.width

        while (instruction = @parser.next)
          next if !@box.verbatim? && line.empty? && instruction.discardable? # ignore discardables at line start
          line.push(instruction)

          if instruction.start_box? && line.length > 1
            if line.all? { |i| i.start_box? || i.discardable? }
              line.clear
              line.push(instruction)
              width = instruction.width
              break_at = nil
            else
              force_break = true
              break_at = line.length - 1
            end
          elsif instruction.break?
            width += instruction.width(:nondiscardable)
            break_at = line.length if width <= line_width
            width += instruction.width(:discardable)
          else
            width += instruction.width
          end

          if force_break || instruction.force_break? || width >= line_width
            break_at ||= line.length
            hard_break = force_break || instruction.force_break? || @parser.eos?

            @parser.push(line.pop) while line.length > break_at

            box = @box
            @box = @box.container if line.last.end_box?

            return Line.new(line, hard_break, box)
          elsif instruction.start_box?
            @box = Box.new(@box, instruction.state)
            line_width = @box.width
          end
        end

        Line.new(line, true, @box) if line.any?
      end

      def unget(line)
        line.source.reverse_each { |instruction| @parser.push(instruction) }
      end

      def translate_prawn_options(style, options)
        style[:text_align] = options[:align] if options.key?(:align)
        style[:kerning] = options[:kerning] if options.key?(:kerning)
        style[:font_size] = options[:size] if options.key?(:size)

        case options[:style]
        when :bold then
          style[:font_weight] = :bold
        when :italic then
          style[:font_style] = :italic
        when :bold_italic then
          style[:font_weight] = :bold
          style[:font_style] = :italic
        end
      end
    end
  end
end
