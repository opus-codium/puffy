require 'melt'

# There are some differences in name resolution of each Ruby implementation.
# See:
# https://github.com/jordansissel/experiments/tree/master/ruby/dns-resolving-bug
module Melt
  RSpec.describe Resolver do
    it 'resolves IPv4 and IPv6' do
      expect(Melt::Resolver.get_instance.resolv('localhost.').collect { |x| x.to_s }).to eq(['::1', '127.0.0.1'])
    end

    it 'resolves IPv4 only' do
      expect(Melt::Resolver.get_instance.resolv('localhost.', :inet).collect { |x| x.to_s }).to eq(['127.0.0.1'])
    end

    it 'resolves IPv6 only' do
      expect(Melt::Resolver.get_instance.resolv('localhost.', :inet6).collect { |x| x.to_s }).to eq(['::1'])
    end

    it 'raises exceptions with unknown hosts' do
      expect { Melt::Resolver.get_instance.resolv('host.invalid.') }.to raise_error
    end
  end
end
