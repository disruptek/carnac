import std/sequtils
import std/macros
import std/exitprocs
import std/os
import std/tables
import std/hashes

import frosty
import supersnappy

when (NimMajor, NimMinor) < (1, 4):
  {.error: "requires nim-1.4".}

{.experimental: "strictFuncs".}

proc isMutable(n: NimNode): bool =
  ## true if the identdefs contain a var
  n.expectKind nnkIdentDefs
  n[^2].kind == nnkVarTy

iterator names(n: NimNode): NimNode =
  ## yield the names from comma-delimited set of params
  for name in n[0 ..< len(n)-2]:  # ie. omit (:type) and (=default)
    yield name

type
  NodeFilter = proc(n: NimNode): NimNode

proc filter(n: NimNode; f: NodeFilter): NimNode =
  result = f(n)
  if result.isNil:
    result = copyNimNode n
    for kid in items(n):
      result.add filter(kid, f)

proc desym(n: NimNode): NimNode =
  result = if n.kind == nnkSym: ident(repr n) else: n

proc replacedSymsWithIdents(n: NimNode): NimNode =
  proc desymifier(n: NimNode): NimNode =
    case n.kind
    of nnkSym:
      result = desym n
    else:
      discard
  result = filter(n, desymifier)

let dir = getEnv("XDG_RUNTIME_DIR", ".") / ".carnac"

proc loadCache[T](table: var T; name: string; sig: string): bool =
  ## true if we read cached data from disk
  let fn = dir / addFileExt(name & "-" & sig, "frosty")
  createDir dir
  result = fileExists(fn)
  if result:
    thaw(uncompress readFile(fn), table)

proc storeCache[T](table: T; name: string; sig: string) =
  let fn = dir / addFileExt(name & "-" & sig, "frosty")
  createDir dir
  writeFile fn, compress(freeze table)

macro carnac*(n: typed) =
  result = n
  if n.kind != nnkFuncDef:
    return

  var returnType: NimNode
  var args = nnkTupleConstr.newTree
  for i, p in pairs n.params:
    if i == 0:
      returnType = p
    elif p.isMutable:
      # just bail if there's any hint of mutability
      return
    else:
      for name in p.names:
        args.add nnkExprColonExpr.newTree(ident name.strVal,
                                          ident name.repr)
  result = newStmtList()

  let table = genSym(nskVar, "carnac")
  var cache = nnkBracketExpr.newTree bindSym"Table"
  cache.add ident"Hash"
  cache.add ident(repr returnType)
  result.add:
    nnkVarSection.newTree:
      newIdentDefs(table, cache, newEmptyNode())

  let load = newDotExpr(table, bindSym"loadCache")
  result.add:
    nnkDiscardStmt.newTree:
      newCall(load, newLit $n.name, newLit n.name.signatureHash)

  let store = newDotExpr(table, bindSym"storeCache")
  let exit = genSym(nskProc, "exit")
  result.add newProc(exit,
    body = newCall(store, newLit $n.name, newLit n.name.signatureHash))
  result.add newCall(bindSym"addExitProc", exit)

  var save = newStmtList()
  args = newCall(ident"hash", args)
  save.add copyNimTree(n.body).replacedSymsWithIdents
  save.add newCall(ident"[]=", table, args, ident"result")

  result.add newProc(ident $n.name, toSeq n.params.replacedSymsWithIdents,
                     body = save, pragmas = n.pragma)
