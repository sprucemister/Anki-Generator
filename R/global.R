# TODO: Do I actually want to suspend cards?
library(reactable)
library(shiny)
library(dplyr)
library(DBI)
library(RSQLite)
library(reticulate)
library(stringr)
library(tidyverse)
library(stringi)
library(readr)
library(readxl)
library(shinyWidgets)

# Filepaths
anki_db_location <- "C:\\Users\\Spruce\\AppData\\Roaming\\Anki2\\Emma\\collection.anki2"
images_location <- 'C:\\Users\\Spruce\\AppData\\Roaming\\Anki2\\Emma\\collection.media'

# Get Data (df) From Anki Database
source("inst/Get SQL.R")
mydb <- dbConnect(RSQLite::SQLite(), anki_db_location)
df <- dbGetQuery(mydb, getSQL('inst/Get All Data.sql'))
dbDisconnect(mydb)

# Get Already Learned Cards, these are from Deck "Emma"
## Parse what cards have already been learned from HTML from column `fields`
## Some code here is commented out that can be used to find bad parses
source("R/Get Cards With Messed Up Learning Word.R")
df.already_learned <-
  df %>%
  filter(deck == 'Emma') %>%
  separate(col = fields, sep = '<div>', remove = FALSE, into = c('learning_words_raw',NA)) %>%
  separate(col = learning_words_raw, sep = '&nbsp', remove = FALSE, 
           into = c('learning_words')) %>%
  separate(col = learning_words, sep = ' ', remove = TRUE, 
           into = c('word1','word2','word3','word4','word5','word6','word7','word8')) %>%
  pivot_longer(cols = starts_with('word'), values_to = 'learning_words',
               values_drop_na = TRUE) %>%
  # get_cards_with_messed_up_learning_word() %>% View()
  select(learning_words, id_card, fields) %>%
  unique()


# Read To-Learn List, gives "df.to_learn"
df.to_learn <- readRDS("inst/List - To Learn.RDS") %>%
  # Remove any NA words that may have gotten through
  filter(is.na(MyWord)==FALSE)

# Join To-Learn list with indicator `rank.already_learned`
df.to_learn <- df.already_learned %>%
  mutate(rank.already_learned = 1) %>%
  select(learning_words, rank.already_learned) %>%
  right_join(df.to_learn, 
             by = c("learning_words" = "MyWord")) %>%
  mutate(rank.already_learned = case_when(rank.already_learned == 1 ~ 1,
                                          TRUE ~ 0))

# Get Seen Heisig Cards
df.heisig_seen <- df %>%
  filter(deck == "Heisig experiment")

# Get Heisig Keyword Lookup List
df.heisig_keywords <- read_excel("inst/Heisig_Keywords.xlsx")

# Get Unseen Heisig Characters
df.heisig_unseen <- df.heisig_keywords %>% 
  anti_join(df.heisig_seen, by=c('kanji'='sort_field'))

# Unseen Kanji
## Loop through each letter in each potential word to learn
## If it contains an unseen kanji, flag rank.seen_kanji from 0 to 1
df.to_learn['rank.unseen_kanji'] = 0
for (i in 1:nrow(df.to_learn)) {
  # print(i)
  learning_word <- df.to_learn[i, 1]
  learning_word_splitted <- str_split(learning_word, "")[[1]]
  for (j in 1:length(learning_word_splitted)) {
    # print(learning_word_splitted[j])
    if (learning_word_splitted[j] %in% df.heisig_unseen$kanji) {
      # print('contains seen heisig kanji')
      df.to_learn['rank.unseen_kanji'][i, 1] = 1
    }
  }
}

# Seen Kanji
## Loop through each letter in each potential word to learn
## If it contains an seen kanji, flag rank.seen_kanji from 1 to 0
df.to_learn['rank.seen_kanji'] = 1
for (i in 1:nrow(df.to_learn)) {
  # print(i)
  learning_word <- df.to_learn[i, 1]
  learning_word_splitted <- str_split(learning_word, "")[[1]]
  for (j in 1:length(learning_word_splitted)) {
    # print(learning_word_splitted[j])
    if (learning_word_splitted[j] %in% df.heisig_seen$sort_field) {
      # print('contains seen heisig kanji')
      df.to_learn['rank.seen_kanji'][i, 1] = 0
    }
  }
}

# Delay List
list.delay <- readRDS('inst//List - Delay.RDS')
df.to_learn <- df.to_learn %>%
  left_join(list.delay, by = c('learning_words' = 'word_to_delay')) %>%
  rename(rank.delay_bonus = rank.delay_bonus.y) %>%
  select(-rank.delay_bonus.x) %>%
  # Set NA's to 0
  mutate(rank.delay_bonus = case_when(is.na(rank.delay_bonus)==TRUE ~ 0, TRUE ~ rank.delay_bonus))

# Never Learn List
list.never_learn <- readRDS('inst//List - Never Learn.RDS')
df.to_learn <- df.to_learn %>%
  left_join(list.never_learn, by = c('learning_words' = 'word_to_never_learn')) %>%
  rename(rank.never_learn = rank.never_learn.y) %>%
  select(-rank.never_learn.x) %>%
  # Set NA's to 0
  mutate(rank.never_learn = case_when(is.na(rank.never_learn)==TRUE ~ 0, TRUE ~ rank.never_learn))

# Order Resulting To-Learn List
df.to_learn <- df.to_learn %>%
  slice(sample(1:n())) %>% # randomize order before sorting so cards within same rank randomized 
  arrange(rank.never_learn,
          rank.already_learned,
          rank.unseen_kanji,
          rank.order + rank.delay_bonus,
          rank.seen_kanji)


# Source Python Script
source_python('./py/Create File With Cards.py')

# Test #-------------------------------------------------------------------
# # Test Suspend/Unsuspend
# source("R/Toggle Suspend.R")
# toggle_suspend('1296499533072', anki_db_location)

# # Test Creating a deck
# ## Get Python scripts
# a_my_learning_word <- c('test a','test b','test c','test d')
# a_my_front <- c('test a','test b','test c','test d')
# a_my_back <- c('test a','test b','test c','test d')
# a_my_front_audio <- c('test a','test b','test c','test d')
# a_my_back_audio <- c('test a','test b','test c','test d')
# create_cards(a_my_learning_word, a_my_front, a_my_back, a_my_front_audio, a_my_back_audio)
