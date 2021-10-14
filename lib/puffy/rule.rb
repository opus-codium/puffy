# frozen_string_literal: true

module Puffy
  class AddressFamilyConflict < RuntimeError
  end

  # Abstract firewall rule.
  class Rule
    # @!attribute action
    #   The action to perform when the rule apply (+:accept+ or +:block+).
    #   @return [Symbol] Action
    # @!attribute return
    #   Whether blocked packets must be returned to sender instead of being silently dropped.
    #   @return [Boolean] Return flag
    # @!attribute dir
    #   The direction of the rule (+:in+ or +:out+).
    #   @return [Symbol] Direction
    # @!attribute proto
    #   The protocol the Puffy::Rule applies to (+:tcp+, +:udp+, etc).
    #   @return [Symbol] Protocol
    # @!attribute af
    #   The address family of the rule (+:inet6+ or +:inet+)
    #   @return [Symbol] Address family
    # @!attribute on
    #   The interface the rule applies to.
    #   @return [String] Interface
    # @!attribute in
    #   The interface packets must arrive on for the rule to apply in a forwarding context.
    #   @return [String] Interface
    # @!attribute out
    #   The interface packets must be sent to for the rule to apply in a forwarding context.
    #   @return [String] Interface
    # @!attribute from
    #   The packet source as a Hash for the rule to apply.
    #
    #   :host:: address of the source host or network the rule apply to
    #   :port:: source port the rule apply to
    #   @return [Hash] Source
    # @!attribute to
    #   The packet destination as a Hash for the rule to apply.
    #
    #   :host:: address of the destination host or network the rule apply to
    #   :port:: destination port the rule apply to
    #   @return [Hash] Destination
    # @!attribute nat_to
    #   The packet destination when peforming NAT.
    #   @return [IPAddr] IP Adress
    # @!attribute rdr_to
    #   The destination as a Hash for redirections.
    #
    #   :host:: address of the destination host or network the rule apply to
    #   :port:: destination port the rule apply to
    #   @return [Hash] Destination
    # @!attribute no_quick
    #   Prevent the rule from being a quick one.
    #   @return [Boolean] Quick flag
    attr_accessor :action, :return, :dir, :proto, :af, :on, :in, :out, :from, :to, :nat_to, :rdr_to, :no_quick

    # Instanciate a firewall Puffy::Rule.
    #
    # +options+ is a Hash of the Puffy::Rule class attributes
    #
    #   Rule.new({ action: :accept, dir: :in, proto: :tcp, to: { port: 80 } })
    def initialize(options = {})
      send_options(options)

      @af = detect_af unless af

      raise "unsupported action `#{options[:action]}'" unless valid_action?
      raise 'if from_port or to_port is specified, the protocol must also be given' if port_without_protocol?
    end

    # Instanciate a forward Puffy::Rule.
    #
    # @param rule [Puffy::Rule] a NAT rule
    #
    # @return [Puffy::Rule]
    def self.fwd_rule(rule)
      res = rule.dup
      res.on_to_in_out!
      res.to.merge!(res.rdr_to.compact)
      res.rdr_to = nil
      res.dir = :fwd
      res
    end

    # Return true if the rule is valid in an IPv4 context.
    def ipv4?
      af.nil? || af == :inet
    end

    # Return true if the rule has an IPv4 source or destination.
    def implicit_ipv4?
      from_ipv4? || to_ipv4? || rdr_to_ipv4? || (rdr_to && af == :inet)
    end

    # Return true if the rule is valid in an IPv6 context.
    def ipv6?
      af.nil? || af == :inet6
    end

    # Return true if the rule has an IPv6 source or destination.
    def implicit_ipv6?
      from_ipv6? || to_ipv6? || rdr_to_ipv6? || (rdr_to && af == :inet6)
    end

    # Return true if the rule is a filter rule.
    def filter?
      !nat? && !rdr?
    end

    # Returns whether the rule applies to incomming packets.
    def in?
      dir.nil? || dir == :in
    end

    # Returns whether the rule applies to outgoing packets.
    def out?
      dir.nil? || dir == :out
    end

    # Returns whether the rule performs Network Address Translation.
    def nat?
      nat_to
    end

    # Returns whether the rule is a redirection.
    def rdr?
      rdr_to_host || rdr_to_port
    end

    # Returns whether the rule performs forwarding.
    def fwd?
      dir == :fwd
    end

    # @!method from_host
    #   Returns the source host of the Puffy::Rule.
    # @!method from_port
    #   Returns the source port of the Puffy::Rule.
    # @!method to_host
    #   Returns the destination host of the Puffy::Rule.
    # @!method to_port
    #   Returns the destination port of the Puffy::Rule.
    # @!method rdr_to_host
    #   Returns the redirect destination host of the Puffy::Rule.
    # @!method rdr_to_port
    #   Returns the redirect destination port of the Puffy::Rule.
    %i[from to rdr_to].each do |destination|
      %i[host port].each do |param|
        define_method("#{destination}_#{param}") do
          res = public_send(destination)
          res && res[param]
        end
      end
    end

    # Setsthe #in / #out to #on depending on #dir.
    #
    # @return [void]
    def on_to_in_out!
      if dir == :in
        self.in ||= on
      else
        self.out ||= on
      end
      self.on = nil
    end

    private

    def valid_action?
      [nil, :pass, :block].include?(action)
    end

    def port_without_protocol?
      (from_port || to_port) && proto.nil?
    end

    def send_options(options)
      options.each do |k, v|
        send("#{k}=", v)
      end
    end

    def detect_af
      afs = collect_afs
      return nil if afs.empty?
      return afs.first if afs.one?

      raise AddressFamilyConflict, "Incompatible address famlilies: #{afs}"
    end

    def collect_afs
      %i[from_host to_host rdr_to_host].map do |method|
        res = send(method)
        if res.nil? then nil
        elsif res.ipv4? then :inet
        elsif res.ipv6? then :inet6
        else
          raise 'Fail'
        end
      end.uniq.compact
    end

    # @!method from_ipv4?
    # @!method from_ipv6?
    # @!method to_ipv4?
    # @!method to_ipv6?
    # @!method rdr_to_ipv4?
    # @!method rdr_to_ipv6?
    %i[from to rdr_to].each do |destination|
      %i[ipv4 ipv6].each do |ip_version|
        define_method("#{destination}_#{ip_version}?") do
          res = public_send("#{destination}_host")
          res&.public_send("#{ip_version}?")
        end
      end
    end
  end
end
