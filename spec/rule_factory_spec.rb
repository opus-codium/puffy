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
      result = @factory.build(dst: { host: '192.0.2.1' })

      expect(result.count).to eq(1)
      expect(result[0].dst[:host].to_s).to eq('192.0.2.1')

      result = @factory.build(dst: { host: '192.0.2.0/24' })

      expect(result.count).to eq(1)
      expect(result[0].dst[:host].to_string).to eq('192.0.2.0/24')
    end

    it 'resolves hostnames' do
      expect(Rule).to receive(:new).twice.and_call_original
      expect(Melt::Resolver.get_instance).to receive(:resolv).with('example.com', nil).and_return([['2001:DB8::1', :inet6], ['192.0.2.1', :inet]])

      result = @factory.build(dst: { host: 'example.com' })

      expect(result.count).to eq(2)
      expect(result[0].dst[:host]).to eq('2001:DB8::1')
      expect(result[1].dst[:host]).to eq('192.0.2.1')
    end

    it 'accepts service names' do
      expect(Rule).to receive(:new).twice.and_call_original

      result = @factory.build(dst: { port: ['http', 'https'] })

      expect(result.count).to eq(2)
      expect(result[0].dst[:port]).to eq(80)
      expect(result[1].dst[:port]).to eq(443)

      expect { @factory.build(dst: { port: 'invalid' }) }.to raise_error
    end

    it 'does not mix IPv4 and IPv6' do
      expect(Melt::Resolver.get_instance).to receive(:resolv).with('example.net', nil).and_return([['2001:DB8::FFFF:FFFF:FFFF', :inet6], ['198.51.100.1', :inet]])
      expect(Melt::Resolver.get_instance).to receive(:resolv).with('example.com', :inet6).and_return([['2001:DB8::1', :inet6]])
      expect(Melt::Resolver.get_instance).to receive(:resolv).with('example.com', :inet).and_return([['192.0.2.1', :inet]])

      expect(Rule).to receive(:new).twice.and_call_original

      result = @factory.build(src: { host: 'example.net' }, dst: { host: 'example.com' })

      expect(result.count).to eq(2)
      expect(result[0].src[:host]).to eq('2001:DB8::FFFF:FFFF:FFFF')
      expect(result[0].dst[:host]).to eq('2001:DB8::1')
      expect(result[1].src[:host]).to eq('198.51.100.1')
      expect(result[1].dst[:host]).to eq('192.0.2.1')
    end
  end
end
