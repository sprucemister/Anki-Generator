def create_cards(my_learning_word, my_front, my_back, my_front_audio, my_back_audio):
  
  # Packages
  import genanki
  
  # Create Model (similar to 'Stew Double Audio Notes')
  my_model = genanki.Model(
    1594519734631,
    'Stew Double Audio Notes-AUTOGENERATED',
    fields=[
      {'name': 'Learning Words - (**Space at end, space between)'},
      {'name': 'Front'},
      {'name': 'Back'},
      {'name': 'Front Audio'},
      {'name': 'Back Audio'},
    ],
    templates=[
      {
        'name': 'This Card',
        'qfmt': '{{Front}}',
        'afmt': '{{FrontSide}}<hr id="answer">{{Back}}',
      },
    ])
  
  # Make a "Deck" object that matches  the deck you want to add to
  my_deck = genanki.Deck(1645976012445, "Emma")
  
  # Loop through each item in the list
  for i in range(len(my_front)): 
    print(str(i) + "this card's front is:")
    print('     '+my_front[i])
    # Create Note for that item
    my_note = genanki.Note(
      model=my_model,
      fields=[my_learning_word[i],
              my_front[i], 
              my_back[i], 
              my_front_audio[i], 
              my_back_audio[i]])
    # Add note to deck
    my_deck.add_note(my_note)
  
  # Write Deck to package file (that can be imported into Anki)
  genanki.Package(my_deck).write_to_file('Deck Of New Cards.apkg')
  
