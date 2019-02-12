# Trello Bulk Create Cards Script for PS1
Bulk create trello cards can be configured through the command line, config file, or environment.

## Options

- InputFile: Env: TRELLO_INPUT_FILE, JSON: input_file, the name of the file with a list of cards in it.
- Token: Env: TRELLO_TOKEN, JSON: token, trello API token.
- ApiKey: Env: TRELLO_API_KEY, JSON: key, trello API key.
- BoardId: Env: TRELLO_BOARD_ID, JSON: board_id, id of the Trello board. This can be taken from the URL of the board.
- ListName: Env: TRELLO_LIST_NAME, JSON: list_name, name of the list to add cards to.

## Input file

The input file is a text file with one card title per file. 
If you would like descriptions, you can add a bar followed by your desction.
```Card One Title
Card Two Title|Card two has a description
Card 3333```

## Sample Config.json
```
{
    "key": "12312313",
    "token": "23234542345234523542345",
    "board_id": "vsfsdfk",
    "input_file": "card_list.txt",
    "list_name": "To Do"
}
```