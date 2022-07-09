module db/sqlite3

import std/os/path

extern import
  c { vcpkg = "sqlite3"; library = "sqlite3" }

extern import
  c file "sqlite3-inline.c"

alias io-sqlite3 = <fsys,ndet,div,exn>

abstract struct db
  ptr : intptr_t  // sqlite3*

abstract struct stmt
  ptr : intptr_t  // sqlite3_stmt*

// * open
// https://www.sqlite.org/c3ref/open.html

extern sqlite3-open(^filename: string): io-sqlite3 error<intptr_t>
  c "kk_sqlite3_open"

pub fun open(path: path): io-sqlite3 db
  Db(sqlite3-open(path.string).untry)

// If the filename is ":memory:", then a private, temporary in-memory database
// is created for the connection. This in-memory database will vanish when the
// database connection is closed. Future versions of SQLite might make use of
// additional special filenames that begin with the ":" character. It is
// recommended that when a database filename actually does begin with a ":"
// character you should prefix the filename with a pathname such as "./" to
// avoid ambiguity.
pub fun open-in-memory(): io-sqlite3 db
  Db(sqlite3-open(":memory:").untry)

// If the filename is an empty string, then a private, temporary on-disk
// database will be created. This private database will be automatically deleted
// as soon as the database connection is closed.
pub fun open-temporary-on-disk(): io-sqlite3 db
  Db(sqlite3-open("").untry)

// * close
// https://www.sqlite.org/c3ref/close.html

extern sqlite3-close(db: intptr_t): io-sqlite3 ()
  c "kk_sqlite3_close"

pub fun close(db: db): io-sqlite3 ()
  sqlite3-close(db.ptr)

// * Compiling An SQL Statement
// https://www.sqlite.org/c3ref/prepare.html

// ptr points inside str's cbuf.
// Need to keep reference of str to prevent it from being freed.
abstract value struct ssql
  str: string
  ptr: intptr_t

inline extern string-cbuf(^str: string): intptr_t
  c inline "(intptr_t)kk_string_cbuf_borrow(#1, NULL)"

// for debug.
inline extern string(ptr: intptr_t): string
  c inline "kk_string_alloc_from_utf8((const char*)(#1), kk_context())"

pub fun ssql(str: string): ssql
  Ssql(str, string-cbuf(str))

// for debug
pub fun show(ssql: ssql): string
  ssql.ptr.string

extern sqlite3-prepare-v2(db: intptr_t, ptr: intptr_t): io-sqlite3 error<(maybe<intptr_t>, maybe<intptr_t>)>
  c "kk_sqlite3_prepare_v2"

pub fun prepare-v2(db: db, ssql: ssql): io-sqlite3 (maybe<stmt>, maybe<ssql>)
  match db.ptr.sqlite3-prepare-v2(ssql.ptr).untry
    (stmt_, ssql_) ->
      ( stmt_.map(Stmt)
      , ssql_.map(fn(ptr_) ssql( ptr = ptr_ ))
      )

// * Binding Values To Prepared Statements
// https://www.sqlite.org/c3ref/bind_blob.html

extern sqlite3-bind-null(stmt: intptr_t, ^index: int): io-sqlite3 error<()>
  c "kk_sqlite3_bind_null"

extern sqlite3-bind-int64(stmt: intptr_t, ^index: int, value: int64): io-sqlite3 error<()>
  c "kk_sqlite3_bind_int64"

extern sqlite3-bind-text(stmt: intptr_t, ^index: int, ^value: string): io-sqlite3 error<()>
  c "kk_sqlite3_bind_text"

pub fun bind-null(stmt: stmt, index: int ): io-sqlite3 ()
  stmt.ptr.sqlite3-bind-null(index).untry

pub fun bind-int64(stmt: stmt, index: int, value: int64): io-sqlite3 ()
  stmt.ptr.sqlite3-bind-int64(index, value).untry

pub fun bind-text(stmt: stmt, index: int, value: string): io-sqlite3 ()
  stmt.ptr.sqlite3-bind-text(index, value).untry

// * Number Of Columns In A Result Set
// https://www.sqlite.org/c3ref/column_count.html

extern sqlite3-column-count(stmt :intptr_t): io-sqlite3 int64
  c "kk_sqlite3_column_count"

pub fun column-count(stmt: stmt): io-sqlite3 int
  stmt.ptr.sqlite3-column-count.int

// * Evaluate An SQL Statement
// https://www.sqlite.org/c3ref/step.html

pub value type step-result
  Busy
  Done
  Row

pub fun show(r: step-result): string
  match r
    Busy -> "Busy"
    Done -> "Done"
    Row -> "Row"

extern sqlite3-step(stmt : intptr_t): io-sqlite3 error<step-result>
  c "kk_sqlite3_step"

pub fun step(stmt: stmt): io-sqlite3 step-result
  stmt.ptr.sqlite3-step.untry

// * Result Values From A Query
// https://www.sqlite.org/c3ref/column_blob.html

extern sqlite3-column-int64(stmt: intptr_t, ^icol: int): io-sqlite3 int64
  c "kk_sqlite3_column_int64"

extern sqlite3-column-double(stmt: intptr_t, ^icol: int): io-sqlite3 float64
  c "kk_sqlite3_column_double"

extern sqlite3-column-text(stmt: intptr_t, ^icol: int): io-sqlite3 maybe<string>
  c "kk_sqlite3_column_text"

pub fun column-int64(stmt : stmt, icol: int): io-sqlite3 int64
  stmt.ptr.sqlite3-column-int64(icol)

pub fun column-double(stmt : stmt, icol: int): io-sqlite3 float64
  stmt.ptr.sqlite3-column-double(icol)

pub fun column-text(stmt: stmt, icol: int): io-sqlite3 maybe<string>
  stmt.ptr.sqlite3-column-text(icol)

// * finalizer
// https://www.sqlite.org/c3ref/finalize.html

extern sqlite3-finalize(stmt : intptr_t): io-sqlite3 error<()>
  c "kk_sqlite3_finalize"

pub fun finalize(stmt: stmt): io-sqlite3 ()
  stmt.ptr.sqlite3-finalize.untry
