using SciMLTesting
using SymbolicSMT

run_qa(
    SymbolicSMT;
    ei_kwargs = (;
        all_qualified_accesses_are_public = (; ignore = (:Expr, :Libz3)),
    ),
    reexports_allow = (Symbol("@variables"),),
)
