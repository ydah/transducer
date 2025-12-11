# Transducer

Generate Markdown documentation from OpenAPI specifications.

Transducer is a Ruby gem that reads OpenAPI YAML specifications (versions 3.0.x and 3.1.x) and generates well-formatted, readable Markdown documentation.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'transducer'
```

And then execute:

```bash
$ bundle install
```

Or install it yourself as:

```bash
$ gem install transducer
```

## Usage

### Command Line

Generate Markdown documentation from an OpenAPI specification:

```bash
$ transducer generate input.yaml -o output.md
```

Options:
- `-o, --output`: Output file path (default: `docs/openapi.md`)
- `-t, --template`: Custom ERB template file path

#### Using Custom Templates

You can customize the output format using ERB templates:

```bash
$ transducer generate input.yaml --template=custom.md.erb --output=api.md
```

Template variables available:
- `data`: Parsed OpenAPI specification hash
- `formatter`: Formatter instance for formatting endpoints, parameters, schemas, etc.

Example custom template:

```erb
# <%= data['info']['title'] %>

<% data['paths']&.each do |path, methods| %>
  <% methods.each do |method, details| %>
### <%= method.upcase %> <%= path %>
<%= formatter.format_endpoint(path, method, details) %>
  <% end %>
<% end %>
```

Display version information:

```bash
$ transducer version
```

Display help:

```bash
$ transducer help
$ transducer help generate
```

### Programmatic Usage

You can also use Transducer programmatically in your Ruby code:

```ruby
require 'transducer'

# Parse OpenAPI specification
parser = Transducer::Parser.new('path/to/openapi.yaml')
data = parser.parse

# Generate Markdown with default template
generator = Transducer::Generator.new(data)
markdown = generator.generate

# Or use a custom template
generator = Transducer::Generator.new(data, template_path: 'custom.md.erb')
markdown = generator.generate

# Write to file
generator.to_file('output.md')
```

## Output Format

The generated Markdown documentation includes:

- API Title and Description: From the `info` section
- Version and Base URL: API version and server URL
- Table of Contents: Automatically generated with links to all sections
- Endpoints: All API endpoints with:
  - HTTP method and path
  - Description
  - Parameters (path, query, header)
  - Request body schema and examples
  - Response codes with schemas and examples
- Schemas: Component schemas with:
  - Type information
  - Property descriptions
  - Required fields
  - Examples

### Example Output

```markdown
# Simple API

A simple API for testing

| | |
|---|---|
| Version | 1.0.0 |
| Base URL | https://api.example.com/v1 |

## Table of Contents

- [Endpoints](#endpoints)
  - [GET /users](#get-users)
  - [POST /users](#post-users)
- [Schemas](#schemas)
  - [User](#user)

## Endpoints

### GET /users

Returns a list of all users

**Parameters**:

| Name | Location | Type | Required | Description |
|------|----------|------|----------|-------------|
| limit | query | integer | No | Maximum number of users to return |

**Responses**:

#### 200 OK

Successful response
...
```

## Supported OpenAPI Versions

- OpenAPI 3.0.x
- OpenAPI 3.1.x

OpenAPI 2.0 (Swagger) is not currently supported.

## Development

After checking out the repo, run `bundle install` to install dependencies.

Run tests:

```bash
$ bundle exec rspec
```

Run RuboCop:

```bash
$ bundle exec rubocop
```

Run all checks (tests + RuboCop):

```bash
$ bundle exec rake
```

To install this gem onto your local machine:

```bash
$ bundle exec rake install
```

To release a new version:

1. Update the version number in `lib/transducer/version.rb`
2. Update `CHANGELOG.md`
3. Run `bundle exec rake release`

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ydah/transducer.

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
