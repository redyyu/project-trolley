TROLLEY_TYPES = {"SimpleTrolleyCart.CartContainer"}

local seatNameTable = {"SeatFrontLeft", "SeatFrontRight", "SeatMiddleLeft", "SeatMiddleRight", "SeatRearLeft", "SeatRearRight"}


local function hasTrollyName(x)
	for _, v in pairs(TROLLEY_TYPES) do
		if v == x then return true end
	end
	return false
end


local function countTrolly(playerInv)
	local count = 0;

	for _, v in pairs(TROLLEY_TYPES) do
		count = count + playerInv:getItemCount(v);
	end
	return count
end


local function onTrolleyTick()
    local playersSum = getNumActivePlayers()
	for playerNum = 0, playersSum - 1 do
		local playerObj = getSpecificPlayer(playerNum)
		
		-- DO NOT switch item to present the cart is full or empty any more.
		-- just use another neutralized 3d model to present (cant even tell) both full or empty.

		if playerObj then

			-- Drop other cart. only keep one cart at time.
			local playerInv = playerObj:getInventory()

			if countTrolly(playerInv) > 0 then
				for i = 1, #TROLLEY_TYPES do
					local itemsArray = playerInv:getItemsFromType(TROLLEY_TYPES[i])

					for j = 0, itemsArray:size() - 1 do
						local _item = itemsArray:get(j)
						if _item ~= playerObj:getPrimaryHandItem() then
							playerInv:Remove(_item)
							local dropX,dropY,dropZ = ISInventoryTransferAction.GetDropItemOffset(playerObj, playerObj:getCurrentSquare(), _item)
							playerObj:getCurrentSquare():AddWorldInventoryItem(_item, dropX, dropY, dropZ);
							break
						end
					end
				end
			end

			-- No need those, Drop when not equip any way.

			-- elseif countTrolly(playerInv) == 1 then
			-- 	for i = 1, #TROLLEY_TYPES do
			-- 		local _item = playerInv:getFirstType(TROLLEY_TYPES[i])
			-- 		if _item ~= playerObj:getPrimaryHandItem() then
			-- 			playerObj:setPrimaryHandItem(_item)
			-- 			playerObj:setSecondaryHandItem(_item)
			-- 			getPlayerData(playerObj:getPlayerNum()).playerInventory:refreshBackpacks();
			-- 		end
			-- 	end
			-- end

			
			-- Drop cart while do something.
			if playerObj:getVariableString("righthandmask") == "holdingtrolleyright" then

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
end


local function onEquipTrolley (playerObj, WItem)
    if WItem:getSquare() and luautils.walkAdj(playerObj, WItem:getSquare()) then
		if playerObj:getPrimaryHandItem() then
			ISTimedActionQueue.add(ISUnequipAction:new(playerObj, playerObj:getPrimaryHandItem(), 50));
		end
		if playerObj:getSecondaryHandItem() and playerObj:getSecondaryHandItem() ~= playerObj:getPrimaryHandItem() then
			ISTimedActionQueue.add(ISUnequipAction:new(playerObj, playerObj:getSecondaryHandItem(), 50));
		end
		ISTimedActionQueue.add(ISTakeTrolley:new(playerObj, WItem, 1))
	end
end

local function getWorldObjectsOnSquares(squares, worldObj)
	for _,square in ipairs(squares) do
		local squareObjects = square:getWorldObjects()
		for i=1,squareObjects:size() do
			local obj = squareObjects:get(i-1)
			table.insert(worldObj, obj)
		end
	end
end


local function onDropTrolley(playerObj)
	playerObj:setPrimaryHandItem(nil);
	playerObj:setSecondaryHandItem(nil);
	local pdata = getPlayerData(playerObj:getPlayerNum());
	if pdata ~= nil then
		pdata.playerInventory:refreshBackpacks();
		pdata.lootInventory:refreshBackpacks();
	end
end


