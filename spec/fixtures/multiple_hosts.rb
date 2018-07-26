# frozen_string_literal: true

host 'example.com', 'example.net' do
  pass :in, proto: :tcp, to: { port: 'postgresql' }
end
