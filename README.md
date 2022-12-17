# Puffy

[![Build Status](https://github.com/opus-codium/puffy/actions/workflows/ci.yml/badge.svg?branch=master)](https://github.com/opus-codium/puffy/actions/workflows/ci.yml)
[![Maintainability](https://api.codeclimate.com/v1/badges/e12923a13a5e17698b05/maintainability)](https://codeclimate.com/github/opus-codium/puffy/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/e12923a13a5e17698b05/test_coverage)](https://codeclimate.com/github/opus-codium/puffy/test_coverage)
[![Inline docs](http://inch-ci.org/github/opus-codium/puffy.svg?branch=master)](http://inch-ci.org/github/opus-codium/puffy)

## Features

* Generate rules for [iptables](http://www.netfilter.org/) and [PF](http://www.openbsd.org/faq/pf/) (extensible);
* IPv6 and IPv4 support;
* Define the configuration of multiple *nodes* in a single file;
* Define *services* as group of rules to mix-in in *nodes* rules definitions;
* Handle NAT & port redirection;

## Requirements

* Accurate DNS information;

## Syntax

The Puffy syntax is inspired by the syntax of the [OpenBSD Packet Filter](http://www.openbsd.org/faq/pf/), with the ability to group rules in reusable blocks in order to describe all rules of a network of nodes in a single file.

Rules must appear in either a *node* or *service* definition, *services* being
reusable blocks of related rules:

~~~
service ntp do
  pass proto udp to port ntp
end

service postgresql do
  pass proto tcp to port postgresql
end

service ssh do
  pass proto tcp to port ssh
end

service www do
  pass proto tcp to port {http https}
end

service base do
  client ntp
  server ssh
end

node 'db.example.com' do
  service base
  server postgresql from 'www1.example.com'
end

node /www\d+.example.com/ do
  service base
  server www
  client postgresql to 'db.example.com'
  pass in proto tcp from any to port 8000
end
~~~
