#coding: utf-8

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require "prawn"
require "prawn/format"

Prawn::Document.generate("custom-tags.pdf") do
  tags[:p][:text_align] = :justify

  tags[:h1][:margin_top] = 144

  tags[:stave] = {
    :meta => { :name => :anchor },
    :text_align => :center,
    :display => :block,
    :font_weight => :bold,
    :font_size => "2em"
  }

  tags[:title] = {
    :text_align => :center,
    :display => :block,
    :font_weight => :bold,
    :font_size => "1.5em",
    :margin_bottom => "1em"
  }

  tags[:song] = {
    :display => :block,
    :text_align => :center,
    :margin_top => "0.5em",
    :margin_bottom => "0.5em",
    :font_style => :italic
  }

  tags[:contents] = {
    :display => :block,
    :margin_left => "25%",
    :margin_top => 72
  }

  styles[:noindent] = { :text_indent => 0 }

  font "Times-Roman", :size => 14
  text(File.read("#{File.dirname(__FILE__)}/christmas-carol.html"))
end
