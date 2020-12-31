version = "0.0.1"
author = "disruptek"
description = "magical function memoization across invocations"
license = "MIT"

requires "https://github.com/disruptek/criterion < 1.0.0"
requires "https://github.com/disruptek/frosty < 1.0.0"
requires "https://github.com/guzba/supersnappy < 2.0.0"
requires "https://github.com/disruptek/testes >= 0.7.13 & < 1.0.0"

task test, "run tests for ci":
  when defined(windows):
    exec "testes.cmd"
  else:
    exec findExe"testes"

task demo, "generate demo":
  exec """demo docs/demo.svg "nim c --gc:arc --define:danger --out=\$1 tests/test.nim""""
