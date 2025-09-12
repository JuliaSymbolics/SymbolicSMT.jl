using SafeTestsets, Test
using SymbolicSAT

const GROUP = get(ENV, "GROUP", "All")

if GROUP == "All" || GROUP == "Core"
    @testset "SymbolicSAT.jl Tests" begin
        @safetestset "Basic Functionality" begin include("basic.jl") end
        @safetestset "SAT Solver Tests" begin include("solver.jl") end
        @safetestset "Constraint Construction" begin include("constraints.jl") end
        @safetestset "Symbolic Operations" begin include("operations.jl") end
        @safetestset "Symbolics.jl Frontend" begin include("symbolics_frontend.jl") end
    end
end