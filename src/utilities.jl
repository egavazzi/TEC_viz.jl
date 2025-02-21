using AstroLib
using Dates

function toCartesian(lon, lat, alt; cxyz = (0, 0, 0))
    x = cxyz[1] + (alt/6500 + 1) * cosd(lat) * cosd(lon+180)
    y = cxyz[2] + (alt/6500 + 1) * cosd(lat) * sind(lon+180)
    z = cxyz[3] + (alt/6500 + 1) * sind(lat)
    return (x, y, z)
end

function night_shade(unixtime)
    # This is a simplified model of the nightshade on Earth surface.
    # It is assuming that Earth rotation axis is not tilted.
    zen_lon, _ = zenpos(unix2datetime(unixtime), 0, 0, 0)
    zen_lon = rad2deg(zen_lon)
    midnight_lon = 180 - zen_lon
    nightshade_lon = (midnight_lon - 90):(midnight_lon + 90)

    return midnight_lon, nightshade_lon
end
