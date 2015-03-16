module Melt
  # Abstract firewall rule.
  class Rule
    # Action to perform (+accept+ or +block+)
    attr_accessor :action

    # Return block packets
    attr_accessor :return

    # Direction (+in+ or +out+).
    attr_accessor :dir

    # Prototype (+tcp+, +udp+, ...)
    attr_accessor :proto

    # Address family (+inet6+ or +inet+)
    attr_accessor :af

    # Interface
    attr_accessor :on

    # In interface (forwarding)
    attr_accessor :in

    # Out interface (forwarding context)
    attr_accessor :out

    # Packet source as a Hash
    #
    # :host:: address of the source host or network the rule apply to
    # :port:: source port the rule apply to
    attr_accessor :from

    # Packet destination as a Hash
    #
    # :host:: address of the destination host or network the rule apply to
    # :port:: destination port the rule apply to
    attr_accessor :to

    # Destination for NAT.
    attr_accessor :nat_to

    # Destination for redirections.
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

      raise "if src_port or dst_port is specified, the protocol must also be given" if (src_port || dst_port) && proto.nil?
    end

    # Return true if the rule is valid in an IPv4 context.
    def ipv4?
      ! (af == :inet6 || from && from[:host] && from[:host].ipv6? || to && to[:host] && to[:host].ipv6?)
    end

    # Return true if the rule is valid in an IPv6 context.
    def ipv6?
      ! (af == :inet || from && from[:host] && from[:host].ipv4? || to && to[:host] && to[:host].ipv4?)
    end

    # Return true if the rule is a filter rule.
    def filter?
      ! nat? && ! rdr?
    end

    def in?
      dir.nil? || dir == :in
    end

    def out?
      dir.nil? || dir == :out
    end

    # Return true if the rule performs Network Address Translation.
    def nat?
      !! nat_to
    end

    # Return true if the rule is a redirection.
    def rdr?
      !! rdr_to && rdr_to[:host]
    end

    def fwd?
      dir == :fwd
    end

    # Return the source port of the Rule.
    def src_port
      from and from[:port]
    end

    # Return the destination port of the Rule.
    def dst_port
      to and to[:port]
    end

    # Return the redirect destination port of the Rule.
    def rdr_to_port
      rdr_to and rdr_to[:port]
    end
  end
end
