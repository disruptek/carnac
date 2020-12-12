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
  ## yield the names from a (multi-variable?) ident def
  assert n.kind == nnkIdentDefs
  for name in n[0 ..< len(n)-2]:  # ie. omit (:type) and (=default)
    yield name

type
  NodeFilter = proc(n: NimNode): NimNode

proc filter(n: NimNode; f: NodeFilter): NimNode =
  ## zevv's famous filter
  result = f(n)
  if result.isNil:
    result = copyNimNode n
    for kid in items(n):
      result.add filter(kid, f)

proc desym(n: NimNode): NimNode =
  ## turn a sym into an ident
  result = if n.kind == nnkSym: ident(repr n) else: n

proc replacedSymsWithIdents(n: NimNode): NimNode =
  ## yield a new tree with syms as idents
  proc desymifier(n: NimNode): NimNode =
    ## return nil or a desym'd sym
    case n.kind
    of nnkSym:
      result = desym n
    else:
      discard
  # filter the input to produce desym'd output
  result = filter(n, desymifier)

# query the env to determine the cache directory at runtime
let dir = getEnv("XDG_RUNTIME_DIR", ".") / ".carnac"
static:
  hint "carnac cache in " & getEnv("XDG_RUNTIME_DIR", ".") / ".carnac"

proc loadCache[T](table: var T; name: string; sig: string): bool =
  ## true if we read cached data from disk
  let fn = dir / addFileExt(name & "-" & sig, "frosty")
  createDir dir
  result = fileExists(fn)
  if result:
    thaw(uncompress readFile(fn), table)

proc storeCache[T](table: T; name: string; sig: string) =
  ## write the cache to disk
  let fn = dir / addFileExt(name & "-" & sig, "frosty")
  createDir dir
  writeFile fn, compress(freeze table)

macro carnac*(n: typed) =
  ## apply to a func in order to cache its results

  # this is pretty aggressive; we can loosen it later
  if n.kind != nnkFuncDef:
    hint "carnac can only consume funcs"
    return n

  # collect the details of the func; args, return type, etc.
  # if any argument is mutable, we'll skip mutating the func.
  var returnType: NimNode
  var args = nnkTupleConstr.newTree
  for i, p in n.params.pairs:
    if i == 0:
      returnType = p
    elif p.isMutable:
      # just bail if there's any hint of mutability
      warning "carnac found mutability in " & p.name.repr
      return n
    else:
      for name in p.names:
        args.add nnkExprColonExpr.newTree(ident name.strVal,
                                          ident name.repr)
  result = newStmtList()

  # setup a table to serve as our cache, with the proper key/value types
  let table = genSym(nskVar, "carnac")
  var cache = nnkBracketExpr.newTree bindSym"Table"
  cache.add bindSym"Hash"
  cache.add ident(repr returnType)
  result.add:
    nnkVarSection.newTree:
      newIdentDefs(table, cache, newEmptyNode())

  # add a call to load the cache at runtime
  result.add:
    nnkDiscardStmt.newTree:
      newCall(bindSym"loadCache", table,
              newLit $n.name, newLit n.name.signatureHash)

  # add a call to store the cache at program exit
  let exit = genSym(nskProc, "exit")
  result.add newProc(exit,
    body = newCall(bindSym"storeCache", table,
                   newLit $n.name, newLit n.name.signatureHash))
  result.add newCall(bindSym"addExitProc", exit)

  # add the cache read and cache write to the func body
  var save = newStmtList()
  let hash = genSym(nskLet, "hash")
  save.add newLetStmt(hash, newCall(bindSym"hash", args))
  save.add newIfStmt (newCall(bindSym"contains", table, hash),
                      nnkReturnStmt.newTree newCall(bindSym"[]", table, hash))
  save.add copyNimTree(n.body).replacedSymsWithIdents
  save.add newCall(bindSym"[]=", table, hash, ident"result")

  var pragmas =
    if true:
      newEmptyNode()
    elif n.pragma.kind == nnkPragma:
      copyNimTree n.pragma
    else:
      newTree nnkPragma

  # add the new proc to our result, using the old name
  result.add newProc(ident $n.name, toSeq n.params.replacedSymsWithIdents,
                     body = save, pragmas = pragmas)
