# Constraints

This section explains how to create and work with constraints in SymbolicSMT.jl.

## What are Constraints?

Constraints are boolean expressions that define the valid domain for your variables. They represent the conditions that must be satisfied in any solution to your problem.

```julia
using Symbolics, SymbolicSMT

@variables x::Real y::Real

# These are constraints:
x > 0           # x must be positive
y >= -2         # y must be at least -2  
x + y < 10      # sum must be less than 10
x^2 + y^2 <= 1  # point must be inside unit circle
```

## Creating Constraint Sets

Use the `Constraints` constructor to create a collection of constraints:

```julia
# Single constraint
constraints1 = Constraints([x > 0])

# Multiple constraints (all must be satisfied)
constraints2 = Constraints([
    x > 0,
    y >= 0, 
    x + y <= 10,
    x - y >= -5
])
```

## Types of Constraints

### Linear Constraints

Linear constraints involve variables with power 1:

```julia
@variables x::Real y::Real z::Real

linear_constraints = Constraints([
    x + 2*y - 3*z <= 5,
    x - y >= 0,
    2*x + y == 7
])
```

### Quadratic Constraints

Quadratic constraints involve squared terms:

```julia
quadratic_constraints = Constraints([
    x^2 + y^2 <= 1,    # Circle constraint
    x^2 - y >= 0,      # Parabola constraint
    (x - 1)^2 + (y - 2)^2 <= 4  # Circle centered at (1,2)
])
```

### Boolean Constraints

Boolean constraints involve logical variables and operations:

```julia
@variables p::Bool q::Bool r::Bool

boolean_constraints = Constraints([
    p,              # p must be true
    !q | r,         # either q is false or r is true
    p & (q | !r)    # p and (q or not r)
])
```

### Mixed Constraints

Combine different types of variables and constraints:

```julia
@variables x::Real n::Integer valid::Bool

mixed_constraints = Constraints([
    x >= 0,                    # Real constraint
    n >= 1,                    # Integer constraint
    valid | (x < n),           # Boolean + mixed constraint
    x^2 + n <= 10              # Nonlinear mixed constraint
])
```

## Constraint Evaluation

### Empty Constraint Sets

Empty constraint sets are always satisfiable:

```julia
empty_constraints = Constraints([])
issatisfiable(x > 100, empty_constraints)  # true - no restrictions
```

### Contradictory Constraints

Some constraint sets have no solutions:

```julia
impossible = Constraints([x > 5, x < 3])
issatisfiable(true, impossible)  # false - constraint set is unsatisfiable
```

### Redundant Constraints

Some constraints may be implied by others:

```julia
# The second constraint is redundant
redundant = Constraints([x > 5, x > 3])  # x > 3 is implied by x > 5
```

## Working with Constraint Objects

### Inspecting Constraints

You can examine the constraints in a `Constraints` object:

```julia
cs = Constraints([x > 0, y <= 5])
println(cs)  # Shows: Constraints: x > 0 ' y <= 5

# Access the constraint expressions
cs.constraints  # Vector of original expressions
```

### Constraint Context

Each `Constraints` object maintains its own Z3 solver context:

```julia
cs = Constraints([x > 0])
# cs.solver contains the Z3 solver
# cs.context contains the Z3 context
```

## Advanced Constraint Patterns

### Conditional Constraints

Use boolean variables to create conditional constraints:

```julia
@variables x::Real active::Bool

conditional = Constraints([
    active => (x > 0),  # If active, then x > 0
    !active => (x <= 0) # If not active, then x <= 0
])
```

### Range Constraints

Define variables within specific ranges:

```julia
@variables angle::Real

# Angle between 0 and 2À
angle_constraints = Constraints([
    angle >= 0,
    angle <= 2*À
])
```

### Geometric Constraints

Model geometric relationships:

```julia
@variables x1::Real y1::Real x2::Real y2::Real

# Two points on the unit circle
unit_circle = Constraints([
    x1^2 + y1^2 == 1,
    x2^2 + y2^2 == 1
])

# Distance constraint
distance_constraint = Constraints([
    (x1 - x2)^2 + (y1 - y2)^2 <= 1  # Points within distance 1
])
```

## Tips for Effective Constraint Design

### 1. Start Simple

Begin with simple constraints and add complexity gradually:

```julia
# Start with basic bounds
basic = Constraints([x >= 0, y >= 0])

# Add more specific constraints
refined = Constraints([x >= 0, y >= 0, x + y <= 10, x - y >= -2])
```

### 2. Use Appropriate Types

Choose variable types that match your problem:

```julia
# For continuous optimization
@variables position::Real velocity::Real

# For counting problems  
@variables count::Integer items::Integer

# For logical conditions
@variables enabled::Bool valid::Bool
```

### 3. Structure Boolean Logic

Make boolean expressions as simple as possible:

```julia
# Prefer simple forms
simple = Constraints([p, !q])

# Over complex nested expressions
complex = Constraints([((p & q) | (!p & !q)) & (p | q)])
```

### 4. Check Constraint Satisfiability

Always verify your constraint set has solutions:

```julia
cs = Constraints([x > 5, x < 3])  # Oops! No solutions
issatisfiable(true, cs)  # false - indicates problem with constraints
```

## Common Patterns

### Optimization Bounds

```julia
@variables x::Real y::Real

bounds = Constraints([
    x >= -10, x <= 10,
    y >= -10, y <= 10
])
```

### Non-negativity  

```julia
non_negative = Constraints([x >= 0, y >= 0, z >= 0])
```

### Normalization

```julia
# Unit vector constraint
unit_vector = Constraints([x^2 + y^2 + z^2 == 1])
```

### Mutual Exclusion

```julia
@variables option1::Bool option2::Bool option3::Bool

# Exactly one option must be true
exactly_one = Constraints([
    option1 | option2 | option3,           # At least one
    !(option1 & option2),                  # Not both 1 and 2
    !(option1 & option3),                  # Not both 1 and 3
    !(option2 & option3)                   # Not both 2 and 3
])
```