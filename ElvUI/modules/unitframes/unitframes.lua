local E, L, V, P, G = unpack(select(2, ...)); --Inport: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local UF = E:NewModule('UnitFrames', 'AceTimer-3.0', 'AceEvent-3.0', 'AceHook-3.0');
local LSM = LibStub("LibSharedMedia-3.0");
UF.LSM = LSM

local _, ns = ...
local ElvUF = ns.oUF
local AceTimer = LibStub:GetLibrary("AceTimer-3.0")
assert(ElvUF, "ElvUI was unable to locate oUF.")

local opposites = {
	['DEBUFFS'] = 'BUFFS',
	['BUFFS'] = 'DEBUFFS'
}

local removeMenuOptions = {
	["SET_FOCUS"] = true,
	["CLEAR_FOCUS"] = true,
	["MOVE_FOCUS_FRAME"] = true,
	["LARGE_FOCUS"] = true,	
	["MOVE_PLAYER_FRAME"] = true,
	["MOVE_TARGET_FRAME"] = true,
	["PVP_REPORT_AFK"] = true,
	["PET_DISMISS"] = E.myclass == 'HUNTER',
}

UF['headerstoload'] = {}
UF['unitgroupstoload'] = {}
UF['unitstoload'] = {}

UF['headers'] = {}
UF['groupunits'] = {}
UF['units'] = {}

UF['statusbars'] = {}
UF['fontstrings'] = {}
UF['badHeaderPoints'] = {
	['TOP'] = 'BOTTOM',
	['LEFT'] = 'RIGHT',
	['BOTTOM'] = 'TOP',
	['RIGHT'] = 'LEFT',
}

UF['classMaxResourceBar'] = {
	['DEATHKNIGHT'] = 6,
	['PALADIN'] = 5,
	['WARLOCK'] = 4,
	['PRIEST'] = 3,
	['MONK'] = 5,
	['MAGE'] = 4,
}

UF['headerGroupBy'] = {
	['CLASS'] = function(header)
		header:SetAttribute("groupingOrder", "DEATHKNIGHT,DRUID,HUNTER,MAGE,PALADIN,PRIEST,SHAMAN,WARLOCK,WARRIOR")
		header:SetAttribute('sortMethod', 'NAME')
		header:SetAttribute("groupBy", 'CLASS')
	end,
	['MTMA'] = function(header)
		header:SetAttribute("groupingOrder", "MAINTANK,MAINASSIST,NONE")
		header:SetAttribute('sortMethod', 'NAME')
		header:SetAttribute("groupBy", 'ROLE')
	end,
	['ROLE'] = function(header)
		header:SetAttribute("groupingOrder", "TANK,HEALER,DAMAGER,NONE")
		header:SetAttribute('sortMethod', 'NAME')
		header:SetAttribute("groupBy", 'ASSIGNEDROLE')
	end,
	['NAME'] = function(header)
		header:SetAttribute("groupingOrder", "1,2,3,4,5,6,7,8")
		header:SetAttribute('sortMethod', 'NAME')
		header:SetAttribute("groupBy", 'GROUP')
	end,
	['NAME_ENTIRE_GROUP'] = function(header)
		header:SetAttribute("groupingOrder", "1,2,3,4,5,6,7,8")
		header:SetAttribute('sortMethod', 'NAME')
		header:SetAttribute("groupBy", nil)
	end, 
	['GROUP'] = function(header)
		header:SetAttribute("groupingOrder", "1,2,3,4,5,6,7,8")
		header:SetAttribute('sortMethod', 'INDEX')
		header:SetAttribute("groupBy", 'GROUP')
	end,
}

local POINT_COLUMN_ANCHOR_TO_DIRECTION = {
	['TOPTOP'] = 'UP_RIGHT',
	['BOTTOMBOTTOM'] = 'TOP_RIGHT',
	['LEFTLEFT'] = 'RIGHT_UP',
	['RIGHTRIGHT'] = 'LEFT_UP',
	['RIGHTTOP'] = 'LEFT_DOWN',
	['LEFTTOP'] = 'RIGHT_DOWN',
	['LEFTBOTTOM'] = 'RIGHT_UP',
	['RIGHTBOTTOM'] = 'LEFT_UP',
	['BOTTOMRIGHT'] = 'UP_LEFT',
	['BOTTOMLEFT'] = 'UP_RIGHT',
	['TOPRIGHT'] = 'DOWN_LEFT',
	['TOPLEFT'] = 'DOWN_RIGHT'
}

local DIRECTION_TO_POINT = {
	DOWN_RIGHT = "TOP",
	DOWN_LEFT = "TOP",
	UP_RIGHT = "BOTTOM",
	UP_LEFT = "BOTTOM",
	RIGHT_DOWN = "LEFT",
	RIGHT_UP = "LEFT",
	LEFT_DOWN = "RIGHT",
	LEFT_UP = "RIGHT"
}


