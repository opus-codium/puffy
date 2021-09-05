# frozen_string_literal: true

node 'example.com', 'example.net' do
  pass :in, proto: :tcp, to: { port: 'postgresql' }
end
