module Melt
  # The Melt Domain Specific Language (DSL) is used to describe network firewall rules.
  #
  #   service 'ssh' do
  #     pass :in, af: :inet, proto: :tcp, from: { host: '192.168.1.0/24' }, to: { port: 'ssh' }
  #   end
  #
  #   host 'www' do
  #     service 'ssh'
  #     pass :in, proto: :tcp, to: { port: 'http' }
  #     pass :out
  #   end
  #
  #   host 'gw' do
  #     service 'ssh'
  #     pass :out, on: 'ppp0', nat_to: 'public-ip'
  #     pass :in, on: 'ppp0', proto: :tcp, to: { port: 'http' }, rdr_to: { host: 'www' }
  #     pass :out
  #   end
  class Dsl
    attr_reader :policy

    def initialize
      @factory = RuleFactory.new
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
    end

    # Returns the found hosts hostname.
    #
    # @return [Array]
    def hosts
      @hosts.keys
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
      @policy = :block
      found = false
      if @hosts[hostname]
        found = true
        @hosts[hostname].call
      else
        @hosts.each do |k, v|
          next unless k.is_a?(Regexp)
          if k.match(hostname)
            fail "Multiple host definition match \"#{hostname}\"" if found
            found = true
            v.call
          end
        end
      end
      fail "No host definition match \"#{hostname}\"" unless found
      @rules
    end

    # Changes the default policy.
    #
    # @param policy [Symbol]
    # @return [void]
    def default_policy(policy)
      @policy = policy
    end

    # Emits a pass rule with the given +direction+ and +options+.
    #
    # @return [void]
    def pass(*args)
      direction = args.first
      options = if args.last.is_a?(Hash)
                  args.last
                else
                  {}
                end
      options = options.merge(action: :pass, dir: direction)
      @rules += @factory.build(options)
    end

    # Emits a block rule with the given +direction+ and +options+.
    #
    # @return [void]
    def block(*args)
      direction = args.first
      options = if args.last.is_a?(Hash)
                  args.last
                else
                  {}
                end
      options = options.merge(action: :block, dir: direction)
      @rules += @factory.build(options)
    end

    # Emits a log rule with the given +direction+ and +options+.
    #
    # @return [void]
    def log(direction, options = {})
      options = options.merge(action: :log, dir: direction)
      @rules += @factory.build(options)
    end

    # Limits the scope of a set of rules to IPv4 only.
    #
    # @return [void]
    def ipv4
      @factory.ipv4 do
        yield
      end
    end

    # Limits the scope of a set of rules to IPv6 only.
    #
    # @return [void]
    def ipv6
      @factory.ipv6 do
        yield
      end
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
    #   host 'backup' do
    #     service 'base-services'
    #     pass :in,  proto: :tcp, to: { port: 'bacula-sd' }
    #     pass :out, proto: :tcp, from: { port: 'bacula-dir' }
    #   end
    #
    #   host 'dns' do
    #     service 'base-services'
    #     pass :in, proto: :udp, to: { port: 'domain' }
    #   end
    #
    #   host 'www' do
    #     service 'base-services'
    #     pass :in, proto: :tcp, to: { port: 'http' }
    #   end
    #
    # @return [void]
    def service(name, &block)
      if block_given?
        @services[name] = block
      else
        fail "Undefined service \"#{name}\"" unless @services[name]
        @services[name].call
      end
    end

    # Defines rules for the host +hostname+.
    #
    #   host 'fqdn' do
    #     pass :out
    #     pass :in, to: { port: 'ssh' }
    #   end
    #
    # @return [void]
    def host(hostname, &block)
      hostname = /\A#{hostname}\z/ if hostname.is_a?(Regexp)
      @hosts[hostname] = block
    end

    private

    def reset_network
      @services = {}
      @hosts = {}
    end
  end
end
