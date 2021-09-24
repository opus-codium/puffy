class Melt::Parser
rule
  target: assignation target
        | node target
        | policy target { @default_policy = val[0] }
        | service target
        |
        ;

  assignation: IDENTIFIER '=' '{' variable_value_list '}'  { @variables[val[0]] = val[3].freeze }
             | IDENTIFIER '=' variable_value               { @variables[val[0]] = val[2].freeze }
             ;

  variable_value_list: variable_value_list ',' variable_value { result = val[0] + [val[2]] }
                     | variable_value_list variable_value     { result = val[0] + [val[1]] }
                     | variable_value                         { result = [val[0]] }
                     ;

  variable_value: ADDRESS
                | STRING
                ;

  service: SERVICE service_name block { @services[val[1]] = val[2] }
         ;

  service_name: IDENTIFIER
              | STRING
              ;

  node: NODE '{' node_name_list '}' block_with_policy { @nodes[val[2]] = val[4]; @saved_policies[val[2]] = @policy }
      | NODE node_name block_with_policy              { @nodes[val[1]] = val[2]; @saved_policies[val[1]] = @policy }
      ;

  node_name_list: node_name_list ',' node_name { result = val[0] + [val[2]] }
                | node_name_list node_name     { result = val[0] + [val[1]] }
                | node_name                    { result = [val[0]] }
                ;

  node_name: STRING
           | REGEX
           ;

  block_with_policy: '{' policy rules '}' { @policy = val[1]; result = val[2] }
                   | DO policy rules END  { @policy = val[1]; result = val[2] }
                   | block                { @policy = nil; result = val[0] }
                   ;

  block: '{' rules '}' { result = val[1].freeze }
       | DO rules END  { result = val[1].freeze }
       ;

  rules: pf_rule rules    { result = val[0] + val[1] }
       | ipv4_block rules { result = val[0] + val[1] }
       | ipv6_block rules { result = val[0] + val[1] }
       |                  { result = [] }
       ;

  policy: POLICY action { result = val[1][:action] }
        | POLICY LOG    { result = 'log' }
        ;

  ipv4_block: IPV4 DO rules END  { result = val[2].reject { |x| x[:af] == :inet6 }.map { |x| x[:af] = :inet ; x } }
            | IPV4 '{' rules '}' { result = val[2].reject { |x| x[:af] == :inet6 }.map { |x| x[:af] = :inet ; x } }
            ;

  ipv6_block: IPV6 DO rules END  { result = val[2].reject { |x| x[:af] == :inet }.map { |x| x[:af] = :inet6 ; x } }
            | IPV6 '{' rules '}' { result = val[2].reject { |x| x[:af] == :inet }.map { |x| x[:af] = :inet6 ; x } }
            ;

  pf_rule: SERVICE service_name optional_hosts { result = @services.fetch(val[1]).deep_dup.map { |x| x.merge(val[2]) } }
         | CLIENT service_name optional_hosts  {
             raise "service #{val[1]} cannot be used as client" if @services.fetch(val[1]).map { |x| x[:dir] }.compact.any?
             result = @services.fetch(val[1]).deep_dup.map { |x| x.merge(dir: :out).deep_merge(val[2]) }
           }
         | SERVER service_name optional_hosts  {
             raise "service #{val[1]} cannot be used as server" if @services.fetch(val[1]).map { |x| x[:dir] }.compact.any?
             result = @services.fetch(val[1]).deep_dup.map { |x| x.merge(dir: :in).deep_merge(val[2]) }
           }
         | action rule_direction log on_interface rule_af protospec hosts filteropts { result = [val.compact.inject(:merge)] }
         ;

  log: LOG
     |
     ;

  on_interface:
              | ON STRING { result = { on: val[1] } }
              ;

  action: BLOCK  { result = { action: :block } }
        | PASS   { result = { action: :pass } }
        ;

  rule_direction:
                | '{' direction_list '}' { result = { dir: val[1] } }
                | direction              { result = { dir: val[0] } }
                ;

  direction_list: direction_list ',' direction { result = val[0] + [val[2]] }
                | direction_list direction     { result = val[0] + [val[1]] }
                | direction                    { result = [val[0]] }
                ;

  direction: IN  { result = :in }
           | OUT { result = :out }
           ;

  rule_af:
         | INET   { result = { af: :inet } }
         | INET6  { result = { af: :inet6 } }
         ;

  protospec:
           | PROTO '{' protocol_list '}' { result = { proto: val[2] } }
           | PROTO protocol              { result = { proto: val[1] } }
           ;

  protocol_list: protocol_list ',' protocol { result = val[0] + [val[2]] }
               | protocol_list protocol     { result = val[0] + [val[1]] }
               | protocol                   { result = [val[0]] }
               ;

  protocol: IDENTIFIER { result = val[0].to_sym }
          ;

  hosts: FROM hosts_from hosts_port TO hosts_to hosts_port { result = { from: { host: val[1], port: val[2] }, to: { host: val[4], port: val[5] } } }
       | ALL                                               { result = {} }
       ;

  optional_hosts: hosts
                |       { result = {} }
                ;

  hosts_from: ANY               { result = nil }
            | '{' host_list '}' { result = val[1] }
            | host
            | VARIABLE          { result = @variables.fetch(val[0]) }
            |
            ;

  hosts_to: ANY               { result = nil }
          | '{' host_list '}' { result = val[1] }
          | host
          | VARIABLE          { result = @variables.fetch(val[0]) }
          |
          ;

  hosts_port: PORT '{' port_list '}' { result = val[2] }
            | PORT port              { result = val[1] }
            |
            ;

  port_list: port_list ',' port { result = val[0] + [val[2]] }
           | port_list port     { result = val[0] + [val[1]] }
           | port               { result = [val[0]] }
           ;

  port: INTEGER
      | IDENTIFIER
      # TODO: Directly return a Range.
      # RuleFactory#port_is_a_range does it for us.
      | INTEGER ':' INTEGER { result = val.join }
      ;

  host: ADDRESS
      | STRING
      ;

  host_list: host_list ',' host { result = val[0] + [val[2]] }
           | host_list host     { result = val[0] + [val[1]] }
           | host               { result = [val[0]] }
           ;

  filteropts: filteropts ',' filteropt  { result = val[0].merge(val[2]) }
            | filteropts filteropt      { result = val[0].merge(val[1]) }
            |                           { result = {} }
            ;

  filteropt: RDR_TO ADDRESS PORT INTEGER { result = { rdr_to: { host: val[1], port: val[3] } } }
           | RDR_TO ADDRESS { result = { rdr_to: { host: val[1] } } }
           | NAT_TO ADDRESS { result = { nat_to: val[1] } }
           ;
