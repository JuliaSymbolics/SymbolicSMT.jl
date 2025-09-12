# SymbolicSAT.jl

*Satisfiability solving for symbolic expressions*

SymbolicSAT.jl provides an interface between [SymbolicUtils.jl](https://github.com/JuliaSymbolics/SymbolicUtils.jl) and [Symbolics.jl](https://github.com/JuliaSymbolics/Symbolics.jl) symbolic expressions and the [Z3](https://github.com/Z3Prover/z3) satisfiability modulo theories (SMT) solver. This allows you to check satisfiability and provability of symbolic boolean expressions containing arithmetic constraints.

## Features

- **Symbolics.jl integration**: Work with `@variables` and `Num` types from Symbolics.jl
- **SymbolicUtils.jl support**: Direct compatibility with SymbolicUtils expressions
- **Z3 integration**: Leverage the power of Microsoft Research's Z3 solver  
- **Multiple theories**: Support for linear and nonlinear real arithmetic
- **Satisfiability checking**: Determine if constraints have solutions
- **Provability checking**: Verify if statements are always true under constraints

## Installation

```julia
using Pkg
Pkg.add("SymbolicSAT")
```

## Quick Example with Symbolics.jl

```julia
using Symbolics, SymbolicSAT

# Create symbolic variables with Symbolics.jl
@variables x::Real y::Real

# Define constraints: both variables are positive
constraints = Constraints([x > 0, y > 0])

# Check satisfiability: Can x + y be greater than 1?
issatisfiable(x + y > 1, constraints)  # true

# Check provability: Is x + y always positive?
isprovable(x + y > 0, constraints)     # true

# Check provability: Is x always greater than y?
isprovable(x > y, constraints)         # false

# Resolve expressions to constants when possible
resolve(x > 0, constraints)     # true (always true)
resolve(x > 10, constraints)    # x > 10 (cannot determine)
```

## Alternative: SymbolicUtils.jl Interface

SymbolicSAT.jl also supports the lower-level SymbolicUtils.jl interface:

```julia
using SymbolicUtils, SymbolicSAT

@syms x::Real y::Real
constraints = Constraints([x > 0, y > 0])
issatisfiable(x + y > 1, constraints)  # true
```

## Package Ecosystem

SymbolicSAT.jl is part of the [JuliaSymbolics](https://github.com/JuliaSymbolics) ecosystem and works seamlessly with:

- **[Symbolics.jl](https://github.com/JuliaSymbolics/Symbolics.jl)**: High-level symbolic computation and modeling
- **[SymbolicUtils.jl](https://github.com/JuliaSymbolics/SymbolicUtils.jl)**: Core symbolic expression manipulation
- **[ModelingToolkit.jl](https://github.com/SciML/ModelingToolkit.jl)**: Symbolic-numeric modeling

## Related Packages

- **[Z3.jl](https://github.com/ahumenberger/Z3.jl)**: Julia bindings for the Z3 theorem prover
- **[JuMP.jl](https://github.com/jump-dev/JuMP.jl)**: Mathematical optimization in Julia
- **[Satisfiability.jl](https://github.com/elsoroka/Satisfiability.jl)**: Alternative SAT/SMT interface

## Getting Help

- **Documentation**: Browse the manual and API reference in the sidebar
- **Examples**: Check out the tutorials for practical usage patterns
- **Issues**: Report bugs or request features on [GitHub](https://github.com/JuliaSymbolics/SymbolicSAT.jl/issues)
- **Discussions**: Join the community on the [Julia Discourse](https://discourse.julialang.org/)