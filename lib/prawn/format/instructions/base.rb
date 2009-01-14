module Prawn
  module Format
    module Instructions

      class Base
        attr_reader :state, :ascent, :descent

        def initialize(state)
          @state = state
          state.font.size(state.font_size) do
            @height = state.font.height
            @ascent = state.font.ascender
            @descent = state.font.descender
          end
        end

        def spaces
          0
        end

        def width(*args)
          0
        end

        def height(*args)
          @height
        end

        def break?
          false
        end

        def force_break?
          false
        end

        def page_break?
          false
        end

        def discardable?
          false
        end

        def start_box?
          false
        end

        def end_box?
          false
        end

        def style
          {}
        end

        def compatible?(with)
          false
        end

        def accumulate(list)
          if list.any? && list.last.compatible?(self)
            list.last.append(self)
          else
            list.push(dup)
          end

          list
        end
      end

    end
  end
end
