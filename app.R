ui <- fluidPage(
  
  # includeCSS("www/my_styles.css"),
  
  tags$head(tags$link(rel = "stylesheet", type = "text/css", 
                      href = "my_styles.css")),
  
  titlePanel("Anki Generator"),
  
  sidebarLayout(
    
    # Sidebar Panel for Controls ----
    sidebarPanel(
      
      fluidRow(style='padding: 0',
               
               column(6, style='padding: 0',
                      
                      # Text Input for Learning Word
                      textInput('front_word','Learning Word', width = '100%'),
                      
                      # Table Containing Words to Learn
                      reactableOutput('first_table', width = '100%', inline=TRUE),
                      
                      actionButton('delay_button', 'Delay Word', width = '100%',
                                   inline=TRUE, icon = icon("forward")),
                      
                      actionButton('never_button', 'Never Learn Word', width = '100%',
                                   inline=TRUE, icon = icon("eye-slash")),
                      
                      switchInput(
                        inputId = "toggle_clear_on_create_card",
                        label = 'Clear Inputs',
                        value = TRUE)
                      
               ),
               
               column(6, style='padding: 0; margin: 0; padding: 0;',
                      
                      # Buttons To Make Individual Cards
                      actionButton('make_audio_card', 'Make Audio Card', width = '100%',
                                   inline=TRUE, icon = icon("volume-off")),
                      
                      actionButton('make_reading_card', 'Make Reading Card', width = '100%',
                                   inline=TRUE, icon = icon("readme")),
                      
                      # Text Inputs
                      textInput('hiragana', 'Hiragana'),
                      
                      textInput('english_definition', 'English Definition'),
                      
                      textInput('sample_japanese', 'Sample Sentence - Japanese'),
                      
                      textInput('sample_english', 'Sample Sentence - English'),
                      
                      textInput('image_filename', 'Image Filename',
                                placeholder = 'exclude ".jpg"'),
                      
                      div('Only accepts ".jpg" file types', style = 'text-align: center;'),
                      
                      div('but dont need to type ".jpg"', style = 'text-align: center;'),
                      
                      # Copy Image Directory Button
                      actionButton('copy_image_directory', 'Copy Image Directory', width = '100%',
                                   inline=TRUE, icon = icon('image')),
                      
                      tags$hr(),
                      
                      # Button to Make Deck out of Cards
                      actionButton('make_deck', 'Make Deck', width = '100%', 
                                   inline=TRUE, icon = icon("layer-group")),
                      
                      
                      actionButton('check_new_cards','Check Cards', width = '100%')
                      
               )
               
      )
      
    ),
    
    # Main Panel for Displaying Websites ----
    mainPanel(
      
      tabsetPanel(type = "tabs",
                  tabPanel("Definition", htmlOutput('page_definition')),
                  tabPanel("Example Sentences", htmlOutput('page_exampleSentences')),
                  tabPanel("Picture", htmlOutput("page_imageSearch"))
      )
    )
  )
)

