% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/utils.R
\name{compose_biker_inputs}
\alias{compose_biker_inputs}
\title{Prepare biker object for stan model}
\usage{
compose_biker_inputs(bikerdata, priors = biker_priors(bikerdata))
}
\arguments{
\item{bikerdata}{bikerdata object}

\item{priors}{bikerpriors object}
}
\description{
"Decomposes" the structure of the bikerdata pbject into a form more easily read by the stan sampling functions (i.e. a big ole list)
}
