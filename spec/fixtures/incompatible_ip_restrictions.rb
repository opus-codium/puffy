# frozen_string_literal: true

server = ['192.0.2.1', '2001:DB8::1']

host 'client' do
  ipv4 do
    ipv6 do
      pass :out, on: 'eth0', proto: :tcp, to: { host: server, port: 3000 }
    end
  end
end
