# frozen_string_literal: true

require 'spec_helper'
require 'fileutils'

RSpec.describe Transducer::CLI do
  let(:simple_api_path) { File.expand_path('fixtures/simple_api.yaml', __dir__) }
  let(:output_path) { File.expand_path('../tmp/cli_output.md', __dir__) }

  before do
    FileUtils.rm_f(output_path)
  end

  after do
    FileUtils.rm_f(output_path)
  end

  describe 'generate command' do
    it 'generates markdown from input file' do
      cli = described_class.new
      cli.options = { output: output_path }

      expect { cli.generate(simple_api_path) }.to output(/Documentation generated successfully/).to_stdout

      expect(File).to exist(output_path)
    end

    it 'uses default output path when not specified' do
      default_output_path = 'docs/openapi.md'
      FileUtils.rm_f(default_output_path)

      expect do
        described_class.start(['generate', simple_api_path])
      end.to output(/Documentation generated successfully/).to_stdout

      expect(File).to exist(default_output_path)

      FileUtils.rm_f(default_output_path)
      FileUtils.rm_rf('docs')
    end

    it 'handles missing input file' do
      cli = described_class.new
      cli.options = { output: output_path }

      expect { cli.generate('/nonexistent.yaml') }.to raise_error(SystemExit)
    end

    it 'handles parse errors with exit code 2' do
      invalid_yaml_path = File.expand_path('fixtures/syntax_error.yaml', __dir__)
      File.write(invalid_yaml_path, "invalid: yaml: content:\n  - malformed")

      cli = described_class.new
      cli.options = { output: output_path }

      begin
        cli.generate(invalid_yaml_path)
      rescue SystemExit => e
        expect(e.status).to eq(2)
      end

      FileUtils.rm_f(invalid_yaml_path)
    end

    it 'handles validation errors with exit code 3' do
      cli = described_class.new
      cli.options = { output: output_path }

      expect do
        cli.generate(File.expand_path('fixtures/invalid_api.yaml', __dir__))
      rescue SystemExit => e
        expect(e.status).to eq(3)
        raise
      end.to raise_error(SystemExit)
    end

    it 'handles unexpected errors with exit code 4' do
      cli = described_class.new
      cli.options = { output: output_path }

      allow(Transducer::Parser).to receive(:new).and_raise(StandardError, 'Unexpected error')

      expect do
        cli.generate(simple_api_path)
      rescue SystemExit => e
        expect(e.status).to eq(4)
        raise
      end.to raise_error(SystemExit)
    end
  end

  describe 'template option' do
    let(:custom_template_path) { File.expand_path('fixtures/test_template.md.erb', __dir__) }

    it 'generates documentation with custom template' do
      File.write(custom_template_path, "# Custom: <%= data['info']['title'] %>")

      cli = described_class.new
      cli.options = { output: output_path, template: custom_template_path }

      expect { cli.generate(simple_api_path) }.to output(/Documentation generated successfully/).to_stdout

      expect(File).to exist(output_path)
      content = File.read(output_path)
      expect(content).to include('# Custom: Simple API')

      FileUtils.rm_f(custom_template_path)
    end

    it 'handles missing template file' do
      cli = described_class.new
      cli.options = { output: output_path, template: '/nonexistent/template.erb' }

      expect do
        cli.generate(simple_api_path)
      rescue SystemExit => e
        expect(e.status).to eq(1)
        raise
      end.to raise_error(SystemExit)
    end
  end

  describe 'version command' do
    it 'displays version information' do
      cli = described_class.new

      expect { cli.version }.to output(/Transducer version #{Transducer::VERSION}/).to_stdout
    end
  end
end
