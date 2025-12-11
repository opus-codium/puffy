Feature: Policies
  Scenario: Default policy
    Given a file named "network.puffy" with:
    """
    policy block in log all
    policy block out log all
    node 'example.com' do
      pass in proto tcp from any to any port 443
    end
    node { /\.com$/ 'example.net' } do
      policy pass in all
      policy pass out all
      block in proto tcp from any to any port 443
    end
    """
    When I successfully run `puffy generate -f Pf network.puffy example.com`
    Then the stdout from "puffy generate -f Pf network.puffy example.com" should contain:
    """
    block in log all
    block out log all
    """
    When I successfully run `puffy generate -f Pf network.puffy example.net`
    Then the stdout from "puffy generate -f Pf network.puffy example.net" should contain:
    """
    pass in all
    pass out all
    """
    When I successfully run `puffy generate -f Pf network.puffy foo.example.com`
    Then the stdout from "puffy generate -f Pf network.puffy foo.example.com" should contain:
    """
    pass in all
    pass out all
    """
