using DiffEqBiological, Plots, Test

cd(@__DIR__)
include("test_networks.jl")

#Tests various bifurcation capabilities.
for rn in reaction_networks_standard
    p_vals = map(amp->amp*rand(length(rn.params)),[1.,10.,100.])
    param1 = rand(rn.params)
    param2 = rand(rn.params)
    range_tupple = (1.,rand(5.:10.))
    range1 = 1.: rand(5.:10.)
    range2 = 1.: rand(5.:10.)
    for p in p_vals
        bif1 = bifurcations(rn,p,param1,range_tupple)
        bif2 = bifurcations(rn,SimpleHCBifurcationSolver(),p,param1,range_tupple)
        bif_grid = bifurcation_grid(rn,p,param1,range1)
        bif_grid_2d = bifurcation_grid_2d(rn,p,param1,range1,param2,range2)
        bif_grid_dia = bifurcation_grid_diagram(rn,p,param1,range1,param2,range_tupple)
        plot(bif1); plot(bif2); plot(bif_grid); plot(bif_grid_2d); plot(bif_grid_dia);
    end
end

#More extensive tests on familiar networks.
brusselator_network = @reaction_network begin
    A, ∅ → X
    1, 2X + Y → 3X
    B, X → Y
    1, X → ∅
end A B;
brusselator_p = [1.,4.]
@make_hc_template brusselator_network
@add_hc_template brusselator_network
bif_brusselator = bifurcations(brusselator_network,brusselator_p,:B,(1.,4.))
if VERSION >=  v"1.1"
    @test length(bif_brusselator.paths) == 1
else
    @warn "Some test for bifurcation diagram path numbers are disabled for Julia 1.0 versions. Bifurcation diagrams might contain slight errors for tehse versions."
end

σ_network = @reaction_network begin
    v0 + hill(σ,v,K,n), ∅ → (σ+A)
    deg, (σ,A,Aσ) → ∅
    (kB,kD), A + σ ↔ Aσ
    S*kC, Aσ → σ
end v0 v K n kD kB kC deg S;
fix_parameters(σ_network,n=4)
σ_p = [0.005, 0.1, 2.8, 4, 10, 100, 0.1, 0.01, 0.5]
make_hc_template!(σ_network)
add_hc_template!(σ_network)
ss_σ = steady_states(σ_network,σ_p)
@test(length(ss_σ)==3)
stabs_σ = stability(ss_σ,σ_network,σ_p)
@test(sum(stabs_σ.==true)==2)
bif_σ = bifurcations(σ_network,σ_p,:S,(0.,2.))
if VERSION >= v"1.1"
    @test length(bif_σ.paths) == 3
else
    @warn "Some test for bifurcation diagram path numbers are disabled for Julia 1.0 versions. Bifurcation diagrams might contain slight errors for tehse versions."
end

cc_network = @reaction_network begin
  k1, 0 --> Y
  k2p, Y --> 0
  k2pp*P, Y --> 0
  (k3p+k3pp*A)/(J3+Po), Po-->P
  (k4*m)/(J4+P), Y + P --> Y + Po
end k1 k2p k2pp k3p k3pp A J3 k4 m J4
cc_p = [0.04,0.04,1.,1.,10.0,0.,0.04,35.,.3,.04]
@add_constraint cc_network P+Po=1
add_hc_template!(cc_network)
@add_hc_template cc_network
ss_cc = steady_states(cc_network,cc_p)
@test(length(ss_cc)==3)
stabs_cc = stability(ss_σ,σ_network,σ_p)
@test(sum(stabs_cc.==true)==2)
bif_cc = bifurcations(cc_network,cc_p,:m,(.01,.65))
if VERSION>= v"1.1"
    @test length(bif_cc.paths) == 3
else
    @warn "Some test for bifurcation diagram path numbers are disabled for Julia 1.0 versions. Bifurcation diagrams might contain slight errors for tehse versions."
end

bs_network = @reaction_network begin
    d,    (X,Y) → ∅
    hillR(Y,v1,K1,n1), ∅ → X
    hillR(X,v2,K2,n2), ∅ → Y
end d v1 K1 n1 v2 K2 n2
bs_p = [0.01, 1. , 30., 3, 1., 30, 3];
bif_bs = bifurcations(bs_network, bs_p,:v1,(.1,10.))
if VERSION >= v"1.1"
    @test length(bif_bs.paths) == 3
    @test sum(map(p->median(p.stability_types),bif_bs.paths))==2
else
    @warn "Some test for bifurcation diagram path numbers are disabled for Julia 1.0 versions. Bifurcation diagrams might contain slight errors for tehse versions."
end
