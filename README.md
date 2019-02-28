# Melt

[![Build Status](https://travis-ci.com/opus-codium/melt.svg?branch=master)](https://travis-ci.com/opus-codium/melt)
[![Maintainability](https://api.codeclimate.com/v1/badges/1d46ac8511718fd284fd/maintainability)](https://codeclimate.com/github/opus-codium/melt/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/1d46ac8511718fd284fd/test_coverage)](https://codeclimate.com/github/opus-codium/melt/test_coverage)
[![Inline docs](http://inch-ci.org/github/opus-codium/melt.svg?branch=master)](http://inch-ci.org/github/opus-codium/melt)

## Features

* Generate rules for [Netfilter](http://www.netfilter.org/) and [PF](http://www.openbsd.org/faq/pf/) (extensible);
* IPv6 and IPv4 support;
* Define the configuration of multiple *hosts* in a single file;
* Define *services* as group of rules to mix-in in *hosts* rules definitions;
* Handle NAT & port redirection;

## Requirements

* Accurate DNS information;

## Syntax

The Melt {Melt::Rule} syntax if basically a [Ruby](https://www.ruby-lang.org) representation of the [OpenBSD Packet Filter](http://www.openbsd.org/faq/pf/) rules, with the ability to group them in reusable blocks in order to describe network rules in a single file.

As an example, the following PF rules:

    pass in proto tcp to port 80
    pass in proto udp from 192.168.1.0/24 port 123 to port 123

can be expressed as:

~~~ruby
pass :in, proto: :tcp, to: { port: 80 }
pass :in, proto: :udp, from: { host: '192.168.1.0/24', port: 123 }, to: { port: 123 }
~~~

Rules must appear in either a *host* or *service* definition, *services* being
reusable blocks of related rules:

~~~ruby
service 'base' do
  service 'ntp'
  service 'ssh'
end

service 'ntp' do
  pass :out, proto: :udp, to: { port: 'ntp' }
end

service 'ssh' do
  pass :in, proto: :tcp, to: { port: 'ssh' }
end

host 'db.example.com' do
  service 'base'
  pass :in, proto: :tcp, from: { host: 'www1.example.com' }, to: { port: 'postgresql' }
end

host /www\d+.example.com/ do
  service 'base'
  pass :in, proto: :tcp, to: { port: 'www' }
  pass :out, proto: :tcp, to: { host: 'db.example.com', port: 'postgresql' }
end
~~~

## Debugging rulesets

Logging is handy for debugging missing rules in your firewall configuration.  An easy way to diagnose missing rules consists in setting a *pass* `policy`, and `log` both *in* and *out*:

~~~ruby
host 'debilglos' do
  policy :pass

  # Existing rules

  log [:in, :out]
end
~~~
