version = "0.0.1"
author = "disruptek"
description = "magical function memoization across runtimes"
license = "MIT"

requires "https://github.com/disruptek/criterion < 1.0.0"
requires "https://github.com/disruptek/frosty < 1.0.0"
requires "https://github.com/guzba/supersnappy < 2.0.0"
requires "https://github.com/disruptek/testes < 1.0.0"

proc execCmd(cmd: string) =
  echo "exec: " & cmd
  exec cmd

proc execTest(test: string) =
  when getEnv("GITHUB_ACTIONS", "false") != "true":
    execCmd "nim c -r -f " & test
    when (NimMajor, NimMinor) >= (1, 2):
      execCmd "nim c -d:danger --gc:arc -r -f " & test
  else:
    execCmd "nim c   -d:danger -r -f " & test
    execCmd "nim cpp -d:danger -r -f " & test
    when (NimMajor, NimMinor) >= (1, 2):
      execCmd "nim c --useVersion:1.0 -d:danger -r -f " & test
      execCmd "nim c   -d:danger --gc:arc -r -f " & test
      execCmd "nim cpp -d:danger --gc:arc -r -f " & test

task test, "run tests for ci":
  execTest("tests/test.nim")

task bench, "generate benchmark":
  exec "termtosvg docs/bench.svg --max-frame-duration=3000 --loop-delay=3000 --screen-geometry=80x30 --template=window_frame_powershell --command=\"nim c --gc:arc --define:danger -r tests/bench.nim\""
