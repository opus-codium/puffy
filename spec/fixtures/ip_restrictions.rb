server = ['192.0.2.1', '2001:DB8::1']

host 'client' do
  pass :out, on: 'eth0', proto: :tcp, to: { host: server, port: 3000 }
  ipv4 do
    pass :out, on: 'eth0', proto: :tcp, to: { host: server, port: 3001 }
  end
  ipv6 do
    pass :out, on: 'eth0', proto: :tcp, to: { host: server, port: 3002 }
  end
end
