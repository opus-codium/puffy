require 'melt'

module Melt
  RSpec.describe Dsl do
    it 'reports missing services' do
      subject.eval_network(File.join('spec', 'fixtures', 'undefined_service.rb'))

      expect { subject.ruleset_for('localhost') }.to raise_error('Undefined service "unknown"')
    end

    it 'detects services and hosts' do
      subject.eval_network(File.join('spec', 'fixtures', 'trivial_network.rb'))
      expect(subject.hosts).to eq(['localhost'])
      expect(subject.services).to eq([])

      subject.eval_network(File.join('spec', 'fixtures', 'simple_lan_network.rb'))
      expect(subject.hosts).to eq(%w(gw www))
      expect(subject.services).to eq([:dns])
    end

    it 'generates ruleset for host' do
      subject.eval_network(File.join('spec', 'fixtures', 'trivial_network.rb'))

      expect(subject.ruleset_for('localhost').count).to eq(2)
    end

    it 'matches hosts using Regexp' do
      subject.eval_network(File.join('spec', 'fixtures', 'hosting_network.rb'))

      expect(subject.ruleset_for('db1.example.com').count).to eq(2)
      expect(subject.ruleset_for('db2.example.com').count).to eq(1)
      expect(subject.ruleset_for('db3.example.com').count).to eq(1)
    end

    it 'performs ip restrictions' do
      subject.eval_network(File.join('spec', 'fixtures', 'ip_restrictions.rb'))
      rules = subject.ruleset_for('client')
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
      subject.eval_network(File.join('spec', 'fixtures', 'incompatible_ip_restrictions.rb'))
      expect { subject.ruleset_for('client') }.to raise_error(RuntimeError)
    end
  end
end
