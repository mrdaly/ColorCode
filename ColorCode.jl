using DataStructures
using DataFrames
using CSV
using Distributions

let #change to struct & function 
  counts = Dict([(r[1],r[2]+1) for r in eachrow(Matrix(DataFrame(CSV.File("trigram_counts.csv",header=false))))])
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

ColorSelections = Vector{Tuple{Int,Dict{Symbol,Int}}}

mutable struct Belief
  b::OrderedDict{Symbol,Float64}
  right_color_count::Int
  wrong_color_count::Int
  selections::ColorSelections
end

function Belief(b::OrderedDict{Symbol,Float64},right_color_count::Int,wrong_color_count::Int)
  return Belief(b,right_color_count,wrong_color_count,ColorSelections())
end

BeliefHistory = Vector{Tuple{Symbol,Belief}}

function colorProbability(color::Int,l::Symbol,belief::Belief,assignment::Dict{Symbol,Int})
  p_right_color = belief.right_color_count / (belief.right_color_count + belief.wrong_color_count)
  if assignment[l] == color
    return p_right_color
  else
    return 1 - p_right_color
  end
end

function colorProbability(color::Int,belief::Belief,assignment::Dict{Symbol,Int})
  return sum(belief.b[l]*colorProbability(color,l,belief,assignment) for l in keys(belief.b))
end

function colorEntropy(belief::Belief, assignment::Dict{Symbol,Int})
  p(c) = colorProbability(c,belief,assignment)
  return -sum(p(c)log(2,p(c)) for c in 1:2)
end

function randomAssignments(m)
  assignments = [Dict([l => c for (l,c) in zip(keys(keyboardStrings),digits(n,base=2,pad=28).+1)]) for n in rand(1:((2^27)-1), m)]
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

function rollout(belief,d,certaintyThreshold)
  ret = 0.0
  for t = 1:d
    a = heuristicPolicy(belief)
    dist = Bernoulli(colorProbability(2,belief,a))
    c = rand(dist)+1
    updateBelief(belief,c,a)
    if any(map(prob->prob>=certaintyThreshold,values(belief.b))) #if we are certain about any of the letters
      break
    else
      ret += 0.9^(t-1) * colorEntropy(belief,a)
    end
  end
  return ret
end

function sparse_rollout_lookahead(belief,d,m,certaintyThreshold)
  best = (a=nothing,u=-Inf)
  for a in randomAssignments(m)
    red = 1
    blue = 2

    red_belief = deepcopy(belief)
    updateBelief(red_belief,red,a)
    u_red = rollout(red_belief,d,certaintyThreshold)

    blue_belief = deepcopy(belief)
    updateBelief(blue_belief,blue,a)
    u_blue = rollout(blue_belief,d,certaintyThreshold)

    u = colorEntropy(belief,a) + (0.9)*(colorProbability(red,belief,a)*u_red + colorProbability(blue,belief,a)*u_blue)
    if u > best.u
      best = (a=a,u=u)
    end
  end
  return best.a
end

function sparse_sampling(belief::Belief,d::Int,m,certaintyThreshold)
  #print("in sparse sampling, d = $(d)\n")
  if any(map(prob->prob>=certaintyThreshold,values(belief.b))) #if we are certain about any of the letters
    return (a=Dict([l=>1 for l in keys(belief.b)]),u=10)
  end

  if d <= 0
    return (a=nothing,u=maximum(colorEntropy(belief,a) for a in randomAssignments(100)))
  end
  best = (a=nothing,u=-Inf)
  for a in randomAssignments(m)
    red = 1
    blue = 2

    red_belief = deepcopy(belief)
    updateBelief(red_belief,red,a)
    a_red,u_red = sparse_sampling(red_belief,d-1,m,certaintyThreshold)

    blue_belief = deepcopy(belief)
    updateBelief(blue_belief,blue,a)
    a_blue,u_blue = sparse_sampling(blue_belief,d-1,m,certaintyThreshold)

    u = colorEntropy(belief,a) + (0.9)*(colorProbability(red,belief,a)*u_red + colorProbability(blue,belief,a)*u_blue)

    if u > best.u
      best = (a=a,u=u)
    end
  end
  return best
end

function updateBelief(belief::Belief, color::Int, assignment::Dict{Symbol,Int})
  push!(belief.selections,(color,copy(assignment)))

  for l in keys(belief.b)
    belief.b[l] = colorProbability(color,l,belief,assignment)*belief.b[l]
  end
  total = sum(values(belief.b))
  map!(x->x/total,values(belief.b))
end

function changeAssignment(belief::Belief, assignment::Dict{Symbol,Int},certaintyThreshold)
  #sorted_belief = sort(collect(belief.b),rev=true,by=x->x[2])
  #color = 1
  #for (sym,_) in sorted_belief
  #  assignment[sym] = color
  #  color = color == 1 ? 2 : 1
  #end

  m = 10000

  assignments = [Dict([l => c for (l,c) in zip(keys(belief.b),digits(n,base=2,pad=28).+1)]) for n in rand(1:((2^27)-1), m)]
  entropies = [colorEntropy(belief,a) for a in assignments]
  a = argmax(entropies)
  best = assignments[a]
  for k in keys(assignment)
    assignment[k] = best[k]
  end

  #best = sparse_sampling(belief,1,100,certaintyThreshold).a
  #print("sparse sampling done\n")
  #for k in keys(assignment)
  #  assignment[k] = best[k]
  #end

  #best = sparse_rollout_lookahead(belief,5,1000,certaintyThreshold)
  #for k in keys(assignment)
  #  assignment[k] = best[k]
  #end
end

function getPrior()
  #freqs = [ 0.0651738 0.0124248 0.0217339 0.0349835 0.1041442 0.0197881 0.0158610 0.0492888 0.0558094 0.0009033 0.0050529 0.0331490 0.0202124 0.0564513 0.0596302 0.0137645 0.0008606 0.0497563 0.0515760 0.0729357 0.0225134 0.0082903 0.0171272 0.0013692 0.0145984 0.0007836 0.1918182]
  #letter_syms = collect(keys(keyboardStrings))
  #prior = OrderedDict([(letter_syms[i], freqs[i]) for i in 1:length(freqs)])
  prior = languageModel("")
  prior[:UNDO] = 0
  return prior
end

function getPrior(commString::String, belief::Belief,selected_letter::Symbol)
  if isempty(commString) #can't do UNDO
    return getPrior()
  else # use past belief to inform
    #freqs = [ 0.0651738 0.0124248 0.0217339 0.0349835 0.1041442 0.0197881 0.0158610 0.0492888 0.0558094 0.0009033 0.0050529 0.0331490 0.0202124 0.0564513 0.0596302 0.0137645 0.0008606 0.0497563 0.0515760 0.0729357 0.0225134 0.0082903 0.0171272 0.0013692 0.0145984 0.0007836 0.1918182]
    #letter_syms = collect(keys(keyboardStrings))
    #prior = OrderedDict([(letter_syms[i], freqs[i]) for i in 1:length(freqs)])
    prior = languageModel(commString)

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