server <- function(input, output, session) {
  
  # Initialize Reactive for main data ----
  df.to_learn <- reactiveVal(df.to_learn)
  
  # Initialize Reactive - Stores input fields of newly created cards ----
  new_card.learning_word <- reactiveVal(c())
  new_card.front <- reactiveVal(c())
  new_card.back <- reactiveVal(c())
  new_card.front_audio <- reactiveVal(c())
  new_card.back_audio <- reactiveVal(c())
  
  # Output Table - Words to Learn ----
  output$first_table <- renderReactable({
    reactable(df.to_learn() %>% select(learning_words),
              # columns = list(learning_words = colDef(maxWidth = 120)),
              fullWidth = FALSE,
              compact = TRUE,
              bordered = TRUE,
              striped = TRUE,
              highlight = TRUE, 
              defaultPageSize = 10,
              paginationType = 'simple',
              showPageInfo = FALSE,
              showPageSizeOptions = FALSE,
              # style = list(maxWidth = 120),
              onClick = JS("function(rowInfo, column) {
    if (window.Shiny) {
      Shiny.setInputValue('search_term_index', { index: rowInfo.index + 1 }, { priority: 'event' })
    }
  }"))
  })
  
  # Learning Word ----
  observeEvent(input$search_term_index, {
    
    # Get the search term from the index
    search_term <- get_search_term_by_index(df.to_learn(), input$search_term_index$index)
    
    updateTextInput(session, 'front_word', value = search_term)
  })
  
  # Output Web Page - Bing Search ----
  output$page_imageSearch<-renderUI({
    
    # Take learning word as the search term
    search_term <- input$front_word
    # Get iframe web page
    get_page(search_term, 'image')
  })
  
  # Output Web Page - Example Sentences ----
  output$page_exampleSentences<-renderUI({
    
    # Take learning word as the search term
    search_term <- input$front_word
    # Get iframe web page
    get_page(search_term, 'example')
  })
  
  # Output Web Page - Definition (from Jisho.org) ----
  output$page_definition<-renderUI({
    
    # Take learning word as the search term
    search_term <- input$front_word
    # Get iframe web page
    get_page(search_term, 'definition')
  })
  
  # Make Card - Audio-Front ----
  observeEvent(input$make_audio_card, {
    
    # Get the search term from the index
    search_term <- get_search_term_by_index(df.to_learn(), input$search_term_index$index)
    # Get the learning word
    learning_words <- paste(unique(c(search_term, input$front_word)), collapse = '&nbsp;')
    
    # Create "Back" of card
    back_elements <- list(
      input$front_word,
      input$hiragana,
      input$english_definition,
      paste0('<br>', input$sample_japanese),
      input$sample_english,
      paste0('<img src="',input$image_filename,'.jpg">'))
    new_back_item <- concatenate_back_elements(back_elements)
    # If I have example sentence,
    ## Add another line break so when I add audio it's on a new line
    if (input$sample_japanese != '') {
      new_back_item <- paste0(new_back_item, '<br>')
    }
    new_card.back(append(new_card.back(), new_back_item))
    
    # Create other pieces of card besides "Back"    
    new_card.learning_word(append(new_card.learning_word(), paste0(learning_words,'&nbsp;')))
    new_card.front(append(new_card.front(), 'x'))
    new_card.front_audio(append(new_card.front_audio(), input$front_word))
    new_card.back_audio(append(new_card.back_audio(), input$sample_japanese))
    
    # Reset input fields to blank
    if (input$toggle_clear_on_create_card) {
      updateTextInput(session, 'hiragana', value = '')
      updateTextInput(session, 'english_definition', value = '')
      updateTextInput(session, 'sample_japanese', value = '')
      updateTextInput(session, 'sample_english', value = '')
      updateTextInput(session, 'image_filename', value = '')
    }
    
    # Display Notification Pop-up to let user know card was added
    showNotification(
      ui = 'Audio Card Successfully Created! 😃',
      duration = 3,
      type = "message"
    )
  })
  
  # Make Card - Reading-Front ----
  observeEvent(input$make_reading_card, {
    
    # Get the search term from the index
    search_term <- get_search_term_by_index(df.to_learn(), input$search_term_index$index)
    # Get the learning word
    learning_words <- paste(unique(c(search_term, input$front_word)), collapse = '&nbsp;')
    
    # Create "Back" of card
    back_elements <- list(
      input$hiragana,
      input$english_definition,
      get_kanji_info(input$front_word),
      paste0('<img src="',input$image_filename,'.jpg">'),
      sep = '<br>')
    new_back_item <- concatenate_back_elements(back_elements)
    # Add another line break so when I add audio it's on a new line
    new_back_item <- paste0(new_back_item, '<br>')
    new_card.back(append(new_card.back(), new_back_item))
    
    # Create other pieces of card besides "Back"    
    new_card.learning_word(append(new_card.learning_word(), paste0(learning_words,'&nbsp;')))
    new_card.front(append(new_card.front(), learning_words))
    new_card.front_audio(append(new_card.front_audio(), ''))
    new_card.back_audio(append(new_card.back_audio(), learning_words))
    
    # Reset input fields to blank
    if (input$toggle_clear_on_create_card) {
      updateTextInput(session, 'hiragana', value = '')
      updateTextInput(session, 'english_definition', value = '')
      updateTextInput(session, 'sample_japanese', value = '')
      updateTextInput(session, 'sample_english', value = '')
      updateTextInput(session, 'image_filename', value = '')
    }    
    # Display Notification Pop-up to let user know card was added
    showNotification(
      ui = 'Reading Card Successfully Created! 😃',
      duration = 3,
      type = "message"
    )
  })
  
  # Button - Copy Image Directory to Clipboard ----
  observeEvent(input$copy_image_directory, {
    writeClipboard(images_location)
  })
  
  # Button - Delay Word ----
  observeEvent(input$delay_button, {
    # Get the search term from the index
    search_term <- get_search_term_by_index(df.to_learn(), input$search_term_index$index)
    
    # Add search term to list
    readRDS('inst//List - Delay.RDS') %>%
      add_row(word_to_delay = search_term,
              rank.delay_bonus = 1500) %>%
      saveRDS('inst//List - Delay.RDS')
    
    # Remove search term from table reactive
    df.to_learn() %>%
      slice(-1 * input$search_term_index$index) %>%
      df.to_learn()
  })
  
  # Button - Never Learn ----
  observeEvent(input$never_button, {
    # Get the search term from the index
    search_term <- get_search_term_by_index(df.to_learn(), input$search_term_index$index)
    
    # Add search term to list
    readRDS('inst//List - Never Learn.RDS') %>%
      add_row(word_to_never_learn = search_term,
              rank.never_learn = 1) %>%
      saveRDS('inst//List - Never Learn.RDS')
    
    # Remove search term from table reactive
    df.to_learn() %>%
      slice(-1 * input$search_term_index$index) %>%
      df.to_learn()
  })
  
  # Button - Create Deck Of New Cards ----
  observeEvent(input$make_deck, {
    print(new_card.learning_word()) 
    create_cards(new_card.learning_word(),
                 new_card.front(),
                 new_card.back(),
                 new_card.front_audio(),
                 new_card.back_audio())
  })
  
  # Button - Check new cards ----
  observeEvent(input$check_new_cards, {
    print('learning words:')
    print(new_card.learning_word())
    print('front:')
    print(new_card.front())
    print('back:')
    print(new_card.back())
    print('front audio:')
    print(new_card.front_audio())
    print('back audio:')
    print(new_card.back_audio())
  })
  
}

# Complete app with UI and server components
shinyApp(ui, server)
