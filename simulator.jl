using Statistics
include("ColorCode.jl")

function simulate(str,error_rate)
  assignment = Dict([(k,1) for k in keys(keyboardStrings)])

  prior = getPrior()
  belief = Belief(prior,9,1)
  history = BeliefHistory()
  certaintyThreshold = 0.95
  changeAssignment(belief,assignment,certaintyThreshold)

  letters = Stack{Symbol}()
  foreach(c->push!(letters,c==' ' ? :SPACE : Symbol(c)), reverse(str))
  commString = ""
  totalClicks = 0.0
  print("starting simulate\n")
  while !isempty(letters)
    letter = pop!(letters)
    clickCount = 0.0
    while true
      if rand() < error_rate
        color = assignment[letter]==1 ? 2 : 1
      else
        color = assignment[letter]
      end
      clickCount += 1.0
      updateBelief(belief,color,assignment)
      newCommString = chooseLetter(belief,commString,certaintyThreshold,history)
      changeAssignment(belief,assignment,certaintyThreshold)
      if length(newCommString) != length(commString)
        new_letter = nothing
        if length(newCommString) > length(commString)
          new_letter = newCommString[end] == ' ' ? :SPACE : Symbol(newCommString[end])
          print("selected: $(new_letter), click count: $(clickCount)\n")
        end
        length(newCommString) < length(commString) ? print("selected: $(letter), click count: $(clickCount)\n") : nothing
        commString = newCommString
        if !isnothing(new_letter) && new_letter != letter
          push!(letters,letter)
          push!(letters,:UNDO)
        end
        break
      end
    end
    totalClicks += clickCount
  end
  print("average clicks per letter: $(totalClicks/length(str)))\n")
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
