% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/posterior.R
\name{by_strata_TopicWord}
\alias{by_strata_TopicWord}
\title{Estimate Subsetted Topic-Word distribution}
\usage{
by_strata_TopicWord(x, keyATM_docs, by)
}
\arguments{
\item{x}{the output from a keyATM model (see \code{keyATM()})}

\item{keyATM_docs}{(see \code{keyATM_read()})}

\item{by}{a vector whose length is the number of documents}
}
\value{
strata_topicword object (a list)
}
\description{
Estimate Subsetted Topic-Word distribution
}
