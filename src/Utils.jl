module Utils
    using Statistics
    using BumpAttractorUtils
    using Plots, LaTeXStrings

    function split_into_segments(data::Array, tol::Real)
        diff_data = diff(data)
        diff_data = abs.(diff_data)
        tol = mean(diff_data) * tol
        idx = findall(x -> x > tol, diff_data)
        
        if length(idx) == 0
            return [data]
        end
        
        segments = []
        last_index = 1
        for i in eachindex(idx)
            push!(segments, data[last_index:idx[i]])
            last_index = idx[i] + 1
        end
        push!(segments, data[last_index:end])
        return segments
    end 

    function smooth(data::Array, window_size::Int)
        smoothed = similar(data)
        half_window = Int(floor(window_size/2))
        for i in eachindex(data)
            if i <= half_window || i >= length(data) - half_window 
                smoothed[i] = data[i]
            else
                smoothed[i] = mean(data[i-half_window:i+half_window])
            end
        end
        return smoothed
    end

    function raster_plot(
            spikes::Array, 
            sp::SimulationParameters, 
            np::NetworkParameters; 
            title::Union{LaTeXString, String}=""
        )
        return heatmap(
            transpose(spikes), 
            title=title, 
            xlabel=L"t"*" (ms)", 
            ylabel= "Neuron Location", 
            c = reverse(cgrad(:grayC)), 
            colorbar=false, 
            right_margin = 3Plots.mm, 
            left_margin = 2Plots.mm, 
            yticks = (
                range(start = 0, stop = np.N , length =5), 
                [L"0", L"\frac{\pi}{2}", L"\pi", L"\frac{3\pi}{2}", L"2 \pi"]
            ), 
            xticks = (
                Int.(round.(range(0, size(spikes, 1), length=11))), 
                # range the xticks from 0 to T with 10 ticks on multiples of 10
                Int.(round.(range(0, sp.T, length=11)))
            ),
            grid = false
        )
    end

    function spikes_to_average_bump_location(
        spikes::Array, 
        x_i::Array, 
        bin_size::Int, 
        sp::SimulationParameters
    )
        bin_length = Int64(bin_size/sp.delta_t)
        (n, N) = size(spikes)
        n = n - 1

        bump_location = locate_bump.(eachrow(spikes), Ref(x_i))
        bump_location_bins = transpose(reshape(bump_location[1:n], bin_length, Int((n)/bin_length)))
        avg_bump_location = locate_bump_avg.(Ref(ones(bin_length)), eachrow(bump_location_bins))
        
        bump_location = locate_bump.(eachrow(spikes), Ref(x_i))
        bump_location_bins = transpose(reshape(bump_location[1:sp.n], bin_length, Int((sp.n)/bin_length)))
        avg_bump_location = locate_bump_avg.(Ref(ones(bin_length)), eachrow(bump_location_bins))
        return avg_bump_location
    end

    function plot_angle_location(
        angles::Array, 
        N::Int;
        color::Symbol=:black, 
        label::Union{LaTeXString, String, Bool}=false,
        tol::Real = 50
    )
        angles = map_angle_to_idx.(angles, N)
        n = length(angles)
        plot_segments(collect(0:n), angles, color=color, label=label, tol = tol)
    end

    function plot_avg_bump_location(
        spikes::Array, 
        x_i::Array, 
        bin_size::Int, 
        sp::SimulationParameters,
        np::NetworkParameters;
        color::Symbol=:orange,
        label::Union{LaTeXString, String, Bool}=false,
        tol::Real=10
    )
        bin_length = Int64(bin_size/sp.delta_t)
        (n, N) = size(spikes)
        n = n - 1

        bump_location = locate_bump.(eachrow(spikes), Ref(x_i))
        bump_location_bins = transpose(reshape(bump_location[1:n], bin_length, Int((n)/bin_length)))
        avg_bump_location = locate_bump_avg.(Ref(ones(bin_length)), eachrow(bump_location_bins))
    
        avg_bump_location = map_angle_to_idx.(avg_bump_location, N)
        n = length(avg_bump_location)
        x = collect(0:bin_length:n*bin_length)
        plot_segments(x, avg_bump_location, color=color, label=label, tol=tol)
    end

    map_angle_to_idx(angle, N) = Int(floor(angle/(2*pi) * N)) + 1

    function plot_segments(x::Array, y::Array; color::Symbol=:black, label::Union{LaTeXString, String, Bool}=false, tol::Real=50, xlabel="", ylabel="")
        segments = split_into_segments(y, tol)
        count = 1
        for segment in segments
            new_n = count + length(segment)-1
            label = count == 1 ? label : false
            plot!(x[count:new_n], segment, label=label, color=color, lw=1, grid=false)
            count = new_n + 1
        end
        xlabel!(xlabel)
        ylabel!(ylabel)
    end
end