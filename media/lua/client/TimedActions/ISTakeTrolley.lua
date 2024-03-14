--***********************************************************
--**                    ROBERT JOHNSON                     **
--***********************************************************

require "TimedActions/ISBaseTimedAction"
require "TimedActions/ISEquipWeaponAction.lua "

ISTakeTrolley = ISBaseTimedAction:derive("ISTakeTrolley");

function ISTakeTrolley:isValid()
	-- Check that the item wasn't picked up by a preceding action
	if self.item == nil then return false end
	-- no need check player has trolley in inventory here,
	-- multiple trolly will drop anyway, from `onTrolleyTick`.
	return true
end

function ISTakeTrolley:update()
	self.item:setJobDelta(self:getJobDelta())
end

function ISTakeTrolley:start()
	self:setActionAnim("Loot")
	self:setAnimVariable("LootPosition", "Medium")
	self:setOverrideHandModels(nil, nil)
	self.item:setJobType(getText("ContextMenu_Grab"))
	self.item:setJobDelta(0.0)
end

function ISTakeTrolley:stop()
    ISBaseTimedAction.stop(self)
    self.item:setJobDelta(0.0)
end

function ISTakeTrolley:perform()
	forceDropHeavyItems(self.character)
	-- from TimedActions/ISEquipWeaponAction.lua 
	-- it is for drop Corps and Generator or any other item hasTag `HeavyItem` when using weapons.
	if self.worldItem and self.worldItem:getSquare() then
		self.worldItem:getSquare():transmitRemoveItemFromSquare(self.worldItem)
		self.worldItem:removeFromWorld()
		self.worldItem:removeFromSquare()
		self.worldItem:setSquare(nil)
	end
	self.item:setWorldItem(nil)
	self.item:setJobDelta(0.0)
	self.character:getInventory():setDrawDirty(true)
	self.character:getInventory():AddItem(self.item)
	self.action:stopTimedActionAnim()
	self.action:setLoopedAction(false)
	self.character:setPrimaryHandItem(self.item)
	self.character:setSecondaryHandItem(self.item)

	local pdata = getPlayerData(self.character:getPlayerNum())
	if pdata ~= nil then
		pdata.playerInventory:refreshBackpacks()
		pdata.lootInventory:refreshBackpacks()
	end
	-- needed to remove from queue / start next.
	ISBaseTimedAction.perform(self)

end

function ISTakeTrolley:new (character, item, time)
	local o = {}
	setmetatable(o, self)
	self.__index = self
	o.character = character
	o.item = item
	o.worldItem = item:getWorldItem()
	o.stopOnWalk = true
	o.stopOnRun = true	   
	o.maxTime = time
	o.loopedAction = false
	return o
end
