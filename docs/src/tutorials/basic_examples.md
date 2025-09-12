# Basic Examples

This tutorial provides practical examples of using SymbolicSMT.jl for various types of problems.

## Example 1: Planning and Scheduling

Let's solve a simple resource allocation problem:

```julia
using Symbolics, SymbolicSMT

# Define variables: time allocated to each task (in hours)
@variables task1::Real task2::Real task3::Real

# Constraints: budget and minimum requirements
constraints = Constraints([
    task1 >= 2,           # Task 1 needs at least 2 hours
    task2 >= 1,           # Task 2 needs at least 1 hour  
    task3 >= 3,           # Task 3 needs at least 3 hours
    task1 + task2 + task3 <= 10  # Total budget is 10 hours
])

# Questions we can ask:
issatisfiable(task1 + task2 + task3 == 10, constraints)  # true - can use full budget
issatisfiable(task1 > 5, constraints)                    # true - task1 can be > 5
issatisfiable(task1 > 6, constraints)                    # false - would exceed budget
```

## Example 2: Geometric Reasoning

Solve problems involving geometric shapes and relationships:

```julia
@variables x::Real y::Real

# Point inside unit circle
inside_circle = Constraints([x^2 + y^2 <= 1])

# Point in first quadrant
first_quadrant = Constraints([x >= 0, y >= 0])

# Combined constraints
constraints = Constraints([x^2 + y^2 <= 1, x >= 0, y >= 0])

# Geometric questions:
issatisfiable(x > 0.5 & y > 0.5, constraints)           # Check if corner point exists
isprovable(x >= 0, constraints)                         # true - always in first quadrant  
issatisfiable(x^2 + y^2 > 0.9, constraints)            # true - can be near boundary
```

## Example 3: Logic Puzzles

Solve propositional logic problems:

```julia
@variables alice_tall::Bool bob_tall::Bool charlie_tall::Bool

# Logic puzzle constraints:
# 1. At least one person is tall
# 2. If Alice is tall, then Bob is not tall
# 3. Charlie is tall if and only if exactly one of Alice/Bob is tall

puzzle_constraints = Constraints([
    alice_tall | bob_tall | charlie_tall,              # At least one tall
    !alice_tall | !bob_tall,                           # Alice tall ’ Bob not tall
    charlie_tall == ((alice_tall & !bob_tall) | (!alice_tall & bob_tall))  # Charlie iff exactly one
])

# Solution questions:
issatisfiable(alice_tall & !bob_tall & charlie_tall, puzzle_constraints)  # Check specific solution
isprovable(charlie_tall => (alice_tall | bob_tall), puzzle_constraints)   # Logical implication
```

## Example 4: System Configuration

Model system configuration constraints:

```julia
@variables memory::Integer cores::Integer storage::Integer

# System requirements
system_constraints = Constraints([
    memory >= 4,           # At least 4GB RAM
    cores >= 2,            # At least 2 CPU cores
    storage >= 100,        # At least 100GB storage
    memory * cores <= 32,  # Memory-core product limit
    storage <= 1000        # Storage upper limit
])

# Configuration questions:
issatisfiable(memory == 8 & cores == 4, system_constraints)      # Valid config?
isprovable(memory + cores >= 6, system_constraints)              # Always true?
issatisfiable(memory > 16 & cores > 4, system_constraints)       # High-end possible?
```

## Example 5: Financial Modeling

Model financial constraints and optimization:

```julia
@variables stocks::Real bonds::Real cash::Real

# Portfolio constraints
portfolio_constraints = Constraints([
    stocks >= 0, bonds >= 0, cash >= 0,    # No short selling
    stocks + bonds + cash == 100000,       # Total portfolio value
    stocks <= 60000,                       # Max 60% in stocks
    cash >= 10000                          # Minimum cash reserve
])

# Investment questions:
issatisfiable(stocks > 50000, portfolio_constraints)              # Can we have >50% stocks?
isprovable(bonds + cash >= 40000, portfolio_constraints)          # Always have 40%+ in bonds/cash?
resolve(cash >= 10000, portfolio_constraints)                     # true - always satisfied
```

