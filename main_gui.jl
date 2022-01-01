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
  return vbox(keyboard.commString,
              vbox(hbox(letterObjs[1:9]...),
                   hbox(letterObjs[10:18]...),
                   hbox(letterObjs[19:26]...),
                   hbox(letterObjs[27:end]...)))
end

function renderAssignment(keyboard::KeyboardFrontEnd, assignment::Dict{Symbol,Int})
  colors = ["red" "blue"] 
  foreach(x->keyboard.letters[x[1]][] = "\\fbox{\\color{$(colors[x[2]])} \\huge \\texttt{$(keyboardStrings[x[1]])}}",assignment)
end

buttons = [button(x) for x in ["red" "blue"]]

keyboard = KeyboardFrontEnd(OrderedDict([sym => latex(str) for (sym,str) in keyboardStrings]),latex("\\Large\\textrm{|}"))

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
  keyboard.commString[] = "\\Large\\textrm{$(replace(commString[]," "=>"\\  "))|}"

  plotBelief(belief)

  #randomAssignment = Dict([(k,rand(1:2)) for k in keys(keyboardStrings)])
  renderAssignment(keyboard,assignment)
end

buttonCallbacks = [on(_->buttonCallback(n,commString),button) for (button,n) in zip(buttons,1:length(buttons))]

w = Window()
title(w,"ColorCode")
body!(w,vbox(layoutKeyboard(keyboard),hbox(pad(1em,buttons[1]), pad(1em,buttons[2]))))
js(w,Blink.JSString("""document.onkeydown = function (e) {Blink.msg("press",e.keyCode)}; """))
handle(w,"press") do key
  if key == 37
    buttonCallback(1,commString)
  end
  if key == 39
    buttonCallback(2,commString)

  end
end

wait()
