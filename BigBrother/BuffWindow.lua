local addonName, vars = ...
local L = vars.L

local bit, math, date, string, select, table, time, tonumber, unpack, wipe, pairs, ipairs = 
      bit, math, date, string, select, table, time, tonumber, unpack, wipe, pairs, ipairs

local GetSpellInfo, UnitBuff, UnitDebuff, UnitIsConnected, UnitIsDeadOrGhost = 
      GetSpellInfo, UnitBuff, UnitDebuff, UnitIsConnected, UnitIsDeadOrGhost

local BarHeight=18
local BarWidth=260
local WindowWidth=BarWidth+32
local TotalBuffs=9
local PlayersShown=8
local RowsCreated=PlayersShown+1
local BuffSpacing=18

local BuffWindow_Functions={}

local BuffWindow_ResizeWindow, BuffWindow_UpdateWindow, BuffWindow_UpdateBuffs

local RL = AceLibrary("Roster-2.1")

-- tie-in for third party addons to add tooltips
-- table maps GUID => {  highlight = boolean, [addonname] = "status text" }
BigBrother.unitstatus = {}
BigBrother.unitstatus.refresh = function() 
   if BigBrother_BuffWindow and BigBrother_BuffWindow:IsShown() then
      BigBrother:BuffWindow_Update() 
   end
end

local function spellData(spellID, ignoreMissing, ...)
	local name,rank,icon = GetSpellInfo(spellID)
	if (not name) then
	  if (not ignoreMissing) then
	    BigBrother:Print("MISSING BUFF SPELLID: "..spellID)
	  end
	  name = "UNKNOWN"
	  icon = ""
	end
	return name, icon, ...
end

--[[ Load up local tables from master spell ID tables ]]

vars.Flasks = {}
for i,v in ipairs(vars.SpellData.flasks) do
	table.insert( vars.Flasks, { spellData(v) })
end

vars.ElixirsBattle={}
for i,v in ipairs(vars.SpellData.elixirsBattle) do
	table.insert( vars.ElixirsBattle, { spellData(v) })
end

vars.ElixirsGuardian={}
for i,v in ipairs(vars.SpellData.elixirsGuardian) do
	table.insert( vars.ElixirsGuardian, { spellData(v) })
end

vars.Elixirs={}
for i,v in ipairs(vars.ElixirsBattle) do
	table.insert( vars.Elixirs, v )
end
for i,v in ipairs(vars.ElixirsGuardian) do
	table.insert( vars.Elixirs, v )
end

vars.Foodbuffs={}
for i,v in ipairs(vars.SpellData.foods) do
	table.insert(vars.Foodbuffs,  { spellData(v) })
end

vars.Pokesfish={}
for i,v in ipairs(vars.SpellData.pokesfish) do
	table.insert(vars.Pokesfish,  { spellData(v) })
end

vars.Maslo={}
for i,v in ipairs(vars.SpellData.masloo) do
	table.insert(vars.Maslo,  { spellData(v) })
end

local foodmin = 60 -- minimum food stat level to allow
local scanfoodcache = {}
local scantt = CreateFrame("GameTooltip", "BigBrotherScanTooltip", UIParent, "GameTooltipTemplate")
local function scanfood(spellid)
  local f = scanfoodcache[spellid]
  if f then return f end
  f = { spellData(spellid) }
  scantt:ClearLines()
  scantt:SetOwner(UIParent, "ANCHOR_NONE");
  scantt:SetSpellByID(spellid)
  local line = getglobal(scantt:GetName() .. "TextLeft3")
  line = line and line:GetText()
  if not line then return f end
  local statval = 0
  for v in string.gmatch(line, "%d+") do  -- assume largest number in tooltip is the statval
     statval = math.max(statval,tonumber(v))
  end
  if statval >= 100 and string.find(line, ITEM_MOD_STAMINA_SHORT) then -- normalize for MoP stam bonus
     statval = statval * 300 / 450
  end
  --print(spellid, f[1], statval)
  if statval >= foodmin or
     spellid == 66623 then -- bountiful feast
     -- food is good
  elseif statval == 0 then -- scan failed (client cache miss), retry next call
     return f
  else
     -- food is bad
     f[4] = true
  end
  scanfoodcache[spellid] = f
  return f
