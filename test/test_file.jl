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


    @testset "Basic interface test" begin
        df = find_interface_limits(sys, solver)

        @test df isa DataFrame
        @test names(df) == ["interface", "transfer_limit", "sum_capacity"]
        @test nrow(df) > 0
        @test all(df.transfer_limit .>= 0)
        @test all(df.transfer_limit .<= df.sum_capacity .+ 1e-6)
    end

    @testset "n-1 interface limits (security=true)" begin
        @info "calculating n-1 interface limits"
        df = find_interface_limits(sys, solver, security=true)

        @test df isa DataFrame
        @test names(df) == ["interface", "transfer_limit", "sum_capacity"]
        @test nrow(df) > 0
        @test all(df.transfer_limit .>= 0)
        @test all(df.transfer_limit .<= df.sum_capacity .+ 1e-6)
    end

    interfaces = InterfaceLimits.find_interfaces(sys)
    interface_key = first(collect(keys(interfaces)))
    interface = interfaces[interface_key]

    @testset "calculating n-0 interface limits for just 1 interface" begin
        interface_lims =
            find_interface_limits(sys, solver, interface_key, interface)
        interface_lims = find_interface_limits(
            sys,
            solver,
            interface_key,
            interface,
            security=true,
        )
        @test interface_lims isa DataFrame
        @test names(interface_lims) == ["interface", "transfer_limit", "sum_capacity"]
        @test nrow(interface_lims) > 0
        @test all(interface_lims.transfer_limit .>= 0)
    end

    @testset "custom interface limits (with n-1)" begin
        interface_lims = find_interface_limits(
            sys,
            solver,
            interface_key,
            interface,
            security=true,
            injection_limits=InjectionLimits(genbus_upper_bound=5.0, loadbus_bounds=(0.0, 2.0), enforce_ldfs=true),
        )
        @test interface_lims isa DataFrame
        @test names(interface_lims) == ["interface", "transfer_limit", "sum_capacity"]
        @test nrow(interface_lims) > 0
        @test all(interface_lims.transfer_limit .>= 0)
    end
end
