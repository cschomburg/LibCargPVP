local lib = LibStub:NewLibrary("LibCargPVP", 5)
if(not lib) then return end

-- Index following GetNumBattlegroundTypes()
-- You have been awared x honor points.
-- You gain x experience.
local data = {
	{
		name = "Alterac Valley",
		abbr = "Alterac",
		achTotal = 53,
		achWon = 49,
		itemID = 20560,
		maxTicks = 29, -- 3 for captain, 4x3 for destroyed towers, 4x1 for graveyards at end, 4x1 for towers at end,
		minTicks = 0, -- 1 for loss
		maxTicksHoliday = 33,
		minTicksHoliday = 4, -- 4 for end,
	},{
		name = "Warsong Gulch",
		abbr = "Warsong",
		achTotal = 52,
		achWon = 105,
		itemID = 20558,
		maxTicks = 9, -- 2 for end, 3*2 for flags, 1 for win
		minTicks = 2, -- 2 for end
		maxTicksHoliday = 13, -- 2x end, 2x win
		minTicksHoliday = 4, -- 2x end
	},{
		name = "Arathi Basin",
		abbr = "Arathi",
		achTotal = 55,
		achWon = 51,
		itemID = 20559,
		maxTicks = 9, -- 2 for end, 6*1 for 260-points-tick, 1 for win
		minTicks = 2, -- 2 for end
		maxTicksHoliday = 17, -- 2x end, 8*1 for 200-points-tick, 
		minTicksHoliday = 4, -- 2x end
	},{
		name = "Eye of the Storm",
		abbr = "EotS",
		achTotal = 54,
		achWon = 50,
		itemID = 29024,
		maxTicks = 9,
		minTicks = 2,
		maxTicksHoliday = 17, --2x end
		minTicksHoliday = 4, -- 2x end
	},{
		name = "Strand of the Ancients",
		abbr = "SotA",
		achTotal = 1549,
		achWon = 1550,
		itemID = 42425,
	},{
		name = "Isle of Conquest",
		abbr = "IoC",
		achTotal = 4096,
		achWon = 4097,
		itemID = 47395,
	},
	[-1] = {
		name = "Wintergrasp",
		abbr = "Wintergrasp",
		itemID = 43589,
	},
}

local dailies = {
	[13428] = 1,	-- Horde AV old
	[13427] = 1,	-- Alliance AV old
	[11340] = 1,	-- Horde AV new
	[11336] = 1,	-- Alliance AV new

	[14183] = 2,	-- Horde WS old
	[14180] = 2,	-- Alliance WS old
	[11342] = 2,	-- Horde WS new
	[11338] = 2,	-- Alliance WS new

	[14181] = 3,	-- Horde AB old
	[14178] = 3,	-- Alliance AB old
	[11339] = 3,	-- Horde AB new
	[11335] = 3,	-- Alliance AB new

	[14182] = 4,	-- Horde EotS old
	[14179] = 4,	-- Alliance EotS old
	[11341] = 4,	-- Horde EotS new
	[11337] = 4,	-- Alliance EotS new

	[13407] = 5,	-- Horde SotA
	[13405] = 5,	-- Alliance SotA

	[14164] = 6,	-- Horde IoC
	[14163] = 6,	-- Alliance IoC
}

--holiday order of the battlegroundIDs
local holidays = {1, 2, 5, 6, 3, 4}

-- Returns percent, win total info by battleground id
function lib.GetBattlegroundWinTotal(id)
	local info = data[id]
	if(not info or not info.achWon or not info.achTotal) then return 0, 0 end
	local total, won = GetStatistic(info.achTotal), GetStatistic(info.achWon)
	if(total == "--") then total = 0 else total = tonumber(total) or 0 end
	if(won == "--") then won = 0 else won = tonumber(won) or 0 end
	return won, total
end

-- Returns mark count and id by battleground id
function lib.GetBattlegroundMarkCount(id, includeBank)
	local info = data[id]
	if(not info) then return end
	return GetItemCount(info.itemID, includeBank), info.itemID
end

-- Returns only the itemID of the mark
function lib.GetBattlegroundMarkID(id)
	return data[id] and data[id].itemID
