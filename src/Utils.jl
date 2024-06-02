module Utils
    using Statistics
    using BumpAttractorUtils
    using Plots, LaTeXStrings

    function split_into_segments(data::Array, tol::Real)
        diff_data = diff(data)
        diff_data = abs.(diff_data)
        tol = mean(diff_data) * tol
        println(tol)
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

    function raster_plot(spikes::Array, sp::SimulationParameters, np::NetworkParameters)
        return heatmap(
                transpose(spikes), 
                title="Network Activity", 
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
                    Int.(0:sp.n/5:sp.n), 
                    Int.(0:sp.T/5:sp.T)
                )
            )
    end

    function spikes_to_average_bump_location(spikes::Array, x_i::Array, bin_size::Int, sp::SimulationParameters)
        bin_length = Int64(bin_size/sp.delta_t)
        bump_location = locate_bump.(eachrow(spikes), Ref(x_i))
        bump_location_bins = transpose(reshape(bump_location[1:sp.n], bin_length, Int((sp.n)/bin_length)))
        avg_bump_location = locate_bump_avg.(Ref(ones(bin_length)), eachrow(bump_location_bins))
        return avg_bump_location
    end

    function plot_angle_location(
        angles::Array, 
        N::Int;
        color::Symbol=:black, 
        label::Union{LaTeXString, String, Bool}=false
    )
        angles = map_angle_to_idx.(angles, N)
        n = length(angles)
        plot_segments(0:n, angles, color=color, label=label)
    end

    function plot_avg_bump_location(
        spikes::Array, 
        x_i::Array, 
        bin_size::Int, 
        sp::SimulationParameters,
        np::NetworkParameters;
        color::Symbol=:orange,
        label::Union{LaTeXString, String, Bool}=false
    )
        bin_length = Int64(bin_size/sp.delta_t)
        bump_location = locate_bump.(eachrow(spikes), Ref(x_i))
        bump_location_bins = transpose(reshape(bump_location[1:sp.n], bin_length, Int((sp.n)/bin_length)))
        avg_bump_location = locate_bump_avg.(Ref(ones(bin_length)), eachrow(bump_location_bins))
        
        avg_bump_location = map_angle_to_idx.(avg_bump_location, np.N)
        n = length(avg_bump_location)
        x = collect(0:bin_length:n*bin_length)
        plot_segments(x, avg_bump_location, color=color, label=label)
    end

    map_angle_to_idx(angle, N) = Int(floor(angle/(2*pi) * N)) + 1

    function plot_segments(x::Array, y::Array; color::Symbol=:black, label::Union{LaTeXString, String, Bool}=false, tol::Real=50)
        segments = split_into_segments(y, tol)
        count = 1
        for segment in segments
            new_n = count + length(segment)-1
            label = count == 1 ? label : false
            plot!(x[count:new_n], segment, label=label, color=color, lw=1)
            count = new_n + 1
        end
    end
end