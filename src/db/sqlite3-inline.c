
#include <sqlite3.h>

static kk_std_core__error kk_sqlite3_open( kk_string_t filename, kk_context_t* ctx ) {
  const char *cfilename = kk_string_char_borrow(filename, NULL);
  sqlite3 *conn = NULL;
  int result;
  result = sqlite3_open(cfilename, &conn);
  if (result == SQLITE_OK) {
    return kk_error_ok(kk_cptr_raw_box(&kk_sqlite3_free, conn, ctx), ctx);
  } else {
    kk_string_t msg;
    // A database connection handle is usually returned in *ppDb, even if an
    // error occurs. The only exception is that if SQLite is unable to allocate
    // memory to hold the sqlite3 object, a NULL will be written into *ppDb
    // instead of a pointer to the sqlite3 object.
    if (conn != NULL) {
      msg = kk_string_alloc_from_qutf8(sqlite3_errstr(result), ctx);
      sqlite3_close(conn);
    } else {
      msg = kk_string_alloc_from_qutf8("SQLite is unable to allocate memory to hold the sqlite3 object", ctx);
    }
    return kk_std_core__new_Error(kk_std_core__new_Exception(msg, kk_std_core__new_ExnError(ctx), ctx), ctx);
  }
}

static void kk_sqlite3_free( void* conn, kk_block_t* b, kk_context_t* ctx ) {
  sqlite3_close((sqlite3*)conn);
}
