dns_servers = %w(ns1 ns2)

service :dns do
  pass :out, proto: :udp, to: { host: dns_servers, port: 'domain' }
end

host 'gw' do
  service :dns
  nat on: 'ppp0'
  pass on: 'ppp0', proto: :tcp, to: { port: 'http' }, rdr_to: { host: 'www' }
end

host 'www' do
  service :dns
  pass :in, proto: :tcp, to: { port: 'http' }
end
