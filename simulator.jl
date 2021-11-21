using Statistics
include("ColorCode.jl")

function simulate(str)
  assignment = Dict([(k,1) for k in keys(keyboardStrings)])

  nChoices = length(keyboardStrings)
  #prior = OrderedDict{Symbol,Float64}([letter => 1.0/nChoices for letter in keys(keyboardStrings)])
  prior = getPrior("")
  belief = Belief(prior,99,1)
  changeAssignment(belief,assignment)
  certaintyThreshold = 0.95

  commString = ""
  counts = Vector()
  for c in str
    clickCount = 0
    while true
      sym = c == ' ' ? :SPACE : Symbol(c)
      button = assignment[sym]
      clickCount += 1
      updateBelief(belief,button,assignment)
      changeAssignment(belief,assignment)
      newCommString = chooseLetter(belief,commString,certaintyThreshold)
      if length(newCommString) > length(commString)
        commString = newCommString
        break
      end
    end
    print("letter: $(c) clicks: $(clickCount)\n")
    append!(counts, clickCount)
  end
  print("average: $(mean(counts))\n")
end


if length(ARGS) != 1
    error("usage: julia simulator.jl <infile>.txt")
end

inputfilename = ARGS[1]

open(inputfilename) do f
  str = chomp(uppercase(read(f,String)))
  simulate(str)
end
