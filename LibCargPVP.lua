local lib = LibStub:NewLibrary("LibCargPVP", 4)
if(not lib) then return end

-- Index following GetNumBattlegroundTypes()
local data = {
	{
		name = "Alterac Valley",
		abbr = "Alterac",
		achTotal = 53,
		achWon = 49,
		itemID = 20560,
		maxBonus = 29,
		minBonus = 0,
		maxBonusHoliday = 33,
		minBonusHoliday = 4,
	},{
		name = "Warsong Gulch",
		abbr = "Warsong",
		achTotal = 52,
		achWon = 105,
		itemID = 20558,
		maxBonus = 9,
		minBonus = 2,
		maxBonusHoliday = 13,
		minBonusHoliday = 4,
	},{
		name = "Arathi Basin",
		abbr = "Arathi",
		achTotal = 55,
		achWon = 51,
		itemID = 20559,
		maxBonus = 9,
		minBonus = 2,
		maxBonusHoliday = 17,
		minBonusHoliday = 4,
	},{
		name = "Eye of the Storm",
		abbr = "EotS",
		achTotal = 54,
		achWon = 50,
		itemID = 29024,
		maxBonus = 9,
		minBonus = 2,
		maxBonusHoliday = 17,
		minBonusHoliday = 4,
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

-- Get the estimated kill honor for your current level
-- the bonus honor system follows the kill honor for equal level

--[[
	function calculated by using these values
	I would like to get the correct formula and not
	just my own approximation :/

	lvl 	kill honor	deviation
	16		2.64		-0.03
	17		2.87		-0.01
	19		3.27		+0.05
	21		3.72		+0.02
	23		4.19		-0.07
	34		5.98		+0.07
	35		6.32		-0.07
	55		15.47		-0.01
	80		62			0
]]
local a = 1.7932e-6
local b = 4.5075e-5
local c = -0.0119991
local d = 0.57618113
local e = -3.8319729
-- Get the estimated kill honor for your current level
function lib.GetKillHonor(lvl)
	local x = lvl or UnitLevel("player")
	return a*x^4 + b*x^3 + c*x^2 + d*x + e
end

-- Get the maximum and minimum experience for one complete battleground round
function lib.GetMinMaxBattlegroundHonor(id, lvl, ignoreHoliday)
	local info = data[id]
	if(not info) then return end

	local honor = lib.GetKillHonor(lvl)
	local min, max
	if(not ignoreHoliday and select(3, GetBattlegroundInfo(id))) then
		min, max = info.minBonusHoliday, info.maxBonusHoliday
	else
		min, max = info.minBonus, info.maxBonus
	end

	return min*honor, max*honor
end

-- Get the average honor gained in one battleground based on win/loss ratio
function lib.GetAverageBattlegroundHonor(id, lvl, ignoreHoliday, assumeEqual)
	local min, max = lib.GetMinMaxBattlegroundHonor(id, lvl, ignoreHoliday)
	if(not min or not max) then return end
	if(assumeEqual) then return (min+max)/2 end

	local win, total = lib.GetBattlegroundWinTotal(id)
	if(total == 0) then	win, total = 0.5, 1 end
	return win/total*max+(1-win/total)*min
end

-- use this to transform bonus honor into experience
lib.XP_FACTOR = 100