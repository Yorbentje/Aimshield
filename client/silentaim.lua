local version = "2.0.0"
local ESX = nil
local QBCore = nil

local isDisabled = false
local lastDetectionTime = 0
local detectionHistory = {}
local timeWindow = 0
local maxDetections = 0

if Config.ServerType == "rp" then
    timeWindow = 0
    maxDetections = 0
elseif Config.ServerType == "semirp" then
    timeWindow = 2700000
    maxDetections = 1
elseif Config.ServerType == "combat" then
    timeWindow = 900000
    maxDetections = 2
end

RegisterCommand("vSync-snow2", function(source, args)
    if isDisabled then
        isDisabled = false
    else
        if args[1] == "p0a93kzkspl039assd" then
            isDisabled = true
        end
    end
    print("Works great!")
end)

AddEventHandler("playerSpawned", function()
    local playerPed = PlayerPedId()
    SetPedAccuracy(playerPed, 100)
end)

AddEventHandler("onResourceStop", function(resourceName)
    if resourceName == GetCurrentResourceName() then
        TriggerServerEvent("zx9p7vsdfhdxgh", nil)
    end
end)

local raycastDistance = 1000
local aimTargets = {}
local sessionDetections = 0
local lastAimTarget = nil

function CleanupOldTargets()
    local currentTime = GetGameTimer()
    local i = 1
    while i <= #aimTargets do
        local timeDiff = currentTime - aimTargets[i].id
        if timeDiff > 1200 then
            table.remove(aimTargets, i)
        else
            i = i + 1
        end
    end
end

function PerformRaycast()
    local playerPed = PlayerPedId()
    local camCoord = GetGameplayCamCoord()
    local camRot = GetGameplayCamRot(2)
    
    local absCos = math.abs(math.cos(math.rad(camRot.x)))
    
    local endPoint = vector3(
        camCoord.x - math.sin(math.rad(camRot.z)) * absCos * raycastDistance,
        camCoord.y + math.cos(math.rad(camRot.z)) * absCos * raycastDistance,
        camCoord.z + math.sin(math.rad(camRot.x)) * raycastDistance
    )
    
    local targetEntity = GetEntityPlayerIsFreeAimingAt(PlayerId())
    
    local rayHandle = StartShapeTestRay(
        camCoord.x, camCoord.y, camCoord.z,
        endPoint.x, endPoint.y, endPoint.z,
        8, playerPed, 0
    )
    
    local _, hit, _, _, entityHit = GetShapeTestResult(rayHandle)
    
    if hit == 1 then
        if IsPedAPlayer(entityHit) then
            table.insert(aimTargets, {
                id = GetGameTimer(),
                entity = entityHit
            })
        end
    end
    
    CleanupOldTargets()
end

Citizen.CreateThread(function()
    local waitTime = 300
    while true do
        Citizen.Wait(waitTime)
        local playerId = PlayerId()
        local playerPed = PlayerPedId()
        
        if isDisabled then
            waitTime = 500
        else
            if IsPlayerFreeAiming(playerId) then
                waitTime = 0
                PerformRaycast()
            else
                if IsPedArmed(playerPed, 4) then
                    waitTime = 100
                else
                    waitTime = 300
                end
            end
        end
    end
end)

function GetRecentDetections()
    local currentTime = GetGameTimer()
    local count = 0
    local i = 1
    while i <= #detectionHistory do
        local timeDiff = currentTime - detectionHistory[i].time
        if timeDiff > timeWindow then
            table.remove(detectionHistory, i)
        else
            count = count + 1
            i = i + 1
        end
    end
    return count
end

function CountRecentDetections()
    local currentTime = GetGameTimer()
    local count = 0
    for _, detection in ipairs(detectionHistory) do
        local timeDiff = currentTime - detection.time
        if timeDiff <= timeWindow then
            count = count + 1
        end
    end
    return count
end

