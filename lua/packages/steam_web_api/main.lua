module( "steam", package.seeall )

local logger = GPM.Logger( "Steam Web API" )

local key = nil
local api_url = "https://api.steampowered.com/"

-- https://steamcommunity.com/dev/apikey
function Key( str )
    assert( isstring(str), "Steam Web API key must be a string!" )
    key = str
end

/*
    Simple Steam ID Formatter
*/
do
    local util_SteamIDTo64 = util.SteamIDTo64
    function SteamID( str )
        if str:find( "STEAM_" ) then
            str = util_SteamIDTo64( str )
        end

        if (str == "0") then
            logger:error( "An invalid steamid was passed. (Use Steam32 or Steam64)" )
        end

        return str
    end
end

local function JsonError( json, result_name, success_required )
    if (json == nil) then return "JSON is empty!" end
    local response = json[ result_name or "response" ]
    if (response == nil) then return "Response is non-exist!" end
    if (success_required == true) and (response.success ~= 1) then return "Success is false!" end
end

local util_JSONToTable = util.JSONToTable
local http_isSuccess = http.isSuccess
local table_concat = table.concat

/*
    GetWorkshopItemInfo
    `table` workshop items
*/
function GetWorkshopItemInfo( callback, ... )
    local parameters = {}
    parameters.itemcount = 0

    local args = {...}
    if istable( args[1] ) then
        args = args[1]
    end

    for num, wsid in ipairs( args ) do
        parameters["publishedfileids[" .. parameters.itemcount .. "]"] = wsid
        parameters.itemcount = parameters.itemcount + 1
    end

    parameters.itemcount = tostring( parameters.itemcount )

    http.Post( api_url .. "ISteamRemoteStorage/GetPublishedFileDetails/v1/", parameters,
    function( body, len, headers, code )
        if http_isSuccess( code ) then
            local json = util_JSONToTable( body )

            local jsErr = JsonError( json )
            if (jsErr) then
                logger:warn( jsErr )
                return
            end

            pcall( callback, json.response.publishedfiledetails )
            return
        end

        logger:error( "Error on getting info about `{1}` addons from Steam Workshop! (Code: {2}) Body:\n{3}", table_concat( args, ", " ), code, body )
    end,
    function( err )
        logger:error( "Error on getting info about `{1}` addons from Steam Workshop:\n{2}", table_concat( args, ", " ), err )
    end)
end

/*
    GetCollectionDetails
    `table` collections
*/
function GetCollectionDetails( callback, ... )
    local parameters = {}
    parameters.collectioncount = 0

    local args = {...}
    if istable( args[1] ) then
        args = args[1]
    end

    for num, wsid in ipairs( args ) do
        parameters["publishedfileids[" .. parameters.collectioncount .. "]"] = wsid
        parameters.collectioncount = parameters.collectioncount + 1
    end

    parameters.collectioncount = tostring( parameters.collectioncount )

    http.Post( api_url .. "ISteamRemoteStorage/GetCollectionDetails/v1/", parameters,
    function( body, len, headers, code )
        if http_isSuccess( code ) then
            local json = util_JSONToTable( body )

            local jsErr = JsonError( json )
            if (jsErr) then
                logger:warn( jsErr )
                return
            end

            pcall( callback, json.response.collectiondetails )
            return
        end

        logger:error( "Error on getting info about `{1}` collections from Steam Workshop! (Code: {2}) Body:\n{3}", table_concat( args, ", " ), code, body )
    end,
    function( err )
        logger:error( "Error on getting info about `{1}` collections from Steam Workshop:\n{2}", table_concat( args, ", " ), err )
    end)
end

/*
    GetUserInfo
    `table` players
*/
function GetUserInfo( callback, ... )
    local args = {...}
    if istable( args[1] ) then
        args = args[1]
    end

    local count = #args

    if (count > 100) then
        logger:error( "Forbidden > 100 steamids!" )
        return
    end

    local steamids = ""
    for num, str in ipairs( args ) do
        steamids = steamids .. SteamID( str ) .. ( (num == count) and "" or ", " )
    end

    local request = http.request( api_url .. "ISteamUser/GetPlayerSummaries/v2/", function( code, body, headers )
        if http_isSuccess( code ) then
            local json = util_JSONToTable( body )

            local jsErr = JsonError( json )
            if (jsErr) then
                logger:warn( jsErr )
                return
            end

            pcall( callback, json.response.players )
            return
        end

        logger:error( "Error on getting info about `{1}` users from Steam Web API! (Code: {2}) Body:\n{3}", steamids, code, body )
    end)

    request:addParameter( "key", key )
    request:addParameter( "steamids", steamids )
end

/*
    GetUserGroups
    `table` groups
*/
function GetUserGroups( callback, steamid )
    local steamid64 = SteamID( steamid )
    local request = http.request( api_url .. "ISteamUser/GetUserGroupList/v1/", function( code, body, headers )
        if http_isSuccess( code ) then
            local json = util_JSONToTable( body )

            local jsErr = JsonError( json )
            if (jsErr) then
                logger:warn( jsErr )
                return
            end

            pcall( callback, json.response.groups )
            return
        end

        logger:error( "Error on getting info about `{1}` user from Steam Web API! (Code: {2}) Body:\n{3}", steamid64, code, body )
    end)

    request:addParameter( "key", key )
    request:addParameter( "steamid", steamid64 )
