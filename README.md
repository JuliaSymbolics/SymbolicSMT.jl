# SymbolicSMT.jl

[![CI](https://github.com/JuliaSymbolics/SymbolicSMT.jl/workflows/CI/badge.svg)](https://github.com/JuliaSymbolics/SymbolicSMT.jl/actions/workflows/ci.yml)
[![codecov](https://codecov.io/gh/JuliaSymbolics/SymbolicSMT.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/JuliaSymbolics/SymbolicSMT.jl)

**Symbolic SMT solving for Julia**

SymbolicSMT.jl provides a high-level interface for symbolic constraint solving and theorem proving. Built on [Z3](https://github.com/Z3Prover/z3) and integrated with [Symbolics.jl](https://github.com/JuliaSymbolics/Symbolics.jl), it enables you to solve complex mathematical problems involving real numbers, integers, and boolean logic.

## Installation

```julia
using Pkg
Pkg.add("SymbolicSMT")
```

## Quick Start

```julia
using Symbolics, SymbolicSMT

# Create symbolic variables
@variables x::Real y::Real

# Define constraints
constraints = Constraints([x > 0, y > 0, x^2 + y^2 <= 1])

# Check satisfiability: Can x be greater than 1?
issatisfiable(x > 1, constraints)  # true

# Check provability: Is x always positive?
isprovable(x > 0, constraints)  # true

# Resolve expressions: Simplify when possible
resolve(x > 0, constraints)  # true (always satisfied)
resolve(x > 2, constraints)  # x > 2 (cannot determine from constraints)
```

## Key Features

- **🎯 High-level interface**: Work naturally with symbolic expressions
- **🔢 Multiple theories**: Real arithmetic, integer constraints, boolean logic
- **⚡ Powerful backend**: Leverages Microsoft's Z3 SMT solver
- **🔗 Ecosystem integration**: Seamless with Symbolics.jl and SymbolicUtils.jl
- **✅ Comprehensive**: Satisfiability, provability, and constraint-based simplification

## Use Cases

- **Optimization**: Verify feasibility and analyze constraint systems
- **Verification**: Prove mathematical properties and system invariants  
- **Planning**: Resource allocation and scheduling problems
- **Logic**: Propositional and first-order reasoning
- **Geometry**: Spatial relationships and geometric constraints

## Example: Geometric Reasoning

```julia
# Model points on a unit circle
@variables x₁::Real y₁::Real x₂::Real y₂::Real

circle_constraints = Constraints([
    x₁^2 + y₁^2 == 1,  # Point 1 on unit circle
    x₂^2 + y₂^2 == 1   # Point 2 on unit circle  
])

# Can two points be more than distance 2 apart?
issatisfiable((x₁ - x₂)^2 + (y₁ - y₂)^2 > 4, circle_constraints)  # true

# Is distance always bounded?
isprovable((x₁ - x₂)^2 + (y₁ - y₂)^2 <= 4, circle_constraints)  # false
```

## Documentation

For detailed usage, examples, and API reference, see the documentation:

- **[Stable Documentation](https://JuliaSymbolics.github.io/SymbolicSMT.jl/stable/)**
- **[Development Documentation](https://JuliaSymbolics.github.io/SymbolicSMT.jl/dev/)**

## Related Packages

SymbolicSMT.jl is part of the [JuliaSymbolics](https://github.com/JuliaSymbolics) ecosystem:

- **[Symbolics.jl](https://github.com/JuliaSymbolics/Symbolics.jl)**: Computer algebra system and symbolic computation
- **[SymbolicUtils.jl](https://github.com/JuliaSymbolics/SymbolicUtils.jl)**: Expression manipulation and simplification
- **[ModelingToolkit.jl](https://github.com/SciML/ModelingToolkit.jl)**: Symbolic modeling of mathematical systems

## Acknowledgments

Built with [Z3.jl](https://github.com/ahumenberger/Z3.jl) bindings to Microsoft's [Z3 Theorem Prover](https://github.com/Z3Prover/z3). Special thanks to the Z3.jl authors for providing excellent Julia bindings.
