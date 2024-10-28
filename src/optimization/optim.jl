"""
    create_sphere_model(θ::Tuple{T,T})

    creats model for optimization with sphere dependences

    #Arguments
    -`θ::Tuple{T,T}`: tuple of Angles (θx, θz)
    -`start_set`: Parameter start values ["x_rotational_radius";"z_rotational_radius";"track_lever_length";"tie_rod_length"]

    #Returns:
    -`model`: returns a jump model

    See Also
    """
function create_model(θ::Tuple{T,T}, steering::Steering) where {T<:Number}
    θx_, θz_ = θ
    start_x_rotational_radius,start_z_rotational_radius,start_track_lever_length,start_tie_rod_length = getValue(steering)

    #selection of the used solver
    model = Model(optimizer_with_attributes(Ipopt.Optimizer,"tol" => 1e-3, 
                                                             "acceptable_tol" => 1e-1, 
                                                             "dual_inf_tol" =>1e-1, 
                                                            # "compl_inf_tol"=>  1e-9,
                                                            # "constr_viol_tol"=> 1e-9,
                                                             "max_iter" => 100))
   
    # define the parameters to be optimised
    @variable(model, 50.0 <= x_rotational_radius <= 200.0)
    @variable(model, 50.0 <= z_rotational_radius <= 200.0)
    @variable(model, 70.0 <= track_lever_length <= 200.0)
    @variable(model, 195.0 <= tie_rod_length <= 260.0)

    # fixed variables used in optimisation
    @variable(model, θx)
    @variable(model, θz)


    # used and unknown functions must be registered for optimisation
    register(model, :objective°, 6, objective°, autodiff=true)
    register(model, :checkConstraints°, 4, checkConstraints°, autodiff=true)

    # define the objectie of the given NL-Problem
    @NLobjective(model, Min, objective°(θx, θz, x_rotational_radius, z_rotational_radius, track_lever_length, tie_rod_length))
    
    # define the constraint of the given NL-Problem
    @NLconstraint(model, C, checkConstraints°(x_rotational_radius, z_rotational_radius, track_lever_length, tie_rod_length) >= 1 )

    # initialisation of the parameters
    set_start_value(x_rotational_radius, start_x_rotational_radius)
    set_start_value(z_rotational_radius, start_z_rotational_radius)
    set_start_value(track_lever_length, start_track_lever_length)
    set_start_value(tie_rod_length, start_tie_rod_length)

    fix(θx, θx_)
    fix(θz,θz_)

    return model
end

"""
    get_model_solution(model)

    gets the importend informations of the model solution

#Arguments:
-`model`: jump model

#Reruns:
-`objectiv`: value of the final objectiv
"""
function get_model_solution(model)
    x_rotational_radius, z_rotational_radius, track_lever_length, tie_rod_length, ~ = all_variables(model)
    solution = (value(x_rotational_radius),value(z_rotational_radius),value(track_lever_length),value(tie_rod_length))
    objective = objective_value(model)
    status = termination_status(model)
    return solution,objective,status
end 



"""
    optim(θ::Tuple{T,T},upper_bourder::Tuple{Float64, Float64, Float64, Float64},lower_bourder::Tuple{Float64, Float64, Float64, Float64},max_angleConfig)


#Arguments:
-`θ::Tuple{T,T}`: angle pair to be considered
-`upper_bourder::Tuple{Float64, Float64, Float64, Float64}`: upper bourder Tuple (x_rotational_radius, z_rotational_radius, track_lever.length, tie_rod.length)  (guidline = (100.0, 140.0,150.0,270.0))
-`lower_bourder::Tuple{Float64, Float64, Float64, Float64}`: lower bourder Tuple (x_rotational_radius, z_rotational_radius, track_lever.length, tie_rod.length) (guidline = (50.0,100.0, 100.0, 100.0))
-`max_angleConfig`: maximal angular area for rotary component (defult: (0,35))

#Returns:
-`opda`: instance of OptDa (optimization Data)
"""
function optim(θ::Tuple{T,T},args...) where {T<:Number}

    # Find initial values that fulfil all dependences
    param = random_search(args...)
    steering = Steering(param...) # param = x_rotational_radius, z_rotational_radius, track_lever_length, tie_rod_length
    
    suspension = Suspension(30)
    suspensionkinematics!(suspension)


    # optimization
    model = create_model(θ,steering)
    
    JuMP.optimize!(model)

    sol,objective,status = get_model_solution(model)

    # save
    steering = Steering(sol...)
    update!(θ, steering, suspension)

    optda = OptDa(param,steering, objective, status)

    return optda

