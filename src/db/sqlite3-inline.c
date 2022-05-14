
#include <sqlite3.h>

// freeing must be done by the user
static void kk_sqlite3_free_do_nothing( void* p, kk_block_t* b, kk_context_t* ctx ) {
  kk_unused(p);
  kk_unused(b);
  kk_unused(ctx);
}

// * open
// https://www.sqlite.org/c3ref/open.html

static kk_std_core__error kk_sqlite3_open( kk_string_t filename, kk_context_t* ctx ) {
  const char *cfilename = kk_string_cbuf_borrow(filename, NULL);
  sqlite3 *db = NULL;
  int result;
  result = sqlite3_open(cfilename, &db);
  if (result == SQLITE_OK) {
    return kk_error_ok(kk_cptr_raw_box(&kk_sqlite3_free_do_nothing, db, ctx), ctx);
  } else {
    kk_string_t msg;
    // A database dbection handle is usually returned in *ppDb, even if an
    // error occurs. The only exception is that if SQLite is unable to allocate
    // memory to hold the sqlite3 object, a NULL will be written into *ppDb
    // instead of a pointer to the sqlite3 object.
    if (db != NULL) {
      msg = kk_string_alloc_from_qutf8(sqlite3_errstr(result), ctx);
      sqlite3_close(db);
    } else {
      msg = kk_string_alloc_from_qutf8("SQLite is unable to allocate memory to hold the sqlite3 object", ctx);
    }
    return kk_std_core__new_Error(kk_std_core__new_Exception(msg, kk_std_core__new_ExnError(ctx), ctx), ctx);
  }
}

// * close
// https://www.sqlite.org/c3ref/close.html
// TODO: error handling

//
// The sqlite3_close_v2() interface is intended for use with host languages that
// are garbage collected, and where the order in which destructors are called is
// arbitrary.

static kk_unit_t kk_sqlite3_close( kk_box_t db_, kk_context_t* ctx ) {
  sqlite3 *db = (sqlite3*)kk_cptr_raw_unbox(db_);
  sqlite3_close(db);
  return kk_Unit;
}

// * prepare
// https://www.sqlite.org/c3ref/prepare.html

static kk_std_core__error kk_sqlite3_prepare( kk_box_t db_, kk_string_t sql, kk_context_t* ctx ) {
  sqlite3_stmt *stmt = NULL;
  sqlite3 *db = (sqlite3*)kk_cptr_raw_unbox(db_);
  const char *zSql = kk_string_cbuf_borrow(sql, NULL);
  const char *pzTail = NULL;
  int result;
  // The preferred routine to use is sqlite3_prepare_v2(). The sqlite3_prepare()
  // interface is legacy and should be avoided.
  result = sqlite3_prepare_v2(db, zSql, -1, &stmt, &pzTail);
  if (result == SQLITE_OK) {
    kk_box_t stmt_box = kk_cptr_raw_box(&kk_sqlite3_free_do_nothing, stmt, ctx);
    return kk_error_ok(stmt_box, ctx);
  } else {
    kk_string_t msg;
    msg = kk_string_alloc_from_qutf8(sqlite3_errstr(result), ctx);
    return kk_std_core__new_Error(kk_std_core__new_Exception(msg, kk_std_core__new_ExnError(ctx), ctx), ctx);
  }
}

// The calling procedure is responsible for deleting the compiled SQL statement
// using sqlite3_finalize() after it has finished with it.
// https://www.sqlite.org/c3ref/finalize.html
