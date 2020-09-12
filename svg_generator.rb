# frozen_string_literal: true

require 'yaml'
require 'zip'

class SvgGenerator < Middleman::Extension
  def before_build(_builder)
    Dir.glob('svg/symbols/*.svg').each do |symbol_path|
      puts "Converting #{symbol_path}..."

      create_svg('svg/backgrounds/white.svg', '#000000', 'white', symbol_path)
      create_svg('svg/backgrounds/black.svg', '#ffffff', 'black', symbol_path)
      create_svg('svg/backgrounds/transparent.svg', 'param(fill)', 'transparent', symbol_path)
    end

    symbol_names = Dir.glob('svg/symbols/*.svg').sort.map do |svg_file|
      svg_file.split('/').last.split('.').first
    end

    output = {}
    output['symbols'] = symbol_names

    File.open('data/symbols.yml', 'w') { |f| f.write output.to_yaml }

    FileUtils.mkdir_p 'source/downloads'
    %w[black white transparent].each {|c| zip_symbols(c)}
  end

  private

  def zip_symbols(color)
    Zip::File.open("source/downloads/national-park-symbols-#{color}.zip", Zip::File::CREATE) do |zipfile|
      Dir.glob("source/images/svg/#{color}/*.svg").each do |symbol_path|
        zipfile.add(symbol_path.split('/').last, symbol_path)
      end
    end
  end

  def create_svg(background_path, fill_color, prefix, symbol_path)
    FileUtils.mkdir_p "source/images/svg/#{prefix}"

    symbol_name = symbol_path.split('/').last

    background = Nokogiri::XML.parse(File.read(background_path))
    symbol = Nokogiri::XML.parse(File.read(symbol_path.to_s))

    symbol_contents = symbol.css('/svg').children

    translate_group = Nokogiri::XML::Node.new('g', background)
    translate_group.set_attribute('transform', 'translate(3 3)')
    translate_group.add_child(symbol_contents)
    translate_group.css('path').each { |g| g.set_attribute('fill', fill_color) }
    translate_group.css('polygon').each { |g| g.set_attribute('fill', fill_color) }
    translate_group.css('rect').each { |g| g.set_attribute('fill', fill_color) }
    translate_group.css('circle').each { |g| g.set_attribute('fill', fill_color) }
    translate_group.css('ellipse').each { |g| g.set_attribute('fill', fill_color) }

    background.css('/svg/rect').after(translate_group)

    output_path = "source/images/svg/#{prefix}/#{symbol_name}"
    puts "Writing #{output_path}..."
    File.write(output_path, background.to_xml)
  end
end

::Middleman::Extensions.register(:svg_generator, SvgGenerator)
