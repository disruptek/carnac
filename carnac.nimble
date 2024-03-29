version = "0.0.2"
author = "disruptek"
description = "magical function memoization across invocations"
license = "MIT"

requires "https://github.com/disruptek/frosty >= 1.0.0 & < 2.0.0"
requires "https://github.com/guzba/supersnappy < 2.0.0"

when not defined(release):
  requires "https://github.com/disruptek/criterion < 1.0.0"
  requires "https://github.com/disruptek/balls >= 3.0.0 & < 4.0.0"

task test, "run tests for ci":
  when defined(windows):
    exec "balls.cmd"
  else:
    exec findExe"balls"

task demo, "generate demo":
  exec """demo docs/demo.svg "nim c --gc:arc --define:danger --out=\$1 tests/test.nim""""
