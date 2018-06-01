yuni
----

R7RS/R6RS Scheme portability library

[![Build Status](https://travis-ci.org/okuoku/yuni.svg?branch=master)](https://travis-ci.org/okuoku/yuni)
[![Build status](https://ci.appveyor.com/api/projects/status/0mtb3ldlwk2qwvck/branch/master?svg=true)](https://ci.appveyor.com/project/okuoku/yuni/branch/master)

`yuni` is a collection of R6RS/R7RS compatible libraries. It's under development; still USELESS for most people.

## Libraries

 * `(yuni scheme)` - R7RS base library, also available on R6RS. See also: [r7b-Issues][]
 * `(yuni core)` - Basic structure and typing
 * `(yuni ffi *)` - Static binding FFI (under construction)

## Implementations

See also: [PortingNotes][] and [Blocker-Issues][]

Implementations with FFI compatibility layer:

 * [nmosh](https://github.com/okuoku/mosh)
 * [chibi-scheme](http://synthcode.com/wiki/chibi-scheme)
 * [Racket](https://racket-lang.org/) with `srfi-lib` and `r6rs-lib` packages
 * [Sagittarius](https://bitbucket.org/ktakashi/sagittarius-scheme/wiki/Home)
 * [Gauche](http://practical-scheme.net/gauche/) 0.9.5 or later
 * [Guile](http://www.gnu.org/software/guile/) 2.0 or later
 * [Vicare](http://marcomaggi.github.io/vicare.html)
 * [Chicken](http://www.call-cc.org/) interpreter with `r7rs` egg
 * [Larceny](http://larcenists.org/)
 * [Gambit](http://gambitscheme.org/) with experimental R5RS support(BSD3/GPL2+)
 * [ChezScheme](https://github.com/cisco/ChezScheme)
 * [Picrin](https://github.com/picrin-scheme/picrin) with yuniffi patch

Bootstrapped, but no FFI yet:

 * [IronScheme](https://github.com/leppie/IronScheme)
 * [Kawa](http://www.gnu.org/software/kawa/) 2.2 or later
 * [MIT/GNU Scheme](https://www.gnu.org/software/mit-scheme/) with experimental R5RS support(BSD3/GPL2+)

## Build

Install one of bootstrap Scheme and configure this directory with `cmake`. Following Scheme supported as bootstrap Scheme:

 * Chez scheme
 * chibi-scheme
 * Racket
 * Sagittarius
 * Gauche
 * IronScheme (`YUNI_IRON_SCHEME_ROOT`)

Implementations except IronScheme will be auto-detected by the build script.

See [Bootstrap][] for details.

## License

Public domain (CC0-1.0). Yuni R6RS/R7RS runtime component is released into public domain by the author. See `COPYING.CC0` for full license text.

Yuni R5RS support uses Alexpander(BSD3/GPL2+).

Yuni generic scheme support includes `syntax-rules` implementation from Chibi-scheme.

NOTE: Following directories contain copyrighted materials from other projects.

 * `apidata`
 * `external`
 * `integration`
 * `tests`

These directories are not part of Yuni runtime library.


[Blocker-Issues]: https://github.com/okuoku/yuni/issues?q=is%3Aissue+is%3Aopen+label%3AExtern-Blocker
[r7b-Issues]: https://github.com/okuoku/yuni/issues?q=is%3Aissue+is%3Aopen+label%3ALib-R7RSBridge
[PortingNotes]: https://github.com/okuoku/yuni/tree/master/doc/PortingNotes
[Bootstrap]: https://github.com/okuoku/yuni/tree/master/bootstrap
