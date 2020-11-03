import std/times
import std/strutils

import testes

testes:
  func fib(x: int): int {.carnac.} =
    case x
    of 0: 1
    of 1: 1
    else:
      fib(x - 1) + fib(x - 2)

  echo fib(50)
