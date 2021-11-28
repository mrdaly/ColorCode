using Printf

alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ "

function preprocess(file)
  f = open(file,"r")
  str = read(f,String);
  close(f)
  str = uppercase(str);
  str = replace(str,"\n"=>" ");
  str = join([c for c in str if occursin(c,alphabet)]);
  f = open(file,"w")
  write(f,str)
  close(f)
end

function countngrams(str,counts)
  n = 3
  for i in n:length(str)
    counts[str[i-(n-1):i]] += 1
  end
  return counts
end

if length(ARGS) != 2
    error("usage: julia learnLanguageModel.jl <corpus_dir> <out_file>.csv")
end

#get file names from corpus
#init dict of n-grams -> counts
#for each file
# read in file to string (file is already preprocessed)
# call function to count ngrams, updates counts
#write dict to file

counts = Dict{String,Int}()
for a in alphabet, b in alphabet, c in alphabet
  counts[a*b*c] = 0
end

corpus_dir = ARGS[1]
files = readdir(corpus_dir)
for filename in files
  f = open(joinpath(corpus_dir,filename), "r") #do f
    str = chomp(uppercase(read(f,String)))
    global counts = countngrams(str,counts)
  #end
  close(f)
end

out_file = ARGS[2]
open(out_file,"w") do f
  for k in keys(counts)
    @printf(f,"%s,%i\n",k,counts[k])
  end
end
