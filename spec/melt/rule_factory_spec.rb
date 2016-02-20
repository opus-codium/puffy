require 'melt'

module Melt
  RSpec.describe RuleFactory do
    before(:all) do
      @factory = RuleFactory.new
    end

    it 'empty rules produce no rule' do
      expect(Rule).not_to receive(:new)

      expect(@factory.build).to eq([])
    end

    it 'iterates over array values' do
      expect(Rule).to receive(:new).and_call_original

      result = @factory.build(proto: :tcp)
      expect(result.count).to eq(1)
      expect(result.first.proto).to eq(:tcp)

      expect(Rule).to receive(:new).twice.and_call_original

      result = @factory.build(proto: [:tcp, :udp])
      expect(result.count).to eq(2)
      expect(result[0].proto).to eq(:tcp)
      expect(result[1].proto).to eq(:udp)
    end

    it 'passes addresses and networks' do
      result = @factory.build(to: { host: '192.0.2.1' })

      expect(result.count).to eq(1)
      expect(result[0].to[:host].to_s).to eq('192.0.2.1')

      result = @factory.build(to: { host: '192.0.2.0/24' })

      expect(result.count).to eq(1)
      expect(result[0].to[:host].to_string).to eq('192.0.2.0/24')
    end

    it 'resolves hostnames' do
      expect(Rule).to receive(:new).twice.and_call_original
      expect(Melt::Resolver.instance).to receive(:resolv).with('example.com', nil).and_return([IPAddress.parse('2001:DB8::1'), IPAddress.parse('192.0.2.1')])

      result = @factory.build(to: { host: 'example.com' })

      expect(result.count).to eq(2)
      expect(result[0].to[:host]).to eq(IPAddress.parse('2001:DB8::1'))
      expect(result[1].to[:host]).to eq(IPAddress.parse('192.0.2.1'))
    end

    it 'accepts service names' do
      expect(Rule).to receive(:new).twice.and_call_original

      result = @factory.build(proto: :tcp, to: { port: %w(http https) })

      expect(result.count).to eq(2)
      expect(result[0].proto).to eq(:tcp)
      expect(result[0].to[:port]).to eq(80)
      expect(result[1].proto).to eq(:tcp)
      expect(result[1].to[:port]).to eq(443)

      expect { @factory.build(to: { port: 'invalid' }) }.to raise_error('unknown service "invalid"')
    end

    it 'accepts service alt-names' do
      expect(Rule).to receive(:new).exactly(3).times.and_call_original

      result = @factory.build(proto: :tcp, to: { port: %w(http www www-http) })

      expect(result.count).to eq(3)
      expect(result[0].proto).to eq(:tcp)
      expect(result[0].to[:port]).to eq(80)
      expect(result[1].proto).to eq(:tcp)
      expect(result[1].to[:port]).to eq(80)
      expect(result[2].proto).to eq(:tcp)
      expect(result[2].to[:port]).to eq(80)
    end

    it 'does not mix IPv4 and IPv6' do
      expect(Melt::Resolver.instance).to receive(:resolv).with('example.net', nil).and_return([IPAddress.parse('2001:DB8::FFFF:FFFF:FFFF'), IPAddress.parse('198.51.100.1')])
      expect(Melt::Resolver.instance).to receive(:resolv).with('example.com', :inet6).and_return([IPAddress.parse('2001:DB8::1')])
      expect(Melt::Resolver.instance).to receive(:resolv).with('example.com', :inet).and_return([IPAddress.parse('192.0.2.1')])

      expect(Rule).to receive(:new).twice.and_call_original

      result = @factory.build(from: { host: 'example.net' }, to: { host: 'example.com' })

      expect(result.count).to eq(2)
      expect(result[0].from[:host]).to eq(IPAddress.parse('2001:DB8::FFFF:FFFF:FFFF'))
      expect(result[0].to[:host]).to eq(IPAddress.parse('2001:DB8::1'))
      expect(result[1].from[:host]).to eq(IPAddress.parse('198.51.100.1'))
      expect(result[1].to[:host]).to eq(IPAddress.parse('192.0.2.1'))
    end

    it 'filters address family' do
      result = @factory.build(af: :inet, proto: :icmp)
      expect(result.count).to eq(1)

      result = @factory.build(af: :inet6, proto: :icmpv6)
      expect(result.count).to eq(1)
    end

    it 'limits scope to IP version' do
      result = []

      @factory.ipv4 do
        result = @factory.build(to: { host: 'localhost.' })
      end
      expect(result.count).to eq(1)
      expect(result[0].to[:host]).to eq(IPAddress.parse('127.0.0.1'))

      @factory.ipv6 do
        result = @factory.build(to: { host: 'localhost.' })
      end
      expect(result.count).to eq(1)
      expect(result[0].to[:host]).to eq(IPAddress.parse('::1'))
    end
  end
end
