require 'melt'

module Melt
  module Formatters
    RSpec.describe Netfilter do
      let(:formatter) { Netfilter.new }
      it 'formats simple rules' do
        rule = Rule.new(action: :pass, dir: :in, proto: :tcp, to: { host: nil, port: 80 })
        expect(formatter.emit_rule(rule)).to eq('-A INPUT -p tcp --dport 80 -j ACCEPT')

        rule = Rule.new(action: :pass, dir: :in, on: 'lo')
        expect(formatter.emit_rule(rule)).to eq('-A INPUT -i lo -j ACCEPT')

        rule = Rule.new(action: :block, dir: :in, on: '!lo', to: { host: IPAddress.parse('127.0.0.0/8') })
        expect(formatter.emit_rule(rule)).to eq('-A INPUT ! -i lo -d 127.0.0.0/8 -j DROP')

        rule = Rule.new(action: :pass, dir: :out)
        expect(formatter.emit_rule(rule)).to eq('-A OUTPUT -j ACCEPT')
      end

      it 'returns packets when instructed so' do
        rule = Rule.new(action: :block, return: true, dir: :in, proto: :icmp)
        expect(formatter.emit_rule(rule)).to eq('-A INPUT -p icmp -j RETURN')
      end
    end
  end
end
