# carnac

[![Test Matrix](https://github.com/disruptek/carnac/workflows/CI/badge.svg)](https://github.com/disruptek/carnac/actions?query=workflow%3ACI)
[![GitHub release (latest by date)](https://img.shields.io/github/v/release/disruptek/carnac?style=flat)](https://github.com/disruptek/carnac/releases/latest)
![Minimum supported Nim version](https://img.shields.io/badge/nim-1.4.2%2B-informational?style=flat&logo=nim)
[![License](https://img.shields.io/github/license/disruptek/carnac?style=flat)](#license)
[![buy me a coffee](https://img.shields.io/badge/donate-buy%20me%20a%20coffee-orange.svg)](https://www.buymeacoffee.com/disruptek)

Magical function memoization across program invocations.

## Usage

1. Add the `carnac` pragma to your `func` definitions.
1. Run your program and invoke your `func` -- it's slow.
1. Run your program and invoke your `func` -- it's fast.
...
1. Profit!

## Installation

```
$ nimph clone carnac
```
or if you're still using Nimble like it's 2012,
```
$ nimble install https://github.com/disruptek/carnac
```

## Documentation

[The documentation employs Nim's `runnableExamples` feature to
ensure that usage examples are guaranteed to be accurate. The
documentation is rebuilt during the CI process and hosted on
GitHub.](https://disruptek.github.io/carnac/carnac.html)

## License
MIT
