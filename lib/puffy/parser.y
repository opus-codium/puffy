class Puffy::Parser
rule
  target: assignation target
        | node target
        | policy target { @default_policy = val[0] }
        | service target
        |

  assignation: IDENTIFIER '=' '{' variable_value_list '}'  { @variables[val[0][:value]] = val[3].flatten.freeze }
             | IDENTIFIER '=' variable_value               { @variables[val[0][:value]] = val[2].freeze }

  variable_value_list: variable_value_list ',' variable_value { result = val[0] + [val[2]] }
                     | variable_value_list variable_value     { result = val[0] + [val[1]] }
                     | variable_value                         { result = [val[0]] }

  variable_value: host_list_item { result = val[0] }
                | port           { result = val[0] }

  service: SERVICE service_name block { @services[val[1]] = val[2] }

  service_name: IDENTIFIER { result = val[0][:value] }
              | STRING     { result = val[0][:value] }

  node: NODE '{' node_name_list '}' block_with_policy { val[2].each { |name| @nodes[name] = val[4]; @saved_policies[name] = @policy } }
      | NODE node_name block_with_policy              { @nodes[val[1]] = val[2]; @saved_policies[val[1]] = @policy }

  node_name_list: node_name_list ',' node_name { result = val[0] + [val[2]] }
                | node_name_list node_name     { result = val[0] + [val[1]] }
                | node_name                    { result = [val[0]] }

  node_name: STRING { result = val[0][:value] }
           | REGEX  { result = val[0][:value] }

  block_with_policy: '{' policy rules '}' { @policy = val[1]; result = val[2] }
                   | DO policy rules END  { @policy = val[1]; result = val[2] }
                   | block                { @policy = nil; result = val[0] }

  block: '{' rules '}' { result = val[1].freeze }
       | DO rules END  { result = val[1].freeze }

  rules: pf_rule rules    { result = val[0] + val[1] }
       | ipv4_block rules { result = val[0] + val[1] }
       | ipv6_block rules { result = val[0] + val[1] }
       |                  { result = [] }

  policy: POLICY action { result = val[1][:action] }
        | POLICY LOG    { result = 'log' }

  ipv4_block: IPV4 DO rules END  { result = val[2].reject { |x| x[:af] == :inet6 }.map { |x| x[:af] = :inet ; x } }
            | IPV4 '{' rules '}' { result = val[2].reject { |x| x[:af] == :inet6 }.map { |x| x[:af] = :inet ; x } }

  ipv6_block: IPV6 DO rules END  { result = val[2].reject { |x| x[:af] == :inet }.map { |x| x[:af] = :inet6 ; x } }
            | IPV6 '{' rules '}' { result = val[2].reject { |x| x[:af] == :inet }.map { |x| x[:af] = :inet6 ; x } }

  pf_rule: SERVICE service_name optional_hosts {
             begin
               result = constraint_service_to_hosts(val[1], val[2])
             rescue KeyError
               raise ParseError.new("Parse error: service \"#{val[1]}\" is not defined", val[0])
             end
           }
         | CLIENT service_name optional_hosts  {
             begin
               raise "service #{val[1]} cannot be used as client" if @services.fetch(val[1]).map { |x| x[:dir] }.compact.any?
               result = constraint_service_to_hosts(val[1], val[2]).map { |item| item.merge(dir: :out) }
             rescue KeyError
               raise ParseError.new("Parse error: service \"#{val[1]}\" is not defined", val[0])
             end
           }
         | SERVER service_name optional_hosts  {
             begin
               raise "service #{val[1]} cannot be used as server" if @services.fetch(val[1]).map { |x| x[:dir] }.compact.any?
               result = constraint_service_to_hosts(val[1], val[2]).map { |item| item.merge(dir: :in) }
             rescue KeyError
               raise ParseError.new("Parse error: service \"#{val[1]}\" is not defined", val[0])
             end
           }
         | action rule_direction log on_interface rule_af protospec hosts filteropts { result = [val.compact.inject(:merge)] }

  log: LOG
     |

  on_interface:
              | ON STRING { result = { on: val[1][:value] } }

  action: BLOCK  { result = { action: :block } }
        | PASS   { result = { action: :pass } }

  rule_direction:
                | '{' direction_list '}' { result = { dir: val[1] } }
                | direction              { result = { dir: val[0] } }

  direction_list: direction_list ',' direction { result = val[0] + [val[2]] }
                | direction_list direction     { result = val[0] + [val[1]] }
                | direction                    { result = [val[0]] }

  direction: IN  { result = :in }
           | OUT { result = :out }

  rule_af:
         | INET   { result = { af: :inet } }
         | INET6  { result = { af: :inet6 } }

  protospec:
           | PROTO '{' protocol_list '}' { result = { proto: val[2] } }
           | PROTO protocol              { result = { proto: val[1] } }

  protocol_list: protocol_list ',' protocol { result = val[0] + [val[2]] }
               | protocol_list protocol     { result = val[0] + [val[1]] }
               | protocol                   { result = [val[0]] }

  protocol: IDENTIFIER { result = val[0][:value].to_sym }

  hosts: FROM hosts_host TO hosts_host { result = { from: val[1], to: val[3] } }
       | FROM hosts_host               { result = { from: val[1] } }
       | TO hosts_host                 { result = { to: val[1] } }
       | ALL                           { result = {} }

  optional_hosts: hosts
                |       { result = {} }

  hosts_host: ANY hosts_port               { result = [{ host: nil, port: val[1] }] }
            | hosts_port                   { result = [{ host: nil, port: val[0] }] }
            | host_list_item hosts_port    { result = [{ host: val[0], port: val[1] }] }
            | '{' host_list '}' hosts_port { result = [{ host: val[1], port: val[3] }] }
            | SRV '(' STRING ')'           { result = Resolver.instance.resolv_srv(val[2][:value]) }
            | APT_MIRROR '(' STRING ')'    { result = Resolver.instance.resolv_apt_mirror(val[2][:value]) }

  hosts_port: PORT '{' port_list '}' { result = val[2] }
            | PORT port              { result = val[1] }
            |

  port_list: port_list ',' port_list_item { result = val[0] + val[2] }
           | port_list port_list_item     { result = val[0] + val[1] }
           | port_list_item               { result = val[0] }

  port_list_item: port     { result = [val[0]] }
                | VARIABLE { result = @variables.fetch(val[0][:value]) }

  port: INTEGER             { result = val[0][:value] }
      | IDENTIFIER          { result = val[0][:value] }
      | INTEGER ':' INTEGER { result = Range.new(val[0][:value], val[2][:value]) }

  host: ADDRESS { result = val[0][:value] }
      | STRING  { result = val[0][:value] }

  host_list: host_list ',' host_list_item { result = val[0] + val[2] }
           | host_list host_list_item     { result = val[0] + val[1] }
           | host_list_item               { result = val[0] }

  host_list_item: host                          { result = [val[0]] }
                | VARIABLE                      { result = @variables.fetch(val[0][:value]) }
                | AZURE_IP_RANGE '(' STRING ')' { result = Resolver.instance.resolv_azure_ip_range(val[2][:value]) }

  filteropts: filteropts ',' filteropt  { result = val[0].merge(val[2]) }
            | filteropts filteropt      { result = val[0].merge(val[1]) }
            |                           { result = {} }

  filteropt: RDR_TO ADDRESS PORT INTEGER { result = { rdr_to: [{ host: val[1][:value], port: val[3][:value] }] } }
           | RDR_TO ADDRESS              { result = { rdr_to: [{ host: val[1][:value], port: nil }] } }
           | NAT_TO ADDRESS              { result = { nat_to: val[1][:value] } }
