module main

import db/sqlite3

fun test-open()
    val db = open-in-memory()
    val stmt = db.prepare-v2("select 1")
    trace-any("stmt", stmt)
    stmt.finalize()

fun main()
    test-open()
    println("done")
