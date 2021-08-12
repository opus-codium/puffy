Feature: Puppet
  Scenario: Generate firewall rules for a host
    Given a file named "network.rb" with:
    """
    host 'example.com' do
      pass :in, proto: :tcp, to: { port: %w(http https) }
    end
    """
    When I successfully run `melt puppet generate network.rb`
    Then the file "example.com/pf/pf.conf" should contain:
    """
    pass in quick proto tcp to any port 80
    pass in quick proto tcp to any port 443
    """
    And the file "example.com/netfilter/rules.v4" should contain:
    """
    -A INPUT -m conntrack --ctstate NEW -p tcp --dport 80 -j ACCEPT
    -A INPUT -m conntrack --ctstate NEW -p tcp --dport 443 -j ACCEPT
    """
    And the file "example.com/netfilter/rules.v6" should contain:
    """
    -A INPUT -m conntrack --ctstate NEW -p tcp --dport 80 -j ACCEPT
    -A INPUT -m conntrack --ctstate NEW -p tcp --dport 443 -j ACCEPT
    """

  Scenario: Displays firewall rule differences
    Given a file named "network.rb" with:
    """
    host 'example.com' do
      pass :in, proto: :tcp, to: { port: %w(ssh http) }
    end
    """
    And a file named "example.com/pf/pf.conf" with:
    """
    match in all scrub (no-df)
    set skip on lo
    block in all
    block out all
    pass in quick proto tcp to any port 80
    pass in quick proto tcp to any port 443

    """
    And a file named "example.com/netfilter/rules.v4" with:
    """
    *filter
    :INPUT DROP [0:0]
    :FORWARD DROP [0:0]
    :OUTPUT DROP [0:0]
    -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
    -A INPUT -m conntrack --ctstate NEW -p tcp --dport 80 -j ACCEPT
    -A INPUT -m conntrack --ctstate NEW -p tcp --dport 443 -j ACCEPT
    -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
    -A OUTPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
    COMMIT

    """
    And a file named "example.com/netfilter/rules.v6" with:
    """
    *filter
    :INPUT DROP [0:0]
    :FORWARD DROP [0:0]
    :OUTPUT DROP [0:0]
    -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
    -A INPUT -m conntrack --ctstate NEW -p tcp --dport 80 -j ACCEPT
    -A INPUT -m conntrack --ctstate NEW -p tcp --dport 443 -j ACCEPT
    -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
    -A OUTPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
    COMMIT

    """
    When I successfully run `melt puppet diff network.rb`
    Then the stdout should contain:
    """
    --- a/example.com/pf/pf.conf
    +++ b/example.com/pf/pf.conf
    @@ -4,3 +5,3 @@
     block out all
    +pass in quick proto tcp to any port 22
     pass in quick proto tcp to any port 80
    -pass in quick proto tcp to any port 443
    --- a/example.com/netfilter/rules.v4
    +++ b/example.com/netfilter/rules.v4
    @@ -5,4 +6,4 @@
     -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
    +-A INPUT -m conntrack --ctstate NEW -p tcp --dport 22 -j ACCEPT
     -A INPUT -m conntrack --ctstate NEW -p tcp --dport 80 -j ACCEPT
    --A INPUT -m conntrack --ctstate NEW -p tcp --dport 443 -j ACCEPT
     -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
    --- a/example.com/netfilter/rules.v6
    +++ b/example.com/netfilter/rules.v6
    @@ -5,4 +6,4 @@
     -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
    +-A INPUT -m conntrack --ctstate NEW -p tcp --dport 22 -j ACCEPT
     -A INPUT -m conntrack --ctstate NEW -p tcp --dport 80 -j ACCEPT
    --A INPUT -m conntrack --ctstate NEW -p tcp --dport 443 -j ACCEPT
     -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
    """
