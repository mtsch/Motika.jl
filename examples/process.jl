using Motika
using LaTeXStrings
using Plots, StatsPlots

@harvest function h(data)
    nt = first(data.nt)
    u = first(data.u)
    μ_shift, σ_shift = mean_and_se(data.shift)
    μ_proj, σu_proj, σl_proj, _, _ = projected_energy(data)
    label = string("\$u = ", data.u[1], "\$") # Nice string for labels
end

data = sort!(harvest(h, "plateau"; skip=1000), [:u, :nt])

plt = @df data plot(
    :nt, :μ_shift; ribbon=:σ_shift,
    xlabel=L"N_t", ylabel=L"\langle S\rangle", group=:label, legend=:bottomright
)
savefig(plt, "plateau-shift.pdf")

plt = @df data plot(
    :nt, :μ_proj; ribbon=(:σu_proj, :σl_proj),
    xlabel=L"N_t", ylabel=L"E_p", group=:label, legend=:topright
)
savefig(plt, "plateau-proj.pdf")
