# Changelog

## [v1.0.0](https://github.com/opus-codium/puffy/tree/v1.0.0) (2024-04-09)

[Full Changelog](https://github.com/opus-codium/puffy/compare/v0.3.1...v1.0.0)

**Implemented enhancements:**

- Setup dependabot [\#36](https://github.com/opus-codium/puffy/pull/36) ([smortex](https://github.com/smortex))
- Add support for Ruby 3.3 [\#33](https://github.com/opus-codium/puffy/pull/33) ([smortex](https://github.com/smortex))

## [v0.3.1](https://github.com/opus-codium/puffy/tree/v0.3.1) (2023-11-22)

[Full Changelog](https://github.com/opus-codium/puffy/compare/v0.3.0...v0.3.1)

**Fixed bugs:**

- Ensure parser is up-to-date before build [\#31](https://github.com/opus-codium/puffy/pull/31) ([smortex](https://github.com/smortex))

## [v0.3.0](https://github.com/opus-codium/puffy/tree/v0.3.0) (2023-01-04)

[Full Changelog](https://github.com/opus-codium/puffy/compare/v0.2.0...v0.3.0)

**Implemented enhancements:**

- Add support for nested variables [\#29](https://github.com/opus-codium/puffy/pull/29) ([smortex](https://github.com/smortex))

**Fixed bugs:**

- Fix iptables rules without direction [\#28](https://github.com/opus-codium/puffy/pull/28) ([smortex](https://github.com/smortex))

## [v0.2.0](https://github.com/opus-codium/puffy/tree/v0.2.0) (2022-12-18)

[Full Changelog](https://github.com/opus-codium/puffy/compare/v0.1.0...v0.2.0)

**Breaking changes:**

- Rename the netfilter formatter to iptables [\#19](https://github.com/opus-codium/puffy/pull/19) ([smortex](https://github.com/smortex))

**Implemented enhancements:**

- New `apt-mirror()` function to expand `mirror+http://` URI used by apt\(1\) [\#18](https://github.com/opus-codium/puffy/pull/18) ([smortex](https://github.com/smortex))
- New `srv()` function to query SRV records [\#17](https://github.com/opus-codium/puffy/pull/17) ([smortex](https://github.com/smortex))
- Improve services error reporting [\#16](https://github.com/opus-codium/puffy/pull/16) ([smortex](https://github.com/smortex))

**Fixed bugs:**

- Fix service constraining [\#26](https://github.com/opus-codium/puffy/pull/26) ([smortex](https://github.com/smortex))
- Fix parsing IPv6 addresses starting with `:` [\#24](https://github.com/opus-codium/puffy/pull/24) ([smortex](https://github.com/smortex))
- Fix missing require [\#22](https://github.com/opus-codium/puffy/pull/22) ([smortex](https://github.com/smortex))
- Fix node list support [\#21](https://github.com/opus-codium/puffy/pull/21) ([smortex](https://github.com/smortex))

**Merged pull requests:**

- Rename the project [\#11](https://github.com/opus-codium/puffy/pull/11) ([smortex](https://github.com/smortex))

## [v0.1.0](https://github.com/opus-codium/puffy/tree/v0.1.0) (2021-10-11)

[Full Changelog](https://github.com/opus-codium/puffy/compare/aeea61ce647543fbc4c3567e8b5dd30bee5f0edf...v0.1.0)

**Implemented enhancements:**

- Implement a proper language for configuration [\#10](https://github.com/opus-codium/puffy/pull/10) ([smortex](https://github.com/smortex))
- Resolve example.com instead of localhost [\#2](https://github.com/opus-codium/puffy/pull/2) ([smortex](https://github.com/smortex))
- Fix CI [\#1](https://github.com/opus-codium/puffy/pull/1) ([smortex](https://github.com/smortex))

**Merged pull requests:**

- Rename "hosts" to "nodes" [\#9](https://github.com/opus-codium/puffy/pull/9) ([smortex](https://github.com/smortex))
- Drop support for EOL ruby versions [\#8](https://github.com/opus-codium/puffy/pull/8) ([smortex](https://github.com/smortex))
- Rely on the Cri DSL to manage parameters [\#7](https://github.com/opus-codium/puffy/pull/7) ([smortex](https://github.com/smortex))
- Switch from Thor to Cri for command parsing [\#6](https://github.com/opus-codium/puffy/pull/6) ([smortex](https://github.com/smortex))
- Reduce diff context to fix CI [\#5](https://github.com/opus-codium/puffy/pull/5) ([smortex](https://github.com/smortex))
- Switch CI from Travis to GitHub actions [\#4](https://github.com/opus-codium/puffy/pull/4) ([smortex](https://github.com/smortex))
- README.md: fix typo [\#3](https://github.com/opus-codium/puffy/pull/3) ([kenyon](https://github.com/kenyon))



\* *This Changelog was automatically generated by [github_changelog_generator](https://github.com/github-changelog-generator/github-changelog-generator)*
