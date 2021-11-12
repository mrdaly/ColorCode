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
  b::Dict{Symbol,Float64}
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
  for sym in keys(belief.b)
    belief.b[sym] = belief.b[sym] / total
  end
  print(belief.b)
end

function changeAssignment(belief::Belief, assignment::Dict{Symbol,Int})
  for sym in keys(assignment)
    assignment[sym] = rand(1:2)
  end
end
