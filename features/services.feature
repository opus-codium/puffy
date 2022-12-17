Feature: Functions
  As a systems administrator
  In order to make the configuration files more manageable
  I want to be define and use reusable blocks

  Scenario: Define common services
    Given a file named "network.puffy" with:
    """
    localhost = {127.0.0.1 ::1}
    lan = {192.168.0.0/24 fe80::/10}

    service 'mysql' do
      pass proto tcp to port mysql
    end

    service 'ssh' do
      pass proto tcp to port ssh
    end

    service 'ssh-local' do
      service 'ssh' from $lan to $lan
    end

    service 'common' do
      server 'ssh-local'
      client 'ssh-local'
    end

    node 'client' do
      service 'common'
      client 'mysql' to 192.168.18.3
    end

    node 'server' do
      service 'common'
      server 'ssh' from 10.100.0.0/23
    end

    """
    When I successfully run `puffy generate -f Pf network.puffy server`
    Then the stdout should contain:
    """
    pass in quick proto tcp from 192.168.0.0/24 to 192.168.0.0/24 port 22
    pass in quick proto tcp from fe80::/10 to fe80::/10 port 22
    pass out quick proto tcp from 192.168.0.0/24 to 192.168.0.0/24 port 22
    pass out quick proto tcp from fe80::/10 to fe80::/10 port 22
    pass in quick proto tcp from 10.100.0.0/23 to any port 22
    """
    When I successfully run `puffy generate -f Pf network.puffy client`
    Then the stdout from "puffy generate -f Pf network.puffy client" should not contain:
    """
    pass in quick proto tcp from 10.100.0.0/23 to any port 22
    """
    And the stdout from "puffy generate -f Pf network.puffy client" should contain:
    """
    pass out quick proto tcp to 192.168.18.3 port 3306
    """
