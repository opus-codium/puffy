# frozen_string_literal: true

require 'puffy'

# There are some differences in name resolution of each Ruby implementation.
# See:
# https://github.com/jordansissel/experiments/tree/master/ruby/dns-resolving-bug
module Puffy
  RSpec.describe Resolver do
    subject { Puffy::Resolver.instance }
    it 'resolves IPv4 and IPv6' do
      expect(subject.resolv('example.com').collect(&:to_s)).to eq(['2606:2800:220:1:248:1893:25c8:1946', '93.184.216.34'])
    end

    it 'resolves IPv4 only' do
      expect(subject.resolv('example.com', :inet).collect(&:to_s)).to eq(['93.184.216.34'])
      expect(subject.resolv(IPAddr.new('93.184.216.34'), :inet).collect(&:to_s)).to eq(['93.184.216.34'])
      expect(subject.resolv(IPAddr.new('2606:2800:220:1:248:1893:25c8:1946'), :inet).collect(&:to_s)).to eq([])
    end

    it 'resolves IPv6 only' do
      expect(subject.resolv('example.com', :inet6).collect(&:to_s)).to eq(['2606:2800:220:1:248:1893:25c8:1946'])
      expect(subject.resolv(IPAddr.new('93.184.216.34'), :inet6).collect(&:to_s)).to eq([])
      expect(subject.resolv(IPAddr.new('2606:2800:220:1:248:1893:25c8:1946'), :inet6).collect(&:to_s)).to eq(['2606:2800:220:1:248:1893:25c8:1946'])
    end

    it 'raises exceptions with unknown hosts' do
      expect { subject.resolv('host.invalid.') }.to raise_error('"host.invalid." does not resolve to any valid IP address.')
    end

    describe '#resolv_apt_mirror' do
      it 'works' do
        uri = double
        allow(URI).to receive(:parse).with('http://apt.example.org/mirror.lst').and_return(uri)
        allow(uri).to receive(:open).and_yield <<~MIRRORS
          ftp://ftp.de.debian.org/debian/
          http://ftp.us.debian.org/debian/
          https://deb.debian.org/debian/
        MIRRORS
        expect(subject.resolv_apt_mirror('mirror://apt.example.org/mirror.lst')).to eq([
                                                                                         { host: 'apt.example.org', port: 'http', proto_hint: :tcp },
                                                                                         { host: 'ftp.de.debian.org', port: 'ftp', proto_hint: :tcp },
                                                                                         { host: 'ftp.us.debian.org', port: 'http', proto_hint: :tcp },
                                                                                         { host: 'deb.debian.org', port: 'https', proto_hint: :tcp },
                                                                                       ])
      end
    end
  end
end
