
function new_particle()
    local newObject = {}
	newObject.curPosition = {}  --::Dict{String, Float64}
	newObject.curVelocities = {}  --::Dict{String, Float64}
	newObject.err = 1E40
	newObject.bestPosition = {}  --::Dict{String, Float64}
	newObject.bestError = 1E40
    return newObject
end


function new_param_range()
    local newObject = {}
	newObject.lower = 0.0
	newObject.upper = 0.0
    return newObject
end


function new_globals()
    local newObject = {}
	newObject.var_limits = {}  --::Dict{String,param_range}
	newObject.w = 0.8
	newObject.phi_1 = 1.494
	newObject.phi_2 = 1.494
	newObject.tolerance = 0.0
	newObject.iter_limit = 0.0
	newObject.swarmsize = 0.0
    return newObject
end


function new_optimizerControl()
    local newObject = {}
	newObject.globalBestPosition = {}  --::Dict{String,Float64}
	newObject.globalBestError = 1E40
    return newObject
end

newmodule = {}
newmodule.new_particle = new_particle
newmodule.new_param_range = new_param_range
newmodule.new_globals = new_globals
newmodule.new_optimizerControl = new_optimizerControl
return newmodule
