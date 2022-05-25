module db/sqlite3

import std/os/path

extern import
    c { vcpkg = "sqlite3"; library = "sqlite3" }

extern import
    c file "sqlite3-inline.c"

abstract struct db
    ptr : intptr_t  // sqlite3*

abstract struct stmt
    ptr : intptr_t  // sqlite3_stmt*

// * open
// https://www.sqlite.org/c3ref/open.html

extern sqlite3-open( ^filename : string ) : fsys error<intptr_t>
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

extern sqlite3-close( db : intptr_t ) : fsys ()
    c "kk_sqlite3_close"

pub fun close( db : db ) : fsys ()
    sqlite3-close(db.ptr)

// * Compiling An SQL Statement
// https://www.sqlite.org/c3ref/prepare.html

abstract value struct ssql
    str : string
    ptr : intptr_t

inline extern string-cbuf( ^str : string ) : intptr_t
    c inline "(intptr_t)kk_string_cbuf_borrow(#1, NULL)"

pub fun ssql( str : string ) : ssql
    Ssql(str, string-cbuf(str))

extern sqlite3-prepare-v2( db : intptr_t, ptr : intptr_t ) : fsys error<(intptr_t, maybe<intptr_t>)>
    c "kk_sqlite3_prepare_v2"

pub fun prepare-v2( db : db, ssql : ssql ) : <fsys,exn> (stmt, maybe<ssql>)
    match db.ptr.sqlite3-prepare-v2(ssql.ptr).untry
        (stmt_, ssql_) ->
            ( Stmt(stmt_)
            , ssql_.map(fn(ptr_) { ssql( ptr = ptr_ ) })
            )

// * Binding Values To Prepared Statements
// https://www.sqlite.org/c3ref/bind_blob.html

extern sqlite3-bind-null( stmt : intptr_t, ^index : int ) : fsys error<()>
    c "kk_sqlite3_bind_null"

pub fun bind-null( stmt : stmt, index : int ) : <fsys,exn> ()
    stmt.ptr.sqlite3-bind-null(index).untry

extern sqlite3-bind-int64( stmt : intptr_t, ^index : int, value : int64 ) : fsys error<()>
    c "kk_sqlite3_bind_int64"

pub fun bind-int64( stmt : stmt, index : int, value : int64 ) : <fsys,exn> ()
    stmt.ptr.sqlite3-bind-int64(index, value).untry

extern sqlite3-bind-text( stmt : intptr_t, ^index : int, ^value : string ) : fsys error<()>
    c "kk_sqlite3_bind_text"

pub fun bind-text( stmt : stmt, index : int, value : string ) : <fsys,exn> ()
    stmt.ptr.sqlite3-bind-text(index, value).untry

// * Number Of Columns In A Result Set
// https://www.sqlite.org/c3ref/column_count.html

extern sqlite3-column-count( stmt : intptr_t ) : fsys int64
    c "kk_sqlite3_column_count"

pub fun column-count( stmt : stmt ) : fsys int
    stmt.ptr.sqlite3-column-count.int

// * Evaluate An SQL Statement
// https://www.sqlite.org/c3ref/step.html

pub value type step-result
    Busy
    Done
    Row

extern sqlite3-step( stmt : intptr_t ) : fsys error<step-result>
    c "kk_sqlite3_step"

pub fun step( stmt : stmt ) : <fsys,exn> step-result
    stmt.ptr.sqlite3-step.untry

// * Result Values From A Query
// https://www.sqlite.org/c3ref/column_blob.html

extern sqlite3-column-int64( stmt : intptr_t, ^icol : int ) : fsys int64
    c "kk_sqlite3_column_int64"

pub fun column-int64( stmt : stmt, icol : int ) : fsys int64
    stmt.ptr.sqlite3-column-int64(icol)

extern sqlite3-column-double( stmt : intptr_t, ^icol : int ) : fsys float64
    c "kk_sqlite3_column_double"

pub fun column-double( stmt : stmt, icol : int ) : fsys float64
    stmt.ptr.sqlite3-column-double(icol)

extern sqlite3-column-text( stmt : intptr_t, ^icol : int ) : fsys maybe<string>
    c "kk_sqlite3_column_text"

pub fun column-text( stmt : stmt, icol : int ) : fsys maybe<string>
    stmt.ptr.sqlite3-column-text(icol)

// * finalizer
// https://www.sqlite.org/c3ref/finalize.html

extern sqlite3-finalize( stmt : intptr_t ) : fsys error<()>
    c "kk_sqlite3_finalize"

pub fun finalize( stmt : stmt ) : <fsys,exn> ()
    stmt.ptr.sqlite3-finalize.untry
