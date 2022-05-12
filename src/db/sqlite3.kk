module db/sqlite3

extern import
    c { vcpkg = "sqlite3" }

extern import
    c file "sqlite3-inline.c"
