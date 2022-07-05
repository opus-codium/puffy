Feature: Functions
  As a systems administrator
  In order to make the configuration files more manageable
  I want to be able to use functions to generate the final configuration.

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