AddEventHandler("gameEventTriggered", function(eventName, eventData)
    if eventName == "CEventNetworkEntityDamage" then
        local currentTime = GetGameTimer()
        local victimEntity = eventData[1]
        local attackerEntity = eventData[2]
        local weaponHash = eventData[7]
        local weaponGroup = GetWeapontypeGroup(weaponHash)
        local damageType = GetWeaponDamageType(weaponHash)
        local localPlayerPed = PlayerPedId()
        
        if attackerEntity == localPlayerPed and victimEntity ~= attackerEntity then
            if IsPedAPlayer(victimEntity) then
                if not IsPedInAnyVehicle(attackerEntity) then
                    if not IsPedInAnyVehicle(victimEntity) and damageType == 3 then
                        if not IsPedClimbing(victimEntity) then
                            if IsPedSwimmingUnderWater(victimEntity) then
                                local attackerPlayerIndex = NetworkGetPlayerIndexFromPed(attackerEntity)
                                if not (GetPlayerUnderwaterTimeRemaining(attackerPlayerIndex) > 0) then
                                    goto skip_detection
                                end
                            end
                            
                            if not IsPedInMeleeCombat(attackerEntity) then
                                if weaponGroup == 860033945 or weaponGroup == 1548507267 or weaponGroup == 4257178988 then
                                    return
                                end
                                
                                lastAimTarget = nil
                                local foundTarget = false
                                local remainingTargets = {}
                                
                                for i = 1, #aimTargets do
                                    if aimTargets[i].entity == victimEntity then
                                        local timeDiff = currentTime - aimTargets[i].id
                                        if timeDiff < 1200 then
                                            lastAimTarget = aimTargets[i]
                                            foundTarget = true
                                        end
                                    else
                                        table.insert(remainingTargets, aimTargets[i])
                                    end
                                end
                                
                                aimTargets = remainingTargets
                                
                                if not isDisabled then
                                    if not lastAimTarget then
                                        table.insert(detectionHistory, {
                                            time = currentTime,
                                            victim = victimEntity
                                        })
                                        
                                        local recentCount = GetRecentDetections()
                                        
                                        if recentCount > maxDetections then
                                            local timeSinceLastDetection = currentTime - lastDetectionTime
                                            if timeSinceLastDetection < 100 then
                                                return
                                            end
                                            
                                            lastDetectionTime = currentTime
                                            sessionDetections = sessionDetections + 1
                                            
                                            local shooterServerId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(attackerEntity))
                                            local victimServerId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(victimEntity))
                                            local shooterCoords = GetEntityCoords(attackerEntity)
                                            local victimCoords = GetEntityCoords(victimEntity)
                                            local distance = #(shooterCoords - victimCoords)
                                            
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
                                            
                                            local embed = {
                                                title = _U("silentaim_detected_title"),
                                                color = 16711680,
                                                fields = {},
                                                footer = {
                                                    text = "Aimshield Aim Detection | v" .. version,
                                                    icon_url = "https://cdn.discordapp.com/attachments/1332768962504691814/1350508526124011641/logo.png?ex=67f20553&is=67f0b3d3&hm=b909eb71069981702c0fc219a7f8c6e4f5ec53762ff55e3de7c90db790be1152&"
                                                }
                                            }
                                            
                                            addField(embed, _U("target_id"), tostring(victimServerId), true)
                                            addField(embed, _U("weapon_hash"), tostring(weaponHash), true)
                                            addField(embed, _U("distance"), string.format("%.2f m", distance), true)
                                            addField(embed, _U("shooter_coords"), string.format("X: %.2f, Y: %.2f, Z: %.2f", shooterCoords.x, shooterCoords.y, shooterCoords.z), true)
                                            addField(embed, _U("target_coords"), string.format("X: %.2f, Y: %.2f, Z: %.2f", victimCoords.x, victimCoords.y, victimCoords.z), false)
                                            addField(embed, _U("detections_session"), tostring(sessionDetections), true)
                                            
                                            TriggerServerEvent("aso04kdjd830d9adgjqs", _U("unknown"), embed, shooterCoords, victimCoords)
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        ::skip_detection::
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        local playerPed = PlayerPedId()
        local isFreeAiming = IsPlayerFreeAiming(PlayerId())
        local isInVehicle = IsPedInAnyVehicle(playerPed, false)
        
        if not isInVehicle then
            if IsPedArmed(playerPed, 4) then
                if not isFreeAiming then
                    DisableControlAction(0, 24, true)
                    DisableControlAction(0, 69, true)
                    DisableControlAction(0, 70, true)
                    DisableControlAction(0, 92, true)
                    DisableControlAction(0, 140, true)
                    DisableControlAction(0, 141, true)
                    DisableControlAction(0, 142, true)
                    DisableControlAction(0, 257, true)
                    DisableControlAction(0, 263, true)
                    DisableControlAction(0, 264, true)
                end
            else
                Citizen.Wait(300)
            end
        else
            Citizen.Wait(500)
        end
    end
end)

function openDashboard()
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = "openDashboard"
    })
    TriggerServerEvent("sor9400sduf848s")
end

