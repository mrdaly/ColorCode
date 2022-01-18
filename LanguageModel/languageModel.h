#ifndef KENLM_MAX_ORDER
#define KENLM_MAX_ORDER 12
#endif

#include "lm/model.hh"
#include <string>
#include "jlcxx/array.hpp"

using namespace std;

double languageModel(string str);

double totalLogProb(string str);

jlcxx::Array<double> modelProbabilities(string prev_letters, string next_letters);
