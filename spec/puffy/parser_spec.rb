# frozen_string_literal: true

require 'puffy'

RSpec.describe Puffy::Parser do
  subject(:parser) { described_class.new }

  let(:config) do
    <<~CONFIG
      localhost = {127.0.0.1 ::1}
    CONFIG
  end

  it 'parses successfuly' do
    expect { parser.parse(config) }.not_to raise_error
  end
end
