require "TimedActions/ISTimedActionQueue"

local seatNameTable = {"SeatFrontLeft", "SeatFrontRight", "SeatMiddleLeft", "SeatMiddleRight", "SeatRearLeft", "SeatRearRight"}

local Trolley = {}


Trolley.getCartsFromInvertory = function (playerInv)
    local carts = {}
    local items = playerInv:getItemsFromCategory('Container')
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if item:hasTag('Trolley') then
            table.insert(carts, item)
        end
    end
    return carts
end



Trolley.parseWorldObjects = function (worldobjects, playerNum)
    local squares = {}
    local doneSquare = {}
    local worldObjTable = {}

    for i, v in ipairs(worldobjects) do
        if v:getSquare() and not doneSquare[v:getSquare()] then
            doneSquare[v:getSquare()] = true
            table.insert(squares, v:getSquare())
        end
    end

    if #squares > 0 then
        if JoypadState.players[playerNum+1] then
            for _,square in ipairs(squares) do
                for i=0,square:getWorldObjects():size() - 1 do
                    local obj = square:getWorldObjects():get(i)
                    table.insert(worldObjTable, obj)
                end
            end
        else
            local squares2 = {}
            for idx, v in pairs(squares) do
                squares2[idx] = v
            end
            for _, square in ipairs(squares2) do
                ISWorldObjectContextMenu.getSquaresInRadius(square:getX(), square:getY(), square:getZ(), 1, doneSquare, squares)
            end
            for _, square in ipairs(squares) do
                for i=0, square:getWorldObjects():size() -1 do
                    local obj = square:getWorldObjects():get(i)
                    table.insert(worldObjTable, obj)
                end
            end
        end
    end

    return worldObjTable
end


Trolley.dropCartInsanely = function (playerObj, item, square)
    if not item then
        item = playerObj:getPrimaryHandItem()
    end
    if not square then
        square = playerObj:getSquare()
    end

    if item and item:hasTag('Trolley') then
        playerObj:setPrimaryHandItem(nil)
        playerObj:setSecondaryHandItem(nil)
        playerObj:getInventory():Remove(item)
        local pdata = getPlayerData(playerObj:getPlayerNum())
        if pdata ~= nil then
            pdata.playerInventory:refreshBackpacks()
            pdata.lootInventory:refreshBackpacks()
        end
        square:AddWorldInventoryItem(item, ZombRand(0.1, 0.5), ZombRand(0.1, 0.5), 0)
    end
end


Trolley.onTrolleyUpdate = function (playerObj)
    local playerInv = playerObj:getInventory()
    local carts = Trolley.getCartsFromInvertory(playerInv)
    local equippedCart = nil

    if playerObj:getPrimaryHandItem() and playerObj:getPrimaryHandItem():hasTag('Trolley') then
        equippedCart = playerObj:getPrimaryHandItem()
    end

    -- Drop unequipped carts. unless it is in bag.
    for idx, cart in ipairs(carts) do
        if equippedCart ~= cart then
            Trolley.dropCartInsanely(playerObj, cart)
            playerObj:Say(getText("IGUI_PlayerText_Cant_Take_Cart_This_Way"))
        end
    end

    if equippedCart then
        if isDebugEnabled() and playerObj:getCurrentState() ~= IdleState.instance() then
            print("================= Cart whit CurrentState =====================")
            print(playerObj:getCurrentState())
            print("================= End Cart whit CurrentState =====================")
        end
        
        if playerObj:getCurrentState() == IdleState.instance() then
            if playerObj:getVariableString("righthandmask") == "holdingtrolleyright" then
                if playerObj:isPlayerMoving() then
                    local player_stats = playerObj:getStats()
                    local endurance = player_stats:getEndurance()
                    if endurance < 1.0 and endurance > 0.25 then
                        player_stats:setEndurance(endurance - 0.00025)
                    end
                end
            end
        
        else -- Drop cart while do something else.
            -- DO NOT `ISTimedActionQueue.isPlayerDoingAction(playerObj)` this not enough.
            -- forced drop cart while climb window or fence, and others actions.
            Trolley.dropCartInsanely(playerObj)
        end
    end

end


Trolley.onEnterVehicle = function (playerObj)
    local vehicle = playerObj:getVehicle()
    local areaCenter = vehicle:getAreaCenter(seatNameTable[vehicle:getSeat(playerObj)+1])

    if areaCenter then 
        local sqr = getCell():getGridSquare(areaCenter:getX(), areaCenter:getY(), vehicle:getZ())
        Trolley.dropCartInsanely(playerObj, nil, sqr)
    end