end

---- header

require 'deep_merge'
require 'strscan'

---- inner

  attr_accessor :yydebug
  attr_reader :policy
  #attr_accessor :variables, :nodes, :services

  def ipaddress?(s)
    IPAddr.new(s.matched)
  rescue IPAddr::InvalidAddressError
    s.unscan
    nil
  end

  def parse(text)
    lineoff = 0
    lineno = 1
    s = StringScanner.new(text)

    tokens = []
    case
    when s.scan(/\n/)
      lineno += 1
      lineoff = s.pos
    when s.scan(/#.*/) then # ignore comments
    when s.scan(/\s+/) then # ignore blanks

    when s.scan(/\//)
      n = 0
      while char = s.post_match[n]
        case char
        when /\\/
          n += 1
        when /\//
          tokens << [:REGEX, Regexp.new(s.post_match[0...n])]
          s.pos += n + 1
          break
        end
        n += 1
      end
    when s.scan(/=/) then              tokens << ['=', s.matched]
    when s.scan(/:/) then              tokens << [':', s.matched]
    when s.scan(/,/) then              tokens << [',', s.matched]
    when s.scan(/{/) then              tokens << ['{', s.matched]
    when s.scan(/}/) then              tokens << ['}', s.matched]
    when s.scan(/service\b/) then      tokens << [:SERVICE, s.matched]
    when s.scan(/client\b/) then       tokens << [:CLIENT, s.matched]
    when s.scan(/server\b/) then       tokens << [:SERVER, s.matched]
    when s.scan(/node\b/) then         tokens << [:NODE, s.matched]
    when s.scan(/'[^'\n]*'/) then      tokens << [:STRING, s.matched[1...-1]]
    when s.scan(/"[^"\n]*"/) then      tokens << [:STRING, s.matched[1...-1]]

    when s.scan(/ipv4\b/) then         tokens << [:IPV4, s.matched]
    when s.scan(/ipv6\b/) then         tokens << [:IPV6, s.matched]
    when s.scan(/policy\b/) then       tokens << [:POLICY, s.matched]

    when s.scan(/do\b/) then           tokens << [:DO, s.matched]
    when s.scan(/end\b/) then          tokens << [:END, s.matched]

    when s.scan(/\$\S+/) then          tokens << [:VARIABLE, s.matched[1..-1]]

    when s.scan(/pass\b/) then         tokens << [:PASS, s.matched]
    when s.scan(/block\b/) then        tokens << [:BLOCK, s.matched]
    when s.scan(/in\b/) then           tokens << [:IN, s.matched]
    when s.scan(/out\b/) then          tokens << [:OUT, s.matched]
    when s.scan(/log\b/) then          tokens << [:LOG, s.matched]
    when s.scan(/inet\b/) then          tokens << [:INET, s.matched]
    when s.scan(/inet6\b/) then          tokens << [:INET6, s.matched]
    when s.scan(/on\b/) then           tokens << [:ON, s.matched]
    when s.scan(/proto\b/) then        tokens << [:PROTO, s.matched]
    when s.scan(/from\b/) then         tokens << [:FROM, s.matched]
    when s.scan(/to\b/) then           tokens << [:TO, s.matched]
    when s.scan(/all\b/) then          tokens << [:ALL, s.matched]
    when s.scan(/any\b/) then          tokens << [:ANY, s.matched]
    when s.scan(/self\b/) then         tokens << [:SELF, s.matched]
    when s.scan(/port\b/) then         tokens << [:PORT, s.matched]
    when s.scan(/nat-to\b/) then       tokens << [:NAT_TO, s.matched]
    when s.scan(/rdr-to\b/) then       tokens << [:RDR_TO, s.matched]

    when s.scan(/\d+\.\d+\.\d+\.\d+(\/\d+)?/) && ip = ipaddress?(s) then           tokens << [:ADDRESS, IPAddr.new(s.matched)]
    when s.scan(/[[:xdigit:]]*:[:[:xdigit:]]+(\/\d+)?/) && ip = ipaddress?(s) then tokens << [:ADDRESS, IPAddr.new(s.matched)]

    when s.scan(/\d+/) then tokens << [:INTEGER, s.matched.to_i]
    when s.scan(/\w[\w-]+/) then tokens << [:IDENTIFIER, s.matched]
    else
      puts tokens.inspect
      puts "Syntax error on line #{lineno} at position #{s.pos - lineoff + 1}:"

      endlineoff = lineoff
      endlineoff += 1 until text[endlineoff] == "\n"
      puts text[lineoff..endlineoff]
      puts ' ' * (s.pos - lineoff) + '^'
      raise 'Syntax error'
    end until s.eos?

    define_singleton_method(:next_token) do
      r = tokens.shift
      #puts r.inspect
      r
    end

    tokens << [false, false]

    #puts tokens.inspect

    do_parse
  #rescue Racc::ParseError
  end

  def initialize
    super
    @variables = {}
    @nodes = {}
    @saved_policies = {}
    @services = {} 
    @rule_factory = Melt::RuleFactory.new
  end

  def nodes
    @nodes.keys
  end

  def prefered_key_for_hostname(keys, hostname)
    direct_mapping = []
    regexp_mapping = []

    keys.each do |key|
      case key
      when String
        direct_mapping << key if key == hostname
      when Regexp
        regexp_mapping << key if key.match?(hostname)
      when Array
        key.each do |value|
          case value
          when String
            direct_mapping << key if value == hostname
          when Regexp
            regexp_mapping << key if value.match?(hostname)
          end
        end
      end
    end

    raise "Multiple definitions for #{hostname}" if direct_mapping.count > 1
    raise "Multiple definitions match #{hostname}: #{regexp_mapping.join(', ')}" if regexp_mapping.count > 1

    direct_mapping.first || regexp_mapping.first
  end

  def prefered_value_for_hostname(hash, hostname)
    hash[(prefered_key_for_hostname(hash.keys, hostname))]
  end

  def ruleset_for(hostname)
    rules = prefered_value_for_hostname(@nodes, hostname)
    rule_factory = RuleFactory.new
    rules.map do |r|
      rule_factory.build(r)
    end.flatten
  end

  def policy_for(hostname)
    prefered_value_for_hostname(@saved_policies, hostname) || @default_policy || :block
  end
