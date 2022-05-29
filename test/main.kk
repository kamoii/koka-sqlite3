module main

import db/sqlite3

fun test-open()
    val db = open-in-memory()
    val ssql = "select 7".ssql
    val (stmt, ssql2) = db.prepare-v2(ssql)
    trace-any("stmt", stmt)
    trace-any("ssql", ssql2)
    println(stmt.step.show)
    // no show for int64???
    println(stmt.column-int64(0).int.show)
    println(stmt.step.show)
    println(stmt.step.show)
    stmt.finalize()

fun main()
    test-open()
