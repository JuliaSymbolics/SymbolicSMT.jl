using Documenter, SymbolicSAT, Symbolics

# Create custom documenter function
function make_docs()
    makedocs(
        sitename="SymbolicSAT.jl",
        authors="Shashi Gowda <shashigowda91@gmail.com>",
        modules=[SymbolicSAT],
        clean=true,
        doctest=false, # Disable doctests for now since we use Z3
        format=Documenter.HTML(
            prettyurls=get(ENV, "CI", "false") == "true",
            canonical="https://JuliaSymbolics.github.io/SymbolicSAT.jl/stable/",
            assets=String[],
            mathengine=Documenter.MathJax3(Dict(
                :loader => Dict("load" => ["[tex]/physics"]),
                :tex => Dict(
                    "inlineMath" => [["\$", "\$"], ["\\(", "\\)"]],
                    "tags" => "ams",
                    "packages" => ["base", "ams", "autoload", "physics"]
                )
            ))
        ),
        pages=[
            "Home" => "index.md",
            "Getting Started" => "getting_started.md",
            "Manual" => [
                "manual/basics.md",
                "manual/constraints.md",
                "manual/sat_solving.md",
                "manual/symbolics_interface.md"
            ],
            "Tutorials" => [
                "tutorials/basic_examples.md"
            ],
            "API Reference" => "api.md"
        ],
        checkdocs=:exports,
        warnonly=true
    )
end

make_docs()

deploydocs(
    repo="github.com/JuliaSymbolics/SymbolicSAT.jl.git",
    target="build",
    branch="gh-pages",
    devbranch="master",
    versions=["stable" => "v^", "v#.#"]
)