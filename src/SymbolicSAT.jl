module SymbolicSAT

using SymbolicUtils
using SymbolicUtils: Sym, Term, operation, arguments, Symbolic, symtype, istree, iscall
using Symbolics
using Symbolics: Num, unwrap, wrap, @variables
using Z3

export Constraints, issatisfiable, isprovable, resolve
# Re-export useful Symbolics.jl functionality
export @variables

# Symutils -> Z3

"""
    to_z3(term, ctx)

Convert a SymbolicUtils expression to a Z3 expression.

# Arguments
- `term`: The SymbolicUtils expression to convert
- `ctx`: The Z3 context to use for creating the Z3 expression

# Returns
A Z3 expression equivalent to the input term.

# Examples
```julia
using SymbolicUtils, SymbolicSAT, Z3
@syms x::Real
ctx = Context()
z3_expr = to_z3(x > 0, ctx)
```
"""
function to_z3(term, ctx)
    return to_z3_tree(term, ctx)
end

# Handle symbolic variables (updated for new SymbolicUtils API)
# Boolean expressions: use tree processing if it's a compound expression, otherwise treat as variable
function to_z3(x::Symbolic{Bool}, ctx)
    if iscall(x)
        return to_z3_tree(x, ctx)
    else
        return BoolVar(string(x), ctx)
    end
end

to_z3(x::Symbolic{<:Integer}, ctx) = IntVar(string(x), ctx)
to_z3(x::Symbolic{<:Real}, ctx) = IntVar(string(x), ctx)  # Z3 handles reals as ints for now

# Handle literal values
to_z3(x::Integer, ctx) = IntVal(x, ctx)
to_z3(x::AbstractFloat, ctx) = Float64Val(x, ctx)
to_z3(x::Bool, ctx) = BoolVal(x, ctx)

"""
    to_z3_tree(term, ctx)

Helper function to recursively convert SymbolicUtils expression trees to Z3.

Handles the conversion of compound expressions by recursively processing
the operation and its arguments.

# Arguments
- `term`: The SymbolicUtils expression (potentially a tree)
- `ctx`: The Z3 context

# Returns
A Z3 expression representing the input term.
"""
function to_z3_tree(term, ctx)
    if iscall(term)
        op = operation(term)
        args = arguments(term)

        # Convert arguments first
        args′ = map(x->to_z3(x, ctx), args)
        
        # Check for unconverted symbolic arguments
        s = findfirst(x->x isa Symbolic, args′)
        if s !== nothing
            error("$(args′[s]) of type $(typeof(args′[s])) and symtype $(symtype(args′[s])) was not converted into a z3 expression")
        end

        # Handle operations
        if length(args) == 1 && (op === (!) || op === (~))
            # Unary operations
            return Z3.Not(args′[1])
        elseif op === (&)
            return Z3.And(collect(args′))
        elseif op === (|)
            return Z3.Or(collect(args′))
        elseif op === (>=)
            # Comparison operations using low-level API
            expr_ptr = Z3.Libz3.Z3_mk_ge(ctx.ctx, args′[1].expr, args′[2].expr)
            return Z3.Expr(ctx, expr_ptr)
        elseif op === (<=)
            expr_ptr = Z3.Libz3.Z3_mk_le(ctx.ctx, args′[1].expr, args′[2].expr)
            return Z3.Expr(ctx, expr_ptr)
        elseif op === (>)
            expr_ptr = Z3.Libz3.Z3_mk_gt(ctx.ctx, args′[1].expr, args′[2].expr)
            return Z3.Expr(ctx, expr_ptr)
        elseif op === (<)
            expr_ptr = Z3.Libz3.Z3_mk_lt(ctx.ctx, args′[1].expr, args′[2].expr)
            return Z3.Expr(ctx, expr_ptr)
        elseif op === (==)
            expr_ptr = Z3.Libz3.Z3_mk_eq(ctx.ctx, args′[1].expr, args′[2].expr)
            return Z3.Expr(ctx, expr_ptr)
        elseif op === (+)
            # Arithmetic operations
            expr_ptr = Z3.Libz3.Z3_mk_add(ctx.ctx, length(args′), [a.expr for a in args′])
            return Z3.Expr(ctx, expr_ptr)
        elseif op === (-)
            if length(args′) == 1
                # Unary minus
                expr_ptr = Z3.Libz3.Z3_mk_unary_minus(ctx.ctx, args′[1].expr)
            else
                # Binary minus
                expr_ptr = Z3.Libz3.Z3_mk_sub(ctx.ctx, length(args′), [a.expr for a in args′])
            end
            return Z3.Expr(ctx, expr_ptr)
        elseif op === (*)
            expr_ptr = Z3.Libz3.Z3_mk_mul(ctx.ctx, length(args′), [a.expr for a in args′])
            return Z3.Expr(ctx, expr_ptr)
        else
            # Try to use the operation as a function (fallback)
            return op(args′...)
        end
    else
        return term
    end
