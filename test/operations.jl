using SymbolicSMT
using SymbolicUtils
using Test

@testset "Symbolic Operations Tests" begin
    # Updated for SymbolicUtils v4
    @syms x::Real y::Real
    
    @testset "Comparison Operations" begin
        cs = Constraints([x >= 0, y >= 0])
        
        # Test all comparison operators work
        @test issatisfiable(x >= 1, cs) == true
        @test issatisfiable(x <= 100, cs) == true  
        @test issatisfiable(x > 0, cs) == true
        @test issatisfiable(x < 100, cs) == true
        @test issatisfiable(x == 5, cs) == true
    end
    
    @testset "Arithmetic Operations" begin
        cs = Constraints([x >= 1, y >= 1])
        
        # Test addition
        @test issatisfiable(x + y >= 2, cs) == true
        @test issatisfiable(x + y >= 10, cs) == true
        
        # Test subtraction  
        @test issatisfiable(x - y >= 0, cs) == true
        @test issatisfiable(x - y <= 0, cs) == true
        
        # Test multiplication
        @test issatisfiable(x * y >= 1, cs) == true
        
        # Test unary minus
        @test issatisfiable(-x <= -1, cs) == true
    end
    
    @testset "Complex Expressions" begin
        cs = Constraints([x >= 0, y >= 0])
        
        # Test complex arithmetic combinations
        @test issatisfiable(2*x + 3*y - 1 >= 0, cs) == true
        @test issatisfiable((x + y) * 2 >= 0, cs) == true
        @test issatisfiable(x - 2*y + 5 <= 10, cs) == true
    end
    
    @testset "Mixed Variable Types" begin
        @syms z::Integer
        cs = Constraints([x >= 0, z >= 0])
        
        # Test operations between Real and Integer variables
        @test issatisfiable(x + z >= 0, cs) == true
        @test issatisfiable(x - z <= 10, cs) == true
    end
    
    @testset "Constants and Literals" begin
        cs = Constraints([x >= 0])
        
        # Test operations with numeric constants
        @test issatisfiable(x >= 0, cs) == true
        @test issatisfiable(x + 5 >= 5, cs) == true  
        @test issatisfiable(2*x >= 0, cs) == true
        @test issatisfiable(x - 10 >= -10, cs) == true
    end
end