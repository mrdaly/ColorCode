using Statistics
include("ColorCode.jl")

function simulate(str,error_rate)
  assignment = Dict([(k,1) for k in keys(keyboardStrings)])

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
      if rand() < error_rate
        button = assignment[sym]==1 ? 2 : 1
      else
        button = assignment[sym]
      end
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


if length(ARGS) != 2
    error("usage: julia simulator.jl <infile>.txt <error_rate>")
end

inputfilename = ARGS[1]
error_rate = parse(Float64,ARGS[2])

open(inputfilename) do f
  str = chomp(uppercase(read(f,String)))
  simulate(str,error_rate)
end
