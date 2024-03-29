% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/model.R
\name{visualize_keywords}
\alias{visualize_keywords}
\title{Visualize texts}
\usage{
visualize_keywords(docs, keywords, prune = TRUE, label_size = 3.2)
}
\arguments{
\item{docs}{A list of texts read via \code{keyATM_read()} function}

\item{keywords}{A list of keywords}

\item{prune}{Prune keywords that do not appear in `docs`}

\item{label_size}{The size of the keyword labels}
}
\value{
A list containing \describe{
   \item{figure}{a ggplot2 object}
   \item{values}{a tibble object that stores values}
   \item{keywords}{a list of keywords that appear in documents}
}
}
\description{
This function visualizes the proportion of keywords in the documents.
}
\examples{
\dontrun{
 # Prepare a keyATM_docs object
 keyATM_docs <- keyATM_read(input) 
  
 # Keywords are in a list  
 keywords <- list(
                   c("education", "child", "student"),  # Education
                   c("public", "health", "program"),  # Health
                 )

 # Visualize keywords
 keyATM_viz <- visualize_keywords(keyATM_docs, keywords)

 # View a figure
 keyATM_viz
   # Or: `keyATM_viz$figure`

 # Save a figure 
 save_fig(keyATM_viz, filename)

}

}
