# frozen_string_literal: true

host(/db\d+.example.com/) do
  pass :in, proto: :tcp, from: { host: '192.168.0.0/24' }, to: { port: 'postgresql' }
end

host 'db1.example.com' do
  pass :in, proto: :tcp, from: { host: '192.168.0.0/24' }, to: { port: 'postgresql' }
  block :in, proto: :tcp, to: { port: 'mysql' }
end