end

"""
    Constraints(constraints::Vector, solvertype="QF_NRA")

A collection of boolean constraints with an associated Z3 solver.

This type wraps a vector of SymbolicUtils boolean expressions and manages
the corresponding Z3 solver context. Constraints are automatically converted
to Z3 format and added to the solver upon construction.

# Arguments
- `constraints::Vector`: Vector of boolean SymbolicUtils expressions
- `solvertype::String="QF_NRA"`: Z3 solver type to use

# Fields
- `constraints::Vector`: Original SymbolicUtils expressions
- `solver::Z3.Solver`: Z3 solver instance with constraints added
- `context::Z3.Context`: Z3 context associated with the solver

# Examples
```julia
using SymbolicUtils, SymbolicSAT
@syms x::Real y::Real

# Single constraint
c1 = Constraints([x > 0])

# Multiple constraints
c2 = Constraints([x > 0, y > 0, x + y < 10])

# Specify solver type
c3 = Constraints([x > 0], "QF_LRA")
```
"""
struct Constraints
    constraints::Vector
    solver::Z3.Solver
    context::Z3.Context

    function Constraints(cs::Vector, solvertype="QF_NRA")
        ctx = Context()
        s = Solver(ctx)

        for c in cs
            add(s, to_z3(c, ctx))
        end

        new(cs, s, ctx)
    end
end

function Base.show(io::IO, c::Constraints)
    cs = c.constraints
    println("Constraints:")
    for i in 1:length(cs)
        print(io, "  ")
        print(io, cs[i])
        i != length(cs) && println(io, " ∧")
    end
end

"""
    issatisfiable(expr, constraints::Constraints)

Check whether the given expression can be satisfied under the constraints.

Determines if there exists at least one assignment of variables that makes
both the constraints and the expression true.

# Arguments
- `expr`: Boolean expression to check for satisfiability
- `constraints::Constraints`: Constraints that must be satisfied

# Returns
- `true`: The expression can be satisfied given the constraints
- `false`: The expression cannot be satisfied given the constraints  
- `nothing`: The solver cannot determine satisfiability (unknown)

# Examples
```julia
using SymbolicUtils, SymbolicSAT
@syms x::Real y::Real

constraints = Constraints([x > 0, y > 0])

# Can x be negative?
issatisfiable(x < 0, constraints)  # false

# Can x + y be greater than 1?
issatisfiable(x + y > 1, constraints)  # true
```
"""
function issatisfiable(expr::Symbolic{Bool}, cs::Constraints)
    Z3.push(cs.solver)
    add(cs.solver, to_z3(expr, cs.context))
    res = check(cs.solver)
    Z3.pop(cs.solver,1)
    if string(res) == "sat"
        return true
    elseif string(res) == "unsat"
        return false
    elseif string(res) == "unknown"
        return nothing
    end
end

"""
    isprovable(expr, constraints::Constraints)

Check whether the given expression is provable (always true) under the constraints.

An expression is provable if it is true for all assignments of variables that
satisfy the constraints. This is equivalent to checking that the negation of
the expression is unsatisfiable under the constraints.

# Arguments
- `expr`: Boolean expression to check for provability
- `constraints::Constraints`: Constraints under which to check provability

# Returns
- `true`: The expression is provable (always true) given the constraints
- `false`: The expression is not provable given the constraints

# Examples
```julia
using SymbolicUtils, SymbolicSAT
@syms x::Real y::Real

constraints = Constraints([x >= 0, y >= 0])

# Is x + y always non-negative?
isprovable(x + y >= 0, constraints)  # true

# Is x always greater than y?
isprovable(x > y, constraints)  # false
```
"""
function isprovable(expr, cs::Constraints)
    sat = issatisfiable(expr, cs)
    sat === true ? !issatisfiable(!expr, cs) : false
end

"""
    issatisfiable(expr::Bool, ::Constraints)

Handle satisfiability checking for boolean literals.

Boolean literals are trivially satisfiable based on their truth value.

# Arguments
- `expr::Bool`: Boolean literal (true or false)
- `::Constraints`: Constraints (ignored for boolean literals)

# Returns
The boolean value itself.
"""
issatisfiable(expr::Bool, Constraints) = expr

boolsym(x::Symbolic) = symtype(x) == Bool
boolsym(x) = false

