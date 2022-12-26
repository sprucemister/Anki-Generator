get_kanji_info <- function(my_kanji) {
  
  # Initialize kanji info piece of card (in HTML)
  kanji_info <- ''
  
  # Split the learning word into its component characters
  splitted_kanji <- strsplit(my_kanji,'')
  
  # Loop through each chracter and if it matches a Heisig word,
  ## create and HTML snippet of the kanji info
  for (i in 1:length(splitted_kanji[[1]])) {
    my_keyword <- df.heisig_keywords %>%
      filter(kanji == splitted_kanji[[1]][i]) %>%
      pull(keyword) 
    if (is_empty(my_keyword) == FALSE) {
      kanji_info <- paste0(kanji_info, 
                          '<br>',
                          paste0(splitted_kanji[[1]][i], ' = ', my_keyword))
    }
  }
  return(kanji_info)
}