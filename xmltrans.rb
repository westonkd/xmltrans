#!/usr/bin/env ruby
#this file depends on nokogiri, a small ruby gem. Install details can be found at
#http://www.nokogiri.org/tutorials/installing_nokogiri.html
#this file also expects xsl files to be in the /xsl-transforms of the specified xml directory (i.e. xml/xsl-transforms)

require 'nokogiri'
require 'fileutils'

class XMLFileHelper
  attr_accessor :path, :transform, :transforms, :root_elem

  def initialize(path)
    @path = path
    @transforms = get_transforms
  end

  def batch_transform
    confirmed = nil
    until confirmed
      transform_sequence
      confirmed = confirm_transform
    end

    transform_all
  end

  def single_transform(file)
    show_transforms
    get_selected_transform
    input = [(print "Transform #{file} with transform '#{@transforms[@transform - 1]}'? (y/n): "), STDIN.gets.rstrip][1]
    if input.downcase == 'y'
      transform_one(file)
    else
      single_transform(file)
    end
  end

  def transform_sequence
    show_transforms
    get_selected_transform
    get_root_elem
  end

  def show_transforms
    puts "XSL Transforms:"
    transforms.each_with_index do |file, i|
      puts "#{i + 1}. #{file}"
    end
  end

  def get_selected_transform
    @transform = nil
    while @transform.nil? || @transform < 0 || @transform > transforms.length do
      puts "Invalid selection: #{@transform}." unless @transform.nil?
      @transform = [(print 'Select a transform: '), STDIN.gets.rstrip][1].to_i
    end
    @transform
  end

  def get_root_elem
    @root_elem = [(print 'Root element of pages to transform (case sensitive): '), STDIN.gets.rstrip][1]
  end

  def confirm_transform
    input = [(print "Transform pages with root element '#{@root_elem}' with transform '#{@transforms[@transform - 1]}'? (y/n): "), STDIN.gets.rstrip][1]
    input.downcase == 'y' ? true : false
  end

  def transform_all
    Dir.foreach(@path) do |filename|
      next unless filename.include?('.xml')
      File.open("#{@path}/#{filename}") do |f|
        f.each_with_index do |line, i|
          transform_one("#{@path}/#{filename}") if line =~ /^<#{@root_elem}\s/
          break if i > 2
        end
      end
    end
  end

  def transform_one(filename)
    print '.'
    Dir.mkdir("#{path}/xml_backup") unless File.exists?("#{path}/xml_backup")
    FileUtils.cp(filename, "#{path}/xml_backup/#{filename.split('/').last}")

    document = Nokogiri::XML(File.read(filename))
    template = Nokogiri::XSLT(File.read("#{path}/xsl-transforms/#{@transforms[@transform - 1]}"))
    File.open(filename, 'w').write(template.transform(document))
  end

  private

  def get_transforms
    transforms = Array.new
    Dir.foreach("#{path}/xsl-transforms") do |file|
      next if file == '.' || file == '..'
      transforms << file if file.end_with?(".xsl") || file.end_with?(".xslt")
    end
    transforms
  end
end

#Begin Execution
unless ARGV.length == 0
  xml_path = "#{Dir.pwd}#{ARGV.first[0] == '/' ? '' : '/'}#{ARGV.first}"
  xml_helper = XMLFileHelper.new(xml_path)
  puts "xml path set to #{xml_path}"

  if ARGV.length == 2
    xml_helper.single_transform("#{xml_path}/#{ARGV[1]}")
  else
    xml_helper.batch_transform
  end
else
  puts "Error: Usage is xmltrans <xml_folder_path> <optional path_to_file>"
end
