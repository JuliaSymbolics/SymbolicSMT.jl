using SymbolicSMT
using SymbolicUtils
using SymbolicUtils: BasicSymbolic
using Test

@testset "Basic Functionality Tests" begin
    # Test package loads
    @test isdefined(SymbolicSMT, :Constraints)
    @test isdefined(SymbolicSMT, :issatisfiable)
    @test isdefined(SymbolicSMT, :isprovable)

    # Test symbolic variable creation (updated for SymbolicUtils v4)
    @syms x::Real y::Real
    @test x isa BasicSymbolic
    @test y isa BasicSymbolic

    # Test basic constraint creation
    @test_nowarn begin
        Constraints([x >= 0])
        Constraints([x >= 0, y >= 0])
    end

    # Test constraint display
    cs = Constraints([x >= 0, y >= 0])
    @test cs isa Constraints
    @test length(cs.constraints) == 2
end