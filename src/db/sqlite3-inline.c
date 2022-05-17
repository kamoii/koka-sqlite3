
#include <sqlite3.h>

// utility.
// kklib/integer.h doesn't offer kk_integer_t -> int clamp function.
static inline int kk_integer_clamp_int(kk_integer_t x, kk_context_t* ctx) {
#if INT_MAX == INT64_MAX
  return (int)kk_integer_clamp64(x,ctx);
#elif INT_MAX == INT32_MAX
  return (int)kk_integer_clamp32(x,ctx);
#elif INT_MAX == INT16_MAX
  return (int)kk_integer_clamp16(x,ctx);
#else
#error "can't decide platforms int size"
#endif
}

// freeing must be done by the user
static void kk_sqlite3_free_do_nothing( void* p, kk_block_t* b, kk_context_t* ctx ) {
  kk_unused(p);
  kk_unused(b);
  kk_unused(ctx);
}

static inline kk_std_core__error kk_sqlite3_read_error( int error_code, kk_context_t* ctx ) {
  return kk_std_core__new_Error(kk_std_core__new_Exception(kk_string_alloc_from_qutf8(sqlite3_errstr(error_code), ctx), kk_std_core__new_ExnError(ctx), ctx), ctx);
}

static inline kk_std_core__error kk_sqlite3_unit_result( int result, kk_context_t* ctx ) {
  if (result == SQLITE_OK) {
    return kk_error_ok(kk_unit_box(kk_Unit), ctx);
  } else {
    return kk_sqlite3_read_error(result, ctx);
  }
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

// TODO: check for leftover(pzTail)
static kk_std_core__error kk_sqlite3_prepare_v2( kk_box_t db_, kk_string_t sql, kk_context_t* ctx ) {
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
    return kk_sqlite3_read_error(result, ctx);
  }
}

// * Binding Values To Prepared Statements
// https://www.sqlite.org/c3ref/bind_blob.html

static kk_std_core__error kk_sqlite3_bind_null( kk_box_t stmt_, kk_integer_t index_, kk_context_t* ctx ) {
  sqlite3_stmt *stmt = (sqlite3_stmt*)kk_cptr_raw_unbox(stmt_);
  int index = kk_integer_clamp_int(index_, ctx);
  return kk_sqlite3_unit_result(sqlite3_bind_null(stmt, index),ctx);
}

static kk_std_core__error kk_sqlite3_bind_int64( kk_box_t stmt_, kk_integer_t index_, int64_t value, kk_context_t* ctx ) {
  sqlite3_stmt *stmt = (sqlite3_stmt*)kk_cptr_raw_unbox(stmt_);
  int index = kk_integer_clamp_int(index_, ctx);
  return kk_sqlite3_unit_result(sqlite3_bind_int64(stmt, index, (sqlite3_int64)value), ctx);
}

static kk_std_core__error kk_sqlite3_bind_text( kk_box_t stmt_, kk_integer_t index_, kk_string_t value_, kk_context_t* ctx ) {
  sqlite3_stmt *stmt = (sqlite3_stmt*)kk_cptr_raw_unbox(stmt_);
  int index = kk_integer_clamp_int(index_, ctx);
  kk_ssize_t len;
  const char *value = kk_string_cbuf_borrow(value_, &len);
  // QUESTION: Is (int)len safe ? Don't know about kk_ssize_t
  // TODO: SQLITE_TRANSIENT means we copy string content every time.
  return kk_sqlite3_unit_result(sqlite3_bind_text(stmt, index, value, (int)len, SQLITE_TRANSIENT), ctx);
}

// * Evaluate An SQL Statement
// https://www.sqlite.org/c3ref/step.html

static kk_std_core__error kk_sqlite3_step( kk_box_t stmt_, kk_context_t* ctx ) {
  sqlite3_stmt *stmt = (sqlite3_stmt*)kk_cptr_raw_unbox(stmt_);
  int result;
  result = sqlite3_step(stmt);
  if (result == SQLITE_ROW) {
    return kk_error_ok(kk_db_sqlite3__step_result_box(kk_db_sqlite3__new_Row(ctx), ctx), ctx);
  } else if (result == SQLITE_DONE) {
    return kk_error_ok(kk_db_sqlite3__step_result_box(kk_db_sqlite3__new_Done(ctx), ctx), ctx);
  } else if (result == SQLITE_BUSY) {
    return kk_error_ok(kk_db_sqlite3__step_result_box(kk_db_sqlite3__new_Busy(ctx), ctx), ctx);
  } else {
    return kk_sqlite3_read_error(result, ctx);
  }
}

// * finalizer
// https://www.sqlite.org/c3ref/finalize.html

static kk_std_core__error kk_sqlite3_finalize( kk_box_t stmt_, kk_context_t* ctx ) {
  sqlite3_stmt *stmt = (sqlite3_stmt*)kk_cptr_raw_unbox(stmt_);
  return kk_sqlite3_unit_result(sqlite3_finalize(stmt), ctx);
}
