Simple scripts to visualize TEC data from the Madrigal database, in 2D and 3D.

Built using [Makie.jl](https://github.com/MakieOrg/Makie.jl).

# Examples

## 2D
https://github.com/user-attachments/assets/964fbfbe-1378-473e-a5a8-670a16b4664d

## 3D
https://github.com/user-attachments/assets/cc1c27fe-f001-47a8-9b98-33c71ab66ec8


# Installation
1. Install Julia (https://julialang.org/install/)
2. Clone/Download the repository
3. The first time you run the code, you need to initialize your environment. This will install the required packages. Here are some instructions:
    - Move inside the folder where the code was installed, and start Julia
    - From the Julia REPL, activate and instantiate the local environment
    ```julia
    julia> import Pkg
    julia> Pkg.activate(".") # depending on where you are located, you might have to enter a different path
    julia> Pkg.instantiate() # this will install the required packages
    ```
    The next times you want to run the code, you only need to activate the environment.
4. There are different ways to run code in Julia. One of them is to launch scripts from the REPL with the command
    ```
    julia> include("tec_map_2D.jl") # will start the 2D visualization
    julia> include("tec_map_3D.jl") # will start the 3D visualization
    ```

If you have questions/need help, do not hesitate to contact me at  [etienne.gavazzi@uit.no](mailto:etienne.gavazzi@uit.no).