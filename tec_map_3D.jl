using TEC_viz
using Dates
using GeoMakie
using GLMakie
using HDF5

## Extract the data
filename = joinpath("data", "gps150317g.004.hdf5")
fid = h5open(filename, "r")
data = read(fid)
close(fid)

lat = data["Data"]["Array Layout"]["gdlat"]
lon = data["Data"]["Array Layout"]["glon"]
timestamps = data["Data"]["Array Layout"]["timestamps"]
tec = data["Data"]["Array Layout"]["2D Parameters"]["tec"]
dtec = data["Data"]["Array Layout"]["2D Parameters"]["dtec"]



## Plot 3D Earth
n = 1024 ÷ 1 # 2048
θ = LinRange(0, π, n)
φ = LinRange(0, 2π, 2 * n)
x = [cos(φ) * sin(θ) for θ in θ, φ in φ]
y = [sin(φ) * sin(θ) for θ in θ, φ in φ]
z = [cos(θ) for θ in θ, φ in φ]

fig = Figure(size = (1000, 800), backgroundcolor = :grey80)
ax = LScene(fig[1, 1], show_axis = false)
surface!(ax, x, y, z;
    color = GeoMakie.earth(),
    shading = NoShading,
    )
rotate_cam!(ax.scene, (deg2rad(-40), deg2rad(150), 0))  # point on Svalbard
zoom!(ax.scene, 0.6)

# Initialize Observables
tec_points = tec[1, :, :]
good_idx = findall(!isnan, tec_points)
good_lon = Observable([lon[i[1]] for i in good_idx])
good_lat = Observable([lat[i[2]] for i in good_idx])
good_tec = Observable(tec_points[good_idx])
# Switch to cartesian coordinates
positions = Observable(toCartesian.(good_lon[], good_lat[], 100))

# Plot the tec points
sc1 = scatter!(ax, positions; color = good_tec, colormap = :plasma,
               colorrange = (0, 40), depthsorting = true,)
Colorbar(fig[1, 2], sc1; label = "TEC units", tellheight = false)

# Add nightshade
nightshade_lon = Observable(night_shade(timestamps[1])[2])
θ_shade = LinRange(0, π, 360)
φ_shade = Observable(LinRange(deg2rad(nightshade_lon[][1]), deg2rad(nightshade_lon[][end]), 360))
x_shade = Observable([cos(φ) * sin(θ) for θ in θ_shade, φ in φ_shade[]] .* (1 + 200/6500))
y_shade = Observable([sin(φ) * sin(θ) for θ in θ_shade, φ in φ_shade[]] .* (1 + 200/6500))
z_shade = Observable([cos(θ) for θ in θ_shade, φ in φ_shade[]] .* (1 + 200/6500))
surface!(ax, x_shade, y_shade, z_shade; color = fill((:black, 0.4), (180, 180)),
         shading = NoShading)

# Add a title
title_text = Observable(string(unix2datetime(timestamps[1])))
Label(fig[0, 1], title_text; tellwidth = false, fontsize = 20)




# Make a function to update the data points
function update_plot!(i_t, nightshade_lon, tec, good_tec, timestamps, φ_shade, x_shade,
                      y_shade, z_shade)
    # update the tec points
    local tec_points = tec[i_t, :, :]
    local good_idx = findall(!isnan, tec_points)
    good_lon.val = [lon[i[1]] for i in good_idx]
    good_lat.val = [lat[i[2]] for i in good_idx]
    positions.val = toCartesian.(good_lon[], good_lat[], 100)
    good_tec[] = tec_points[good_idx]
    notify(positions)

    # update the nightshade
    _, nightshade_lon[] = night_shade(timestamps[i_t])
    φ_shade[] = LinRange(deg2rad(nightshade_lon[][1]), deg2rad(nightshade_lon[][end]), 360)
    x_shade[] = [cos(φ) * sin(θ) for θ in θ_shade, φ in φ_shade[]] .* (1 + 200/6500)
    y_shade[] = [sin(φ) * sin(θ) for θ in θ_shade, φ in φ_shade[]] .* (1 + 200/6500)
    z_shade[] = [cos(θ) for θ in θ_shade, φ in φ_shade[]] .* (1 + 200/6500)

    # update the title
    title_text[] = string(unix2datetime(timestamps[i_t]))
    return nothing
end

# Add slider to control time
time_slider = Slider(fig[2, 1], range = 1:length(timestamps), startvalue = 1, width = Relative(0.8))
on(time_slider.value) do i_t
    update_plot!(i_t, nightshade_lon, tec, good_tec, timestamps, φ_shade, x_shade,
                 y_shade, z_shade)
end

# Add button to start the animation
fig[3, :] = buttongrid = GridLayout(; tellwidth = false)
run = buttongrid[1, 1] = Button(fig; label = "Play/Pause", tellwidth = false)
i_t = Observable(1)
isrunning = Observable(false)
on(run.clicks) do clicks
    isrunning[] = !isrunning[]
    i_t[] = time_slider.value[]
    @async while isrunning[]
        i_t[] < length(timestamps) ? i_t[] += 1 : i_t[] = 1 # take next time step and loop when t_max is reached
        isopen(fig.scene) || break # ensures animation stops if the figure is closed
        set_close_to!(time_slider, i_t[])
        sleep(0.05)
        # This is in case the user drags the slider at the same time.
        # In that case, the animation continues from the new slider position
        i_t[] = time_slider.value[]
    end
end


# Display the figure
# display(fig)
display(fig, update = false) # this is to avoid our camera zoom to be reset
