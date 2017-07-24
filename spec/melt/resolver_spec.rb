# frozen_string_literal: true

require 'melt'

# There are some differences in name resolution of each Ruby implementation.
# See:
# https://github.com/jordansissel/experiments/tree/master/ruby/dns-resolving-bug
module Melt
  RSpec.describe Resolver do
    subject { Melt::Resolver.instance }
    it 'resolves IPv4 and IPv6' do
      expect(subject.resolv('localhost.').collect(&:to_s)).to eq(['::1', '127.0.0.1'])
    end

    it 'resolves IPv4 only' do
      expect(subject.resolv('localhost.', :inet).collect(&:to_s)).to eq(['127.0.0.1'])
      expect(subject.resolv('127.0.0.1', :inet).collect(&:to_s)).to eq(['127.0.0.1'])
      expect(subject.resolv('::1', :inet).collect(&:to_s)).to eq([])
    end

    it 'resolves IPv6 only' do
      expect(subject.resolv('localhost.', :inet6).collect(&:to_s)).to eq(['::1'])
      expect(subject.resolv('127.0.0.1', :inet6).collect(&:to_s)).to eq([])
      expect(subject.resolv('::1', :inet6).collect(&:to_s)).to eq(['::1'])
    end

    it 'raises exceptions with unknown hosts' do
      expect { subject.resolv('host.invalid.') }.to raise_error('"host.invalid." does not resolve to any valid IP address.')
    end
  end
end
