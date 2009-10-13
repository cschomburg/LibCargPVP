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
	},{
		name = "Warsong Gulch",
		abbr = "Warsong",
		achTotal = 52,
		achWon = 105,
		itemID = 20558,
		winXP = 9,
		lossXP = 1,
	},{
		name = "Arathi Basin",
		abbr = "Arathi",
		achTotal = 55,
		achWon = 51,
		itemID = 20559,
	},{
		name = "Eye of the Storm",
		abbr = "EotS",
		achTotal = 54,
		achWon = 50,
		itemID = 29024,
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
-- function calculated by using these values
--[[
	lvl -	experience tick (half ws flag / 1 tick in arathi basin)
	16		264
	17		287
	19		327
	21		372
	23		419
	34		598
	35		632
	55		1547
	80		6200
]]
local a = 0.03722481
local b = -3.2389638
local c = 108.482513
local d = -809.23023
function lib.GetExperienceTick(lvl)
	local x = lvl or UnitLevel("player")
	return a*x^3 + b*x^2 + c*x + d
end

-- Get the maximum and minimum experience for one battleground
function lib.GetBattlegroundExperience(id, lvl)
	local info = data[id]
	local tick = lib.GetExperienceTick(lvl)
	return info and info.winXP and info.winXP*tick, info and info.lossXP and info.lossXP*tick
end

-- Get the average experience gained in one battleground based on win/loss ratio
function lib.GetAverageBattlegroundExperience(id, lvl, assumeEqual)
	local winXP, lossXP = lib.GetBattlegroundExperience(id, lvl)
	if(assumeEqual) then return winXP and lossXP and (winXP+lossXP)/2 end

	local win, total = lib.GetBattlegroundWinTotal(id)
	if(total == 0) then	win, total = 0.5, 1 end
	return winXP and lossXP and win/total*winXP+(1-win/total)*lossXP
end