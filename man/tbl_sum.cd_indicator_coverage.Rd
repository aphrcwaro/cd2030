% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/tbl_sum.indicator_coverage.R
\name{tbl_sum.cd_indicator_coverage}
\alias{tbl_sum.cd_indicator_coverage}
\title{Table Summary for National Coverage Estimates}
\usage{
\method{tbl_sum}{cd_indicator_coverage}(x, ...)
}
\arguments{
\item{x}{An object of class \code{cd_indicator_coverage}, typically a data frame or tibble containing
national coverage estimates for various health indicators.}

\item{...}{Additional arguments passed to \code{NextMethod()} for extending or customizing the summary
method.}
}
\value{
A named character vector where the first element, \code{"Table"}, is titled \code{"National Coverage Estimates"},
followed by the summary generated by the next method in the class hierarchy.
}
\description{
\code{tbl_sum.cd_indicator_coverage} generates a summary label for national coverage estimates tables,
providing a clear indication of the data contents. This function is designed to be used as a custom
summary method for objects of class \code{cd_indicator_coverage}, creating a consistent table title for
outputs.
}
\details{
This function is part of the summary method hierarchy for \code{cd_indicator_coverage} objects.
By adding a specific table title (\code{"National Coverage Estimates"}), this function helps standardize
output tables, ensuring consistency in reports and summaries for national health coverage indicators.
}
\examples{
\dontrun{
  # Assuming `data` is of class `cd_indicator_coverage`
  tbl_sum.cd_indicator_coverage(data)
}

}
