-- output filter
local argparse = require "argparse"
local json = require "json"

local CMD = "python3 globalWarmingModel.py --json "

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


function main()
    local parser = argparse("adaptor", "Adaptor script that communicates using a standard interface to a particle swarm optimizer")

    local cmdline = CMD
    parser:option("--refcurve", "File containing reference curve to fit to")
    parser:option("--base_infile", "Baseline input file for this run")
    parser:option("--outfile", "output file - JSON file where the error result is placed")    
    parser:option("--particle_data", "json file with particle data, to overlay on input file")
    local args = parser:parse()
    
    local id = tostring(math.random())
    id = string.sub(id,3,8)
    local outfile = "particle_run_out_" .. id .. ".json"
    local infile = "particle_run_in_" .. id .. ".json"
    
    local input_data = readfile(args.base_infile)
    input_data = json.decode(input_data)
    
    local particle_data = readfile(args.particle_data)
    particle_data = json.decode(particle_data)
    
    for param_name, param_value in pairs(particle_data) do
        input_data[param_name] = param_value                 -- program specific code
    end
    local f = io.open(infile,"w")
    f:write(json.encode(input_data))
    f:close()
    
    local precmd = "echo { \\\"err\\\" : > " .. args.outfile
    os.execute(precmd)
    
    cmdline = cmdline .. infile .. " --ghg_csv " .. args.refcurve .. " >> "  .. args.outfile  --program specific code
    cmdline = cmdline .. " --start_year 1950 --end_year 2005 --init_temp 13.9566"
    local retval = os.execute(cmdline)
    if retval == nil then
        os.exit(nil)
    end
    
    local postcmd = "echo } >> " .. args.outfile
    os.execute(postcmd)
    

end

main()
