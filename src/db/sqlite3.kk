module db/sqlite3

import std/os/path

extern import
    c { vcpkg = "sqlite3"; library = "sqlite3" }

extern import
    c file "sqlite3-inline.c"

// NOTE: want newtype-like feature..
abstract struct db
    obj : any  // sqlite3*

abstract struct stmt
    obj : any  // sqlite3_stmt*

// * open
// https://www.sqlite.org/c3ref/open.html

extern sqlite3-open( ^filename : string ) : fsys error<any>
    c "kk_sqlite3_open"

pub fun open-db( path : path ) : <fsys,exn> db
    Db(sqlite3-open(path.string).untry)

// If the filename is ":memory:", then a private, temporary in-memory database
// is created for the connection. This in-memory database will vanish when the
// database connection is closed. Future versions of SQLite might make use of
// additional special filenames that begin with the ":" character. It is
// recommended that when a database filename actually does begin with a ":"
// character you should prefix the filename with a pathname such as "./" to
// avoid ambiguity.
pub fun open-in-memory-db() : <fsys,exn> db
    Db(sqlite3-open(":memory:").untry)

// If the filename is an empty string, then a private, temporary on-disk
// database will be created. This private database will be automatically deleted
// as soon as the database connection is closed.
pub fun open-temporary-on-disk-db() : <fsys,exn> db
    Db(sqlite3-open("").untry)

// * close
// https://www.sqlite.org/c3ref/close.html

extern sqlite3-close( ^db : any ) : fsys ()
    c "kk_sqlite3_close"

pub fun close-db( db : db ) : fsys ()
    sqlite3-close(db.obj)

// * prepare
// https://www.sqlite.org/c3ref/prepare.html

extern sqlite3-prepare( ^db : any, ^sql : string ) : fsys error<any>
    c "kk_sqlite3_prepare"

pub fun prepare( db : db, sql : string ) : <fsys,exn> stmt
    Stmt(db.obj.sqlite3-prepare(sql).untry)
