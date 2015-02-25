require 'melt'

module Melt
  RSpec.describe Rule do
    it 'detects IPv4 rules' do
      expect(Rule.new.ipv4?).to be_truthy
      expect(Rule.new(action: :block, dst: { port: 80 }).ipv4?).to be_truthy
      expect(Rule.new(action: :block, dst: { host: IPAddress.parse('192.0.2.1'), port: 80 }).ipv4?).to be_truthy
      expect(Rule.new(action: :block, dst: { host: IPAddress.parse('2001:DB8::1'), port: 80 }).ipv4?).to be_falsy
    end

    it 'detects IPv6 rules' do
      expect(Rule.new.ipv6?).to be_truthy
      expect(Rule.new(action: :block, dst: { port: 80 }).ipv6?).to be_truthy
      expect(Rule.new(action: :block, dst: { host: IPAddress.parse('192.0.2.1'), port: 80 }).ipv6?).to be_falsy
      expect(Rule.new(action: :block, dst: { host: IPAddress.parse('2001:DB8::1'), port: 80 }).ipv6?).to be_truthy
    end
  end
end
