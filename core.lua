﻿-- Author      : canon
-- Create Date : 7/25/2013 9:51:02 PM

local version = "0.0.0.46"
local frame = CreateFrame("BUTTON", "PKTracker");
local events = {};
local genders = { "unknown", "Male", "Female" };
local playerGUID;
local playerName;
local tooltipSet = false
local classColors = {
	["Death Knight"] = "C41F3B",
	["Druid"] = "FF7D0A",
	["Hunter"] = "ABD473",
	["Mage"] = "69CCF0",
	["Monk"] = "00FF96",
	["Paladin"] = "F58CBA",
	["Priest"] = "FFFFFF",
	["Rogue"] = "FFF569",
	["Shaman"] = "0070DE",
	["Warlock"] = "9482C9",
	["Warrior"] = "C79C6E",
};

-- slightly desaturated and darkened versions of the colors above
local classFrameColors = {
	["Death Knight"] = {0.122788235294118, 0.0386705882352941, 0.0529450980392157, .75},
	["Druid"] = {0.171862745098039, 0.105588235294118, 0.0469607843137255, .75},
	["Hunter"] = {0.139333333333333, 0.160235294117647, 0.11078431372549, .75},
	["Mage"] = {0.102364705882353, 0.152835294117647, 0.171188235294118, .75},
	["Monk"] = {0.0461176470588235, 0.176117647058824, 0.122588235294118, .75},
	["Paladin"] = {0.173243137254902, 0.119713725490196, 0.143164705882353, .75},
	["Priest"] = {.2, .2, .2, .75},
	["Rogue"] = {0.194235294117647, 0.189137254901961, 0.117764705882353, .75},
	["Shaman"] = {0.0245411764705882, 0.0816392156862745, 0.137717647058824, .75},
	["Warlock"] = {0.11456862745098, 0.105392156862745, 0.141588235294118, .75},
	["Warrior"] = {0.146552941176471, 0.12463137254902, 0.101180392156863, .75},
};

local CLASS_TEX_COORDS = {
	["Warrior"] = {0, 0.25, 0, 0.25},
	["Mage"] = {0.25, 0.49609375, 0, 0.25},
	["Rogue"] = {0.49609375, 0.7421875, 0, 0.25},
	["Druid"] = {0.7421875, 0.98828125, 0, 0.25},
	["Hunter"] = {0, 0.25, 0.25, 0.5},
	["Shaman"] = {0.25, 0.49609375, 0.25, 0.5},
	["Priest"] = {0.49609375, 0.7421875, 0.25, 0.5},
	["Warlock"] = {0.7421875, 0.98828125, 0.25, 0.5},
	["Paladin"] = {0, 0.25, 0.5, 0.75},
	["Death Knight"] = {0.25, 0.49609375, 0.5, 0.75},
	["Monk"] = {0.496039375, 0.7421875, 0.5, 0.75},
};

local damageEvents = {
	["SWING_DAMAGE"] = true,
	["RANGE_DAMAGE"] = true,
	["SPELL_DAMAGE"] = true,
	["SPELL_PERIODIC_DAMAGE"] = true,
	["ENVIRONMENTAL_DAMAGE"] = true
};

local damageTypeMapping = {
	["Melee Attack"] = -1,
	["Drowning"] = -2,
	["Falling"] = -3,
	["Fatigue"] = -4,
	["Fire"] = -5,
	["Lava"] = -6,
	["Slime"] = -7
}

local teammates = {}

function math.round(num, idp)
  local mult = 10^(idp or 0)
  return math.floor(num * mult + 0.5) / mult
end

local function getFatalSpellName(spellId)
	
	local spellName = GetSpellInfo(spellId)
	
	if not spellName then
	
		for k,v in pairs(damageTypeMapping) do
			
			if v == spellId then
			
				return k
			
			end
		
		end		
	
	end
	
	return spellName

end

local combatants = {};

local infoRequests = {}

local currentRecord = 0;

local combat

local leftCombat

local tracking = true

local function UnitGUIDIsPlayer(UnitGUID)	    
	return UnitGUID:find("Player");
end

local function nvl(a,b)
	if a ~= nil then
		return a;
	else
		return b;
	end	
end

local function nilIf(a,b)
	if a == b then
		return nil;
	else
		return a;
	end	
end

local function iif(condition, a, b)
	
	if condition then
		return a;
	else
		return b;
	end
	
end

function string.gsplit(s, sep, plain)
	local start = 1
	local done = false
	local function pass(i, j, ...)
		if i then
			local seg = s:sub(start, i - 1)
			start = j + 1
			return seg, ...
		else
			done = true
			return s:sub(start)
		end
	end
	return function()
		if done then return end
		if sep == '' then done = true return s end
		return pass(s:find(sep, start, plain))
	end
end

local function Split(val, pattern)
	local values = {}
	for text in string.gsplit(val, pattern, true) do
		table.insert(values, text)
	end	
	return values;
end

local function SameDay(date1, date2)

	return date1.year == date2.year and date1.month == date2.month and date1.day == date2.day

end

local function AddDebugChatMessage(text)
	DEFAULT_CHAT_FRAME:AddMessage("|cFFDFCE40PKTracker |cFF00FF00debugging|cFFFFFFFF: " .. tostring(text));
end

local function AddChatMessage(text)
	DEFAULT_CHAT_FRAME:AddMessage("|cFFDFCE40PKTracker|cFFFFFFFF " .. tostring(text));
end

seterrorhandler(function(msg)		
	DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000LuaError|cFFFFFFFF: " .. msg);			
end);

local function UpdatePlayerName()
	playerName = string.format("%s-%s",	UnitName("player"), GetRealmName())
end

local function SendUnitInfoRequest(GUID)

	if not GUID or not playerName or (infoRequests[GUID] and time() - infoRequests[GUID] < 10) then
	
		return
	
	end		
		
	infoRequests[GUID] = time()
		
	local message = string.format("UNIT_INFO_REQUEST:%s,%s", GUID, playerName)
				
	SendAddonMessage("PKTRACKER",message,"RAID");	
	