local DIRECTION_TO_GROUP_ANCHOR_POINT = {
	OUT_RIGHT_UP = "BOTTOM",
	OUT_LEFT_UP = "BOTTOM",
	OUT_RIGHT_DOWN = "TOP",
	OUT_LEFT_DOWN = "TOP",
	OUT_UP_RIGHT = "LEFT",
	OUT_UP_LEFT = "RIGHT",
	OUT_DOWN_RIGHT = "LEFT",
	OUT_DOWN_LEFT = "RIGHT",
	DOWN_RIGHT = "TOPLEFT",
	DOWN_LEFT = "TOPRIGHT",
	UP_RIGHT = "BOTTOMLEFT",
	UP_LEFT = "BOTTOMRIGHT",
	RIGHT_DOWN = "TOPLEFT",
	RIGHT_UP = "BOTTOMLEFT",
	LEFT_DOWN = "TOPRIGHT",
	LEFT_UP = "BOTTOMRIGHT"
}

local DIRECTION_TO_COLUMN_ANCHOR_POINT = {
	DOWN_RIGHT = "LEFT",
	DOWN_LEFT = "RIGHT",
	UP_RIGHT = "LEFT",
	UP_LEFT = "RIGHT",
	RIGHT_DOWN = "TOP",
	RIGHT_UP = "BOTTOM",
	LEFT_DOWN = "TOP",
	LEFT_UP = "BOTTOM"
}

local INVERTED_DIRECTION_TO_COLUMN_ANCHOR_POINT = {
	DOWN_RIGHT = "RIGHT",
	DOWN_LEFT = "LEFT",
	UP_RIGHT = "RIGHT",
	UP_LEFT = "LEFT",
	RIGHT_DOWN = "BOTTOM",
	RIGHT_UP = "TOP",
	LEFT_DOWN = "BOTTOM",
	LEFT_UP = "TOP"	
}

local DIRECTION_TO_HORIZONTAL_SPACING_MULTIPLIER = {
	DOWN_RIGHT = 1,
	DOWN_LEFT = -1,
	UP_RIGHT = 1,
	UP_LEFT = -1,
	RIGHT_DOWN = 1,
	RIGHT_UP = 1,
	LEFT_DOWN = -1,
	LEFT_UP = -1
}

local DIRECTION_TO_VERTICAL_SPACING_MULTIPLIER = {
	DOWN_RIGHT = -1,
	DOWN_LEFT = -1,
	UP_RIGHT = 1,
	UP_LEFT = 1,
	RIGHT_DOWN = -1,
	RIGHT_UP = 1,
	LEFT_DOWN = -1,
	LEFT_UP = 1
}

local find, gsub, split, format = string.find, string.gsub, string.split, string.format
local min, abs = math.min, math.abs
local tremove, tinsert = table.remove, table.insert


function UF:ConvertGroupDB(group)
	local db = self.db.units[group.groupName]
	if db.point and db.columnAnchorPoint then
		db.growthDirection = POINT_COLUMN_ANCHOR_TO_DIRECTION[db.point..db.columnAnchorPoint];
		db.point = nil;
		db.columnAnchorPoint = nil;
	end
	
	if db.xOffset then
		db.horizontalSpacing = abs(db.xOffset);
		db.xOffset = nil;
	end
	
	if db.yOffset then
		db.verticalSpacing = abs(db.yOffset);
		db.yOffset = nil;
	end
	
	if db.maxColumns then
		db.numGroups = db.maxColumns;
		db.maxColumns = nil;
	end
	
	if db.unitsPerColumn then
		db.unitsPerGroup = db.unitsPerColumn;
		db.unitsPerColumn = nil;
	end
end

local function DelayedUpdate(group)
	if InCombatLockdown() then return end
	group:Show()
end

function UF:SetupGroupAnchorPoints(group)
	UF:ConvertGroupDB(group)
	local db = self.db.units[group.groupName]
	local direction = db.growthDirection
	local point = DIRECTION_TO_POINT[direction]
	local positionOverride = DIRECTION_TO_GROUP_ANCHOR_POINT[db.startOutFromCenter and 'OUT_'..direction or direction]
	
	local maxUnits, startingIndex = MAX_RAID_MEMBERS, -1
	if (db.numGroups and db.unitsPerGroup) then
		startingIndex = -min(db.numGroups * db.unitsPerGroup, maxUnits) + 1
	end
	
	if point == "LEFT" or point == "RIGHT" then
		group:SetAttribute("xOffset", db.horizontalSpacing * DIRECTION_TO_HORIZONTAL_SPACING_MULTIPLIER[direction])
		group:SetAttribute("yOffset", 0)
		group:SetAttribute("columnSpacing", db.verticalSpacing)
	else
		group:SetAttribute("xOffset", 0)
		group:SetAttribute("yOffset", db.verticalSpacing * DIRECTION_TO_VERTICAL_SPACING_MULTIPLIER[direction])
		group:SetAttribute("columnSpacing", db.horizontalSpacing)
	end
	
	group:SetAttribute("columnAnchorPoint", db.invertGroupingOrder and INVERTED_DIRECTION_TO_COLUMN_ANCHOR_POINT[direction] or DIRECTION_TO_COLUMN_ANCHOR_POINT[direction])
	UF:ClearChildPoints(group:GetChildren())
	group:SetAttribute("point", point)	
	group:SetAttribute("maxColumns", db.numGroups)
	group:SetAttribute("unitsPerColumn", db.unitsPerGroup)		

	if not group.isForced then
		group:SetAttribute("startingIndex", startingIndex)
		RegisterAttributeDriver(group, 'state-visibility', 'show')	
		group.dirtyWidth, group.dirtyHeight = group:GetSize()
		RegisterAttributeDriver(group, 'state-visibility', db.visibility)
		group:SetAttribute('startingIndex', 1)
		
		E:Delay(0.25, DelayedUpdate, group)
	end
	
	if group.mover then
		group.mover.positionOverride = positionOverride
		E:UpdatePositionOverride(group.mover:GetName())
	end

	return positionOverride
