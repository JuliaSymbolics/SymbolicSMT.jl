using SymbolicSMT
using SymbolicUtils: Sym
using Test

@testset "SAT Solver Tests" begin
    # Create symbolic variables
    x = Sym{Real}(:x)
    y = Sym{Real}(:y)
    
    # Test satisfiability with simple constraints
    @testset "Basic Satisfiability" begin
        cs = Constraints([x >= 0, y >= 0])
        
        # Should be satisfiable
        @test issatisfiable(x >= 0, cs) == true
        @test issatisfiable(y >= 0, cs) == true
        @test issatisfiable(x + y >= 0, cs) == true
        @test issatisfiable(x + y >= 1, cs) == true
        
        # Test with expressions that should be satisfiable
        @test issatisfiable(2*x + 3*y <= 100, cs) == true
        @test issatisfiable(x - y <= 10, cs) == true
    end
    
    @testset "Provability Tests" begin
        cs = Constraints([x >= 0, y >= 0])
        
        # Should be provable from constraints
        @test isprovable(x >= 0, cs) == true
        @test isprovable(y >= 0, cs) == true
        
        # Should not be provable (could be false)
        @test isprovable(x >= 1, cs) == false
        @test isprovable(x + y >= 1, cs) == false
    end
    
    @testset "Contradictory Constraints" begin
        # Test with contradictory constraints
        cs_contradiction = Constraints([x >= 10, x <= 5])
        
        # Even x >= 0 should be unsatisfiable due to contradiction
        @test issatisfiable(x >= 0, cs_contradiction) == false
        @test issatisfiable(x == 7, cs_contradiction) == false
    end
    
    @testset "Complex Expressions" begin
        cs = Constraints([x >= 0, y >= 0, x + y <= 10])
        
        # Test complex arithmetic expressions
        @test issatisfiable(2*x + 3*y <= 15, cs) == true
        @test issatisfiable(x*y >= 0, cs) == true
        @test issatisfiable(-x <= 0, cs) == true
    end
end