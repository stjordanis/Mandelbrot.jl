using ProgressMeter
using Plots

function δz(dzr, dzi, size = 3)
    res = zeros(Complex{Float64}, size, size)
    offset = floor(Int, size / 2) + 1
    for j = 1:size
        for i = 1:size
            res[i, j] = im * (i - offset) * dzi + (j - offset) * dzr
        end
    end
    return res
end


function computePatch(
    cr::T,
    ci::T,
    dx,
    dy,
    maxIter = 1000,
    patchSize = 3,
) where {T<:AbstractFloat}
    zr = zero(T)
    zi = zero(T)
    c = complex(cr, ci)
    z = complex(zr, zi)
    z_arr = zeros(Complex{T}, maxIter)
    ε_arr = zeros(Complex{Float64}, patchSize, patchSize, maxIter + 1)
    # A_arr = zeros(Complex{Float64}, maxIter+1)
    # A_arr[1] = 1
    # B_arr = zeros(Complex{Float64}, maxIter+1)
    # B_arr[1] = 0
    # C_arr = zeros(Complex{Float64}, maxIter+1)
    # C_arr[1] = 0

    A = 1
    B = 0
    C = 0

    δ = δz(dx, dy, patchSize)
    δ2 = δ .^ 2
    δ3 = δ .^ 3

    result = zeros(patchSize, patchSize)
    for i = 1:(maxIter-1)
        two_z_f = 2 * z_arr[i]
        C = two_z_f * C + 2 * A * B
        B = two_z_f * B + A^2
        A = two_z_f * A + 1
        ε_arr[:, :, i+1] .= A .* δ + B .* δ2 + C .* δ3

        z = z^2 + c
        z_arr[i+1] = convert(Complex{Float64}, z)
    end

    for j = 1:patchSize
        for i = 1:patchSize
            for iter = 1:(maxIter-1)
                zprime = z_arr[iter] + ε_arr[i, j, iter]
                if abs(zprime) > 2
                    result[i, j] = iter
                    break
                end
            end
        end
    end

    return result
end

#%%
xmin = -2.2
xmax = 0.8
ymin = -1.2
ymax = 1.2

dx = (xmax-xmin)/1920
dy = (ymax-ymin)/1080

x_arr = range(xmin+dx, xmax-dx, step=3*dx)
y_arr = range(ymin+dy, ymax-dy, step=3*dy)

image = zeros(1080,1920)
#%%
@showprogress for (j,x) in enumerate(x_arr)
    for (i,y) in enumerate(y_arr)
        image[(i*3-2):i*3, (j*3-2):j*3] = computePatch(x,y,dx,dy,100,3)
    end
end
#%%
heatmap(image)