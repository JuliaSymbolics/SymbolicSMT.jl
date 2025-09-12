using SymbolicSMT
using SymbolicUtils
using SymbolicUtils: Sym
using Test

@testset "Basic Functionality Tests" begin
    # Test package loads
    @test isdefined(SymbolicSMT, :Constraints)
    @test isdefined(SymbolicSMT, :issatisfiable)
    @test isdefined(SymbolicSMT, :isprovable)

    # Test symbolic variable creation
    x = Sym{Real}(:x)
    y = Sym{Real}(:y)
    @test x isa SymbolicUtils.Symbolic
    @test y isa SymbolicUtils.Symbolic

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