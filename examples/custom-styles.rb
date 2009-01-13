#coding: utf-8

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require "prawn"
require "prawn/format"

Prawn::Document.generate("custom-styles.pdf") do
  styles[:p][:text_align] = :justify

  styles[:h1][:margin_top] = 144

  styles[:stave] = {
    :meta => { :name => :anchor },
    :text_align => :center,
    :display => :block,
    :font_weight => :bold,
    :font_size => "2em"
  }

  styles[:title] = {
    :text_align => :center,
    :display => :block,
    :font_weight => :bold,
    :font_size => "1.5em",
    :margin_bottom => "1em"
  }

  styles[:song] = {
    :display => :block,
    :text_align => :center,
    :margin_top => "0.5em",
    :margin_bottom => "0.5em",
    :font_style => :italic
  }

  styles[:contents] = {
    :display => :block,
    :margin_left => "25%",
    :margin_top => 72
  }

  font "Times-Roman", :size => 14
  text(File.read("#{File.dirname(__FILE__)}/christmas-carol.html"))
end
