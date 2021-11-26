using DataStructures

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

function updateBelief(belief::Belief, color::Int, assignment::Dict{Symbol,Int})
  push!(belief.selections,(color,copy(assignment)))

  p_right_color = belief.right_color_count / (belief.right_color_count + belief.wrong_color_count)
  p_wrong_color = 1 - p_right_color
  for sym in keys(belief.b)
    if assignment[sym] == color
      belief.b[sym] = p_right_color * belief.b[sym]
    else
      belief.b[sym] = p_wrong_color * belief.b[sym]
    end
  end
  total = sum(values(belief.b))
  map!(x->x/total,values(belief.b))
end

function changeAssignment(belief::Belief, assignment::Dict{Symbol,Int})
  sorted_belief = sort(collect(belief.b),rev=true,by=x->x[2])
  color = 1
  for (sym,_) in sorted_belief
    assignment[sym] = color
    color = color == 1 ? 2 : 1
  end
end

function getPrior()
  freqs = [ 0.0651738 0.0124248 0.0217339 0.0349835 0.1041442 0.0197881 0.0158610 0.0492888 0.0558094 0.0009033 0.0050529 0.0331490 0.0202124 0.0564513 0.0596302 0.0137645 0.0008606 0.0497563 0.0515760 0.0729357 0.0225134 0.0082903 0.0171272 0.0013692 0.0145984 0.0007836 0.1918182]
  letter_syms = collect(keys(keyboardStrings))
  prior = OrderedDict([(letter_syms[i], freqs[i]) for i in 1:length(freqs)])
  prior[:UNDO] = 0
  return prior
end

function getPrior(commString::String, belief::Belief,selected_letter::Symbol)
  if isempty(commString) #can't do UNDO
    return getPrior()
  else # use past belief to inform
    freqs = [ 0.0651738 0.0124248 0.0217339 0.0349835 0.1041442 0.0197881 0.0158610 0.0492888 0.0558094 0.0009033 0.0050529 0.0331490 0.0202124 0.0564513 0.0596302 0.0137645 0.0008606 0.0497563 0.0515760 0.0729357 0.0225134 0.0082903 0.0171272 0.0013692 0.0145984 0.0007836 0.1918182]
    letter_syms = collect(keys(keyboardStrings))
    prior = OrderedDict([(letter_syms[i], freqs[i]) for i in 1:length(freqs)])

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
      #learnLikelihood(belief,selected_letter)
      belief.b = prior
      belief.selections = ColorSelections()
    end
  end
  return commString
end
