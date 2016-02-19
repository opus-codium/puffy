require 'melt'

# There are some differences in name resolution of each Ruby implementation.
# See:
# https://github.com/jordansissel/experiments/tree/master/ruby/dns-resolving-bug
module Melt
  RSpec.describe Resolver do
    it 'resolves IPv4 and IPv6' do
      expect(Melt::Resolver.instance.resolv('localhost.').collect(&:to_s)).to eq(['::1', '127.0.0.1'])
    end

    it 'resolves IPv4 only' do
      expect(Melt::Resolver.instance.resolv('localhost.', :inet).collect(&:to_s)).to eq(['127.0.0.1'])
      expect(Melt::Resolver.instance.resolv('127.0.0.1', :inet).collect(&:to_s)).to eq(['127.0.0.1'])
      expect(Melt::Resolver.instance.resolv('::1', :inet).collect(&:to_s)).to eq([])
    end

    it 'resolves IPv6 only' do
      expect(Melt::Resolver.instance.resolv('localhost.', :inet6).collect(&:to_s)).to eq(['::1'])
      expect(Melt::Resolver.instance.resolv('127.0.0.1', :inet6).collect(&:to_s)).to eq([])
      expect(Melt::Resolver.instance.resolv('::1', :inet6).collect(&:to_s)).to eq(['::1'])
    end

    it 'raises exceptions with unknown hosts' do
      expect { Melt::Resolver.instance.resolv('host.invalid.') }.to raise_error('"host.invalid." does not resolve to any valid IP address.')
    end
  end
end
