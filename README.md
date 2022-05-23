# ColorCode
## Paper
The paper for this project, "ColorCode: A Bayesian Approach to Augmentative and Alternative Communication with Two Buttons" is part of the ACL 2022 SLPAT workshop. It can be found on arXiv [here](https://arxiv.org/abs/2204.09745). 

[Watch this for a demo](https://www.youtube.com/watch?v=HtPYEFwMhHo)

## Installation

NB: This is for MacOS. Build steps will be roughly the same for other platforms

First - make sure you have [Julia installed](https://julialang.org/downloads/). 

1. Build libcxxwrap dependency

This is necessary to call the c++ code for the language model from julia. (This requires cmake)

    cd LanguageModel
    mdkir libcxxwrap-julia-build
    cd libcxxwrap-julia-build
    cmake ../libcxxwrap-julia
    make

2. [Download the language model (1.4 GB)](http://data.imagineville.org/lm/dec19_char/lm_dec19_char_huge_12gram.kenlm.gz), and extract the compressed file to the LanguageModel directory.
 
3. Build the C++ code

Now you need to build the C++ code for calling the language model. Execute the compile_query_only.sh script (``./compile_query_only.sh``). Looking back at this makefile, it points to ``/Applications/Julia-1.7.app/Contents/Resources/julia/lib`` and ``/Applications/Julia-1.7.app/Contents/Resources/julia/include/julia``, which I believe is necessary for the interoperation of julia and c++. So I guess make sure that you have the Julia 1.7 app in that location.

## Use

### Launch

    julia main_gui.jl
*Warning:* It takes a few minutes for the GUI to startup.
  
### Controls

You can use a mouse to click the color buttons, or you can use the left arrow for red and the right arrow for blue.

### Exit

Exitting the GUI does not quit the program, so you need to kill the program (CTRL+C) in the command line after you exit out of the GUI.

## Video Demo

[Watch this for a demo](https://www.youtube.com/watch?v=HtPYEFwMhHo)
    
## License

ColorCode is licensed under the MIT license, but this repository also contains dependencies with different licenses. See their license files for more information:
- KenLM: `LanguageModel/kenlm/LICENSE`
- libcxxwrap-julia: `LanguageModel/libcxxwrap-julia/LICENSE.md`

