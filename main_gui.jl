using Interact
using Blink
#using Plots
using WAV
using PortAudio
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
  return pad(1em,vbox(pad(0.5em,keyboard.commString),
                      vbox(pad(0.5em,hbox(map(x->pad(["right"],0.6em,x),letterObjs[1:9])...)),
                           pad(0.5em,hbox(map(x->pad(["right"],0.6em,x),letterObjs[10:18])...)),
                           pad(0.5em,hbox(map(x->pad(["right"],0.6em,x),letterObjs[19:26])...)),
                           pad(0.5em,hbox(map(x->pad(["right"],0.6em,x),letterObjs[27:end])...)))))
end

function renderAssignment(keyboard::KeyboardFrontEnd, assignment::Dict{Symbol,Int})
  colors = ["red" "blue"] 
  foreach(x->keyboard.letters[x[1]][] = "\\fbox{\\color{$(colors[x[2]])} \\Huge \\texttt{$(keyboardStrings[x[1]])}}",assignment)
end

buttons = [button(x,style=Dict(:backgroundColor=>x)) for x in ["red" "blue"]]

keyboard = KeyboardFrontEnd(OrderedDict([sym => latex(str) for (sym,str) in keyboardStrings]),latex("\\Large\\textrm{|}"))

lmModel = LM.getModel()
lmState = LM.getStartState(lmModel)
prior = getPrior(lmModel,lmState)
commString = Ref("")
belief = Belief(prior,99,1)
history = BeliefHistory()
certaintyThreshold = 0.95

assignment = Dict([(k,1) for k in keys(keyboardStrings)])
changeAssignment(belief,assignment)
renderAssignment(keyboard,assignment)

#plotBelief(belief)

popSound,fs = wavread("pop.wav");
audioStream = PortAudioStream(0,2)
write(audioStream,popSound) #stops lag for some reason does it? idk

function buttonCallback(button,commString)
  updateBelief(belief,button,assignment)
  newCommString = chooseLetter(belief,commString[],certaintyThreshold,history,lmModel,lmState)
  if length(newCommString) != length(commString[])
    @async write(audioStream,popSound)
  end
  commString[] = newCommString
  changeAssignment(belief,assignment)
  keyboard.commString[] = "\\Large\\textrm{$(replace(commString[]," "=>"\\  "))|}"

  #plotBelief(belief)

  renderAssignment(keyboard,assignment)
end

buttonCallbacks = [on(_->buttonCallback(n,commString),button) for (button,n) in zip(buttons,1:length(buttons))]

w = Window()
title(w,"ColorCode")
body!(w,vbox(layoutKeyboard(keyboard),pad(["left"],6em,hbox(pad(1em,buttons[1]), pad(1em,buttons[2])))))
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
LM.releaseModel(lmModel)
LM.releaseState(lmModel)