end

local function SendUnitUpdate(unitInfo)
		
	local message = string.format("UNIT_UPDATE:%s,%s,%s,%s,%s,%s,%s,%s,%s",
		unitInfo.GUID,		
		unitInfo.Name,
		nvl(unitInfo.Realm,""),
		nvl(unitInfo.Class,""),
		nvl(unitInfo.Level,""),
		nvl(unitInfo.Race,""),
		nvl(unitInfo.Sex,""),
		nvl(unitInfo.GuildName,""),
		nvl(unitInfo.Time,""))			
		
	SendAddonMessage("PKTRACKER",message,"RAID");

end

local function GetUnitSummary(unit)

	local name, realm = UnitName(unit);

	return {
		GUID = UnitGUID(unit),
		Name = name,
		Realm = realm,
		Class = UnitClass(unit),
		Level = UnitLevel(unit),
		Race = UnitRace(unit),
		Sex = UnitSex(unit),		
		GuildName = GetGuildInfo(unit),
		Time = time()
	};

end

local function IsHostilePlayer(flags)

	return flags and bit.band(flags, COMBATLOG_OBJECT_TYPE_PLAYER) ~= 0 and bit.band(flags, COMBATLOG_OBJECT_REACTION_HOSTILE) ~= 0;

end

local function WipeInfo()

	local info = PKTrackerVars.Info

	local now = time();
	
	for key, value in pairs(info) do
		
		if not combatants[key] and not value.Keep and (not value.Time or now - value.Time > 21600) then
		
			info[key] = nil;
		
		end
		
	end

end

local function UpdateSlider()

	local history = PKTrackerVars.History
	
	local max = #history - #history % 7;
	frame.Slider:SetMinMaxValues(1, iif(max < 1, 1, max));				
	frame.Slider:SetValueStep(7);
	frame.Slider:SetValue(currentRecord);	

end

local function UpdateKillFrame(killFrame, kill, n)		
	
	local history, info, settings = PKTrackerVars.History, PKTrackerVars.Info, PKTrackerVars.Settings
	
	local unitInfo = nvl(info[kill.GUID],{})
		
	local name = nvl(unitInfo.Name, "Unknown");
	
	if name == "Unknown" or not unitInfo.Class or not unitInfo.Level or not unitInfo.Sex or not unitInfo.Race then
		
		SendUnitInfoRequest(kill.GUID)
	
	end	
	
	if unitInfo.Realm and not name:find("-") then
		name = string.format("%s-%s", name, unitInfo.Realm)
	end
				
	if unitInfo.Class then -- extended info			
	
		killFrame.ClassIcon:SetTexture([[Interface\Glues\CharacterCreate\UI-CharacterCreate-Classes]]);
		killFrame.ClassIcon:SetTexCoord(unpack(CLASS_TEX_COORDS[unitInfo.Class]));	
	
		killFrame.PlayerName:SetText(string.format("|cFF%s%s", classColors[unitInfo.Class], name));		
		
		if unitInfo.GuildName then
			killFrame.PlayerGuild:SetText(string.format("|cFFe9e900<%s>", unitInfo.GuildName));
			killFrame.PlayerGuild:SetAlpha(1)
		else
			killFrame.PlayerGuild:SetText("|cFFCCCCCCno guild");
			killFrame.PlayerGuild:SetAlpha(.5)
		end			
				
		killFrame.PlayerLevel:SetText(string.format("%s %s %s |cFF%s%s", nvl(nilIf(nvl(kill.Level,unitInfo.Level),-1), "??"), nvl(genders[unitInfo.Sex],""), nvl(unitInfo.Race,""), classColors[unitInfo.Class], unitInfo.Class):gsub("%s+", " "));
		killFrame.PlayerLevel:Show();
		killFrame.PlayerLevel:SetAlpha(1)
		
		killFrame.texture:SetTexture(unpack(classFrameColors[unitInfo.Class]));
		
	else -- no extended info
	
		killFrame.PlayerName:SetText(string.format("|cFFCCCCCC%s", name));	
		
		killFrame.PlayerGuild:SetText("|cFFCCCCCCunknown guild");
		killFrame.PlayerGuild:SetAlpha(.5)
		
		killFrame.PlayerLevel:SetText("|cFFCCCCCCunknown level, gender, race, & class");
		killFrame.PlayerLevel:SetAlpha(.5)
						
		killFrame.ClassIcon:SetTexture([[Interface\Icons\INV_Misc_QuestionMark]]);
		killFrame.ClassIcon:SetTexCoord(0,1,0,1);			
		
		killFrame.texture:SetTexture(0,0,0,.5);
		
	end		
	
	killFrame.KillTime:SetText(date("%m/%d/%y %I:%M%p", kill.Time));

	if kill.Location.Zone2 and kill.Location.Zone2 ~= kill.Location.Zone then
		killFrame.Zone2:SetText(kill.Location.Zone2);				
	else	
		killFrame.Zone2:SetText(string.format("%.1f, %.1f", kill.Location.X, kill.Location.Y));				
	end

	killFrame.Zone:SetText(kill.Location.Zone);		
	
	if unitInfo.Kills then
		killFrame.TimesKilled:SetText(string.format("Total kills: %d", unitInfo.Kills));
	else
		killFrame.TimesKilled:SetText("|cFFCCCCCCTotal kills: unknown");		
	end
		
	local spellName = getFatalSpellName(kill.SpellID)
	local damageString = ""
	
	if kill.Damage then
		if kill.Damage >= 1000000 then
			damageString = string.format("%.1fm", math.round(kill.Damage / 1000000))
		elseif kill.Damage >= 1000 then
			damageString = string.format("%dk", math.round(kill.Damage / 1000))
		else
			damageString = tostring(kill.Damage)
		end
	end
			
	if spellName then
	
		if kill.Tick then
			spellName = spellName .. ' tick'
		end
		
		if kill.Crit then
			spellName = 'crit ' .. spellName
		end
	
		if kill.SpellID < -1 or kill.SpellID == 188520 then -- environmental or Fel Sludge
		
			killFrame.KilledBy:SetText(string.format("Died from %s", spellName))		
	
		elseif kill.MyKB or kill.AttackerGUID == playerGUID then
		
			if kill.Damage then
				killFrame.KilledBy:SetText(string.format("Died to my %s %s", damageString, spellName))
			else
				killFrame.KilledBy:SetText(string.format("Died to my %s", spellName))
			end
		
		elseif kill.AttackerGUID then
		
			if kill.AttackerGUID == kill.GUID then
			
				killFrame.KilledBy:SetText(string.format("Died to %s own %s", iif(unitInfo and unitInfo.Sex == 3, "her", "his"), spellName))				
			
			elseif info[kill.AttackerGUID] then							
			
				if kill.Damage then
					killFrame.KilledBy:SetText(string.format("Died to %s's %s %s", info[kill.AttackerGUID].Name:gmatch("[^-]+")(), damageString, spellName))									
				else
					killFrame.KilledBy:SetText(string.format("Died to %s's %s", info[kill.AttackerGUID].Name:gmatch("[^-]+")(), spellName))				
				end

			else
			
				killFrame.KilledBy:SetText("Died to Unknown.");			
				
			end
						
		else			
	
			killFrame.KilledBy:SetText("Died to Unknown (assist)")
		end
	
	else
	
		if kill.MyKB or kill.AttackerGUID == playerGUID then
		
			killFrame.KilledBy:SetText(string.format("Died to me"))
		
		elseif kill.AttackerGUID then
	
			if kill.AttackerGUID == kill.GUID then
			
				killFrame.KilledBy:SetText("Committed suicide")				
			
			elseif info[kill.AttackerGUID] then
			
				killFrame.KilledBy:SetText(string.format("Died to %s", info[kill.AttackerGUID].Name:gmatch("[^-]+")()))				
				
			else
			
				killFrame.KilledBy:SetText("Died to Unknown.");
			
			end
						
		else			
	
			killFrame.KilledBy:SetText("Died to Unknown (assist)")
			
		end	
	
	end

	killFrame.KilledBy:SetWidth(204 - killFrame.TimesKilled:GetStringWidth())

