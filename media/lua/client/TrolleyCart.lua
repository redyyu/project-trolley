require "TimedActions/ISTimedActionQueue"
require "TimedActions/ISInventoryTransferAction"

local seatNameTable = {"SeatFrontLeft", "SeatFrontRight", "SeatMiddleLeft", "SeatMiddleRight", "SeatRearLeft", "SeatRearRight"}

local Trolley = {}


Trolley.getTrolleysFromInvertory = function (playerInv)
    local trolley_items = {}
    local items = playerInv:getItemsFromCategory("Container") -- same with getAllCategory("Container")
    for j = 0, items:size() - 1 do
        local item = items:get(j)
        if item:hasTag('Trolley') then
            table.insert(trolley_items, item)
        end
    end
    return trolley_items
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


Trolley.dropItemInsanely = function (playerObj, item, square)
    if playerObj and item then
        if not square then
            square = playerObj:getSquare()
        end

        if item == playerObj:getPrimaryHandItem() then
            playerObj:setPrimaryHandItem(nil)
        end
        if item == playerObj:getSecondaryHandItem() then
            playerObj:setSecondaryHandItem(nil)
        end
        
        playerObj:getInventory():Remove(item)
        local dropX,dropY,dropZ = ISInventoryTransferAction.GetDropItemOffset(playerObj, playerObj:getCurrentSquare(), primary)
        playerObj:getCurrentSquare():AddWorldInventoryItem(item, dropX, dropY, dropZ)

        local pdata = getPlayerData(playerObj:getPlayerNum());
        if pdata ~= nil then
            pdata.playerInventory:refreshBackpacks()
            pdata.lootInventory:refreshBackpacks()
        end
    end
end


Trolley.onTrolleyUpdate = function (playerObj)
    local playerInv = playerObj:getInventory()
    local equippedCart = nil

    for idx, item in ipairs(Trolley.getTrolleysFromInvertory(playerInv)) do
        -- DO NOT AUTO equipped, it will cause lot more logic prolbem,
        -- such as conflict with other MOD did samething.
        -- item will keep equip/unequip in millseconds, don't even see the action.
        -- unless check the log.

        -- equip first Trolley when no Trolley equipped.
        -- if not equippedCart and item:hasTag('Trolley') then
        --     playerObj:setPrimaryHandItem(item)
        --     playerObj:setSecondaryHandItem(item)
        --     equippedCart = item
        -- end

        -- drop any Trolley not equipped.
        if item:isEquipped() then
            equippedCart = item
        else
            -- no cart in inventory while not equipped.
            Trolley.dropItemInsanely(playerObj, item)
            playerObj:Say(getText('IGUI_PlayerText_Cant_Take_Cart_This_Way'))
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
            Trolley.dropItemInsanely(playerObj, equippedCart)
        end
    end

end


Trolley.onEnterVehicle = function (playerObj)
    if playerObj:getPrimaryHandItem() and playerObj:getPrimaryHandItem():hasTag('Trolley') then
        local equippedCart = playerObj:getPrimaryHandItem()
        local vehicle = playerObj:getVehicle()
        local areaCenter = vehicle:getAreaCenter(seatNameTable[vehicle:getSeat(playerObj)+1])

        if areaCenter then
            local sqr = getCell():getGridSquare(areaCenter:getX(), areaCenter:getY(), vehicle:getZ())
            Trolley.dropItemInsanely(playerObj, equippedCart, sqr)
        end
    end
end


Trolley.onEquipTrolley = function (playerNum, item)
    local playerObj = getSpecificPlayer(playerNum)
    local walk_to = nil
    if item:getWorldItem() then
        walk_to = luautils.walkAdj(playerObj, item:getWorldItem():getSquare())
    elseif item:getContainer() then
        walk_to = luautils.walkToContainer(item:getContainer(), playerObj:getPlayerNum())
    else
        walk_to = luautils.walkAdj(playerObj, playerObj:getCurrentSquare())
    end
    
    if walk_to then
        if playerObj:getPrimaryHandItem() then
            ISTimedActionQueue.add(ISUnequipAction:new(playerObj, playerObj:getPrimaryHandItem(), 50));
        end
        if playerObj:getSecondaryHandItem() and playerObj:getSecondaryHandItem() ~= playerObj:getPrimaryHandItem() then
            ISTimedActionQueue.add(ISUnequipAction:new(playerObj, playerObj:getSecondaryHandItem(), 50));
        end
        ISTimedActionQueue.add(ISTakeTrolley:new(playerObj, item, 50))
    end
