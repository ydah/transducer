# frozen_string_literal: true

require_relative 'lib/transducer/version'

Gem::Specification.new do |spec|
  spec.name = 'transducer'
  spec.version = Transducer::VERSION
  spec.authors = ['Yudai Takada']
  spec.email = ['t.yudai92@gmail.com']

  spec.summary = 'Generate Markdown documentation from OpenAPI specifications'
  spec.description = 'A Ruby gem that reads OpenAPI YAML specifications and generates ' \
                     'well-formatted Markdown documentation'
  spec.homepage = 'https://github.com/ydah/transducer'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.0.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir['lib/**/*', 'exe/*', 'LICENSE.txt', 'README.md', 'CHANGELOG.md']
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'psych', '~> 4.0'
  spec.add_dependency 'thor', '~> 1.3'
end
