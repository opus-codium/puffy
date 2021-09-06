Feature: Policies
  Scenario: Default policy
    Given a file named "network.rb" with:
    """
    policy :block
    node 'example.com' do
      pass :in, proto: :tcp, to: { port: 443 }
    end
    node /\.com$/, 'example.net' do
      policy :pass
      block :in, proto: :tcp, to: { port: 443 }
    end
    """
    And a file named "network.melt" with:
    """
    policy block
    node 'example.com' do
      pass in proto tcp from any to any port 443
    end
    node { /\.com$/ 'example.net' } do
      policy pass
      block in proto tcp from any to any port 443
    end
    """
    When I successfully run `melt generate -f Pf network.rb example.com`
    Then the stdout from "melt generate -f Pf network.rb example.com" should contain:
    """
    block in all
    block out all
    """
    When I successfully run `melt generate -f Pf network.rb example.net`
    Then the stdout from "melt generate -f Pf network.rb example.net" should contain:
    """
    pass in all
    pass out all
    """
    When I successfully run `melt generate -f Pf network.rb foo.example.com`
    Then the stdout from "melt generate -f Pf network.rb foo.example.com" should contain:
    """
    pass in all
    pass out all
    """
    When I successfully run `melt generate -f Pf network.melt example.com`
    Then the stdout from "melt generate -f Pf network.melt example.com" should contain:
    """
    block in all
    block out all
    """
    When I successfully run `melt generate -f Pf network.melt example.net`
    Then the stdout from "melt generate -f Pf network.melt example.net" should contain:
    """
    pass in all
    pass out all
    """
    When I successfully run `melt generate -f Pf network.melt foo.example.com`
    Then the stdout from "melt generate -f Pf network.melt foo.example.com" should contain:
    """
    pass in all
    pass out all
    """