end 

"""
    optim_IN_LOOP(θ::Tuple{T,T},upper_bourder::Tuple{Float64, Float64, Float64, Float64},lower_bourder::Tuple{Float64, Float64, Float64, Float64},max_angleConfig)


#Arguments:
-`θ::Tuple{T,T}`: angle pair to be considered
-`upper_bourder::Tuple{Float64, Float64, Float64, Float64}`: upper bourder Tuple (x_rotational_radius, z_rotational_radius, track_lever.length, tie_rod.length)  (guidline = (100.0, 140.0,150.0,270.0))
-`lower_bourder::Tuple{Float64, Float64, Float64, Float64}`: lower bourder Tuple (x_rotational_radius, z_rotational_radius, track_lever.length, tie_rod.length) (guidline = (50.0,100.0, 100.0, 100.0))
-`max_angleConfig`: maximal angular area for rotary component (defult: (0,35))

#Returns:
-`opda`: instance of OptDa (optimization Data)

"""
function optim_IN_LOOP(args...)
    sol = ["solutions"]
    i = 0
    while i < 100
        
        optda = optim(args...)
    
        if optda.status ==  MOI.LOCALLY_SOLVED || optda.status ==  MOI.NUMERICAL_ERROR
            sol = hcat(sol, optda)
            i += 1
        end

    end
    return sol
end



"""
    n_times_parallel_optim(num::Int64, θ::Tuple{T,T},upper_bourder::Tuple{Float64, Float64, Float64, Float64},lower_bourder::Tuple{Float64, Float64, Float64, Float64},max_angleConfig)

    Executes an optimisation 'n' times in parallel using threads.

    !(saves Dict in folder)

#Arguments:
-`θ::Tuple{T,T}`: angle pair to be considered
-`upper_bourder::Tuple{Float64, Float64, Float64, Float64}`: upper bourder Tuple (x_rotational_radius, z_rotational_radius, track_lever.length, tie_rod.length)  (guidline = (100.0, 140.0,150.0,270.0))
-`lower_bourder::Tuple{Float64, Float64, Float64, Float64}`: lower bourder Tuple (x_rotational_radius, z_rotational_radius, track_lever.length, tie_rod.length) (guidline = (50.0,100.0, 100.0, 100.0))
-`max_angleConfig`: maximal angular area for rotary component (defult: (0,35))

#Rerturns:
-`sol_dict`: Dict which contains the optimal solutions.


"""
function n_times_parallel_optim(num::Int64, args...)
    θx, θz = args[1]

    sol_dict = Dict{Int,Any}()

    lk = ReentrantLock()
    for id in 1:num
        valid = true 
        while valid
            optda = optim(args...)
            # status check 
            if optda.status != MOI.OPTIMAL && optda.status != MOI.LOCALLY_SOLVED && optda.status != MOI.NUMERICAL_ERROR && optda.status != MOI.ITERATION_LIMIT
                continue
            else
                valid = false
            end
            # write in Dict
            lock(lr) do 
                sol_dict[id] = optda
            end 
        end
    end 

    # save Dict

    return sol_dict

end 



"""
    grid_optim(upper_bourder::Tuple{Float64, Float64, Float64, Float64},lower_bourder::Tuple{Float64, Float64, Float64, Float64}, max_angleConfig::Tuple{I,I}) where {I::Int64}



"""
function grid_optim(upper_bourder::Tuple{T, T, T, T},lower_bourder::Tuple{T, T, T, T}, max_angleConfig) where {T<:Number}
    θx_max , θz_max = max_angleConfig
    step_size = 1
    #initialisieren aller Winkelmäglichkeiten
    θ_tuple = [(i, j) for i in 0:step_size:θx_max, j in 0:step_size:θz_max]

    ######## starting Optimization #########
    for i in 1:Int((θx_max/step_size)+1)
        data_name = "data\\data($((i-1)*step_size),n)"
        path_data = joinpath(@__DIR__, data_name)
        mkdir(path_data)

        for θ in θ_tuple[i,:] 
            if θ != (0,0)
                sol_dict =  n_times_parallel_optim(2,θ,upper_bourder,lower_bourder,max_angleConfig)

                pathTOdata = joinpath(path_data,"optda($(θx),$(θz)).jld2")

                @save pathTOdata sol_dict


                path = joinpath(@__DIR__,"data\\current_obj.jld2")

                @load path steering obj

                pathTOdata = joinpath(path_data,"optda_min($(θx),$(θz)).jld2")

                @save pathTOdata steering obj
            end   
        end
    end 
end