end

-- ISInventoryPaneContextMenu.equipHeavyItem = function(playerObj, item)
--     if not luautils.walkToContainer(item:getContainer(), playerObj:getPlayerNum()) then
--         return
--     end
--     if playerObj:getPrimaryHandItem() then
--         ISTimedActionQueue.add(ISUnequipAction:new(playerObj, playerObj:getPrimaryHandItem(), 50));
--     end
--     if playerObj:getSecondaryHandItem() and playerObj:getSecondaryHandItem() ~= playerObj:getPrimaryHandItem() then
--         ISTimedActionQueue.add(ISUnequipAction:new(playerObj, playerObj:getSecondaryHandItem(), 50));
--     end
--     ISTimedActionQueue.add(ISEquipHeavyItem:new(playerObj, item, 100));
-- end


-- Trolley.onUnequipTrolley = function (playerNum, item)
--     ISInventoryPaneContextMenu.dropItem(item, playerNum)
-- end


-- Trolley.onGrabTrolleyToGround = function (playerNum, item)
--     ISInventoryPaneContextMenu.dropItem(item, playerNum)
-- end


Trolley.doFillWorldObjectContextMenu = function (playerNum, context, worldobjects, test)
    local playerObj = getSpecificPlayer(playerNum)
    local item = playerObj:getPrimaryHandItem()

    -- Trolly Item has tag `HeavyItem`, native will take care many things.

    if item and item:hasTag('Trolley') then
        -- NO NEED this, `HeavyItem` already creat one option by Vanilla.
        -- context:addOptionOnTop(getText("ContextMenu_DROP_CART"), playerNum, Trolley.onUnequipTrolley, item)
        return
    else
        local worldObjTable = Trolley.parseWorldObjects(worldobjects, playerNum)
        if #worldObjTable == 0 then return false end

        for _, obj in ipairs(worldObjTable) do
            local item = obj:getItem() -- obj is worldItem
            if item and item:hasTag('Trolley') then
                local old_option = context:getOptionFromName(getText("ContextMenu_Grab"))
                if old_option then
                    context:removeOptionByName(old_option.name)
                    context:addOptionOnTop(getText("ContextMenu_TAKE_CART"), playerNum, Trolley.onEquipTrolley, item)
                    return
                end 
            end
        end
    end
end


Trolley.doInventoryContextMenu = function (playerNum, context, items)
    local playerObj = getSpecificPlayer(playerNum)
    local items = ISInventoryPane.getActualItems(items)

    -- Trolly Item has tag `HeavyItem`, native will take care many things.

    for _, item in ipairs(items) do
        if item and item:hasTag('Trolley') then
            context:removeOptionByName(getText("ContextMenu_Equip_Two_Hands"))
            context:removeOptionByName(getText("ContextMenu_Unequip"))

            if playerObj:isHandItem(item) then
                -- use native `Drop` is good enough.
            else
                -- local old_option = context:getOptionFromName(getText("ContextMenu_Grab"))
                -- NO Need this, `HeavyItem` don't have `Grab` option in Inventory.
                -- context:removeOptionByName(old_option.name)
                context:addOptionOnTop(getText("ContextMenu_TAKE_CART"), playerNum, Trolley.onEquipTrolley, item)
                return
            end
        end
    end
end

Events.OnPlayerUpdate.Add(Trolley.onTrolleyUpdate)
Events.OnEnterVehicle.Add(Trolley.onEnterVehicle)

Events.OnFillInventoryObjectContextMenu.Add(Trolley.doInventoryContextMenu)
Events.OnFillWorldObjectContextMenu.Add(Trolley.doFillWorldObjectContextMenu)
