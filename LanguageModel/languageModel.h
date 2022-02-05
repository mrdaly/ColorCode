#ifndef KENLM_MAX_ORDER
#define KENLM_MAX_ORDER 12
#endif

#include "lm/model.hh"
#include <string>
#include <tuple>
#include "jlcxx/array.hpp"
#include "jlcxx/tuple.hpp"

using namespace std;
using namespace lm::ngram;

double languageModel(string str);

double totalLogProb(string str);

jlcxx::Array<double> modelProbabilities(string prev_letters, string next_letters);

void* getModel();
void releaseModel();
void* getStartState(void* model);
void releaseState(void* state);
jlcxx::Array<double> model(void* state, string letter, string next_letters);

State test();
