# Symbolics.jl Interface

This page documents the Symbolics.jl frontend API for SymbolicSMT.jl, which provides a modern, user-friendly interface using `@variables` and `Num` types.

## Overview

The Symbolics.jl interface wraps the core SymbolicUtils.jl backend with convenient dispatch methods that automatically handle conversion between `Num` and `SymbolicUtils.Symbolic` types.

## Variable Creation

### `@variables` Macro

The `@variables` macro is re-exported from Symbolics.jl for convenience. It creates symbolic variables with specified types:

```julia
using SymbolicSMT  # @variables is available directly

@variables x::Real y::Real z::Integer p::Bool
```

## Constraint Construction

```@docs
Constraints(constraints::Vector{Num}, solvertype::String)
```

Create constraints from Symbolics.jl `Num` expressions:

```julia
@variables x::Real y::Real

# Create constraints with Symbolics.jl syntax
constraints = Constraints([x > 0, y >= 0, x + y < 10])
```

## Satisfiability Checking

```@docs
issatisfiable(expr::Num, constraints::Constraints)
```

Check if a `Num` expression can be satisfied:

```julia
@variables x::Real y::Real
constraints = Constraints([x > 0, y > 0])

issatisfiable(x < 0, constraints)        # false
issatisfiable(x + y > 1, constraints)    # true
```

## Provability Checking

```@docs
isprovable(expr::Num, constraints::Constraints)
```

Check if a `Num` expression is always true:

```julia
@variables x::Real y::Real
constraints = Constraints([x >= 0, y >= 0])

isprovable(x >= 0, constraints)     # true
isprovable(x > y, constraints)      # false
```

## Expression Resolution

```@docs
resolve(expr::Num, constraints::Constraints)
```

Resolve `Num` expressions to constants when possible:

```julia
@variables x::Real
constraints = Constraints([x > 5])

resolve(x > 0, constraints)    # true
resolve(x < 0, constraints)    # false  
resolve(x > 10, constraints)   # x > 10 (as Num)
```

## Type Handling

### Variable Types

The Symbolics.jl interface supports all standard variable types:

```julia
# Real numbers (continuous)
@variables position::Real velocity::Real

# Integers (discrete)  
@variables count::Integer index::Integer

# Booleans (logical)
@variables active::Bool valid::Bool
```

### Expression Types

All expression types are automatically handled:

#### Arithmetic Expressions
```julia
@variables x::Real y::Real

expr1 = x + y
expr2 = 2*x - 3*y  
expr3 = x^2 + y^2
expr4 = -x + 5
```

#### Comparison Expressions
```julia
comp1 = x > y
comp2 = x >= 0
comp3 = x == 5
comp4 = x <= 10
comp5 = x < y + 1
```

#### Boolean Expressions
```julia
@variables p::Bool q::Bool

bool1 = p & q
bool2 = p | q
bool3 = !p
bool4 = (p & q) | (!p & !q)
```

#### Mixed Expressions
```julia
@variables x::Real p::Bool

mixed1 = (x > 0) & p
mixed2 = p | (x < 5)
mixed3 = p => (x >= 0)
```

## Conversion Details

### Automatic Unwrapping

`Num` expressions are automatically unwrapped to `SymbolicUtils.BasicSymbolic`:

```julia
@variables x::Real
num_expr = x > 0                    # Symbolics.Num
symbolic_expr = unwrap(num_expr)    # SymbolicUtils.BasicSymbolic
```

!!! note "SymbolicUtils v4 Changes"
    In SymbolicUtils v4, `Symbolic` has been renamed to `BasicSymbolic`. The type parameter
    (e.g., `{Bool}`) is now always `SymReal` regardless of the actual symbolic type.
    Use `symtype(expr)` to get the semantic type (`Bool`, `Integer`, `Real`, etc.).

### Automatic Wrapping

Results are wrapped back to `Num` when appropriate:

