toggle_suspend <- function(id_card, my_anki_db_location) {
  
  sql_base <- "UPDATE cards SET queue = CASE WHEN queue <> -1 THEN -1 ELSE 1 END WHERE id='"
  sql_final <- paste0(sql_base, id_card,"'")
  
  mydb <- dbConnect(RSQLite::SQLite(), my_anki_db_location)
  
  dbExecute(mydb, sql_final)
  
  dbDisconnect(mydb)
  
}