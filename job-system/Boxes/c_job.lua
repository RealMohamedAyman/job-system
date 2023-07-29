local fromPos = {
    {843.7431640625, -2055.87109375, 12.5},
    {838.05859375, -2056.6689453125, 12.5},
    {828.6611328125, -2046.9560546875, 12.5},
    {830.6357421875, -2026.6806640625, 12.5},
    { 838.4951171875, -2020.0986328125, 12.5}
}

local jobWindow
local carrying = false
local LastSpawnPos
local boxObj
local blipObj
local boxMarker
local objCarry

local jobPed = createPed(35, 838.2705078125, -2067.265625, 12.8671875, 0, false)
setElementFrozen(jobPed, true)
local joinJobMarker = createMarker(838.2646484375, -2066.5615234375, 12, "cylinder", 1, 255,0,0,100)
createBlip(838.2646484375, -2066.5615234375, 12, 44)

function showJobMarkers()
    local pos = fromPos[math.random(1, #fromPos)]
    local x,y,z = pos[1], pos[2], pos[3]
    if LastSpawnPos ~= nil then
        if LastSpawnPos == pos then
            return showJobMarkers()
        end
    end
    boxObj = createObject(1220, x,y,z)
    setElementFrozen(boxObj, true)
    boxMarker = createMarker(x, y ,z, "cylinder", 0.9, 0,0,0,0)
    blipObj = createBlip(x,y,z,41)
    addEventHandler("onClientMarkerHit", boxMarker, function()
        if carrying then
            return outputChatBox("You are carrying a box, please sell it first", 255,0,0)
        end

        if isPedInVehicle(localPlayer) then
            return outputChatBox("Please leave your vehicle first", 255,0,0)
        end

        setElementFrozen(localPlayer, true)
        setPedAnimation(localPlayer, "carry","liftup", 5000, true, false, false)
        setTimer(function()
            setElementFrozen(localPlayer, false)
            destroyElement(boxMarker)
            destroyElement(boxObj)
            destroyElement(blipObj)
            outputChatBox("You've lifted a box, go to the green marker and sell it", 0,255,0)
            carrying = true
            setPedAnimation(localPlayer, "carry", "crry_prtial",0, true, true, false ,true)
            local x, y, z = getElementPosition(localPlayer)
            local rx, ry, rz = getElementRotation(localPlayer)
            objCarry = createObject(1220, x, y, z, rx, ry , rz, true)
            setObjectScale(objCarry, 0.6)
            attachElements(objCarry, localPlayer, -0.1, 0.4, 0.5, 0, 90, 0)
        end, 1000, 1)
    end, false)
end

addEventHandler("onClientResourceStart", root, function()
    local job = getElementData(localPlayer, "job")
    if job == 9 then
        showJobMarkers()
    end
end)

local function destroyJobMarkers()
    if boxObj ~= nil then
        destroyElement(boxObj)
    end

    if blipObj ~= nil then
        destroyElement(blipObj)
    end

    if boxMarker ~= nil then
        destroyElement(boxMarker)
    end

    if objCarry ~= nil then
        destroyElement(objCarry)
    end
    setPedAnimation(localPlayer)
end

local sellMarker = createMarker(840.1669921875, -2066.6640625, 12, "cylinder", 1, 0,255,0,100)
addEventHandler("onClientMarkerHit", sellMarker, function(hitPlayer)
    if hitPlayer ~= localPlayer then
        return
    end

    local job = getElementData(localPlayer, "job")
    if job ~= 9 then
        return outputChatBox("You're not employed at boxes", 255,0,0)
    end

    if not carrying then
        return
    end

    showJobMarkers()
    carrying = false

    triggerServerEvent("boxes:pay", localPlayer, 500)
    outputChatBox("Sold your box and paid you $500", 0,255,0)

    if objCarry ~= nil then
        detachElements(localPlayer, objCarry)
        destroyElement(objCarry)
    end
    setPedAnimation(localPlayer)
end)

local function joinButtonFunc(button, state)
    if (button ~= "left") and (state ~= "up") then
        return
    end

    local job = getElementData(localPlayer, "job")
    if job == 9 then
        return outputChatBox("You're already employed")
    elseif job ~= 0 then
        return outputChatBox("You're already employed, Use (/quitjob)")
    end

    triggerServerEvent("acceptJob", getLocalPlayer(), 9)
    outputChatBox("You've joined Boxes, find markers to carry Boxes")
    destroyElement(jobWindow)
    showCursor(false)

    showJobMarkers()
end

local function leaveButtonFunc(button, state)
    if (button ~= "left") and (state ~= "up") then
        return
    end

    local job = getElementData(localPlayer, "job")
    if job ~= 9 then
        return outputChatBox("You are not employed", 255, 0, 0)
    end
    triggerServerEvent("jobs:clientLeaveJob", getLocalPlayer(), getLocalPlayer())
    outputChatBox("You've quitted your job at boxes")
    destroyElement(jobWindow)
    showCursor(false)
    carrying = false

    destroyJobMarkers()
end

local function closeButtonFunc(button, state)
    if (button ~= "left") and (state ~= "up") then
        return
    end
    destroyElement(jobWindow)
    showCursor(false)
end

local function joinJob(hitPlayer)
    if hitPlayer ~= getLocalPlayer() then
        return
    end

    local width, height = 400, 230
    local scrWidth, scrHeight = guiGetScreenSize()
    local x = scrWidth / 2 - (width / 2)
    local y = scrHeight / 2 - (height / 2)
    jobWindow = guiCreateWindow(x, y, width , height, "Boxes Job", false)
    guiWindowSetMovable(jobWindow , false)
    guiWindowSetSizable(jobWindow, false)
    showCursor(true)

    local joinButton = guiCreateButton(10, 30, width - 20, 30, "Join Job", false, jobWindow)
    local leaveButton = guiCreateButton(10, 70, width - 20, 30, "Leave Job", false, jobWindow)
    local closeButton = guiCreateButton(10, 150, width - 20, 30, "Close", false, jobWindow)

    addEventHandler("onClientGUIClick", joinButton, joinButtonFunc, false)
    addEventHandler("onClientGUIClick", leaveButton, leaveButtonFunc, false)
    addEventHandler("onClientGUIClick", closeButton, closeButtonFunc, false)
end

addEventHandler("onClientMarkerHit", joinJobMarker, joinJob)