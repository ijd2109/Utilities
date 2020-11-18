Contextualize = function(data, column_index, word, drop_stop_words = FALSE) 
{
  if(!require(tidytext)) {stop('The tidytext package is required. run `install.packages("tidytext"); library(tidytext)` and try again')}
  if(!require(magrittr)) {stop('The magrittr package is required. run `install.packages("magrittr"); library(magrittr)` and try again')}
  corpus = data.frame(txt = do.call(paste, as.list(data[, column_index])),
                      stringsAsFactors = F)
  tokens = unnest_tokens(corpus, word, txt)
  if (drop_stop_words) {tokens = tokens %>% anti_join(stop_words)}
  map_dfr(word, function(W) {
    map_dfr(grep(paste0('^', tolower(W), '$'), tokens$word), ~{
      if (.x > 1) {before = tokens$word[(max(.x - 11, 0)) : (.x - 1)]} else before = NA
      if (.x != nrow(tokens)) {after = tokens$word[(.x + 1) : min(.x + 11, nrow(tokens))]} else after = NA
      list(before = do.call(paste, as.list(before)), 
           after = do.call(paste, as.list(after)), 
           word = W,
           WC_before = length(before),
           WC_after = length(after))
    })
  })
}
