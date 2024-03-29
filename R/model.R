#' Read Texts
#'
#' This function read texts and creates a tibble. 
#'
#' @param texts Input. keyATM takes dfm, data.frame, tibble, and a vector of file paths.
#'
#' @return A list whose elements are splitted texts.
#'
#' @examples
#' \dontrun{
#'  # Use quanteda dfm 
#'  keyATM_docs <- keyATM_read(quanteda_dfm) 
#'   
#'  # Use data.frame or tibble (texts should be stored in a column named `text`)
#'  keyATM_docs <- keyATM_read(data_frame_object) 
#'  keyATM_docs <- keyATM_read(tibble_object) 
#' 
#'  # Use a vector that stores full paths to the files  
#'  files <- list.files(doc_folder, pattern = "*.txt", full.names = T) 
#'  keyATM_docs <- keyATM_read(files) 
#' }
#'
#' @import magrittr
#' @export
keyATM_read <- function(texts, encoding = "UTF-8", check = TRUE)
{

  # Detect input
  if ("tbl" %in% class(texts)) {
    message("Using tibble.")
    text_dfm <- NULL
    files <- NULL
    text_df <- texts
  } else if ("data.frame" %in% class(texts)) {
    message("Using data.frame.")
    text_dfm <- NULL
    files <- NULL
    text_df <- tibble::as_tibble(texts)
  } else if (class(texts) == "dfm") {
    message("Using quanteda dfm.")
    text_dfm <- texts
    files <- NULL
    text_df <- NULL
  } else if (class(texts) == "character") {
    warning("Reading from files. Please make sure files are preprocessed.")
    text_dfm <- NULL
    files <- texts
    text_df <- NULL
    message(paste0("Encoding: ", encoding))
  } else {
    stop("Check `texts` argument.\n
         It can take quanteda dfm, data.frame, tibble, and a vector of characters.")  
  }


  # Read texts

  # If you have quanteda object
  if (!is.null(text_dfm)) {
    vocabulary <- colnames(text_dfm)
    text_df <- tibble::tibble(
                              text_split = 
                                apply(text_dfm, 1,
                                       function(x){
                                        return(rep(vocabulary, x))
                                       }
                                    )
                             )
    names(text_df$text_split) <- NULL
  }else{
    ## preprocess each text
    # Use files <- list.files(doc_folder, pattern = "txt", full.names = T) when you pass
    if (is.null(text_df)) {
      text_df <- tibble::tibble(text = unlist(lapply(files,
                                                 function(x)
                                                 { 
                                                     paste0(readLines(x, encoding = encoding),
                                                           collapse = "\n") 
                                                 })))
    }
    text_df <- text_df %>% dplyr::mutate(text_split = stringr::str_split(text, pattern = " "))
  }

  W_raw <- text_df %>% dplyr::pull(text_split)

  if (check) {
    check_vocabulary(unique(unlist(W_raw, use.names = F, recursive = F))) 
  }

  class(W_raw) <- c("keyATM_docs", class(W_raw))

  return(W_raw)
}


#' @noRd
#' @export
print.keyATM_docs <- function(x, ...)
{
  cat(paste0("keyATM_docs object of ",
                 length(x), " documents",
                 ".\n"
                )
      )
}


#' @noRd
#' @export
summary.keyATM_docs <- function(object, ...)
{
  doc_len <- sapply(object, length)
  cat(paste0("keyATM_docs object of: ",
              length(object), " documents",
              ".\n",
              "Length of documents:",
              "\n  Avg: ", round(mean(doc_len), 3),
              "\n  Min: ", round(min(doc_len), 3),
              "\n  Max: ", round(max(doc_len), 3),
              "\n   SD: ", round(sd(doc_len), 3),
              "\n"
             )  
         )
}



#' Visualize texts
#'
#' This function visualizes the proportion of keywords in the documents.
#'
#' @param docs A list of texts read via \code{keyATM_read()} function
#' @param keywords A list of keywords
#' @param prune Prune keywords that do not appear in `docs`
#' @param label_size The size of the keyword labels
#'
#' @return A list containing \describe{
#'    \item{figure}{a ggplot2 object}
#'    \item{values}{a tibble object that stores values}
#'    \item{keywords}{a list of keywords that appear in documents}
#' }
#'
#' @examples
#' \dontrun{
#'  # Prepare a keyATM_docs object
#'  keyATM_docs <- keyATM_read(input) 
#'   
#'  # Keywords are in a list  
#'  keywords <- list(
#'                    c("education", "child", "student"),  # Education
#'                    c("public", "health", "program"),  # Health
#'                  )
#'
#'  # Visualize keywords
#'  keyATM_viz <- visualize_keywords(keyATM_docs, keywords)
#'
#'  # View a figure
#'  keyATM_viz
#'    # Or: `keyATM_viz$figure`
#' 
#'  # Save a figure 
#'  save_fig(keyATM_viz, filename)
#'
#' }
#'
#' @import magrittr
#' @import ggplot2
#' @export
visualize_keywords <- function(docs, keywords, prune = TRUE, label_size = 3.2)
{
  # Check type
  check_arg_type(docs, "keyATM_docs", "Please use `keyATM_read()` to read texts.")
  check_arg_type(keywords, "list")
  c <- lapply(keywords, function(x){check_arg_type(x, "character")})

  unlisted <- unlist(docs, recursive = FALSE, use.names = FALSE)


  # Check keywords
  keywords <- check_keywords(unique(unlisted), keywords, prune)

  # Organize data
  unnested_data <- tibble::tibble(text_split = unlisted)
  totalwords <- nrow(unnested_data)

  unnested_data %>%
    dplyr::rename(Word = text_split) %>%
    dplyr::group_by(Word) %>%
    dplyr::summarize(WordCount = dplyr::n()) %>%
    dplyr::ungroup() %>%
    dplyr::mutate(`Proportion(%)` = round(WordCount / totalwords * 100, 3)) %>%
    dplyr::arrange(desc(WordCount)) %>%
    dplyr::mutate(Ranking = 1:(dplyr::n())) -> data

  keywords <- lapply(keywords, function(x){unlist(strsplit(x," "))})
  ext_k <- length(keywords)
  max_num_words <- max(unlist(lapply(keywords, function(x){length(x)}), use.names = F))

  # Make keywords_df
  keywords_df <- data.frame(Topic = 1, Word = 1)
  tnames <- names(keywords)
  for(k in 1:ext_k){
    words <- keywords[[k]]
    numwords <- length(words)
    if (is.null(tnames)) {
      topicname <- paste0("Topic", k)
    } else {
      topicname <- paste0(k, "_", tnames[k]) 
    }

    for(w in 1:numwords) {
      keywords_df <- rbind(keywords_df, data.frame(Topic = topicname, Word = words[w]))
    }
  }
  keywords_df <- keywords_df[2:nrow(keywords_df), ]
  keywords_df$Topic <- factor(keywords_df$Topic, levels = unique(keywords_df$Topic))

  dplyr::right_join(data, keywords_df, by = "Word") %>%
    dplyr::group_by(Topic) %>%
    dplyr::arrange(desc(WordCount)) %>%
    dplyr::mutate(Ranking  =  1:(dplyr::n())) %>%
    dplyr::arrange(Topic, Ranking) -> temp

  # Visualize
  visualize_keywords <- 
    ggplot(temp, aes(x = Ranking, y=`Proportion(%)`, colour = Topic)) +
      geom_line() +
      geom_point() +
      ggrepel::geom_label_repel(aes(label = Word), size = label_size,
                       box.padding = 0.20, label.padding = 0.12,
                       arrow = arrow(angle = 10, length = unit(0.10, "inches"),
                                   ends = "last", type = "closed"),
                       show.legend = F) +
      scale_x_continuous(breaks = 1:max_num_words) +
      ylab("Proportion (%)") +
      theme_bw()

  keyATM_viz <- list(figure = visualize_keywords, values = temp, keywords = keywords)
  class(keyATM_viz) <- c("keyATM_viz", class(keyATM_viz))
  
  return(keyATM_viz)

}


check_keywords <- function(unique_words, keywords, prune)
{
  # Prune keywords that do not appear in the corpus
  keywords_flat <- unlist(keywords, use.names = F, recursive = F)
  non_existent <- keywords_flat[!keywords_flat %in% unique_words]

  if (prune){
    # Prune keywords 
    if (length(non_existent) != 0) {
     if (length(non_existent) == 1) {
       warning("A keyword will be pruned because it does not appear in documents: ",
               paste(non_existent, collapse = ", "))
     } else {
       warning("Keywords will be pruned because they do not appear in documents: ",
               paste(non_existent, collapse = ", "))
     }
    }

    keywords <- lapply(keywords,
                       function(x){
                          x[!x %in% non_existent] 
                       })

  } else {

    # Raise error 
    if (length(non_existent) != 0) {
     if (length(non_existent) == 1) {
       stop("A keyword not found in texts: ", paste(non_existent, collapse = ", "))
     } else {
       stop("Keywords not found in texts: ", paste(non_existent, collapse = ", "))
     }
    } 

  }

  # Check there is at least one keywords in each topic
  num_keywords <- unlist(lapply(keywords, length))
  check_zero <- which(as.vector(num_keywords) == 0)

  if (length(check_zero) != 0) {
    zero_names <- names(keywords)[check_zero]
    stop(paste0("All keywords are pruned. Please check: ", paste(zero_names, collapse = ", ")))
  }

  return(keywords)
}


#' @noRd
#' @export
print.keyATM_viz <- function(x, ...)
{
  print(x$figure)  
}


#' @noRd
#' @export
summary.keyATM_viz <- function(object, ...)
{
  return(object$values)  
}


#' @noRd
#' @export
save.keyATM_viz <- function(x, file = stop("'file' must be specified"))
{
  saveRDS(x, file = file)
}


#' @noRd
#' @export
save_fig.keyATM_viz <- function(x, file = stop("'file' must be specified"))
{
  ggplot2::ggsave(x$figure, file = file)
}



#' Fit keyATM model
#'
#' Select and specify one of the keyATM models and fit the model.
#'
#'
#' @param docs texts read via \code{keyATM_read()}
#' @param model keyATM model: "base", "covariates", and "dynamic"
#' @param no_keyword_topics the number of regular topics
#' @param keywords a list of keywords
#' @param model_settings a list of model specific settings
#' @param priors a list of priors of parameters
#' @param options a list of options
#'
#' @return keyATM_model object, which is a list containing \describe{
#'   \item{W}{a list of vectors of word indexes}
#'   \item{Z}{a list of vectors of topic indicators isomorphic to W}
#'   \item{S}{a list}
#'   \item{model}{the name of the model}
#'   \item{keywords}{}
#'   \item{keywords_raw}{}
#'   \item{no_keyword_topics}{the number of regular topics}
#'   \item{model_settings}{a list of settings}
#'   \item{priors}{a list of priors}
#'   \item{options}{a list of options}
#'   \item{stored_values}{a list of stored_values}
#'   \item{call}{details of the function call}
#' } 
#'
keyATM_fit <- function(docs, model, no_keyword_topics,
                       keywords = list(), model_settings = list(),
                       priors = list(), options = list()) 
{
  ##
  ## Check
  ##

  # Check type
  check_arg_type(docs, "keyATM_docs", "Please use `keyATM_read()` to read texts.")
  if (!is.integer(no_keyword_topics) & !is.numeric(no_keyword_topics))
    stop("`no_keyword_topics` is neigher numeric nor integer.")

  no_keyword_topics <- as.integer(no_keyword_topics)

  if (!model %in% c("base", "cov", "hmm", "lda", "ldacov", "ldahmm")) {
    stop("Please select a correct model.")  
  }

  info <- list(
                models_keyATM = c("base", "cov", "hmm"),
                models_lda = c("lda", "ldacov", "ldahmm")
              )
  keywords <- check_arg(keywords, "keywords", model, info)

  # Get Info
  info$num_doc <- length(docs)
  info$keyword_k <- length(keywords)
  info$total_k <- length(keywords) + no_keyword_topics

  # Set default values
  model_settings <- check_arg(model_settings, "model_settings", model, info)
  priors <- check_arg(priors, "priors", model, info)
  options <- check_arg(options, "options", model, info)

  ##
  ## Initialization
  ##
  message("Initializing the model...")
  set.seed(options$seed)

  # W
  info$wd_names <- unique(unlist(docs, use.names = F, recursive = F))
  check_vocabulary(info$wd_names)

  info$wd_map <- hashmap::hashmap(info$wd_names, 1:length(info$wd_names) - 1L)
  W <- lapply(docs, function(x){ info$wd_map[[x]] })


  # Check keywords
  keywords <- check_keywords(info$wd_names, keywords, options$prune)

  keywords_raw <- keywords  # keep raw keywords (not word_id)
  keywords_id <- lapply(keywords, function(x){ as.integer(info$wd_map$find(x)) })

  # Assign S and Z
  if (model %in% info$models_keyATM) {
    res <- make_sz_key(W, keywords, info)
    S <- res$S
    Z <- res$Z
  }else{
    # LDA based models
    res <- make_sz_lda(W, info)
    S <- res$S
    Z <- res$Z
  }
  rm(res)

  # Organize
  stored_values <- list()

  if (model %in% c("base", "lda")) {
    if (options$estimate_alpha)
      stored_values$alpha_iter <- list()  
  }

  if (model %in% c("hmm", "ldahmm")) {
    options$estimate_alpha <- 1
    stored_values$alpha_iter <- list()  
  }


  if (model %in% c("cov", "ldacov")) {
    stored_values$Lambda_iter <- list()
  }

  if (model %in% c("hmm", "ldahmm")) {
    stored_values$R_iter <- list()

    if (options$store_transition_matrix) {
      stored_values$P_iter <- list()  
    }
  }

  if (options$store_theta)
    stored_values$Z_tables <- list()

  key_model <- list(
                    W = W, Z = Z, S = S,
                    model = abb_model_name(model),
                    keywords = keywords_id, keywords_raw = keywords_raw,
                    no_keyword_topics = no_keyword_topics,
                    vocab = info$wd_names,
                    model_settings = model_settings,
                    priors = priors,
                    options = options,
                    stored_values = stored_values,
                    model_fit = list(),
                    call = match.call()
                   )

  rm(info)
  class(key_model) <- c("keyATM_model", model, class(key_model))

  if (options$iterations == 0) {
    message("`options$iterations` is 0. keyATM returns an initialized object.")  
    return(key_model)
  }


  ##
  ## Fitting
  ##
  message(paste0("Fitting the model. ", options$iterations, " iterations..."))
  set.seed(options$seed)

  if (model == "base") {
    key_model <- keyATM_fit_base(key_model, iter = options$iterations)
  } else if (model == "cov") {
    key_model <- keyATM_fit_cov(key_model, iter = options$iteration)
  } else if (model == "hmm") {
    key_model <- keyATM_fit_HMM(key_model, iter = options$iteration)  
  } else if (model == "lda") {
    key_model <- keyATM_fit_LDA(key_model, iter = options$iteration)
  } else if (model == "ldacov") {
    key_model <- keyATM_fit_LDAcov(key_model, iter = options$iteration)
  } else if (model == "ldahmm") {
    key_model <- keyATM_fit_LDAHMM(key_model, iter = options$iteration)  
  } else {
    stop("Please check `mode`.")  
  }

  class(key_model) <- c("keyATM_fitted", class(key_model))
  return(key_model)
}




#' @noRd
#' @export
print.keyATM_model <- function(x, ...)
{
  cat(
      paste0(
             "keyATM_model object for the ",
             x$model,
             " model.",
             "\n"
            )
     )
}


#' @noRd
#' @export
summary.keyATM_model <- function(object, ...)
{
  cat(
      paste0(
             "keyATM_model object for the ",
             object$model,
             " model.",
             "\n"
            )
     )
}


#' @noRd
#' @export
save.keyATM_model <- function(x, file = stop("'file' must be specified"))
{
  saveRDS(x, file = file)
}


#' @noRd
#' @export
print.keyATM_fitted <- function(x, ...)
{
  cat(
      paste0(
             "keyATM_model object for the ",
             x$model,
             " model. ",
             x$options$iterations, " iterations.\n",
             length(x$W), " documents | ",
             length(x$keywords), " keyword topics",
             "\n"
      )
     )
}


#' @noRd
#' @export
summary.keyATM_fitted <- function(object, ...)
{
  cat(
      paste0(
             "keyATM_model object for the ",
             object$model,
             " model. ",
             object$options$iterations, " iterations.\n",
             length(object$W), " documents | ",
             length(object$keywords), " keyword topics",
             "\n"
      )
     )
}


#' @noRd
#' @export
save.keyATM_fitted <- function(x, file = stop("'file' must be specified"))
{
  saveRDS(x, file = file)
}


check_arg <- function(obj, name, model, info = list())
{
  if (name == "keywords") {
    return(check_arg_keywords(obj, model, info))
  }

  if (name == "model_settings") {
    return(check_arg_model_settings(obj, model, info))  
  }

  if (name == "priors") {
    return(check_arg_priors(obj, model, info))  
  }

  if (name == "options") {
    return(check_arg_options(obj, model, info))  
  }
}


check_arg_keywords <- function(keywords, model, info)
{
  check_arg_type(keywords, "list")

  if (length(keywords) == 0 & model %in% info$models_keyATM) {
    stop("Please provide keywords.")  
  }

  if (length(keywords) != 0 & model %in% info$models_lda) {
    stop("This model does not take keywords.")  
  }


  # Name of keywords topic
  if (model %in% info$models_keyATM) {
    c <- lapply(keywords, function(x){check_arg_type(x, "character")})
  
    if (is.null(names(keywords))) {
      names(keywords)  <- paste0(1:length(keywords))
    }else{
      names(keywords)  <- paste0(1:length(keywords), "_", names(keywords))
    }

  }

  return(keywords)
}

show_unused_arguments <- function(obj, name, allowed_arguments)
{
  unused_input <- names(obj)[! names(obj) %in% allowed_arguments]
  if (length(unused_input) != 0)
    stop(paste0(
                "keyATM doesn't recognize some of the arguments ",
                "in ", name, ": ",
                paste(unused_input, collapse=", ")
               )
        )
}


check_arg_model_settings <- function(obj, model, info)
{
  check_arg_type(obj, "list")
  allowed_arguments <- c()

  if (model %in% c("cov", "ldacov")) {
     if (is.null(obj$covariates_data)) {
      stop("Please provide `obj$covariates_data`.")  
    }

    if (nrow(obj$covariates_data) != info$num_doc) {
      stop("The row of `model_settings$covariates_data` should be the same as the number of documents.")  
    }

    if (sum(is.na(obj$covariates_data)) != 0) {
      stop("Covariate data should not contain missing values.")
    }

    if (is.null(obj$covariates_formula)) {
      warning("`covariates_formula` is not provided. keyATM uses the matrix as it is.")
      obj$covariates_formula <- NULL  # do not need to change the matrix
      obj$covariates_data_use <- as.matrix(obj$covariates_data) 
    } else if (is.formula(obj$covariates_formula)) {
      message("Convert covariates data using `model_settings$covariates_formula`.")
      obj$covariates_data_use <- stats::model.matrix(obj$covariates_formula,
                                                     as.data.frame(obj$covariates_data))
    } else {
      stop("Check `model_settings$covariates_formula`.")  
    }


    if (is.null(obj$standardize)) {
      obj$standardize <- TRUE 
    }

    # Check if it works as a valid regression 
    temp <- as.data.frame(obj$covariates_data_use)
    temp$y <- stats::rnorm(nrow(obj$covariates_data_use))

    if ("(Intercept)" %in% colnames(obj$covariates_data_use)){
      fit <- stats::lm(y ~ 0 + ., data = temp)  # data.frame alreayd includes the intercept
      if (NA %in% fit$coefficients) {
        stop("Covariates are invalid.")    
      }    
    } else {
      fit <- stats::lm(y ~ 0 + ., data = temp)
      if (NA %in% fit$coefficients) {
        stop("Covariates are invalid.")    
      }
    }

    if (obj$standardize) {
      standardize <- function(x){return((x - mean(x)) / stats::sd(x))}

      if ("(Intercept)" %in% colnames(obj$covariates_data_use)) {
        # Do not standardize the intercept
        colnames_keep <- colnames(obj$covariates_data_use)
        obj$covariates_data_use <- cbind(obj$covariates_data_use[, 1, drop=FALSE],
                                         apply(as.matrix(obj$covariates_data_use[, -1]), 2,
                                               standardize) 
                                        )
        colnames(obj$covariates_data_use) <- colnames_keep
      } else {
        obj$covariates_data_use <- apply(obj$covariates_data_use, 2, standardize)
      }
    }

    allowed_arguments <- c(allowed_arguments, "covariates_data", "covariates_data_use",
                           "covariates_formula", "standardize", "info")
  }


  if (model %in% c("hmm", "ldahmm")) {
    if (is.null(obj$num_states)) {
      stop("`model_settings$num_states` is not provided.")  
    }

    if (is.null(obj$time_index)) {
      stop("`model_settings$time_index` is not provided.")
    }

    if (length(obj$time_index) != info$num_doc) {
      stop("The length of the `model_settings$time_index` does not match with the number of documents.")  
    }
    
    if (min(obj$time_index) != 1 | max(obj$time_index) > info$num_doc) {
      stop("`model_settings$time_index` should start from 1 and not exceed the number of documents.")
    }

    if (max(obj$time_index) < obj$num_states)
      stop("`model_settings$num_states` should not exceed the maximum of `model_settings$time_index`.")

    check <- unique(obj$time_index[2:length(obj$time_index)] - lag(obj$time_index)[2:length(obj$time_index)])
    if (sum(!unique(check) %in% c(0,1)) != 0)
      stop("`model_settings$num_states` does not increment by 1.")

    obj$time_index <- as.integer(obj$time_index)

    allowed_arguments <- c(allowed_arguments, "num_states", "time_index")
    
  }

  show_unused_arguments(obj, "`model_settings`", allowed_arguments)

  return(obj)
}


check_arg_priors <- function(obj, model, info)
{
  check_arg_type(obj, "list")
  # Base arguments
  allowed_arguments <- c("beta")

  # prior of pi
  if (model %in% info$models_keyATM) {
    if (is.null(obj$gamma)) {
      obj$gamma <- matrix(1.0, nrow = info$total_k, ncol = 2)  
    }

    if (!is.null(obj$gamma)) {
      if (dim(obj$gamma)[1] != info$total_k)  
        stop("Check the dimension of `priors$gamma`")
      if (dim(obj$gamma)[2] != 2)  
        stop("Check the dimension of `priors$gamma`")
    }


    if (info$keyword_k < info$total_k) {
      # Regular topics are used in keyATM models
      # Priors for regular topics should be 0
      if (sum(obj$gamma[(info$keyword_k+1):info$total_k, ]) != 0) {
        obj$gamma[(info$keyword_k+1):info$total_k, ] <- 0
      }
    }

    allowed_arguments <- c(allowed_arguments, "gamma")
  }


  # beta
  if (is.null(obj$beta)) {
    obj$beta <- 0.01  
  }

  if (model %in% info$models_keyATM) {
    if (is.null(obj$beta_s)) {
      obj$beta_s <- 0.1  
    }  
    allowed_arguments <- c(allowed_arguments, "beta_s")
  }


  # alpha
  if (model %in% c("base", "lda")) {
    if (is.null(obj$alpha)) {
      obj$alpha <- rep(1/info$total_k, info$total_k)
    }
    if (length(obj$alpha) != info$total_k) {
      stop("Starting alpha must be a vector of length ", info$total_k)
    }
    allowed_arguments <- c(allowed_arguments, "alpha")
  
  }

  show_unused_arguments(obj, "`priors`", allowed_arguments)

  return(obj)
}


check_arg_options <- function(obj, model, info)
{
  check_arg_type(obj, "list")
  allowed_arguments <- c("seed", "llk_per", "thinning",
                         "iterations", "verbose",
                         "use_weights", "prune",
                         "store_theta", "slice_shape")

  # llk_per
  if (is.null(obj$llk_per))
    obj$llk_per <- 10L

  if (!is.numeric(obj$llk_per) | obj$llk_per < 0 | obj$llk_per%%1 != 0) {
      stop("An invalid value in `options$llk_per`")  
  }


  # verbose
  if (is.null(obj$verbose)) {
    obj$verbose <- 0L 
  } else {
    obj$verbose <- as.integer(obj$verbose)
    if (!obj$verbose %in% c(0, 1)) {
      stop("An invalid value in `options$verbose`")  
    }
  }

  # thinning
  if (is.null(obj$thinning))
    obj$thinning <- 5L

  if (!is.numeric(obj$thinning) | obj$thinning < 0| obj$thinning%%1 != 0) {
      stop("An invalid value in `options$thinning`")  
  }

  # seed
  if (is.null(obj$seed))
    obj$seed <- floor(stats::runif(1)*1e5)

  # iterations
  if (is.null(obj$iterations))
    obj$iterations <- 1500L
  if (!is.numeric(obj$iterations) | obj$iterations < 0| obj$iterations%%1 != 0) {
      stop("An invalid value in `options$iterations`")  
  }

  # Store theta
  if (is.null(obj$store_theta)) {
    obj$store_theta <- 0L
  } else {
    obj$store_theta <- as.integer(obj$store_theta)  
    if (!obj$store_theta %in% c(0, 1)) {
      stop("An invalid value in `options$store_theta`")  
    }
  }

  # Estimate alpha
  if (model %in% c("base", "lda")) {
    if (is.null(obj$estimate_alpha)) {
      obj$estimate_alpha <- 1L
    } else {
      obj$estimate_alpha <- as.integer(obj$estimate_alpha)  
      if (!obj$estimate_alpha %in% c(0, 1)) {
        stop("An invalid value in `options$estimate_alpha`")  
      }

    }
    allowed_arguments <- c(allowed_arguments, "estimate_alpha")
  }
  
  # Slice shape
  if (is.null(obj$slice_shape)) {
    # parameter for slice sampling
    obj$slice_shape <- 1.2
  }
  if (!is.numeric(obj$slice_shape) | obj$slice_shape < 0) {
      stop("An invalid value in `options$slice_shape`")  
  }

  # Use weights
  if (is.null(obj$use_weights)) {
    obj$use_weights <- 1L 
  } else {
    obj$use_weights <- as.integer(obj$use_weights)
    if (!obj$use_weights %in% c(0, 1)) {
      stop("An invalid value in `options$use_weights`")  
    }
  }

  # Prune keywords
  if (is.null(obj$prune)) {
    obj$prune <- 1L 
  } else {
    obj$prune <- as.integer(obj$prune)
    if (!obj$prune %in% c(0, 1)) {
      stop("An invalid value in `options$prune`")  
    }
  }

  # Store transition matrix in Dynamic models
  if (model %in% c("hmm", "ldahmm")) {
    if (is.null(obj$store_transition_matrix)) {
      obj$store_transition_matrix <- 0L  
    }
    if (!obj$store_transition_matrix %in% c(0, 1)) {
      stop("An invalid value in `options$store_transition_matrix`")  
    }
    allowed_arguments <- c(allowed_arguments, "store_transition_matrix")
  }

  # Check unused arguments
  show_unused_arguments(obj, "`options`", allowed_arguments)
  return(obj)
}


check_vocabulary <- function(vocab)
{
  if (" " %in% vocab) {
    stop("A space is recognized as a vocabulary. Please remove an empty document or consider using quanteda::dfm.")  
  }

  if ("" %in% vocab) {
    stop('A blank `""` is recognized as a vocabulary. Please review preprocessing steps.')  
  }

  if (sum(stringr::str_detect(vocab, "^[:upper:]+$")) != 0) {
    warning('Upper case letters are used. Please review preprocessing steps.')  
  }

  if (sum(stringr::str_detect(vocab, "\t")) != 0) {
    warning('Tab is detected in the vocabulary. Please review preprocessing steps.')  
  }

  if (sum(stringr::str_detect(vocab, "\n")) != 0) {
    warning('A line break is detected in the vocabulary. Please review preprocessing steps.')  
  }
}


make_sz_key <- function(W, keywords, info)
{
  # zs_assigner maps keywords to category ids
  key_wdids <- unlist(lapply(keywords, function(x){ info$wd_map$find(x) }))
  cat_ids <- rep(1:(info$keyword_k) - 1L, unlist(lapply(keywords, length)))

  if (length(key_wdids) == length(unique(key_wdids))) {
    #
    # No keyword appears more than once
    #
    zs_assigner <- hashmap::hashmap(as.integer(key_wdids), as.integer(cat_ids))

    # if the word is a keyword, assign the appropriate (0 start) Z, else a random Z
    topicvec <- 1:(info$total_k) - 1L
    make_z <- function(s, topicvec){
      zz <- zs_assigner[[s]] # if it is a keyword word, we already know the topic
      zz[is.na(zz)] <- sample(topicvec,
                              sum(is.na(zz)),
                              replace = TRUE)
      return(zz)
    }

  }else{
    #
    # Some keywords appear multiple times
    #
    keys_df <- data.frame(wid = key_wdids, cat = cat_ids)
    keys_char <- sapply(unique(key_wdids),
                        function(x){
                          paste(as.character(keys_df[keys_df$wid == x, "cat"]), collapse=",")
                        })
    zs_hashtable <- hashmap::hashmap(as.integer(unique(key_wdids)), keys_char)

    zs_assigner <- function(s){
      topic <- zs_hashtable[[s]]
      topic <- strsplit(topic, split=",")
      topic <- lapply(topic, sample, 1)
      topic <- as.integer(unlist(topic))
      return(topic)
    }

    # if the word is a seed, assign the appropriate (0 start) Z, else a random Z
    topicvec <- 1:(info$total_k) - 1L
    make_z <- function(s, topicvec){
      zz <- zs_assigner(s) # if it is a seed word, we already know the topic
      zz[is.na(zz)] <- sample(topicvec,
                              sum(is.na(zz)),
                              replace = TRUE)
      return(zz)
    }
  }


  ## ss indicates whether the word comes from a seed topic-word distribution or not
  make_s <- function(s){
    key <- as.numeric(s %in% key_wdids) # 1 if they're a seed
    # Use s structure
    s[key == 0] <- 0L # non-keyword words have s = 0
    s[key == 1] <- sample(0:1, length(s[key == 1]), prob = c(0.3, 0.7), replace = TRUE)
      # keywords have x = 1 probabilistically
    return(s)
  }

 S <- lapply(W, make_s)
 Z <- lapply(W, make_z, topicvec)

 return(list(S = S, Z = Z))
}


make_sz_lda <- function(W, info)
{
  topicvec <- 1:(info$total_k) - 1L
  make_z <- function(x, topicvec){
    zz <- sample(topicvec,
                 length(x),
                 replace = TRUE)
    return(as.integer(zz))
  }  


 Z <- lapply(W, make_z, topicvec)

 return(list(S = list(), Z = Z))
}



