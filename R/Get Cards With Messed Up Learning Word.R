get_cards_with_messed_up_learning_word <- function(my_df) {
  bad_ids <- my_df %>%
    filter(nchar(learning_words>2) | grepl('\\d',learning_words)==TRUE)
  
  my_df %>%
    filter(id_card %in% bad_ids$id_card) %>%
    group_by(id_card) %>%
    mutate(group_id = cur_group_id()) %>%
    return()
}