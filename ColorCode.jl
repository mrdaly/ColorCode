using DataStructures
#using DataFrames
#using CSV
#using Distributions

module LM
  using CxxWrap
  @wrapmodule(joinpath("LanguageModel","lib","liblanguageModel.so"))
  #@wrapmodule(joinpath("lib","liblanguageModel.so"))
  function __init__()
    @initcxx
  end
end
#using LM

function modelPrior(prev_letters::String)
  alphabet = "abcdefghijklmnopqrstuvwxyz "
  if length(prev_letters) > 12
    prev_letters = prev_letters[end-11:end]
  end
  prev_letters = lowercase(prev_letters)

  logprobs = LM.modelProbabilities(prev_letters, alphabet)
  #prior = OrderedDict([(k, 10^(LM.languageModel(prev_letters*k))) for k in alphabet])
  prior = OrderedDict([(alphabet[i], 10^(logprobs[i])) for i in 1:length(alphabet)])
  total = sum(values(prior))
  return OrderedDict([(k==' ' ? :SPACE : Symbol(uppercase(k)), v/total) for (k,v) in prior])
end

#=let #change to struct & function 
  counts = Dict([(r[1],r[2]+1) for r in eachrow(Matrix(DataFrame(CSV.File("aac_trigram_counts.csv",header=false))))])
  alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ "
  model = Dict([(a*b,OrderedDict([(c,counts[a*b*c]/sum(counts[a*b*d] for d in alphabet)) for c in alphabet])) for a in alphabet, b in alphabet])
  global function languageModel(prev_letters::String)
    prior = nothing
    if length(prev_letters) == 0
      prior = OrderedDict([(k,sum(model[x*y][k] for x in alphabet for y in alphabet)) for k in alphabet])
      total = sum(values(prior))
      for k in keys(prior)
        prior[k] = prior[k] / total
      end
    elseif length(prev_letters) == 1
      prior = OrderedDict([(k,sum(model[x*prev_letters][k] for x in alphabet)) for k in alphabet])  
      total = sum(values(prior))
      for k in keys(prior)
        prior[k] = prior[k] / total
      end
    else #prev_letters >= 2
      prev_letters = prev_letters[end-1:end]
      prior = model[prev_letters]
    end
    return OrderedDict([(k==' ' ? :SPACE : Symbol(k), v) for (k,v) in prior])
  end
end
=#

keyboardStrings = OrderedDict(:A => "A",
                              :B => "B",
                              :C => "C",
                              :D => "D",
                              :E => "E",
                              :F => "F",
                              :G => "G",
                              :H => "H",
                              :I => "I",
                              :J => "J",
                              :K => "K",
                              :L => "L",
                              :M => "M",
                              :N => "N",
                              :O => "O",
                              :P => "P",
                              :Q => "Q",
                              :R => "R",
                              :S => "S",
                              :T => "T",
                              :U => "U",
                              :V => "V",
                              :W => "W",
                              :X => "X",
                              :Y => "Y",
                              :Z => "Z",
                              :SPACE => "SPACE",
                              :UNDO => "UNDO")

# history of color selections (Int) along with the assignment at the time of selection
ColorSelections = Vector{Tuple{Int,Dict{Symbol,Int}}}

mutable struct Belief
  b::OrderedDict{Symbol,Float64} # belief distribution over all keys
  # these two counts represent beta distribution over user's error rate
  right_color_count::Int # count of how many times the user chose the right color for their letter
  wrong_color_count::Int # count of how many times the user chose the wrong color for their letter
  selections::ColorSelections # history of what colors users chose
end

function Belief(b::OrderedDict{Symbol,Float64},right_color_count::Int,wrong_color_count::Int)
  return Belief(b,right_color_count,wrong_color_count,ColorSelections())
end

BeliefHistory = Vector{Tuple{Symbol,Belief}}

# likelihood - probability of user choosing a color given they want to choose the key l
function colorProbability(color::Int,l::Symbol,belief::Belief,assignment::Dict{Symbol,Int})
  p_right_color = belief.right_color_count / (belief.right_color_count + belief.wrong_color_count)
  if assignment[l] == color
    return p_right_color
  else
    return 1 - p_right_color
  end
end

# probability user will choose a color given our current belief and the current assignment
function colorProbability(color::Int,belief::Belief,assignment::Dict{Symbol,Int})
  return sum(belief.b[l]*colorProbability(color,l,belief,assignment) for l in keys(belief.b))
end

# entropy of user's color choice
function colorEntropy(belief::Belief, assignment::Dict{Symbol,Int})
  p(c) = colorProbability(c,belief,assignment)
  return -sum(p(c)log(2,p(c)) for c in 1:2)
end

