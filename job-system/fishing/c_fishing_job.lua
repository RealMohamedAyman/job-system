local count = 0
local pFish = nil
local state = 0
local fishSize = 0
local hotSpot1 = nil
local hotSpot2 = nil
local totalCatch = 0
local fishingBlip, fishingMarker, fishingCol = nil

local function showFishMarker(msg)
	if not (fishingBlip) then -- If the /sellfish marker isnt already being shown...
		fishingBlip = createBlip( 147.0830078125,-1795.9716796875, 3.4455327987671, 0, 2, 255, 0, 255, 255 )
		fishingMarker = createMarker( 147.0830078125, -1795.9716796875,3.4455327987671, "cylinder", 2, 255, 0, 255, 150 )
		fishingCol = createColSphere ( 147.0830078125, -1795.9716796875, 3.4455327987671, 3)
		if msg == 1 then
			exports.hud:sendBottomNotification(localPlayer, "Fishing", "When you are done fishing you can sell your catch at the fish market (pink marker), using /sellfish.")
		elseif msg == 2 then
			exports.hud:sendBottomNotification(localPlayer, "Fishing", "You still have " .. totalCatch .. " lbs of fish with you. Go to the fish market to sell it.")
		end
	end
end

function castLine(oldcatch)

	local element = getPedContactElement(getLocalPlayer()) or getElementAttachedTo(getLocalPlayer())
	if not (isElement(element)) then
		exports.hud:sendBottomNotification(localPlayer, "Fishing", "You must be on a boat to fish.")
	else
		if not (getElementType(element)=="vehicle") then
			exports.hud:sendBottomNotification(localPlayer, "Fishing", "You must be on a boat to fish.")
		else
			if not (getVehicleType(element)=="Boat") then
				exports.hud:sendBottomNotification(localPlayer, "Fishing", "You must be on a boat to fish.")
			else
				local x, y, z = getElementPosition(getLocalPlayer())
				if ((y < 3000) and ( y > -3000)) and ((x > -3000) and (x < 3000)) then -- Are they out at sea.
					exports.hud:sendBottomNotification(localPlayer, "Fishing", "You must be out at sea to fish. (Off the map).")
				else
					if (catchTimer) then -- Are they already fishing?
						exports.hud:sendBottomNotification(localPlayer, "Fishing", "You have already cast your line. Wait for a bite.")
					else
						totalCatch = oldcatch
						if (totalCatch >= 2000) then
							exports.hud:sendBottomNotification(localPlayer, "Fishing", "This boat cant hold any more fish. Sell your current catch first.")
							showFishMarker()
						else
							local biteTimer = math.random(30000,300000) -- 30 seconds to 5 minutes for a bite.
							catchTimer = setTimer( fishOnLine, biteTimer, 1 ) -- A fish will bite within 1 and 5 minutes.
							triggerServerEvent("castOutput", getLocalPlayer())
							showFishMarker(1)
						end
					end
				end
			end
		end
	end
end
addEvent("castLine", true)
addEventHandler("castLine", getRootElement(), castLine)

function restoreFishingJob(amount)
	totalCatch = amount
	showFishMarker(2)
end
addEvent("restoreFishingJob", true)
addEventHandler("restoreFishingJob", getLocalPlayer(), restoreFishingJob)