end

local function Sort_RaidBuffs(a,b)
	if a.totalBuffs ~= b.totalBuffs then
		return a.totalBuffs < b.totalBuffs
	elseif a.buffMask ~= b.buffMask then
		return a.buffMask < b.buffMask
	else
		return a.name < b.name
	end
end

local function Sort_ByClass(a,b)
	if a.class<b.class then
		return true
	elseif a.class>b.class then
		return false
	elseif a.name<b.name then
		return true
	end
	return false
end

local function headerColor(s)
  return "|cffffffff"..s.."|r"
end

local function spellNames(...)
  local r 
  for i=1,select("#",...) do
    local s = select(i,...)
    if not s then
      r = headerColor(r)
    else
      local n
      if tonumber(s) then
        n = spellData(s,true)
      else
        n = s
      end
      if n then
        if r then
          r = r.."\n"..n
        else
          r = n
        end
      end
    end
  end
  return r
end

local BigBrother_BuffTable={
	{
		name=L["Raid Buffs"],
		sortFunc=Sort_ByClass,
		buffs={
			{{spellData(20217)},{spellData(25898)},{spellData(69378)}}, -- 20217 Blessing of Kings, 25898 Greater Blessing of Kings, 69378 Blessing of Forgotten Kings	
			{{spellData(19740)},{spellData(25782)},{spellData(6673)}}, -- 19740 Blessing of Might, 25782 Greater Blessing of Might, 6673 Battle Shout
			{{spellData(19742)},{spellData(25894)},{spellData(5677)}}, -- 19742 Blessing of Wisdom, 25894 Greater Blessing of Wisdom, 5677 Mana Spring
			{{spellData(20911)},{spellData(25899)},{spellData(14893)}}, -- 20911 Blessing of Sanctuary, 25899 Greater Blessing of Sanctuary, 14893 Inspiration
			{{spellData(1459)},{spellData(23028)},{spellData(61024)},{spellData(61316)}}, -- 1459 Arcane Intellect, 23028 Arcane Brilliance, 61024 Dalaran Intellect, 61316 Dalaran Brilliance
			{{spellData(1243)},{spellData(21562)},{spellData(69377)}}, -- 1243 Power Word: Fortitude, 21562 Prayer of Fortitude, 69377 Runescroll of Fortitude
			{{spellData(1126)},{spellData(21849)}}, -- 1126 Mark of the Wild, 21849 Gift of the Wild
			{{spellData(14752)},{spellData(27681)}}, -- 14752 Divine Spirit, 27681 Prayer of Spirit
			{{spellData(976)},{spellData(27683)}}, -- Защита от тьмы 
		},
		header={
			L["All Stats"],
			L["Attack power"],
			L["MP5"], 
			L["Blessing of Sanctuary"],
			L["Intellect"],
			L["Stamina"],
			L["Mark of the Wild"], 
			L["Spirit"],
			L["Shadow Protection"],
		}
	},	
	{
		name=L["Consumables"],
		sortFunc=Sort_ByClass,
		buffs={
		    {},{},{},{},
			vars.ElixirsBattle,
			vars.ElixirsGuardian,
			vars.Flasks,
			vars.Maslo,			
      		vars.Foodbuffs,	
		},
		header={
		    {},{},{},{},
			{headerColor(L["Battle Elixirs"]),     select(2,spellData(60341))}, 
			{headerColor(L["Guardian Elixirs"]),   select(2,spellData(60343))}, 
			{headerColor(L["Flasks"]),           select(2,spellData(67019))}, 
			{headerColor(L["Maslo"]),     select(2,spellData(317727))}, 
			{headerColor(L["Foods"]),            select(2,spellData(62349))},
		}
	},
}

