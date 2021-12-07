using Interact
using Blink
using Plots
include("ColorCode.jl")

function plotBelief(belief::Belief)
  plot(OrderedDict(reverse([(string(k),v) for (k,v) in belief.b],dims=1)),
       plot_title="Belief",
       ylabel="Key",
       xlabel="Probability",
       seriestype=:bar,
       #bar_width=0.6,
       orientation=:horizontal,
       xlims=(0,1),
       yticks=:all,
       legend=false)
       #size=(1100,500))
  gui()
end

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

prior = getPrior()
commString = Ref("")
belief = Belief(prior,99,1)
history = BeliefHistory()
certaintyThreshold = 0.95

assignment = Dict([(k,1) for k in keys(keyboardStrings)])
changeAssignment(belief,assignment,certaintyThreshold)
renderAssignment(keyboard,assignment)

plotBelief(belief)

function buttonCallback(button,commString)
  updateBelief(belief,button,assignment)
  commString[] = chooseLetter(belief,commString[],certaintyThreshold,history)
  changeAssignment(belief,assignment,certaintyThreshold)
  keyboard.commString[] = "\\textrm{$(replace(commString[]," "=>"\\  "))|}"

  plotBelief(belief)

  #randomAssignment = Dict([(k,rand(1:2)) for k in keys(keyboardStrings)])
  renderAssignment(keyboard,assignment)
end

buttonCallbacks = [on(_->buttonCallback(n,commString),button) for (button,n) in zip(buttons,1:length(buttons))]

w = Window()
body!(w,vbox(layoutKeyboard(keyboard),hbox(buttons...)))

wait()
