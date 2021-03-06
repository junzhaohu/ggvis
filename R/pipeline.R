#' Create a new "pipeline" object.
#'
#' A pipeline represents a sequence of data transformations, and is the key
#' data structure that underlies the data hierarchy. The most important method
#' for a pipeline is \code{\link{connect}}, which connects together the 
#' multiple pipelines that underlying a ggvis graphic to create a reactive
#' pipeline which is automatically updated when the underlying data changes.
#' 
#' This function allows you to explicitly connect a series of 
#' \code{\link{pipe}} objects into a pipeline. You should never need to call
#' it explicitly as \code{\link{ggvis}} and \code{\link{layer}} automatically
#' create a pipeline using \code{as.pipeline}.
#' 
#' @param ... a list of pipes
#' @param .pipes if you already have the pipes in a list, use this argument.
#' @param x an object to test/coerce
#' @param .id Use a specific ID for this pipeline instead of an auto-generated
#'   one. This is primarily for internal use.
#' @export
#' @keywords internal
#' @examples
#' pipeline(mtcars)
#' as.pipeline(mtcars)
#' pipeline(cars = mtcars)
#'
#' # A pipeline can contain multiple data sets, but only the last one is
#' # returned
#' pipeline(mtcars, sleep)
#'
#' # More useful pipelines combine data and transformations
#' pipeline(mtcars, transform_bin())
#' pipeline(mtcars, by_group(cyl), transform_bin())
pipeline <- function(..., .pipes = list(), .id = NULL) {
  check_empty_args()
  args <- list(...)
  if (is.null(names(args))) {
    names(args) <- vapply(dots(...), deparse2, character(1))
  }
  input <- c(args, .pipes)
  if (length(input) == 0) return()

  names <- names(input) %||% rep(list(NULL), length(input))
  pipes <- trim_to_source(compact(Map(as.pipe, input, names)))

  structure(
    pipes,
    class = "pipeline",
    id = .id
  )
}

#' @export
c.pipeline <- function(x, ...) {
  new_pipes <- lapply(list(...), as.pipeline)

  structure(
    trim_to_source(c(unclass(x), unlist(new_pipes, recursive = FALSE))),
    class = "pipeline"
  )
}

#' @export
`[.pipeline` <- function(x, ...) {
  structure(NextMethod(x, ...), class = "pipeline")
}

#' @export
#' @rdname pipeline
is.pipeline <- function(x) inherits(x, "pipeline")

#' @export
#' @rdname pipeline
as.pipeline <- function(x, ...) {
  UseMethod("as.pipeline")
}

#' @export
as.pipeline.pipeline <- function(x, ...) x

#' @export
as.pipeline.pipe <- function(x, ...) pipeline(x)

#' @export
as.pipeline.default <- function(x, name = NULL, ...) {
  if (is.null(name)) name <- deparse2(substitute(x))
  pipeline(datasource(x, name = name))
}


#' @export
format.pipeline <- function(x, ...) {
  pipes <- vapply(x, format, character(1))
  paste0(pipes, collapse = "\n")
}

#' @export
print.pipeline <- function(x, ...) {
  cat(format(x, ...), "\n", sep = "")
}

# Return an id string, summarizing the pipeline
pipeline_id <- function(x, props) {
  if (length(x) == 0) return(NULL)
  if (!is.null(attr(x, "id"))) return(attr(x, "id"))
  paste(vapply(x, props = props, pipe_id, character(1)), collapse = "_")
}

# Given a pipeline object, trim off all items previous to the last source
trim_to_source <- function(x) {
  sources <- vapply(x, is_source, FUN.VALUE = logical(1))

  if (any(sources))
    x <- x[max(which(sources)):length(x)]

  x
}

# Does this pipeline contain a data source?
has_source <- function(x) {
  any(vapply(x, is_source, FUN.VALUE = logical(1)))
}

#' @export
split_vars.pipeline <- function(x) {
  unlist(lapply(x, split_vars), recursive = FALSE)
}
