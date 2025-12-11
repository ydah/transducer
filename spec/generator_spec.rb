# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Transducer::Generator do
  let(:simple_api_path) { File.expand_path('fixtures/simple_api.yaml', __dir__) }
  let(:parser) { Transducer::Parser.new(simple_api_path) }
  let(:parsed_data) { parser.parse }
  let(:generator) { described_class.new(parsed_data) }

  describe '#generate' do
    it 'generates markdown with correct structure' do
      result = generator.generate

      expect(result).to include('# Simple API')
      expect(result).to include('| Version | 1.0.0 |')
      expect(result).to include('## Table of Contents')
      expect(result).to include('## Endpoints')
      expect(result).to include('## Schemas')
    end

    it 'includes table of contents' do
      result = generator.generate

      expect(result).to include('- [Endpoints](#endpoints)')
      expect(result).to include('- [Schemas](#schemas)')
    end

    it 'includes all endpoints' do
      result = generator.generate

      expect(result).to include('### GET /users')
      expect(result).to include('### POST /users')
      expect(result).to include('### GET /users/{id}')
    end

    it 'includes all schemas' do
      result = generator.generate

      expect(result).to include('### User')
      expect(result).to include('### UserInput')
    end

    it 'handles endpoints without parameters' do
      data = {
        'openapi' => '3.0.0',
        'info' => { 'title' => 'Test', 'version' => '1.0.0' },
        'paths' => {
          '/test' => {
            'get' => {
              'description' => 'Test endpoint'
            }
          }
        }
      }
      gen = described_class.new(data)
      result = gen.generate

      expect(result).to include('### GET /test')
      expect(result).to include('Test endpoint')
    end
  end

  describe '#to_file' do
    let(:output_path) { File.expand_path('../tmp/output.md', __dir__) }

    before do
      FileUtils.rm_f(output_path)
    end

    after do
      FileUtils.rm_f(output_path)
    end

    it 'writes markdown to specified file' do
      generator.to_file(output_path)

      expect(File).to exist(output_path)
      content = File.read(output_path)
      expect(content).to include('# Simple API')
    end

    it 'creates parent directories if needed' do
      nested_path = File.expand_path('../tmp/nested/dir/output.md', __dir__)
      FileUtils.rm_rf(File.dirname(nested_path))

      generator.to_file(nested_path)

      expect(File).to exist(nested_path)

      FileUtils.rm_rf(File.expand_path('../tmp', __dir__))
    end

    it 'raises FileError on permission denied' do
      allow(File).to receive(:write).and_raise(Errno::EACCES)

      expect do
        generator.to_file(output_path)
      end.to raise_error(Transducer::FileError, /Permission denied/)
    end

    it 'raises FileError on write failure' do
      allow(File).to receive(:write).and_raise(StandardError, 'Write failed')

      expect do
        generator.to_file(output_path)
      end.to raise_error(Transducer::FileError, /Failed to write file/)
    end
  end

  describe 'header generation' do
    it 'includes server information when available' do
      data_with_server = parsed_data.merge(
        'servers' => [{ 'url' => 'https://api.example.com' }]
      )
      gen = described_class.new(data_with_server)
      result = gen.generate

      expect(result).to include('| Base URL | https://api.example.com |')
    end

    it 'omits server information when not available' do
      data_without_server = parsed_data.dup
      data_without_server.delete('servers')
      gen = described_class.new(data_without_server)
      result = gen.generate

      expect(result).not_to include('| Base URL |')
    end

    it 'handles empty servers array' do
      data_with_empty_servers = parsed_data.merge('servers' => [])
      gen = described_class.new(data_with_empty_servers)
      result = gen.generate

      expect(result).not_to include('| Base URL |')
    end

    it 'includes description when available' do
      data_with_description = parsed_data
      data_with_description['info']['description'] = 'This is a test API'
      gen = described_class.new(data_with_description)
      result = gen.generate

      expect(result).to include('This is a test API')
    end
  end

  describe 'template support' do
    let(:custom_template_path) { File.expand_path('fixtures/custom_template.md.erb', __dir__) }

    it 'uses custom template when provided' do
      File.write(custom_template_path,
                 "# Custom: <%= data['info']['title'] %>\nVersion: <%= data['info']['version'] %>")

      gen = described_class.new(parsed_data, template_path: custom_template_path)
      result = gen.generate

      expect(result).to include('# Custom: Simple API')
      expect(result).to include('Version: 1.0.0')

      FileUtils.rm_f(custom_template_path)
    end

    it 'raises error for non-existent template' do
      gen = described_class.new(parsed_data, template_path: '/nonexistent/template.erb')

      expect { gen.generate }.to raise_error(Transducer::FileError, /Template file not found/)
    end

    it 'raises error for template rendering errors' do
      File.write(custom_template_path, '<%= undefined_variable %>')

      gen = described_class.new(parsed_data, template_path: custom_template_path)

      expect { gen.generate }.to raise_error(Transducer::FileError, /Failed to render template/)

      FileUtils.rm_f(custom_template_path)
    end

    it 'provides access to data and formatter in template' do
      File.write(custom_template_path, "<%= formatter.class.name %>\n<%= data.keys.join(', ') %>")

      gen = described_class.new(parsed_data, template_path: custom_template_path)
      result = gen.generate

      expect(result).to include('Transducer::Formatter')
      expect(result).to include('openapi')
      expect(result).to include('info')

      FileUtils.rm_f(custom_template_path)
    end
  end

  describe 'edge cases' do
    it 'handles API without paths' do
      data = {
        'openapi' => '3.0.0',
        'info' => { 'title' => 'Empty API', 'version' => '1.0.0' }
      }
      gen = described_class.new(data)
      result = gen.generate

      expect(result).to include('# Empty API')
      expect(result).not_to include('## Endpoints')
    end

    it 'handles API without schemas' do
      data = {
        'openapi' => '3.0.0',
        'info' => { 'title' => 'No Schema API', 'version' => '1.0.0' },
        'paths' => {
          '/test' => {
            'get' => { 'description' => 'Test' }
          }
        }
      }
      gen = described_class.new(data)
      result = gen.generate

      expect(result).to include('# No Schema API')
      expect(result).not_to include('## Schemas')
    end

    it 'skips special keys starting with $' do
      data = {
        'openapi' => '3.0.0',
        'info' => { 'title' => 'Test API', 'version' => '1.0.0' },
        'paths' => {
          '/test' => {
            'get' => { 'description' => 'Test' },
            '$ref' => '#/components/paths/test'
          }
        }
      }
      gen = described_class.new(data)
      result = gen.generate

      expect(result).to include('### GET /test')
      expect(result).not_to include('### $REF')
    end

    it 'handles schema with example' do
      data = {
        'openapi' => '3.0.0',
        'info' => { 'title' => 'Test', 'version' => '1.0.0' },
        'components' => {
          'schemas' => {
            'TestSchema' => {
              'type' => 'object',
              'properties' => {
                'id' => { 'type' => 'string' }
              },
              'example' => { 'id' => '123' }
            }
          }
        }
      }
      gen = described_class.new(data)
      result = gen.generate

      expect(result).to include('**Example**:')
      expect(result).to include('```json')
    end

    it 'handles schema with description' do
      data = {
        'openapi' => '3.0.0',
        'info' => { 'title' => 'Test', 'version' => '1.0.0' },
        'components' => {
          'schemas' => {
            'TestSchema' => {
              'description' => 'A test schema',
              'type' => 'object'
            }
          }
        }
      }
      gen = described_class.new(data)
      result = gen.generate

      expect(result).to include('A test schema')
    end
  end
end
