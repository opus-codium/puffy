require 'melt'

module Melt
  RSpec.describe Dsl do
    let(:dsl) { Dsl.new }
    let(:trivial_network) do
      <<-EOT
        host 'localhost' do
          pass :out, proto: :udp, to: { host: ['192.0.2.27'], port: 'domain' }
          pass :in, proto: :tcp, to: { port: 'ssh' }
        end
      EOT
    end
    let(:simple_lan_network) do
      <<-EOT
        dns_servers = ['ns1', 'ns2']

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
      EOT
    end
    let(:hosting_network) do
      <<-EOT
      host(/db\\d+.example.com/) do
        pass :in, proto: :tcp, from: { host: '192.168.0.0/24' }, to: { port: 'postgresql' }
      end

      host 'db1.example.com' do
        pass :in, proto: :tcp, from: { host: '192.168.0.0/24' }, to: { port: 'postgresql' }
        block :in, proto: :tcp, to: { port: 'mysql' }
      end
      EOT
    end
    let(:ip_restrictions) do
      <<-EOT
        server = [ '192.0.2.1', '2001:DB8::1' ]

        host 'client' do
          pass :out, on: 'eth0', proto: :tcp, to: { host: server, port: 3000 }
          ipv4 do
            pass :out, on: 'eth0', proto: :tcp, to: { host: server, port: 3001 }
          end
          ipv6 do
            pass :out, on: 'eth0', proto: :tcp, to: { host: server, port: 3002 }
          end
        end
      EOT
    end
    let(:incompatible_ip_restrictions) do
      <<-EOT
        server = [ '192.0.2.1', '2001:DB8::1' ]

        host 'client' do
          ipv4 do
            ipv6 do
              pass :out, on: 'eth0', proto: :tcp, to: { host: server, port: 3000 }
            end
          end
        end
      EOT
    end

    it 'reports missing services' do
      dsl.eval_network 'incompatible_ip_restrictions.rb', <<-EOT
      host 'localhost' do
        service 'missing'
      end
      EOT

      expect { dsl.ruleset_for('localhost') }.to raise_error('Undefined service "missing"')
    end

    it 'detects services and hosts' do
      dsl.eval_network('trivial_network.rb', trivial_network)
      expect(dsl.hosts).to eq(['localhost'])
      expect(dsl.services).to eq([])

      dsl.eval_network('simple_lan_network.rb', simple_lan_network)
      expect(dsl.hosts).to eq(%w(gw www))
      expect(dsl.services).to eq([:dns])
    end

    it 'generates ruleset for host' do
      dsl.eval_network('trivial_network.rb', trivial_network)

      expect(dsl.ruleset_for('localhost').count).to eq(2)
    end

    it 'matches hosts using Regexp' do
      dsl.eval_network('hosting_network.rb', hosting_network)

      expect(dsl.ruleset_for('db1.example.com').count).to eq(2)
      expect(dsl.ruleset_for('db2.example.com').count).to eq(1)
      expect(dsl.ruleset_for('db3.example.com').count).to eq(1)
    end

    it 'performs ip restrictions' do
      dsl.eval_network('ip_restrictions.rb', ip_restrictions)
      rules = dsl.ruleset_for('client')
      expect(rules.count).to eq(4)
      expect(rules.count { |r| r.ipv4? && r.dst_port == 3000 }).to eq(1)
      expect(rules.count { |r| r.ipv6? && r.dst_port == 3000 }).to eq(1)
      expect(rules.count { |r| r.ipv4? && r.dst_port == 3001 }).to eq(1)
      expect(rules.count { |r| r.ipv6? && r.dst_port == 3001 }).to eq(0)
      expect(rules.count { |r| r.ipv4? && r.dst_port == 3002 }).to eq(0)
      expect(rules.count { |r| r.ipv6? && r.dst_port == 3002 }).to eq(1)
      expect(rules.count { |r| r.ipv4? && r.dst_port == 3003 }).to eq(0)
      expect(rules.count { |r| r.ipv6? && r.dst_port == 3003 }).to eq(0)
    end

    it 'detects incompatible ip restrictions' do
      dsl.eval_network('incompatible_ip_restrictions.rb', incompatible_ip_restrictions)
      expect { dsl.ruleset_for('client') }.to raise_error(RuntimeError)
    end
  end
end
