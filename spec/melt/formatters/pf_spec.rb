require 'melt'

module Melt
  module Formatters
    RSpec.describe Pf do
      it 'formats simple rules' do
        rule = Rule.new(action: :pass, dir: :out, proto: :tcp)
        expect(subject.emit_rule(rule)).to eq('pass out quick proto tcp')

        rule = Rule.new(action: :pass, dir: :in, proto: :tcp, to: { host: nil, port: 80 })
        expect(subject.emit_rule(rule)).to eq('pass in quick proto tcp to port 80')

        rule = Rule.new(action: :block, dir: :in, proto: :icmp)
        expect(subject.emit_rule(rule)).to eq('block in quick proto icmp')

        rule = Rule.new(action: :pass, dir: :in, proto: :udp, from: { port: 123 }, to: { port: 123 })
        expect(subject.emit_rule(rule)).to eq('pass in quick proto udp from port 123 to port 123')
      end

      it 'generates non-quick rules' do
        rule = Rule.new(action: :block, dir: :in, no_quick: true)
        expect(subject.emit_rule(rule)).to eq('block in')
      end

      it 'returns packets when instructed so' do
        rule = Rule.new(action: :block, return: true, dir: :in, proto: :icmp)
        expect(subject.emit_rule(rule)).to eq('block return in quick proto icmp')
      end

      it 'formats redirect rules' do
        rule = Rule.new(action: :pass, dir: :in, on: 'eth0', proto: :tcp, to: { port: 80 }, rdr_to: { host: IPAddress.parse('127.0.0.1/32'), port: 3128 })
        expect(subject.emit_rule(rule)).to eq('pass in quick on eth0 proto tcp to port 80 divert-to 127.0.0.1 port 3128')
      end
    end
  end
end
