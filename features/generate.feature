Feature: Generate firewall rules
  As a systems administrator
  In order to protect the systems I manage
  I want to generate their firewall configuration

  Background:
    Given a file named "network.puffy" with:
    """
    node 'example.com' do
      pass in proto tcp from any to port {http https}
    end
    """

  Scenario: Generate firewall rules for an OpenBSD node
    When I successfully run `puffy generate -f Pf network.puffy example.com`
    Then the stdout should contain:
    """
    pass in quick proto tcp to any port 80
    pass in quick proto tcp to any port 443
    """

  Scenario: Generate IPv4 firewall rules for a Linux node
    When I successfully run `puffy generate -f Iptables4 network.puffy example.com`
    Then the stdout should contain:
    """
    -A INPUT -m conntrack --ctstate NEW -p tcp --dport 80 -j ACCEPT
    -A INPUT -m conntrack --ctstate NEW -p tcp --dport 443 -j ACCEPT
    """

  Scenario: Generate IPv6 firewall rules for a Linux node
    When I successfully run `puffy generate -f Iptables6 network.puffy example.com`
    Then the stdout should contain:
    """
    -A INPUT -m conntrack --ctstate NEW -p tcp --dport 80 -j ACCEPT
    -A INPUT -m conntrack --ctstate NEW -p tcp --dport 443 -j ACCEPT
    """
