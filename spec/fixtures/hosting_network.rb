# frozen_string_literal: true

node(/db\d+.example.com/) do
  pass :in, proto: :tcp, from: { host: '192.168.0.0/24' }, to: { port: 'postgresql' }
end

node 'db1.example.com' do
  pass :in, proto: :tcp, from: { host: '192.168.0.0/24' }, to: { port: 'postgresql' }
  block :in, proto: :tcp, to: { port: 'mysql' }
end
