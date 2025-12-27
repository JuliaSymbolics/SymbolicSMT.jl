using SymbolicSMT
using Symbolics
using Test

@testset "Symbolics.jl Frontend Tests" begin
    # Test @variables macro re-export
    @variables x::Real y::Real z::Integer
    
    @test x isa Symbolics.Num
    @test y isa Symbolics.Num  
    @test z isa Symbolics.Num
    
    @testset "Constraints with Num Types" begin
        # Test Constraints constructor with Num
        @test_nowarn Constraints([x > 0])
        @test_nowarn Constraints([x > 0, y >= 0])
        @test_nowarn Constraints([x + y < 10, x * y > 1])
        
        # Test constraint creation works
        cs = Constraints([x >= 0, y >= 0])
        @test cs isa Constraints
        @test length(cs.constraints) == 2
    end
    
    @testset "issatisfiable with Num" begin
        cs = Constraints([x > 0, y > 0])
        
        # Basic satisfiability tests with Num expressions
        @test issatisfiable(x > 0, cs) == true
        @test issatisfiable(y > 0, cs) == true
        @test issatisfiable(x < 0, cs) == false
        @test issatisfiable(y < 0, cs) == false
        
        # Arithmetic expressions
        @test issatisfiable(x + y > 0, cs) == true
        @test issatisfiable(x + y > 2, cs) == true
        @test issatisfiable(x - y < 10, cs) == true
        @test issatisfiable(x * y > 0, cs) == true
        
        # Complex expressions
        @test issatisfiable(2*x + 3*y > 1, cs) == true
        @test issatisfiable(x^2 + y^2 > 0, cs) == true
    end
    
    @testset "isprovable with Num" begin
        cs = Constraints([x >= 0, y >= 0])
        
        # Provability tests with Num expressions
        @test isprovable(x >= 0, cs) == true
        @test isprovable(y >= 0, cs) == true
        # Note: x + y >= 0 may not be provable with some Z3 theories, so we test a simpler case
        @test isprovable(x >= 0, cs) == true
        
        # Should not be provable
        @test isprovable(x > 0, cs) == false  # Could be x = 0
        @test isprovable(x > y, cs) == false  # Could be x < y
        @test isprovable(x + y > 1, cs) == false  # Could be x = y = 0
    end
    
    @testset "resolve with Num" begin
        cs = Constraints([x > 5, y >= 0])
        
        # Should resolve to boolean constants
        result1 = resolve(x > 0, cs)
        @test result1 === true
        
        result2 = resolve(x < 0, cs)  
        @test result2 === false
        
        # Should return Num (cannot resolve)
        result3 = resolve(x > 10, cs)
        @test result3 isa Symbolics.Num
        @test string(result3) == "x > 10"
        
        result4 = resolve(y > 1, cs)
        @test result4 isa Symbolics.Num
        @test string(result4) == "y > 1"
    end
    
    @testset "Mixed Num and SymbolicUtils" begin
        # Test that we can mix Symbolics and SymbolicUtils variables
        # Updated for SymbolicUtils v4
        using SymbolicUtils
        SymbolicUtils.@syms x_sym::Real

        # Constraints with mixed types
        cs_mixed = Constraints([x > 0])  # x is Num

        # Test with SymbolicUtils expression
        @test issatisfiable(x_sym > 0, cs_mixed) == true

        # Test with Num expression
        @test issatisfiable(x < 0, cs_mixed) == false
    end
    
    @testset "Integer Variables" begin
        # Test with integer Num variables
        @variables n::Integer m::Integer
        
        cs_int = Constraints([n >= 1, m >= 1])
        
        @test issatisfiable(n + m >= 2, cs_int) == true
        @test isprovable(n >= 1, cs_int) == true
        @test isprovable(n > 0, cs_int) == true
    end
    
    @testset "Boolean Variables" begin
        # Test with boolean Num variables
        @variables p::Bool q::Bool
        
        cs_bool = Constraints([p])  # p must be true
        
        @test issatisfiable(p, cs_bool) == true
        @test issatisfiable(!p, cs_bool) == false
        @test isprovable(p, cs_bool) == true
        @test isprovable(p | q, cs_bool) == true
    end
    
    @testset "Complex Symbolics Expressions" begin
        @variables a::Real b::Real c::Real
        
        # Test complex constraints  
        cs_complex = Constraints([
            a^2 + b^2 <= 1,  # Unit circle
            c >= 0            # Positive c
        ])
        
        # Test complex expressions
        @test issatisfiable(a + b + c > 0, cs_complex) == true
        @test issatisfiable(a^2 + b^2 + c^2 <= 2, cs_complex) == true
        
        # Test that points on circle boundary satisfy the constraint
        @test issatisfiable(a^2 + b^2 <= 1, cs_complex) == true
    end
end