end

local function CreateKillFrame(i)	
		
	local killFrame = CreateFrame("FRAME", nil, frame);
	frame["KILLFRAME" .. i] = killFrame;
	killFrame:SetWidth(210);	
	killFrame:SetHeight(47); --37	

	local bg = killFrame:CreateTexture(nil, "BACKGROUND");
	bg:SetTexture(0,0,0,.5);
	bg:SetAllPoints(killFrame);
	killFrame.texture = bg;

	killFrame.ContentFrame = CreateFrame("FRAME",nil,killFrame);	
	killFrame.ContentFrame:SetWidth(200);	
	killFrame.ContentFrame:SetHeight(27);		
	killFrame.ContentFrame:SetPoint("TOPLEFT", killFrame, "TOPLEFT", 5, -5);		

	killFrame.ClassIcon = killFrame.ContentFrame:CreateTexture();
	killFrame.ClassIcon:SetHeight(8);
	killFrame.ClassIcon:SetWidth(8);
	killFrame.ClassIcon:SetTexture([[Interface\Glues\CharacterCreate\UI-CharacterCreate-Classes]]);
	killFrame.ClassIcon:SetPoint("TOPLEFT", killFrame.ContentFrame, "TOPLEFT", 1, 0);

	killFrame.PlayerName = killFrame.ContentFrame:CreateFontString();
	killFrame.PlayerName:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE");		
	killFrame.PlayerName:SetWidth(123);
	killFrame.PlayerName:SetWordWrap(false);	
	killFrame.PlayerName:SetJustifyH("left");
	killFrame.PlayerName:SetPoint("LEFT", killFrame.ClassIcon, "RIGHT", 2, 0);
		
	killFrame.PlayerGuild = killFrame.ContentFrame:CreateFontString();
	killFrame.PlayerGuild:SetFont("Fonts\\ARIALN.TTF", 8, "OUTLINE");
	killFrame.PlayerGuild:SetPoint("LEFT", killFrame.ContentFrame, "LEFT");			
	
	killFrame.PlayerLevel = killFrame.ContentFrame:CreateFontString(); 	
	killFrame.PlayerLevel:SetPoint("BOTTOMLEFT", killFrame.ContentFrame, "BOTTOMLEFT");							
	killFrame.PlayerLevel:SetFont("Fonts\\ARIALN.TTF", 8, "OUTLINE");
				
	killFrame.KillTime = killFrame.ContentFrame:CreateFontString(); 	
	killFrame.KillTime:SetPoint("TOPRIGHT", killFrame.ContentFrame, "TOPRIGHT");							
	killFrame.KillTime:SetFont("Fonts\\ARIALN.TTF", 8, "OUTLINE");		
	
	killFrame.Zone2 = killFrame.ContentFrame:CreateFontString(); 	
	killFrame.Zone2:SetPoint("RIGHT", killFrame.ContentFrame, "RIGHT");							
	killFrame.Zone2:SetFont("Fonts\\ARIALN.TTF", 8, "OUTLINE");
	
	killFrame.Zone = killFrame.ContentFrame:CreateFontString(); 	
	killFrame.Zone:SetPoint("BOTTOMRIGHT", killFrame.ContentFrame, "BOTTOMRIGHT");							
	killFrame.Zone:SetFont("Fonts\\ARIALN.TTF", 8, "OUTLINE");	
	
	killFrame.KilledBy = killFrame.ContentFrame:CreateFontString();
	killFrame.KilledBy:SetPoint("BOTTOMLEFT", killFrame.ContentFrame, "BOTTOMLEFT", 0, -10);		
	killFrame.KilledBy:SetFont("Fonts\\ARIALN.TTF", 8, "OUTLINE");	
	killFrame.KilledBy:SetWordWrap(false) 	
	killFrame.KilledBy:SetJustifyH("left");	
	
	
	killFrame.TimesKilled = killFrame.ContentFrame:CreateFontString();
	killFrame.TimesKilled:SetFont("Fonts\\ARIALN.TTF", 8, "OUTLINE");
	killFrame.TimesKilled:SetPoint("BOTTOMRIGHT", killFrame.ContentFrame, "BOTTOMRIGHT", 0, -10);				

	return killFrame;
	