function fishOnLine()
	
	killTimer(catchTimer)
	catchTimer=nil
	local x, y, z = getElementPosition(getLocalPlayer())
	if ((y < 3000) and ( y > -3000)) and ((x > -3000) and (x < 3000)) then
		exports.hud:sendBottomNotification(localPlayer, "Fishing", "You should have stayed out at sea if you wanted to fish.")
	else
		triggerServerEvent("fishOnLine", getLocalPlayer()) -- outputs /me
		
		--  the progress bar
		count = 0
		state = 0
				
		if (pFish) then
			destroyElement(pFish)
		end
			
		pFish = guiCreateProgressBar(0.425, 0.75, 0.2, 0.035, true)
		exports.hud:sendBottomNotification(localPlayer, "Fishing", "You've got a bite! Use [ and ] to reel it in.")
		bindKey("[", "down", reelItIn)
		setElementData(getLocalPlayer(), "fishing", true, false)
		
		-- create two timers
		resetTimer = setTimer(resetProgress, 2750, 0)
		gotAwayTimer = setTimer(gotAway, 60000, 1)
		
		if ((x >= 3950) and (x <= 4450)) and ((y >= -2050) and (y <= -1550)) or (x >= -250) and (x <= 250) and (y >= -4103) and (y <= -3603) then
			fishSize = math.random(100, 200)
		else
			if (x > 5500) or (x < -5500) or (y > 5500) or (y < -5500) then
				fishSize = math.random(80, 105)
			elseif (x > 4500) or (x < -4500) or (y > 4500) or (y < -4500) then
				fishSize = math.random(50, 90)
			elseif (x > 3500) or (x < -3500) or (y > 3500) or (y < -3500) then
				fishSize = math.random(30,70)
			else
				fishSize = math.random(1, 50)
			end
		end
		
		local lineSnap = math.random(1,10) -- Chances of line snapping 1/10. Fish over 100lbs are twice as likely to snap your line.
		if (fishSize>=100)then
			if (lineSnap > 9) then
				exports.hud:sendBottomNotification(localPlayer, "Fishing", "A large fish has broken your line. You need to buy a new rod.")
				triggerServerEvent("lineSnap",getLocalPlayer())
				killTimer (resetTimer)
				killTimer (gotAwayTimer)
				destroyElement(pFish)
				pFish = nil
				unbindKey("[", "down", reelItIn)
				unbindKey("]", "down", reelItIn)
				fishSize = 0
				setElementData(getLocalPlayer(), "fishing", false, false)
			end
		end
	end
end

function reelItIn()
	if (state==0) then
		bindKey("[", "down", reelItIn)
		unbindKey("]", "down", reelItIn)
		state = 1
	elseif (state==1) then
		bindKey("[", "down", reelItIn)
		unbindKey("]", "down", reelItIn)
		state = 0
	end
	
	count = count + 1
	guiProgressBarSetProgress(pFish, count)
	
	if (count>=100) then
		killTimer (resetTimer)
		killTimer (gotAwayTimer)
		destroyElement(pFish)
		pFish = nil
		unbindKey("[", "down", reelItIn)
		unbindKey("]", "down", reelItIn)

		totalCatch = math.floor(totalCatch + fishSize)
		exports.hud:sendBottomNotification(localPlayer, "Fishing", "You have caught " .. totalCatch .. " lbs of fish so far.")
		triggerServerEvent("catchFish", getLocalPlayer(), fishSize, totalCatch)
		fishSize = 0
		
		setElementData(getLocalPlayer(), "fishing", false, false)
	end
end

function resetProgress()
	if(count>=0)then
		local difficulty = (fishSize/4)
		guiProgressBarSetProgress(pFish, (count-difficulty))
		count = count-difficulty
	else
		count = 0
	end
end

function gotAway()
	killTimer (resetTimer)
	destroyElement(pFish)
	pFish = nil
	unbindKey("[", "down", reelItIn)
	unbindKey("]", "down", reelItIn)
	outputChatBox("#FF9933The fish got away.", 255, 0, 0, true)
	fishSize = 0
	setElementData(getLocalPlayer(), "fishing", false, false)
end

-- /totalcatch command
function currentCatch()
	exports.hud:sendBottomNotification(localPlayer, "Fishing", "You have caught " .. totalCatch .. " lbs of fish so far.")
end
addCommandHandler("totalcatch", currentCatch, false, false)

-- sellfish
function unloadCatch(thePlayer, commandName)
	if (isElementWithinColShape(getLocalPlayer(), fishingCol)) then
		if (totalCatch == 0) then
			exports.hud:sendBottomNotification(localPlayer, "Fishing", "You need to catch some fish to sell first.")
		else
			local profit = math.floor(totalCatch*3.00)
			exports.hud:sendBottomNotification(localPlayer, "Fishing", "You made $" .. exports.global:formatMoney(profit) .. " from the fish you caught.")
			triggerServerEvent("sellcatch", getLocalPlayer(), totalCatch )
			destroyElement(fishingBlip)
			destroyElement(fishingMarker)
			destroyElement(fishingCol)
			fishingBlip, fishingMarker, fishingCol = nil
			
			totalCatch = 0
		end
	else
		exports.hud:sendBottomNotification(localPlayer, "Fishing", "You need to be at a fish market to sell your fish.")
	end
end
addCommandHandler("sellFish", unloadCatch, false, false)
