module Melt
  # Abstract firewall rule.
  class Rule
    # The action to perform when the rule apply (+accept+ or +block+).
    attr_accessor :action

    # Whether blocked packets must be returned to sender instead of being silently dropped.
    attr_accessor :return

    # The direction of the rule (+in+ or +out+).
    attr_accessor :dir

    # The protocol the Rule applies to (+tcp+, +udp+, etc).
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

    # Instanciate a firewall Rule.
    #
    # +options+ is a Hash of the Rule class attributes
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

    # Return true if the rule is valid in an IPv6 context.
    def ipv6?
      ! (af == :inet || from_ipv4? || to_ipv4?)
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
      rdr_to && (rdr_to[:host] || rdr_to[:port])
    end

    # Returns whether the rule performs forwarding.
    def fwd?
      dir == :fwd
    end

    # Returns the source port of the Rule.
    def src_port
      from && from[:port]
    end

    # Returns the destination port of the Rule.
    def dst_port
      to && to[:port]
    end

    # Returns the redirect destination port of the Rule.
    def rdr_to_port
      rdr_to && rdr_to[:port]
    end

    private

    def from_ipv6?
      from && from[:host] && from[:host].ipv6?
    end

    def from_ipv4?
      from && from[:host] && from[:host].ipv4?
    end

    def to_ipv6?
      to && to[:host] && to[:host].ipv6?
    end

    def to_ipv4?
      to && to[:host] && to[:host].ipv4?
    end
  end
end
