# Gets web page of bing image search given a search term
get_page <- function(my_search_term, page_type) {
  
  if (page_type == 'definition') {
    page_url_stem <- "https://jisho.org/search/"
  } else if (page_type == 'example') {
    page_url_stem <- "https://ejje.weblio.jp/sentence/content/"
  } else if (page_type == 'image') {
    page_url_stem <- "https://www.bing.com/images/search?q="
  }
  
  return(tags$iframe(
    src = paste0(page_url_stem, my_search_term)
    , style="width:100%;",  frameborder="0"
    , id="iframe"
    , height = "500px"))
}