## Example 6: Process Control

Model control system constraints:

```julia
@variables temperature::Real pressure::Real flow_rate::Real

# Safe operating constraints
safety_constraints = Constraints([
    temperature >= 20, temperature <= 80,     # Temperature range
    pressure >= 1, pressure <= 5,             # Pressure range  
    flow_rate >= 0, flow_rate <= 100,         # Flow rate range
    temperature * pressure <= 300,            # Safety interlock
    flow_rate <= 2 * pressure                 # Flow depends on pressure
])

# Safety verification:
isprovable(temperature <= 80, safety_constraints)                 # Always safe temp?
issatisfiable(pressure > 4 & flow_rate > 8, safety_constraints)  # High pressure/flow possible?
resolve(temperature > 60, safety_constraints)                     # Can we run hot?
```

## Example 7: Network Topology

Model network connectivity constraints:

```julia
@variables node1_active::Bool node2_active::Bool node3_active::Bool
@variables link12::Bool link13::Bool link23::Bool

# Network constraints
network_constraints = Constraints([
    # Links exist only if both nodes are active
    link12 => (node1_active & node2_active),
    link13 => (node1_active & node3_active), 
    link23 => (node2_active & node3_active),
    
    # At least one node must be active
    node1_active | node2_active | node3_active,
    
    # Network must be connected (at least one link if multiple nodes)
    (node1_active & node2_active) => link12,
    (node1_active & node3_active) => link13,
    (node2_active & node3_active) => link23
])

# Network analysis:
issatisfiable(node1_active & node2_active & !link12, network_constraints)  # false
isprovable(link12 => (node1_active & node2_active), network_constraints)   # true
```

## Example 8: Hybrid Systems

Combine continuous and discrete variables:

```julia
@variables position::Real velocity::Real
@variables gear::Integer braking::Bool

# Vehicle dynamics constraints
vehicle_constraints = Constraints([
    position >= 0,                    # Position bounds
    velocity >= 0, velocity <= 120,   # Speed limits
    gear >= 1, gear <= 5,            # Gear range
    
    # Gear-speed relationship
    (gear == 1) => (velocity <= 30),
    (gear == 2) => (velocity <= 50),
    (gear == 3) => (velocity <= 70),
    
    # Braking physics
    braking => (velocity <= 60)       # Can't brake effectively at high speed
])

# Driving scenario analysis:
issatisfiable(velocity > 80 & gear <= 3, vehicle_constraints)     # Possible?
isprovable(braking => (gear <= 3), vehicle_constraints)          # Braking implies low gear?
```

## Tips for Effective SAT Solving

### 1. Structure Your Queries

Ask specific, well-defined questions:

```julia
# Good: Specific question
issatisfiable(x > 5 & y < 3, constraints)

# Better: Break down complex queries
issatisfiable(x > 5, constraints) && issatisfiable(y < 3, constraints)
```

### 2. Use Appropriate Granularity

Choose the right level of detail:

```julia
# For rough feasibility
issatisfiable(x > 0, constraints)

# For precise analysis  
issatisfiable(x >= 2.5 & x <= 2.6, constraints)
```

### 3. Leverage Provability

Use provability to verify invariants:

```julia
# Safety verification
isprovable(temperature <= max_temp, safety_constraints)  # Always safe?

# Optimization verification
isprovable(profit >= 0, business_constraints)            # Always profitable?
```

### 4. Combine Multiple Queries

Build complex analysis from simple queries:

```julia
# Check if exactly one solution exists
has_solution = issatisfiable(expr, constraints)
unique_solution = has_solution && isprovable(expr, constraints)
```

## Common Patterns

### Feasibility Checking
```julia
issatisfiable(candidate_solution, constraints)
```

### Invariant Verification
```julia
isprovable(safety_property, constraints)
```

### Bounds Analysis
```julia
issatisfiable(variable > upper_bound, constraints)  # Can exceed bound?
isprovable(variable >= lower_bound, constraints)    # Always above bound?
```

### Configuration Validation
```julia
issatisfiable(configuration_expr, system_constraints)
```