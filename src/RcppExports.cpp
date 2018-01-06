// Generated by using Rcpp::compileAttributes() -> do not edit by hand
// Generator token: 10BE3573-1514-4C36-9D1C-5A225CD40393

#include <RcppEigen.h>
#include <Rcpp.h>

using namespace Rcpp;

// train
List train(List model, int k_seeded, int k_free, double alpha_k, int iter);
RcppExport SEXP _topicdict_train(SEXP modelSEXP, SEXP k_seededSEXP, SEXP k_freeSEXP, SEXP alpha_kSEXP, SEXP iterSEXP) {
BEGIN_RCPP
    Rcpp::RObject rcpp_result_gen;
    Rcpp::RNGScope rcpp_rngScope_gen;
    Rcpp::traits::input_parameter< List >::type model(modelSEXP);
    Rcpp::traits::input_parameter< int >::type k_seeded(k_seededSEXP);
    Rcpp::traits::input_parameter< int >::type k_free(k_freeSEXP);
    Rcpp::traits::input_parameter< double >::type alpha_k(alpha_kSEXP);
    Rcpp::traits::input_parameter< int >::type iter(iterSEXP);
    rcpp_result_gen = Rcpp::wrap(train(model, k_seeded, k_free, alpha_k, iter));
    return rcpp_result_gen;
END_RCPP
}

static const R_CallMethodDef CallEntries[] = {
    {"_topicdict_train", (DL_FUNC) &_topicdict_train, 5},
    {NULL, NULL, 0}
};

RcppExport void R_init_topicdict(DllInfo *dll) {
    R_registerRoutines(dll, NULL, CallEntries, NULL, NULL);
    R_useDynamicSymbols(dll, FALSE);
}