function randomAssignments(m)
  assignments = [Dict([l => c for (l,c) in zip(keys(keyboardStrings),digits(n,base=2,pad=28).+1)]) for n in rand(1:((2^27)-1), m)]
end

function updateBelief(belief::Belief, color::Int, assignment::Dict{Symbol,Int})
  push!(belief.selections,(color,copy(assignment)))

  for l in keys(belief.b)
    belief.b[l] = colorProbability(color,l,belief,assignment)*belief.b[l]
  end
  total = sum(values(belief.b))
  map!(x->x/total,values(belief.b))
end

function heuristicPolicy(belief)
  sorted_belief = sort(collect(belief.b),rev=true,by=x->x[2])
  color = 1
  assignment = Dict{Symbol,Int}()
  for (sym,_) in sorted_belief
    assignment[sym] = color
    color = color == 1 ? 2 : 1
  end
  return assignment
end

function entropy_lookahead(belief::Belief,m)
  assignments = randomAssignments(m)
  entropies = Vector(undef,m)
  Threads.@threads for i in 1:m
  #for i in 1:m
    entropies[i] = colorEntropy(belief,assignments[i])
  end
  #entropies = [colorEntropy(belief,a) for a in assignments]
  a = argmax(entropies)
  return assignments[a]
end

function test_entropy_lookahead(belief::Belief,m)
  assignments = randomAssignments(m)
  diffs = Vector(undef,m)
  Threads.@threads for i in 1:m
  #for i in 1:m
  diffs[i] = abs(sum(belief.b[l] for l in keys(belief.b) if assignments[i][l]==1) - sum(belief.b[l] for l in keys(belief.b) if assignments[i][l]==2))
  end
  a = argmin(diffs)
  return assignments[a]
end

struct HuffmanTree
  symbols::Vector{Symbol}
  probability::Float64
  red::Union{Nothing,HuffmanTree}
  blue::Union{Nothing,HuffmanTree}
end

function buildHuffmanTree(nodes::Vector{HuffmanTree})
  if length(nodes) == 1
    return nodes[1]
  end

  sorted_nodes = sort(nodes,by=x->x.probability)
  new_node = HuffmanTree(vcat(sorted_nodes[1].symbols, sorted_nodes[2].symbols),
                         sorted_nodes[1].probability + sorted_nodes[2].probability,
                         sorted_nodes[1], sorted_nodes[2])
  nodes = length(sorted_nodes) >= 3 ? 
            vcat(new_node, sorted_nodes[3:end]) : Vector{HuffmanTree}([new_node])
  return buildHuffmanTree(nodes)
end

function buildHuffmanTree(b::OrderedDict{Symbol,Float64})
  nodes = Vector{HuffmanTree}()

  for sym in keys(b)
    push!(nodes,HuffmanTree([sym],b[sym],nothing,nothing))
  end
  return buildHuffmanTree(nodes)
end

function fullHuffmanAssignment(belief::Belief,huffmanTree)
  if isnothing(huffmanTree) || length(huffmanTree.symbols) == 1
    huffmanTree = buildHuffmanTree(belief.b)
  end
  assignment = Dict{Symbol,Int}()
  others = []
  for s in keys(belief.b)
    if s in huffmanTree.red.symbols
      assignment[s] = 1
    elseif s in huffmanTree.blue.symbols
      assignment[s] = 2
    else
      #assignment[s] = rand(1:2)
      push!(others,s)
    end
  end
  if !isempty(others)
    assignments = randomAssignments(1000)
    diffs = Vector(undef,1000)
    for i in 1:1000
      redOthers = [belief.b[l] for l in others if assignments[i][l]==1]
      blueOthers = [belief.b[l] for l in others if assignments[i][l]==2]
      #redSum = isempty(redOthers) ? 0 : sum(redOthers)
      redSum = sum(redOthers) + sum(belief.b[l] for l in keys(assignment) if assignment[l]==1)
      #blueSum = isempty(blueOthers) ? 0 : sum(blueOthers)
      blueSum = sum(blueOthers) + sum(belief.b[l] for l in keys(assignment) if assignment[l]==2)
      diffs[i] = abs(redSum - blueSum)
    end
    a = argmin(diffs)
    a = assignments[a]
    for s in others
      assignment[s] = a[s]
    end
  end

  return (assignment, huffmanTree)
end