end

function UF:Construct_UF(frame, unit)
	frame:SetScript('OnEnter', UnitFrame_OnEnter)
	frame:SetScript('OnLeave', UnitFrame_OnLeave)	
	
	frame.menu = self.SpawnMenu
	
	frame:SetFrameLevel(5)
	
	frame.RaisedElementParent = CreateFrame('Frame', nil, frame)
	frame.RaisedElementParent:SetFrameStrata("MEDIUM")
	frame.RaisedElementParent:SetFrameLevel(frame:GetFrameLevel() + 10)	
	
	if not self['groupunits'][unit] then
		local stringTitle = E:StringTitle(unit)
		if stringTitle:find('target') then
			stringTitle = gsub(stringTitle, 'target', 'Target')
		end
		self["Construct_"..stringTitle.."Frame"](self, frame, unit)
	else
		UF["Construct_"..E:StringTitle(self['groupunits'][unit]).."Frames"](self, frame, unit)
	end
	
	self:Update_StatusBars()
	self:Update_FontStrings()	
	return frame
end

function UF:GetPositionOffset(position, offset)
	if not offset then offset = 2; end
	local x, y = 0, 0
	if find(position, 'LEFT') then
		x = offset
	elseif find(position, 'RIGHT') then
		x = -offset
	end					
	
	if find(position, 'TOP') then
		y = -offset
	elseif find(position, 'BOTTOM') then
		y = offset
	end
	
	return x, y
end

function UF:GetAuraOffset(p1, p2)
	local x, y = 0, 0
	if p1 == "RIGHT" and p2 == "LEFT" then
		x = -3
	elseif p1 == "LEFT" and p2 == "RIGHT" then
		x = 3
	end
	
	if find(p1, 'TOP') and find(p2, 'BOTTOM') then
		y = -1
	elseif find(p1, 'BOTTOM') and find(p2, 'TOP') then
		y = 1
	end
	
	return E:Scale(x), E:Scale(y)
end

function UF:GetAuraAnchorFrame(frame, attachTo, isConflict)
	if isConflict then
		E:Print(format(L['%s frame(s) has a conflicting anchor point, please change either the buff or debuff anchor point so they are not attached to each other. Forcing the debuffs to be attached to the main unitframe until fixed.'], E:StringTitle(frame:GetName())))
	end
	
	if isConflict or attachTo == 'FRAME' then
		return frame
	elseif attachTo == 'TRINKET' then
		if select(2, IsInInstance()) == "arena" then
			return frame.Trinket
		else
			return frame.PVPSpecIcon
		end	
	elseif attachTo == 'BUFFS' then
		return frame.Buffs
	elseif attachTo == 'DEBUFFS' then
		return frame.Debuffs
	else
		return frame
	end
end

function UF:ClearChildPoints(...)
	for i=1, select("#", ...) do
		local child = select(i, ...)
		child:ClearAllPoints()
	end
end

function UF:UpdateColors()
	local db = self.db.colors

	local good = E:GetColorTable(db.reaction.GOOD)
	local bad = E:GetColorTable(db.reaction.BAD)
	local neutral = E:GetColorTable(db.reaction.NEUTRAL)
	
	ElvUF.colors.tapped = E:GetColorTable(db.tapped);
	ElvUF.colors.disconnected = E:GetColorTable(db.disconnected);
	ElvUF.colors.health = E:GetColorTable(db.health);
	ElvUF.colors.power.MANA = E:GetColorTable(db.power.MANA);
	ElvUF.colors.power.RAGE = E:GetColorTable(db.power.RAGE);
	ElvUF.colors.power.FOCUS = E:GetColorTable(db.power.FOCUS);
	ElvUF.colors.power.ENERGY = E:GetColorTable(db.power.ENERGY);
	ElvUF.colors.power.RUNIC_POWER = E:GetColorTable(db.power.RUNIC_POWER);
	
	ElvUF.colors.runes = {}
	ElvUF.colors.runes[1] = E:GetColorTable(db.classResources.DEATHKNIGHT[1])
	ElvUF.colors.runes[2] = E:GetColorTable(db.classResources.DEATHKNIGHT[2])
	ElvUF.colors.runes[3] = E:GetColorTable(db.classResources.DEATHKNIGHT[3])
	ElvUF.colors.runes[4] = E:GetColorTable(db.classResources.DEATHKNIGHT[4])
	
	ElvUF.colors.holyPower = E:GetColorTable(db.classResources.PALADIN);
	
	ElvUF.colors.arcaneCharges = E:GetColorTable(db.classResources.MAGE);
	
	ElvUF.colors.shadowOrbs = E:GetColorTable(db.classResources.PRIEST);
	
	ElvUF.colors.eclipseBar = {}
	ElvUF.colors.eclipseBar[1] = E:GetColorTable(db.classResources.DRUID[1])
	ElvUF.colors.eclipseBar[2] = E:GetColorTable(db.classResources.DRUID[2])
	
	ElvUF.colors.harmony = {}
	ElvUF.colors.harmony[1] = E:GetColorTable(db.classResources.MONK[1])
	ElvUF.colors.harmony[2] = E:GetColorTable(db.classResources.MONK[2])
	ElvUF.colors.harmony[3] = E:GetColorTable(db.classResources.MONK[3])
	ElvUF.colors.harmony[4] = E:GetColorTable(db.classResources.MONK[4])
	ElvUF.colors.harmony[5] = E:GetColorTable(db.classResources.MONK[5])
	
	ElvUF.colors.WarlockResource = {}
	ElvUF.colors.WarlockResource[1] = E:GetColorTable(db.classResources.WARLOCK[1])
	ElvUF.colors.WarlockResource[2] = E:GetColorTable(db.classResources.WARLOCK[2])
	ElvUF.colors.WarlockResource[3] = E:GetColorTable(db.classResources.WARLOCK[3])
	
	ElvUF.colors.reaction[1] = bad
	ElvUF.colors.reaction[2] = bad
	ElvUF.colors.reaction[3] = bad
	ElvUF.colors.reaction[4] = neutral
	ElvUF.colors.reaction[5] = good
	ElvUF.colors.reaction[6] = good
	ElvUF.colors.reaction[7] = good
	ElvUF.colors.reaction[8] = good
	ElvUF.colors.smooth = {1, 0, 0,
	1, 1, 0,
	unpack(E:GetColorTable(db.health))}
	
	ElvUF.colors.castColor = E:GetColorTable(db.castColor);
	ElvUF.colors.castNoInterrupt = E:GetColorTable(db.castNoInterrupt);