```julia
result = resolve(x > 10, constraints)
# If cannot resolve: returns Num
# If resolves to bool: returns Bool
```

### Type Preservation

The interface preserves semantic meaning:

```julia
# Input: Num expression
# Processing: SymbolicUtils backend
# Output: Appropriate type (Bool for constants, Num for expressions)
```

## Usage Patterns

### Basic Workflow

```julia
using Symbolics, SymbolicSMT

# 1. Create variables
@variables x::Real y::Real

# 2. Define constraints  
constraints = Constraints([x >= 0, y >= 0])

# 3. Query system
result1 = issatisfiable(x + y > 5, constraints)  
result2 = isprovable(x >= 0, constraints)
result3 = resolve(x > 10, constraints)
```

### Advanced Usage

```julia
# Mixed variable types
@variables pos::Real vel::Real gear::Integer active::Bool

# Complex constraint set
constraints = Constraints([
    pos >= 0,                           # Real constraint
    vel >= 0, vel <= 120,              # Real bounds
    gear >= 1, gear <= 5,              # Integer constraint
    active,                             # Boolean constraint
    active => (vel > 0),               # Conditional constraint
    (gear > 3) => (vel > 50)          # Gear-speed relationship
])

# Complex queries
can_be_stationary = issatisfiable(vel == 0, constraints)
always_moving = isprovable(vel > 0, constraints)  
high_gear_fast = isprovable((gear > 3) => (vel > 50), constraints)
```

## Comparison with SymbolicUtils Interface

### Symbolics.jl Interface (Recommended)

```julia
using Symbolics, SymbolicSMT

@variables x::Real y::Real
constraints = Constraints([x > 0, y > 0])
result = issatisfiable(x + y > 1, constraints)
```

**Benefits:**
- Modern Julia ecosystem standard
- Clean `@variables` syntax
- Automatic type handling
- Better integration with other packages

### SymbolicUtils.jl Interface

```julia
using SymbolicUtils, SymbolicSMT

@syms x::Real y::Real  
constraints = Constraints([x > 0, y > 0])
result = issatisfiable(x + y > 1, constraints)
```

**When to use:**
- Advanced symbolic manipulation
- Custom symbolic operations
- Lower-level control
- Existing SymbolicUtils.jl codebase

### Mixed Usage

Both interfaces can be used together:

```julia
using Symbolics, SymbolicUtils, SymbolicSMT

# Mix Symbolics and SymbolicUtils variables
@variables x::Real          # Symbolics.Num
@syms y::Real              # SymbolicUtils.Symbolic

# Both work in the same constraint set
constraints = Constraints([x > 0, y > 0])
issatisfiable(x + y > 1, constraints)  # Works seamlessly
```

## Error Handling

The Symbolics.jl interface provides the same error handling as the SymbolicUtils backend:

### Conversion Errors

```julia
# If expressions cannot be converted to Z3
try
    constraints = Constraints([unsupported_expr])
catch e
    # Detailed error message about conversion failure
    println(e)
end
```

### Type Mismatches

```julia
# Type mismatches are caught during unwrapping
@variables x::Real

# This would cause an error if x is used in boolean context incorrectly
# The error message will indicate the type mismatch
```

## Performance Notes

### Zero Overhead Design

The Symbolics.jl interface adds minimal overhead:

- **Dispatch cost**: Single method lookup
- **Conversion cost**: Simple unwrap/wrap operations  
- **Backend unchanged**: Same optimized SymbolicUtils processing

### Memory Usage

- **Shared backend**: No duplication of solver state
- **Minimal wrappers**: `Num` types are lightweight wrappers
- **Efficient conversion**: Direct delegation without copying

### Recommendations

For best performance:
1. **Batch constraint creation** rather than creating many small sets
2. **Use appropriate variable types** for your problem domain
3. **Prefer the Symbolics interface** for new code (better ecosystem integration)
4. **Mix interfaces judiciously** - conversion has minimal but non-zero cost