-- index the buff table to optimize scanning
local BuffTable_index = {}
BigBrother.BuffTable_index = BuffTable_index
for pageid,page in ipairs(BigBrother_BuffTable) do
  for colid, col in ipairs(page.buffs) do
    for order, spellinfo in ipairs(col) do
      spellinfo.page = pageid
      spellinfo.col = colid
      spellinfo.order = order
      local id = spellinfo[1]
      BuffTable_index[id] = BuffTable_index[id] or {}
      table.insert(BuffTable_index[id], spellinfo)
    end
  end
end

-- default each header to the buff spells and icon to first one
for i = 1, table.getn(BigBrother_BuffTable) do
  local page = BigBrother_BuffTable[i]
  local hiddenBuffs = { 
      [GetSpellInfo(31876)] = true, -- communion doesnt show
	  [GetSpellInfo(28093)] = true, -- communion doesnt show
    }
  for col = 1, table.getn(page.buffs) do
    if type(page.header[col]) ~= "table" then
      local label = page.header[col] or ""
      if #label > 0 then label = headerColor(label) end
      for _,data in ipairs(page.buffs[col]) do
        local spellname = data[1]
	if hiddenBuffs[spellname] then
	  spellname = "("..spellname..")" 
	end
	if not data[3] then
          if #label > 0 then
            label = label.."\n"
          end
          label = label..spellname
	end
      end
      page.header[col] = { label, page.buffs[col][1][2] }
    end
  end 
end

function BuffWindow_Functions:CreateBuffRow(parent, xoffset, yoffset)
	local Row=CreateFrame("Button",nil,parent)

	Row:SetPoint("TOPLEFT",parent,"TOPLEFT",xoffset,yoffset)
	Row:SetHeight(BarHeight)
	Row:SetWidth(BarWidth)
	Row:Show()

	Row:SetScript("OnClick", function(self,button) 
	      local u = self.unit
	      if u and u ~= "header" and UnitExists(u) and CanInspect(u) and UnitIsConnected(u) 
	           and UnitIsVisible(u) and CheckInteractDistance(u, 1) then 
	         InspectUnit(u) 
	      end end)
	
	Row:SetScript("OnEnter", function(self) 
	      local guid = self.guid
	      local status = guid and BigBrother.unitstatus[guid]
	      if status then
	        GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT")
		GameTooltip:ClearLines();
	        local gotone
		for k,v in pairs(status) do
		  if k ~= "highlight" then
		    gotone = true
		    GameTooltip:AddLine(k..": "..v);
		  end
		end
		if gotone then GameTooltip:Show() end
	      end end)
	Row:SetScript("OnLeave", function(self) GameTooltip:Hide() end)
	
	Row.Background=Row:CreateTexture(nil,"BACKGROUND")
	Row.Background:SetAllPoints(Row)
	Row.Background:SetTexture("Interface\\Buttons\\WHITE8X8.blp")
	Row.Background:SetGradientAlpha("HORIZONTAL",1.0/2,0.0,0.0,0.8,1.0/2,0.0,0.0,0.0)
	Row.Background:Show()

	Row.Name=Row:CreateFontString(nil,"OVERLAY","GameFontNormal")	
	Row.Name:SetPoint("LEFT",Row,"LEFT",4,0)
	Row.Name:SetTextColor(1.0,1.0,1.0)
	Row.Name:SetText("Test")

	

	Row.Buff={}
	for i=1,TotalBuffs do
		Row.Buff[i]=CreateFrame("FRAME",nil,Row)		
		Row.Buff[i]:SetPoint("RIGHT",Row,"RIGHT",-4-(TotalBuffs-i)*BuffSpacing,0)
		Row.Buff[i]:SetHeight(16)
		Row.Buff[i]:SetWidth(16)

		Row.Buff[i].texture=Row.Buff[i]:CreateTexture(nil,"OVERLAY")
		Row.Buff[i].texture:SetAllPoints(Row.Buff[i])
		Row.Buff[i].texture:SetTexture("Interface\\Buttons\\UI-CheckBox-Check.blp")
			
		Row.Buff[i].BuffName = nil
		--GameTooltip:ClearLines();GameTooltip:AddLine(this.BuffName);GameTooltip:Show()
		Row.Buff[i]:SetScript("OnEnter", BuffWindow_Functions.OnEnterBuff)
		Row.Buff[i]:SetScript("OnLeave", BuffWindow_Functions.OnLeaveBuff)
		Row.Buff[i]:EnableMouse()

		Row.Buff[i]:Show()
	end

	Row.SetPlayer=BuffWindow_Functions.SetPlayer
	Row.SetBuffValue=BuffWindow_Functions.SetBuffValue
	Row.SetBuffIcon=BuffWindow_Functions.SetBuffIcon
	Row.SetBuffName=BuffWindow_Functions.SetBuffName

	return Row
