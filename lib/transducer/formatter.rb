# frozen_string_literal: true

module Transducer
  class Formatter
    def format_endpoint(path, method, details)
      output = []
      output << "### #{method.upcase} #{path}"
      output << ''
      output << details['description'] if details['description']
      output << ''
      output << format_parameters(details['parameters']) if details['parameters']
      output << format_request_body(details['requestBody']) if details['requestBody']
      output << format_responses(details['responses']) if details['responses']
      output.join("\n")
    end

    def format_parameters(parameters)
      return '' if parameters.nil? || parameters.empty?

      output = []
      output << '**Parameters**:'
      output << ''
      output << '| Name | Location | Type | Required | Description |'
      output << '|------|----------|------|----------|-------------|'

      parameters.each do |param|
        name = param['name'] || 'N/A'
        location = param['in'] || 'N/A'
        type = extract_type(param['schema'])
        required = param['required'] ? 'Yes' : 'No'
        description = param['description'] || ''
        output << "| #{name} | #{location} | #{type} | #{required} | #{description} |"
      end

      output << ''
      output.join("\n")
    end

    def format_request_body(request_body)
      return '' unless request_body

      output = []
      output << '**Request Body**:'
      output << ''

      if request_body['description']
        output << request_body['description']
        output << ''
      end

      request_body['content']&.each do |content_type, details|
        output << "**Content-Type**: `#{content_type}`"
        output << ''
        output << format_schema(details['schema']) if details['schema']
        next unless details['example']

        output << '**Example**:'
        output << ''
        output << '```json'
        output << JSON.pretty_generate(details['example'])
        output << '```'
        output << ''
      end

      output.join("\n")
    end

    def format_responses(responses)
      return '' unless responses

      output = []
      output << '**Responses**:'
      output << ''

      responses.each do |status_code, response|
        output << "#### #{status_code} #{status_name(status_code)}"
        output << ''
        output << response['description'] if response['description']
        output << ''

        next unless response['content']

        response['content'].each do |content_type, details|
          output << "**Content-Type**: `#{content_type}`"
          output << ''
          if details['schema']
            output << '**Schema**:'
            output << ''
            output << '```json'
            output << JSON.pretty_generate(details['schema'])
            output << '```'
            output << ''
          end
          next unless details['example']

          output << '**Example**:'
          output << ''
          output << '```json'
          output << JSON.pretty_generate(details['example'])
          output << '```'
          output << ''
        end
      end

      output.join("\n")
    end

    def format_schema(schema)
      return '' unless schema

      output = []

      if schema['$ref']
        ref_name = schema['$ref'].split('/').last
        output << "**Schema**: `#{ref_name}`"
        output << ''
        return output.join("\n")
      end

      output << "**Type**: #{schema['type']}" if schema['type']
      output << ''

      if schema['properties']
        output << '**Properties**:'
        output << ''
        output << '| Name | Type | Required | Description |'
        output << '|------|------|----------|-------------|'

        required_fields = schema['required'] || []
        schema['properties'].each do |prop_name, prop_details|
          type = extract_type(prop_details)
          is_required = required_fields.include?(prop_name) ? 'Yes' : 'No'
          description = prop_details['description'] || ''
          output << "| #{prop_name} | #{type} | #{is_required} | #{description} |"
        end
        output << ''
      end

      output.join("\n")
    end

    private

    def extract_type(schema)
      return 'N/A' unless schema

      if schema['$ref']
        schema['$ref'].split('/').last
      elsif schema['type']
        type = schema['type']
        if type == 'array' && schema['items']
          item_type = extract_type(schema['items'])
          "array[#{item_type}]"
        else
          type
        end
      else
        'object'
      end
    end

    def status_name(code)
      names = {
        '200' => 'OK',
        '201' => 'Created',
        '204' => 'No Content',
        '400' => 'Bad Request',
        '401' => 'Unauthorized',
        '403' => 'Forbidden',
        '404' => 'Not Found',
        '500' => 'Internal Server Error'
      }
      names[code.to_s] || ''
    end
  end
end
