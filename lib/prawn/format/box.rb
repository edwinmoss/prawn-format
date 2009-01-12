module Prawn
  module Format
    class Box
      attr_reader :container

      attr_reader :margin_left, :margin_right, :margin_top, :margin_bottom
      attr_reader :text_align, :text_indent

      def initialize(container, state)
        @container = container
        @state     = state

        container_width = (container && container.width) || @state.document.bounds.width
        @width = evaluate(:width, container_width) || container_width
        @margin_left = evaluate(:margin_left, @width) || 0
        @margin_right = evaluate(:margin_right, @width) || 0
        @margin_top = evaluate(:margin_top, 0) || 0
        @margin_bottom = evaluate(:margin_bottom, 0) || 0
        @text_indent = evaluate(:text_indent, @width) || 0

        @text_align = @state.original_style[:text_align] ||
          (container && container.text_align) || :left
      end

      def width
        @width - @margin_left - @margin_right
      end

      def resize!(width)
        if @container
          @container.resize!(width)
          @width = evaluate(:width, @container.width) || @container.width
        else
          @width = width
        end
      end

      def full_width
        @container ? @container.full_width : @width
      end

      private

        def evaluate(attribute, relative)
          @state.document.evaluate_measure(@state.original_style[attribute],
            :em => @state.font_size, :relative => relative)
        end
    end
  end
end
