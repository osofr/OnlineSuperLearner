#' Simulator.Slow
#'
#' @docType class
#' @importFrom R6 R6Class
Simulator.Slow <- R6Class("Simulator.Slow",
  private =
    list(
        validateMechanism = function(fun) {
          if (!mode(fun)=="function") {
            throw("A mechanism should be of mode 'function', not, ", mode(fun))
          }
          if (is.null(attr(fun, "memory"))) {
            throw("Attribute 'memory' is missing, this is not a valid mechanism")
          }
          if (is.null(attr(fun, "family"))) {
            throw("Attribute 'family' is missing, this is not a valid mechanism")
          }
          return(fun)
        },

        validateIntervention = function(ll) {
          ## ...
          return(ll)
        }
        ),
  public =
    list(
        initialize = function() {
        },

        simulateWAY = function(by=1,
                                qw=self$generateMechanism(0, family="gaussian"),
                                ga=self$generateMechanism(0, family="bernoulli"),
                                Qy=self$generateMechanism(0, family="bernoulli"),
                                intervention=NULL,
                                verbose=FALSE,
                                version="slow") {
          ## Retrieving arguments
          by <- Arguments$getInteger(by, c(1, Inf))
          qw <- private$validateMechanism(qw)
          ga <- private$validateMechanism(ga)
          Qy <- private$validateMechanism(Qy)
          if (!is.null(intervention)) {
            intervention <- private$validateIntervention(intervention)
          }
          verbose <- Arguments$getVerbose(verbose)

          families <- c(W=attr(qw, "family"),
                        A=attr(ga, "family"),
                        Y=attr(Qy, "family"))

          memories <- c(W=attr(qw, "memory"),
                        A=attr(ga, "memory"),
                        Y=attr(Qy, "memory"))

          rsource <- list(bernoulli=runif,
                          gaussian=rnorm)

          rgen <- list(bernoulli=function(xx, yy){as.integer(xx <= yy)},
                        gaussian=function(xx, yy){xx+yy})

          ## verbose
          if (is.null(intervention)) {
            msg <- "Simulating...\n"
          } else {
            msg <- "Simulating under the specified intervention...\n"
          }
          verbose && cat(verbose, msg)

          init <- rep(NA, by)
          ## sources of randomness
          UU <- cbind(W=init, A=init, Y=init)
          for (ii in 1:3) {
            UU[, ii] <- rsource[[families[ii]]](by)
          }

          WAY <- rep(init, 3)
          if (version=="slow") {
            ## -------------
            ## first version ## must be very slow
            ## -------------
            for (ii in 1:by) {
              past.idx <- self$retrieveRelevantPastWAYScenarioOne("W", ii, memories["W"])
              which.pos <- which(past.idx>0)
              past <- rep(0, memories["W"])
              past[which.pos] <- WAY[past.idx[which.pos]]
              WAY[(ii-1)*3+1] <- rgen[[families[1]]](UU[ii, 1], qw(past))
              ##
              past.idx <- self$retrieveRelevantPastWAYScenarioOne("A", ii, memories["A"])
              which.pos <- which(past.idx>0)
              past <- rep(0, memories["A"])
              past[which.pos] <- WAY[past.idx[which.pos]]
              WAY[(ii-1)*3+2] <- rgen[[families[2]]](UU[ii, 2], ga(past))
              ##
              past.idx <- self$retrieveRelevantPastWAYScenarioOne("Y", ii, memories["Y"])
              which.pos <- which(past.idx>0)
              past <- rep(0, memories["Y"])
              past[which.pos] <- WAY[past.idx[which.pos]]
              WAY[(ii-1)*3+3] <- rgen[[families[3]]](UU[ii, 3], Qy(past))
            }
          } else if (version=="faster") {
            ## --------------
            ## second version ## significantly faster than previous one?
            ## --------------

            #### check how to require libraries 'inline' and 'Rcpp'...

            throw("'Rcpp' version not implemented yet...")

            ## #############
            ## A TEMPLATE...
            ## #############
            ##
            ## generateWAY <- cxxfunction(signature(x="numeric", y="numeric", wt="numeric", param="numeric"),
            ##                            body="
            ##              Rcpp::NumericVector xx(x);
            ##              Rcpp::NumericVector yy(y);
            ##              /*Rcpp::NumericVector aa(alpha);*/
            ##              Rcpp::NumericVector wwtt(wt);
            ##              Rcpp::NumericVector bb(param);
            ##              int n=xx.size();
            ##              Rcpp::NumericVector out(1);
            ##              Rcpp::NumericVector Nb(1);

            ##              Nb[0]=0;
            ##              out[0]=0;
            ##              for(int i=0; i < n; i++){
            ##                Nb[0] +=wwtt[i];
            ##                for(int j=0; j<n; j++){
            ##                  out[0] = out[0] + (1/(1+exp(bb[0]*(xx[i]-xx[j])*(yy[i]-yy[j]))))*wwtt[i]*wwtt[j];
            ##                }
            ##               }
            ##              out[0] = out[0]/(Nb[0]*Nb[0]);


            ##              return out;",
            ##              plugin="Rcpp")
          }
          WAY <- t(matrix(WAY, nrow=3, dimnames=list(c("W", "A", "Y"), NULL)))
          return(WAY)
        },

        generateMechanism = function(param, family=c("bernoulli", "gaussian")) {
          ## Retrieving arguments
          param <- Arguments$getNumerics(param)
          memory <- length(param)-1
          family <- match.arg(family)
          link <- switch(family,
                          bernoulli=expit,
                          gaussian=identity)

          if (length(param)==1) {
            mechanism <- function(xx=numeric(0), par=param, lnk=link, verbose=FALSE) {
              ## Retrieving arguments
              verbose <- Arguments$getVerbose(verbose)
              if (!length(xx)==0) {
                verbose && enter(verbose, "Argument 'xx' not used when argument 'par' has length 1")
                verbose && exit(verbose)
              }
              par <- Arguments$getNumerics(par)
              if (mode(lnk)!="function") {
                throw("Argument 'lnk' must be a link function, not ", mode(lnk))
              }
              ##
              link(par)
            }
          } else {
            mechanism <- function(xx=NA, par=param, lnk=link, verbose=FALSE) {
              ## Retrieving arguments
              xx <- Arguments$getNumerics(xx)
              par <- Arguments$getNumerics(par)
              if (mode(lnk)!="function") {
                throw("Argument 'lnk' must be a link function, not ", mode(lnk))
              }
              verbose <- Arguments$getVerbose(verbose)
              if (length(xx)!=length(param)-1) {
                throw("Length of 'xx' should equal length of 'par' minus one")
              }
              ##
              if (FALSE) {
                link(param[1] + param[-1]%*%xx)
              } else {
                link(param[1] + sum(param[-1]*xx))
              }
            }
          }
          attr(mechanism, "memory") <- memory
          attr(mechanism, "family") <- family
          return(mechanism)
        },


        retrieveRelevantPastWAYScenarioOne = function(of, at, mem) {
          ## Retrieving arguments
          of <- Arguments$getCharacter(of)
          at <- Arguments$getInteger(at, c(1, Inf))
          mem <- Arguments$getInteger(mem, c(0, Inf))
          ##
          if (mem==0) {
            idx <- integer(0)
          } else {
            from <- switch(of,
                            "W"=3*(at-1),
                            "A"=3*(at-1)+1,
                            "Y"=3*(at-1)+2)
            to <- from - mem + 1
            idx <- seq.int(from, to)
          }
          return(idx)
        }
    )
)
