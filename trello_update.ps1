param([string]$InputFile, [string]$ConfigFile, [string]$ApiKey, [string]$Token, [string]$BoardId, [string]$ListName)

function Log([string]$msg)
{
    Write-Host $msg
}

function GetRequiredSetting([string]$name, [string]$option, [string]$env, [string]$config)
{
    $result = IsNull $option $env $config
    if( -not $result )
    {
        Log "Error: $name is a required option."
        exit 1
    }
    return $result
}

function IsNull
{
    for($i=0;$i -lt $args.count;$i++)
    {
        if($args[$i])
        {
            return $args[$i]
        }
    }
}

function LoadConfig()
{
    $Script:config_file = GetRequiredSetting -name 'ConfigFile' -option $ConfigFile -env $Env:TRELLO_CONFIG_FILE -config 'config.json'

    if( Test-Path $Script:config_file )
    {
        Log "Using config file '$($Script:config_file)'"
        $json = Get-Content $Script:config_file | Out-String | ConvertFrom-Json
    }
    else 
    {
        $json = @()
    }

    $Script:config_inputFile = GetRequiredSetting -name 'InputFile' -option $InputFile -env $Env:TRELLO_INPUT_FILE -config $json.input_file
    $Script:config_token = GetRequiredSetting -name 'Token' -option $Token -env $Env:TRELLO_TOKEN -config $json.token
    $Script:config_key = GetRequiredSetting -name 'ApiKey' -option $ApiKey -env $Env:TRELLO_API_KEY -config $json.key
    $Script:config_boardId = GetRequiredSetting -name 'BoardId' -option $BoardId -env $Env:TRELLO_BOARD_ID -config $json.board_id
    $Script:config_listName = GetRequiredSetting -name 'ListName' -option $ListName -env $Env:TRELLO_LIST_NAME -config $json.list_name
}

function GetInputCards()
{
    $file = $Script:config_inputFile

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


    return "$root$path&key=$($Script:config_key)&token=$($Script:config_token)"
}

function GetList([string]$boardId, [string] $listName)
{
    Log "Getting lists"
    $url = TrelloUrl("/boards/$boardId/lists?cards=none&card_fields=all&filter=open&fields=all")
    $result = Invoke-RestMethod -Method 'GET' $url -UseBasicParsing
    $list = $result | Where-Object { $_.name -eq $listName }
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
    return $result
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

LoadConfig
$todoList = GetList -boardId $Script:config_boardId -listName $Script:config_listName
$cardsToAdd = GetInputCards
CreateCards -listId $todoList.id -cardList $cardsToAdd




