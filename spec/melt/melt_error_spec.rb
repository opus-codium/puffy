# frozen_string_literal: true

require 'melt'

RSpec.describe Melt::MeltError do
  let(:token) do
    {
      filename: 'filename.ext',
      lineno:   12,
      line:     '1234567890',
      position: 4,
      length:   3,
    }
  end

  subject do
    Melt::MeltError.new('Message', token)
  end

  it 'reports the correct location in file' do
    expect(subject.to_s).to match(/^filename.ext:12:5: Message/)
  end
  it 'highlights the correct location in the line' do
    expect(subject.to_s).to match(/^    \^~~$/)
  end
end
