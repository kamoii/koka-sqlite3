# koka-sqlite3

🚧 WIP 🚧

[sqlite3](https://www.sqlite.org/index.html) binding for [koka](https://koka-lang.github.io/koka/doc/index.html).

## Building

Needs sqlite3 static library to build.
In this project, we use [vcpkg](https://vcpkg.io/en/index.html)(C/C++ package manager) to install C dependencies.
Execute following command once before running tests or building.
It will install sqlite3 package in-project under `./vcpkg` directory.

    make vcpkg.init
    make vcpkg.install

## Test

Run test by:

    make test