end

function UF:Update_StatusBars()
	local statusBarTexture = LSM:Fetch("statusbar", self.db.statusbar)
	for statusbar in pairs(UF['statusbars']) do
		if statusbar and statusbar:GetObjectType() == 'StatusBar' and not statusbar.isTransparent then
			statusbar:SetStatusBarTexture(statusBarTexture)
		elseif statusBar and statusbar:GetObjectType() == 'Texture' then
			statusbar:SetTexture(statusBarTexture)
		end
	end
end

function UF:Update_StatusBar(bar)
	bar:SetStatusBarTexture(LSM:Fetch("statusbar", self.db.statusbar))
end

function UF:Update_FontString(object)
	object:FontTemplate(LSM:Fetch("font", self.db.font), self.db.fontSize, self.db.fontOutline)
end

function UF:Update_FontStrings()
	local stringFont = LSM:Fetch("font", self.db.font)
	for font in pairs(UF['fontstrings']) do
		font:FontTemplate(stringFont, self.db.fontSize, self.db.fontOutline)
	end
end

function UF:Configure_FontString(obj)
	UF['fontstrings'][obj] = true
	obj:FontTemplate() --This is temporary.
end

function UF:Update_AllFrames()
	if InCombatLockdown() then self:RegisterEvent('PLAYER_REGEN_ENABLED'); return end
	if E.private["unitframe"].enable ~= true then return; end
	self:UpdateColors()
	self:Update_FontStrings()
	self:Update_StatusBars()	
	
	for unit in pairs(self['units']) do
		if self.db['units'][unit].enable then
			self[unit]:Enable()
			self[unit]:Update()
		else
			self[unit]:Disable()
		end
	end

	for unit, group in pairs(self['groupunits']) do
		if self.db['units'][group].enable then
			self[unit]:Enable()
			self[unit]:Update()
		else
			self[unit]:Disable()
		end
	end	
	
	self:UpdateAllHeaders()
end

function UF:CreateAndUpdateUFGroup(group, numGroup)
	if InCombatLockdown() then self:RegisterEvent('PLAYER_REGEN_ENABLED'); return end

	for i=1, numGroup do
		local unit = group..i
		local frameName = E:StringTitle(unit)
		frameName = frameName:gsub('t(arget)', 'T%1')		
		if not self[unit] then
			self['groupunits'][unit] = group;	
			self[unit] = ElvUF:Spawn(unit, 'ElvUF_'..frameName)
			self[unit].index = i
			self[unit]:SetParent(ElvUF_Parent)
			self[unit]:SetID(i)
		end
		
		local frameName = E:StringTitle(group)
		frameName = frameName:gsub('t(arget)', 'T%1')		
		self[unit].Update = function()
			UF["Update_"..E:StringTitle(frameName).."Frames"](self, self[unit], self.db['units'][group])	
		end
		
		if self.db['units'][group].enable then
			self[unit]:Enable()
			self[unit].Update()
			
			if self[unit].isForced then
				self:ForceShow(self[unit])		
			end
		else
			self[unit]:Disable()
		end
	end
end

function UF:HeaderUpdateSpecificElement(group, elementName)
	assert(self[group], "Invalid group specified.")
	for i=1, self[group]:GetNumChildren() do
		local frame = select(i, self[group]:GetChildren())
		if frame and frame.Health then
			frame:UpdateElement(elementName)
		end
	end
end

