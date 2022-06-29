module main

import db/sqlite3
import test

fun main()
  run-test
    test-open()

fun test-open()
  val db = open-in-memory()
  val ssql = "select 7".ssql
  val (stmt, ssql-rest) = db.prepare-v2(ssql)
  test("ssql-rest must be empty")
    ssql-rest.is-nothing
  test("first step should be Row")
    stmt.step.is-row
  test("first column should be 7")
    stmt.column-int64(0).int == 7
  test("shoud be DONE")
    stmt.step.is-done
  stmt.finalize()