end

function BuffWindow_Functions:OnEnterBuff()
	GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT")
        if self.unit == "header" then
          GameTooltip:SetText(self.BuffName)
	else
	  GameTooltip:SetUnitBuff(self.unit, self.BuffName)
	  GameTooltip:SetUnitDebuff(self.unit, self.BuffName)
        end
	GameTooltip:Show()
end

function BuffWindow_Functions:OnLeaveBuff()
	GameTooltip:Hide()
end


function BuffWindow_Functions:SetPlayer(player,class,unit)
	local guid = UnitGUID(unit)
	self.Name:SetText(player)
	self.unit = unit
	self.guid = guid
	local status = BigBrother.unitstatus[guid]
	if status and status.highlight then
	    self.Name:SetTextColor(1.0,0.2,0.2)
	else
	    self.Name:SetTextColor(1,1,1)
	end
	local color
 	if unit == "header" then
	  color={["r"]=1,["g"]=1,["b"]=1}
	elseif not UnitIsConnected(unit) then
	  color={["r"]=0.5,["g"]=0.5,["b"]=0.5}
	elseif UnitIsDeadOrGhost(unit) then
	  color={["r"]=0.1,["g"]=0.1,["b"]=0.1}
        else
          color=RAID_CLASS_COLORS[class]
	end
	self.Background:SetGradientAlpha("HORIZONTAL",color.r/1.5,color.g/1.5,color.b/1.5,0.8,color.r/1.5,color.g/2,color.b/1.5,0)
end

function BuffWindow_Functions:SetBuffValue(num,enabled)
	if enabled then
		self.Buff[num]:Show()
	else
		self.Buff[num]:Hide()
	end
end

function BuffWindow_Functions:SetBuffIcon(num,texture,dimmed)
	self.Buff[num].texture:SetTexture(texture)
        if dimmed then
	   self.Buff[num].texture:SetAlpha(0.5)
        else
	   self.Buff[num].texture:SetAlpha(1.0)
        end
end

function BuffWindow_Functions:SetBuffName(num,buffName,unit)
	self.Buff[num].BuffName=buffName
	self.Buff[num].unit=unit
end

local update_events = { "UNIT_AURA", "RAID_ROSTER_UPDATE", "PARTY_MEMBERS_CHANGED" }
function BigBrother:RegisterEvents()
  for _,e in pairs(update_events) do
    self:RegisterBucketEvent(e, 0.25, "BuffWindow_Update")
  end
end
function BigBrother:UnregisterEvents()
  self:UnregisterAllBucketEvents()
end

function BigBrother:ToggleBuffWindow()
	if BigBrother_BuffWindow then
		if BigBrother_BuffWindow:IsShown() then
			BigBrother_BuffWindow:Hide()
			self:UnregisterEvents()
		else
			BuffWindow_UpdateBuffs()
			BuffWindow_UpdateWindow()
			BigBrother_BuffWindow:Show()
			self:RegisterEvents()
		end
	else
		self:CreateBuffWindow()
	end
