% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/WeightedCombinationComputer.R
\docType{class}
\name{WeightedCombinationComputer}
\alias{WeightedCombinationComputer}
\title{WeightedCombinationComputer}
\format{An object of class \code{R6ClassGenerator} of length 24.}
\usage{
WeightedCombinationComputer
}
\description{
WeightedCombinationComputer
}
\section{Methods}{

\describe{
  \item{\code{new()}}{
   Creates a new computer for determining the best weighted combination of the ML libraries.
   \code{weigths.initial} vector containing the initial weights
  }
  \item{\code{getWeigths()}}{
   Returns the current list of optimal weights (or the initial weights, if not yet fitted)
  }
  \item{\code{compute(Z, Y, libraryNames)}}{
   Method to compute the best weighted combination of the underlying estimators
   \code{Z} matrix containing the outcomes of each of the estimators
   \code{Y} vector containing the actual outcome
   \code{libraryNames} vector containing the names of the estimators
  }
}
}

\keyword{datasets}
