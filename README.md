# ColorCode


## Installation

1. Build libcxxwrap dependency

This is necessary to call the c++ code for the language model from julia. (This requires cmake)

    cd LanguageModel
    mdkir libcxxwrap-julia-build
    cd libcxxwrap-julia-build
    cmake ../libcxxwrap-julia
    make

2. [Download the language model (1.4 GB)](http://data.imagineville.org/lm/dec19_char/lm_dec19_char_huge_12gram.kenlm.gz), and extract the compressed file to the LanguageModel directory.
 
3. Build the C++ code

Now you need to build the C++ code for calling the language model. Execute the compile_query_only.sh script (``./compile_query_only.sh``). Looking back at this makefile, it points to "/Applications/Julia-1.7.app/Contents/Resources/julia/lib" and "/Applications/Julia-1.7.app/Contents/Resources/julia/include/julia", which I believe is necessary for the interoperation of julia and c++. So I guess make sure that you have the Julia 1.7 app in that location.

## Running it

Launch GUI:

    julia main_gui.jl
    
You can use a mouse to click the color buttons, or you can use the left arrow for red and the right arrow for blue.
    
* Warning: It takes a few minutes for the GUI to startup. *

    
## License

ColorCode is licensed under the MIT license, but this repository also contains dependencies with different licenses. See their license files for more information:
- KenLM: `LanguageModel/kenlm/LICENSE`
- libcxxwrap-julia: `LanguageModel/libcxxwrap-julia/LICENSE.md`