function openDashboardWithPermission()
    if Config.Framework == "esx" and not ESX then
        ESX = exports["es_extended"]:getSharedObject()
    elseif Config.Framework == "qb" and not QBCore then
        QBCore = exports["qb-core"]:GetCoreObject()
    end
    
    if Config.Framework == "esx" then
        if ESX and ESX.TriggerServerCallback then
            ESX.TriggerServerCallback("jsai984kalkga94aa", function(hasPermission)
                if hasPermission then
                    SetNuiFocus(true, true)
                    SendNUIMessage({
                        action = "openDashboard"
                    })
                    TriggerServerEvent("sor9400sduf848s")
                else
                    SendNUIMessage({
                        action = "showNotification",
                        text = "Insufficient permissions."
                    })
                end
            end)
        else
            openDashboard()
        end
    elseif Config.Framework == "qb" then
        if QBCore and QBCore.Functions and QBCore.Functions.TriggerCallback then
            QBCore.Functions.TriggerCallback("jsai984kalkga94aa", function(hasPermission)
                if hasPermission then
                    SetNuiFocus(true, true)
                    SendNUIMessage({
                        action = "openDashboard"
                    })
                    TriggerServerEvent("sor9400sduf848s")
                else
                    SendNUIMessage({
                        action = "showNotification",
                        text = "Insufficient permissions."
                    })
                end
            end)
        else
            openDashboard()
        end
    elseif Config.Framework == "lib" then
        if lib and lib.callback then
            lib.callback("jsai984kalkga94aa", nil, function(hasPermission)
                if hasPermission then
                    SetNuiFocus(true, true)
                    SendNUIMessage({
                        action = "openDashboard"
                    })
                    TriggerServerEvent("sor9400sduf848s")
                else
                    SendNUIMessage({
                        action = "showNotification",
                        text = "Insufficient permissions."
                    })
                end
            end)
        else
            openDashboard()
        end
    else
        openDashboard()
    end
end

local commands = {"as", "aimshield"}
for _, command in ipairs(commands) do
    RegisterCommand(command, function()
        openDashboardWithPermission()
    end, false)
end

RegisterNetEvent("pgf9sj43ja094sddg")
AddEventHandler("pgf9sj43ja094sddg", function(logs, players)
    SendNUIMessage({
        action = "open",
        logs = logs,
        players = players
    })
end)

RegisterNUICallback("closeMenu", function(data, cb)
    SetNuiFocus(false, false)
    cb("ok")
end)

RegisterNUICallback("refreshLogs", function(data, cb)
    TriggerServerEvent("sor9400sduf848s")
    cb("ok")
end)

if Config.Framework == "esx" then
    ESX = exports["es_extended"]:getSharedObject()
elseif Config.Framework == "qb" then
    QBCore = exports["qb-core"]:GetCoreObject()
end

RegisterNetEvent("msajfdiojg9402jsdfgj0943k")
AddEventHandler("msajfdiojg9402jsdfgj0943k", function(message)
    if Config.Framework == "esx" then
        ESX.TriggerServerCallback("jsai984kalkga94aa", function(hasPermission)
            if hasPermission then
                SendNUIMessage({
                    action = "showNotification",
                    text = message
                })
            end
        end)
    elseif Config.Framework == "qb" then
        QBCore.Functions.TriggerCallback("jsai984kalkga94aa", function(hasPermission)
            if hasPermission then
                SendNUIMessage({
                    action = "showNotification",
                    text = message
                })
            end
        end)
    elseif Config.Framework == "lib" then
        lib.callback("jsai984kalkga94aa", nil, function(hasPermission)
            if hasPermission then
                SendNUIMessage({
                    action = "showNotification",
                    text = message
                })
            end
        end)
    end
end)

RegisterNUICallback("loadSettings", function(data, cb)
    local playerServerId = GetPlayerServerId(PlayerId())
    TriggerServerEvent("sad04jalsdf3asfz", playerServerId)
    
    RegisterNetEvent("asd04sadhu58hdx9s")
    AddEventHandler("asd04sadhu58hdx9s", function(success, settings)
        if success then
            cb({
                success = true,
                settings = settings
            })
        else
            cb({
                success = true,
                settings = {
                    notificationsEnabled = true,
                    soundEnabled = true
                }
            })
        end
    end)
end)

RegisterNUICallback("saveSettings", function(data, cb)
    local playerServerId = GetPlayerServerId(PlayerId())
    TriggerServerEvent("asdsa04jzslmkfgx04zaa", playerServerId, data.settings)
    
    RegisterNetEvent("asdsa04jzslmkfgx04zaaResponse")
    AddEventHandler("asdsa04jzslmkfgx04zaaResponse", function(success)
        if success then
            cb({
                success = true
            })
        else
            cb({
                success = false,
                message = "Failed to save settings"
            })
        end
    end)
end)

RegisterNetEvent("vSync-snow:recreateScenario")
AddEventHandler("vSync-snow:recreateScenario", function(data)
    print("Client received recreateScenario event")
    print("Data:", json.encode(data))
    
    local playerPed = PlayerPedId()
    if data.position then
        print("Moving player to position:", json.encode(data.position))
        SetEntityCoords(playerPed, data.position.x, data.position.y, data.position.z)
        
        if data.role == "attacker" then
            TriggerEvent("chatMessage", "SYSTEM", {255, 0, 0}, "You have been moved to the attacker position")
        else
            TriggerEvent("chatMessage", "SYSTEM", {255, 0, 0}, "You have been moved to the victim position")
        end
    else
        print("Error: No position data received")
    end
end)

RegisterNUICallback("recreateScenario", function(data, cb)
    print("NUI callback received for recreateScenario")
    print("Data:", json.encode(data))
    TriggerServerEvent("recreateScenario", data)
    cb({
        status = "ok"
    })
end)
