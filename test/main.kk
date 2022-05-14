module main

import db/sqlite3

fun test-open()
    val db = open-in-memory-db()
    val stmt = db.prepare("select 1")
    trace-any("stmt", stmt) 
    println("opened")

fun main()
    test-open()
    println("done")
