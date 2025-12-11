# frozen_string_literal: true

require 'psych'

module Transducer
  class Parser
    attr_reader :file_path, :data, :errors

    def initialize(file_path)
      @file_path = file_path
      @data = nil
      @errors = []
    end

    def parse
      raise FileError, "File not found: #{file_path}" unless File.exist?(file_path)

      begin
        @data = Psych.safe_load_file(file_path, permitted_classes: [Symbol, Date, Time])
      rescue Psych::SyntaxError => e
        raise ParseError, "YAML syntax error at line #{e.line}: #{e.message}"
      end

      validate_openapi_spec
      @data
    end

    def valid?
      @errors.empty?
    end

    private

    def validate_openapi_spec
      @errors = []

      unless @data.is_a?(Hash)
        @errors << 'OpenAPI specification must be a hash'
        raise ValidationError, @errors.join(', ')
      end

      validate_openapi_version
      validate_info
      validate_paths

      raise ValidationError, @errors.join(', ') unless valid?
    end

    def validate_openapi_version
      unless @data['openapi']
        @errors << 'Missing required field: openapi'
        return
      end

      version = @data['openapi'].to_s
      return if version.start_with?('3.0') || version.start_with?('3.1')

      @errors << "Unsupported OpenAPI version: #{version}. Only 3.0.x and 3.1.x are supported."
    end

    def validate_info
      unless @data['info']
        @errors << 'Missing required field: info'
        return
      end

      info = @data['info']
      @errors << 'Missing required field: info.title' unless info['title']
      @errors << 'Missing required field: info.version' unless info['version']
    end

    def validate_paths
      @errors << 'Missing required field: paths' unless @data['paths']
    end
  end
end
