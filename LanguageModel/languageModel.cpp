#include "lm/model.hh"
#include <string>
#include "jlcxx/jlcxx.hpp"
#include "jlcxx/array.hpp"
#include "jlcxx/tuple.hpp"

using namespace std;
using namespace jlcxx;
using namespace lm::ngram;

void* getModel() {
  QuantTrieModel* model = new QuantTrieModel("LanguageModel/lm_dec19_char_huge_12gram.kenlm");//make path better
  return (void*)model;
}

void releaseModel(void* modelPtr) {
  QuantTrieModel* model = (QuantTrieModel*) modelPtr; 
  delete model;
}

//return model too??
void* getStartState(void* modelPtr) {
  QuantTrieModel* model = (QuantTrieModel*) modelPtr; 
  State* state = new State(model->BeginSentenceState());
  return (void*)state;
}

void releaseState(void* statePtr) {
  State* state = (State*) statePtr;
  delete state;
}

Array<double> model(void* modelPtr, void* statePtr, string letter, string next_letters) {
  using namespace lm::ngram;
  QuantTrieModel* model = (QuantTrieModel*) modelPtr; 
  State* state = (State*) statePtr;
  State out_state;
  const SortedVocabulary &vocab = model->GetVocabulary();
  if (letter == " ") {
    letter = "<sp>";
  }
  double logprob = model->Score(*state, vocab.Index(letter), out_state);
  *state = out_state;

  Array<double> next_letter_probabilities;
  for (int i=0; i < next_letters.length(); i++) {
    string next_letter;
    next_letter = next_letters[i];
    if (next_letter == " ") {
      next_letter = "<sp>";
    }
    State dump_state;
    next_letter_probabilities.push_back(model->Score(*state, vocab.Index(next_letter), dump_state));
  }

  return next_letter_probabilities;
}

JLCXX_MODULE define_julia_module(jlcxx::Module& mod)
{
  mod.method("model", &model);
  mod.method("getStartState", &getStartState);
  mod.method("releaseState", &releaseState);
  mod.method("getModel", &getModel);
  mod.method("releaseModel", &releaseModel);
}