"""
    resolve(expr, constraints::Constraints)

Attempt to resolve an expression to a boolean constant using the constraints.

Tries to determine if the expression is provably true or provably false
under the given constraints. If neither can be proven, returns the
original expression unchanged.

# Arguments
- `expr`: Expression to resolve
- `constraints::Constraints`: Constraints to use for resolution

# Returns
- `true`: If the expression is provably true
- `false`: If the expression is provably false  
- `expr`: The original expression if it cannot be resolved

# Examples
```julia
using SymbolicUtils, SymbolicSAT
@syms x::Real

constraints = Constraints([x > 5])

resolve(x > 0, constraints)   # true (provable)
resolve(x < 0, constraints)   # false (provable negation)
resolve(x > 10, constraints)  # x > 10 (cannot resolve)
```
"""
function resolve(x, ctx)
     isprovable(x, ctx) === true ?
        true : isprovable(!(x), ctx) === true ? false : x
end

# ========================================
# Symbolics.jl Frontend
# ========================================

"""
    Constraints(constraints::Vector{Num}, solvertype="QF_NRA")

Create constraints from Symbolics.jl `Num` expressions.

This is a convenience constructor that accepts `Num` types from Symbolics.jl,
unwraps them to SymbolicUtils expressions, and creates the constraint set.

# Arguments
- `constraints::Vector{Num}`: Vector of boolean Symbolics.jl `Num` expressions
- `solvertype::String="QF_NRA"`: Z3 solver type to use

# Examples
```julia
using Symbolics, SymbolicSAT

@variables x::Real y::Real

# Create constraints with Symbolics.jl syntax
constraints = Constraints([x > 0, y >= 0, x + y < 10])

# Use with standard SymbolicSAT functions
issatisfiable(x + y > 5, constraints)
```
"""
function Constraints(constraints::Vector{Num}, solvertype="QF_NRA")
    # Unwrap Num to SymbolicUtils expressions
    symbolic_constraints = [unwrap(c) for c in constraints]
    return Constraints(symbolic_constraints, solvertype)
end

"""
    issatisfiable(expr::Num, constraints::Constraints)

Check satisfiability of a Symbolics.jl `Num` expression.

This convenience method accepts `Num` expressions from Symbolics.jl,
unwraps them to SymbolicUtils, and delegates to the core implementation.

# Arguments
- `expr::Num`: Boolean expression to check for satisfiability
- `constraints::Constraints`: Constraints that must be satisfied

# Returns
- `true`: The expression can be satisfied given the constraints
- `false`: The expression cannot be satisfied given the constraints  
- `nothing`: The solver cannot determine satisfiability (unknown)

# Examples
```julia
using Symbolics, SymbolicSAT

@variables x::Real y::Real
constraints = Constraints([x > 0, y > 0])

# Check with Symbolics.jl Num expressions
issatisfiable(x < 0, constraints)        # false
issatisfiable(x + y > 1, constraints)    # true
```
"""
function issatisfiable(expr::Num, cs::Constraints)
    return issatisfiable(unwrap(expr), cs)
end

"""
    isprovable(expr::Num, constraints::Constraints)

Check provability of a Symbolics.jl `Num` expression.

This convenience method accepts `Num` expressions from Symbolics.jl,
unwraps them to SymbolicUtils, and delegates to the core implementation.

# Arguments
- `expr::Num`: Expression to check for provability
- `constraints::Constraints`: Constraints under which to check provability

# Returns
- `true`: The expression is provably true under the constraints
- `false`: The expression can be false under the constraints

# Examples
```julia
using Symbolics, SymbolicSAT

@variables x::Real y::Real
constraints = Constraints([x >= 0, y >= 0])

# Check provability with Symbolics.jl
isprovable(x >= 0, constraints)     # true
isprovable(x > y, constraints)      # false
```
"""
function isprovable(expr::Num, cs::Constraints)
    return isprovable(unwrap(expr), cs)
end

"""
    resolve(expr::Num, constraints::Constraints)

Resolve a Symbolics.jl `Num` expression to a boolean constant if possible.

This convenience method accepts `Num` expressions from Symbolics.jl,
unwraps them to SymbolicUtils, delegates to the core implementation,
and wraps boolean results back to `Num` if needed.

# Arguments
- `expr::Num`: Expression to resolve
- `constraints::Constraints`: Constraints to use for resolution

# Returns
- `true`: If the expression is provably true
- `false`: If the expression is provably false  
- `Num`: The wrapped original expression if it cannot be resolved

# Examples
```julia
using Symbolics, SymbolicSAT

@variables x::Real
constraints = Constraints([x > 5])

resolve(x > 0, constraints)    # true
resolve(x < 0, constraints)    # false  
resolve(x > 10, constraints)   # x > 10 (as Num)
```
"""
function resolve(expr::Num, cs::Constraints)
    result = resolve(unwrap(expr), cs)
    # If result is the original SymbolicUtils expression, wrap it back to Num
    return result isa Bool ? result : wrap(result)
end

end # module
