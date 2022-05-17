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

pub fun open( path : path ) : <fsys,exn> db
    Db(sqlite3-open(path.string).untry)

// If the filename is ":memory:", then a private, temporary in-memory database
// is created for the connection. This in-memory database will vanish when the
// database connection is closed. Future versions of SQLite might make use of
// additional special filenames that begin with the ":" character. It is
// recommended that when a database filename actually does begin with a ":"
// character you should prefix the filename with a pathname such as "./" to
// avoid ambiguity.
pub fun open-in-memory() : <fsys,exn> db
    Db(sqlite3-open(":memory:").untry)

// If the filename is an empty string, then a private, temporary on-disk
// database will be created. This private database will be automatically deleted
// as soon as the database connection is closed.
pub fun open-temporary-on-disk() : <fsys,exn> db
    Db(sqlite3-open("").untry)

// * close
// https://www.sqlite.org/c3ref/close.html

extern sqlite3-close( ^db : any ) : fsys ()
    c "kk_sqlite3_close"

pub fun close( db : db ) : fsys ()
    sqlite3-close(db.obj)

// * prepare
// https://www.sqlite.org/c3ref/prepare.html

extern sqlite3-prepare-v2( ^db : any, ^sql : string ) : fsys error<any>
    c "kk_sqlite3_prepare_v2"

pub fun prepare-v2( db : db, sql : string ) : <fsys,exn> stmt
    Stmt(db.obj.sqlite3-prepare-v2(sql).untry)

// * Binding Values To Prepared Statements
// https://www.sqlite.org/c3ref/bind_blob.html

// null
extern sqlite3-bind-null( ^stmt : any, ^index : int ) : fsys error<()>
    c "kk_sqlite3_bind_null"

pub fun bind-null( stmt : stmt, index : int ) : <fsys,exn> ()
    stmt.obj.sqlite3-bind-null(index).untry

// int64
extern sqlite3-bind-int64( ^stmt : any, ^index : int, value : int64 ) : fsys error<()>
    c "kk_sqlite3_bind_int64"

pub fun bind-int64( stmt : stmt, index : int, value : int64 ) : <fsys,exn> ()
    stmt.obj.sqlite3-bind-int64(index, value).untry

// text
extern sqlite3-bind-text( ^stmt : any, ^index : int, ^value : string ) : fsys error<()>
    c "kk_sqlite3_bind_text"

pub fun bind-text( stmt : stmt, index : int, value : string ) : <fsys,exn> ()
    stmt.obj.sqlite3-bind-text(index, value).untry

// * Number Of Columns In A Result Set
// https://www.sqlite.org/c3ref/column_count.html

extern sqlite3-column-count( ^stmt : any ) : fsys int64
    c "kk_sqlite3_column_count"

pub fun column-count( stmt : stmt ) : fsys int
    stmt.obj.sqlite3-column-count.int

// * Evaluate An SQL Statement
// https://www.sqlite.org/c3ref/step.html

pub value type step-result
    Busy
    Done
    Row

extern sqlite3-step( ^stmt : any ) : fsys error<step-result>
    c "kk_sqlite3_step"

pub fun step( stmt : stmt ) : <fsys,exn> step-result
    stmt.obj.sqlite3-step.untry

// * finalizer
// https://www.sqlite.org/c3ref/finalize.html

extern sqlite3-finalize( ^stmt : any ) : fsys error<()>
    c "kk_sqlite3_finalize"

pub fun finalize( stmt : stmt ) : <fsys,exn> ()
    stmt.obj.sqlite3-finalize.untry
