import testes
import carnac

{.experimental: "strictFuncs".}

template test(fn: typed; x: int; r: int) =
  let y = fn(x)
  if y != r:
    raise newException(AssertionDefect, "compute")

testes:
  block:
    ## without carnac

    func fib1(x: int): int =
      case x
      of 0: 1
      of 1: 1
      else:
        fib1(x - 1) + fib1(x - 2)

    block ten:
      test fib1, 10, 89
    block forty_five:
      test fib1, 45, 1836311903

  block:
    ## with carnac

    func fib2(x: int): int {.carnac.} =
      case x
      of 0: 1
      of 1: 1
      else:
        fib2(x - 1) + fib2(x - 2)

    block ten:
      test fib2, 10, 89
    block forty_five:
      test fib2, 45, 1836311903
