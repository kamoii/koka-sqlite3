module main

import db/sqlite3

fun test-open()
    val conn = open-in-memory()
    println("opened")

fun main()
    test-open()
    println("done")
