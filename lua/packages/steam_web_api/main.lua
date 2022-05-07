module( "steam", package.seeall )

local key = nil
function Key( str )
    assert( isstring(str), "Steam Web API key must be a string!" )
    key = str
end

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
        if http.isSuccess( code ) then
            local json = util.JSONToTable( body )
            if (json ~= nil) and (json.response ~= nil) then
                callback( json.response.publishedfiledetails )
                return
            end
        end

        MsgN( "Error on getting info about " .. table.concat( args, ", " ) .. " addons from Steam Workshop! (Code: " .. code .. ") Body:\n" .. body )
    end,
    function( err )
        MsgN( "Error on getting info about " .. table.concat( args, ", " ) .. " addons from Steam Workshop:\n" .. err )
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
        if http.isSuccess( code ) then
            local json = util.JSONToTable( body )
            if (json ~= nil) and (json.response ~= nil) then
                callback( json.response.collectiondetails )
                return
            end
        end

        MsgN( "Error on getting info about " .. table.concat( args, ", " ) .. " collections from Steam Workshop! (Code: " .. code .. ") Body:\n" .. body )
    end,
    function( err )
        MsgN( "Error on getting info about " .. table.concat( args, ", " ) .. " collections from Steam Workshop:\n" .. err )
    end)
end

-- steam.GetWorkshopItemInfo( function( addons )
--     print( addons, "\n" )
--     PrintTable( addons )
-- end, "2799307109" )

-- steam.GetCollectionDetails( function( collections )
--     print( collections, "\n" )
--     PrintTable( collections )
-- end, "2799727735" )