end

function BigBrother:CreateBuffWindow()
	local BuffWindow = CreateFrame("FRAME","BigBrother_BuffWindow",UIParent)

	BuffWindow:SetBackdrop({bgFile = "Interface/Tooltips/UI-Tooltip-Background", 
                                            edgeFile = "Interface/Tooltips/UI-Tooltip-Border", 
                                            tile = true, tileSize = 16, edgeSize = 16, 
                                            insets = { left = 4, right = 4, top = 4, bottom = 4 }});
	BuffWindow:SetBackdropColor(0,0,0,0.5);
	BuffWindow:SetWidth(WindowWidth) 
	BuffWindow:SetMovable(true)
	BuffWindow:SetClampedToScreen(true)
	BuffWindow:EnableMouse()
	
  BuffWindow:ClearAllPoints()
	if BigBrother.db.profile.BuffWindow_posX then
     BuffWindow:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT",
                         BigBrother.db.profile.BuffWindow_posX,
                         BigBrother.db.profile.BuffWindow_posY)	 
     BuffWindow:SetHeight(BigBrother.db.profile.BuffWindow_height or 190);                           
	else
     BuffWindow:SetPoint("CENTER",UIParent)
     BuffWindow:SetHeight(551);     
	end

	BuffWindow:SetScript("OnMouseDown", function() 
						  BigBrother_BuffWindow:StartMoving();
						  BigBrother_BuffWindow.isMoving = true;
						end)
	BuffWindow:SetScript("OnMouseUp", function() 
						if ( BigBrother_BuffWindow.isMoving ) then
						  BigBrother_BuffWindow:StopMovingOrSizing();
						  BigBrother_BuffWindow.isMoving = false;
						  BigBrother.db.profile.BuffWindow_posX = BigBrother_BuffWindow:GetLeft();
						  BigBrother.db.profile.BuffWindow_posY = BigBrother_BuffWindow:GetTop();
	                                          BigBrother.db.profile.BuffWindow_height = BigBrother_BuffWindow:GetHeight();
						 end
						end)
					
	BuffWindow:SetScript("OnHide", function() 
						if ( BigBrother_BuffWindow.isMoving ) then
						  BigBrother_BuffWindow:StopMovingOrSizing();
						  BigBrother_BuffWindow.isMoving = false;
						 end
						end)
	
	BuffWindow:Show()

	BuffWindow.Title=BuffWindow:CreateFontString(nil,"OVERLAY","GameFontNormal")
	BuffWindow.Title:SetPoint("TOP",BuffWindow,"TOP",0,-8)
	BuffWindow.Title:SetTextColor(1.0,1.0,1.0)

	BuffWindow.LeftButton=CreateFrame("Button",nil,BuffWindow)
	BuffWindow.LeftButton:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Up.blp")
	BuffWindow.LeftButton:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Down.blp")
	BuffWindow.LeftButton:SetWidth(16)
	BuffWindow.LeftButton:SetHeight(18)
	BuffWindow.LeftButton:SetPoint("TOPLEFT",BuffWindow,"TOPLEFT",64,-5)
	BuffWindow.LeftButton:SetScript("OnClick",function() 
							BigBrother_BuffWindow.SelectedBuffs=BigBrother_BuffWindow.SelectedBuffs-1
							if BigBrother_BuffWindow.SelectedBuffs==0 then
								BigBrother_BuffWindow.SelectedBuffs=table.getn(BigBrother_BuffTable)
							end
							BuffWindow_UpdateBuffs()
							BuffWindow_UpdateWindow()
						end)

	BuffWindow.RightButton=CreateFrame("Button",nil,BuffWindow)
	BuffWindow.RightButton:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up.blp")
	BuffWindow.RightButton:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Down.blp")
	
	BuffWindow.RightButton:SetWidth(16)
	BuffWindow.RightButton:SetHeight(18)
	BuffWindow.RightButton:SetPoint("TOPRIGHT",BuffWindow,"TOPRIGHT",-64,-5)
	BuffWindow.RightButton:SetScript("OnClick",function() 
							BigBrother_BuffWindow.SelectedBuffs=BigBrother_BuffWindow.SelectedBuffs+1
							if BigBrother_BuffWindow.SelectedBuffs>table.getn(BigBrother_BuffTable) then
								BigBrother_BuffWindow.SelectedBuffs=1
								
							end
							BuffWindow_UpdateBuffs()
							BuffWindow_UpdateWindow()
						end)
	
	BuffWindow.CloseButton=CreateFrame("Button",nil,BuffWindow)
	BuffWindow.CloseButton:SetNormalTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up.blp")
	BuffWindow.CloseButton:SetPushedTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Down.blp")
	BuffWindow.CloseButton:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight.blp")
	BuffWindow.CloseButton:SetWidth(20)
	BuffWindow.CloseButton:SetHeight(20)
	BuffWindow.CloseButton:SetPoint("TOPRIGHT",BuffWindow,"TOPRIGHT",-4,-4)
	BuffWindow.CloseButton:SetScript("OnClick",function() BigBrother_BuffWindow:Hide();self:UnregisterEvents() end)
	
	BuffWindow.RCButton=CreateFrame("Button", nil, BuffWindow)
  --BuffWindow.RCButton:SetNormalTexture("Interface\\RAIDFRAME\\ReadyCheck-Waiting")
	BuffWindow.RCButton:SetWidth(1)
	BuffWindow.RCButton:SetHeight(1)
	BuffWindow.RCButton:SetPoint("TOPLEFT", BuffWindow, "TOPLEFT", 8, -8)
	BuffWindow.RCButton:SetScript("OnClick",function() DoReadyCheck() end)
