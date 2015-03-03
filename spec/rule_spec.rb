require 'melt'

module Melt
  RSpec.describe Rule do
    it 'detects IPv4 rules' do
      expect(Rule.new.ipv4?).to be_truthy
      expect(Rule.new(action: :block, dir: :out, proto: :tcp, to: { port: 80 }).ipv4?).to be_truthy
      expect(Rule.new(action: :block, dir: :out, proto: :tcp, to: { host: IPAddress.parse('192.0.2.1'), port: 80 }).ipv4?).to be_truthy
      expect(Rule.new(action: :block, dir: :out, proto: :tcp, to: { host: IPAddress.parse('2001:DB8::1'), port: 80 }).ipv4?).to be_falsy
      expect(Rule.new(action: :pass, dir: :fwd, in: 'eth0', out: 'eth1').ipv4?).to be_truthy
    end

    it 'detects IPv6 rules' do
      expect(Rule.new.ipv6?).to be_truthy
      expect(Rule.new(action: :block, dir: :out, proto: :tcp, to: { port: 80 }).ipv6?).to be_truthy
      expect(Rule.new(action: :block, dir: :out, proto: :tcp, to: { host: IPAddress.parse('192.0.2.1'), port: 80 }).ipv6?).to be_falsy
      expect(Rule.new(action: :block, dir: :out, proto: :tcp, to: { host: IPAddress.parse('2001:DB8::1'), port: 80 }).ipv6?).to be_truthy
      expect(Rule.new(action: :pass, dir: :fwd, in: 'eth0', out: 'eth1').ipv6?).to be_truthy
    end

    it 'detects redirect rules' do
      expect(Rule.new.rdr?).to be_falsy
      expect(Rule.new(action: :pass, dir: :in, proto: :tcp, to: { port: 80 }).rdr?).to be_falsy
      expect(Rule.new(action: :pass, dir: :out, on: 'eth0', nat_to: '198.51.100.72').rdr?).to be_falsy
      expect(Rule.new(action: :pass, dir: :in, on: 'eth0', rdr_to: { host: '192.0.2.1' }).rdr?).to be_truthy
      expect(Rule.new(action: :pass, dir: :fwd, in: 'eth0', out: 'eth1').rdr?).to be_falsy
    end

    it 'detects NAT rules' do
      expect(Rule.new.nat?).to be_falsy
      expect(Rule.new(action: :pass, dir: :out, proto: :tcp, to: { port: 80 }).nat?).to be_falsy
      expect(Rule.new(action: :pass, dir: :out, on: 'eth0', nat_to: '198.51.100.72').nat?).to be_truthy
      expect(Rule.new(action: :pass, dir: :in, on: 'eth0', rdr_to: { host: '192.0.2.1' }).nat?).to be_falsy
      expect(Rule.new(action: :pass, dir: :fwd, in: 'eth0', out: 'eth1').nat?).to be_falsy
    end

    it 'detects forward rules' do
      expect(Rule.new.fwd?).to be_falsy
      expect(Rule.new(action: :pass, dir: :out, proto: :tcp, to: { port: 80 }).fwd?).to be_falsy
      expect(Rule.new(action: :pass, dir: :out, on: 'eth0', nat_to: '198.51.100.72').fwd?).to be_falsy
      expect(Rule.new(action: :pass, dir: :in, on: 'eth0', rdr_to: { host: '192.0.2.1' }).fwd?).to be_falsy
      expect(Rule.new(action: :pass, dir: :fwd, in: 'eth0', out: 'eth1').fwd?).to be_truthy
    end
  end
end
