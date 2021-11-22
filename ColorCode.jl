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

mutable struct Belief
  b::OrderedDict{Symbol,Float64}
  right_color_count::Int
  wrong_color_count::Int
  history::Vector{Vector{Tuple{Int,Dict{Symbol,Int}}}} # history keeps track of the color assignments and the colors the user chose
end

function Belief(b::OrderedDict{Symbol,Float64},right_color_count::Int,wrong_color_count::Int)
  belief = Belief(b,right_color_count,wrong_color_count,Vector{Vector{Tuple{Int,Dict{Symbol,Int}}}}())
  push!(belief.history, Vector{Tuple{Int,Dict{Symbol,Int}}}())
  return belief
end

function updateBelief(belief::Belief, color::Int, assignment::Dict{Symbol,Int})
  push!(belief.history[end],(color,copy(assignment)))

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

function getPrior(commString)
  freqs = [ 0.0651738 0.0124248 0.0217339 0.0349835 0.1041442 0.0197881 0.0158610 0.0492888 0.0558094 0.0009033 0.0050529 0.0331490 0.0202124 0.0564513 0.0596302 0.0137645 0.0008606 0.0497563 0.0515760 0.0729357 0.0225134 0.0082903 0.0171272 0.0013692 0.0145984 0.0007836 0.1918182]
  letter_syms = collect(keys(keyboardStrings))
  prior = OrderedDict([(letter_syms[i], freqs[i]) for i in 1:length(freqs)])
  if isempty(commString) #can't do UNDO
    prior[:UNDO] = 0
  else # mix in UNDO into prior distribution
    nChoices = length(keyboardStrings)
    uniform_prob = 1.0/nChoices
    prior[:UNDO] = 0.5 * uniform_prob # make UNDO relatively unlikely: half the probability of if it was an equally likely option
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
    if selected_letter == :UNDO

    else
      right_count = sum(color == assignment[selected_letter] for (color,assignment) in belief.history[end])
      wrong_count = sum(color != assignment[selected_letter] for (color,assignment) in belief.history[end])
      belief.right_color_count += right_count
      belief.wrong_color_count += wrong_count
      push!(belief.history, Vector{Tuple{Int,Dict{Symbol,Int}}}())
    end
end

# choose letter IF we are confident, and update belief
function chooseLetter(belief::Belief, commString::String, certaintyThreshold)
  selected_letter = findfirst(prob->prob>=certaintyThreshold,belief.b) 
  if !isnothing(selected_letter)
    if selected_letter == :UNDO
      commString = commString[1:end-1]
    else
      nextLetter = selected_letter == :SPACE ? " " : keyboardStrings[selected_letter]
      commString = commString * nextLetter
    end
    #nChoices = length(keyboardStrings)
    #prior = OrderedDict{Symbol,Float64}([letter => 1.0/nChoices for letter in keys(keyboardStrings)])
    prior = getPrior(commString)
    belief.b = prior
    learnLikelihood(belief,selected_letter)
  end
  return commString
end
