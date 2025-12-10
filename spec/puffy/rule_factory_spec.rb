# frozen_string_literal: true

require 'puffy'

module Puffy
  RSpec.describe RuleFactory do
    subject(:factory) { described_class.new }

    it 'empty rules produce no rule' do
      allow(Rule).to receive(:new)

      expect(factory.build).to eq([])

      expect(Rule).not_to have_received(:new)
    end

    it 'accept a single value' do
      allow(Rule).to receive(:new).and_call_original

      result = factory.build(proto: :tcp)
      expect(Rule).to have_received(:new)
      expect(result.count).to eq(1)
      expect(result.first.proto).to eq(:tcp)
    end

    it 'iterates over array values' do
      allow(Rule).to receive(:new).and_call_original

      result = factory.build(proto: %i[tcp udp])
      expect(Rule).to have_received(:new).twice
      expect(result.count).to eq(2)
      expect(result[0].proto).to eq(:tcp)
      expect(result[1].proto).to eq(:udp)
    end

    it 'passes addresses and networks' do
      result = factory.build(to: [{ host: IPAddr.new('203.0.113.42') }])

      expect(result.count).to eq(1)
      expect(result[0].to[:host]).to eq(IPAddr.new('203.0.113.42'))

      result = factory.build(to: [{ host: IPAddr.new('192.0.2.0/24') }])

      expect(result.count).to eq(1)
      expect(result[0].to[:host]).to eq(IPAddr.new('192.0.2.0/24'))
    end

    it 'resolves hostnames' do
      allow(Rule).to receive(:new).and_call_original
      allow(Puffy::Resolver.instance).to receive(:resolv).with('example.com').and_return([IPAddr.new('2001:db8:fa4e:adde::42'), IPAddr.new('203.0.113.42')])

      result = factory.build(to: [{ host: 'example.com' }])

      expect(result.count).to eq(2)
      expect(result[0].to[:host]).to eq(IPAddr.new('2001:db8:fa4e:adde::42'))
      expect(result[1].to[:host]).to eq(IPAddr.new('203.0.113.42'))
    end

    it 'accepts service names' do
      allow(Rule).to receive(:new).and_call_original

      result = factory.build(proto: :tcp, to: [{ port: %w[http https] }])

      expect(result.count).to eq(2)
      expect(result[0].proto).to eq(:tcp)
      expect(result[0].to[:port]).to eq(80)
      expect(result[1].proto).to eq(:tcp)
      expect(result[1].to[:port]).to eq(443)

      expect { factory.build(to: [{ port: 'invalid' }]) }.to raise_error('unknown service "invalid"')
    end

    it 'accepts service alt-names' do
      allow(Rule).to receive(:new).and_call_original

      result = factory.build(proto: :tcp, to: [{ port: %w[auth tap ident] }])

      expect(result.count).to eq(3)
      expect(result[0].proto).to eq(:tcp)
      expect(result[0].to[:port]).to eq(113)
      expect(result[1].proto).to eq(:tcp)
      expect(result[1].to[:port]).to eq(113)
      expect(result[2].proto).to eq(:tcp)
      expect(result[2].to[:port]).to eq(113)
    end

    it 'does not mix IPv4 and IPv6' do
      allow(Puffy::Resolver.instance).to receive(:resolv).with('example.net').and_return([IPAddr.new('2001:db8:fa4e:adde::27'), IPAddr.new('203.0.113.27')])
      allow(Puffy::Resolver.instance).to receive(:resolv).with('example.com').and_return([IPAddr.new('2001:db8:fa4e:adde::42'), IPAddr.new('203.0.113.42')])

      allow(Rule).to receive(:new).exactly(4).times.and_call_original

      result = factory.build(from: [{ host: 'example.net' }], to: [{ host: 'example.com' }])

      expect(result.count).to eq(2)
      expect(result[0].from[:host]).to eq(IPAddr.new('2001:db8:fa4e:adde::27'))
      expect(result[0].to[:host]).to eq(IPAddr.new('2001:db8:fa4e:adde::42'))
      expect(result[1].from[:host]).to eq(IPAddr.new('203.0.113.27'))
      expect(result[1].to[:host]).to eq(IPAddr.new('203.0.113.42'))
    end

    it 'filters address family' do
      result = factory.build(af: :inet, proto: :icmp)
      expect(result.count).to eq(1)

      result = factory.build(af: :inet6, proto: :icmpv6)
      expect(result.count).to eq(1)
    end

    it 'limits scope to IP version' do
      allow(Puffy::Resolver.instance).to receive(:resolv).with('example.com').and_return([IPAddr.new('2001:db8:fa4e:adde::42'), IPAddr.new('203.0.113.42')])

      result = []

      factory.ipv4 do
        result = factory.build(to: [{ host: 'example.com' }])
      end
      expect(result.count).to eq(1)
      expect(result[0].to[:host]).to eq(IPAddr.new('203.0.113.42'))

      factory.ipv6 do
        result = factory.build(to: [{ host: 'example.com' }])
      end
      expect(result.count).to eq(1)
      expect(result[0].to[:host]).to eq(IPAddr.new('2001:db8:fa4e:adde::42'))
    end
  end
end
