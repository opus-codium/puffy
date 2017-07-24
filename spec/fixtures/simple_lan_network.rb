# frozen_string_literal: true

dns_servers = ['192.168.0.53', '192.168.1.53']

service :dns do
  pass :out, proto: :udp, to: { host: dns_servers, port: 'domain' }
end

host 'gw' do
  service :dns
  pass :out, on: 'ppp0', nat_to: '198.51.100.72'
  pass :in, on: 'ppp0', proto: :tcp, to: { port: 'http' }, rdr_to: { host: '192.168.1.80' }
end

host 'www' do
  service :dns
  pass :in, proto: :tcp, to: { port: 'http' }
end
