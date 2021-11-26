

if length(ARGS) != 2
    error("usage: julia learnLanguageModel.jl <corpus_dir> <out_file>.csv")
end

#get file names from corpus
#init dict of n-grams -> counts
#for each file
# read in file to string (file is already preprocessed)
# call function to count ngrams, updates counts
#write dict to file
