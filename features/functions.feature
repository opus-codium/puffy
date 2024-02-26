Feature: Functions
  As a systems administrator
  In order to make the configuration files more manageable
  I want to be able to use functions to generate the final configuration.

  Scenario: Generate firewall rules using an apt mirror
    apt-transport-mirror(1) allows to fetch a list of mirrors from the
    Internet.

    Given a file named "network.puffy" with:
    """
    node 'example.com' do
      pass out to apt-mirror('mirror+http://mirrorlists.choria.io/apt/release/debian/bullseye/mirrors.txt')
    end
    """
    When I successfully run `puffy generate -f Pf network.puffy example.com`
    Then the stdout should contain:
    """
    pass out quick proto tcp to 2600:3c03::f03c:91ff:fedf:e379 port 80
    pass out quick proto tcp to 2a01:7e00::f03c:91ff:fedf:226a port 80
    pass out quick proto tcp to 66.228.41.18 port 80
    pass out quick proto tcp to 144.76.99.150 port 80
    pass out quick proto tcp to 178.79.157.154 port 80
    pass out quick proto tcp to 144.76.99.150 port 443
    pass out quick proto tcp to 2a01:7e00::f03c:91ff:fedf:226a port 443
    pass out quick proto tcp to 178.79.157.154 port 443
    pass out quick proto tcp to 2600:3c03::f03c:91ff:fedf:e379 port 443
    pass out quick proto tcp to 66.228.41.18 port 443
    """

  Scenario: Generate firewall rules using an SRV record
    A single SRV record can store multiple combinations of host+port for a
    single service.

    Given a file named "network.puffy" with:
    """
    node 'example.com' do
      pass out to srv('_x-puppet._tcp.blogreen.org')
    end
    """
    When I successfully run `puffy generate -f Pf network.puffy example.com`
    Then the stdout should contain:
    """
    pass out quick proto tcp to 2a01:4f9:c010:e1dd:: port 8140
    pass out quick proto tcp to 135.181.146.104 port 8140
    """