end

local function UpdateKillFrames(n, newKill)
		
	local history, info, settings = PKTrackerVars.History, PKTrackerVars.Info, PKTrackerVars.Settings		
	
	local killFrame, count, nHistory, nMax;			
		
	nHistory = #history;
	nMax = nHistory - nHistory % 7 + iif(nHistory % 7 == 0, -6, 1);		
			
	n = nvl(n, nHistory);

	count = 0;
		
	n = n - n % 7 + 1;
		
	if n > nMax then
	
		n = nMax;
		currentRecord = n;
	
	elseif n > 0 and nHistory > 0 then
	
		if currentRecord ~= n then
		
			currentRecord = n;
			if settings.Sound and not newKill then
				PlaySound("igAbiliityPageTurn");
			end
			
		end
	
	else
	
		n = currentRecord;
				
	end

	for i = 1, 7 do
		
		killFrame = frame["KILLFRAME" .. i];
						
		if n <= nHistory and n > 0 then
		
			UpdateKillFrame(killFrame, history[n], n)			
			killFrame.ContentFrame:Show();		
			if newKill and n == nHistory and settings.Sound then
				PlaySound("igAbilityIconDrop"); -- igPVPUpdate
			end			
			n = n + 1;
			count = count + 1;			
		else
		
			killFrame.texture:SetTexture(0,0,0,.5);
			killFrame.ContentFrame:Hide();
		
		end		
		
	end	
	
	if nHistory > 0 then		
		local nPages = math.ceil(nHistory / 7);
		frame.PageText:SetText(string.format("Page %d of %d", math.ceil(currentRecord / nHistory * nPages), nPages));
	else
		frame.PageText:SetText("No PvP Kills recorded.");
	end
					
	if currentRecord > 1 then		
		frame.Back:SetButtonState("NORMAL")
		frame.Back:Enable();		
	else	
		frame.Back:SetButtonState("PUSHED")
		frame.Back:Disable();		
	end
	
	if currentRecord < nMax and nHistory > 0 then
		frame.Next:SetButtonState("NORMAL")
		frame.Next:Enable();		
	else
		frame.Next:SetButtonState("PUSHED")
		frame.Next:Disable();		
	end
	
	if frame.Slider:GetValue() ~= currentRecord then
		frame.Slider:SetValue(currentRecord) 
	end
	
end

local function CreateNavButton(text, clickHandler)

	local button = CreateFrame("Button",nil,frame);
	button:SetWidth(50);
	button:SetHeight(20);
	button:SetText(text);
	button:SetNormalFontObject("GameFontNormal");
	
	local ntex = button:CreateTexture();
	ntex:SetTexture("Interface/Buttons/UI-Panel-Button-Up");
	ntex:SetTexCoord(0, 0.625, 0, 0.6875);
	ntex:SetAllPoints();
	button:SetNormalTexture(ntex);
	
	local htex = button:CreateTexture();
	htex:SetTexture("Interface/Buttons/UI-Panel-Button-Highlight");
	htex:SetTexCoord(0, 0.625, 0, 0.6875);
	htex:SetAllPoints();
	button:SetHighlightTexture(htex);
	
	local ptex = button:CreateTexture();
	ptex:SetTexture("Interface/Buttons/UI-Panel-Button-Down");
	ptex:SetTexCoord(0, 0.625, 0, 0.6875);
	ptex:SetAllPoints();
	button:SetPushedTexture(ptex);
	
	button:SetScript("OnClick", clickHandler); 
	button:SetScale(.75);
	
	return button;

end

local function CreateKillFrames()

	local settings = PKTrackerVars.Settings

	local anchor = frame;				
	local n = 1;

	frame:SetFrameStrata("BACKGROUND");
	frame:Show();
	frame:SetWidth(210);
	frame:SetHeight(346);	
	if settings.Scale then
		frame:SetScale(settings.Scale)
	end	
	
	frame:SetPoint(nvl(settings.point,"LEFT"), nvl(settings.relativeTo, "UIParent"), nvl(settings.relativePoint, "LEFT"), nvl(settings["x-offset"], 5), nvl(settings["y-offset"], 0));
	
	frame.PageText = frame:CreateFontString("TOP"); 	
	frame.PageText:SetPoint("TOP", frame, "TOP", 0, 6);							
	frame.PageText:SetFont("Fonts\\ARIALN.TTF", 8, "OUTLINE");	
	
	frame.Back = CreateNavButton("Older", function(self, e, ...)
		UpdateKillFrames(currentRecord - 7);
	end);
	frame.Back:SetPoint("TOPLEFT", frame, "TOPLEFT");		
	
	frame.Next = CreateNavButton("Newer", function(self, e, ...)
		UpdateKillFrames(currentRecord + 7);
	end);
	frame.Next:SetPoint("TOPRIGHT", frame, "TOPRIGHT");	
		
	for i = 1, 7 do

		local f = CreateKillFrame(i);
		if i == 1 then
			f:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -16);
		else
			f:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -1);
		end
		anchor = f;		
		
	end	
		
	frame.Slider = CreateFrame("Slider", "PKTracker_Slider", frame, "OptionsSliderTemplate");	
	frame.Slider:SetPoint("TOP", frame, "TOP", 0, 0);
	frame.Slider:SetWidth(130);
	frame.Slider:SetValueStep(1);
	_G["PKTracker_SliderLow"]:SetText("");
	_G["PKTracker_SliderHigh"]:SetText("");
	_G["PKTracker_SliderText"]:SetText("");
	frame.Slider:SetScript("OnValueChanged",  function(self, value) 			    				
		UpdateKillFrames(value)		
	end)
	UpdateSlider()
	
end

