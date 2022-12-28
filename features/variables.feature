Feature: Variables
  As a systems administrator
  In order to make the configuration files more manageable
  I want to define and use variabels

  Scenario: Basic variables
    Given a file named "network.puffy" with:
    """
    www1 = 192.168.0.1
    www = $www1
    db = 192.168.0.10

    node 'example.com' do
      pass in proto tcp to $www port {http https}
      pass out proto tcp to $db port 5432
    end
    """
    When I successfully run `puffy generate -f Pf network.puffy example.com`
    Then the stdout should contain:
    """
    pass in quick proto tcp to 192.168.0.1 port 80
    pass in quick proto tcp to 192.168.0.1 port 443
    pass out quick proto tcp to 192.168.0.10 port 5432
    """

  Scenario: List variables
    Given a file named "network.puffy" with:
    """
    www = { 192.168.0.1 192.168.0.2 192.168.0.3 }
    db = { 192.168.0.10 192.168.0.11 }

    node 'example.com' do
      pass in proto tcp to $www port {http https}
      pass out proto tcp to $db port 5432
    end
    """
    When I successfully run `puffy generate -f Pf network.puffy example.com`
    Then the stdout should contain:
    """
    pass in quick proto tcp to 192.168.0.1 port 80
    pass in quick proto tcp to 192.168.0.2 port 80
    pass in quick proto tcp to 192.168.0.3 port 80
    pass in quick proto tcp to 192.168.0.1 port 443
    pass in quick proto tcp to 192.168.0.2 port 443
    pass in quick proto tcp to 192.168.0.3 port 443
    pass out quick proto tcp to 192.168.0.10 port 5432
    pass out quick proto tcp to 192.168.0.11 port 5432
    """

  Scenario: Nested variables
    Given a file named "network.puffy" with:
    """
    www1 = 192.168.0.1
    www2 = { 192.168.0.2 192.168.0.3 }
    www = { $www1 $www2 }
    db1 = 192.168.0.10
    db2 = { 192.168.0.11 }
    db = { $db1 $db2 }

    node 'example.com' do
      pass in proto tcp to $www port {http https}
      pass out proto tcp to $db port 5432
    end
    """
    When I successfully run `puffy generate -f Pf network.puffy example.com`
    Then the stdout should contain:
    """
    pass in quick proto tcp to 192.168.0.1 port 80
    pass in quick proto tcp to 192.168.0.2 port 80
    pass in quick proto tcp to 192.168.0.3 port 80
    pass in quick proto tcp to 192.168.0.1 port 443
    pass in quick proto tcp to 192.168.0.2 port 443
    pass in quick proto tcp to 192.168.0.3 port 443
    pass out quick proto tcp to 192.168.0.10 port 5432
    pass out quick proto tcp to 192.168.0.11 port 5432
    """