end


Trolley.onEquipTrolley = function (playerNum, WItem)
    local playerObj = getSpecificPlayer(playerNum)
    if WItem:getSquare() and luautils.walkAdj(playerObj, WItem:getSquare()) then
        if playerObj:getPrimaryHandItem() then
            ISTimedActionQueue.add(ISUnequipAction:new(playerObj, playerObj:getPrimaryHandItem(), 50));
        end
        if playerObj:getSecondaryHandItem() and playerObj:getSecondaryHandItem() ~= playerObj:getPrimaryHandItem() then
            ISTimedActionQueue.add(ISUnequipAction:new(playerObj, playerObj:getSecondaryHandItem(), 50));
        end
        ISTimedActionQueue.add(ISTakeTrolley:new(playerObj, WItem, 50))
    end
end


Trolley.onUnequipTrolley = function (playerNum, item)
    ISInventoryPaneContextMenu.dropItem(item, playerNum)
end


Trolley.onGrabTrolleyFromContainer = function (playerNum, item)
    local playerObj = getSpecificPlayer(playerNum)
    local container = item:getContainer()
    local inventory = getPlayerInventory(playerNum).inventory

    if inventory:hasRoomFor(playerObj, item) then
        if item:getContainer() ~= inventory then
			if luautils.walkToContainer(item:getContainer(), playerNum) then
				ISTimedActionQueue.add(ISInventoryTransferAction:new(playerObj, item, item:getContainer(), inventory))
			end
		end
    else
        ISInventoryPaneContextMenu.dropItem(item, playerNum)
    end
end


Trolley.doFillWorldObjectContextMenu = function (playerNum, context, worldobjects, test)
    local playerObj = getSpecificPlayer(playerNum)
    local item = playerObj:getPrimaryHandItem()

    if item and item:hasTag('Trolley') then
        context:addOptionOnTop(getText("ContextMenu_DROP_CART"), playerNum, Trolley.onUnequipTrolley, item)
        return
    else
        local worldObjTable = Trolley.parseWorldObjects(worldobjects, playerNum)
        if #worldObjTable == 0 then return false end

        for _, obj in ipairs(worldObjTable) do
            local item = obj:getItem()
            if item and item:hasTag('Trolley') then
                local old_option = context:getOptionFromName(getText("ContextMenu_Grab"))
                if old_option then
                    -- context:removeOptionByName(old_option.name) -- it might grab to bags.
                    context:addOptionOnTop(getText("ContextMenu_TAKE_CART"), playerNum, Trolley.onEquipTrolley, obj)
                    return
                end                
            end
        end
    end
end


Trolley.doInventoryContextMenu = function (playerNum, context, items)
    local playerObj = getSpecificPlayer(playerNum)
    local items = ISInventoryPane.getActualItems(items)

    for _, item in ipairs(items) do
        if item and item:hasTag('Trolley') then
            context:removeOptionByName(getText("ContextMenu_Equip_Two_Hands"))
            context:removeOptionByName(getText("ContextMenu_Unequip"))
            local old_option = context:getOptionFromName(getText("ContextMenu_Grab"))
            if old_option then
                -- context:removeOptionByName(old_option.name) -- it might grab to bags.
                if item:getContainer():getType() == "floor" then
                    context:addOptionOnTop(getText("ContextMenu_TAKE_CART"), playerNum, Trolley.onEquipTrolley, item:getWorldItem())
                    return
                else
                    context:addOptionOnTop(getText("ContextMenu_TAKE_CART"), playerNum, Trolley.onGrabTrolleyFromContainer, item)
                    return
                end
            elseif item == playerObj:getPrimaryHandItem() then
                context:addOptionOnTop(getText("ContextMenu_DROP_CART"), playerNum, Trolley.onUnequipTrolley, item)
                return
            end
        end
    end
end

Events.OnPlayerUpdate.Add(Trolley.onTrolleyUpdate)
Events.OnEnterVehicle.Add(Trolley.onEnterVehicle)

Events.OnFillInventoryObjectContextMenu.Add(Trolley.doInventoryContextMenu)
Events.OnFillWorldObjectContextMenu.Add(Trolley.doFillWorldObjectContextMenu)
