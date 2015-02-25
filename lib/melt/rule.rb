module Melt
  class Rule
    attr_accessor :action, :dir, :proto, :af, :iface, :src, :dst

    def initialize(options)
      options.each do |k, v|
        send("#{k}=", v)
      end
    end
  end
end
