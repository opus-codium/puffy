require 'melt'

module Melt
  module Formatters
    RSpec.describe Pf do
      let(:formatter) { Pf.new }

      it 'formats simple rules' do
        rule = Rule.new(action: :pass, dir: :out, proto: :tcp)
        expect(formatter.emit_rule(rule)).to eq('pass out quick proto tcp all')

        rule = Rule.new(action: :pass, dir: :in, proto: :tcp, dst: { host: nil, port: 80 })
        expect(formatter.emit_rule(rule)).to eq('pass in quick proto tcp to any port 80')

        rule = Rule.new(action: :pass, dir: :in, proto: :udp, src: { port: 123 }, dst: { port: 123 })
        expect(formatter.emit_rule(rule)).to eq('pass in quick proto udp from any port 123 to any port 123')
      end

      it 'generates non-quick rules' do
        rule = Rule.new(action: :block, dir: :in, no_quick: true)
        expect(formatter.emit_rule(rule)).to eq('block in all')
      end
    end
  end
end
