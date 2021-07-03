local so = require "swarmopt_structs"
local json = require "json"

--swarmoptimizer params and settings
local W = 0.8
local PHI1 = 1.494
local PHI2 = 1.494
local LOGINTERP = 0  -- Log interpolation not properly tested, not recommended currently to set = 1, better to stay with 0
                     -- Considering future modification of the script to choose different SCALING for different optimized var inputs
                     -- So JSON input file for variable ranges would have a "scaling" setting for each variable

function readfile(fn)
    local f = io.open(fn,"r")
    local s = ""
    while 1==1 do
        local line = f:read()
        if line == nil then
            break
        end
        s = s .. line
    end
    f:close()
    return s
end

-- initialization ------------------------------------------------------------------
function particleInit(p, lims, logInterp)
    for vn, item in pairs(lims) do
	local up = item.upper
	local low = item.lower
        local x
        if logInterp == 1 then
            -- print("Using log interp")
            x = math.random()*((up/low)-1.0)
            p.curPosition[vn] = low * (x+1.0)
        else
            x = math.random()*(up -low)
            p.curPosition[vn] = low + x
        end
		
        p.bestPosition[vn] = p.curPosition[vn]
        if logInterp == 1 then
            p.curVelocities[vn] = (0.5-math.random())*(p.curPosition[vn]-low)*0.1 -- for log interp case, want velocities dependent on
        else                                                                      -- position, so that we don't move away from small value
	    p.curVelocities[vn] = (0.5-math.random())*(up-low)*0.1                -- too quickly
        end
    end
end

