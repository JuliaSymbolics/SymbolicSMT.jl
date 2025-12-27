using SymbolicSMT
using SymbolicUtils
using Test

@testset "Regression Tests" begin
    @testset "Issue #14 - Multi-variable arithmetic expressions" begin
        # These tests verify that multi-variable arithmetic expressions are correctly
        # converted to Z3. Before the fix, expressions like `x + y` were incorrectly
        # converted to a single Z3 variable named "x + y" instead of the sum of x and y.

        # Updated for SymbolicUtils v4
        @syms x::Integer y::Integer

        # Constraints: x >= 1, y >= 1
        cs = Constraints([x >= 1, y >= 1])

        # This would incorrectly return `true` with the bug because `x + y` was
        # treated as a new unconstrained variable that could take any value
        @test issatisfiable(x + y <= 0, cs) == false

        # This would incorrectly return `false` with the bug
        @test isprovable(x + y >= 2, cs) == true

        # Additional multi-variable arithmetic tests
        @test issatisfiable(x + y >= 2, cs) == true
        @test issatisfiable(x + y >= 100, cs) == true  # satisfiable since x, y can be large
        @test isprovable(x + y >= 1, cs) == true  # always true since x >= 1, y >= 1
        @test isprovable(x + y > 0, cs) == true   # always true since x >= 1, y >= 1

        # Test subtraction with multi-variable expressions
        @test issatisfiable(x - y == 0, cs) == true  # x = y = 1 works
        @test issatisfiable(x - y > 0, cs) == true   # x > y is possible
        @test issatisfiable(x - y < 0, cs) == true   # x < y is possible

        # Test multiplication with multi-variable expressions
        @test issatisfiable(x * y == 1, cs) == true  # x = y = 1 works
        @test isprovable(x * y >= 1, cs) == true     # always true since x >= 1, y >= 1

        # Test nested expressions
        cs2 = Constraints([x >= 0, y >= 0, x + y <= 10])
        @test issatisfiable(x + y > 5, cs2) == true
        @test issatisfiable(x + y > 10, cs2) == false
        @test isprovable(x + y <= 10, cs2) == true
    end

    @testset "Power operator support" begin
        # Test power operator (^) which was added as part of the fix
        # Updated for SymbolicUtils v4
        @syms x::Integer y::Integer

        # Basic power tests
        cs = Constraints([x >= 0, x <= 3])
        @test issatisfiable(x^2 <= 9, cs) == true
        @test issatisfiable(x^2 >= 0, cs) == true
        @test isprovable(x^2 >= 0, cs) == true

        # Quadratic constraints
        cs2 = Constraints([x^2 + y^2 < 4])
        @test issatisfiable(x == 0, cs2) == true
        @test issatisfiable(x == 1, cs2) == true
        @test issatisfiable(y == 1, cs2) == true
        # For integers, x^2 + y^2 < 4 means |x| <= 1 and |y| <= 1 (excluding corners like (1,2))
        # Actually: x^2 + y^2 < 4 allows (0,0), (0,1), (1,0), (1,1), (-1,0), (0,-1), (-1,1), (1,-1), (-1,-1)
        # So x can be -1, 0, or 1 (since 2^2 = 4 >= 4)
        @test issatisfiable(x == 2, cs2) == false   # 2^2 = 4 >= 4
        @test issatisfiable(x == -2, cs2) == false  # (-2)^2 = 4 >= 4

        # Power with multi-variable expressions
        cs3 = Constraints([x >= 1, y >= 1])
        @test issatisfiable(x^2 + y^2 >= 2, cs3) == true  # x=1, y=1 gives 2
        @test isprovable(x^2 + y^2 >= 2, cs3) == true     # minimum is 1+1=2
    end

    # Note: Division operator (/) was added to handle the Z3_mk_div operation,
    # but integer division semantics in Z3 are complex and may not work as expected
    # in all cases. The core fix for Issue #14 is the arithmetic expression handling.
end
