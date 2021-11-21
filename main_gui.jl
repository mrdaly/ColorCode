using Interact
using Blink
using Plots
include("ColorCode.jl")

struct KeyboardFrontEnd
  letters::OrderedDict{Symbol,Widget{:latex,String}}
  commString::Widget{:latex,String}
end

function layoutKeyboard(keyboard::KeyboardFrontEnd)
  letterObjs = collect(values(keyboard.letters))
  return vbox(keyboard.commString,hbox(vbox(letterObjs[1:6]...),vbox(letterObjs[7:12]...),vbox(letterObjs[13:18]...),vbox(letterObjs[19:24]...),vbox(letterObjs[25:end]...)))
end

function renderAssignment(keyboard::KeyboardFrontEnd, assignment::Dict{Symbol,Int})
  colors = ["red" "blue"] 
  foreach(x->keyboard.letters[x[1]][] = "\\fbox{\\color{$(colors[x[2]])} \\textrm{$(keyboardStrings[x[1]])}}",assignment)
end

buttons = [button(x) for x in ["red" "blue"]]

keyboard = KeyboardFrontEnd(OrderedDict([sym => latex(str) for (sym,str) in keyboardStrings]),latex("\\textrm{|}"))
assignment = Dict([(k,rand(1:2)) for k in keys(keyboardStrings)])
renderAssignment(keyboard,assignment)

nChoices = length(keyboardStrings)
#prior = OrderedDict{Symbol,Float64}([letter => 1.0/nChoices for letter in keys(keyboardStrings)])
prior = getPrior("")
commString = Ref("")
belief = Belief(prior,99,1)
certaintyThreshold = 0.95

plot(OrderedDict([(string(k),v) for (k,v) in belief.b]), seriestype=:bar, ylims = (0,1), xticks = :all,legend=false)
gui()

function buttonCallback(button,commString)
  updateBelief(belief,button,assignment)
  changeAssignment(belief,assignment)
  commString[] = chooseLetter(belief,commString[],certaintyThreshold)
  keyboard.commString[] = "\\textrm{$(replace(commString[]," "=>"\\  "))|}"

  plot(OrderedDict([(string(k),v) for (k,v) in belief.b]), seriestype=:bar, ylims = (0,1), xticks = :all,legend=false)
  gui()

  #randomAssignment = Dict([(k,rand(1:2)) for k in keys(keyboardStrings)])
  renderAssignment(keyboard,assignment)
end

buttonCallbacks = [on(_->buttonCallback(n,commString),button) for (button,n) in zip(buttons,1:length(buttons))]

w = Window()
body!(w,vbox(layoutKeyboard(keyboard),hbox(buttons...)))

wait()
