% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/keyATM.R
\name{keyATM}
\alias{keyATM}
\title{keyATM Main function}
\usage{
keyATM(docs, model, no_keyword_topics, keywords = list(),
  model_settings = list(), priors = list(), options = list(),
  keep = c())
}
\arguments{
\item{model}{keyATM model: "base", "covariates", and "dynamic"}

\item{no_keyword_topics}{the number of regular topics}

\item{keywords}{a list of keywords}

\item{model_settings}{a list of model specific settings}

\item{priors}{a list of priors of parameters}

\item{options}{a list of options}

\item{keep}{a vector of the names of elements you want to keep in output}

\item{keyATM_docs}{texts read via \code{keyATM_read()}}
}
\value{
A keyATM_output object containing:
  \describe{
    \item{keyword_k}{Number of keyword topics}
    \item{no_keyword_topics}{Number of regular unseeded topics}
    \item{V}{Number of word types}
    \item{N}{Number of documents}
    \item{theta}{Normalized topic proportions for each document}
    \item{phi}{Normalized topic specific word generation probabilities}
    \item{topic_counts}{Number of tokens assigned to each topic}
    \item{word_counts}{Number of times each word type appears}
    \item{doc_lens}{Length of each document in tokens}
    \item{vocab}{Words in the vocabulary}
    \item{model_fit}{Perplexity and log-likelihood}
    \item{p}{Estimated p}
    \item{values_iter}{Organized values stored during iterations}
    \item{kept_values}{Outputs you specified to store.}
  }
}
\description{
Run keyATM models.
}
\examples{
\dontrun{
  # keyATM Base
  out <- keyATM(
                docs, model = "base", no_keyword_topics = 5, keywords = keywords_list
               )

  # keyATM Covariates
  out <- keyATM(
                docs, model = "covariates", no_keyword_topics = 5, keywords = keywords_list,
                model_settings(covariates_data = cov)
               )

  # keyATM Dynamic
  out <- keyATM(
                docs, model = "dynamic", no_keyword_topics = 5, keywords = keywords_list,
                model_settings(time_index = time_index_vec, num_states = 5)
               )

}

}