end

/*
    GetSteamLevel
    `number` steam level
*/
function GetSteamLevel( callback, steamid )
    local steamid64 = SteamID( steamid )
    local request = http.request( api_url .. "IPlayerService/GetSteamLevel/v1/", function( code, body, headers )
        if http_isSuccess( code ) then
            local json = util_JSONToTable( body )

            local jsErr = JsonError( json )
            if (jsErr) then
                logger:warn( jsErr )
                return
            end

            pcall( callback, json.response.player_level )
            return
        end

        logger:error( "Error on getting info about `{1}` user from Steam Web API! (Code: {2}) Body:\n{3}", steamid64, code, body )
    end)

    request:addParameter( "key", key )
    request:addParameter( "steamid", steamid64 )
end

/*
    GetIDFromURL
    `string` steamid
*/
STEAM_PROFILE = 1
STEAM_GROUP = 2
STEAM_OFFICIAL_GAME_GROUP = 3

local typeToTitle = {
    [STEAM_PROFILE] = "profile",
    [STEAM_GROUP] = "group",
    [STEAM_OFFICIAL_GAME_GROUP] = "official game group"
}

function GetIDFromURL( callback, url, type )
    local request = http.request( api_url .. "ISteamUser/ResolveVanityURL/v1/", function( code, body, headers )
        if http_isSuccess( code ) then
            local json = util_JSONToTable( body )

            local jsErr = JsonError( json, nil, true )
            if (jsErr) then
                logger:warn( jsErr )
                return
            end

            pcall( callback, json.response.steamid )
            return
        end

        logger:error( "Error on getting id for `{1}` {2} from Steam Web API! (Code: {3}) Body:\n{4}", url, typeToTitle[ type or STEAM_PROFILE ], code, body )
    end)

    request:addParameter( "key", key )
    request:addParameter( "vanityurl", url )
    request:addParameter( "url_type", type or STEAM_PROFILE )
end

/*
    GetBans
    `table` players
*/
function GetBans( callback, ... )
    local args = {...}
    if istable( args[1] ) then
        args = args[1]
    end

    local count = #args

    local steamids = ""
    for num, str in ipairs( args ) do
        steamids = steamids .. SteamID( str ) .. ( (num == count) and "" or "," )
    end

    local request = http.request( api_url .. "ISteamUser/GetPlayerBans/v1/", function( code, body, headers )
        if http_isSuccess( code ) then
            local json = util_JSONToTable( body )

            local jsErr = JsonError( json, "players" )
            if (jsErr) then
                logger:warn( jsErr )
                return
            end

            pcall( callback, json.players )
            return
        end

        logger:error( "Error on getting bans for `{1}` {2} from Steam Web API! (Code: {3}) Body:\n{4}", url, typeToTitle[ type or STEAM_PROFILE ], code, body )
    end)

    request:addParameter( "key", key )
    request:addParameter( "steamids", steamids )
end

/*
    GetOwnedGames
    `table` games, `number` games count
*/
function GetOwnedGames( callback, steamid, include_appinfo, include_played_free_game, appids_filter )
    local steamid64 = SteamID( steamid )
    local request = http.request( api_url .. "IPlayerService/GetOwnedGames/v1/", function( code, body, headers )
        if http_isSuccess( code ) then
            local json = util_JSONToTable( body )

            local jsErr = JsonError( json, nil )
            if (jsErr) then
                logger:warn( jsErr )
                return
            end

            pcall( callback, json.response.games, json.response.game_count )
            return
        end

        logger:error( "Error on getting games for `{1}` from Steam Web API! (Code: {3}) Body:\n{4}", steamid64, code, body )
    end)

    request:addParameter( "key", key )
    request:addParameter( "steamid", steamid64 )
    request:addParameter( "include_appinfo", include_appinfo == true )
    request:addParameter( "include_played_free_games", include_played_free_games == true )
    request:addParameter( "appids_filter", appids_filter )
end

/*
    GetApp( callback, steamid, id )
    `table` game
*/
function GetApp( callback, steamid, id )
    local appid = tonumber( id )
    GetOwnedGames(function( games, count )
        for num, app in ipairs( games ) do
            if (app.appid == appid) then
                pcall( callback, app )
                return
            end
        end

        logger:warn( "User ({1}) does not have an application `{2}` on the account.", steamid, id )
    end, steamid)
end

/*
    GetGarrysMod( callback, steamid )
    `table` app info
*/
function GetGarrysMod( callback, steamid )
    GetApp(function( app )
        pcall( callback, app )
    end, steamid, 4000 )
end

/*
    GetGarrysModHours( callback, steamid )
    `number` hours
*/
function GetGarrysModHours( callback, steamid )
    GetGarrysMod( function( app )
        pcall( callback, math.floor( app.playtime_forever / 60 ) )
    end, steamid )
end
