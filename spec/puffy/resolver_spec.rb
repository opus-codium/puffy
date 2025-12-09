# frozen_string_literal: true

require 'puffy'

# There are some differences in name resolution of each Ruby implementation.
# See:
# https://github.com/jordansissel/experiments/tree/master/ruby/dns-resolving-bug
module Puffy
  RSpec.describe Resolver do
    before do
      dns = Resolv::DNS.new
      allow(dns).to receive(:getresources).with('example.com', Resolv::DNS::Resource::IN::A).and_return([Resolv::DNS::Resource::IN::A.new('203.0.113.42')])
      allow(dns).to receive(:getresources).with('example.com', Resolv::DNS::Resource::IN::AAAA).and_return([Resolv::DNS::Resource::IN::AAAA.new('2001:db8:fa4e:adde::42')])
      allow(dns).to receive(:getresources).with('host.invalid.', Resolv::DNS::Resource::IN::A).and_call_original
      allow(dns).to receive(:getresources).with('host.invalid.', Resolv::DNS::Resource::IN::AAAA).and_call_original

      allow(Resolv::DNS).to receive(:open).with(nil).and_return(dns)
    end

    subject(:resolver) { described_class.clone.instance }

    it 'resolves IPv4 and IPv6' do
      expect(resolver.resolv('example.com').collect(&:to_s)).to eq(['2001:db8:fa4e:adde::42', '203.0.113.42'])
    end

    it 'resolves IPv4 only' do
      expect(resolver.resolv('example.com', :inet).collect(&:to_s)).to eq(['203.0.113.42'])
      expect(resolver.resolv(IPAddr.new('203.0.113.27'), :inet).collect(&:to_s)).to eq(['203.0.113.27'])
      expect(resolver.resolv(IPAddr.new('2001:db8:c0ff:ee::42'), :inet).collect(&:to_s)).to eq([])
    end

    it 'resolves IPv6 only' do
      expect(resolver.resolv('example.com', :inet6).collect(&:to_s)).to eq(['2001:db8:fa4e:adde::42'])
      expect(resolver.resolv(IPAddr.new('203.0.113.27'), :inet6).collect(&:to_s)).to eq([])
      expect(resolver.resolv(IPAddr.new('2001:db8:c0ff:ee::42'), :inet6).collect(&:to_s)).to eq(['2001:db8:c0ff:ee::42'])
    end

    it 'raises exceptions with unknown hosts' do
      expect { resolver.resolv('host.invalid.') }.to raise_error('"host.invalid." does not resolve to any valid IP address.')
    end

    describe '#resolv_apt_mirror' do
      it 'works as expected' do
        uri = double
        allow(URI).to receive(:parse).with('http://apt.example.org/mirror.lst').and_return(uri)
        allow(uri).to receive(:open).and_yield <<~MIRRORS
          ftp://ftp.de.debian.org/debian/
          http://ftp.us.debian.org/debian/
          https://deb.debian.org/debian/
        MIRRORS
        expect(resolver.resolv_apt_mirror('mirror://apt.example.org/mirror.lst')).to eq([
                                                                                          { host: 'apt.example.org', port: 'http', proto_hint: :tcp },
                                                                                          { host: 'ftp.de.debian.org', port: 'ftp', proto_hint: :tcp },
                                                                                          { host: 'ftp.us.debian.org', port: 'http', proto_hint: :tcp },
                                                                                          { host: 'deb.debian.org', port: 'https', proto_hint: :tcp },
                                                                                        ])
      end
    end

    describe '#resolv_azure_ip_range' do
      it 'works as expected' do
        res = resolver.resolv_azure_ip_range('ActionGroup')

        expect(res).to be_an(Array)
        expect(res).not_to be_empty
        expect(res.first).to be_an(IPAddr)
      end
    end
  end
end
