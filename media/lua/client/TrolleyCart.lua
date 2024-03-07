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


Trolley.dropCart = function (playerObj, square)
    local item = playerObj:getPrimaryHandItem()
    if not square then
        square = playerObj:getSquare()
    end

    if item and item:hasTag('Trolley') then
        playerObj:getInventory():Remove(item)
        local pdata = getPlayerData(playerObj:getPlayerNum());
        if pdata ~= nil then
            pdata.playerInventory:refreshBackpacks();
            pdata.lootInventory:refreshBackpacks();
        end
        playerObj:setPrimaryHandItem(nil);
        playerObj:setSecondaryHandItem(nil);
        square:AddWorldInventoryItem(item, 0, 0, 0);
    end
end


Trolley.onTrolleyUpdate = function (playerObj)
    local playerInv = playerObj:getInventory()
    local carts = Trolley.getCartsFromInvertory(playerInv)
    local item = playerObj:getPrimaryHandItem()
    local hasCart = false

    -- Drop other cart. only keep one cart at time.
    if #carts > 0 then
        if not item or not item:hasTag('Trolley') then
            item = carts[1]
            playerObj:setPrimaryHandItem(item)
            playerObj:setSecondaryHandItem(item)
        end
        if item:hasTag('Trolley') and #carts > 1 then
            for _, cart in ipairs(carts) do
                if item ~= cart then
                    playerInv:Remove(cart)
                    playerObj:getCurrentSquare():AddWorldInventoryItem(cart, 0, 0, 0)
                end
            end
        end
        local pdata = getPlayerData(playerObj:getPlayerNum())
        if pdata ~= nil then
            pdata.playerInventory:refreshBackpacks()
            pdata.lootInventory:refreshBackpacks()
        end
        hasCart = true
    end

    -- Drop cart while do something else.
    if playerObj:getVariableString("righthandmask") == "holdingtrolleyright" and hasCart then
        if playerObj:isPlayerMoving() then
            local player_stats = playerObj:getStats()
            local endurance = player_stats:getEndurance()
            if endurance < 1.0 and endurance > 0.25 then
                player_stats:setEndurance(endurance - 0.00025)
            end
        end
        -- forced drop cart while climb window or fence, but not wall. 
        -- climb wall already in vanilla, just like taking a bag on hand.
        if not (playerObj:getCurrentState() == IdleState.instance() or 
                playerObj:getCurrentState() == PlayerAimState.instance()) then
            Trolley.dropCart(playerObj)
        end
    end

end


Trolley.onEnterVehicle = function (playerObj)
    local vehicle = playerObj:getVehicle()
    local areaCenter = vehicle:getAreaCenter(seatNameTable[vehicle:getSeat(playerObj)+1])

    if areaCenter then 
        local sqr = getCell():getGridSquare(areaCenter:getX(), areaCenter:getY(), vehicle:getZ())
        Trolley.dropCart(playerObj, sqr)
    end
end


Trolley.onEquipTrolley = function (playerObj, WItem)
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


Trolley.parseWorldObjects = function (worldobjects, playerIdx)
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
        if JoypadState.players[playerIdx+1] then
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


Trolley.onUnequipTrolley = function (playerObj)
    Trolley.dropCart(playerObj)
end


Trolley.onGrabTrolleyFromContainer = function (playerObj, item)
    local container = item:getContainer()
    if container:getType() ~= "floor" then
        container:Remove(item)
        local pdata = getPlayerData(playerObj:getPlayerNum())
        if pdata ~= nil then
            playerObj:getCurrentSquare():AddWorldInventoryItem(item, 0, 0, 0)
            pdata.playerInventory:refreshBackpacks()
            pdata.lootInventory:refreshBackpacks()
        end
    end
end


Trolley.doFillWorldObjectContextMenu = function (player, context, worldobjects, test)
    local playerObj = getSpecificPlayer(player)
    local playerInv = playerObj:getInventory()
    local item = playerObj:getPrimaryHandItem()

    if item and item:hasTag('Trolley') then
        context:addOptionOnTop(getText("ContextMenu_DROP_CART"), playerObj, Trolley.onUnequipTrolley)
        return
    else
        local worldObjTable = Trolley.parseWorldObjects(worldobjects, player)
        if #worldObjTable == 0 then return false end

        for _, obj in ipairs(worldObjTable) do
            local item = obj:getItem()
            if item and item:hasTag('Trolley') then
                local old_option = context:getOptionFromName(getText("ContextMenu_Grab"))
                if old_option then
                    -- context:removeOptionByName(old_option.name)
                    context:addOptionOnTop(getText("ContextMenu_TAKE_CART"), playerObj, Trolley.onEquipTrolley, obj)
                    return
                end                
            end
        end
    end
end


Trolley.doInventoryContextMenu = function (playerNumber, context, items)
    local playerObj = getSpecificPlayer(playerNumber);
    local items = ISInventoryPane.getActualItems(items)

    for _, item in ipairs(items) do
        if item and item:hasTag('Trolley') then
            context:removeOptionByName(getText("ContextMenu_Equip_Two_Hands"))
            context:removeOptionByName(getText("ContextMenu_Unequip"))
            local old_option = context:getOptionFromName(getText("ContextMenu_Grab"))
            if old_option then
                -- context:removeOptionByName(old_option.name)
                if item:getContainer():getType() == "floor" then
                    context:addOptionOnTop(getText("ContextMenu_TAKE_CART"), playerObj, Trolley.onEquipTrolley, item:getWorldItem())
                    return
                else
                    context:addOptionOnTop(getText("ContextMenu_GRAB_CART_TO_FLOOR"), playerObj, Trolley.onGrabTrolleyFromContainer, item)
                    return
                end
            end
        end
    end
end

Events.OnPlayerUpdate.Add(Trolley.onTrolleyUpdate)
Events.OnEnterVehicle.Add(Trolley.onEnterVehicle)

Events.OnFillInventoryObjectContextMenu.Add(Trolley.doInventoryContextMenu)
Events.OnFillWorldObjectContextMenu.Add(Trolley.doFillWorldObjectContextMenu)





