# Contextualizer for R by Ian Douglas (idouglas@utexas.edu)
# Implementation of Ryan Boyd's Contextualizer software (https://www.ryanboyd.io/software/context/)

# 1. Define the function that will conduct contextualization
Contextualize = function(data, column_index, word, N = 10, drop_stop_words = FALSE) 
{
  if(!require(tidytext)) {stop('The tidytext package is required. run `install.packages("tidytext"); library(tidytext)` and try again')}
  if(!require(magrittr)) {stop('The magrittr package is required. run `install.packages("magrittr"); library(magrittr)` and try again')}
  if(!require(purrr)) {stop('The purrr package is required. run `install.packages("purrr"); library(purrr)` and try again')}
  if(!require(tibble)) {stop('The tibble package is required. run `install.packages("tibble"); library(tibble)` and try again')}
  corpus = data.frame(txt = do.call(paste, as.list(data[, column_index])),
                      stringsAsFactors = F)
  tokens = unnest_tokens(corpus, word, txt)
  reduce(purrr::map(word, function(W) {
    if (drop_stop_words) {
      tokens = tokens %>% 
        anti_join(stop_words[!grepl(paste0('^', tolower(W), '$'), stop_words$word), ], by = 'word')
    }
    reduce(purrr::map(grep(paste0('^', tolower(W), '$'), tokens$word), ~{
      if (.x > 1) {before = as.vector(unlist(tokens$word))[(max(.x - N, 0)) : (.x - 1)]} else before = NA
      if (.x != nrow(tokens)) {after = as.vector(unlist(tokens$word))[(.x + 1) : min(.x + N, nrow(tokens))]} else after = NA
      assign('bef', before, pos = .GlobalEnv)
      assign('aft', after, pos = .GlobalEnv)
      data.frame(before = do.call(paste, as.list(before)), 
                 after = do.call(paste, as.list(after)), 
                 word = W,
                 WC_before = if (is.na(before) && length(before) == 1) {NA} else length(before),
                 WC_after = if (is.na(after) && length(after) == 1) {NA} else length(after),
                 stringsAsFactors = F)
    }), rbind)
  }), rbind) %>% as.data.frame %>% remove_rownames
}

# 2. Run the function as follows:
# Run Contextualize(data, column_index, word, N, drop_stop_words)
# Supply to the first argument (data) the data frame containing:
#### A column containing all of the text entries on each subsequent row. (this could be 1 row)
# column_index can be the name of that column, or it's position in the data frame (first column = 1, etc.)
# word: the word for which you wish to return the surrounding N words.
##### `word` can also be a vector or list of words, such as c('he', 'she') or list('he', 'she')
# N: the number around each word you wish to return
# if drop_stop_words is TRUE, then you can also ignore stop words in the output. Note,
# if your word of choice IS a stop word, then you will get no results.

# Example
# text_entry1 = "WordA wordB wordC wordD wordE wordF target wordH wordI wordJ wordK wordL wordM"
# text_entry2 = "WordA wordB wordC wordD wordE wordF target wordH wordI wordJ wordK wordL wordM"
# 
# df <- data.frame(TextEntries = c(text_entry1, text_entry2))
# df
#                                                                      TextEntries
# 1 WordA wordB wordC wordD wordE wordF target wordH wordI wordJ wordK wordL wordM
# 2 WordA wordB wordC wordD wordE wordF target wordH wordI wordJ wordK wordL wordM

# Contextualize(data = df, column_index = 'TextEntries', word = 'target', N = 5, drop_stop_words = FALSE)
# # A tibble: 2 x 5
#     before                        after                         word  WC_before WC_after
#     <chr>                         <chr>                         <chr>      <int>    <int>
#   1 wordb wordc wordd worde wordf wordh wordi wordj wordk wordl target         5        5
#   2 wordb wordc wordd worde wordf wordh wordi wordj wordk wordl target         5        5
