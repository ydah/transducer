# frozen_string_literal: true

require_relative 'transducer/version'
require_relative 'transducer/parser'
require_relative 'transducer/formatter'
require_relative 'transducer/generator'
require_relative 'transducer/cli'

module Transducer
  class Error < StandardError; end
  class ParseError < Error; end
  class ValidationError < Error; end
  class FileError < Error; end
end
