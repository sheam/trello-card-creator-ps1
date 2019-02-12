param([string]$InputFile)

$API_KEY = 'f20469d0a4dd5cdd39af63294652bf9a'
$TOKEN = '7a401a9356d62270ef0ec6e54ff0244dc41c20780cdee270e68db6c78dc09437'
$BOARD_ID = 'vxgj7axH'

function Log([string]$msg)
{
    Write-Host $msg
}

function GetInputCards()
{
    $file = $InputFile

    if( -not $file )
    {
        Log('InputFile is not set, exiting')
        exit 1
    }

    if( -not (Test-Path $file) )
    {
        Log("Could not find the card input file '$file'")
        exit 1
    }

    $result = @()
    foreach($line in Get-Content $file)
    {
        $line = $line.Trim()
        if( $line.StartsWith("#") )
        {
            continue
        }

        $title,$description = $line.Split('|')
        $title = $title.Trim()

        if($description)
        {
            $description = $description.Trim()
        }

        if( -not $title )
        {
            continue
        }

        $result += @{ Title = $title; Description = $description; }
    }

    Log("Loaded $($result.Count) Cards from $file")

    return $result
}

function TrelloUrl([string]$path)
{
    $root = "https://api.trello.com/1"
    if( $path[0] -ne '/')
    {
        $path = "/$path"
    }

    if( -not $path.Contains('?') )
    {
        $path = "$path?"
    }


    return "$root$path&key=$API_KEY&token=$TOKEN"
}

function GetList([string]$boardId, [string] $listName)
{
    Log "Getting lists"
    $url = TrelloUrl("/boards/$boardId/lists?cards=none&card_fields=all&filter=open&fields=all")
    $result = Invoke-RestMethod -Method 'GET' $url -UseBasicParsing
    $list = $result | where { $_.name -eq $listName }
    if( -not $list )
    {
        Log "ERROR: could not find the '$listName' on board with id '$boardId'"
        exit 1
    }
    return $list
}

# https://developers.trello.com/reference#cards-2
function CreateCard([string]$listId, [string]$title, [string]$desc)
{
    Log "Creating card $title"
    if( -not $listId )
    {
        Log 'Missing list id in CreateCard, exiting'
        exit 1
    }
    if( -not $title )
    {
        Log 'Card missing title, skipping'
        return
    }
    $path = "/cards?idList=$listId&keepFromSource=all&name=$title"
    if( $desc )
    {
        $path += "&desc=$desc"
    }
    $url = TrelloUrl($path)
    $result = Invoke-RestMethod -Method 'POST' $url -UseBasicParsing
}

function CreateCards([string]$listId, $cardList)
{
    if( -not $listId )
    {
        Log 'Missing list id in CreateCard, exiting'
        exit 1
    }
    foreach($card in $cardList)
    {
        CreateCard -listId $listId -title $card.Title -desc $card.Description
    }
}

$todoList = GetList -boardId $BOARD_ID -listName 'TODO'
$cardsToAdd = GetInputCards
CreateCards -listId $todoList.id -cardList $cardsToAdd




