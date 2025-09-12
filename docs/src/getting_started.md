# Getting Started

This tutorial will walk you through the basics of using SymbolicSMT.jl to solve symbolic constraint problems.

## Installation and Setup

First, install the required packages:

```julia
using Pkg
Pkg.add(["SymbolicSMT", "Symbolics"])
```

Then load the packages:

```julia
using Symbolics, SymbolicSMT
```

## Creating Symbolic Variables with Symbolics.jl

SymbolicSMT.jl works seamlessly with Symbolics.jl `@variables` and `Num` types:

```julia
@variables x::Real y::Real z::Integer p::Bool
```

This creates symbolic variables: `x` and `y` as real numbers, `z` as an integer, and `p` as a boolean.

## Defining Constraints

Constraints are collections of boolean expressions that must be satisfied. Create constraints using the `Constraints` constructor:

```julia
# Simple constraints with Symbolics.jl variables
constraints = Constraints([
    x > 0,      # x must be positive
    y >= -2,    # y must be at least -2
    x + y < 10  # sum must be less than 10
])
```

## Checking Satisfiability

Use `issatisfiable` to check if an expression can be true given the constraints:

```julia
# Can x be greater than 5?
issatisfiable(x > 5, constraints)  # true - possible

# Can x be negative?
issatisfiable(x < 0, constraints)  # false - conflicts with x > 0

# Can x + y equal 15?
issatisfiable(x + y == 15, constraints)  # false - conflicts with x + y < 10
```

## Checking Provability

Use `isprovable` to check if an expression is always true given the constraints:

```julia
# Is x always positive?
isprovable(x > 0, constraints)     # true - follows from constraints

# Is x always greater than y?
isprovable(x > y, constraints)     # false - not necessarily true
```

## Expression Resolution

The `resolve` function attempts to simplify expressions to boolean constants:

```julia
@variables t::Real
time_constraints = Constraints([t >= 0, t <= 24])  # Time in hours

# These resolve to constants
resolve(t >= 0, time_constraints)   # true (always true)
resolve(t < 0, time_constraints)    # false (never true)

# This cannot be resolved (returns original Num expression)
resolve(t > 12, time_constraints)   # t > 12 (unchanged)
```

## Working with Different Variable Types

### Real Variables
```julia
@variables x::Real y::Real temperature::Real

constraints = Constraints([x >= 0, y >= 0, temperature > 273.15])
issatisfiable(x + y > temperature, constraints)
```

### Integer Variables  
```julia
@variables n::Integer count::Integer age::Integer

constraints = Constraints([n >= 1, count <= 100, age >= 0])
isprovable(n > 0, constraints)  # true
```

### Boolean Variables
```julia
@variables valid::Bool active::Bool

constraints = Constraints([valid, !active])  # valid is true, active is false
isprovable(valid | active, constraints)  # true
```

## Complex Expressions

SymbolicSMT.jl supports complex arithmetic and boolean expressions:

```julia
@variables a::Real b::Real

# Quadratic constraints
quadratic_constraints = Constraints([
    a^2 + b^2 <= 1,  # Inside unit circle
    a >= 0           # First quadrant
])

# Check complex expressions
issatisfiable(a * b > 0.1, quadratic_constraints)
isprovable(a >= 0, quadratic_constraints)  # true
```

## Return Values

Understanding the return values:

- **`true`**: The expression is satisfiable/provable
- **`false`**: The expression is unsatisfiable/not provable  
- **`nothing`**: The solver cannot determine the result (rare)

For `resolve`, boolean results are returned as `Bool`, while unresolved expressions are returned as `Num`.

## Alternative Interface: SymbolicUtils.jl

You can also use the lower-level SymbolicUtils.jl interface directly:

```julia
using SymbolicUtils, SymbolicSMT

@syms x::Real y::Real
constraints = Constraints([x > 0, y > 0])
issatisfiable(x + y > 1, constraints)
```

## Next Steps

- Read the [Manual](@ref) for deeper understanding of concepts
- Check out [Tutorials](@ref) for more complex examples
- Browse the [API Reference](@ref) for complete function documentation