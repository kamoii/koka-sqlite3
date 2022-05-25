module main

import db/sqlite3

fun test-open()
    val db = open-in-memory()
    val ssql = "select 1".ssql
    val (stmt, _ssql) = db.prepare-v2(ssql)
    trace-any("stmt", stmt)
    stmt.finalize()

fun main()
    test-open()
    println("done")