function UF:CreateAndUpdateHeaderGroup(group, groupFilter, template, headerUpdate)
	if InCombatLockdown() then self:RegisterEvent('PLAYER_REGEN_ENABLED'); return end

	local db = self.db['units'][group]
	if not self[group] then
		ElvUF:RegisterStyle("ElvUF_"..E:StringTitle(group), UF["Construct_"..E:StringTitle(group).."Frames"])
		ElvUF:SetActiveStyle("ElvUF_"..E:StringTitle(group))

		self[group] = ElvUF:SpawnHeader("ElvUF_"..E:StringTitle(group), nil, nil, 
			'oUF-initialConfigFunction', ([[self:SetWidth(%d); self:SetHeight(%d); self:SetFrameLevel(5)]]):format(db.width, db.height), 
			'groupFilter', groupFilter,
			'showParty', true,
			'showRaid', true,
			'showSolo', true,
			template and 'template', template)

		self[group]:SetParent(ElvUF_Parent)		
		self['headers'][group] = self[group]
		self[group].groupName = group
	end
	
	self[group].db = db
	
	self[group].Update = function()
		local db = self.db['units'][group]
		if db.enable ~= true then 
			RegisterAttributeDriver(self[group], 'state-visibility', 'hide')	
			return
		end
		UF["Update_"..E:StringTitle(group).."Header"](self, self[group], db)
		
		for i=1, self[group]:GetNumChildren() do
			local child = select(i, self[group]:GetChildren())
			UF["Update_"..E:StringTitle(group).."Frames"](self, child, self.db['units'][group])

			if _G[child:GetName()..'Pet'] then
				UF["Update_"..E:StringTitle(group).."Frames"](self, _G[child:GetName()..'Pet'], self.db['units'][group])
			end
			
			if _G[child:GetName()..'Target'] then
				UF["Update_"..E:StringTitle(group).."Frames"](self, _G[child:GetName()..'Target'], self.db['units'][group])
			end			
		end			
	end	
	
	if headerUpdate then
		UF["Update_"..E:StringTitle(group).."Header"](self, self[group], db)
	else
		self[group].Update()
	end
end

function UF:PLAYER_REGEN_ENABLED()
	self:Update_AllFrames()
	self:UnregisterEvent('PLAYER_REGEN_ENABLED')
end

function UF:CreateAndUpdateUF(unit)
	assert(unit, 'No unit provided to create or update.')
	if InCombatLockdown() then self:RegisterEvent('PLAYER_REGEN_ENABLED'); return end

	local frameName = E:StringTitle(unit)
	frameName = frameName:gsub('t(arget)', 'T%1')
	if not self[unit] then
		self[unit] = ElvUF:Spawn(unit, 'ElvUF_'..frameName)
		self['units'][unit] = unit
	end

	self[unit].Update = function()
		UF["Update_"..frameName.."Frame"](self, self[unit], self.db['units'][unit])
	end

	if self.db['units'][unit].enable then
		self[unit]:Enable()
		self[unit].Update()
	else
		self[unit]:Disable()
	end
	
	if self[unit]:GetParent() ~= ElvUF_Parent then
		self[unit]:SetParent(ElvUF_Parent)
	end
end


function UF:LoadUnits()
	for _, unit in pairs(self['unitstoload']) do
		self:CreateAndUpdateUF(unit)
	end	
	self['unitstoload'] = nil
	
	for group, numGroup in pairs(self['unitgroupstoload']) do
		self:CreateAndUpdateUFGroup(group, numGroup)
	end
	self['unitgroupstoload'] = nil
	
	for group, groupOptions in pairs(self['headerstoload']) do
		local groupFilter, template
		if type(groupOptions) == 'table' then
			groupFilter, template = unpack(groupOptions)
		end

		self:CreateAndUpdateHeaderGroup(group, groupFilter, template)
	end
	self['headerstoload'] = nil
end

function UF:UpdateAllHeaders(event)	
	if InCombatLockdown() then
		self:RegisterEvent('PLAYER_REGEN_ENABLED', 'UpdateAllHeaders')
		return
	end
	
	if event == 'PLAYER_REGEN_ENABLED' then
		self:UnregisterEvent('PLAYER_REGEN_ENABLED')
	end
		
	local _, instanceType = IsInInstance();
	local ORD = ns.oUF_RaidDebuffs or oUF_RaidDebuffs
	if ORD then
		ORD:ResetDebuffData()
		
		if instanceType == "party" or instanceType == "raid" then
			ORD:RegisterDebuffs(E.global.unitframe.aurafilters.RaidDebuffs.spells)
		else
			ORD:RegisterDebuffs(E.global.unitframe.aurafilters.CCDebuffs.spells)
		end
	end	
	
	for _, header in pairs(UF['headers']) do
		header:Update()
	end	
	
	if E.private.unitframe.disableBlizzard then
		ElvUF:DisableBlizzard('party')	
	end
end

function HideRaid()
	if InCombatLockdown() then return end
	CompactRaidFrameManager:Kill()
	local compact_raid = CompactRaidFrameManager_GetSetting("IsShown")
	if compact_raid and compact_raid ~= "0" then 
		CompactRaidFrameManager_SetSetting("IsShown", "0")
	end
end

