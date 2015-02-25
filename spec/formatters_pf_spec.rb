require 'melt'

module Melt
  module Formatters
    RSpec.describe Pf do
      it 'formats simple rules' do
        formatter = Pf.new

        rule = Rule.new(action: :pass, dir: :out, proto: :tcp)
        expect(formatter.emit_rule(rule)).to eq('pass out proto tcp all')

        rule = Rule.new(action: :pass, dir: :in, proto: :tcp, dst: { host: nil, port: 80 })
        expect(formatter.emit_rule(rule)).to eq('pass in proto tcp to any port 80')

        rule = Rule.new(action: :pass, dir: :in, proto: :udp, src: { port: 123 }, dst: { port: 123 })
        expect(formatter.emit_rule(rule)).to eq('pass in proto udp from any port 123 to any port 123')
      end
    end
  end
end
