# frozen_string_literal: true

require 'puffy'

module Puffy
  RSpec.describe Rule do
    it 'reports invalid rules' do
      expect { described_class.new(action: :moin) }.to raise_error("unsupported action `moin'")
      expect { described_class.new(action: :pass, moin: :moin) }.to raise_error(NoMethodError, /undefined method `moin='/)
    end

    it 'detects IPv4 rules' do
      expect(described_class.new).to be_ipv4
      expect(described_class.new(action: :block, dir: :out, proto: :tcp, to: { port: 80 })).to be_ipv4
      expect(described_class.new(action: :block, dir: :out, proto: :tcp, to: { host: IPAddr.new('203.0.113.42'), port: 80 })).to be_ipv4
      expect(described_class.new(action: :block, dir: :out, proto: :tcp, to: { host: IPAddr.new('2001:db8:fa4e:adde::42'), port: 80 })).not_to be_ipv4
      expect(described_class.new(action: :pass, dir: :fwd, in: 'eth0', out: 'eth1')).to be_ipv4
    end

    it 'detects IPv6 rules' do
      expect(described_class.new).to be_ipv6
      expect(described_class.new(action: :block, dir: :out, proto: :tcp, to: { port: 80 })).to be_ipv6
      expect(described_class.new(action: :block, dir: :out, proto: :tcp, to: { host: IPAddr.new('203.0.113.42'), port: 80 })).not_to be_ipv6
      expect(described_class.new(action: :block, dir: :out, proto: :tcp, to: { host: IPAddr.new('2001:db8:fa4e:adde::42'), port: 80 })).to be_ipv6
      expect(described_class.new(action: :pass, dir: :fwd, in: 'eth0', out: 'eth1')).to be_ipv6
    end

    it 'detects implicit IPv4 rules' do
      expect(described_class.new).not_to be_implicit_ipv4
      expect(described_class.new(action: :block, dir: :in, from: { host: IPAddr.new('192.168.0.0/24') })).to be_implicit_ipv4
      expect(described_class.new(action: :block, dir: :in, from: { host: IPAddr.new('fe80::/16') })).not_to be_implicit_ipv4
      expect(described_class.new(action: :block, dir: :in, af: :inet, proto: :tcp, to: { port: 80 })).not_to be_implicit_ipv4
      expect(described_class.new(action: :block, dir: :in, af: :inet6, proto: :tcp, to: { port: 80 })).not_to be_implicit_ipv4
    end

    it 'detects implicit IPv6 rules' do
      expect(described_class.new).not_to be_implicit_ipv6
      expect(described_class.new(action: :block, dir: :in, from: { host: IPAddr.new('192.168.0.0/24') })).not_to be_implicit_ipv6
      expect(described_class.new(action: :block, dir: :in, from: { host: IPAddr.new('fe80::/16') })).to be_implicit_ipv6
      expect(described_class.new(action: :block, dir: :in, af: :inet, proto: :tcp, to: { port: 80 })).not_to be_implicit_ipv6
      expect(described_class.new(action: :block, dir: :in, af: :inet6, proto: :tcp, to: { port: 80 })).not_to be_implicit_ipv6
    end

    it 'detects redirect rules' do
      expect(described_class.new).not_to be_rdr
      expect(described_class.new(action: :pass, dir: :in, proto: :tcp, to: { port: 80 })).not_to be_rdr
      expect(described_class.new(action: :pass, dir: :out, on: 'eth0', nat_to: IPAddr.new('198.51.100.72'))).not_to be_rdr
      expect(described_class.new(action: :pass, dir: :in, on: 'eth0', rdr_to: { host: IPAddr.new('203.0.113.42') })).to be_rdr
      expect(described_class.new(action: :pass, dir: :fwd, in: 'eth0', out: 'eth1')).not_to be_rdr
    end

    it 'detects NAT rules' do
      expect(described_class.new).not_to be_nat
      expect(described_class.new(action: :pass, dir: :out, proto: :tcp, to: { port: 80 })).not_to be_nat
      expect(described_class.new(action: :pass, dir: :out, on: 'eth0', nat_to: IPAddr.new('198.51.100.72'))).to be_nat
      expect(described_class.new(action: :pass, dir: :in, on: 'eth0', rdr_to: { host: IPAddr.new('203.0.113.42') })).not_to be_nat
      expect(described_class.new(action: :pass, dir: :fwd, in: 'eth0', out: 'eth1')).not_to be_nat
    end

    it 'detects forward rules' do
      expect(described_class.new).not_to be_fwd
      expect(described_class.new(action: :pass, dir: :out, proto: :tcp, to: { port: 80 })).not_to be_fwd
      expect(described_class.new(action: :pass, dir: :out, on: 'eth0', nat_to: IPAddr.new('198.51.100.72'))).not_to be_fwd
      expect(described_class.new(action: :pass, dir: :in, on: 'eth0', rdr_to: { host: IPAddr.new('203.0.113.42') })).not_to be_fwd
      expect(described_class.new(action: :pass, dir: :fwd, in: 'eth0', out: 'eth1')).to be_fwd
    end

    it 'detects in rules' do
      expect(described_class.new).to be_in
      expect(described_class.new(action: :pass, dir: :in, proto: :tcp, to: { port: 80 })).to be_in
      expect(described_class.new(action: :pass, dir: :out, on: 'eth0', nat_to: IPAddr.new('198.51.100.72'))).not_to be_in
      expect(described_class.new(action: :pass, dir: :fwd, in: 'eth0', out: 'eth1')).not_to be_in
    end

    it 'detects out rules' do
      expect(described_class.new).to be_out
      expect(described_class.new(action: :pass, dir: :in, proto: :tcp, to: { port: 80 })).not_to be_out
      expect(described_class.new(action: :pass, dir: :out, on: 'eth0', nat_to: IPAddr.new('198.51.100.72'))).to be_out
      expect(described_class.new(action: :pass, dir: :fwd, in: 'eth0', out: 'eth1')).not_to be_out
    end
  end
end
