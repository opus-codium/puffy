require 'melt'

module Melt
  module Formatters
    RSpec.describe Pf::Rule do
      it 'formats simple rules' do
        rule = Rule.new(action: :pass, dir: :out, proto: :tcp)
        expect(subject.emit_rule(rule)).to eq('pass out quick proto tcp')

        rule = Rule.new(action: :pass, dir: :in, proto: :tcp, to: { host: nil, port: 80 })
        expect(subject.emit_rule(rule)).to eq('pass in quick proto tcp to any port 80')

        rule = Rule.new(action: :block, dir: :in, proto: :icmp)
        expect(subject.emit_rule(rule)).to eq('block in quick proto icmp')

        rule = Rule.new(action: :pass, dir: :in, proto: :udp, from: { port: 123 }, to: { port: 123 })
        expect(subject.emit_rule(rule)).to eq('pass in quick proto udp from any port 123 to any port 123')
      end

      it 'generates non-quick rules' do
        rule = Rule.new(action: :block, dir: :in, no_quick: true)
        expect(subject.emit_rule(rule)).to eq('block in all')
      end

      it 'returns packets when instructed so' do
        rule = Rule.new(action: :block, return: true, dir: :in, proto: :icmp)
        expect(subject.emit_rule(rule)).to eq('block return in quick proto icmp')
      end

      context 'redirect rules' do
        it 'formats redirect rules' do
          rule = Rule.new(action: :pass, dir: :in, on: 'eth0', proto: :tcp, to: { port: 80 }, rdr_to: { host: IPAddress.parse('127.0.0.1/32'), port: 3128 })
          expect(subject.emit_rule(rule)).to eq('pass in quick on eth0 proto tcp to any port 80 divert-to 127.0.0.1 port 3128')
        end

        it 'fails on ambiguous redirect rule' do
          rule = Rule.new(action: :pass, dir: :in, on: 'eth0', proto: :tcp, to: { port: 80 }, rdr_to: { port: 3128 })
          expect { subject.emit_rule(rule) }.to raise_exception('Unspecified address family')
        end

        it 'formats implicit IPv4 destination' do
          rule = Rule.new(action: :pass, dir: :in, on: 'eth0', af: :inet, proto: :tcp, to: { port: 80 }, rdr_to: { port: 3128 })
          expect(subject.emit_rule(rule)).to eq('pass in quick on eth0 proto tcp to any port 80 divert-to 127.0.0.1 port 3128')
        end

        it 'formats implicit IPv6 destination' do
          rule = Rule.new(action: :pass, dir: :in, on: 'eth0', af: :inet6, proto: :tcp, to: { port: 80 }, rdr_to: { port: 3128 })
          expect(subject.emit_rule(rule)).to eq('pass in quick on eth0 proto tcp to any port 80 divert-to ::1 port 3128')
        end
      end

      context 'implicit address family' do
        it 'skips redundant address family' do
          rule = Rule.new(action: :pass, dir: :in, af: :inet, proto: :tcp, to: { host: IPAddress.parse('127.0.0.1') })
          expect(subject.emit_rule(rule)).to eq('pass in quick proto tcp to 127.0.0.1')
          rule = Rule.new(action: :pass, dir: :in, af: :inet6, proto: :tcp, to: { host: IPAddress.parse('::1') })
          expect(subject.emit_rule(rule)).to eq('pass in quick proto tcp to ::1')
          rule = Rule.new(action: :pass, dir: :in, af: :inet, proto: :tcp, to: { port: 80 })
          expect(subject.emit_rule(rule)).to eq('pass in quick inet proto tcp to any port 80')
          rule = Rule.new(action: :pass, dir: :in, af: :inet6, proto: :tcp, to: { port: 80 })
          expect(subject.emit_rule(rule)).to eq('pass in quick inet6 proto tcp to any port 80')
        end
      end
    end

    RSpec.describe Pf::Ruleset do
      context 'ruleset' do
        let(:dsl) do
          dsl = Melt::Dsl.new
          dsl.eval_network(File.join('spec', 'fixtures', 'simple_lan_network.rb'))
          dsl
        end

        it 'formats a simple lan network rules' do
          rules = dsl.ruleset_for('gw')
          expect(subject.emit_ruleset(rules, :block)).to eq <<-EOT
match in all scrub (no-df)
set skip on lo
block in all
block out all
pass out quick on ppp0 nat-to 198.51.100.72
pass in quick on ppp0 proto tcp to any port 80 rdr-to 192.168.1.80
pass out quick proto udp to 192.168.0.53 port 53
pass out quick proto udp to 192.168.1.53 port 53
EOT
        end

        it 'formats a simple lan network rules' do
          rules = dsl.ruleset_for('www')
          expect(subject.emit_ruleset(rules, :block)).to eq <<-EOT
match in all scrub (no-df)
set skip on lo
block in all
block out all
pass out quick proto udp to 192.168.0.53 port 53
pass out quick proto udp to 192.168.1.53 port 53
pass in quick proto tcp to any port 80
EOT
        end
      end
    end
  end
end
