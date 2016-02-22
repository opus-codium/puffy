module Melt
  # Abstract firewall rule.
  class Rule
    # The action to perform when the rule apply (+accept+ or +block+).
    attr_accessor :action

    # Whether blocked packets must be returned to sender instead of being silently dropped.
    attr_accessor :return

    # The direction of the rule (+in+ or +out+).
    attr_accessor :dir

    # The protocol the Melt::Rule applies to (+tcp+, +udp+, etc).
    attr_accessor :proto

    # The address family of the rule (+inet6+ or +inet+)
    attr_accessor :af

    # The interface the rule applies to.
    attr_accessor :on

    # The interface packets must arrive on for the rule to apply in a forwarding context.
    attr_accessor :in

    # The interface packets must be sent to for the rule to apply in a forwarding context.
    attr_accessor :out

    # The packet source as a Hash for the rule to apply.
    #
    # :host:: address of the source host or network the rule apply to
    # :port:: source port the rule apply to
    attr_accessor :from

    # The packet destination as a Hash for the rule to apply.
    #
    # :host:: address of the destination host or network the rule apply to
    # :port:: destination port the rule apply to
    attr_accessor :to

    # The packet destination when peforming NAT.
    attr_accessor :nat_to

    # The destination as a Hash for redirections.
    #
    # :host:: address of the destination host or network the rule apply to
    # :port:: destination port the rule apply to
    attr_accessor :rdr_to

    # Prevent the rule from being a quick one.
    attr_accessor :no_quick

    # Instanciate a firewall Melt::Rule.
    #
    # +options+ is a Hash of the Melt::Rule class attributes
    #
    #   Rule.new({ action: :accept, dir: :in, proto: :tcp, to: { port: 80 } })
    def initialize(options = {})
      options.each do |k, v|
        send("#{k}=", v)
      end

      fail 'if src_port or dst_port is specified, the protocol must also be given' if (src_port || dst_port) && proto.nil?
    end

    # Return true if the rule is valid in an IPv4 context.
    def ipv4?
      ! (af == :inet6 || from_ipv6? || to_ipv6?)
    end

    # Return true if the rule has an IPv4 source or destination.
    def implicit_ipv4?
      from_ipv4? || to_ipv4?
    end

    # Return true if the rule is valid in an IPv6 context.
    def ipv6?
      ! (af == :inet || from_ipv4? || to_ipv4?)
    end

    # Return true if the rule has an IPv6 source or destination.
    def implicit_ipv6?
      from_ipv6? || to_ipv6?
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

    # Returns the source host of the Melt::Rule.
    def src_host
      from && from[:host]
    end

    # Returns the source port of the Melt::Rule.
    def src_port
      from && from[:port]
    end

    # Returns the destination host of the Melt::Rule.
    def dst_host
      to && to[:host]
    end

    # Returns the destination port of the Melt::Rule.
    def dst_port
      to && to[:port]
    end

    # Returns the redirect destination host of the Melt::Rule.
    def rdr_to_host
      rdr_to && rdr_to[:host]
    end

    # Returns the redirect destination port of the Melt::Rule.
    def rdr_to_port
      rdr_to && rdr_to[:port]
    end

    def as_fwd_rule
      res = dup
      res.on_to_in_out!
      res.to.merge!(res.rdr_to.reject { |_k, v| v.nil? })
      res.rdr_to = nil
      res.dir = :fwd
      res
    end

    def on_to_in_out!
      if dir == :in
        self.in ||= on
      else
        self.out ||= on
      end
      self.on = nil
    end

    private

    def from_ipv6?
      src_host && src_host.ipv6?
    end

    def from_ipv4?
      src_host && src_host.ipv4?
    end

    def to_ipv6?
      dst_host && dst_host.ipv6?
    end

    def to_ipv4?
      dst_host && dst_host.ipv4?
    end
  end
end
