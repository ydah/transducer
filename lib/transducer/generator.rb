# frozen_string_literal: true

require 'json'
require 'erb'

module Transducer
  class Generator
    attr_reader :data, :formatter, :template_path

    def initialize(parsed_data, template_path: nil)
      @data = parsed_data
      @formatter = Formatter.new
      @template_path = template_path
    end

    def generate
      if @template_path
        render_template
      else
        generate_default
      end
    end

    def to_file(output_path)
      require 'fileutils'
      FileUtils.mkdir_p(File.dirname(output_path))

      File.write(output_path, generate)
    rescue Errno::EACCES
      raise FileError, "Permission denied: #{output_path}"
    rescue StandardError => e
      raise FileError, "Failed to write file: #{e.message}"
    end

    private

    def render_template
      raise FileError, "Template file not found: #{@template_path}" unless File.exist?(@template_path)

      template_content = File.read(@template_path)
      erb = ERB.new(template_content, trim_mode: '-')
      erb.result(binding)
    rescue Errno::EACCES
      raise FileError, "Permission denied reading template: #{@template_path}"
    rescue StandardError => e
      raise FileError, "Failed to render template: #{e.message}"
    end

    def generate_default
      output = []
      output << generate_header
      output << generate_table_of_contents
      output << generate_endpoints
      output << generate_schemas
      output.compact.join("\n\n")
    end

    def generate_header
      info = @data['info']
      output = []
      output << "# #{info['title']}"
      output << ''
      output << info['description'] if info['description']
      output << ''
      output << '| | |'
      output << '|---|---|'
      output << "| Version | #{info['version']} |"

      output << "| Base URL | #{@data['servers'][0]['url']} |" if @data['servers'] && !@data['servers'].empty?

      output.join("\n")
    end

    def generate_table_of_contents
      output = []
      output << '## Table of Contents'
      output << ''
      output << '- [Endpoints](#endpoints)'

      @data['paths']&.each do |path, methods|
        methods.each_key do |method|
          next if method.start_with?('$')

          anchor = "#{method}-#{path}".downcase.gsub(/[^a-z0-9\s-]/, '').gsub(/\s+/, '-')
          output << "  - [#{method.upcase} #{path}](##{anchor})"
        end
      end

      if @data['components'] && @data['components']['schemas']
        output << '- [Schemas](#schemas)'
        @data['components']['schemas'].each_key do |schema_name|
          anchor = schema_name.downcase.gsub(/[^a-z0-9\s-]/, '').gsub(/\s+/, '-')
          output << "  - [#{schema_name}](##{anchor})"
        end
      end

      output.join("\n")
    end

    def generate_endpoints
      return nil unless @data['paths']

      output = []
      output << '## Endpoints'
      output << ''

      @data['paths'].each do |path, methods|
        methods.each do |method, details|
          next if method.start_with?('$')

          output << @formatter.format_endpoint(path, method, details)
          output << ''
        end
      end

      output.join("\n")
    end

    def generate_schemas
      return nil unless @data['components'] && @data['components']['schemas']

      output = []
      output << '## Schemas'
      output << ''

      @data['components']['schemas'].each do |schema_name, schema|
        output << "### #{schema_name}"
        output << ''
        output << schema['description'] if schema['description']
        output << ''
        output << @formatter.format_schema(schema)
        output << ''

        next unless schema['example']

        output << '**Example**:'
        output << ''
        output << '```json'
        output << JSON.pretty_generate(schema['example'])
        output << '```'
        output << ''
      end

      output.join("\n")
    end
  end
end
