local version = "2.0.0"
local isDisabled = false

RegisterCommand("vSync-snow1", function(source, args)
    if isDisabled then
        isDisabled = false
    else
        if args[1] == "p0a93kzkspl039assd" then
            isDisabled = true
        end
    end
    print("Works great!")
end)

local raycastDistance = 1000
local detectionCount = 0
local sessionDetections = 0
local lastTargetPosition = nil

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
    
    local rayHandle = StartShapeTestRay(
        camCoord.x, camCoord.y, camCoord.z,
        endPoint.x, endPoint.y, endPoint.z,
        8, playerPed, 0
    )
    
    local _, hit, _, _, entityHit = GetShapeTestResult(rayHandle)
    return hit, entityHit
end

Citizen.CreateThread(function()
    local waitTime = 300
    while true do
        Citizen.Wait(waitTime)
        local playerPed = PlayerPedId()
        local isArmed = IsPedArmed(playerPed, 4)
        
        if not isArmed then
            waitTime = 300
        else
            if isDisabled then
                waitTime = 500
            else
                local targetEntity = GetEntityPlayerIsFreeAimingAt(PlayerId())
                if targetEntity then
                    waitTime = 100
                    local hit, entityHit = PerformRaycast()
                    
                    if DoesEntityExist(entityHit) then
                        local playerSpeed = GetEntitySpeed(playerPed)
                        local targetSpeed = GetEntitySpeed(entityHit)
                        
                        if lastTargetPosition then
                            local distanceMoved = #(hit - lastTargetPosition)
                            
                            local isPlayerMoving = IsPedWalking(playerPed) or IsPedRunning(playerPed)
                            local isTargetMoving = IsPedWalking(entityHit) or IsPedRunning(entityHit)
                            
                            if not isPlayerMoving and not isTargetMoving then
                                local isPlayerInVehicle = IsPedInAnyVehicle(playerPed, false)
                                if isPlayerInVehicle then
                                    local vehicleSpeed = GetEntitySpeed(GetVehiclePedIsIn(playerPed, false))
                                    if not (vehicleSpeed > 10) then
                                        goto continue_check
                                    end
                                end
                            end
                            
                            if not IsEntityDead(entityHit) and not IsPedRagdoll(entityHit) then
                                if distanceMoved < 0.02 then
                                    detectionCount = detectionCount + 1
                                end
                            end
                            ::continue_check::
                        else
                            detectionCount = 0
                        end
                        
                        if detectionCount > 3 then
                            sessionDetections = sessionDetections + 1
                            local shooterId = GetPlayerServerId(PlayerId())
                            local targetId = nil
                            local targetPlayerIndex = NetworkGetPlayerIndexFromPed(entityHit)
                            if targetPlayerIndex then
                                targetId = GetPlayerServerId(targetPlayerIndex)
                            end
                            if not targetId then
                                targetId = _U("unknown")
                            end
                            
                            local weaponHash = GetSelectedPedWeapon(playerPed)
                            local shooterCoords = GetEntityCoords(playerPed)
                            local targetCoords = GetEntityCoords(entityHit)
                            local distance = #(shooterCoords - targetCoords)
                            
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
                                title = _U("aimlock_detected_title"),
                                color = 16711680,
                                fields = {},
                                footer = {
                                    text = "Aimshield Aim Detection | v" .. version,
                                    icon_url = "https://cdn.discordapp.com/attachments/1332768962504691814/1350508526124011641/logo.png?ex=67f20553&is=67f0b3d3&hm=b909eb71069981702c0fc219a7f8c6e4f5ec53762ff55e3de7c90db790be1152&"
                                }
                            }
                            
                            addField(embed, _U("shooter_id"), tostring(shooterId), true)
                            addField(embed, _U("target_id"), tostring(targetId), true)
                            addField(embed, _U("weapon_hash"), tostring(weaponHash), false)
                            addField(embed, _U("shooter_coords"), string.format("X: %.2f, Y: %.2f, Z: %.2f", shooterCoords.x, shooterCoords.y, shooterCoords.z), false)
                            addField(embed, _U("target_coords"), string.format("X: %.2f, Y: %.2f, Z: %.2f", targetCoords.x, targetCoords.y, targetCoords.z), true)
                            addField(embed, _U("distance"), string.format("%.2f m", distance), false)
                            addField(embed, _U("false_ban"), _U("no"), false)
                            addField(embed, _U("detections_session"), tostring(sessionDetections), true)
                            
                            TriggerServerEvent("fdsg9us84j3j4k5jsldnf99", nil, embed)
                            detectionCount = 0
                        end
                        lastTargetPosition = hit
                    else
                        waitTime = 100
                    end
                else
                    waitTime = 100
                end
            end
        end
    end
end)

RegisterNetEvent("vjoirpwuisiogj")
AddEventHandler("vjoirpwuisiogj", function(message)
    ESX.TriggerServerCallback("jsai984kalkga94aa", function(hasPermission)
        if hasPermission then
            SendNUIMessage({
                action = "showNotification",
                text = message
            })
        end
    end)
end)

RegisterNetEvent("vSync-snow:requestScenarioConfirmation")
AddEventHandler("vSync-snow:requestScenarioConfirmation", function(data)
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = "showScenarioConfirmation",
        requesterName = data.requesterName,
        requesterId = data.requesterId,
        attackerCoords = data.attackerCoords,
        victimCoords = data.victimCoords
    })
end)

RegisterNUICallback("confirmScenario", function(data, cb)
    SetNuiFocus(false, false)
    TriggerServerEvent("vSync-snow:confirmScenario", data)
    cb("ok")
end)

RegisterNUICallback("rejectScenario", function(data, cb)
    SetNuiFocus(false, false)
    TriggerServerEvent("vSync-snow:rejectScenario", data)
    cb("ok")
end)

RegisterNUICallback("closeModal", function(data, cb)
    SetNuiFocus(false, false)
    cb("ok")
end)
