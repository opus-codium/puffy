# Melt

[![Build Status](https://travis-ci.com/opus-codium/melt.svg?branch=master)](https://travis-ci.com/opus-codium/melt)
[![Maintainability](https://api.codeclimate.com/v1/badges/1d46ac8511718fd284fd/maintainability)](https://codeclimate.com/github/opus-codium/melt/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/1d46ac8511718fd284fd/test_coverage)](https://codeclimate.com/github/opus-codium/melt/test_coverage)
[![Inline docs](http://inch-ci.org/github/opus-codium/melt.svg?branch=master)](http://inch-ci.org/github/opus-codium/melt)

## Features

* Generate rules for [Netfilter](http://www.netfilter.org/) and [PF](http://www.openbsd.org/faq/pf/) (extensible);
* IPv6 and IPv4 support;
* Define the configuration of multiple *nodes* in a single file;
* Define *services* as group of rules to mix-in in *nodes* rules definitions;
* Handle NAT & port redirection;

## Requirements

* Accurate DNS information;

## Syntax

The Melt syntax is inspired by the syntax of the [OpenBSD Packet Filter](http://www.openbsd.org/faq/pf/), with the ability to group rules in reusable blocks in order to describe all rules of a network of nodes in a single file.

Rules must appear in either a *node* or *service* definition, *services* being
reusable blocks of related rules:

~~~
service base do
  service ntp
  service ssh
end

service ntp do
  pass out proto udp from any to port ntp
end

service ssh do
  pass in proto tcp form any to port ssh
end

node 'db.example.com' do
  service base
  pass in proto tcp from 'www1.example.com' to port postgresql
end

node /www\d+.example.com/ do
  service base
  pass in proto tcp from any to port www
  pass out proto tcp from any to 'db.example.com' port postgresql
end
~~~
