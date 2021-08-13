using Motika

add = BoseFS((0,0,0,8,0,0,0,0))
params = RunTillLastStep(laststep=5_000)
dv = DVec(add => 1; style=IsDynamicSemistochastic())

@plant id="plateau" path=joinpath(@__DIR__, "plateau") u=2:2:6 nt=100:100:2500 begin
    ham = HubbardMom1D(add; u)
    post_step = ProjectedEnergy(ham, dv)
    s_strat = DoubleLogUpdate(targetwalkers=nt)
    params.step = 0
    lomc!(ham, dv; params, s_strat, post_step, dτ=1e-4, maxlength=5000)
end
