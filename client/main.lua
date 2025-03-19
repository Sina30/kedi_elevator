ESX = nil
QBCore = nil
local framework, PlayerData, target
local isUIOpen = false
local isTransitioning = false

local function ShowNotification(data)
    if Config.UI.type == 'ox_lib' then
        lib.notify({
            title = data.title,
            description = data.message,
            type = data.type,
            duration = data.duration or 5000
        })
    end
end

local function ShowProgress(data)
    if Config.UI.type == 'ox_lib' then
        return lib.progressBar({
            duration = data.duration,
            label = data.label,
            useWhileDead = false,
            canCancel = data.canCancel,
            anim = data.animation,
        })
    end
end

local function ShowTextUI(data)
    if Config.UI.type == 'ox_lib' then
        lib.showTextUI(data.message, {
            position = "right-center",
            icon = data.key,
        })
    end
end

local function HideTextUI()
    if Config.UI.type == 'ox_lib' then
        lib.hideTextUI()
    end
end

-- Framework initialization
CreateThread(function()
    if framework then return end

    framework = GetResourceState('es_extended') == 'started' and 'esx' or GetResourceState('qb-core') == 'started' and 'qb' or nil

    if not framework then return end

    if framework == 'esx' then
        ESX = exports.es_extended:getSharedObject()
        PlayerData = ESX.GetPlayerData()
        while not PlayerData or not PlayerData.job do
            Wait(100)
            PlayerData = ESX.GetPlayerData()
        end

        RegisterNetEvent('esx:setJob', function(job)
            PlayerData.job = job
        end)
        
        RegisterNetEvent('esx:playerLoaded', function(xPlayer)
            PlayerData = xPlayer
        end)
    elseif framework == 'qb' then
        QBCore = exports['qb-core']:GetCoreObject()
        PlayerData = QBCore.Functions.GetPlayerData()

        RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job)
            PlayerData.job = job
        end)
        
        RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
            PlayerData = QBCore.Functions.GetPlayerData()
        end)
    end
end)

local function RefreshPlayerData()
    if framework == 'esx' then
        PlayerData = ESX.GetPlayerData()
    elseif framework == 'qb' then
        PlayerData = QBCore.Functions.GetPlayerData()
    end
    print('Player data manually refreshed')
end

RegisterCommand('refreshjob', function()
    RefreshPlayerData()
    ShowNotification({
        type = 'success',
        title = 'Job Updated',
        message = 'Your job data has been refreshed: ' .. PlayerData.job.name
    })
end, false)

CreateThread(function()
    while not framework do
        Wait(500)
    end
    if framework == 'esx' then
        target = 'qtarget'
    else
        target = 'qb-target'
    end
end)

local function ClearAllAnimations()
    local ped = cache.ped
    ClearPedTasks(ped)
    ClearPedSecondaryTask(ped)
end

local function PlayElevatorAnimation()
    local ped = cache.ped
    local dict = Config.Animations.waiting.dict
    local anim = Config.Animations.waiting.name
    
    lib.requestAnimDict(dict)
    TaskPlayAnim(ped, dict, anim, 8.0, -8.0, -1, Config.Animations.waiting.flags, 0, false, false, false)
end

local function TransitionToFloor(coords, heading)
    local ped = cache.ped
    if isUIOpen then
        isUIOpen = false
        SendNUIMessage({
            action = 'closeElevator'
        })
        SetNuiFocus(false, false)
    end
    isTransitioning = true
    ClearAllAnimations()
    ShowProgress({
        duration = 3000,
        label = 'Elevator in motion...',
        canCancel = false,
        animation = Config.Animations.entering,
        onComplete = function()
            ClearAllAnimations()
        end
    })
    DoScreenFadeOut(1500)
    while not IsScreenFadedOut() do Wait(0) end
    RequestCollisionAtCoord(coords.x, coords.y, coords.z)
    while not HasCollisionLoadedAroundEntity(ped) do Wait(0) end
    SetEntityCoords(ped, coords.x, coords.y, coords.z, false, false, false, false)
    SetEntityHeading(ped, heading or 0.0)
    PlayElevatorAnimation()
    Wait(1000)
    ClearAllAnimations()
    DoScreenFadeIn(1500)
    isTransitioning = false
end

local function OpenElevatorUI(elevatorId, floorIndex)
    if isUIOpen or isTransitioning then return end
    RefreshPlayerData()
    local elevator = Config.Elevators[elevatorId]
    if not elevator then return end
    if not elevator.settings.buildingName then
        elevator.settings.buildingName = elevator.settings.name
    end
    SendNUIMessage({
        action = 'openElevator',
        elevator = {
            id = elevatorId,
            settings = elevator.settings
        },
        currentFloor = floorIndex,
        floors = elevator.floors
    })
    SetNuiFocus(true, true)
    isUIOpen = true
    HideTextUI()
end

RegisterNUICallback('closeElevator', function(data, cb)
    SetNuiFocus(false, false)
    isUIOpen = false
    cb({})
end)

RegisterNUICallback('selectFloor', function(data, cb)
    cb({success = true})

    if isTransitioning then
        return
    end

    RefreshPlayerData()
    
    local elevator = Config.Elevators[data.elevator]
    local floor = elevator.floors[data.floor]
    local hasAccess = true

    if floor.groups then
        hasAccess = false
        for _, group in ipairs(floor.groups) do
            if PlayerData.job.name == group then
                hasAccess = true
                break
            end
        end
    end
    
    if hasAccess then
        SetNuiFocus(false, false)
        isUIOpen = false
        isTransitioning = true
        PlaySoundFrontend(-1, Config.Sounds.elevatorMoving, "HUD_FRONTEND_DEFAULT_SOUNDSET", 1)
        TransitionToFloor(floor.coords, floor.heading)
        PlaySoundFrontend(-1, Config.Sounds.elevatorArrived, "HUD_FRONTEND_DEFAULT_SOUNDSET", 1)
    else
        ShowNotification({
            type = 'error',
            title = 'Access Denied',
            message = 'You do not have access to this floor',
            icon = 'fa-solid fa-lock'
        })
    end
end)

