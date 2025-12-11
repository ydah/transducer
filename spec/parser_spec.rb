# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Transducer::Parser do
  let(:simple_api_path) { File.expand_path('fixtures/simple_api.yaml', __dir__) }
  let(:invalid_api_path) { File.expand_path('fixtures/invalid_api.yaml', __dir__) }
  let(:nonexistent_path) { '/path/to/nonexistent.yaml' }

  describe '#parse' do
    context 'with valid OpenAPI YAML' do
      it 'successfully parses the file' do
        parser = described_class.new(simple_api_path)
        data = parser.parse

        expect(data).to be_a(Hash)
        expect(data['openapi']).to eq('3.0.0')
      end

      it 'extracts API info correctly' do
        parser = described_class.new(simple_api_path)
        data = parser.parse

        expect(data['info']['title']).to eq('Simple API')
        expect(data['info']['version']).to eq('1.0.0')
      end

      it 'extracts all paths' do
        parser = described_class.new(simple_api_path)
        data = parser.parse

        expect(data['paths']).to have_key('/users')
        expect(data['paths']).to have_key('/users/{id}')
      end

      it 'extracts all schemas' do
        parser = described_class.new(simple_api_path)
        data = parser.parse

        expect(data['components']['schemas']).to have_key('User')
        expect(data['components']['schemas']).to have_key('UserInput')
      end
    end

    context 'with invalid YAML' do
      it 'raises an error for missing required fields' do
        parser = described_class.new(invalid_api_path)

        expect { parser.parse }.to raise_error(Transducer::ValidationError, /Missing required field: info.version/)
      end
    end

    context 'with nonexistent file' do
      it 'raises a FileError' do
        parser = described_class.new(nonexistent_path)

        expect { parser.parse }.to raise_error(Transducer::FileError, /File not found/)
      end
    end
  end

  describe '#valid?' do
    it 'returns true for valid specification' do
      parser = described_class.new(simple_api_path)
      parser.parse

      expect(parser).to be_valid
    end

    it 'returns false for invalid specification' do
      parser = described_class.new(invalid_api_path)

      begin
        parser.parse
      rescue Transducer::ValidationError
        expect(parser).not_to be_valid
      end
    end
  end

  describe 'error handling' do
    it 'raises ParseError for YAML syntax errors' do
      syntax_error_path = File.expand_path('fixtures/syntax_error.yaml', __dir__)
      File.write(syntax_error_path, "invalid: yaml: content:\n  - malformed\n  unclosed: [")

      parser = described_class.new(syntax_error_path)

      expect { parser.parse }.to raise_error(Transducer::ParseError, /YAML syntax error/)

      FileUtils.rm_f(syntax_error_path)
    end

    it 'raises ValidationError for missing openapi field' do
      missing_openapi_path = File.expand_path('fixtures/missing_openapi.yaml', __dir__)
      File.write(missing_openapi_path, "info:\n  title: Test\n  version: 1.0.0\npaths: {}")

      parser = described_class.new(missing_openapi_path)

      expect { parser.parse }.to raise_error(Transducer::ValidationError, /Missing required field: openapi/)

      FileUtils.rm_f(missing_openapi_path)
    end

    it 'raises ValidationError for unsupported OpenAPI version' do
      unsupported_version_path = File.expand_path('fixtures/unsupported_version.yaml', __dir__)
      File.write(unsupported_version_path, "openapi: 2.0\ninfo:\n  title: Test\n  version: 1.0.0\npaths: {}")

      parser = described_class.new(unsupported_version_path)

      expect { parser.parse }.to raise_error(Transducer::ValidationError, /Unsupported OpenAPI version/)

      FileUtils.rm_f(unsupported_version_path)
    end

    it 'raises ValidationError for missing info.title' do
      missing_title_path = File.expand_path('fixtures/missing_title.yaml', __dir__)
      File.write(missing_title_path, "openapi: 3.0.0\ninfo:\n  version: 1.0.0\npaths: {}")

      parser = described_class.new(missing_title_path)

      expect { parser.parse }.to raise_error(Transducer::ValidationError, /Missing required field: info.title/)

      FileUtils.rm_f(missing_title_path)
    end

    it 'raises ValidationError for missing paths' do
      missing_paths_path = File.expand_path('fixtures/missing_paths.yaml', __dir__)
      File.write(missing_paths_path, "openapi: 3.0.0\ninfo:\n  title: Test\n  version: 1.0.0")

      parser = described_class.new(missing_paths_path)

      expect { parser.parse }.to raise_error(Transducer::ValidationError, /Missing required field: paths/)

      FileUtils.rm_f(missing_paths_path)
    end

    it 'raises ValidationError for non-hash specification' do
      non_hash_path = File.expand_path('fixtures/non_hash.yaml', __dir__)
      File.write(non_hash_path, "- item1\n- item2")

      parser = described_class.new(non_hash_path)

      expect { parser.parse }.to raise_error(Transducer::ValidationError, /must be a hash/)

      FileUtils.rm_f(non_hash_path)
    end
  end

  describe 'version support' do
    it 'accepts OpenAPI 3.0.x versions' do
      openapi_30_path = File.expand_path('fixtures/openapi_30.yaml', __dir__)
      File.write(openapi_30_path, "openapi: 3.0.3\ninfo:\n  title: Test\n  version: 1.0.0\npaths: {}")

      parser = described_class.new(openapi_30_path)
      data = parser.parse

      expect(data['openapi']).to eq('3.0.3')
      expect(parser).to be_valid

      FileUtils.rm_f(openapi_30_path)
    end

    it 'accepts OpenAPI 3.1.x versions' do
      openapi_31_path = File.expand_path('fixtures/openapi_31.yaml', __dir__)
      File.write(openapi_31_path, "openapi: 3.1.0\ninfo:\n  title: Test\n  version: 1.0.0\npaths: {}")

      parser = described_class.new(openapi_31_path)
      data = parser.parse

      expect(data['openapi']).to eq('3.1.0')
      expect(parser).to be_valid

      FileUtils.rm_f(openapi_31_path)
    end
  end

  describe 'complex validations' do
    it 'accumulates multiple validation errors' do
      multiple_errors_path = File.expand_path('fixtures/multiple_errors.yaml', __dir__)
      File.write(multiple_errors_path, "openapi: 3.0.0\ninfo: {}")

      parser = described_class.new(multiple_errors_path)

      expect { parser.parse }.to(
        raise_error(Transducer::ValidationError) do |error|
          expect(error.message).to include('info.title')
          expect(error.message).to include('info.version')
          expect(error.message).to include('paths')
        end
      )

      FileUtils.rm_f(multiple_errors_path)
    end
  end
end