local function UpdateKillFrameUnitInfo(unitInfo)

	local history = PKTrackerVars.History

	for i = currentRecord, math.min(currentRecord + 6, #history) do
	
		if history[i] and history[i].GUID == unitInfo.GUID then
			UpdateKillFrames(currentRecord);
			break
		end
	
	end

end

local function UpdateUnit(unitId)

	local info = PKTrackerVars.Info

	if not UnitExists(unitId) then return end
	
	local unitGUID = UnitGUID(unitId)
	
	if not UnitGUIDIsPlayer(unitGUID) or not UnitIsEnemy(unitId, "player") then return end
	
	local summary = GetUnitSummary(unitId)
	
	local unitInfo = info[unitGUID]
	
	if not unitInfo then
	
		info[unitGUID] = summary
		unitInfo = info[unitGUID]
		
	elseif summary.Name and summary.Name ~= "Unknown" then
			
		unitInfo.Name = nvl(summary.Name,unitInfo.Name)
		unitInfo.Realm = nvl(summary.Realm,unitInfo.Realm)
		unitInfo.Class = nvl(summary.Class,unitInfo.Class)
		unitInfo.Level = nvl(summary.Level,unitInfo.Level)
		unitInfo.Race = nvl(summary.Race,unitInfo.Race)
		unitInfo.GuildName = nvl(summary.GuildName,unitInfo.GuildName)
		unitInfo.Time = nvl(summary.Time,unitInfo.Time)
	
	end
	
	UpdateKillFrameUnitInfo(unitInfo)
					
end

local function AggregateKills()
        
    AddChatMessage("aggregating kills...")
    
    local history, info, settings = PKTrackerVars.History, PKTrackerVars.Info, PKTrackerVars.Settings
	
	-- set flag
	settings.KillsAggregated = true
		
	local kill, unitInfo
	
	-- wipe out current totals, if any
	for k,v in pairs(info) do	
		v.Kills = nil
	end
	
	-- recalculate totals
	for i = 1, #history do
	
		kill = history[i]
		
		unitInfo = info[kill.GUID]
		
		if unitInfo then
								
			if not unitInfo.Kills then
				
				unitInfo.Kills = 1				
				
			else
			
				unitInfo.Kills = unitInfo.Kills + 1
			
			end
		
		end
	
	end
	
end

local function InitializeSavedVariables()		
	
	if not PKTrackerVars then
				
		PKTrackerVars = {}

		-- fix some variable name collisions with other addons, i.e.: history, info, settings
				
		if history then
			--determine if the history variable is ours				
			local h = history[1]
			
			if h and h.GUID and h.Time and h.Location then
			
				-- add history to the PKTrackerVars object
				PKTrackerVars.History = history		
				-- wipe out the old history object
				history = nil
			
			end				
		
		end
		
		if not PKTrackerVars.History then
			
			PKTrackerVars.History = {}
			
		end
		
		if info then
			-- determine if the info variable is ours
			for k,v in pairs(info) do 					
				
				if v and v.GUID and v.Time then
					
					-- add info to the PKTrackerVars object
					PKTrackerVars.Info = info
					
					-- wipe out the old history object
					info = nil
					
				end					
				
				break
			end				
		
		end
		
		if not PKTrackerVars.Info then
			
			PKTrackerVars.Info = {}
			
		end					
		
		if settings then
		
			-- determine if the settings variable is ours
			if settings.KillsAggregated ~= nil then
			
				-- add settings to the PKTrackerVars object
				PKTrackerVars.Settings = settings
				
				-- wipe out the old settings object
				settings = nil
			
			end
		
		end
		
		if not PKTrackerVars.Settings then
			
			PKTrackerVars.Settings = {
				Scale = .85,
				Sound = true,
				KillsAggregated = true					
			}
			
		end			
				
	end
	
	if PKTrackerVars.Settings.Sound == nil then
		PKTrackerVars.Settings.Sound = true;
	end
	
	if not PKTrackerVars.Settings.KillsAggregated then
		AggregateKills()
	end	

end


events.ADDON_LOADED = function(...)	

	if select(1, ...) == "PKTracker" then	
		
		frame:UnregisterEvent("ADDON_LOADED");							

		AddChatMessage(string.format(" version %s loaded.", version))
		
		InitializeSavedVariables()
		
		WipeInfo();
		currentRecord = #PKTrackerVars.History;			
		CreateKillFrames();
		
		if PKTrackerVars.Settings.Hide then
			frame:Hide();					
		end			
	
	end

end

events.PLAYER_ENTER_COMBAT = function(...)
	
	combat = true
	
	frame:SetScript("OnUpdate", nil)
	
end

events.PLAYER_LEAVE_COMBAT = function(...)
    
    local history, info, settings = PKTrackerVars.History, PKTrackerVars.Info, PKTrackerVars.Settings	
    
    combat = false      
    
    leftCombat = 0
    
	frame:SetScript("OnUpdate", function(self, elapsed)		
	
		leftCombat = leftCombat + elapsed
	
		if leftCombat >= 20 then -- clear combatants 20 seconds after leaving combat			
		
			frame:SetScript("OnUpdate", nil)
	
			for key in pairs(combatants) do
						
				combatants[key] = nil;
				
				if settings.debugging then
					AddDebugChatMessage(string.format("Removed combatant: %s", key))		
				end				
			
			end
			
		end
	 
	end);           
   
end

events.COMBAT_LOG_EVENT_UNFILTERED = function (timestamp, event, hideCaster, sourceGUID, sourceName, sourceFlags, sourceFlags2, destGUID, destName, destFlags, destFlags2,	...)
   
	local history, info, settings = PKTrackerVars.History, PKTrackerVars.Info, PKTrackerVars.Settings	
   
	local _,
	spellId,	
	spellName,
	spellSchool,
	amount,
	overkill,
	environment,
	critical,
	tick;
	
	local combatant = combatants[destGUID]
	
	local isHostilePlayer = IsHostilePlayer(destFlags)
		
	if not combatant and not isHostilePlayer then
	
		return
	
	end			
	
	if event == "UNIT_DIED" and combatant and combatant.Dead then			
			
		if settings.debugging then
			AddDebugChatMessage(string.format("event: %s, AttackerGUID:%s, AttackerName: %s, SpellID: %s", tostring(event), tostring(combatant.AttackerGUID), tostring(combatant.AttackerName), tostring(combatant.SpellID)))		
		end
						
		local x, y = GetPlayerMapPosition("player");
					
		local targetInfo = info[destGUID]
					
		if not targetInfo then
		
			targetInfo = {
				GUID = destGUID,
				Name = destName,
				Kills = 1,
				Time = time()
			}
			
			info[destGUID] = targetInfo		
			
		elseif targetInfo.Kills then
		
			targetInfo.Kills = targetInfo.Kills + 1
			
		else
			
			targetInfo.Kills = 1
		
		end				
		
		if combatant.AttackerGUID and combatant.AttackerGUID ~= playerGUID and not info[combatant.AttackerGUID] then
		
			info[combatant.AttackerGUID] = {
				GUID = combatant.AttackerGUID,
				Name = combatant.AttackerName,
				Keep = true
			}
		
		end					
		
		local kill = { 
			GUID = destGUID,
			Level = targetInfo.Level,
			Time = timestamp,
			Location = {
				Zone = GetZoneText("player"),
				Zone2 = GetMinimapZoneText(),
				X = x * 100,
				Y = y * 100
			},
			AttackerGUID = combatant.AttackerGUID,
			SpellID = combatant.SpellID,
			Damage = combatant.Damage,
			Tick = combatant.Tick,
			Crit = combatant.Crit,
		};							
						
		targetInfo.Keep = true		
		table.insert(history, kill);		
		UpdateKillFrames(#history, true);	
		UpdateSlider();		
		
		combatants[destGUID] = nil			

		if settings.debugging then
			AddDebugChatMessage(string.format("Removed combatant: %s", destGUID))		
		end					
	
	elseif event == "PARTY_KILL" and isHostilePlayer then			
		
		if settings.debugging then
			AddDebugChatMessage(string.format("event: %s, sourceName: %s, destName: %s", tostring(event), tostring(sourceName), tostring(destName)))
		end
		
		if not combatant then
		
			combatants[destGUID] = {
				GUID = destGUID				
			}
			
			combatant = combatants[destGUID]
		
		end		
	
		combatant.Dead = true
		combatant.AttackerGUID = sourceGUID
		combatant.AttackerName = sourceName		
	
	elseif damageEvents[event] and isHostilePlayer then
	
		if event == "SWING_DAMAGE" then
			amount, overkill, _, _, _, _, critical = ...	
			spellId = -1			
			spellName = "melee attack"
		elseif event == "ENVIRONMENTAL_DAMAGE" then
			environment, amount, overkill, _, _, _, _, critical = ...
			spellId = damageTypeMapping[environment]			
		else 
			spellId, spellName, spellSchool, amount, overkill, _, _, _, _, critical = ...
		end
		
		if event == "SPELL_PERIODIC_DAMAGE" then
			tick = true
		end
		
		critical = nilIf(critical, false)
	
		if (combatant or sourceGUID == playerGUID or teammates[sourceGUID]) then
								
			if settings.debugging then
				AddDebugChatMessage(string.format("event: %s, sourceName: %s, spellId: %s, spellName: %s, overkill: %s, tick: %s, crit: %s", tostring(event), tostring(sourceName), tostring(spellId), tostring(spellName), nvl(overkill), tostring(tick), tostring(critical)))
			end
				
			-- overkill killing blow				
			if not combatant then
				
				combatants[destGUID] = {
					GUID = destGUID
				}		
				
				combatant = combatants[destGUID]		
						
			end
						
			combatant.Dead = overkill and overkill > 0
			combatant.Damage = amount
			combatant.Tick = tick
			combatant.Crit = critical			
			combatant.AttackerGUID = sourceGUID
			combatant.AttackerName = sourceName					
			combatant.SpellID = spellId	

		elseif not combatant and (sourceGUID == playerGUID or teammates[sourceGUID]) then
		
			if settings.debugging then
				AddDebugChatMessage(string.format("event: %s, sourceName: %s, spellId: %s, spellName: %s, overkill: %s, tick: %s, crit: %s", tostring(event), tostring(sourceName), tostring(spellId), tostring(spellName), tostring(overkill), tostring(tick), tostring(critical)))
			end
		
			-- Add unit GUID to combatants
			combatants[destGUID] = {
				GUID = destGUID,						
				AttackerGUID = sourceGUID,
				AttackerName = sourceName,					
				SpellID = spellId,
				Dead = overkill and overkill > 0,
				Damage = amount,
				Tick = tick,
				Crit = critical,
			}						
		
		end
		
	elseif event == "SPELL_AURA_APPLIED" and combatant then
			
		spellId, spellName, spellSchool = ...			
			
		if settings.debugging then
			AddDebugChatMessage(string.format("event: SPELL_AURA_APPLIED, spellId: %s, spellName: %s, destName: %s", tostring(spellId), tostring(spellName), tostring(destName)))
		end							
					
		-- priest Spirit of Redemption			
		if spellId == 27827 then			
			combatant.Dead = true						
			events.COMBAT_LOG_EVENT_UNFILTERED(timestamp, "UNIT_DIED", hideCaster, sourceGUID, sourceName, sourceFlags, sourceFlags2, destGUID, destName, destFlags, destFlags2)						
		end		
	
	elseif event == "SPELL_INSTAKILL" and combatant then
	
		spellId, spellName, spellSchool = ...	
	
		-- stupid purgatory...		
						
		if settings.debugging then
			AddDebugChatMessage(string.format("event: %s, sourceName: %s, spellId: %s, spellName: %s", tostring(event), tostring(sourceName), tostring(spellId), tostring(spellName)))
		end
		
		-- Allow UNIT_DIED to pick up the kill if it wasn't a PARTY_KILL			
		combatant.Dead = true
		combatant.Damage = nil
		combatant.Tick = nil
		combatant.Crit = nil			
		combatant.AttackerGUID = sourceGUID
		combatant.AttackerName = sourceName					
		combatant.SpellID = spellId										
			
	end
   
end

events.UNIT_TARGET = function (unitId)
     
	UpdateUnit(unitId .. "target")	
   
end

events.UNIT_NAME_UPDATE = function(unitId)
	if unitId == "player" then
		UpdatePlayerName()
	else
		UpdateUnit(unitId)
	end
end

events.OnTooltipCleared = function(self)
	tooltipSet = false
end

events.OnTooltipSetUnit = function(self)
	if tooltipSet then return end
	
	local history, info, settings = PKTrackerVars.History, PKTrackerVars.Info, PKTrackerVars.Settings	
	
	tooltipSet = true	
	
	local name, unit = GameTooltip:GetUnit()
	
	if not UnitExists(unit) or not UnitIsEnemy("player", unit) then return end
	
	local guid = UnitGUID(unit)
	
	if guid and guid:match("Player--") then
		
		local unitInfo = info[guid]
		
		if not unitInfo then 
		
			GameTooltip:AddLine("Killed 0 times.")										
		
		elseif unitInfo.Kills == 1 then
		
			GameTooltip:AddLine("Killed 1 time.")										
		
		else		
		
			GameTooltip:AddLine(string.format("Killed %d times.", unitInfo.Kills))			
		
		end		
		
	end	
end

local function InUntrackedArea()
	local pvpType, isFFA, faction = GetZonePVPInfo();
		
	if pvpType == "combat" or IsInInstance() then
		return true
	end
	
	local zone, subZone = GetZoneText("player"), GetMinimapZoneText()
	
	-- The PvP area of Ashran apparently likes to sometimes report as "contested" rather than "combat"...
	if zone == "Ashran" and not (subZone == "Stormshield" or subZone == "Warspear") then
		return true
	end
	
	return false

end

local function OnZoneSwapped()

	local history, info, settings = PKTrackerVars.History, PKTrackerVars.Info, PKTrackerVars.Settings	

	if InUntrackedArea() then
		if tracking then				
			AddChatMessage("has paused tracking.")			
		end
		tracking = false
		frame:Hide()
		frame:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
		frame:UnregisterEvent("UNIT_TARGET");
		frame:UnregisterEvent("UNIT_NAME_UPDATE");		
		frame:UnregisterEvent("GROUP_ROSTER_UPDATE");				
		frame:UnregisterEvent("PLAYER_ENTER_COMBAT");
		frame:UnregisterEvent("PLAYER_LEAVE_COMBAT");	
		-- GameTooltip:SetScript("OnTooltipCleared", nil)
		-- GameTooltip:SetScript("OnTooltipSetUnit", nil)			
	else		
		if not tracking then
			AddChatMessage("has resumed tracking.")
		end
		tracking = true
		if settings and not settings.Hide then
			frame:Show()
		end
		frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
		frame:RegisterEvent("UNIT_TARGET");
		frame:RegisterEvent("UNIT_NAME_UPDATE");		
		frame:RegisterEvent("GROUP_ROSTER_UPDATE");		
		frame:RegisterEvent("PLAYER_ENTER_COMBAT");
		frame:RegisterEvent("PLAYER_LEAVE_COMBAT");			
		-- GameTooltip:SetScript("OnTooltipCleared", events.OnTooltipCleared)
		-- GameTooltip:SetScript("OnTooltipSetUnit", events.OnTooltipSetUnit)		
		-- tooltipSet = false
	end
end

events.PLAYER_ENTERING_WORLD = function (...)
	playerGUID = UnitGUID("player");
	UpdatePlayerName()		
	UpdateKillFrames(currentRecord)
	OnZoneSwapped();   
end

events.ZONE_CHANGED_NEW_AREA = function (...)
	OnZoneSwapped();
end

events.custom = {}

events.custom.UNIT_UPDATE = function (unitGUID,	name, realm, class, level, race, sex, guildName, time)

	if not infoRequests[unitGUID] then
	
		return
	
	end
	
	local history, info, settings = PKTrackerVars.History, PKTrackerVars.Info, PKTrackerVars.Settings	
	
	infoRequests[unitGUID] = nil

	realm = nilIf(realm, "")
	class = nilIf(class, "")
	level = nilIf(level, "")
	race = nilIf(race, "")
	sex = nilIf(sex, "")
	guildName = nilIf(guildName, "")			
	time = nilIf(time, "")
	
	if level then
		level = tonumber(level, 10)
	end

	if sex then
		sex = tonumber(sex, 10)
	end
	
	if time then
		time = tonumber(time, 10)
	end	
	
	local unitInfo = info[unitGUID]
	
	if not unitInfo then
	
		info[unitGUID] = { 
			GUID = unitGUID,
			Time = time()
		}
		
		unitInfo = info[unitGUID]		
		
	end
	
	unitInfo.Name = nvl(name,unitInfo.Name)
	unitInfo.Realm = nvl(realm,unitInfo.Realm)
	unitInfo.Class = nvl(class,unitInfo.Class)
	unitInfo.Level = nvl(level,unitInfo.Level)
	unitInfo.Sex = nvl(sex,unitInfo.Sex)
	unitInfo.GuildName = nvl(guildName,unitInfo.GuildName)
	unitInfo.Time = nvl(time,unitInfo.Time)
	
	UpdateKillFrameUnitInfo(unitInfo)	
	
end

events.custom.UNIT_INFO_REQUEST = function (GUID, requestor)
	
	if infoRequests[unitGUID] then
	
		-- let's not loop ourselves...
	
		return
	
	end		

	local info = PKTrackerVars.Info
	
	local unitInfo = info[GUID];
		
	if unitInfo and unitInfo.Name ~= "Unknown" then
		
		SendUnitUpdate(unitInfo)
		
	end
	
end

events.CHAT_MSG_ADDON = function(prefix, message, type, sender)			
	
	if prefix ~= "PKTRACKER" then
		return
	end
	
	local eventName = message:match("^[A-Z_]+")	
	
	local handler = events.custom[eventName]		
		
	if handler then				
		handler(unpack(Split(message:sub(#eventName + 2),",")))	
	end
	
end

events.GROUP_ROSTER_UPDATE = function(...)     
   
   local n, prefix, guid
   
   n = GetNumGroupMembers()	
   
   if n == 0 then
   
		for k,v in pairs(teammates) do
		
			teammates[k] = nil
			
		end

		return   
	
	end
	
	prefix = iif(UnitInRaid("player"), "raid", "party")
   
	for i = 1, n do
	
		guid = UnitGUID(string.format("%s%d", prefix, i))
		
		if guid then	
			
			-- add players
			teammates[guid] = true
			
			guid = UnitGUID(string.format("%s%dpet", prefix, i))
			
			if guid then
			
				-- add pets
				teammates[guid] = true			
				
			end	
						
			guid = UnitGUID(string.format("%s%dvehicle", prefix, i))
			
			if guid then
			
				-- add vehicles?
				teammates[guid] = true			
				
			end				
							
		end 
		  
	end   
   
end

RegisterAddonMessagePrefix("PKTRACKER");
frame:RegisterEvent("ADDON_LOADED");
frame:RegisterEvent("CHAT_MSG_ADDON");
frame:RegisterEvent("PLAYER_ENTERING_WORLD");
frame:RegisterEvent("ZONE_CHANGED_NEW_AREA");

frame:SetScript("OnEvent", function(self, event, ...)
	events[event](...);
end);

SLASH_PKTtracker1,SLASH_PKTtracker2 = "/pkt", "/pktracker";
SlashCmdList.PKTtracker = function(msg, editbox)

	local history, info, settings = PKTrackerVars.History, PKTrackerVars.Info, PKTrackerVars.Settings	

	if msg == "hide" then
		settings.Hide = true;
		frame:Hide();
	elseif msg == "info" then
		local maxLevelKills = 0
		local killsToday = 0
		local maxLevelKillsToday = 0
		local today = date("*t", time())
		local killedToday
		
		
		for i = 1, #history do
			
			killedToday = SameDay(today, date("*t", history[i].Time))
		
			if history[i].Level == 100 then
				maxLevelKills = maxLevelKills + 1
				
				if killedToday then
				
					maxLevelKillsToday = maxLevelKillsToday + 1
				
				end			
				
			end
			
			if killedToday then
			
				killsToday = killsToday + 1
			
			end
			
		end	
		AddChatMessage(string.format("%d total kills; %d level 100s. %d kills today; %d level 100s.", #history, maxLevelKills, killsToday, maxLevelKillsToday));
	elseif msg == "resetdata" then		
		for key in pairs(history) do			
			history[key] = nil;			
		end		
		for key in pairs(info) do			
			info[key] = nil;			
		end				
		for key in pairs(combatants) do			
			combatants[key] = nil;			
		end				
		UpdateKillFrames();
		AddChatMessage("data reset.");
	elseif msg == "debug" then	
		settings.debugging = not settings.debugging
		AddChatMessage("debugging " .. iif(settings.debugging, "enabled", "disabled"))	
	elseif msg == "resetposition" then				
		settings.point = "LEFT"
		settings.relativeTo = "UIParent"			
		settings.relativePoint = "LEFT"
		settings["x-offset"] = 5;						
		settings["y-offset"] = 0;						
		frame:SetPoint("LEFT","UIParent","LEFT",5,0);
		AddChatMessage("position reset.");
	elseif msg == "show" then
		settings.Hide = nil;
		frame:Show();
	elseif msg == "sound" then
		settings.Sound = not settings.Sound;
		AddChatMessage(iif(settings.Sound, "sound enabled.", "sound disabled."));				
	elseif msg:find("scale") then
	    local n = msg:match("%d*%.?%d+")	    
	    if n then
			local scale = tonumber(n,10)			
			frame:SetScale(scale);		
			settings.Scale = scale;
		else
			AddChatMessage(string.format("current scale: %f.", settings.Scale));
		end	
	elseif msg:find("x-offset") then
	    local n = msg:match("%d*%.?%d+")	    
	    if n then
			settings["x-offset"] = tonumber(n,10);						
			frame:SetPoint(nvl(settings.point,"LEFT"), nvl(settings.relativeTo, "UIParent"), nvl(settings.relativePoint, "LEFT"), n, nvl(settings["y-offset"], 0));
		else
			AddChatMessage(string.format("current x-offset: %f.", settings["x-offset"]));
		end						
	elseif msg:find("y-offset") then
	    local n = msg:match("%d*%.?%d+")	    
	    if n then
			settings["y-offset"] = tonumber(n,10);			
			frame:SetPoint(nvl(settings.point,"LEFT"), nvl(settings.relativeTo, "UIParent"), nvl(settings.relativePoint, "LEFT"), nvl(settings["x-offset"], 5), n);
		else
			AddChatMessage(string.format("current x-offset: %f.", settings["y-offset"]));			
		end				
	elseif msg:find("unlock") then	
		frame:EnableMouse(true)
		frame:SetMovable(true)
		frame:RegisterForDrag("LeftButton");
		frame:SetScript("OnDragStart", function()
			frame:StartMoving();
		end);		
		frame:SetScript("OnDragStop", function()
			frame:StopMovingOrSizing();			
			settings.point, settings.relativeTo, settings.relativePoint, settings["x-offset"], settings["y-offset"] = frame:GetPoint()
		end);	
		AddChatMessage("unlocked; drag to move.");
	elseif msg:find("lock") then											
		frame:EnableMouse(false)
		frame:SetMovable(false)
		frame:RegisterForDrag();
		frame:SetScript("OnDragStart", nil);		
		frame:SetScript("OnDragStop", nil);	
		AddChatMessage("locked.");
	else
		AddChatMessage("commands:\n/pkt hide\n/pkt info\n/pkt resetdata\n/pkt resetposition\n/pkt show\n/pkt sound\n/pkt lock\n/pkt unlock\n/pkt scale .85\n/pkt x-offset 5\n/pkt y-offset 100\n/pkt debug");
	end
end