local function TrolleyOnFillWorldObjectContextMenu(player, context, worldobjects, test)
	local playerObj = getSpecificPlayer(player)
	local squares = {}
	local doneSquare = {}
	
	local playerInv = playerObj:getInventory()

	if countTrolly(playerInv) > 0 then
		context:addOption(getText("ContextMenu_DROP_CART"), playerObj, onDropTrolley)
		return
	else

		for i,v in ipairs(worldobjects) do
			if v:getSquare() and not doneSquare[v:getSquare()] then
				doneSquare[v:getSquare()] = true
				table.insert(squares, v:getSquare())
			end
		end

		if #squares == 0 then return false end
		
		local worldObjTable = {}
		if JoypadState.players[player+1] then
			for _,square in ipairs(squares) do
				for i=1,square:getWorldObjects():size() do
					local obj = square:getWorldObjects():get(i-1)
					table.insert(worldObjTable, obj)
				end
			end
		else
			local squares2 = {}
			for k,v in pairs(squares) do
				squares2[k] = v
			end
			local radius = 1
			for _,square in ipairs(squares2) do
				ISWorldObjectContextMenu.getSquaresInRadius(square:getX(), square:getY(), square:getZ(), radius, doneSquare, squares)
			end
			getWorldObjectsOnSquares(squares, worldObjTable)
		end

		if #worldObjTable == 0 then return false end

		for _, obj in ipairs(worldObjTable) do
			local trolleyName = obj:getItem():getFullType()
			if hasTrollyName(trolleyName) then
				local old_option_update = context:getOptionFromName(getText("ContextMenu_Grab"))
				if old_option_update then
					context:updateOptionTsar(old_option_update.id, getText("ContextMenu_TAKE_CART"), playerObj, onEquipTrolley, obj)
					return
				end				
			end
		end
	end
end


-- local function TrolleyInventoryContextMenu(playerNumber, context, items)
-- 	local playerObj = getSpecificPlayer(playerNumber);
-- 	local items = ISInventoryPane.getActualItems(items)
-- 	local item = items[1];

-- 	if #items > 0 and hasTrollyName(item:getFullType()) then
-- 		context:removeOptionByName(getText("ContextMenu_Equip_Two_Hands"))
-- 		context:removeOptionByName(getText("ContextMenu_Unequip"))
-- 		local old_option_update = context:getOptionFromName(getText("ContextMenu_Grab"))
-- 		if old_option_update then
-- 			context:updateOptionTsar(old_option_update.id, getText("ContextMenu_TAKE_CART"), playerObj, onEquipTrolley, item:getWorldItem())
-- 			return
-- 		end
-- 	end
	
-- end


local function onGrabTrolleyFromContainer(playerObj, item)
	local container = item:getContainer();
	playerObj:getInventory():AddItem(item);
	container:Remove(item);
	
	local pdata = getPlayerData(playerObj:getPlayerNum());
	if pdata ~= nil then
		pdata.playerInventory:refreshBackpacks();
		pdata.lootInventory:refreshBackpacks();
	end
end


local function TrolleyInventoryContextMenu(playerNumber, context, items)
	local playerObj = getSpecificPlayer(playerNumber);
	local items = ISInventoryPane.getActualItems(items)

	for _, item in ipairs(items) do
		if item and hasTrollyName(item:getFullType()) then
			context:removeOptionByName(getText("ContextMenu_Equip_Two_Hands"))
			context:removeOptionByName(getText("ContextMenu_Unequip"))
			if item:getContainer() then
				local old_option_update = context:getOptionFromName(getText("ContextMenu_Grab"))
				if old_option_update then
					context:updateOptionTsar(old_option_update.id, getText("ContextMenu_GRAB_CONTAINER"), playerObj, onGrabTrolleyFromContainer, item)
					return
				end
			end
		end
	end
end


Events.OnFillInventoryObjectContextMenu.Add(TrolleyInventoryContextMenu); 
Events.OnFillWorldObjectContextMenu.Add(TrolleyOnFillWorldObjectContextMenu);
Events.OnTick.Add(onTrolleyTick);



