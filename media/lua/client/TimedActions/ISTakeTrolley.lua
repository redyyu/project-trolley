--***********************************************************
--**                    ROBERT JOHNSON                     **
--***********************************************************

require "TimedActions/ISBaseTimedAction"

ISTakeTrolley = ISBaseTimedAction:derive("ISTakeTrolley");

function ISTakeTrolley:isValid()
	-- Check that the item wasn't picked up by a preceding action
	if self.item == nil or self.item:getSquare() == nil then return false end
	-- no need check player has trolley in inventory here,
	-- multiple trolly will drop anyway, from `onTrolleyTick`.
	return true
end

function ISTakeTrolley:update()
	self.item:getItem():setJobDelta(self:getJobDelta());
end

function ISTakeTrolley:start()
	self:setActionAnim("Loot");
	self:setAnimVariable("LootPosition", "Medium");
	self:setOverrideHandModels(nil, nil);
	self.item:getItem():setJobType(getText("ContextMenu_Grab"));
	self.item:getItem():setJobDelta(0.0);
end

function ISTakeTrolley:stop()
    ISBaseTimedAction.stop(self);
    self.item:getItem():setJobDelta(0.0);
end

function ISTakeTrolley:perform()
	-- forceDropHeavyItems(self.character)
	-- from TimedActions/ISEquipWeaponAction.lua 
	-- it is for drop Corps and Generator or any other item hasTag `HeavyItem` when using weapons.
	local inventoryItem = self.item:getItem()
	self.item:getSquare():transmitRemoveItemFromSquare(self.item);
	self.item:removeFromWorld()
	self.item:removeFromSquare()
	self.item:setSquare(nil)
	inventoryItem:setWorldItem(nil)
	inventoryItem:setJobDelta(0.0);
	self.character:getInventory():setDrawDirty(true);
	self.character:getInventory():AddItem(inventoryItem);
	self.action:stopTimedActionAnim();
	self.action:setLoopedAction(false);
	self.character:setPrimaryHandItem(self.item:getItem());
	self.character:setSecondaryHandItem(self.item:getItem());
	local pdata = getPlayerData(self.character:getPlayerNum());
	if pdata ~= nil then
		pdata.playerInventory:refreshBackpacks();
		pdata.lootInventory:refreshBackpacks();
	end
	-- needed to remove from queue / start next.
	ISBaseTimedAction.perform(self);

end

function ISTakeTrolley:new (character, item, time)
	local o = {}
	setmetatable(o, self)
	self.__index = self
	o.character = character
	o.item = item
	o.stopOnWalk = true
	o.stopOnRun = true	   
	o.maxTime = time
	o.loopedAction = false
	return o
end
