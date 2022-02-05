using Statistics
using Plots
include("ColorCode.jl")

function simulate(str,error_rate)
  assignment = Dict([(k,1) for k in keys(keyboardStrings)])

  lmModel = LM.getModel()
  lmState = LM.getStartState(lmModel)
  prior = getPrior(lmModel,lmState)
  belief = Belief(prior,9,1)
  history = BeliefHistory()
  certaintyThreshold = 0.95
  #huffmanTree = changeAssignment(belief,assignment)
  changeAssignment(belief,assignment)

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
      newCommString = chooseLetter(belief,commString,certaintyThreshold,history,lmModel,lmState)
      #huffmanTree = color == 1 ? huffmanTree.red : huffmanTree.blue
      #huffmanTree = length(newCommString) != length(commString) ? nothing : huffmanTree
      #huffmanTree = changeAssignment(belief,assignment,huffmanTree)
      changeAssignment(belief,assignment)
      if length(newCommString) != length(commString)
        new_letter = nothing
        if length(newCommString) > length(commString)
          new_letter = newCommString[end] == ' ' ? :SPACE : Symbol(newCommString[end])
          #print("selected: $(new_letter), click count: $(clickCount)\n")
        end
        #length(newCommString) < length(commString) ? print("selected: $(letter), click count: $(clickCount)\n") : nothing
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
  LM.releaseModel(lmModel)
  LM.releaseState(lmState)
  clicksPerChar = totalClicks/length(str)
  print("error_rate=$(error_rate), average clicks per letter: $(clicksPerChar)\n")
  return clicksPerChar
end

function simulate(str)
  h2(x) = x*log(2,1/x) + (1-x)*log(2,1/(1-x))
  #error_rates = 0.01:0.01:0.2
  error_rates = 0.01:0.01:0.45
  base = simulate(str,0)
  p1 = plot(x->1/((1-h2(x))/base),xlim=[0 0.5],legend=false,xticks=error_rates,yticks=0:0.5:35,minorgrid=true)
  gui()
  results = []
  for r in error_rates
    res = simulate(str,r)
    push!(results,res)
    plot!(p1,[r],[res],seriestype=:scatter)
    gui()
  end
  print("results: \n")
  print(results)

  p2 = plot(x->1-h2(x),xlim=[0 0.5],xticks=0:0.05:0.5,yticks=0:0.1:1.0,minorgrid=true)
  i = base ./ results
  plot!(p2,error_rates,i,seriestype=:scatter)
  gui(p2)
  wait()
end


if length(ARGS) != 2 && length(ARGS) != 1
    error("usage: julia simulator.jl <infile>.txt <error_rate>")
end

inputfilename = ARGS[1]
error_rate = nothing
if length(ARGS) == 2
  error_rate = parse(Float64,ARGS[2])
end

open(inputfilename) do f
  str = chomp(uppercase(read(f,String)))
  if !isnothing(error_rate)
    simulate(str,error_rate)
  else
    simulate(str)
  end
end