function UF:DisableBlizzard(event)
	hooksecurefunc("CompactRaidFrameManager_UpdateShown", HideRaid)
	CompactRaidFrameManager:HookScript('OnShow', HideRaid)
	CompactRaidFrameContainer:UnregisterAllEvents()
	
	HideRaid()
	hooksecurefunc("CompactUnitFrame_RegisterEvents", CompactUnitFrame_UnregisterEvents)
end

local hiddenParent = CreateFrame("Frame")
hiddenParent:Hide()

local HandleFrame = function(baseName)
	local frame
	if(type(baseName) == 'string') then
		frame = _G[baseName]
	else
		frame = baseName
	end

	if(frame) then
		frame:UnregisterAllEvents()
		frame:Hide()

		-- Keep frame hidden without causing taint
		frame:SetParent(hiddenParent)

		local health = frame.healthbar
		if(health) then
			health:UnregisterAllEvents()
		end

		local power = frame.manabar
		if(power) then
			power:UnregisterAllEvents()
		end

		local spell = frame.spellbar
		if(spell) then
			spell:UnregisterAllEvents()
		end

		local altpowerbar = frame.powerBarAlt
		if(altpowerbar) then
			altpowerbar:UnregisterAllEvents()
		end
	end
end

function ElvUF:DisableBlizzard(unit)
	if(not unit) or InCombatLockdown() then return end

	if(unit == 'player') then
		HandleFrame(PlayerFrame)

		-- For the damn vehicle support:
		PlayerFrame:RegisterUnitEvent('UNIT_ENTERING_VEHICLE', "player")
		PlayerFrame:RegisterUnitEvent('UNIT_ENTERED_VEHICLE', "player")
		PlayerFrame:RegisterUnitEvent('UNIT_EXITING_VEHICLE', "player")
		PlayerFrame:RegisterUnitEvent('UNIT_EXITED_VEHICLE', "player")
		PlayerFrame:RegisterEvent('PLAYER_ENTERING_WORLD')
		
		-- User placed frames don't animate
		PlayerFrame:SetUserPlaced(true)
		PlayerFrame:SetDontSavePosition(true)
	elseif(unit == 'pet') then
		HandleFrame(PetFrame)
	elseif(unit == 'target') then
		HandleFrame(TargetFrame)
		HandleFrame(ComboFrame)
	elseif(unit == 'focus') then
		HandleFrame(FocusFrame)
		HandleFrame(TargetofFocusFrame)
	elseif(unit == 'targettarget') then
		HandleFrame(TargetFrameToT)
	elseif(unit:match'(boss)%d?$' == 'boss') then
		local id = unit:match'boss(%d)'
		if(id) then
			HandleFrame('Boss' .. id .. 'TargetFrame')
		else
			for i=1, 4 do
				HandleFrame(('Boss%dTargetFrame'):format(i))
			end
		end
	elseif(unit:match'(party)%d?$' == 'party') then
		local id = unit:match'party(%d)'
		if(id) then
			HandleFrame('PartyMemberFrame' .. id)
		else
			for i=1, 4 do
				HandleFrame(('PartyMemberFrame%d'):format(i))
			end
		end
	elseif(unit:match'(arena)%d?$' == 'arena') then
		local id = unit:match'arena(%d)'

		if(id) then
			HandleFrame('ArenaEnemyFrame' .. id)
			HandleFrame('ArenaPrepFrame'..id)
			HandleFrame('ArenaEnemyFrame'..id..'PetFrame')
		else
			for i=1, 5 do
				HandleFrame(('ArenaEnemyFrame%d'):format(i))
				HandleFrame(('ArenaPrepFrame%d'):format(i))
				HandleFrame(('ArenaEnemyFrame%dPetFrame'):format(i))
			end
		end
	end
end

function UF:ADDON_LOADED(event, addon)
	if addon ~= 'Blizzard_ArenaUI' then return; end
	ElvUF:DisableBlizzard('arena')
	self:UnregisterEvent("ADDON_LOADED");
end

function UF:PLAYER_ENTERING_WORLD(event)
	self:Update_AllFrames()
end

function UF:UnitFrameThreatIndicator_Initialize(_, unitFrame)
	unitFrame:UnregisterAllEvents() --Arena Taint Fix
end

function UF:RemoveDismissPet()
	--This *should* make it so if you are in the Kara Event you can still use the dismiss pet from right click menu
	--Otherwise hunters need to use the spell Dismiss Pet
	if not PetCanBeAbandoned() then
		if UnitPopupMenus["PET"][4] ~= "PET_DISMISS" then
			tinsert(UnitPopupMenus["PET"], 4, "PET_DISMISS")
		end		
	else
		if UnitPopupMenus["PET"][4] == "PET_DISMISS" then
			tremove(UnitPopupMenus["PET"], 4)
		end		
	end
end

