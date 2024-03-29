% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/posterior.R
\name{top_words}
\alias{top_words}
\title{Show the top words for each topic}
\usage{
top_words(x, n = 10, measure = c("probability", "lift"),
  show_keyword = TRUE)
}
\arguments{
\item{x}{the output (see \code{keyATM()} and \code{by_strata_TopicWord()})}

\item{n}{How many terms to show. Default: NULL, which shows all}

\item{measure}{How to sort the terms: 'probability' (default) or 'lift'}

\item{show_keyword}{Mark keywords. (default: TRUE)}
}
\value{
An n x k table of the top n words in each topic
}
\description{
If \code{show_keyword} is true then words in their seeded categories
are suffixed with a check mark. Words from another seeded category
are labeled with the name of that category.
}
