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
keyboardStrings = OrderedDict([e[1] => "\\fbox{$(e[2])}" for e in keyboardStrings])

mutable struct Belief
  b::OrderedDict{Symbol,Float64}
  right_color_count::Int
  wrong_color_count::Int
end

function updateBelief(belief::Belief, button::Int, assignment::Dict{Symbol,Int})
  p_right_color = belief.right_color_count / (belief.right_color_count + belief.wrong_color_count)
  p_wrong_color = 1 - p_right_color
  for sym in keys(belief.b)
    if assignment[sym] == button
      belief.b[sym] = p_right_color * belief.b[sym]
    else
      belief.b[sym] = p_wrong_color * belief.b[sym]
    end
  end
  total = sum(values(belief.b))
  map!(x->x/total,values(belief.b))
  #print(belief.b)
end

function changeAssignment(belief::Belief, assignment::Dict{Symbol,Int})
  #for sym in keys(assignment)
  #  assignment[sym] = rand(1:2)
  #end

  sorted_belief = sort(collect(belief.b),rev=true,by=x->x[2])
  color = 1
  for (sym,_) in sorted_belief
    assignment[sym] = color
    color = color == 1 ? 2 : 1
  end
end

# choose letter IF we are confident, and update belief
function chooseLetter(belief::Belief, commString::String, certaintyThreshold)
  selected_letter = findfirst(prob->prob>=certaintyThreshold,belief.b) 
  if !isnothing(selected_letter)
    commString = commString * keyboardStrings[selected_letter]
    nChoices = length(keyboardStrings)
    prior = OrderedDict{Symbol,Float64}([letter => 1.0/nChoices for letter in keys(keyboardStrings)])
    belief.b = prior
  end
  return commString
end