CompactUnitFrameProfiles:UnregisterEvent('VARIABLES_LOADED') 	--Re-Register this event only if disableblizzard is turned off.
function UF:Initialize()	
	self.db = E.db["unitframe"]
	
	CompactUnitFrameProfiles:RegisterEvent('VARIABLES_LOADED')
	if E.private["unitframe"].enable ~= true then return; end
	E.UnitFrames = UF;
	
	local ElvUF_Parent = CreateFrame('Frame', 'ElvUF_Parent', E.UIParent, 'SecureHandlerStateTemplate');
	ElvUF_Parent:SetAllPoints(E.UIParent)
	ElvUF_Parent:SetAttribute("_onstate-show", [[		
		if newstate == "hide" then
			self:Hide();
		else
			self:Show();
		end	
	]]);

	RegisterStateDriver(ElvUF_Parent, "show", '[petbattle] hide;show');	
	
	self:UpdateColors()
	ElvUF:RegisterStyle('ElvUF', function(frame, unit)
		self:Construct_UF(frame, unit)
	end)
	
	self:LoadUnits()
	self:RegisterEvent('PLAYER_ENTERING_WORLD')

	if E.private["unitframe"].disableBlizzard then
		self:DisableBlizzard()	
		self:SecureHook('UnitFrameThreatIndicator_Initialize')
		--InterfaceOptionsFrameCategoriesButton9:SetScale(0.0001)
		InterfaceOptionsFrameCategoriesButton10:SetScale(0.0001)
		InterfaceOptionsFrameCategoriesButton11:SetScale(0.0001)
		InterfaceOptionsStatusTextPanelPlayer:SetScale(0.0001)
		InterfaceOptionsStatusTextPanelTarget:SetScale(0.0001)
		InterfaceOptionsStatusTextPanelParty:SetScale(0.0001)
		InterfaceOptionsStatusTextPanelPet:SetScale(0.0001)
		InterfaceOptionsStatusTextPanelPlayer:SetAlpha(0)
		InterfaceOptionsStatusTextPanelTarget:SetAlpha(0)
		InterfaceOptionsStatusTextPanelParty:SetAlpha(0)
		InterfaceOptionsStatusTextPanelPet:SetAlpha(0)
		InterfaceOptionsCombatPanelEnemyCastBarsOnPortrait:SetAlpha(0)
		InterfaceOptionsCombatPanelEnemyCastBarsOnPortrait:EnableMouse(false)
		InterfaceOptionsCombatPanelTargetOfTarget:SetScale(0.0001)
		InterfaceOptionsCombatPanelTargetOfTarget:SetAlpha(0)
		InterfaceOptionsCombatPanelEnemyCastBarsOnNameplates:ClearAllPoints()
		InterfaceOptionsCombatPanelEnemyCastBarsOnNameplates:SetPoint(InterfaceOptionsCombatPanelEnemyCastBarsOnPortrait:GetPoint())
		InterfaceOptionsDisplayPanelShowAggroPercentage:SetScale(0.0001)
		InterfaceOptionsDisplayPanelShowAggroPercentage:SetAlpha(0)

		if not IsAddOnLoaded('Blizzard_ArenaUI') then
			self:RegisterEvent('ADDON_LOADED')
		else
			ElvUF:DisableBlizzard('arena')
		end
		
		if E.myclass == "HUNTER" then
			self:RegisterEvent("UPDATE_POSSESS_BAR", "RemoveDismissPet")
		end
		
		--index #4 is PET_DISMISS for PET UnitPopupMenus
		for name, menu in pairs(UnitPopupMenus) do
			for index = #menu, 1, -1 do
				if removeMenuOptions[menu[index]] then
					tremove(menu, index)
				end
			end
		end				

		self:RegisterEvent('GROUP_ROSTER_UPDATE', 'DisableBlizzard')
		UIParent:UnregisterEvent('GROUP_ROSTER_UPDATE') --This may fuck shit up.. we'll see...
	else
		CompactUnitFrameProfiles:RegisterEvent('VARIABLES_LOADED')
	end
		
	local ORD = ns.oUF_RaidDebuffs or oUF_RaidDebuffs
	if not ORD then return end
	ORD.ShowDispelableDebuff = true
	ORD.FilterDispellableDebuff = true
	ORD.MatchBySpellName = true
end

function UF:ResetUnitSettings(unit)
	E:CopyTable(self.db['units'][unit], P['unitframe']['units'][unit]); 
	
	if self.db['units'][unit].buffs and self.db['units'][unit].buffs.sizeOverride then
		self.db['units'][unit].buffs.sizeOverride = P.unitframe.units[unit].buffs.sizeOverride or 0
	end
	
	if self.db['units'][unit].debuffs and self.db['units'][unit].debuffs.sizeOverride then
		self.db['units'][unit].debuffs.sizeOverride = P.unitframe.units[unit].debuffs.sizeOverride or 0
	end
	
	self:Update_AllFrames()
end

function UF:ToggleForceShowGroupFrames(unitGroup, numGroup)
	for i=1, numGroup do
		if self[unitGroup..i] and not self[unitGroup..i].isForced then
			UF:ForceShow(self[unitGroup..i])
		elseif self[unitGroup..i] then
			UF:UnforceShow(self[unitGroup..i])
		end
	end
end

local ignoreSettings = {
	['position'] = true,
	['playerOnly'] = true,
	['noConsolidated'] = true,
	['useBlacklist'] = true,
	['useWhitelist'] = true,
	['noDuration'] = true,
	['onlyDispellable'] = true,
	['useFilter'] = true,
}

local ignoreSettingsGroup = {
	['visibility'] = true,
}

local allowPass = {
	['sizeOverride'] = true,
}