RegisterNUICallback('playSound', function(data, cb)
    if Config.Sounds[data.sound] then
        PlaySoundFrontend(-1, Config.Sounds[data.sound], "HUD_FRONTEND_DEFAULT_SOUNDSET", 1)
    end
    cb({})
end)


AddEventHandler('kedi_elevator:openMenu', function(data)
    OpenElevatorUI(data.elevator, data.floor)
end)

-- Target setup
CreateThread(function()
    while not target and GetResourceState('ox_target') ~= 'started' do
        Wait(500)
    end

    for elevatorId, elevator in pairs(Config.Elevators) do
        for floorIndex, floor in ipairs(elevator.floors) do
            if target then
                exports[target]:AddBoxZone(
                    elevatorId..':'..floorIndex,
                    floor.coords,
                    floor.target.width,
                    floor.target.length,
                    {
                        name = elevatorId..':'..floorIndex,
                        heading = floor.target.heading or 0.0,
                        debugPoly = false,
                        minZ = floor.coords.z - 1.5,
                        maxZ = floor.coords.z + 1.5
                    },
                    {
                        options = {
                            {
                                event = 'kedi_elevator:openMenu',
                                icon = elevator.settings.icon or 'fa-solid fa-elevator',
                                label = 'Use Elevator',
                                elevator = elevatorId,
                                floor = floorIndex
                            },
                        },
                        distance = 1.5
                    }
                )
            end
            
            if GetResourceState('ox_target') == 'started' then
                exports.ox_target:addBoxZone({
                    coords = floor.coords,
                    size = vec3(floor.target.width, floor.target.length, 3.0),
                    rotation = floor.target.heading or 0.0,
                    debug = false,
                    options = {
                        {
                            name = 'elevator_' .. elevatorId .. '_' .. floorIndex,
                            icon = elevator.settings.icon or 'fa-solid fa-elevator',
                            label = 'Use Elevator',
                            onSelect = function()
                                OpenElevatorUI(elevatorId, floorIndex)
                            end,
                            distance = 1.5
                        }
                    }
                })
            end
        end
    end
end)


CreateThread(function()
    Wait(1000)
    
    local elevatorMarkers = {}
    local currentTextUI = nil
    local textUIDebounce = 0
    
    for elevatorId, elevator in pairs(Config.Elevators) do
        for floorIndex, floor in ipairs(elevator.floors) do
            table.insert(elevatorMarkers, {
                coords = floor.coords,
                elevatorId = elevatorId,
                floorIndex = floorIndex,
                theme = elevator.settings.theme,
                name = elevator.settings.name or 'Elevator'
            })
        end
    end
    
    while true do
        local sleep = 1000
        local playerCoords = GetEntityCoords(cache.ped)
        local closestDistance = 999
        local closestMarker = nil
        
        for _, marker in ipairs(elevatorMarkers) do
            local distance = #(playerCoords - marker.coords)
            if distance < closestDistance and distance < 10.0 then
                closestDistance = distance
                closestMarker = marker
            end
        end
        
        if closestMarker and closestDistance < 10.0 then
            sleep = 0
            
            DrawMarker(2, 
                closestMarker.coords.x, 
                closestMarker.coords.y, 
                closestMarker.coords.z + 1.0, 
                0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 
                0.3, 0.3, 0.3, 
                tonumber(closestMarker.theme.primary:sub(2), 16), 
                tonumber(closestMarker.theme.secondary:sub(2), 16), 
                255, true, false, false, true, nil, nil, false
            )
            
            if closestDistance < 1.5 and not isUIOpen and not isTransitioning then
                if textUIDebounce < GetGameTimer() then
                    textUIDebounce = GetGameTimer() + 500 
                    
                    if not currentTextUI or currentTextUI ~= closestMarker.elevatorId then
                        currentTextUI = closestMarker.elevatorId
                        
                        HideTextUI()
                        Wait(50) 
                        
                        ShowTextUI({
                            key = 'E',
                            message = 'Use ' .. closestMarker.name,
                            canInteract = true
                        })
                        
                        CreateThread(function()
                            while currentTextUI == closestMarker.elevatorId and not isUIOpen and not isTransitioning do
                                if IsControlJustPressed(0, 38) then -- E key
                                    OpenElevatorUI(closestMarker.elevatorId, closestMarker.floorIndex)
                                end
                                Wait(0)
                            end
                        end)
                    end
                end
            elseif (closestDistance >= 1.5 or isUIOpen or isTransitioning) and currentTextUI then
                currentTextUI = nil
                HideTextUI()
            end
        elseif currentTextUI then
            currentTextUI = nil
            HideTextUI()
        end
        
        Wait(sleep)
    end
end)

AddEventHandler('gameEventTriggered', function(name, args)
    if name == 'CEventNetworkEntityDamage' then
        local victim = args[1]
        if victim == cache.ped and IsEntityDead(victim) then
            ClearAllAnimations()
            if isUIOpen then
                SetNuiFocus(false, false)
                isUIOpen = false
                SendNUIMessage({
                    action = 'closeElevator'
                })
            end
        end
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        ClearAllAnimations()
        if isUIOpen then
            SetNuiFocus(false, false)
        end
    end
end)