--[[	BuffWindow.RCButton:SetScript("OnEnter",function()
	      GameTooltip:SetOwner(BuffWindow, "ANCHOR_CURSOR"); GameTooltip:SetText(READY_CHECK); GameTooltip:Show() end)
	BuffWindow.RCButton:SetScript("OnLeave",function() GameTooltip:Hide() end) ]]

        BuffWindow.MenuButton=CreateFrame("Button", nil, BuffWindow)
        BuffWindow.MenuButton:SetNormalTexture("Interface\\AddOns\\BigBrother\\icon")
        BuffWindow.MenuButton:SetWidth(15)
        BuffWindow.MenuButton:SetHeight(15)
        BuffWindow.MenuButton:SetPoint("TOPLEFT", BuffWindow.RCButton, "TOPRIGHT", 0, 0)
        BuffWindow.MenuButton:SetScript("OnClick",function() BigBrother:OpenMenu(BuffWindow.MenuButton,BigBrother) end)
        BuffWindow.MenuButton:SetScript("OnEnter",function()
              GameTooltip:SetOwner(BuffWindow, "ANCHOR_CURSOR"); GameTooltip:SetText(OPTIONS_MENU); GameTooltip:Show() end)
        BuffWindow.MenuButton:SetScript("OnLeave",function() GameTooltip:Hide() end)

	BuffWindow.Rows={}
	for i=1,RowsCreated do
		BuffWindow.Rows[i]=BuffWindow_Functions:CreateBuffRow(BuffWindow,8,-4-i*(BuffSpacing+2))
	end

	BuffWindow.ScrollBar=CreateFrame("SCROLLFRAME","BuffWindow_ScrollBar",BuffWindow,"FauxScrollFrameTemplate")
	BuffWindow.ScrollBar:SetScript("OnVerticalScroll", function(self, offset) FauxScrollFrame_OnVerticalScroll(self, offset, 20, BuffWindow_UpdateWindow) end)

	BuffWindow.ScrollBar:SetPoint("TOPLEFT", BuffWindow.Rows[2], "TOPLEFT", 0, 0)
	BuffWindow.ScrollBar:SetPoint("BOTTOMRIGHT", BuffWindow.Rows[8], "BOTTOMRIGHT", -4, 0)

	-- drag handle
	
	BuffWindow.draghandle = CreateFrame("Frame", nil, BuffWindow)
	BuffWindow.draghandle:Show()
	BuffWindow.draghandle:SetFrameLevel( BuffWindow:GetFrameLevel() + 10 ) -- place this above everything
	BuffWindow.draghandle:SetWidth(WindowWidth)
	BuffWindow.draghandle:SetHeight(16)
	BuffWindow.draghandle:SetPoint("BOTTOM", BuffWindow, "BOTTOM", 0, 0)
	BuffWindow.draghandle:EnableMouse(true)
	BuffWindow.draghandle:SetScript("OnMouseDown", function() BigBrother_BuffWindow.isResizing = true; BigBrother_BuffWindow:StartSizing("BOTTOMRIGHT") end )
	BuffWindow.draghandle:SetScript("OnMouseUp", function() BigBrother_BuffWindow:StopMovingOrSizing(); BigBrother_BuffWindow.isResizing = false; end )
	
	BuffWindow:SetMinResize(WindowWidth,110)
	BuffWindow:SetMaxResize(WindowWidth,551)	
	BuffWindow:SetResizable(true);

	BuffWindow:SetScript("OnSizeChanged", function()
						if ( BigBrother_BuffWindow.isResizing ) then
							BuffWindow_ResizeWindow()
						end
					end)
    

	BigBrother_BuffWindow=BuffWindow
	BigBrother_BuffWindow.SelectedBuffs=1
	BuffWindow_UpdateBuffs()
	BuffWindow_ResizeWindow()
	self:RegisterEvents()
