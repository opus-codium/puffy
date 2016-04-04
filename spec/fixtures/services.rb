service :openvpn do
  pass proto: %w(udp tcp), to: { port: 'openvpn' }
end

host 'server.example.com' do
  server :openvpn
end

host 'client.example.com' do
  client :openvpn
end
