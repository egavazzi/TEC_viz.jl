using TEC_viz
using Dates
using GeoMakie
using GLMakie
using HDF5


## Extract the data
filename = joinpath("data", "gps150317g.004.hdf5")
# filename = joinpath(@__DIR__, "data", "gps131107g.004.hdf5")
fid = h5open(filename, "r")
data = read(fid)
close(fid)

lat = data["Data"]["Array Layout"]["gdlat"]
lon = data["Data"]["Array Layout"]["glon"]
timestamps = data["Data"]["Array Layout"]["timestamps"]
tec = data["Data"]["Array Layout"]["2D Parameters"]["tec"]
dtec = data["Data"]["Array Layout"]["2D Parameters"]["dtec"]



## Plot
# Prepare the figure and axis
fig = Figure(; size = (1500, 900))
ax1 = GeoAxis(fig[1, 1]; dest = "+proj=ortho +lat_0=90", xticks = 0:60:360,
              yticks = 0:15:90,
              xticklabelsvisible = false, yticklabelsvisible = false)
ax2 = GeoAxis(fig[1, 3]; dest = "+proj=ortho +lat_0=-90", xticks = 0:60:360,
              yticks = 0:-15:-90,
              xticklabelsvisible = false, yticklabelsvisible = false)
# Plot the coastlines and terrain
l1 = lines!(ax1, GeoMakie.coastlines(); color = :black)
l2 = lines!(ax2, GeoMakie.coastlines(); color = :black)
translate!(l1, 0, 0, 1) # put the coastlines over everything
translate!(l2, 0, 0, 1) # put the coastlines over everything
earth1 = surface!(ax1, -180 .. 180, 0 .. 90, zeros(180, 360);
                  color = rotr90(GeoMakie.earth()[1:180, :]))
earth2 = surface!(ax2, -180 .. 180, -90 .. 0, zeros(180, 360);
                  color = rotr90(GeoMakie.earth()[181:end, :]))
translate!(earth1, 0, 0, -1) # put the terrain under everything
translate!(earth2, 0, 0, -1) # put the terrain under everything
# Initialize Observables
tec_points = tec[1, :, :]
good_idx = findall(!isnan, tec_points)
good_lon = Observable([lon[i[1]] for i in good_idx])
good_lat = Observable([lat[i[2]] for i in good_idx])
good_tec = Observable(tec_points[good_idx])
# Plot the tec points
sc1 = scatter!(ax1, good_lon, good_lat; color = good_tec, colormap = :inferno,
               colorrange = (0, 30))
            #    colorrange = (-1, 10))
sc2 = scatter!(ax2, good_lon, good_lat; color = good_tec, colormap = :inferno,
               colorrange = (0, 30))
            #    colorrange = (-1, 10))
# Add a colobar
Colorbar(fig[1, 2], sc1; label = "TEC units", tellheight = false,
         height = @lift Fixed($(pixelarea(ax1.scene)).widths[2]))
Colorbar(fig[1, 4], sc2; label = "TEC units", tellheight = false,
         height = @lift Fixed($(pixelarea(ax1.scene)).widths[2]))
# Add a shade over the night side of Earth
nightshade_lon = Observable(night_shade(timestamps[1])[2])
surface!(ax1, nightshade_lon, 0 .. 90, ones(30, 15); color = fill((:black, 0.3), 30, 15))
surface!(ax2, nightshade_lon, -90 .. 0, ones(30, 15); color = fill((:black, 0.3), 30, 15))
# Rotate Earth so that the zenith is at the "top"
midnight_lon = Observable(night_shade(timestamps[1])[1])
ax1.dest[] = "+proj=ortho +lat_0=90 +lon_0=$(midnight_lon[])"
ax2.dest[] = "+proj=ortho +lat_0=-90 +lon_0=$(180+midnight_lon[])"
# Add a title
ax1.title = string(unix2datetime(timestamps[1]))
ax1.titlesize = 20


# Make a function to update the data points
function update_plot!(i_t, ax1, ax2, midnight_lon, nightshade_lon, tec, good_tec,
                      timestamps)
    # update the Sun pointing direction and the nightshade accordingly
    midnight_lon[], nightshade_lon[] = night_shade(timestamps[i_t])
    ax1.dest[] = "+proj=ortho +lat_0=90 +lon_0=$(midnight_lon[])"
    ax2.dest[] = "+proj=ortho +lat_0=-90 +lon_0=$(180+midnight_lon[])"
    # update the tec points
    local tec_points = tec[i_t, :, :]
    local good_idx = findall(!isnan, tec_points)
    good_lon.val = [lon[i[1]] for i in good_idx]
    good_lat.val = [lat[i[2]] for i in good_idx]
    good_tec[] = tec_points[good_idx]
    notify(good_lon)
    notify(good_lat)
    # update the title
    ax1.title = string(unix2datetime(timestamps[i_t]))
    return nothing
end

# Add slider to control time
time_slider = Slider(fig[2, :], range = 1:length(timestamps), startvalue = 1, width = Relative(0.8))
on(time_slider.value) do i_t
    update_plot!(i_t, ax1, ax2, midnight_lon, nightshade_lon, tec, good_tec, timestamps)
end

# Add button to launch the animation
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

# Finally display the figure
display(fig)



## That's to animate and save
video_file = joinpath(@__DIR__, "animations", "tec_map_20150317_new_smaller.mp4")
record(fig, video_file, 1:length(timestamps); px_per_unit = 1, framerate = 15) do i_t
    set_close_to!(time_slider, i_t[])
end