end

--When called will update buffs and the window
function BigBrother:BuffWindow_Update()
	BuffWindow_UpdateBuffs()
	BuffWindow_UpdateWindow()
end


local PlayerList={}
function BuffWindow_UpdateBuffs()
	local unit
	local thispage = BigBrother_BuffWindow.SelectedBuffs
	local BuffChecking=BigBrother_BuffTable[thispage]
	local Filter=BuffChecking.filter
	local index = 1

	local foodcol
	for col, BuffList in pairs(BuffChecking.buffs) do
	  if BuffList == vars.Foodbuffs then
	    foodcol = col
	    break
	  end
	end

	for unit in RL:IterateRoster(false) do
		if BigBrother.db.profile.Groups[unit.subgroup] then
			if (not Filter) or Filter[unit.class] then
				local player = PlayerList[index]
				
				if player==nil then
					player = {}
					PlayerList[index] = player
				end

				player.name=unit.name
				player.class=unit.class
				player.totalBuffs = 0
				player.buffMask = 0
				player.buff = wipe(player.buff or {})
				player.unit=unit.unitid
				if BigBrother.oldscan then -- slow legacy scan code
				    for i, BuffList in pairs(BuffChecking.buffs) do
					for _, buffs in pairs(BuffList) do
						local spellid = select(11,UnitBuff(unit.unitid, buffs[1]))
						if spellid then
							player.buff[i] = buffs
							player.totalBuffs = player.totalBuffs + 1
							if not buffs[4] then -- binary sort by non-weak buffs
							  player.buffMask = bit.bor(player.buffMask, 2^i)
							end
							break
						end
					end
				    end
				else -- optimized scan code
				    player.buffMask = 0
				    for b=1,40 do
				      local name,
				      	    _,_,_,_,_,_,_,_,_,
				            spellid = UnitBuff(unit.unitid, b)
				      if not name then break end
				      local spellinfo = BuffTable_index[name]
				      if spellinfo then
				        for _,buffinfo in ipairs(spellinfo) do -- handle multi-column buffs
					  if buffinfo.page == thispage then
				            local col = buffinfo.col
					    local bestinfo = player.buff[col]
					    if not bestinfo then -- first buff for this col
					      player.totalBuffs = player.totalBuffs + 1
					    end
					    if not bestinfo or
					       buffinfo.order < bestinfo.order then
					       if col == foodcol then
						 buffinfo = scanfood(spellid)
						 buffinfo.order = 0
					       end
					       player.buff[col] = buffinfo
					       if not buffinfo[4] then -- binary sort by non-weak buffs
					         player.buffMask = bit.bor(player.buffMask, 2^col)
					       end
					    end
					  end
					end
				      end
				    end
				end
				
				index = index + 1
			end
		end
	end

  while PlayerList[index] do -- clear the rest of the table so we dont get nil holes that lead to ill-defined behavior in sort
	  PlayerList[index] = nil
	  index = index + 1
	end

	table.sort(PlayerList,BuffChecking.sortFunc)
	BigBrother_BuffWindow.List=PlayerList
