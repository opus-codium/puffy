Feature: Generate firewall rules
  As a systems administrator
  In order to protect the systems I manage
  I want to generate their firewall configuration

  Background:
    Given a file named "network.rb" with:
    """
    host 'example.com' do
      pass :in, proto: :tcp, to: { port: %w(http https) }
    end
    """

  Scenario: Generate firewall rules for an OpenBSD host
    When I run `melt generate -f Pf network.rb example.com`
    Then the stdout should contain:
    """
    pass in quick proto tcp to any port 80
    pass in quick proto tcp to any port 443
    """

  Scenario: Generate IPv4 firewall rules for a Linux host
    When I run `melt generate -f Netfilter4 network.rb example.com`
    Then the stdout should contain:
    """
    -A INPUT -m conntrack --ctstate NEW -p tcp --dport 80 -j ACCEPT
    -A INPUT -m conntrack --ctstate NEW -p tcp --dport 443 -j ACCEPT
    """

  Scenario: Generate IPv6 firewall rules for a Linux host
    When I run `melt generate -f Netfilter6 network.rb example.com`
    Then the stdout should contain:
    """
    -A INPUT -m conntrack --ctstate NEW -p tcp --dport 80 -j ACCEPT
    -A INPUT -m conntrack --ctstate NEW -p tcp --dport 443 -j ACCEPT
    """
