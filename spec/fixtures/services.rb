# frozen_string_literal: true

service :openvpn do
  pass proto: %w[udp tcp], to: { port: 'openvpn' }
end

service :ssh do
  pass :in, proto: 'tcp', to: { port: 'ssh' }
end

node 'server.example.com' do
  server :openvpn
end

node 'client.example.com' do
  client :openvpn
end

node 'restricted.client.example.com' do
  client :openvpn, to: { host: '10.0.0.1' }
end

node 'invalid.client1.example.com' do
  service :openvpn
end

node 'invalid.client2.example.com' do
  server :ssh
end
