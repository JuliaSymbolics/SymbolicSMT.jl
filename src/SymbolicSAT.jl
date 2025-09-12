module SymbolicSAT

using SymbolicUtils
using SymbolicUtils: Sym, Term, operation, arguments, Symbolic, symtype, istree
using Z3

export Constraints, issatisfiable, isprovable

# Symutils -> Z3

function to_z3(term, ctx)
    return to_z3_tree(term, ctx)
end

# Handle boolean expressions as trees (must come before Integer to avoid ambiguity)  
to_z3(x::Symbolic{Bool}, ctx) = to_z3_tree(x, ctx)

# Handle symbolic variables (updated for new SymbolicUtils API)
to_z3(x::Symbolic{<:Integer}, ctx) = IntVar(string(x), ctx)
to_z3(x::Symbolic{<:Real}, ctx) = IntVar(string(x), ctx)  # Z3 handles reals as ints for now

# Handle literal values
to_z3(x::Integer, ctx) = IntVal(x, ctx)
to_z3(x::AbstractFloat, ctx) = Float64Val(x, ctx)

# Helper function to handle tree processing (renamed the main tree logic)
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
            return Z3.And(args′...)
        elseif op === (|)
            return Z3.Or(args′...)
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

function isprovable(expr, cs::Constraints)
    sat = issatisfiable(expr, cs)
    sat === true ? !issatisfiable(!expr, cs) : false
end

issatisfiable(expr::Bool, Constraints) = expr

boolsym(x::Symbolic) = symtype(x) == Bool
boolsym(x) = false

function resolve(x, ctx)
     isprovable(x, ctx) === true ?
        true : isprovable(!(x), ctx) === true ? false : x
end

end # module
