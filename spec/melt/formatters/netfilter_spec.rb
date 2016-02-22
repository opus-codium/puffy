require 'melt'

module Melt
  module Formatters
    RSpec.describe Netfilter do
      it 'formats simple rules' do
        rule = Rule.new(action: :pass, dir: :in, proto: :tcp, to: { host: nil, port: 80 })
        expect(subject.emit_rule(rule)).to eq('-A INPUT -p tcp --dport 80 -j ACCEPT')

        rule = Rule.new(action: :pass, dir: :in, on: 'lo')
        expect(subject.emit_rule(rule)).to eq('-A INPUT -i lo -j ACCEPT')

        rule = Rule.new(action: :block, dir: :in, on: '!lo', to: { host: IPAddress.parse('127.0.0.0/8') })
        expect(subject.emit_rule(rule)).to eq('-A INPUT ! -i lo -d 127.0.0.0/8 -j DROP')

        rule = Rule.new(action: :pass, dir: :out)
        expect(subject.emit_rule(rule)).to eq('-A OUTPUT -j ACCEPT')
      end

      it 'returns packets when instructed so' do
        rule = Rule.new(action: :block, return: true, dir: :in, proto: :icmp)
        expect(subject.emit_rule(rule)).to eq('-A INPUT -p icmp -j RETURN')
      end

      it 'formats forward rules' do
        rule = Rule.new(action: :pass, dir: :fwd, in: 'eth1', out: 'ppp0', from: { host: IPAddress.parse('192.168.0.0/24') })
        expect(subject.emit_rule(rule)).to eq('-A FORWARD -i eth1 -o ppp0 -s 192.168.0.0/24 -j ACCEPT')
      end

      it 'formats dnat rules' do
        rule = Rule.new(action: :pass, dir: :in, on: 'ppp0', proto: :tcp, to: { port: 80 }, rdr_to: { host: IPAddress.parse('192.168.0.42') })
        expect(subject.emit_rule(rule)).to eq('-A PREROUTING -i ppp0 -p tcp --dport 80 -j DNAT --to-destination 192.168.0.42')
      end

      it 'formats redirect rules' do
        rule = Rule.new(action: :pass, dir: :in, on: 'eth0', proto: :tcp, to: { port: 80 }, rdr_to: { host: IPAddress.parse('127.0.0.1/32'), port: 3128 })
        expect(subject.emit_rule(rule)).to eq('-A PREROUTING -i eth0 -p tcp --dport 80 -j REDIRECT --to-port 3128')
      end

      it 'formats nat rules' do
        rule = Rule.new(action: :pass, dir: :out, on: 'ppp0', nat_to: IPAddress.parse('198.51.100.72'))
        expect(subject.emit_rule(rule)).to eq('-A POSTROUTING -o ppp0 -j MASQUERADE')
      end
    end
  end
end
