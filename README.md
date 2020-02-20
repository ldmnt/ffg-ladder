A tool to simulate the rank variation of a player in the french ladder after a go tournament. Enter your initial rank, your opponents and the results, and you get a report with the variation after each match.
There are two interfaces: a CLI and a simple android application.

This started out as an Ocaml exercise, then I wanted to make it usable through a minimalistic android application. This was achieved by compiling the Ocaml bytecode into javascript stubs with [js_of_ocaml](https://ocsigen.org/js_of_ocaml) and binding them to the java code of the mobile app.

## Building the project

You need an Ocaml compiler and a couple libraries that can be installed via [opam](https://opam.ocaml.org). First install the [base](https://github.com/janestreet/base) standard library and [dune](https://github.com/ocaml/dune) to be able to build the OCaml code:
```sh
opam install base dune
```

### Command line interface (unix)

For the command line executable, the following ocaml libraries are used:
- [cohttp](https://github.com/mirage/ocaml-cohttp) to fetch the ladder file from http://ffg.jeudego.org
- [lwt](https://github.com/ocsigen/lwt) as asynchronicity backend for cohttp
- [uutf](https://erratique.ch/logiciel/uutf) to decode the ladder file that is encoded in latin-1
- [stdio](https://github.com/janestreet/stdio) to print the results

```sh
opam install lwt cohttp cohttp-lwt-unix uutf stdio
```

Then build the executable:

```sh
make cli
```

It can be found at `ocaml/_build/default/bin/ffg_ladder.exe`.

### Android interface

To build the mobile app, you need the [android SDK](https://developer.android.com/studio) and [gradle](https://gradle.org/). Once you have a working installation, install [js_of_ocaml](https://ocsigen.org/js_of_ocaml) which is needed to generate the OCaml to javascript binding:
```sh
opam install js_of_ocaml js_of_ocaml-ppx
```

Then you can obtain a debug APK by running:

```sh
make android
```

The APK is created at `android/app/build/outputs/apk/debug/app-debug.apk`