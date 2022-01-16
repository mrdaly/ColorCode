#include "lm/model.hh"
#include <string>
#include "jlcxx/jlcxx.hpp"

using namespace std;

double languageModel(string str) {
  using namespace lm::ngram;
  QuantTrieModel model("lm_dec19_char_large_12gram.kenlm");
  State state(model.BeginSentenceState()), out_state;
  const SortedVocabulary &vocab = model.GetVocabulary();

  double logprob;
  for (int i=0; i < str.length(); i++) {
    string word;
    word = str[i];
    if (word == " ") {
      word = "<sp>";
    }
    logprob = model.Score(state, vocab.Index(word), out_state);
    state = out_state;
  }

  return logprob;
}

JLCXX_MODULE define_julia_module(jlcxx::Module& mod)
{
  mod.method("languageModel", &languageModel);
}
