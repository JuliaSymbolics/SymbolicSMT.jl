# Basics

This section covers the fundamental concepts and usage patterns in SymbolicSMT.jl.

## Overview

SymbolicSMT.jl bridges the gap between symbolic computation and satisfiability solving. It allows you to:

- Define symbolic constraints on real, integer, and boolean variables
- Check if logical expressions are satisfiable under those constraints  
- Prove or disprove symbolic statements
- Simplify expressions using constraint-based reasoning

## The SymbolicSMT Workflow

The typical workflow involves three main steps:

1. **Create symbolic variables** using Symbolics.jl or SymbolicUtils.jl
2. **Define constraints** that bound the problem domain
3. **Query satisfiability or provability** of expressions

```julia
using Symbolics, SymbolicSMT

# Step 1: Create variables
@variables x::Real y::Real

# Step 2: Define constraints
constraints = Constraints([x >= 0, y >= 0, x + y <= 10])

# Step 3: Query the system
issatisfiable(x + y > 5, constraints)  # true
isprovable(x >= 0, constraints)        # true
```

## Types of Variables

SymbolicSMT.jl supports different types of symbolic variables:

### Real Variables

Real variables represent continuous numeric values:

```julia
@variables x::Real y::Real temperature::Real
```

These can be used in arithmetic expressions and inequality constraints.

### Integer Variables  

Integer variables represent discrete numeric values:

```julia
@variables n::Integer count::Integer age::Integer
```

Integer variables support the same operations as real variables but are constrained to integer solutions.

### Boolean Variables

Boolean variables represent logical values:

```julia
@variables p::Bool flag::Bool condition::Bool
```

Boolean variables are useful for encoding logical relationships and conditional constraints.

## Supported Operations

### Arithmetic Operations

- **Addition**: `x + y`, `x + 5`
- **Subtraction**: `x - y`, `x - 3`  
- **Multiplication**: `x * y`, `2 * x`
- **Powers**: `x^2`, `x^n`
- **Unary minus**: `-x`

### Comparison Operations

- **Equal**: `x == y`
- **Greater than**: `x > y`
- **Greater than or equal**: `x >= y`  
- **Less than**: `x < y`
- **Less than or equal**: `x <= y`

### Logical Operations

- **AND**: `p & q`
- **OR**: `p | q`
- **NOT**: `!p`

## Type System Integration

SymbolicSMT.jl handles the conversion between Symbolics/SymbolicUtils types and Z3 types:

### Supported Type Mappings

- `Real` ’ Z3 Int (current implementation treats reals as integers)
- `Integer` ’ Z3 Int
- `Bool` ’ Z3 Bool

### Automatic Conversion

The conversion happens automatically when creating constraints:

```julia
@variables x::Real p::Bool
constraints = Constraints([x > 0, p])  # Automatic type conversion
```

## Frontend Interfaces

### Symbolics.jl Interface (Recommended)

The modern, user-friendly interface using `@variables`:

```julia
using Symbolics, SymbolicSMT

@variables x::Real y::Real
constraints = Constraints([x > 0, y > 0])
issatisfiable(x + y > 1, constraints)
```

### SymbolicUtils.jl Interface

The lower-level interface for advanced users:

```julia
using SymbolicUtils, SymbolicSMT

@syms x::Real y::Real
constraints = Constraints([x > 0, y > 0])  
issatisfiable(x + y > 1, constraints)
```

Both interfaces can be mixed in the same code.

## Performance Considerations

### Solver Complexity

Different constraint types have different computational complexity:

- **Linear arithmetic**: Generally efficient
- **Nonlinear arithmetic**: More expensive
- **Boolean satisfiability**: Depends on structure
- **Mixed integer**: Can be challenging

### Best Practices

1. **Keep constraints simple** when possible
2. **Use appropriate variable types** (prefer `Real` over `Integer` when exact integers aren't required)
3. **Batch constraint creation** rather than creating many small constraint sets
4. **Structure boolean expressions** to be as simple as possible

## Error Handling

SymbolicSMT.jl provides informative error messages when expressions cannot be converted:

```julia
# This will show what failed to convert if there are unsupported operations
try
    constraints = Constraints([some_unsupported_expr])
catch e
    println(e)  # Detailed error message
end
```

## Understanding Results

### Satisfiability Results

`issatisfiable` returns:

- `true`: There exists at least one solution
- `false`: No solution exists  
- `nothing`: The solver cannot determine (rare)

### Provability Results

`isprovable` returns:

- `true`: The statement is always true under the constraints
- `false`: The statement can be false under the constraints

### Resolution Results

`resolve` returns:

- `true`: The expression is provably true
- `false`: The expression is provably false
- Original expression (as `Num` or `Symbolic`): Cannot be determined