#coding: utf-8

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require "prawn"
require "prawn/format"

Prawn::Document.generate("text_formatting.pdf") do
  styles[:p][:text_align] = :justify

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

  font "Times-Roman", :size => 14

  move_text_position 144
  format "<h1>A Christmas Carol</h1>\n<h2>By Charles Dickens</h2>"

  move_text_position 72
  bounding_box [bounds.left+bounds.width/4,y], :width => bounds.width, :height => self.y do
    format "1. <a href='stave1'>Stave One</a>: Marley's Ghost<br />" +
           "2. <a href='stave2'>Stave Two</a>: The First of the Three Spirits<br />" +
           "3. <a href='stave3'>Stave Three</a>: The Second of the Three Spirits<br />" +
           "4. <a href='stave4'>Stave Four</a>: The Last of the Spirits<br />" +
           "5. <a href='stave5'>Stave Five</a>: The End of it."
  end

  start_new_page
  format(File.read("#{File.dirname(__FILE__)}/christmas-carol.html"))
end
