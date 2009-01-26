$LOAD_PATH.unshift "#{File.dirname(__FILE__)}/../lib"
require 'prawn'
require 'prawn/format'
require 'prawn/format/version'
require 'coderay'

def process_style(document, style, content, line_number)
  content = process_substitutions(content)

  case style
  when "h1"        then h1(document, content)
  when "h2"        then h2(document, content)
  when "p"         then paragraph(document, content)
  when "fp"        then paragraph(document, content, false)
  when "ul"        then start_list(document)
  when "li"        then list_item(document, content)
  when "/ul"       then end_list(document)
  when "page"      then new_page(document)
  when "highlight" then highlight(document, content)
  when "hr"        then horiz_rule(document)
  when "center"    then center(document, content)
  else warn "unknown style #{style.inspect}"
  end

rescue Exception => err
  puts "[error occurred while processing line ##{line_number}]"
  raise
end

def process_substitutions(content)
  content.
    gsub(/%FORMAT:VERSION%/, Prawn::Format::Version::STRING).
    gsub(/%NOW%/, Time.now.utc.strftime("%e %B %Y at %H:%M UTC"))
end

def center(document, content)
  document.y -= document.font_size
  document.text(content, :plain => false, :align => :center)
  document.y -= document.font_size
end

def horiz_rule(document)
  document.y -= document.font_size
  document.stroke_color "000000"
  document.stroke_horizontal_rule
  document.y -= document.font_size
end

def h1(document, content)
  document.text "<h1>#{content}</h1>"
  document.stroke_color "000080"
  document.stroke_horizontal_rule
  document.y -= document.font_size * 2
end

def h2(document, content)
  document.text "<h2>#{content}</h2>"
  document.stroke_color "000080"
  document.stroke_horizontal_rule
  document.y -= document.font_size
end

def paragraph(document, content, indent=true)
  indent_tag = indent ? "<indent/>" : ""
  document.text "#{indent_tag}#{content}", :align => :justify, :plain => false
end

def start_list(document)
  document.y -= document.font_size
end

def list_item(document, content)
  indent_b = document.font_size * 3
  indent   = document.font_size * 4

  document.start_new_page if document.y < document.font_size
  y = document.y - document.bounds.absolute_bottom
  document.text "&bull;", :at => [indent_b, y - document.font.ascender]
  document.layout(content, :align => :justify) do |helper|
    while !helper.done?
      y = helper.fill(indent, y, document.bounds.width-indent, :height => document.y)
      if helper.done?
        document.y = y + document.bounds.absolute_bottom
      else
        document.start_new_page
        y = document.y - document.bounds.absolute_bottom
      end
    end
  end

  document.y -= document.font_size / 4
end

def end_list(document)
  document.y -= document.font_size * 3 / 4
end

def new_page(document)
  document.start_new_page
end

def highlight(document, content)
  file, syntax = content.split(/,/)
  analyzed = CodeRay.scan(File.read(File.join(File.dirname(__FILE__), file)), syntax.to_sym)
  html = "<pre>" + analyzed.html + "</pre>"

  document.y -= document.font_size * 2
  y = document.y - document.bounds.absolute_bottom
  start_y = y + document.font_size

  indent = document.font_size * 2

  document.layout(html) do |helper|
    while !helper.done?
      y = helper.fill(indent, y, document.bounds.width-indent*2, :height => document.y)
      if helper.done?
        document.y = y + document.bounds.absolute_bottom
      else
        document.start_new_page
        y = document.y - document.bounds.absolute_bottom
      end
    end
  end

  document.stroke_color "a0a0a0"
  document.rectangle [document.font_size, start_y], bounds.width - document.font_size*2, (start_y - y)
  document.stroke

  document.y -= document.font_size
end

SERIF_FONT  = "/Library/Fonts/Baskerville.dfont"

Prawn::Document.generate("prawn-format.pdf", :compress => true) do
  if File.exists?(SERIF_FONT)
    font_families["Baskerville"] = {
      :normal      => { :file => SERIF_FONT, :font => 1 },
      :italic      => { :file => SERIF_FONT, :font => 2 },
      :bold        => { :file => SERIF_FONT, :font => 4 }, # semi-bold, not bold
      :bold_italic => { :file => SERIF_FONT, :font => 3 }
    }
    font "Baskerville", :size => 14
  else
    warn "Baskerville font is preferred for the manual, but could not be found. Using Times-Roman."
    font "Times-Roman", :size => 14
  end

  tags :h1 => { :font_size => "2em", :font_weight => :bold, :color => "navy" },
       :h2 => { :font_size => "1.5em", :font_weight => :bold, :color => "navy" },
       :indent => { :width => "2em" },
       :about => { :font_size => "80%", :color => "808080", :font_style => :italic }

  styles :no  => { :color => "gray" },
         :c   => { :color => "#666" },
         :s   => { :color => "#d20" },
         :dl  => { :color => "black" },
         :co  => { :color => "#036", :font_weight => :bold },
         :pc  => { :color => "#038", :font_weight => :bold },
         :sy  => { :color => "#A60" },
         :r   => { :color => "#080" },
         :i   => { :color => "#00D", :font_weight => :bold },
         :idl => { :color => "#888", :font_weight => :bold },
         :dl  => { :color => "#840", :font_weight => :bold }

  File.open("#{File.dirname(__FILE__)}/manual.txt") do |source|
    number = 0
    source.each_line do |line|
      number += 1
      line.chomp!
      next if line.length == 0

      style, content = line.match(/^(\S+)\.\s*(.*)/)[1,2]
      process_style(self, style, content, number)
    end
  end
end
