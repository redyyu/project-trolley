
local seatNameTable = {"SeatFrontLeft", "SeatFrontRight", "SeatMiddleLeft", "SeatMiddleRight", "SeatRearLeft", "SeatRearRight"}


function onTrolleyTick()
    local playersSum = getNumActivePlayers()
	for playerNum = 0, playersSum - 1 do
		local playerObj = getSpecificPlayer(playerNum)
		
		-- DO NOT switch item to present the cart is full or empty any more.
		-- just use another neutralized 3d model to present (cant even tell) both full or empty.

		-- Also, change to player can carry multiple cart in inventory same time, as more as they.
		-- why not? cart not 100% WeightReduction now!


		-- Drop cart while do something.
		if playerObj and playerObj:getVariableString("righthandmask") == "holdingtrolleyright" then

			-- forced drop Trolley cart while climb window or fence, but not wall. 
			-- climb wall already in vanilla, just like taking a bag on hand.
			if not (playerObj:getCurrentState() == IdleState.instance() or 
					playerObj:getCurrentState() == PlayerAimState.instance()) then
				local sqr = playerObj:getSquare()
				local trol = playerObj:getPrimaryHandItem()
				playerObj:getInventory():Remove(trol)
				local pdata = getPlayerData(playerObj:getPlayerNum());
				if pdata ~= nil then
					pdata.playerInventory:refreshBackpacks();
					pdata.lootInventory:refreshBackpacks();
				end
				playerObj:setPrimaryHandItem(nil);
				playerObj:setSecondaryHandItem(nil);
				sqr:AddWorldInventoryItem(trol, 0, 0, 0);
			end

			-- forced drop Trolley cart while into a vehicle
			if playerObj:getVehicle() then
				local vehicle = playerObj:getVehicle()
				local areaCenter = vehicle:getAreaCenter(seatNameTable[vehicle:getSeat(playerObj)+1])

				if areaCenter then 
					local sqr = getCell():getGridSquare(areaCenter:getX(), areaCenter:getY(), vehicle:getZ())
					local trol = playerObj:getPrimaryHandItem()
					playerObj:getInventory():Remove(trol)
					local pdata = getPlayerData(playerObj:getPlayerNum());
					if pdata ~= nil then
						pdata.playerInventory:refreshBackpacks();
						pdata.lootInventory:refreshBackpacks();
					end
					playerObj:setPrimaryHandItem(nil);
					playerObj:setSecondaryHandItem(nil);
					sqr:AddWorldInventoryItem(trol, 0, 0, 0);
				end
			end
		end

    end
end


Events.OnTick.Add(onTrolleyTick);
