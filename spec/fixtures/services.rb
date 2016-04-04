service :openvpn do
  pass proto: %w(udp tcp), to: { port: 'openvpn' }
end

service :ssh do
  pass :in, proto: 'tcp', to: { port: 'ssh' }
end

host 'server.example.com' do
  server :openvpn
end

host 'client.example.com' do
  client :openvpn
end

host 'restricted.client.example.com' do
  client :openvpn, to: { host: '10.0.0.1' }
end

host 'invalid.client1.example.com' do
  service :openvpn
end

host 'invalid.client2.example.com' do
  server :ssh
end
