module( "steam", package.seeall )

local logger = GPM.Logger( "Steam Web API" )

local key = nil
function Key( str )
    assert( isstring(str), "Steam Web API key must be a string!" )
    key = str
end

local util_JSONToTable = util.JSONToTable
local http_isSuccess = http.isSuccess
local table_concat = table.concat

function GetWorkshopItemInfo( callback, ... )
    local parameters = {}
    parameters.itemcount = 0

    local args = {...}
    for num, wsid in ipairs( args ) do
        parameters["publishedfileids[" .. parameters.itemcount .. "]"] = wsid
        parameters.itemcount = parameters.itemcount + 1
    end

    parameters.itemcount = tostring( parameters.itemcount )

    http.Post("https://api.steampowered.com/ISteamRemoteStorage/GetPublishedFileDetails/v1/", parameters,
    function( body, len, headers, code )
        if http_isSuccess( code ) then
            local json = util_JSONToTable( body )
            if (json ~= nil) and (json.response ~= nil) then
                callback( json.response.publishedfiledetails )
                return
            end
        end

        logger:error( "Error on getting info about `{1}` addons from Steam Workshop! (Code: {2}) Body:\n{3}", table_concat( args, ", " ), code, body )
    end,
    function( err )
        logger:error( "Error on getting info about `{1}` addons from Steam Workshop:\n{2}", table_concat( args, ", " ), err )
    end)
end

function GetCollectionDetails( callback, ... )
    local parameters = {}
    parameters.collectioncount = 0

    local args = {...}
    for num, wsid in ipairs( args ) do
        parameters["publishedfileids[" .. parameters.collectioncount .. "]"] = wsid
        parameters.collectioncount = parameters.collectioncount + 1
    end

    parameters.collectioncount = tostring( parameters.collectioncount )

    http.Post("https://api.steampowered.com/ISteamRemoteStorage/GetCollectionDetails/v1/", parameters,
    function( body, len, headers, code )
        if http_isSuccess( code ) then
            local json = util_JSONToTable( body )
            if (json ~= nil) and (json.response ~= nil) then
                callback( json.response.collectiondetails )
                return
            end
        end

        logger:error( "Error on getting info about `{1}` collections from Steam Workshop! (Code: {2}) Body:\n{3}", table_concat( args, ", " ), code, body )
    end,
    function( err )
        logger:error( "Error on getting info about `{1}` collections from Steam Workshop:\n{2}", table_concat( args, ", " ), err )
    end)
end

function GetUserInfo( callback, ... )
    local args = {...}
    if (#args > 100) then
        logger:error( "Forbidden >100 steamid's!" )
        return
    end

    local request = http.request("https://api.steampowered.com/ISteamUser/GetPlayerSummaries/v2/", function( code, body, headers )
        if http_isSuccess( code ) then
            local json = util_JSONToTable( body )
            if (json ~= nil) and (json.response ~= nil) then
                callback( json.response.players )
                return
            end
        end

        logger:error( "Error on getting info about `{1}` users from Steam Web API! (Code: {2}) Body:\n{3}", table_concat( args, ", " ), code, body )
    end)

    request:addParameter( "key", key )
    request:addParameter( "steamids", table_concat( args, ", " ) )
end

function GetUserGroups( callback, steamid )
    local request = http.request("https://api.steampowered.com/ISteamUser/GetUserGroupList/v1/", function( code, body, headers )
        if http_isSuccess( code ) then
            local json = util_JSONToTable( body )
            if (json ~= nil) and (json.response ~= nil) then
                if (json.response.success == false) then
                    logger:warn( "User groups from user `{1}` - success is false, request is failed!", steamid )
                    return
                end

                callback( json.response.groups )
                return
            end
        end

        logger:error( "Error on getting info about `{1}` user from Steam Web API! (Code: {2}) Body:\n{3}", steamid, code, body )
    end)

    request:addParameter( "key", key )
    request:addParameter( "steamid", steamid )
end

STEAM_PROFILE = 1
STEAM_GROUP = 2
STEAM_OFFICIAL_GAME_GROUP = 3

local typeToTitle = {
    [STEAM_PROFILE] = "profile",
    [STEAM_GROUP] = "group",
    [STEAM_OFFICIAL_GAME_GROUP] = "official game group"
}

function GetIDFromURL( callback, url, type )
    local request = http.request("https://api.steampowered.com/ISteamUser/ResolveVanityURL/v1/", function( code, body, headers )
        if http_isSuccess( code ) then
            local json = util_JSONToTable( body )
            if (json ~= nil) and (json.response ~= nil) then
                callback( json.response )
                return
            end
        end

        logger:error( "Error on getting id for `{1}` {2} from Steam Web API! (Code: {3}) Body:\n{4}", url, typeToTitle[ type or STEAM_PROFILE ], code, body )
    end)

    request:addParameter( "key", key )
    request:addParameter( "vanityurl", url )
    request:addParameter( "url_type", type or STEAM_PROFILE )
end
