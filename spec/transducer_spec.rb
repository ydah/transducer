# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Transducer do
  it 'has a version number' do
    expect(Transducer::VERSION).not_to be_nil
  end

  it 'defines custom error classes' do
    expect(Transducer::Error).to be < StandardError
    expect(Transducer::ParseError).to be < Transducer::Error
    expect(Transducer::ValidationError).to be < Transducer::Error
    expect(Transducer::FileError).to be < Transducer::Error
  end
end
