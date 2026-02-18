using SymbolicSMT
using SymbolicUtils
using Symbolics
using Test

@testset "Unsat Core Tests" begin
    @testset "Basic unsat core extraction" begin
        @syms x::Real y::Real

        # Constraints 1 and 2 contradict; constraint 3 is irrelevant
        cs = Constraints([x > 0, x < -1, y > 0])
        core = unsat_core(cs)

        # Core should contain indices 1 and 2 but not 3
        @test 1 in core
        @test 2 in core
        @test !(3 in core)
    end

    @testset "All constraints in core" begin
        @syms x::Real

        # All three constraints together are unsatisfiable
        cs = Constraints([x > 0, x < 10, x > 20])
        core = unsat_core(cs)

        # Core should identify the conflicting subset
        @test length(core) >= 2
        # At minimum, x > 20 and x < 10 must be in the core
        @test 2 in core
        @test 3 in core
    end

    @testset "Error on satisfiable constraints" begin
        @syms x::Real y::Real

        cs = Constraints([x > 0, y > 0])
        @test_throws ErrorException unsat_core(cs)
    end

    @testset "Two-constraint contradiction" begin
        @syms x::Real

        cs = Constraints([x >= 10, x <= 5])
        core = unsat_core(cs)
        @test sort(core) == [1, 2]
    end

    @testset "Unsat core with Symbolics.jl Num types" begin
        @variables x::Real y::Real

        cs = Constraints([x > 0, x < -1, y > 0])
        core = unsat_core(cs)

        @test 1 in core
        @test 2 in core
        @test !(3 in core)
    end

    @testset "Retrieve original constraints from core" begin
        @syms x::Real y::Real

        constraints_vec = [x > 0, x < -1, y > 0]
        cs = Constraints(constraints_vec)
        core = unsat_core(cs)

        # Can index back into original constraints
        conflicting = cs.constraints[core]
        @test length(conflicting) == 2
    end

    @testset "Larger constraint set" begin
        @syms x::Real y::Real z::Real

        # Only constraints 2 and 5 conflict (y > 10 and y < 0)
        cs = Constraints(
            [
                x > 0,
                y > 10,
                z > 0,
                x + z < 100,
                y < 0,
            ]
        )
        core = unsat_core(cs)

        @test 2 in core
        @test 5 in core
        # x and z constraints should not be in the core
        @test !(1 in core)
        @test !(3 in core)
        @test !(4 in core)
    end
end
