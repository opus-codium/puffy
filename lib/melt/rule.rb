module Melt
  # Abstract firewall rule.
  class Rule
    # Action to perform (+accept+ or +block+)
    attr_accessor :action

    # Direction (+in+ or +out+).
    attr_accessor :dir

    # Prototype (+tcp+, +udp+, ...)
    attr_accessor :proto

    # Address family (+inet6+ or +inet+)
    attr_accessor :af

    # Interface
    attr_accessor :on

    # Packet source as a Hash
    #
    # :host:: address of the source host or network the rule apply to
    # :port:: source port the rule apply to
    attr_accessor :src

    # Packet destination as a Hash
    #
    # :host:: address of the destination host or network the rule apply to
    # :port:: destination port the rule apply to
    attr_accessor :dst

    # Instanciate a firewall Rule.
    #
    # +options+ is a Hash of the Rule class attributes
    #
    #   Rule.new({ action: :accept, dir: :in, proto: :tcp, dst: { port: 80 } })
    def initialize(options = {})
      options.each do |k, v|
        send("#{k}=", v)
      end
    end

    # Return true if the rule is valid in an IPv4 context.
    def ipv4?
      ! (src && src[:host] && src[:host].ipv6? || dst && dst[:host] && dst[:host].ipv6?)
    end

    # Return true if the rule is valid in an IPv6 context.
    def ipv6?
      ! (src && src[:host] && src[:host].ipv4? || dst && dst[:host] && dst[:host].ipv4?)
    end
  end
end
