local i4, i2, i1, u4, u2, u1, pchar = mem.i4, mem.i2, mem.i1, mem.u4, mem.u2, mem.u1, mem.pchar
local call = mem.call
local mmver = offsets.MMVersion


local function mmv(...)
	return select(mmver - 5, ...)
end
local function mm78(...)
	return select(mmver - 5, nil, ...)
end

local _KNOWNGLOBALS = Party, Game, Map, VFlipUnfixed, FixVFlip, HookManager, structs, GetCurrentNPC


do
	-- HookManager (only these functions so far)
	
	local procs = {
		hook = true,
		hookjmp = true,
		autohook = true,
		autohook2 = true,
		bytecodehook = true,
		bytecodehook2 = true,
		bytecodepatch = true,
	}

	local asmprocs = {
		asmhook = true,
		asmhook2 = true,
		asmpatch = true,
	}

	function HookManager(ref)
		local t = {}
		function t.Add(memf, addr, hookf, size, ...)
			local size1 = size and size >= 5 and size or mem.GetHookSize(addr)
			local std = mem.string(addr, size1, true)
			local delmem = memf(addr, hookf, size or size1, ...)
			local delhook = mem.hooks[addr]
			local mine = mem.string(addr, size1, true)
			t[#t + 1] = function(on)
				if on == "off" then
					if delmem then
						mem.hookfree(delmem)
					end
					if delhook then
						mem.hooks[addr] = nil
					end
					on = false
				end
				mem.IgnoreProtection(true)
				mem.copy(addr, on and mine or std, size1)
				mem.IgnoreProtection(false)
			end
		end
		function t.Switch(on)
			if on == "off" then
				return t.Clear()
			end
			for i = 1, #t do
				t[i](on)
			end
		end
		function t.Clear()
			for i = 1, #t do
				t[i]("off")
				t[i] = nil
			end
		end
		t.ref = ref or {}
		t.ref[""] = "%"
		function t.ProcessAsm(code)
			return code:gsub("%%([%w_]*)%%", t.ref)
		end
		for proc in pairs(procs) do
			t[proc] = function(...)
				t.Add(mem[proc], ...)
			end
		end
		for proc in pairs(asmprocs) do
			t[proc] = function(addr, code, ...)
				t.Add(mem[proc], addr, t.ProcessAsm(code), ...)
			end
		end
		t.asmproc = function(code)
			return mem.asmproc(t.ProcessAsm(code))
		end
		return t
	end

end


mem.IgnoreProtection(true)


-- internal.OnWaitMessage
local function HookWaitMessage(p)
	local std = u4[p]
	local new = mem.hookalloc()
	mem.hook(new, function(d)
		u4[d.esp] = std
		if internal.OnWaitMessage then
			internal.OnWaitMessage()
		end
	end)
	mem.IgnoreProtection(true)
	u4[p] = new
	mem.IgnoreProtection(false)
end

HookWaitMessage(mmv(0x4B9228, 0x4D8270, 0x4E8290))  -- WaitMessage
if mmver > 6 then
	HookWaitMessage(mm78(0x4D80B8, 0x4E8158))  -- Sleep
end
do
	local std = mmv(0x4A6590, 0x4BF377, 0x4BCFC3)
	mem.hook(mmv(0x4A59DB, 0x4BE6A6, 0x4BC233), function(d)
		d:push(std)
		if internal.OnWaitMessage then
			internal.OnWaitMessage()
		end
	end)
end



function internal.CalcSpellDamage(dmg, spell, skill, mastery, HP)
	local t = {Result = dmg, Spell = spell,
		-- :const.Skills
		Skill = skill,
		-- :const.*
		Mastery = mastery, HP = HP, HitPoints = HP}
	events.cocall("CalcSpellDamage", t)
	return t.Result
end



local WorldSides = {'up', 'down', 'left', 'right'}  -- 0 - party start, 1 - north, 2 - south, 3 - east, 4 - west
local SideToNum = table.invert(WorldSides)

function internal.TravelWalk(mapName, x, y, buf, bufsize, result)
	local dir
	if x < -22528 then
		dir = 'left'
	elseif x > 22528 then
		dir = 'right'
	elseif y < -22528 then
		dir = 'down'
	elseif y > 22528 then
		dir = 'up'
	else
		return result
	end
	local oldRes = result == 1 and mem.string(buf):lower() or nil
	local time = mm78(0x6BCEFC, 0x6F2650)
	local side = mm78(0x6BE1DC, 0x6F399C)

	local t = {LeaveMap = mem.string(mapName):lower(), LeaveSide = side and dir, X = x, Y = y,
	           EnterMap = oldRes, EnterSide = side and (WorldSides[i4[side]] or i4[side]), Days = time and i4[time]}
	-- Sides:
	--   0, "up", "down", "left", "right".
	--   0 means "party start" sprite.
	events.cocall("WalkToMap", t)
	local res = t.EnterMap and tostring(t.EnterMap)
	if res and res ~= oldRes and assert(#res < bufsize) then
		mem.copy(buf, res, #res + 1)
	end
	if mmver ~= 6 then
		i4[time] = t.Days
		i4[side] = SideToNum[t.EnterSide] or t.EnterSide
	end
	return res and 1 or 0
end

function internal.NewGameMap()
	Party.FallStartZ = 99999
	events.cocall("NewGameMap")
	if Party.FallStartZ == 99999 then
		Party.FallStartZ = Party.Z
	end
	mem.copy(mmv(0x908CAC, 0xACD500, 0xB21568), mmv(0x908C98, 0xACD4EC, 0xB21554), 0x14)
end

function internal.DeathMap(p)
	local t = {Name = mem.string(p)}
	events.cocall("DeathMap", t)
	assert(#t.Name < 0x14)
	mem.copy(p, t.Name, #t.Name + 1)
	Party.FallStartZ = Party.Z
end

function internal.SetFogRange()
	events.cocall("FogRange")
end

function internal.GameInitialized1()
	-- loaded .bin data
	events.cocall("GameInitialized1")
end

function internal.GameInitialized2()
	-- loaded .txt data
	events.cocall("GameInitialized2")
end

local function MapCheckHook(d, ev, t)
	local param1, param2 = d:getparams(0, 2)
	local r = mem.call(mmv(0x4AF370, 0x4CAAF0, 0x4DA920), 0, param1, param2)
	t = t or {}
	t.Map = mem.string(param1):lower()
	t.Result = (r ~= 0)
	events.cocall(ev, t)
	d.eax = t.Result and 1 or 0
	return t
end

-- CanSaveGame
mem.hook(mmv(0x44F378, 0x45F4CA, 0x45CF92), function(d)
--[[!({
  IsArena
  SaveKind
})]]
	MapCheckHook(d, "CanSaveGame", {SaveKind = (mmver == 6 and d.ebx or u4[d.ebp - 0x24])})
end)

if mmver > 6 then
	local isarena
	mem.hook(mm78(0x4600CA, 0x45DB81), function(d)
		isarena = mem.string(offsets.MapName, 20):lower() == mm78("d05.blv", "d42.blv")
		isarena = MapCheckHook(d, "CanSaveGame", {SaveKind = 0, IsArena = isarena}).IsArena
	end)
	mem.hook(mm78(0x4601BE, 0x45DCD1), function(d)
		if isarena then
			d:push(mm78(0x44C1A1, 0x4496C5))
		end
	end)
end

if mmver == 8 then
	mem.hook(0x42F349, function(d)
		MapCheckHook(d, "CanSaveGame", {SaveKind = 0})
	end)
end

-- CanCastLloyd
mem.hook(mmv(0x425FD3, 0x42B54F, 0x4296E6), function(d)
	MapCheckHook(d, "CanCastLloyd")
end)

-- IsUnderwater
local function IsUnderwaterHook(d)
	local param1, param2 = d:getparams(0, 2)
	local r = mem.call(mmv(0x4AF370, 0x4CAAF0, 0x4DA920), 0, param1, param2)
	local t = {Map = mem.string(param1):lower(), Result = (r == 0)}
	-- [MM7+]
	events.cocall("IsUnderwater", t)
	d.eax = t.Result and 0 or 1
end

if mmver > 6 then
	mem.hook(mm78(0x464880, 0x462BC7), IsUnderwaterHook)
end

if mmver == 7 then
	mem.hook(0x46496C, IsUnderwaterHook)
end

-- SetMapNoNPC
if mmver == 7 then
	mem.hook(0x460B45, function(d)
		u1[0xA74AEB] = 0
		-- [MM7]
		events.cocall("SetMapNoNPC")
	end, 7)
	mem.hook(0x432FE3, function(d)
		d.edi = 1
		d.edx = 1
		events.cocall("SetMapNoNPC")
	end)
end

-- Don't show error message if .evt or .str doesn't exist
mem.hook(mmv(0x43968E, 0x443D1E, 0x440B1F), function(d)
	local this, name = d:getparams(1, 1)
	local f = mem.call(mmv(0x44CBC0, 0x4615BD, 0x45FCA6), 1, mmv(this, this, 0x6F30D0), name, 0)
	if f ~= 0 then  -- found
		d:push(mmv(0x40C1A0, 0x410897, 0x411C9B))
	else
		d.esp = d.esp + 12
		d[mmv("ebp", "eax", "esi")] = 0
		d:push(mmv(0x43978E, 0x443DBE, 0x440BC0))
	end
end)

-- Fix evt.SimpleMessage in MM8
if mmver == 8 then
	mem.hook(0x44204A, function(d)
		local mon = mem.u4[0xFFD45C]
		if mon == 0 then
			mem.u4[d.esp] = 0x4421D9
		end
		d.ecx = mon
	end, 6)
end

-- MM7 Question in house: 0x4B29ED - check esi ~= 0

-- ShowNPCTopics - called when NPC topics list is about to be shown
local CurrentNPC

local function NPCTopicsHook(p)
	local i = (p - Game.NPC["?ptr"])/Game.NPC[0]["?size"]
	if i >= 0 and i < Game.NPC.Length then
		local start = not CurrentNPC
		CurrentNPC = i
		if start then
			events.cocall("EnterNPC", i)
		end
		events.cocall("ShowNPCTopics", i)
	end
end

if mmver == 6 then
	mem.autohook(0x419774, function(d)  NPCTopicsHook(d.ebp)  end)  -- street NPC
	mem.autohook(0x499B3A, function(d)  NPCTopicsHook(d.ebp)  end)  -- house NPC
elseif mmver == 7 then
	mem.autohook(0x41C633, function(d)  NPCTopicsHook(d.ebp)  end)  -- street NPC
	mem.autohook(0x4B43CD, function(d)  NPCTopicsHook(d.eax)  end)  -- house NPC
else
	mem.autohook(0x41BD22, function(d)  NPCTopicsHook(d.eax)  end)  -- street NPC
	mem.autohook(0x4B2E7E, function(d)  NPCTopicsHook(d.eax)  end)  -- house NPC
end

-- DrawNPCGreeting - called when NPC greeting is about to be shown
local CurNPCGreet

local function NPCGreetingHook(eax, p)
	local t = {Text = mem.pchar[Game.NPCGreet["?ptr"] + eax*4], Seen = (eax % 2 ~= 0)}
	t.NPC = (p - Game.NPC["?ptr"])/Game.NPC[0]["?size"]
	--print(p, dump(t))
	if t.NPC >= 0 and t.NPC < Game.NPC.Length then
		events.cocall("DrawNPCGreeting", t)
	end
	CurNPCGreet = tostring(t.Text)
	return CurNPCGreet ~= "" and mem.topointer(CurNPCGreet) or 0
end

if mmver == 7 then
	mem.i4[0x4455C2 + 2] = 0
	mem.hook(0x4455D9, function(d)
		d.eax = NPCGreetingHook(d.eax, d.ebx)
		if d.eax == 0 then
			u4[d.esp] = 0x4456FA
		end
	end, 7)
	mem.i4[0x4B2B73 + 2] = 0
	mem.hook(0x4B2BA1, function(d)
		d.edx = NPCGreetingHook(d.eax, d.esi)
		if d.edx == 0 then
			d.esp = d.esp + 12
			d:push(0x4B2C3C)
		end
	end, 7)
elseif mmver == 8 then
	mem.i4[0x44274E + 2] = 0
	mem.hook(0x442765, function(d)  d.eax = NPCGreetingHook(d.eax, d.edi)  end, 7)
	mem.i4[0x4B1389 + 2] = 0
	mem.hook(0x4B13A3, function(d)
		d.edx = NPCGreetingHook(d.eax, d.esi)
		if d.edx == 0 then
			d.esp = d.esp + 12
			d:push(0x4B1450)
		end
	end, 7)
end

-- WindowProc
do
	local buf = mem.hookalloc()
	local ptr = mmv(0x45733A+4, 0x4652BB+3, 0x463542+3)
	local std = u4[ptr]
	u4[ptr] = buf
	
	mem.hook(buf, function(d)
		d.esp = d.esp + 4
		local wnd, msg, wp, lp = d:getparams(0, 4)
		d:ret(4*4)
		d.eax = 0
		local t = {Window = wnd, Msg = msg, WParam = wp, LParam = lp, Handled = false}
		events.cocall("WindowMessage", t)
		if t.Handled then
			return
		end
		msg, wp, lp = t.Msg, t.WParam, t.LParam
		if msg == 0x100 or msg == 0x104 then
			local t = {
				-- :const.Keys
				Key = wp, Alt = (msg ~= 0x100), ExtendedKey = lp:And(0x1000000) ~= 0,
				WasPressed = lp:And(0x1000000) ~= 0, Handled = false}
			events.cocall("KeyDown", t)
			wp = t.Key
			if wp == 0 or t.Handled then
				return
			end
		-- elseif msg == 
		end
		d.eax = call(std, 0, wnd, msg, wp, lp)
	end)
end

-- OnAction
local screensNPC = {[4] = true, [13] = true, [19] = true}  -- SpeakNPC, house, street NPC
local function OnAction(InGame, a1, a2, a3)
	local t = {Action = i4[a1], Param = i4[a2], Param2 = a3 and i4[a3] or 0, Handled = false}
	events.cocall(InGame and "Action" or "MenuAction", t)
	if t.Handled then
		i4[a1] = 0
	else
		i4[a1], i4[a2] = t.Action, t.Param
		if a3 then
			i4[a3] = t.Param2
		end
		if CurrentNPC and i4[a1] == 113 and screensNPC[Game.CurrentScreen] then
			local i = CurrentNPC
			CurrentNPC = nil
			events.cocall("ExitNPC", i)
		end
	end
end

function GetCurrentNPC()
	return CurrentNPC
end

if mmver == 6 then
	mem.hook(0x42B348, function(d)
		local a1, a2, a3 = d.esp + 4 + 0x3D8 - 0x3B0, d.esp + 4 + 0x3D8 - 0x3C8, d["?ptr"] + d.offsets.edx
		OnAction(true, a1, a2, a3)
		d.edi = i4[a1]
		d.zf = (d.edi == 0x7F)
		if d.edi > 0x7F then
			u4[d.esp] = 0x42DAAD
		end
	end)
	mem.autohook(0x42FB85, function(d)
		local a1, a2 = d.esp + 0x14 - 4, d["?ptr"] + d.offsets.ebp
		OnAction(false, a1, a2)
	end)
else
	mem.hookcall(mm78(0x430581, 0x42EE8D), 1, 3, function(d, std, this, ...)
		std(this, ...)
		OnAction(true, ...)
	end)
	mem.hookcall(mm78(0x43576F, 0x4331C3), 1, 3, function(d, std, this, ...)
		std(this, ...)
		OnAction(false, ...)
	end)
end

-- KeysFilter
if mmver > 6 then
	mem.hook(mm78(0x42FCD1, 0x42E616), function(d)
		local on = d.al ~= 0
		local t = {
			-- :const.Keys
			Key = i4[d.esp + 0x1C - 8],
			On = on, Result = on}
		events.cocall("KeysFilter", t)
		if not t.Result then
			u4[d.esp] = mm78(0x43015B, 0x42EC44)
		end
	end, 6)
else
	local function f(d)
		local on = not d.ZF
		local t = {Key = d.esi, On = on, Result = on}
		events.cocall("KeysFilter", t)
		if not t.Result then
			u4[d.esp] = 0x42B229
		end
	end
	mem.hook(0x42AE5C, f, 6)
	mem.hook(0x42AE73, f, 6)
end

-- Save/load game
do
	local savehdr = mem.StaticAlloc(0x20)
	mem.copy(savehdr, "luadata.bin\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0", 0x20)

	local tmp = mem.StaticAlloc(4)

	function internal.OnSaveGame()
		if internal.SaveGameData then  -- if not New Game
			internal.TimersSaveGame()
			events.cocalls("BeforeSaveGame")
			internal.MonstersRestore(true)
		end
		local buf, err = internal.persist(internal.SaveGameData) --, permanentsSave)
		if err then
			ErrorMessage(err)
		end
		u4[tmp] = #buf
		buf = mem.string(tmp, 4, true)..buf
		u4[savehdr + 0x14] = #buf
		call(offsets.SaveFileToLod, 1, offsets.SaveGameLod, savehdr, buf, 0)
	end

	mem.autohook2(mmv(0x44FE3A, 0x4600A7, 0x45DB5F), function()
		if internal.SaveGameData then  -- if not New Game
			events.cocalls("AfterSaveGame")
		end
	end)

	function internal.OnLoadGame()
		internal.OnBeforeLoadGame()
		local f = call(offsets.FindFileInLod, 1, offsets.SaveGameLod, "luadata.bin", 1)
		if f ~= 0 then
			call(offsets.fread, 0, tmp, 4, 1, f)
			local size = u4[tmp]
			if size ~= 0 then
				local buf = mem.malloc(size)
				call(offsets.fread, 0, buf, size, 1, f)
				local err
				internal.SaveGameData, err = internal.unpersist(mem.string(buf, size, true)) --, permanentsTable)
				mem.free(buf)
				if err then
					ErrorMessage(err)
				end
			end
		end
	end
end

-- Allow entering completely new maps
do
	local function hookf(d, std, lod, ...)
		local r = std(lod, ...)
		if r == 0 then
			r = std(Game.GamesLod["?ptr"], ...)
		end
		return r
	end

	mem.hookcall(mmv(0x46DA0B, 0x47E3DF, 0x47D8E5), 1, 2, hookf)  -- ddm
	mem.hookcall(mmv(0x48BE10, 0x49A3E3, 0x4978CD), 1, 2, hookf)  -- dlv
	if mmver == 6 then
		mem.asmpatch(0x469DE1, "jmp 0x469DF5 - 0x469DE1")
		mem.asmpatch(0x45534D, "jmp 0x455361 - 0x45534D")
		mem.asmpatch(0x454FB2, "jmp 0x454FC6 - 0x454FB2")
	end
end

-- Allow drawing null pointer text
do
	local p = mmv(0x55BDE0, 0x5C4430, 0x5DC8E0)
	local code = ([[
		test ecx, ecx
		jnz @f
		mov [%d], cl
		mov eax, %d
		ret %%d
	@@:
	]]):format(p, p)

	if mmver == 6 then
		mem.asmhook(0x442F50, code:format(8))
	else
		mem.asmhook(mm78(0x44C794, 0x449ECA), code:format(12))
		mem.asmhook(mm78(0x44C95F, 0x44A058), code:format(16))
	end
	mem.asmpatch(mmv(0x443636, 0x44CE4F, 0x44A52A), ("jmp absolute %d"):format(mmv(0x4438D2, 0x44D0DA, 0x44A7AB)))
	-- 44A253 DrawTextLimited
end

-- Improve doors in D3D mode
if mmver > 6 then
	-- Bitmap-independant door UV calculation in D3D mode (was good for editor when it used to change textures)
	u4[mm78(0x46F7C4, 0x46E2A5)] = 0xC0316690
	u4[mm78(0x46F7C4, 0x46E265)] = 0xC0316690
	-- Don't reset static door texture coordinates in D3D mode
	mem.asmpatch(mm78(0x46F622, 0x46E103), [[
		mov ecx, [ebx + 0x2C]  ; bits
		test ecx, 0x9000
		jz @f
		mov [esi + 0x14], ax   ; BitmapU
	@@:
		test ecx, 0x20008
		jz @f
		mov [esi + 0x16], ax   ; BitmapV
	@@:
	]])
end

-- FindInTFT returns wrong 'not found' value
if mmver > 6 then
	mem.asmpatch(mm78(0x44E1B9, 0x44B8A5), "xor eax, eax", 3)
end

-- fix TFT bitmaps outdoors
if mmver == 6 then
	mem.asmhook(0x4695AF, [[
		mov [esi + 0x3C], ax
	]])
else
	mem.asmhook(mm78(0x478C40, 0x477B71), [[
		mov [ebx + 0x4C], ax
	]])
end

-- allow 64k files in lods instead of 32k
mem.u1[mmv(0x44D0E7, 0x461939, 0x45F354)+1] = 0xB7

-- fix flat and almost flat surfaces V orientation
if mmver == 8 then
	mem.i4[0x4781F6+1] = 0x10000
	mem.u2[0x4826EA] = 0x9090
	mem.asmpatch(0x482681, "add eax, [ebp - 0x14]", 3)
elseif mmver == 7 then
	mem.i4[0x4792C3+1] = 0x10000
	mem.u2[0x482D32] = 0x9090
	mem.asmpatch(0x482CCB, "add eax, [ebp - 0x14]", 3)
else
	-- Questionable in MM6. In MM7, MM8 the bug breaks SW/D3D consistency, thus must be fixed
	-- NWC made models without knowledge that BitmapV of almost-flat surfaces actually gets negated
	-- So, I'm fixing BitmapV negation, but not texture flip in MM6
	-- Modders can call FixVFlip() for their mods
	VFlipUnfixed = true
	local code = [[
		savereg edx
		mov edx, [esi + 0x48]  ; poly->Facet
		mov edx, [edx + 8]     ; NormalZ
		cmp edx, 0xE6CA
		jg @neg
		cmp edx, -0xE6CA
		jnl @std
	@neg:
		neg eax
	@std:
	]]
	local hooks = HookManager()
	hooks.asmhook(0x475A92, code)
	hooks.asmhook(0x47432D, code)
	
	-- [MM6]
	function FixVFlip()
		mem.IgnoreProtection(true)
		if VFlipUnfixed then
			mem.i4[0x469BBE+1] = 0x10000
			mem.u2[0x472FB7] = 0x9090
			mem.asmpatch(0x472F5E, "add eax, ecx", 2)
		else
			mem.i4[0x469BBE+1] = -0x10000
			mem.u2[0x472FB7] = 0xD8F7
			mem.u2[0x472F5E] = 0xC12B
		end
		VFlipUnfixed = not VFlipUnfixed
		hooks.Switch(VFlipUnfixed)
		mem.IgnoreProtection(true)
		Party.NeedRender = true
	end
	
	-- fix only for non-flat surfaces:
	-- mem.asmhook2(0x469B75, [[
		-- jl absolute 0x469B7C
		-- xor ecx, ecx
		-- mov eax, 0x10000
		-- mov edx, eax
		-- jmp absolute 0x469BC3
	-- ]])	
end

-- fix water in maps without a building with WtrTyl texture
if mmver == 7 then
	mem.autohook(0x47EBD2, function(d)
		mem.i4[0xEF5114] = Game.BitmapsLod:LoadBitmap("WtrTyl")
	end)
elseif mmver == 8 then
	-- doesn't seem to happen in MM8
end

-- when games.lod index is used make negative indeces refer to mapstats.txt lines
if mmver == 6 then
	local hooks = HookManager{
		MapStats = "[0x40CAC1]",
	}
	-- lloyd games index -> mapstats index
	hooks.asmhook(0x40C850, [[
		cmp ecx, 0
		jnl @f
		mov eax, ecx
		neg eax
		ret
	@@:
	]])
	hooks.asmhook(0x40CA59, [[
		cmp eax, 0
		jnl @f
		neg eax
		mov esi, eax
		jmp absolute 0x40CAA8
	@@:
	]])
	-- lloyd get
	hooks.asmhook(0x42E245, [[
		cmp eax, 0
		jnl @f
		imul eax, -0x38
		add eax, %MapStats%
		mov eax, [eax+4]
		jmp absolute 0x42E250
	@@:
	]])
	hooks.asmhook(0x42E2D8, [[
		cmp edi, 0
		jnl @f
		mov eax, edi
		imul eax, -0x38
		add eax, %MapStats%
		mov edi, [eax+4]
		or ecx, -1
		jmp absolute 0x42E2E5
	@@:
	]])
	-- lloyd set
	hooks.asmhook(0x42E4B1, [[
		push 0x6107BC  ; MapName
		mov ecx, %MapStats%
		call absolute 0x446BD0  ; MapStats_Find
		test eax, eax
		jz @f
		neg eax
		mov [ebp+0x1A], ax
	@@:
	]])
	
	-- town portal
	hooks.asmpatch(0x42E6C9, [[
		movsx eax, word [0x4C1F98 + 0x10 + ebp]
		imul eax, 0x38
		add eax, %MapStats%
		mov ecx, [eax+4]
		mov edx, 0x20
		; std
		or edi, ebx
		xor eax, eax
	]], 0x42E6DC - 0x42E6C9)
	-- strange: 42F209 - pyramid.blv
	-- 43BC39 - NPC news, not that important
	
	-- transport (use free byte at +9 offset to indicate map stats)
	-- location names are at 9DDE24, copied from GLOBAL.txt starting at index 545
	local code = [[
		cmp byte [ebp+9], 0
		jz @f
		mov eax, edx
		imul eax, 0x38
		add eax, %MapStats%
		mov %reg%, [eax+4]
		jmp absolute %p%
	@@:
	]]
	hooks.ref.p = 0x49D73A
	hooks.ref.reg = "ecx"
	hooks.asmhook(0x49D733, code)
	hooks.ref.p = 0x49D866
	hooks.ref.reg = "edi"
	hooks.asmhook(0x49D85F, code)
else
	local hooks = HookManager{
		MapStats = mm78("[0x410FB2]", "[0x41336B]"),
		MapName = mm78(0x6BE1C4, 0x6F3984),
		MapStats_Find = mm78(0x4547CF, 0x451F39),
		ver = mm78(7, 8),
	}
	-- lloyd games index -> mapstats index
	hooks.asmhook(mm78(0x410DA5, 0x4121B6), [[
		cmp ecx, 0
		jnl @f
		mov eax, ecx
		neg eax
		ret
	@@:
	]])
	-- lloyd get
	local code = [[
		cmp eax, 0
		jnl @f
		imul eax, -0x44
		add eax, %MapStats%
		mov eax, [eax+4]
		jmp absolute %p%
	@@:
	]]
	hooks.ref.p = mm78(0x43362F, 0x430F1A)
	hooks.asmhook(mm78(0x433626, 0x430F11), code)
	hooks.ref.p = mm78(0x433699, 0x430F79)
	hooks.asmhook(mm78(0x433690, 0x430F70), code)
	-- lloyd set
	hooks.asmhook2(mm78(0x43385C, 0x4310B3), [[
		jl @f
		push %MapName%
		mov ecx, %MapStats%
		call absolute %MapStats_Find%
		test eax, eax
		jz @f
		neg eax
	if %ver% eq 7
		mov ecx, [esp + 0x5F8 - 0x5DC]
		mov [ecx+0x1A], ax
	else
		mov [esi+0x1A], ax
	end if
		test esp, esp
	@@:
	]])
	-- strange: 433B65
end

-- SkyBitmap
mem.autohook(mmv(0x46E01E, 0x47EB89, 0x47E0D4), function(d)
	local time = Map.OutdoorLastVisitTime
	local first = (time == 0)
	if first or time:div(const.Day) % 28 ~= Game.DayOfMonth then
		local t = {FirstVisit = first, Result = Map.OutdoorExtra.SkyBitmap}
		events.cocall("SkyBitmap", t)
		Map.OutdoorExtra.SkyBitmap = t.Result
	end
end)

if mmver == 8 then
	mem.u1[0x47E2DA] = 0x47E304 - 0x47E2DB
end

-- automatic MazeInfo
if mmver == 6 then
	mem.autohook2(0x439F35, function(d)
		if Map.MapStatsIndex > 0 then
			d.eax = i4[Game.MapStats[Map.MapStatsIndex]["?ptr"]]
		end
	end)
end

-- internal.MapRefilled (used in evt.lua)
mem.autohook(mmv(0x4554B5, 0x450AD6, 0x44E339), function(d)
	internal.MapRefilled = 1
end)

-- Player hooks
local function GetPlayer(p)
	local i = (p - Party.PlayersArray["?ptr"]) / Party.PlayersArray[0]["?size"]
	return i, Party.PlayersArray[i]
end

local function GetMonster(p)
	if p == 0 then
		return
	end
	local i = (p - Map.Monsters["?ptr"]) / Map.Monsters[0]["?size"]
	return i, Map.Monsters[i]
end

-- CalcStatBonusByItems
mem.hookfunction(mmv(0x482E80, 0x48EAA6, 0x48E213), 1, mmv(1, 2, 2), function(d, def, this, stat, IgnoreExtraHand)
	local t = {
		-- :const.Stats
		Stat = stat,  -- const.Stats
		IgnoreExtraHand = IgnoreExtraHand and IgnoreExtraHand ~= 0,
		Result = def(this, stat, IgnoreExtraHand),
	}
	t.PlayerIndex, t.Player = GetPlayer(this)
	--!k{Player :structs.Player}
	events.cocall("CalcStatBonusByItems", t)
	return t.Result
end)

-- CalcStatBonusByMagic
mem.hookfunction(mmv(0x483800, 0x48F734, 0x48EE09), 1, 1, function(d, def, this, stat)
	local t = {
		-- :const.Stats
		Stat = stat,  -- const.Stats
		Result = def(this, stat),
	}
	t.PlayerIndex, t.Player = GetPlayer(this)
	--!k{Player :structs.Player}
	events.cocall("CalcStatBonusByMagic", t)
	return t.Result
end)

-- CalcStatBonusBySkills
mem.hookfunction(mmv(0x483930, 0x48FBF8, 0x48F084), 1, 1, function(d, def, this, stat)
	local t = {
		-- :const.Stats
		Stat = stat,  -- const.Stats
		Result = def(this, stat),
	}
	t.PlayerIndex, t.Player = GetPlayer(this)
	--!k{Player :structs.Player}
	events.cocall("CalcStatBonusBySkills", t)
	return t.Result
end)

-- GetSkill
if mmver > 6 then
	mem.hookfunction(mm78(0x48F87A, 0x48EF4F), 1, 1, function(d, def, this, skill)
		local t = {
			Skill = skill,  -- const.Skills
			Result = def(this, skill),
		}
		t.PlayerIndex, t.Player = GetPlayer(this)
		--!k{Player :structs.Player}
		events.cocall("GetSkill", t)
		return t.Result
	end)
end

-- GetAttackDelay
mem.hookfunction(mmv(0x481A80, 0x48E19B, 0x48D62A), 1, 1, function(d, def, this, ranged)
	local t = {
		Ranged = ranged ~= 0,
		Result = def(this, ranged),
	}
	t.PlayerIndex, t.Player = GetPlayer(this)
	--!k{Player :structs.Player}
	events.cocall("GetAttackDelay", t)
	return t.Result
end)

-- CalcDamageToPlayer
mem.hookfunction(mmv(0x47F670, 0x48D499, 0x48CDA6), 1, 2, function(d, def, this, kind, dmg)
	local t = {
		-- :const.Damage
		DamageKind = kind,
		Damage = dmg,
		Result = def(this, kind, dmg),
	}
	t.PlayerIndex, t.Player = GetPlayer(this)
	--!k{Player :structs.Player}
	events.cocall("CalcDamageToPlayer", t)
	return t.Result
end)

-- Skill effects
local function SimplePlayerHook(p, name)
	mem.hookfunction(p, 1, 0, function(d, def, this)
		local t = {
			Result = def(this)
		}
		t.PlayerIndex, t.Player = GetPlayer(this)
		--!k{Player :structs.Player}
		events.cocall(name, t)
		return t.Result
	end)
end

SimplePlayerHook(mmv(0x485340, 0x4911EB, 0x49028F), "GetMerchantTotalSkill")
SimplePlayerHook(mmv(0x4853E0, 0x4912A8, 0x49031C), "GetDisarmTrapTotalSkill")

if mmver == 6 then
	SimplePlayerHook(0x4852D0, "GetDiplomacyTotalSkill")
else
	SimplePlayerHook(mm78(0x491252, 0x4902DF), "GetPerceptionTotalSkill")
	SimplePlayerHook(mm78(0x49130F, 0x49036E), "GetLearningTotalSkill")
end

-- DoBadThingToPlayer
mem.hookfunction(mmv(0x480010, 0x48DCDC, 0x48D166), 1, mmv(1, 2, 2), function(d, def, this, thing, mon)
	local t = {
		-- :const.MonsterBonus
		Thing = thing,
		Allow = true,
	}
	t.PlayerIndex, t.Player = GetPlayer(this)
	if mmver > 6 then
		t.MonsterIndex, t.Monster = GetMonster(mon)
	end
	--!k{Player :structs.Player [MM7+], Monster :structs.MapMonster [MM7+]}
	events.cocall("DoBadThingToPlayer", t)
	return t.Allow and def(this, thing, mon) or 0
end)

-- GetStatisticEffect
mem.hookfunction(mmv(0x482DC0, 0x48EA13, 0x48E18E), 0, 1, function(d, def, val)
	local t = {
		Value = val,
		Result = def(val),
	}
	events.cocall("GetStatisticEffect", t)
	return t.Result
end)

-- MonsterKilled
mem.hookfunction(mmv(0x403050, 0x402D6E, 0x402E78), 1, 0, function(d, def, index)
	local function callDef()
		def = def and def(index) and nil
	end
	--!(mon:structs.MapMonster, monIndex, defaultHandler)
	events.cocall("MonsterKilled", Map.Monsters[index], index, callDef)
	callDef()
end)

if mmver > 6 then
	-- IsMonsterOfKind
	mem.hookfunction(mm78(0x438BCE, 0x436542), 2, 0, function(d, def, id, kind)
		local t = {
			Id = id,
			-- :const.MonsterKind
			Kind = kind,
			Result = def(id, kind),
		}
		events.cocall("IsMonsterOfKind", t)
		return t.Result
	end)
	
	-- ItemAdditionalDamage
	mem.hookfunction(mm78(0x439E16, 0x4378CD), 2, 1, function(d, def, item, kind, vampiric)
		local t = {
			Item = structs.Item:new(item),
			Result = def(item, kind, vampiric),
		}
		-- :const.Damage
		t.DamageKind = i4[kind]
		t.Vampiric = (i4[vampiric] ~= 0)
		events.cocall("ItemAdditionalDamage", t)
		i4[kind] = t.DamageKind
		i4[vampiric] = (t.Vampiric and 1 or 0)
		return t.Result
	end)
	
	-- GetMonsterAggression
	-- mem.hookfunction(mm78(0x40104C, 0x401051), 2, 0, function(d, def, mon1, mon2)
	-- 	local t = {
	-- 		Result = def(mon1, mon2),
	-- 	}
	-- 	t.Monster1Index, t.Monster1 = GetMonster(mon1)
	-- 	t.Monster2Index, t.Monster2 = GetMonster(mon2)
	-- 	events.cocall("GetMonsterAggression", t)
	-- 	return t.Result
	-- end)
end

-- CalcDamageToMonster
mem.hookfunction(mmv(0x421DC0, 0x427522, 0x425951), 0, 3, function(d, def, mon, kind, dmg)
	local t = {
		-- :const.Damage
		DamageKind = kind,
		Damage = dmg,
		Result = def(mon, kind, dmg),
	}
	t.MonsterIndex, t.Monster = GetMonster(mon)
	--!k{Monster :structs.MapMonster}
	events.cocall("CalcDamageToMonster", t)
	return t.Result
end)

-- PickCorpse
mem.hookfunction(mmv(0x421670, 0x426A03, 0x424E3D), 0, 1, function(d, def, mon)
	local t = {
		CallDefault = function()
			def = def and def(mon) and nil
		end,
		AllowDefault = true,
	}
	t.MonsterIndex, t.Monster = GetMonster(mon)
	--!k{Monster :structs.MapMonster}
	events.cocall("PickCorpse", t)
	if t.AllowDefault then
		t.CallDefault()
	end
end)

-- CastTelepathy
if mmver > 6 then
	mem.hookfunction(mmv(nil, 0x4086E9, 0x408E89), 1, 0, function(d, def, mon)
		local t = {
			AllowDefault = true,
		}
		t.CallDefault = function()
			def = def and def(mon) and nil
			t.AllowDefault = false
		end
		t.MonsterIndex, t.Monster = GetMonster(mon)
		--!k{Monster :structs.MapMonster}
		events.cocall("CastTelepathy", t)
		if t.AllowDefault then
			t.CallDefault()
		end
	end)
end

mem.IgnoreProtection(false)