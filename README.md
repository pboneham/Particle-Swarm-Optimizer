# Particle-Swarm-Optimizer
This program is copyright Paul Boneham and made available under the GPL V3.

This repository contains a Lua script which will perform a particle swarm optimization on a
commandline program. The optimizer needs a stable interface to call the commandline program
but an arbitary program could be called in many different ways, i.e, its arguments could be
different to those expected by the optimizer - this problem is solved by the use of an "adaptor"
script, which is called using the standard interface and then calls the underlying program according 
to its own interface.

The swarm optimizer is used as follows (it can be called using lua, or the faster JIT version, luajit):

`code`
luajit swarmoptmizer [--optimizer_iterations <optimizer_iterations>]
       [--optimizer_swarmsize <optimizer_swarmsize>]
       [--optimizer_tolerance <optimizer_tolerance>]
       [--base_infile <base_infile>] [--refcurve <refcurve>]
       [--script_engine <script_engine>] [--adaptor <adaptor>]
       [--param_ranges <param_ranges>] [-h]
`code`

A particle swarm optimizer which can be set up to optimize any program

Options:
   --optimizer_iterations <optimizer_iterations>
                         Sets max number of iterations for swarm solver
   --optimizer_swarmsize <optimizer_swarmsize>
                         Sets swarm size if swarm optimization performed
   --optimizer_tolerance <optimizer_tolerance>
                         Sets tolerance for ending optimization if swarm optimization performed
   --base_infile <base_infile>
                         Name of base case input file for adaptor program
   --refcurve <refcurve> File containing reference curve to fit to
   --script_engine <script_engine>
                         name of script engine to use with adaptor, if any (default: )
   --adaptor <adaptor>   name of adaptor program that wraps program to optimize
   --param_ranges <param_ranges>
                         Name of JSON file that specifies ranges (default: none)
   -h, --help            Show this help message and exit.

By way of additional explanation of some of the commandline arguments:

The base_infile is expected to be a JSON formatted file containing all the input variables and values.
This base input file will contain (1) variables and their values that are constant in every optimizer 
iteration and particle, and (2) variables whose values will be varied during the optimizer run. In other
words, the base_infile variables may be constants or variables that change to achieve the optimization. The latter
(the changing variables) are specified in a later commandline argument.

The ref_curve is a file in any format (has to be compatible with your program specific adaptor script) which is
used to compare to the results (output) of each particle run (each call to the commandline program). The adaptor
script should calculate a single error value as a result of comparing the "ref_curve" to the program output each
time a particle is quantified.

script_engine is the name of the script interpreter used to run the adpator script. Can be blank, in which case
the adaptor program needs to be executable.

adaptor is the program or script used to wrap the actual program being optimized. The user needs to write this adaptor.
The adaptor gives a standard interface for the optimizer to call the program being optimized. Using a lua script as an
example of how the adaptor is called (i.e., case where script_engine is luajit or lua), an example of how the adaptor 
would be called by the optimizer is given below:

    luajit adaptor_name.lua --refcurve       <filename> 
                            --base_infile    <base infile name as given to optimizer>
                            --outfile        <a filename for particle run output, this name set internally by optimizer>
                            --particle_data  <json file with particle data, to overlay on input file>

The user needs to understand the above in order to be able to write a working adaptor script.

param_ranges is a JSON file which gives a variable names whose values the optimizer will vary to find the best values, and lower and upper values 
that define the range of variation for these variables.
