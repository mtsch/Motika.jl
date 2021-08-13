module Motika

using Reexport
# Reexport stuff to create a nice environment to work in.
@reexport using DataFrames
@reexport using Rimu
@reexport using Rimu.StatsTools
@reexport using Rimu.RMPI
@reexport using Rimu: RimuIO

@reexport using Statistics, LinearAlgebra

using KrylovKit
using MacroTools
using MacroTools: postwalk
using NamedTupleTools
using Serialization
using SHA

export reference
export @plant, @harvest, harvest
export memory_use, projected_energy, set_coherence_and_norm!

include("references.jl")
include("plant.jl")
include("harvest.jl")
include("utils.jl")

end
