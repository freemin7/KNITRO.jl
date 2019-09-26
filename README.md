KNITRO.jl
=========
[![](https://img.shields.io/badge/docs-latest-blue.svg)](https://juliaopt.github.io/KNITRO.jl/latest)

KNITRO.jl provides an interface for using the [Artelys Knitro
solver](https://www.artelys.com/knitro) from
[Julia](http://julialang.org/). You cannot use KNITRO.jl without having
purchased and installed Knitro from [Artelys](https://www.artelys.com/knitro).
This package is available free of charge and in no way replaces or alters any
functionality of Artelys Knitro solver.

Documentation is available at
[https://juliaopt.github.io/KNITRO.jl/latest](https://juliaopt.github.io/KNITRO.jl/latest).
Refer to [Knitro documentation](https://www.artelys.com/tools/knitro_doc/3_referenceManual/callableLibraryAPI.html)
for a full specification of the Knitro's API.

*The Artelys Knitro wrapper for Julia is supported by the JuliaOpt
community (which originates the development of this package) and
Artelys. Feel free to contact [Artelys support](mailto:support-knitro@artelys.com) if you encounter
any problem either with this interface or the solver.*


MathOptInterface wrapper
========================

**Note: MathOptInterface works only with the new Knitro's `KN` API which requires Knitro >= `v11.0`.**

KNITRO.jl now supports [MathOptInterface](https://github.com/JuliaOpt/MathOptInterface.jl)
and [JuMP 0.19](https://github.com/JuliaOpt/JuMP.jl).

```julia
using JuMP, KNITRO

model = with_optimizer(KNITRO.Optimizer, outlev=3)

```


Low-level wrapper
=================

KNITRO.jl implements most of Knitro's functionalities.
If you aim at using part of Knitro's API that are not implemented
in the MathOptInterface/JuMP ecosystem, you can refer to the low
level API which wraps directly the API of Knitro (whose templates
are specified in the file `knitro.h`).

Comprehensive examples using the C wrapper can be found in `examples/`.


Ampl wrapper
============

The package [AmplNLWriter.jl](https://github.com/JuliaOpt/AmplNLWriter.jl")
allows to to call `knitroampl` through Julia to solve JuMP's optimization
models.

The usage is as follow:

```julia
using JuMP, KNITRO, AmplNLWriter

model = with_optimizer(AmplNLWriter.Optimizer, KNITRO.amplexe, ["outlev=3"])

```

Note that supports is still experimental for JuMP 0.19.
