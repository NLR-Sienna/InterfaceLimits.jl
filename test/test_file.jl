using PowerSystems
using PowerNetworkMatrices
using DataFrames
using HiGHS

@testset "find_interface_limits on RTS-GMLC" begin
    solver = optimizer_with_attributes(HiGHS.Optimizer, "output_flag" => false)

    sys = System(
        joinpath(
            dirname(dirname(pathof(InterfaceLimits))),
            "examples",
            "rts",
            "RTS-GMLC.RAW",
        ),
    )
    set_units_base_system!(sys, "natural_units")

    df = find_interface_limits(sys, solver)

    @test df isa DataFrame
    @test names(df) == ["interface", "transfer_limit", "sum_capacity"]
    @test nrow(df) > 0
    @test all(df.transfer_limit .>= 0)
    @test all(df.transfer_limit .<= df.sum_capacity .+ 1e-6)
end
