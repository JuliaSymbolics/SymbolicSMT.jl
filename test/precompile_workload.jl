using SymbolicSMT
using Symbolics
using Test

@variables x::Real
constraints = Constraints([x > 0])

@test issatisfiable(x > 1, constraints)
@test isprovable(x > 0, constraints)
@test isequal(resolve(x > 1, constraints), x > 1)