function huffmanAssignment(belief::Belief,assignment::Dict{Symbol,Int})
  vals = unique(values(assignment))
  if length(vals) == 2
    # convert assignment to colors (1 or 2)
    for l in keys(assignment)
      assignment[l] = assignment[l] == vals[1] ? 1 : 2
    end
    return assignment
  else
    probs = OrderedDict{Int,Float64}(v => 0 for v in vals) 
    for l in keys(assignment)
      probs[assignment[l]] += belief.b[l]
    end
    sorted_vals = map(first, sort(collect(probs),by=last))
    # merge two least probable values in assignment
    for l in keys(assignment)
      if assignment[l] == sorted_vals[2]
        assignment[l] = sorted_vals[1]
      end
    end

    return huffmanAssignment(belief,assignment)
  end
end

function huffmanAssignment(belief::Belief)
  assignment = Dict{Symbol,Int}()
  c = 1
  for s in keys(belief.b)
    assignment[s] = c
    c += 1
  end
  return huffmanAssignment(belief,assignment)
end

#=
function maximizeEntropy(belief::Belief) # only over letter uncertainty
  a = map(Int∘floor,collect(values(belief.b)).*1000)

  dp = Matrix{Bool}(undef,length(a)+1,sum(a)+1)
  dp[:,1] = true
  dp[1,2:end] = false
  for i in 2:length(a)+1, j = 2:sum(a)+1
    dp[i,j] = dp[i-1,j]
    if a[i - 1] <= j
      dp[i,j] |= dp[i-1,j-a[i-1]]
    end
  end

  diff = Inf
  for j in Int(floor(sum(a)/2)):-1:1
    if 
  end
end
=#

#function changeAssignment(belief::Belief, assignment::Dict{Symbol,Int},huffmanTree=nothing)
function changeAssignment(belief::Belief, assignment::Dict{Symbol,Int})
   #best = heuristicPolicy(belief)

  #m = 1000
  #best = entropy_lookahead(belief,m)
  #best = test_entropy_lookahead(belief,m)
  
  best = huffmanAssignment(belief)
  #(best,huffmanTree) = fullHuffmanAssignment(belief,huffmanTree)
  
  for k in keys(assignment)
    assignment[k] = best[k]
  end

  #return huffmanTree
end

function getUniformPrior()
  nChoices = length(keyboardStrings)
  prior = OrderedDict{Symbol,Float64}([letter => 1.0/nChoices for letter in keys(keyboardStrings)])
  return prior
end

function getPrior()
  #return getUniformPrior()
  #prior = languageModel("")
  prior = modelPrior("")
  prior[:UNDO] = 0
  return prior
end

function getPrior(commString::String, belief::Belief,selected_letter::Symbol)
  #return getUniformPrior()
  if isempty(commString) #can't do UNDO
    return getPrior()
  else # use past belief to inform
    #prior = languageModel(commString)
    prior = modelPrior(commString)

    prior[:UNDO] = 1 - belief.b[selected_letter] 
    #normalize other probablities
    for key in keys(prior)
      if key != :UNDO
        prior[key] = prior[key] / (1 - prior[:UNDO])
      end
    end
  end
  return prior
end

function learnLikelihood(belief::Belief,selected_letter::Symbol)
    selections = belief.selections
    right_count = sum(color == assignment[selected_letter] for (color,assignment) in selections)
    wrong_count = sum(color != assignment[selected_letter] for (color,assignment) in selections)
    belief.right_color_count += right_count
    belief.wrong_color_count += wrong_count
    #print("right count: $(belief.right_color_count) wrong count: $(belief.wrong_color_count)\n")
end

function undo(belief::Belief,history::BeliefHistory)
  (prev_letter,prev_belief) = pop!(history)
  belief.right_color_count = prev_belief.right_color_count
  belief.wrong_color_count = prev_belief.wrong_color_count
  belief.selections = prev_belief.selections

  new_belief = deepcopy(prev_belief.b)
  new_belief[prev_letter] = 1 - belief.b[:UNDO] # the probability that I still wanted that previous letter is the probability my current undo was wrong
  #normalize other probablities
  for key in keys(new_belief)
    if key != prev_letter
      new_belief[key] = new_belief[key] / (1 - new_belief[prev_letter])
    end
  end
  belief.b = new_belief
end

# choose letter IF we are confident, and update belief
function chooseLetter(belief::Belief, commString::String, certaintyThreshold::Float64, history::BeliefHistory)
  selected_letter = findfirst(prob->prob>=certaintyThreshold,belief.b)
  if !isnothing(selected_letter)
    if selected_letter == :UNDO
      commString = commString[1:end-1]
      undo(belief,history)
    else
      nextLetter = selected_letter == :SPACE ? " " : keyboardStrings[selected_letter]
      commString = commString * nextLetter
      prior = getPrior(commString,belief,selected_letter)
      push!(history,(selected_letter,deepcopy(belief)))
      learnLikelihood(belief,selected_letter)
      belief.b = prior
      belief.selections = ColorSelections()
    end
  end
  return commString
end