end

function BuffWindow_UpdateWindow()
	local PlayerList=BigBrother_BuffWindow.List
	local Rows=BigBrother_BuffWindow.Rows
	local endOfList = false
	
	FauxScrollFrame_Update(BigBrother_BuffWindow.ScrollBar, table.getn(PlayerList), PlayersShown, 20)
	local offset = FauxScrollFrame_GetOffset(BigBrother_BuffWindow.ScrollBar)
	
	BigBrother_BuffWindow.Title:SetText(BigBrother_BuffTable[BigBrother_BuffWindow.SelectedBuffs].name)

        local header = BigBrother_BuffTable[BigBrother_BuffWindow.SelectedBuffs].header
        local roffset = 0
        if header then
          local headerRow = Rows[1]
          headerRow:SetPlayer("",nil,"header")
	  for j=1,TotalBuffs do
	    if header[j][2] then
               headerRow:SetBuffIcon(j,header[j][2],true)
               headerRow:SetBuffName(j,header[j][1], "header")
               headerRow:SetBuffValue(j,true)
            else
               headerRow:SetBuffValue(j,false)
            end 
          end
          roffset = 1
          headerRow:Show()
	end

	for i=1,PlayersShown do
		if not endOfList and PlayerList[i+offset] then
			local Player=PlayerList[i+offset]
			Rows[i+roffset]:SetPlayer(Player.name,Player.class,Player.unit)
			for j=1,TotalBuffs do
				if Player.buff[j] then
					Rows[i+roffset]:SetBuffIcon(j,Player.buff[j][2],Player.buff[j][4])
					Rows[i+roffset]:SetBuffName(j,Player.buff[j][1], Player.unit)
					Rows[i+roffset]:SetBuffValue(j,true)
				else
					Rows[i+roffset]:SetBuffValue(j,false)
				end
			end
			Rows[i+roffset]:Show()
		else
			endOfList = true
			Rows[i+roffset]:Hide()
		end
	end
end

function BuffWindow_ResizeWindow()

	local NumVisibleRows=math.floor( (BigBrother_BuffWindow:GetHeight() - (BuffSpacing+4)-8) / (BuffSpacing+2) )

	if NumVisibleRows>RowsCreated then
		for i=(1+RowsCreated),NumVisibleRows do
			BigBrother_BuffWindow.Rows[i]=BuffWindow_Functions:CreateBuffRow(BigBrother_BuffWindow,8,-4-i*(BuffSpacing+2))
			BigBrother_BuffWindow.Rows[i]:Hide()
		end
		RowsCreated=NumVisibleRows
	end

	if NumVisibleRows<PlayersShown+1 then
		for i=(1+NumVisibleRows),PlayersShown+1 do
			BigBrother_BuffWindow.Rows[i]:Hide()
		end
	end
	PlayersShown=NumVisibleRows-1

	BigBrother_BuffWindow.ScrollBar:SetPoint("BOTTOMRIGHT", BigBrother_BuffWindow.Rows[NumVisibleRows], "BOTTOMRIGHT", -4, 0)
	BuffWindow_UpdateWindow()
	
	BigBrother.db.profile.BuffWindow_height = BigBrother_BuffWindow:GetHeight();
end