end

-- Returns the next bg holiday and if it's currently active
function lib.GetBattlegroundHoliday()
	local max = #holidays
	local now = date("*t")
	local week = floor(now.yday/7)+1
	if(now.wday == 3) then week = week +1 end
	week = (week + 2) % max
	week = week > 0 and week or max
	return holidays[week], now.wday > 5 or now.wday < 3
end

-- Returns english full name and abbreviation for the battlegroundID
function lib.GetBattlegroundName(id)
	local info = data[id]
	return info and info.name, info and info.abbr
end

-- Gets your current battleground daily and questID
function lib.GetBattlegroundDaily()
	for i=1, GetNumQuestLogEntries() do
		local link = GetQuestLink(i)
		local id = link and tonumber(link:match("quest:(%d+)"))
		if(id and dailies[id]) then
			return dailies[id], id
		end
	end
end

-- Get the estimated experience tick for your current level
-- it seems to roughly follow the bonus honor (which likely is constant in your battleground range)
-- but has some kind of difficulty factor based on level in it
-- round levels (30, 40, etc) have a very high tick which falls out of the curve

local a = 2.3279-6
local b = -4.725e-5
local c = -6.747e-3
local d = 0.46295607
local e = -3.0124704

-- function calculated by using the table values
-- I would like to get the correct formula and not
-- just my own approximation :/
local xpTicks = setmetatable({
	[16] = 220, [17] = 239,
	[19] = 273,
	[21] = 310,
	[23] = 349, [24] = 368, [25] = 376, [26] = 396, [27] = 415, [28] = 435, [29] = 442,
	[30] = 698, [31] = 492, [32] = 518,
	[34] = 598, [35] = 632, [36] = 673, [37] = 707, [38] = 808,
	[40] = 1235, [41] = 868, [42] = 934, [43] = 967, [44] = 1001, [45] = 1067, [46] = 1101, [47] = 1167,
	[55] = 1547,
	[70] = 3594, [71] = 3877,
	[75] = 4046, [76] = 4079,
	[80] = 6200,
}, {__index = function(self, x) return a*x^4 + b*x^3 + c*x^2 + d*x + e end})

-- Get the estimated bg xp tick for your current level
function lib.GetExperienceTick(lvl)
	return xpTicks[lvl or UnitLevel("player")]
end

-- Get the maximum and minimum experience for one complete battleground round
function lib.GetMinMaxBattlegroundExperience(id, lvl, ignoreHoliday)
	local info = data[id]
	if(not info) then return end

	local honor = lib.GetExperienceTick(lvl)
	local min, max
	if(not ignoreHoliday and select(3, GetBattlegroundInfo(id))) then
		min, max = info.minTicksHoliday, info.maxTicksHoliday
	else
		min, max = info.minTicks, info.maxTicks
	end

	return min and min*honor, max and max*honor
end

-- Get the average experience gained in one battleground based on win/loss ratio
function lib.GetAverageBattlegroundExperience(id, lvl, ignoreHoliday, assumeEqual)
	local min, max = lib.GetMinMaxBattlegroundExperience(id, lvl, ignoreHoliday)
	if(not min or not max) then return end
	if(assumeEqual) then return (min+max)/2 end

	local win, total = lib.GetBattlegroundWinTotal(id)
	if(total == 0) then	win, total = 0.5, 1 end
	return win/total*max+(1-win/total)*min
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function()
	local XP_GAIN, HONOR_GAIN = COMBATLOG_XPGAIN_FIRSTPERSON_UNNAMED:gsub("%%d", "(%%d+)"), COMBATLOG_HONORAWARD:gsub("%%d", "(%%d+)")
	local _addMessage = ChatFrame3.AddMessage
	local foundHonor
	ChatFrame3.AddMessage = function(self, msg, ...)
		if(foundHonor) then
			local xp = msg:match(XP_GAIN)
			if(xp) then
				local text = ("%d xp per %d honor at %d"):format(xp, foundHonor, UnitLevel("player"))
				_ = debug and debug(text)
				print(text)
			end
		end
		foundHonor = msg:match(HONOR_GAIN)
		return _addMessage(self, msg, ...)
	end
end)