function UF:MergeUnitSettings(fromUnit, toUnit, isGroupUnit)
	local db = self.db['units']
	local filter = ignoreSettings
	if isGroupUnit then
		filter = ignoreSettingsGroup 
	end
	if fromUnit ~= toUnit then
		for option, value in pairs(db[fromUnit]) do
			if type(value) ~= 'table' and not filter[option] then
				if db[toUnit][option] ~= nil then
					db[toUnit][option] = value
				end
			elseif not filter[option] then
				if type(value) == 'table' then
					for opt, val in pairs(db[fromUnit][option]) do
						--local val = db[fromUnit][option][opt]
						if type(val) ~= 'table' and not filter[opt] then
							if db[toUnit][option] ~= nil and (db[toUnit][option][opt] ~= nil or allowPass[opt]) then
								db[toUnit][option][opt] = val
							end				
						elseif not filter[opt] then
							if type(val) == 'table' then
								for o, v in pairs(db[fromUnit][option][opt]) do
									if not filter[o] then
										if db[toUnit][option] ~= nil and db[toUnit][option][opt] ~= nil and db[toUnit][option][opt][o] ~= nil then
											db[toUnit][option][opt][o] = v	
										end
									end
								end		
							end
						end
					end
				end
			end
		end
	else
		E:Print(L['You cannot copy settings from the same unit.'])
	end

	self:Update_AllFrames()
end

local function updateColor(self, r, g, b)
	if not self.isTransparent then return end
	if self.backdrop then
		local _, _, _, a = self.backdrop:GetBackdropColor()
		self.backdrop:SetBackdropColor(r * 0.58, g * 0.58, b * 0.58, a)
	elseif self:GetParent().template then
		local _, _, _, a = self:GetParent():GetBackdropColor()
		self:GetParent():SetBackdropColor(r * 0.58, g * 0.58, b * 0.58, a)
	end
	
	if self.bg and self.bg:GetObjectType() == 'Texture' and not self.bg.multiplier then
		self.bg:SetTexture(r * 0.35, g * 0.35, b * 0.35)
	end
end

function UF:ToggleTransparentStatusBar(isTransparent, statusBar, backdropTex, adjustBackdropPoints, invertBackdropTex)
	statusBar.isTransparent = isTransparent
	
	local statusBarTex = statusBar:GetStatusBarTexture()
	local statusBarOrientation = statusBar:GetOrientation()
	if isTransparent then
		if statusBar.backdrop then
			statusBar.backdrop:SetTemplate("Transparent")
			statusBar.backdrop.ignoreUpdates = true
		elseif statusBar:GetParent().template then
			statusBar:GetParent():SetTemplate("Transparent")	
			statusBar:GetParent().ignoreUpdates = true
		end
		
		statusBar:SetStatusBarTexture(0, 0, 0, 0)
		backdropTex:ClearAllPoints()
		if statusBarOrientation == 'VERTICAL' then
			backdropTex:SetPoint("TOPLEFT", statusBar, "TOPLEFT")
			backdropTex:SetPoint("BOTTOMLEFT", statusBarTex, "TOPLEFT")
			backdropTex:SetPoint("BOTTOMRIGHT", statusBarTex, "TOPRIGHT")			
		else
			backdropTex:SetPoint("TOPLEFT", statusBarTex, "TOPRIGHT")
			backdropTex:SetPoint("BOTTOMLEFT", statusBarTex, "BOTTOMRIGHT")
			backdropTex:SetPoint("BOTTOMRIGHT", statusBar, "BOTTOMRIGHT")
		end
		
		if invertBackdropTex then
			backdropTex:Show()
		end
		
		if not invertBackdropTex and not statusBar.hookedColor then
			hooksecurefunc(statusBar, "SetStatusBarColor", updateColor)
			statusBar.hookedColor = true
		end
		
		if backdropTex.multiplier then
			backdropTex.multiplier = 0.25
		end
	else
		if statusBar.backdrop then
			statusBar.backdrop:SetTemplate("Default")
			statusBar.backdrop.ignoreUpdates = nil
		elseif statusBar:GetParent().template then
			statusBar:GetParent():SetTemplate("Default")
			statusBar:GetParent().ignoreUpdates = nil
		end
		statusBar:SetStatusBarTexture(LSM:Fetch("statusbar", self.db.statusbar))
		if adjustBackdropPoints then
			backdropTex:ClearAllPoints()
			if statusBarOrientation == 'VERTICAL' then
				backdropTex:SetPoint("TOPLEFT", statusBar, "TOPLEFT")
				backdropTex:SetPoint("BOTTOMLEFT", statusBarTex, "TOPLEFT")
				backdropTex:SetPoint("BOTTOMRIGHT", statusBarTex, "TOPRIGHT")				
			else			
				backdropTex:SetPoint("TOPLEFT", statusBarTex, "TOPRIGHT")
				backdropTex:SetPoint("BOTTOMLEFT", statusBarTex, "BOTTOMRIGHT")
				backdropTex:SetPoint("BOTTOMRIGHT", statusBar, "BOTTOMRIGHT")
			end
		end
		
		if invertBackdropTex then
			backdropTex:Hide()
		end
		
		if backdropTex.multiplier then
			backdropTex.multiplier = 0.25	
		end
	end
end

E:RegisterInitialModule(UF:GetName())