function init_optimizer(limits, itmax, tolerance, swarmsize)
	local g = so.new_globals()
	g.iter_limit = itmax
	g.tolerance = tolerance
	g.swarmsize = swarmsize
	for varname, item in pairs(limits) do
		local vn = varname
		g.var_limits[vn] = limits[vn]
	end
	local opt = so.new_optimizerControl()
	local particles = {}
    local logInterp = LOGINTERP
	for i = 1 , g.swarmsize, 1 do
		local p = so.new_particle()
		particleInit(p, limits, logInterp)
		table.insert(particles, #particles+1, p)
	end
	for vn, item in pairs(particles[1].curPosition) do
		opt.globalBestPosition[vn] = item
	end
	
        g.w = W             -- Use values set at top of this file
        g.phi_1 = PHI1      --
        g.phi_2 = PHI2      --

	return g, opt, particles
end


-- ----- Updating -------------------------------------------
function velocities_update(p, coord, opt, g)
	local rnd1 = 0.4 + 0.6 * math.random()
	local rnd2 = 0.4 + 0.6 * math.random()
	local result = p.curVelocities[coord] * g.w;
	result = result + g.phi_1 * rnd1 * (p.bestPosition[coord] - p.curPosition[coord])
	result = result + g.phi_2 * rnd2 * (opt.globalBestPosition[coord] - p.curPosition[coord])
	return result
end

function move(p, lims)
	for varname, item in pairs(p.curPosition) do
		p.curPosition[varname] = p.curPosition[varname] + p.curVelocities[varname]
		if p.curPosition[varname] < lims[varname].lower then
			p.curPosition[varname] = lims[varname].lower
                        p.curVelocities[varname] = 0.0
		end
		if p.curPosition[varname] > lims[varname].upper then
			p.curPosition[varname] = lims[varname].upper
                        p.curVelocities[varname] = 0.0
		end
	end
end

function recalc(p, opt, adaptor_params)
    for index, value in pairs(opt) do
        print(index," ",value)
    end
    local id = string.sub(tostring(math.random()), 3,9)
    local outfile_name = "particle_error_" .. id .. ".json"
    
    local particle_datafilename = "particle_position_" .. id .. ".json"
    local particle_datafile = io.open(particle_datafilename,"w")
    particle_datafile:write(json.encode(p.curPosition))
    particle_datafile:close()
    
    local cmdline = adaptor_params.script_engine .. " "
    cmdline = cmdline ..  adaptor_params.adaptor .. " "
    cmdline = cmdline ..  " --base_infile " .. adaptor_params.base_infile
    cmdline = cmdline .. " --outfile " .. outfile_name
    cmdline = cmdline .. " --refcurve " .. adaptor_params.refcurve
    cmdline = cmdline .. " --particle_data " .. particle_datafilename
    local retval = os.execute(cmdline)
    if retval == nil then
        print("There was an error")
        os.exit(nil)
    end
    local result_string = readfile(outfile_name)
    local data = json.decode(result_string)
    print("data.err", data.err)
	return data.err
end

function pre_update(particles, opt, g, adaptor_params)
	for junk, p in pairs(particles) do
		-- adjust each particle velocity
		for variable, item in pairs(p.curVelocities) do
			p.curVelocities[variable] = velocities_update(p, variable, opt, g)
		end
	end
end

function update(particles, opt, varlimits, adaptor_params, iter)
	local counter = 1
	for junk, p in pairs(particles) do
		-- move each particle to new position
		-- and recalc
		move(p, varlimits)
		p.err = recalc(p, opt, adaptor_params) -- needs updating
        print("Particle / iteration = " .. counter .. " / " .. iter)
		counter = counter + 1
	end
end

function post_update(particles, opt, g)
	for junk, p in pairs(particles) do
		if p.err < p.bestError then
			p.bestError = p.err
			for vn, item in pairs(p.curPosition) do
				p.bestPosition[vn] = p.curPosition[vn]
			end
		end
		if p.err < opt.globalBestError then
			for varname, item in pairs(p.curPosition) do
				opt.globalBestPosition[varname] = p.curPosition[varname]
			end
			opt.globalBestError = p.err
		end
	end
end


-- function to be called externally, controls the optimization
function swarmopt(varlimits, itmax, tolerance, swarmsize, base_infile,
                                 refcurve, script_engine, adaptor, param_ranges)
	
    local g
    local opt
    local particles
    g, opt, particles = init_optimizer(varlimits, itmax, tolerance, swarmsize)
    local adaptor_params = {}
    adaptor_params.base_infile = base_infile
    adaptor_params.refcurve = refcurve
    adaptor_params.script_engine = script_engine
    adaptor_params.adaptor = adaptor
            
	local optimized = 0
	for iter = 1, g.iter_limit, 1 do
                if iter > 1 then -- don't update velocities on first iteration; can use init velocities
		    pre_update(particles, opt, g)
                end
		update(particles, opt, g.var_limits, adaptor_params, iter)
		post_update(particles, opt, g)
		if opt.globalBestError < g.tolerance then
			optimized = 1
			break
		end
		print("Iteration: ", iter, "   Global best error = ", opt.globalBestError)
	end
	
	if optimized == 0 then
		print("Not optimized")
		for varname, item in pairs(opt.globalBestPosition) do
			print(varname, ":  ", opt.globalBestPosition[varname])
		end
	else
		print()
		print("Optimized")
		for varname, item in pairs(opt.globalBestPosition) do
			print(varname, ":  ", opt.globalBestPosition[varname])
		end
	end
end


function main()
    
    local argparse = require "argparse"
    
    local parser = argparse("swarmoptmizer", "A particle swarm optimizer which can be set up to optimize any program")
    parser:option("--optimizer_iterations", "Sets max number of iterations for swarm solver", 0)
    parser:option("--optimizer_swarmsize", "Sets swarm size if swarm optimization performed", 0)
	parser:option("--optimizer_tolerance", "Sets tolerance for ending optimization if swarm optimization performed", 0.0)
    parser:option("--base_infile", "Name of base case input file for adaptor program")
    parser:option("--refcurve", "File containing reference curve to fit to")
    parser:option("--script_engine", "name of script engine to use with adaptor, if any", "")
    parser:option("--adaptor", "name of adaptor program that wraps program to optimize")
    parser:option("--param_ranges", "Name of JSON file that specifies ranges", "none")

    local args = parser:parse()
    
	local s = readfile(args.param_ranges)
        
	local varlimits = json.decode(s)
	local var_limits = {}
    for key, value in pairs(varlimits) do
        var_limits[key] = so.new_param_range()
        var_limits[key].lower = value.lower
        var_limits[key].upper = value.upper
    end
    math.randomseed(os.time())
    swarmopt(var_limits, args.optimizer_iterations, 
                tonumber(args.optimizer_tolerance), 
                args.optimizer_swarmsize,
                args.base_infile,
                args.refcurve,
                args.script_engine,
                args.adaptor,
                args.param_ranges
                )
	end

main()
