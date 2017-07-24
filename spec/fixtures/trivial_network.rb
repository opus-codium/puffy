# frozen_string_literal: true

host 'localhost' do
  pass :out, proto: :udp, to: { host: ['192.0.2.27'], port: 'domain' }
  pass :in, proto: :tcp, to: { port: 'ssh' }
end
