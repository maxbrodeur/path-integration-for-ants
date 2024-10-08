module RandomTrajectory

    using Distributions
    using Plots
    # using Images

    function random_trajectory(
                speed::Real=1.0, # speed of the ant (m/s) (if 1, then the ant moves 1m in 1000ms)
                T::Real=1000,  # total time of trajectory (ms)
                delta_t::Real=0.1, # time step (ms)
                volatility::Real=1.0,
    )
        n = Int64(round(T/delta_t))
        pos = zeros(Float64, (n+1, 2))
        angles = zeros(Float64, n+1)
        angles[1] = pi
        for i in range(1, length=n)
            angles[i+1] = rand(Normal(angles[i], volatility)) % (2*pi)
            if angles[i+1] < 0
                angles[i+1] += 2*pi
            end
            pos[i+1, :] = pos[i, :] + speed *  delta_t * [cos(angles[i+1]), sin(angles[i+1])]
        end
        return angles, pos
    end

    function plot_trajectory(
                pos_x::Array,
                pos_y::Array;
                label::Union{Bool, String} = false,
                start_end_labels::Bool = true,
                color::Symbol = :blue,
                alpha::Real = 1.0
                )
            
        p = plot!(pos_x, pos_y, color = color, lw = 2, label = label, alpha = alpha)
        label = start_end_labels ? "home" : ""
        scatter!([pos_x[1]], [pos_y[1]], color = :Green, label = label, ms = 7)
        label = start_end_labels ? "ant" : ""
        scatter!([pos_x[end]], [pos_y[end]], color = :Red, label = label, ms = 7)
        xlabel!("x")
        ylabel!("y")
        return p
    end

    export random_trajectory

end 