end

---- header

require 'deep_merge'
require 'ipaddr'
require 'json'
require 'strscan'

---- inner

  attr_accessor :yydebug
  attr_reader :policy, :filename
  #attr_accessor :variables, :nodes, :services

  def ipaddress?(s)
    IPAddr.new(s.matched)
  rescue IPAddr::InvalidAddressError
    s.unscan
    nil
  end

  def parse_file(filename)
    @filename = filename
    parse(File.read(filename))
    @filename = nil
  end

  def parse(text)
    @filename ||= '<stdin>'
    @lineno = 1
    s = StringScanner.new(text)

    @tokens = []
    @position = 0
    @line = (s.check_until(/\n/) || '').chomp
    until s.eos? do
      case
      when s.scan(/\n/)
        @lineno += 1
        @position = -1 # Current match "\n" length will be added before we read the first token
        @line = (s.check_until(/\n/) || '').chomp
      when s.scan(/#.*/) then # ignore comments
      when s.scan(/\s+/) then # ignore blanks

      when s.scan(/\//)
        n = 0
        while char = s.post_match[n]
          case char
          when /\\/
            n += 1
          when /\//
            emit(:REGEX, Regexp.new(s.post_match[0...n]), s.matched_size)
            s.pos += n + 1
            break
          end
          n += 1
        end
      when s.scan(/service\b/) then emit(:SERVICE, s.matched)
      when s.scan(/client\b/) then  emit(:CLIENT, s.matched)
      when s.scan(/server\b/) then  emit(:SERVER, s.matched)
      when s.scan(/node\b/) then    emit(:NODE, s.matched)
      when s.scan(/'[^'\n]*'/) then emit(:STRING, s.matched[1...-1], s.matched_size)
      when s.scan(/"[^"\n]*"/) then emit(:STRING, s.matched[1...-1], s.matched_size)

      when s.scan(/ipv4\b/) then    emit(:IPV4, s.matched)
      when s.scan(/ipv6\b/) then    emit(:IPV6, s.matched)
      when s.scan(/policy\b/) then  emit(:POLICY, s.matched)

      when s.scan(/do\b/) then      emit(:DO, s.matched)
      when s.scan(/end\b/) then     emit(:END, s.matched)

      when s.scan(/\$\w[\w-]*/) then emit(:VARIABLE, s.matched[1..-1], s.matched_size)

      when s.scan(/pass\b/) then    emit(:PASS, s.matched)
      when s.scan(/block\b/) then   emit(:BLOCK, s.matched)
      when s.scan(/in\b/) then      emit(:IN, s.matched)
      when s.scan(/out\b/) then     emit(:OUT, s.matched)
      when s.scan(/log\b/) then     emit(:LOG, s.matched)
      when s.scan(/inet\b/) then    emit(:INET, s.matched)
      when s.scan(/inet6\b/) then   emit(:INET6, s.matched)
      when s.scan(/on\b/) then      emit(:ON, s.matched)
      when s.scan(/proto\b/) then   emit(:PROTO, s.matched)
      when s.scan(/from\b/) then    emit(:FROM, s.matched)
      when s.scan(/to\b/) then      emit(:TO, s.matched)
      when s.scan(/all\b/) then     emit(:ALL, s.matched)
      when s.scan(/any\b/) then     emit(:ANY, s.matched)
      when s.scan(/self\b/) then    emit(:SELF, s.matched)
      when s.scan(/port\b/) then    emit(:PORT, s.matched)
      when s.scan(/nat-to\b/) then  emit(:NAT_TO, s.matched)
      when s.scan(/rdr-to\b/) then  emit(:RDR_TO, s.matched)
      when s.scan(/srv\b/) then     emit(:SRV, s.matched)
      when s.scan(/apt-mirror\b/) then emit(:APT_MIRROR, s.matched)
      when s.scan(/azure-ip-range\b/) then emit(:AZURE_IP_RANGE, s.matched)

      when s.scan(/\d+\.\d+\.\d+\.\d+(\/\d+)?/) && ip = ipaddress?(s) then           emit(:ADDRESS, ip, s.matched_size)
      when s.scan(/[[:xdigit:]]*:[:[:xdigit:]]+(\/\d+)?/) && ip = ipaddress?(s) then emit(:ADDRESS, ip, s.matched_size)

      when s.scan(/\d+/) then      emit(:INTEGER, s.matched.to_i, s.matched_size)
      when s.scan(/\w[\w-]*/) then emit(:IDENTIFIER, s.matched)

      when s.scan(/=/) then         emit('=', s.matched)
      when s.scan(/:/) then         emit(':', s.matched)
      when s.scan(/,/) then         emit(',', s.matched)
      when s.scan(/{/) then         emit('{', s.matched)
      when s.scan(/}/) then         emit('}', s.matched)
      when s.scan(/\(/) then        emit('(', s.matched)
      when s.scan(/\)/) then        emit(')', s.matched)
      else
        raise SyntaxError.new('Syntax error', { filename: @filename, lineno: @lineno, position: @position, line: @line })
      end
      @position += s.matched_size if s.matched_size
    end

    begin
      do_parse
    rescue Racc::ParseError => e
      raise ParseError.new("Parse error: unexpected token: #{@current_token[0]}", @current_token[1])
    end
  end

  def emit(token, value, length = nil)
    if token && length.nil?
      raise "length must be explicitly passed when value is not a String (#{value.class.name})" unless value.is_a?(String)

      length = value.length
    end

    exvalue = {
      value: value,
      line: @line,
      lineno: @lineno,
      position: @position,
      filename: @filename,
      length: length,
    }
    @tokens << [token, exvalue]
  end

  def next_token
    @current_token = @tokens.shift
  end

  def initialize
    super
    @variables = {}
    @nodes = {}
    @saved_policies = {}
    @services = {} 
    @rule_factory = Puffy::RuleFactory.new
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

  def constraint_service_to_hosts(service, hosts)
    result = @services.fetch(service).deep_dup
    result.map! do |item|
      item[:from] = if item[:from]
        item[:from].product(hosts.fetch(:from, [{}])).map { |parts| parts[0].merge(parts[1].compact) }
      else
        hosts.fetch(:from, [{}])
      end

      item[:to] = if item[:to]
        item[:to].product(hosts.fetch(:to, [{}])).map { |parts| parts[0].merge(parts[1].compact) }
      else
        hosts.fetch(:to, [{}])
      end

      item
    end
    result
  end
