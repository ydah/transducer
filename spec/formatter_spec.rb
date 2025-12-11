# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Transducer::Formatter do
  let(:formatter) { described_class.new }

  describe '#format_endpoint' do
    it 'formats GET endpoint correctly' do
      details = {
        'description' => 'Get all users',
        'parameters' => [
          { 'name' => 'limit', 'in' => 'query', 'schema' => { 'type' => 'integer' }, 'required' => false }
        ]
      }

      result = formatter.format_endpoint('/users', 'get', details)

      expect(result).to include('### GET /users')
      expect(result).to include('Get all users')
      expect(result).to include('| limit | query | integer | No |')
    end

    it 'formats POST endpoint correctly' do
      details = {
        'description' => 'Create a user',
        'requestBody' => {
          'content' => {
            'application/json' => {
              'schema' => { 'type' => 'object' }
            }
          }
        }
      }

      result = formatter.format_endpoint('/users', 'post', details)

      expect(result).to include('### POST /users')
      expect(result).to include('Create a user')
      expect(result).to include('**Request Body**:')
    end
  end

  describe '#format_parameters' do
    it 'formats path parameters correctly' do
      parameters = [
        { 'name' => 'id', 'in' => 'path', 'schema' => { 'type' => 'string' }, 'required' => true,
          'description' => 'User ID' }
      ]

      result = formatter.format_parameters(parameters)

      expect(result).to include('| Name | Location | Type | Required | Description |')
      expect(result).to include('| id | path | string | Yes | User ID |')
    end

    it 'handles required and optional parameters' do
      parameters = [
        { 'name' => 'id', 'in' => 'path', 'schema' => { 'type' => 'string' }, 'required' => true },
        { 'name' => 'limit', 'in' => 'query', 'schema' => { 'type' => 'integer' }, 'required' => false }
      ]

      result = formatter.format_parameters(parameters)

      expect(result).to include('| id | path | string | Yes |')
      expect(result).to include('| limit | query | integer | No |')
    end
  end

  describe '#format_schema' do
    it 'formats object schema' do
      schema = {
        'type' => 'object',
        'required' => %w[id name],
        'properties' => {
          'id' => { 'type' => 'string', 'description' => 'User ID' },
          'name' => { 'type' => 'string', 'description' => 'User name' },
          'email' => { 'type' => 'string', 'description' => 'User email' }
        }
      }

      result = formatter.format_schema(schema)

      expect(result).to include('**Type**: object')
      expect(result).to include('| id | string | Yes | User ID |')
      expect(result).to include('| name | string | Yes | User name |')
      expect(result).to include('| email | string | No | User email |')
    end

    it 'handles $ref references' do
      schema = { '$ref' => '#/components/schemas/User' }

      result = formatter.format_schema(schema)

      expect(result).to include('**Schema**: `User`')
    end

    it 'formats array schema' do
      schema = {
        'type' => 'array',
        'items' => { 'type' => 'string' }
      }

      result = formatter.format_schema(schema)

      expect(result).to include('**Type**: array')
    end
  end

  describe '#format_responses' do
    it 'formats multiple response codes' do
      responses = {
        '200' => {
          'description' => 'Success',
          'content' => {
            'application/json' => {
              'schema' => { 'type' => 'object' }
            }
          }
        },
        '404' => {
          'description' => 'Not found'
        }
      }

      result = formatter.format_responses(responses)

      expect(result).to include('#### 200 OK')
      expect(result).to include('Success')
      expect(result).to include('#### 404 Not Found')
      expect(result).to include('Not found')
    end

    it 'handles various status codes' do
      responses = {
        '201' => { 'description' => 'Created' },
        '204' => { 'description' => 'No Content' },
        '400' => { 'description' => 'Bad Request' },
        '401' => { 'description' => 'Unauthorized' },
        '403' => { 'description' => 'Forbidden' },
        '500' => { 'description' => 'Internal Server Error' }
      }

      result = formatter.format_responses(responses)

      expect(result).to include('#### 201 Created')
      expect(result).to include('#### 204 No Content')
      expect(result).to include('#### 400 Bad Request')
      expect(result).to include('#### 401 Unauthorized')
      expect(result).to include('#### 403 Forbidden')
      expect(result).to include('#### 500 Internal Server Error')
    end

    it 'handles unknown status codes' do
      responses = {
        '418' => { 'description' => "I'm a teapot" }
      }

      result = formatter.format_responses(responses)

      expect(result).to include('#### 418')
      expect(result).to include("I'm a teapot")
    end
  end

  describe '#format_endpoint' do
    it 'handles endpoint without description' do
      details = {
        'parameters' => []
      }

      result = formatter.format_endpoint('/test', 'get', details)

      expect(result).to include('### GET /test')
      expect(result).not_to include('description')
    end

    it 'handles endpoint with all components' do
      details = {
        'description' => 'Test endpoint',
        'parameters' => [
          { 'name' => 'id', 'in' => 'path', 'schema' => { 'type' => 'string' }, 'required' => true }
        ],
        'requestBody' => {
          'content' => {
            'application/json' => {
              'schema' => { 'type' => 'object' }
            }
          }
        },
        'responses' => {
          '200' => { 'description' => 'OK' }
        }
      }

      result = formatter.format_endpoint('/test', 'post', details)

      expect(result).to include('### POST /test')
      expect(result).to include('Test endpoint')
      expect(result).to include('**Parameters**:')
      expect(result).to include('**Request Body**:')
      expect(result).to include('**Responses**:')
    end
  end

  describe 'edge cases' do
    it 'handles nil parameters' do
      result = formatter.format_parameters(nil)

      expect(result).to eq('')
    end

    it 'handles empty parameters array' do
      result = formatter.format_parameters([])

      expect(result).to eq('')
    end

    it 'handles nested array types' do
      schema = {
        'type' => 'array',
        'items' => {
          'type' => 'array',
          'items' => { 'type' => 'string' }
        }
      }

      result = formatter.format_schema(schema)

      expect(result).to include('**Type**: array')
    end

    it 'handles schema without type' do
      schema = {
        'properties' => {
          'name' => { 'type' => 'string' }
        }
      }

      result = formatter.format_schema(schema)

      expect(result).to include('**Properties**:')
    end

    it 'handles parameter without description' do
      parameters = [
        { 'name' => 'id', 'in' => 'query', 'schema' => { 'type' => 'string' }, 'required' => true }
      ]

      result = formatter.format_parameters(parameters)

      expect(result).to include('| id | query | string | Yes |  |')
    end

    it 'handles request body with multiple content types' do
      request_body = {
        'content' => {
          'application/json' => {
            'schema' => { 'type' => 'object' }
          },
          'application/xml' => {
            'schema' => { 'type' => 'object' }
          }
        }
      }

      result = formatter.format_request_body(request_body)

      expect(result).to include('**Content-Type**: `application/json`')
      expect(result).to include('**Content-Type**: `application/xml`')
    end
  end
end
