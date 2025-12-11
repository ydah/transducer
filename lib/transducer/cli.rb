# frozen_string_literal: true

require 'thor'

module Transducer
  class CLI < Thor
    def self.exit_on_failure?
      true
    end

    desc 'generate INPUT', 'Generate Markdown documentation from OpenAPI specification'
    method_option :output, aliases: '-o', type: :string, default: 'docs/openapi.md',
                           desc: 'Output file path for the generated Markdown'
    method_option :template, aliases: '-t', type: :string,
                             desc: 'Custom ERB template file path'
    def generate(input_file)
      unless File.exist?(input_file)
        error "Input file not found: #{input_file}"
        exit 1
      end

      output_file = options[:output]
      template_path = options[:template]

      parser = Parser.new(input_file)
      data = parser.parse

      generator = Generator.new(data, template_path: template_path)
      generator.to_file(output_file)

      success "Documentation generated successfully: #{output_file}"
    rescue FileError => e
      error "File error: #{e.message}"
      exit 1
    rescue ParseError => e
      error "Parse error: #{e.message}"
      exit 2
    rescue ValidationError => e
      error "Validation error: #{e.message}"
      exit 3
    rescue StandardError => e
      error "Unexpected error: #{e.message}"
      exit 4
    end

    desc 'version', 'Display version information'
    def version
      puts "Transducer version #{Transducer::VERSION}"
    end

    private

    def success(message)
      puts "✓ #{message}"
    end

    def error(message)
      warn "✗ #{message}"
    end
  end
end
