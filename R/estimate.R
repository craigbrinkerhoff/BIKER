#########################
#Functions to sample from the posterior (via stan) and then return posterior means, sigmas, and CIs
##########################


#' Estimate BIKER
#'
#' Fits a BIKER model of one of several variants using Hamiltonian Monte Carlo.
#'
#' @param bikerdata A bikerdata object, as produced by \code{biker_data()}
#' @param bikerpriors A bikerpriors object.
#' @param cores Number of processing cores for running chains in parallel.
#'   See \code{?rstan::sampling}. Defaults to \code{parallel::detectCores()}.
#' @param meas_error Should we run with latent variables accounting for uncertainty in SWOT measurements. LEAVE THIS OFF, IT IS IN ACTIVE DEVELOPMENT
#' @param chains A positive integer specifying the number of Markov chains. The default is 3.
#' @param iter Number of iterations per chain (including warmup). Defaults to 1000.
#' @param CI: Confidence intervals, defaults to 95%, i.e.e 0.95
#' @param chainExtract: Which chains to use to construct the posterior k600. Defaults to all.
#' @param pars (passed to \code{rstan::sampling()}) A vector of character strings specifying parameters of interest to be returned in the stanfit object. If not specified, a default parameter set is returned.
#' @param include (passed to \code{rstan::sampling()}) Defaults to FALSE, which
#'   excludes parameters specified in \code{pars} from the returned model.
#' @param ... Other arguments passed to rstan::sampling() for customizing the
#'   Monte Carlo sampler
#' @import rstan
#' @export
biker_estimate <- function(bikerdata,
                         bikerpriors,
                         cores = getOption("mc.cores", default = parallel::detectCores()),
                         meas_error = FALSE,
                         chains = 3L,
                         iter = 1000L,
                         CI = 0.95,
                         chainExtract = 'all',
                         pars = NULL,
                         include = FALSE,
                         ...) {

  #reformat priors to a single list for stan
  bikerpriors <- c(bikerpriors[[2]], bikerpriors[[3]])

  bikerinputs <- compose_biker_inputs(bikerdata, bikerpriors)
  bikerinputs$inc <- 1
  bikerinputs$meas_err <- ifelse(meas_error == TRUE, 1, 0)

  stanfit <- stanmodels[["master"]]

  if (is.null(pars)) {
    pars <- c("man_rhs", "logWSpart",
              "logktn", "logknbar",
              "Sact", "dAact")
  }

  #generate stanfit object (i.e. sample from the posterior using stan)
  fitmodel <- sampling(stanfit, data = bikerinputs,
                  cores = cores, chains = chains, iter = iter,
                  pars = NULL, include = include,
                  ...)

  #extract posterior means, sigmas, and CIs from full posterior approximation
  kpost <- extract(fitmodel, pars='logk', permuted = FALSE) %>%
    reshape2::melt()
  
  if (CI <= 0 || CI >= 1)
    stop("CI must be on the interval (0,1).\n")
  
  alpha <- 1 - CI
  
  nchains <- fitmodel@sim$chains
  if (chainExtract == "all")
    chainExtract <- 1:nchains
  stopifnot(is.numeric(chainExtract))
  
  #get k stats
  kstats <- kpost %>%
    dplyr::mutate(chains = gsub("^chain:", "", {{ chains }})) %>%
    dplyr::filter({{ chains }} %in% chainExtract) %>%
    dplyr::mutate(value = exp(.data$value)) %>%
    dplyr::group_by(.data$parameters) %>%
    dplyr::summarize(mean = mean(.data$value),
                     conf.low = quantile(.data$value, alpha / 2),
                     conf.high = quantile(.data$value, 1 - (alpha / 2)),
                     sigma = sd(.data$value)) %>%
    dplyr::rename(time = .data$parameters) %>%
    dplyr::mutate(time = gsub("^logk\\[", "", .data$time),
                  time = gsub("\\]$", "", .data$time),
                  time = as.numeric(.data$time)) %>%
    dplyr::arrange(.data$time)
  
  kstats
}




