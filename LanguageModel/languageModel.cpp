#include "lm/model.hh"
#include <string>
#include "jlcxx/jlcxx.hpp"
#include "jlcxx/array.hpp"

using namespace std;
using namespace jlcxx;

double languageModel(string str) {
  using namespace lm::ngram;
  QuantTrieModel model("LanguageModel/lm_dec19_char_tiny_12gram.kenlm");//make path better
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

//literally just duplicate code but I'm just trying to do this fast
double totalLogProb(string str) {
  using namespace lm::ngram;
  QuantTrieModel model("LanguageModel/lm_dec19_char_tiny_12gram.kenlm");//make path better
  State state(model.BeginSentenceState()), out_state;
  const SortedVocabulary &vocab = model.GetVocabulary();

  double total;
  for (int i=0; i < str.length(); i++) {
    string word;
    word = str[i];
    if (word == " ") {
      word = "<sp>";
    }
    total += model.Score(state, vocab.Index(word), out_state);
    state = out_state;
  }
  return total;
}

Array<double> modelProbabilities(string prev_letters, string next_letters) {
  using namespace lm::ngram;
  QuantTrieModel model("LanguageModel/lm_dec19_char_large_12gram.kenlm");//make path better
  State state(model.BeginSentenceState()), out_state;
  const SortedVocabulary &vocab = model.GetVocabulary();

  double logprob;
  for (int i=0; i < prev_letters.length(); i++) {
    string word;
    word = prev_letters[i];
    if (word == " ") {
      word = "<sp>";
    }
    logprob = model.Score(state, vocab.Index(word), out_state);
    state = out_state;
  }

  Array<double> next_letter_probabilities;
  for (int i=0; i < next_letters.length(); i++) {
    string next_letter;
    next_letter = next_letters[i];
    if (next_letter == " ") {
      next_letter = "<sp>";
    }
    next_letter_probabilities.push_back(model.Score(state, vocab.Index(next_letter), out_state));
  }
  return next_letter_probabilities;
}

JLCXX_MODULE define_julia_module(jlcxx::Module& mod)
{
  mod.method("languageModel", &languageModel);
  mod.method("totalLogProb", &totalLogProb);
  mod.method("modelProbabilities", &modelProbabilities);
}
