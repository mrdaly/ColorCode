using DataStructures

module LM
  using CxxWrap
  @wrapmodule(joinpath("LanguageModel","lib","liblanguageModel.so"))
  function __init__()
    @initcxx
  end
end

function modelPrior(next_letter::String,lmModel,lmState)
  alphabet = "abcdefghijklmnopqrstuvwxyz "
  next_letter = lowercase(next_letter)

  logprobs = LM.model(lmModel,lmState,next_letter,alphabet)
  prior = OrderedDict([(alphabet[i], 10^(logprobs[i])) for i in 1:length(alphabet)])
  total = sum(values(prior))
  return OrderedDict([(k==' ' ? :SPACE : Symbol(uppercase(k)), v/total) for (k,v) in prior])
end

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

function greedyPartition(belief::Belief)
  sorted_belief = sort(collect(belief.b),rev=true,by=x->x[2])
  assignment = Dict{Symbol,Int}()
  for (sym,_) in sorted_belief
    redSum = sum(vcat([belief.b[k] for (k,v) in assignment if v==1],0))
    blueSum = sum(vcat([belief.b[k] for (k,v) in assignment if v==2],0))
    assignment[sym] = redSum < blueSum ? 1 : 2
  end
  return assignment
end

function changeAssignment(belief::Belief, assignment::Dict{Symbol,Int})
  best = greedyPartition(belief)
  
  #best = huffmanAssignment(belief)
  
  for k in keys(assignment)
    assignment[k] = best[k]
  end
end

function getUniformPrior()
  nChoices = length(keyboardStrings)
  prior = OrderedDict{Symbol,Float64}([letter => 1.0/nChoices for letter in keys(keyboardStrings)])
  return prior
end

function getPrior(lmModel,lmState)
  #return getUniformPrior()
  prior = modelPrior("",lmModel,lmState)
  prior[:UNDO] = 0
  return prior
end

function getPrior(commString::String, belief::Belief,selected_letter::Symbol,lmModel,lmState)
  #return getUniformPrior()
  if isempty(commString) #can't do UNDO
    return getPrior(lmState)
  else # use past belief to inform
    nextLetter = selected_letter == :SPACE ? " " : keyboardStrings[selected_letter]
    prior = modelPrior(nextLetter,lmModel,lmState)

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
function chooseLetter(belief::Belief, commString::String, certaintyThreshold::Float64, history::BeliefHistory,lmModel, lmState)
  selected_letter = findfirst(prob->prob>=certaintyThreshold,belief.b)
  if !isnothing(selected_letter)
    if selected_letter == :UNDO
      commString = commString[1:end-1]
      undo(belief,history)
    else
      nextLetter = selected_letter == :SPACE ? " " : keyboardStrings[selected_letter]
      commString = commString * nextLetter
      prior = getPrior(commString,belief,selected_letter,lmModel,lmState)
      push!(history,(selected_letter,deepcopy(belief)))
      learnLikelihood(belief,selected_letter)
      belief.b = prior
      belief.selections = ColorSelections()
    end
  end
  return commString
end
