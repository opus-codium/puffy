# frozen_string_literal: true

require 'deep_merge'

module Melt
  # The Melt Domain Specific Language (DSL) is used to describe network firewall rules.
  #
  #   service 'ssh' do
  #     pass :in, af: :inet, proto: :tcp, from: { host: '192.168.1.0/24' }, to: { port: 'ssh' }
  #   end
  #
  #   node 'www' do
  #     service 'ssh'
  #     pass :in, proto: :tcp, to: { port: 'http' }
  #     pass :out
  #   end
  #
  #   node 'gw' do
  #     service 'ssh'
  #     pass :out, on: 'ppp0', nat_to: 'public-ip'
  #     pass :in, on: 'ppp0', proto: :tcp, to: { port: 'http' }, rdr_to: { host: 'www' }
  #     pass :out
  #   end
  class Dsl
    # Changes the default policy.
    attr_reader :default_policy

    def initialize
      @policy = :block
      @saved_policies = {}
      @factory = RuleFactory.new
      @default_direction = nil
      @extra_options = {}
      reset_network
    end

    # Evaluates a network configuration.
    #
    # Configuration is read form +filename+ unless +contents+ is also provided.
    #
    # @param filename [String] Path to the network description file
    # @param contents [String,nil] Contents of the network description file
    # @return [void]
    def eval_network(filename, contents = nil)
      reset_network
      contents ||= File.read(filename)
      instance_eval(contents, filename, 1)
      @default_policy = @policy
    end

    # Returns the found nodes hostname.
    #
    # @return [Array]
    def nodes
      @nodes.keys
    end

    # Returns the found services.
    #
    # @return [Array]
    def services
      @services.keys
    end

    # Returns the ruleset for +hostname+.
    #
    # @param hostname [String]
    # @return [Array<Melt::Rule>]
    def ruleset_for(hostname)
      @rules = []
      @policy = @default_policy
      bloc_for(hostname).call
      @saved_policies[hostname] = @policy
      @rules
    end

    # Returns the policy for +hostname+.
    #
    # @param hostname [String]
    # @return [Symbol]
    def policy_for(hostname)
      raise "Policy for #{hostname} unknown" unless @saved_policies[hostname]

      @saved_policies[hostname]
    end

    # Sets the policy to +policy+
    #
    # @param policy [Symbol]
    def policy(policy)
      @policy = policy
    end

    # @!method pass(direction = nil, options = {})
    #   Emits a pass rule with the given +direction+ and +options+.
    #   @return [void]
    # @!method block(direction = nil, options = {})
    #   Emits a block rule with the given +direction+ and +options+.
    #   @return [void]
    # @!method log(direction = nil, options = {})
    #   Emits a log rule with the given +direction+ and +options+.
    #   @return [void]
    %i[pass block log].each do |action|
      define_method(action) do |*args|
        options = build_options(args.last.is_a?(Hash) ? args.pop : nil)
        direction = build_direction(args.first)
        options[:action] = action
        options[:dir] = direction
        options.freeze
        @rules += @factory.build(options)
      end
    end

    # Limits the scope of a set of rules to IPv4 only.
    #
    # @return [void]
    def ipv4(&block)
      @factory.ipv4(&block)
    end

    # Limits the scope of a set of rules to IPv6 only.
    #
    # @return [void]
    def ipv6(&block)
      @factory.ipv6(&block)
    end

    # Defines a set of reusable rules for service named +name+.
    #
    #   service 'base-services' do
    #     pass :out, proto: :udp, to: { host: 'dns', port: 'domain' }
    #     pass :in,  proto: :tcp, from: { host: sysadmins }, to: { port: 'ssh' }
    #     pass :in,  proto: :tcp, from: { host: 'backup' }, to: { port: 'bacula-fd' }
    #     pass :out, proto: :tcp, to: { host: 'backup', port: 'bacula-sd' }
    #   end
    #
    #   node 'backup' do
    #     service 'base-services'
    #     pass :in,  proto: :tcp, to: { port: 'bacula-sd' }
    #     pass :out, proto: :tcp, from: { port: 'bacula-dir' }
    #   end
    #
    #   node 'dns' do
    #     service 'base-services'
    #     pass :in, proto: :udp, to: { port: 'domain' }
    #   end
    #
    #   node 'www' do
    #     service 'base-services'
    #     pass :in, proto: :tcp, to: { port: 'http' }
    #   end
    #
    # @return [void]
    def service(name, &block)
      if block_given?
        @services[name] = block
      else
        raise "Undefined service \"#{name}\"" unless @services[name]

        @services[name].call
      end
    end

    # @!method client(name, options = {})
    #   Declare a service client
    #
    #     service 'http' do
    #       pass proto: :tcp, to { port: %w(http https) }
    #     end
    #
    #     node /^node\d+/ do
    #       client 'http'
    #     end
    #
    #     node /^node\d+/ do
    #       client 'http', to: { host: 'restricted-destination.example.com' }
    #     end
    #
    #   @return [void]
    # @!method server(name, options = {})
    #   Declare a service server
    #
    #     service 'ssh' do
    #       pass proto: :tcp, to { port: 'ssh' }
    #     end
    #
    #     node /^node\d+/ do
    #       server 'ssh'
    #     end
    #
    #   @return [void]
    { client: :out, server: :in }.each do |role, direction|
      define_method(role) do |name, options = {}|
        @default_direction = direction
        @extra_options = options
        @services[name].call
        @default_direction = nil
        @extra_options = {}
      end
    end

    # Defines rules for the node +hostname+.
    #
    #   node 'fqdn' do
    #     pass :out
    #     pass :in, to: { port: 'ssh' }
    #   end
    #
    # @return [void]
    def node(*hostnames, &block)
      hostnames.each do |hostname|
        hostname = /\A#{hostname}\z/ if hostname.is_a?(Regexp)
        @nodes[hostname] = block
      end
    end

    private

    def bloc_for(hostname)
      @nodes[hostname] || block_matching(hostname)
    end

    def block_matching(hostname)
      found = nil
      @nodes.select { |node, _block| node.is_a?(Regexp) }.each do |_node, block|
        raise "Multiple node definition match \"#{hostname}\"" if found

        found = block
      end
      raise "No node definition match \"#{hostname}\"" unless found

      found
    end

    def build_options(options)
      (options || {}).deep_merge(@extra_options)
    end

    def build_direction(direction)
      raise 'Direction redefined' if direction && @default_direction

      direction ||= @default_direction
      raise 'Direction unspecified' unless direction

      direction
    end

    def reset_network
      @services = {}
      @nodes = {}
    end
  end
end
