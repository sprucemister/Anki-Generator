concatenate_back_elements <- function(my_back_elements) {
  
  # Initialize "Back" field of card (HTML snippet)
  new_back_item <- ''
  
  # Loop through each element; if it is valid, paste it together
  for (item in my_back_elements) {
    if (item == '' | item == '<br>' | item == '<img src=\".jpg\">') {
    } else {
      if (new_back_item == '') {
        new_back_item <- item
      } else {
        new_back_item <- paste(new_back_item, item, sep = '<br>')
      }
    }
  }
  return(new_back_item)
}
