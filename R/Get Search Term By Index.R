get_search_term_by_index <- function(my_df, my_index) {
  my_df %>%
    slice(my_index) %>%
    pull(learning_words)
}