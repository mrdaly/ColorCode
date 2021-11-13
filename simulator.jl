include("ColorCode.jl")

function simulate(str,outFileName)
  assignment = Dict([(k,rand(1:2)) for k in keys(keyboardStrings)])

  prior = Dict{Symbol,Float64}([letter => 1.0/nChoices for letter in keys(keyboardStrings)])
  belief = Belief(prior,9,1)
  certaintyThreshold = 0.95

  for c in str

  end
end


if length(ARGS) != 2
    error("usage: julia simulator.jl <infile>.txt <outfile>.out")
end

inputfilename = ARGS[1]
outputfilename = ARGS[2]

open(inputfilename) do f
  str = chomp(uppercase(read(f,String)))
  simulate(str,outputfilename)
end
