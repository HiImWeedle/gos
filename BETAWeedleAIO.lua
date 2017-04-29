local KoreanChamps = {"Twitch", "Skarner", "Soraka", "Veigar", "Rengar", "Nami", "Lissandra", "LeeSin", "Bardo", "Ashe", "Annie", "Ezreal", "Zed", "Ahri", "Blitzcrank", "Caitlyn", "Brand", "Ziggs", "Morgana", "Syndra", "KogMaw", "Lux", "Cassiopeia", "Karma", "Orianna", "Ryze", "Jhin", "Jayce", "Kennen", "Thresh", "Amumu", "Elise", "Zilean", "Corki", "Sivir", "Aatrox", "Jinx", "Warwick"}
if not table.contains(KoreanChamps, myHero.charName)  then print("" ..myHero.charName.. " Is Not (Yet) Supported") return end

local function Ready(spell)
	return myHero:GetSpellData(spell).currentCd == 0 and myHero:GetSpellData(spell).level > 0 and myHero:GetSpellData(spell).mana <= myHero.mana
end

local KoreanMechanics = MenuElement({type = MENU, id = "KoreanMechanics", name = "WeedleAIO", leftIcon = "http://4.1m.yt/d5VbDBm.png"})
KoreanMechanics:MenuElement({id = "Hold", name = "Hold Enable Key", key = string.byte(" ")})
KoreanMechanics:MenuElement({id = "Enabled", name = "Toggle Enable Key", key = string.byte("M"), toggle = true})
KoreanMechanics:MenuElement({type = MENU, id = "Spell", name = "Spell Settings"})
KoreanMechanics:MenuElement({type = MENU, id = "Draw", name = "Draw Settings"})
	KoreanMechanics.Draw:MenuElement({id = "Enabled", name = "Enable all Drawings", value = true})
	KoreanMechanics.Draw:MenuElement({id = "OFFDRAW", name = "Draw text when Off", value = true})	
KoreanMechanics:MenuElement({type = SPACE, name = "Version 0.25 by Weedle and Sofie"})		


local _AllyHeroes
local function GetAllyHeroes()
	if _AllyHeroes then return _AllyHeroes end
	_AllyHeroes = {}
	for i = 1, Game.HeroCount() do
		local unit = Game.Hero(i)
		if unit.isAlly then
			table.insert(_AllyHeroes, unit)
		end
	end
	return _AllyHeroes
end

local _EnemyHeroes
local function GetEnemyHeroes()
	if _EnemyHeroes then return _EnemyHeroes end
	_EnemyHeroes = {}
	for i = 1, Game.HeroCount() do
		local unit = Game.Hero(i)
		if unit.isEnemy then
			table.insert(_EnemyHeroes, unit)
		end
	end
	return _EnemyHeroes
end

local function GetPercentHP(unit)
	if type(unit) ~= "userdata" then error("{GetPercentHP}: bad argument #1 (userdata expected, got "..type(unit)..")") end
	return 100*unit.health/unit.maxHealth
end

local function GetPercentMP(unit)
	if type(unit) ~= "userdata" then error("{GetPercentMP}: bad argument #1 (userdata expected, got "..type(unit)..")") end
	return 100*unit.mana/unit.maxMana
end

local function GetBuffData(unit, buffname)
	for i = 0, unit.buffCount do
		local buff = unit:GetBuff(i)
		if buff.name == buffname and buff.count > 0 then 
			return buff
		end
	end
	return {type = 0, name = "", startTime = 0, expireTime = 0, duration = 0, stacks = 0, count = 0}--
end

local function IsImmobileTarget(unit)
	for i = 0, unit.buffCount do
		local buff = unit:GetBuff(i)
		if buff and (buff.type == 5 or buff.type == 11 or buff.type == 29 or buff.type == 24 or buff.name == "recall") and buff.count > 0 then
			return true
		end
	end
	return false	
end

local function GetBuffs(unit)
	local t = {}
	for i = 0, unit.buffCount do
		local buff = unit:GetBuff(i)
		if buff.count > 0 then
			table.insert(t, buff)
		end
	end
	return t
end

local sqrt = math.sqrt 
local function GetDistance(p1,p2)
	return sqrt((p2.x - p1.x)*(p2.x - p1.x) + (p2.y - p1.y)*(p2.y - p1.y) + (p2.z - p1.z)*(p2.z - p1.z))
end

local function GetDistance2D(p1,p2)
	return sqrt((p2.x - p1.x)*(p2.x - p1.x) + (p2.y - p1.y)*(p2.y - p1.y))
end


local _OnVision = {}
function OnVision(unit)
	if _OnVision[unit.networkID] == nil then _OnVision[unit.networkID] = {state = unit.visible , tick = GetTickCount(), pos = unit.pos} end
	if _OnVision[unit.networkID].state == true and not unit.visible then _OnVision[unit.networkID].state = false _OnVision[unit.networkID].tick = GetTickCount() end
	if _OnVision[unit.networkID].state == false and unit.visible then _OnVision[unit.networkID].state = true _OnVision[unit.networkID].tick = GetTickCount() end
	return _OnVision[unit.networkID]
end
Callback.Add("Tick", function() OnVisionF() end)
local visionTick = GetTickCount()
function OnVisionF()
	if GetTickCount() - visionTick > 100 then
		for i,v in pairs(GetEnemyHeroes()) do
			OnVision(v)
		end
	end
end

local _OnWaypoint = {}
function OnWaypoint(unit)
	if _OnWaypoint[unit.networkID] == nil then _OnWaypoint[unit.networkID] = {pos = unit.posTo , speed = unit.ms, time = Game.Timer()} end
	if _OnWaypoint[unit.networkID].pos ~= unit.posTo then 
		-- print("OnWayPoint:"..unit.charName.." | "..math.floor(Game.Timer()))
		_OnWaypoint[unit.networkID] = {startPos = unit.pos, pos = unit.posTo , speed = unit.ms, time = Game.Timer()}
			DelayAction(function()
				local time = (Game.Timer() - _OnWaypoint[unit.networkID].time)
				local speed = GetDistance2D(_OnWaypoint[unit.networkID].startPos,unit.pos)/(Game.Timer() - _OnWaypoint[unit.networkID].time)
				if speed > 1250 and time > 0 and unit.posTo == _OnWaypoint[unit.networkID].pos and GetDistance(unit.pos,_OnWaypoint[unit.networkID].pos) > 200 then
					_OnWaypoint[unit.networkID].speed = GetDistance2D(_OnWaypoint[unit.networkID].startPos,unit.pos)/(Game.Timer() - _OnWaypoint[unit.networkID].time)
					-- print("OnDash: "..unit.charName)
				end
			end,0.05)
	end
	return _OnWaypoint[unit.networkID]
end

local function GetPred(unit,speed,delay)
	if unit == nil then return end
	local speed = speed or math.huge
	local delay = delay or 0.25
	local unitSpeed = unit.ms
	if OnWaypoint(unit).speed > unitSpeed then unitSpeed = OnWaypoint(unit).speed end
	if OnVision(unit).state == false then
		local unitPos = unit.pos + Vector(unit.pos,unit.posTo):Normalized() * ((GetTickCount() - OnVision(unit).tick)/1000 * unitSpeed)
		local predPos = unitPos + Vector(unit.pos,unit.posTo):Normalized() * (unitSpeed * (delay + (GetDistance(myHero.pos,unitPos)/speed)))
		if GetDistance(unit.pos,predPos) > GetDistance(unit.pos,unit.posTo) then predPos = unit.posTo end
		return predPos
	else
		if unitSpeed > unit.ms then
			local predPos = unit.pos + Vector(OnWaypoint(unit).startPos,unit.posTo):Normalized() * (unitSpeed * (delay + (GetDistance(myHero.pos,unit.pos)/speed)))
			if GetDistance(unit.pos,predPos) > GetDistance(unit.pos,unit.posTo) then predPos = unit.posTo end
			return predPos
		elseif IsImmobileTarget(unit) then
			return unit.pos
		else
			return unit:GetPrediction(speed,delay)
		end
	end
end

local isCasting = 0 
function KoreanCast(key, pos)
local Cursor = mousePos
    if pos == nil or isCasting == 1 then return end
    isCasting = 1
        Control.SetCursorPos(pos)
        DelayAction(function()
        	if Control.IsKeyDown(key) == false then
       		 Control.SetCursorPos(Cursor)
        	end
        DelayAction(function()
         isCasting = 0
        end, 0.002)
        end, (KoreanMechanics.delay:Value() + Game.Latency()) / 1000)
end 


class "Ezreal"

function Ezreal:__init()
	print("Weedle's Ezreal Loaded")
	Callback.Add("Tick", function() self:Tick() end)
	Callback.Add("Draw", function() self:Draw() end)
	self:Menu()
end

function Ezreal:Menu()
	KoreanMechanics.Spell:MenuElement({id = "Q", name = "Q Key", key = string.byte("Q")})
	KoreanMechanics.Spell:MenuElement({id = "QR", name = "Q Range", value = 1150, min = 0, max = 1150, step = 10})
	KoreanMechanics.Spell:MenuElement({id = "W", name = "W Key", key = string.byte("W")})
	KoreanMechanics.Spell:MenuElement({id = "E", name = "E Key", key = string.byte("E")})	
	KoreanMechanics.Spell:MenuElement({id = "WR", name = "W Range", value = 1000, min = 0, max = 1000, step = 10})
	KoreanMechanics.Spell:MenuElement({id = "R", name = "R Key", key = string.byte("R")})

	KoreanMechanics.Draw:MenuElement({id = "QD", name = "Draw Q range", type = MENU})
    KoreanMechanics.Draw.QD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.QD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.QD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
    KoreanMechanics.Draw:MenuElement({id = "WD", name = "Draw W range", type = MENU})
    KoreanMechanics.Draw.WD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.WD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.WD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
end

function Ezreal:Tick()
	if myHero.attackData.state == STATE_WINDUP then return end	
	if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then
		if KoreanMechanics.Spell.Q:Value() then
			self:Q()
		end
		if KoreanMechanics.Spell.W:Value() then
			self:W()
		end	
		if KoreanMechanics.Spell.E:Value() then
			self:E()
		end		
		if KoreanMechanics.Spell.R:Value() then
			self:R()
		end
	end	
end

function Ezreal:Q()
	if Ready(_Q) then
local target =  _G.SDK.TargetSelector:GetTarget(1250)
if target == nil then return end 	
	local pos = GetPred(target, 1400, (0.25 + Game.Latency())/1000)
	Control.CastSpell(HK_Q, pos)
end
end

function Ezreal:W()
	if Ready(_W) then
local target =  _G.SDK.TargetSelector:GetTarget(1100)	
if target == nil then return end 		
	local pos = GetPred(target, 1200, 0.25 + Game.Latency()/1000)
	Control.CastSpell(HK_W, pos)
end
end

function Ezreal:E()
	if Ready(_E) then
	Control.CastSpell(HK_E, mousePos)
	end
end	


function Ezreal:R()	
	if Ready(_R) then
local targety =  _G.SDK.TargetSelector:GetTarget()
	if targety == nil then return end 	
	local pos = GetPred(targety, 2000, 0.25 + Game.Latency()/1000)
	Control.CastSpell(HK_R, pos)
end
end

function Ezreal:Draw()
	if not myHero.dead then
	   	if KoreanMechanics.Draw.Enabled:Value() then
	   		local textPos = myHero.pos:To2D()
	   		if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then
				Draw.Text("Aimbot ON", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 000, 255, 000)) 		
			end
			if not KoreanMechanics.Enabled:Value() and not KoreanMechanics.Hold:Value() and KoreanMechanics.Draw.OFFDRAW:Value() then 
				Draw.Text("Aimbot OFF", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 255, 000, 000)) 
			end 
			if KoreanMechanics.Draw.QD.Enabled:Value() then
	    	    Draw.Circle(myHero.pos, KoreanMechanics.Spell.QR:Value(), KoreanMechanics.Draw.QD.Width:Value(), KoreanMechanics.Draw.QD.Color:Value())
	    	end
	    	if KoreanMechanics.Draw.WD.Enabled:Value() then
	    	    Draw.Circle(myHero.pos, KoreanMechanics.Spell.WR:Value(), KoreanMechanics.Draw.WD.Width:Value(), KoreanMechanics.Draw.WD.Color:Value())
	    	end  	
	    end		
	end
end

class "Zed"

function Zed:__init()
	print("Weedle's Zed Loaded")
	Callback.Add("Tick", function() self:Tick() end)
	Callback.Add("Draw", function() self:Draw() end)
	self:Menu()
end

function Zed:Menu()
	KoreanMechanics.Spell:MenuElement({id = "Q", name = "Q Key", key = string.byte("Q")})
	KoreanMechanics.Spell:MenuElement({id = "QR", name = "Max Q Combo Range", value = 1600, min = 0, max = 1600, step = 25})
	KoreanMechanics.Spell:MenuElement({id = "R", name = "R Key", key = string.byte("R")})

	KoreanMechanics.Draw:MenuElement({id = "QD", name = "Draw Q range", type = MENU})
    KoreanMechanics.Draw.QD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.QD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.QD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
end

function Zed:Tick()
	if myHero.attackData.state == STATE_WINDUP then return end	
	if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then
		if KoreanMechanics.Spell.Q:Value() then
			self:Q()
		end
		if KoreanMechanics.Spell.R:Value() then
			self:R()
		end		
	end
end	

function Zed:Q()
	if Ready(_Q) then
local target =  _G.SDK.TargetSelector:GetTarget(1500)
if target == nil then return end 	
	local pos = GetPred(target, 1100, (0.25 + Game.Latency())/1000)
	Control.CastSpell(HK_Q, pos)
end
end

function Zed:R()
	if Ready(_R) then
local target =  _G.SDK.TargetSelector:GetTarget(850)
if target == nil then return end 	
	Control.CastSpell(HK_R, target.pos)
end
end	

function Zed:Draw()
	if not myHero.dead then
	   	if KoreanMechanics.Draw.Enabled:Value() then
	   		local textPos = myHero.pos:To2D()
	   		if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then
				Draw.Text("Aimbot ON", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 000, 255, 000)) 		
			end
			if not KoreanMechanics.Enabled:Value() and not KoreanMechanics.Hold:Value() and KoreanMechanics.Draw.OFFDRAW:Value() then 
				Draw.Text("Aimbot OFF", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 255, 000, 000)) 
			end 
			if KoreanMechanics.Draw.QD.Enabled:Value() then
	    	    Draw.Circle(myHero.pos, 900, KoreanMechanics.Draw.QD.Width:Value(), KoreanMechanics.Draw.QD.Color:Value())
	    	end
	    end		
	end
end

class "Ahri"

function Ahri:__init()
	print("Weedle's Ahri Loaded")
	Callback.Add("Tick", function() self:Tick() end)
	Callback.Add("Draw", function() self:Draw() end)
	self:Menu()
end

function Ahri:Menu()
	KoreanMechanics.Spell:MenuElement({id = "Q", name = "Q Key", key = string.byte("Q")})
	KoreanMechanics.Spell:MenuElement({id = "QR", name = "Q Range", value = 875, min = 0, max = 875, step = 10})
	KoreanMechanics.Spell:MenuElement({id = "E", name = "E Key", key = string.byte("E")})
	KoreanMechanics.Spell:MenuElement({id = "ER", name = "E Range", value = 950, min = 0, max = 950, step = 10})

	KoreanMechanics.Draw:MenuElement({id = "QD", name = "Draw Q range", type = MENU})
    KoreanMechanics.Draw.QD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.QD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.QD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
    KoreanMechanics.Draw:MenuElement({id = "ED", name = "Draw E range", type = MENU})
    KoreanMechanics.Draw.ED:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.ED:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.ED:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
end

function Ahri:Tick()
	if myHero.attackData.state == STATE_WINDUP then return end	
	if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then
		if KoreanMechanics.Spell.Q:Value() then
			self:Q()
		end
		if KoreanMechanics.Spell.E:Value() then
			self:E()
		end
	end
end

function Ahri:Q()
	if Ready(_Q) then
local target =  _G.SDK.TargetSelector:GetTarget(1000)
if target == nil then return end 	
	local pos = GetPred(target, 1700, (0.25 + Game.Latency())/1000)
	Control.CastSpell(HK_Q, pos)
end
end	

function Ahri:E()
	if Ready(_E) then
local target =  _G.SDK.TargetSelector:GetTarget(1050)
if target == nil then return end 	
	local pos = GetPred(target, 1600, (0.25 + Game.Latency())/1000)
	Control.CastSpell(HK_E, pos)
end
end	

function Ahri:Draw()
	if not myHero.dead then
	   	if KoreanMechanics.Draw.Enabled:Value() then
	   		local textPos = myHero.pos:To2D()
	   		if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then
				Draw.Text("Aimbot ON", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 000, 255, 000)) 		
			end
			if not KoreanMechanics.Enabled:Value() and not KoreanMechanics.Hold:Value() and KoreanMechanics.Draw.OFFDRAW:Value() then 
					Draw.Text("Aimbot OFF", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 255, 000, 000)) 
			end 
			if KoreanMechanics.Draw.QD.Enabled:Value() then
	    	    Draw.Circle(myHero.pos, KoreanMechanics.Spell.QR:Value(), KoreanMechanics.Draw.QD.Width:Value(), KoreanMechanics.Draw.QD.Color:Value())
	    	end
	    	if KoreanMechanics.Draw.ED.Enabled:Value() then
	    	    Draw.Circle(myHero.pos, KoreanMechanics.Spell.ER:Value(), KoreanMechanics.Draw.ED.Width:Value(), KoreanMechanics.Draw.ED.Color:Value())
	    	end
	    end		
	end
end

class "Blitzcrank"

function Blitzcrank:__init()
	print("Weedle's Blitzcrank Loaded")
	Callback.Add("Tick", function() self:Tick() end)
	Callback.Add("Draw", function() self:Draw() end)
	self:Menu()
end

function Blitzcrank:Menu()
	KoreanMechanics.Spell:MenuElement({id = "Q", name = "Q Key", key = string.byte("Q")})
	KoreanMechanics.Spell:MenuElement({id = "QR", name = "Q Range", value = 925, min = 0, max = 925, step = 10})
	KoreanMechanics.Draw:MenuElement({id = "QD", name = "Draw Q range", type = MENU})

    KoreanMechanics.Draw.QD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.QD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.QD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})	
end 

function Blitzcrank:Tick()
	if myHero.attackData.state == STATE_WINDUP then return end	
	if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then
		if KoreanMechanics.Spell.Q:Value() then
			self:Q()
		end
	end
end	

function Blitzcrank:Q()
	if Ready(_Q) then
local target =  _G.SDK.TargetSelector:GetTarget(1025)
if target == nil then return end 	
	local pos = GetPred(target, 1800, (0.25 + Game.Latency())/1000)
	Control.CastSpell(HK_Q, pos)
end
end

function Blitzcrank:Draw()
	if not myHero.dead then
	   	if KoreanMechanics.Draw.Enabled:Value() then
	   		local textPos = myHero.pos:To2D()
	   		if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then
				Draw.Text("Aimbot ON", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 000, 255, 000)) 		
			end
			if not KoreanMechanics.Enabled:Value() and not KoreanMechanics.Hold:Value() and KoreanMechanics.Draw.OFFDRAW:Value() then 
				Draw.Text("Aimbot OFF", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 255, 000, 000)) 
			end 
			if KoreanMechanics.Draw.QD.Enabled:Value() then
	    	    Draw.Circle(myHero.pos, KoreanMechanics.Spell.QR:Value(), KoreanMechanics.Draw.QD.Width:Value(), KoreanMechanics.Draw.QD.Color:Value())
	    	end
	    end		
	end
end		

class "Caitlyn"

function Caitlyn:__init()
	print("Weedle's Caitlyn Loaded")
	Callback.Add("Tick", function() self:Tick() end)
	Callback.Add("Draw", function() self:Draw() end)
	self:Menu()
end

function Caitlyn:Menu()
	KoreanMechanics.Spell:MenuElement({id = "Q", name = "Q Key", key = string.byte("Q")})
	KoreanMechanics.Spell:MenuElement({id = "QR", name = "Q Range", value = 1250, min = 0, max = 1250, step = 10})
	KoreanMechanics.Spell:MenuElement({id = "E", name = "E Key", key = string.byte("E")})
	KoreanMechanics.Spell:MenuElement({id = "ER", name = "E Range", value = 750, min = 0, max = 750, step = 10})
	KoreanMechanics.Spell:MenuElement({id = "R", name = "R Key", key = string.byte("R")})			

	KoreanMechanics.Draw:MenuElement({id = "QD", name = "Draw Q range", type = MENU})
    KoreanMechanics.Draw.QD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.QD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.QD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
    KoreanMechanics.Draw:MenuElement({id = "ED", name = "Draw E range", type = MENU})
    KoreanMechanics.Draw.ED:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.ED:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.ED:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
end

function Caitlyn:Tick()
	if myHero.attackData.state == STATE_WINDUP then return end	
	if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then
		if KoreanMechanics.Spell.Q:Value() then
			self:Q()
		end
		if KoreanMechanics.Spell.E:Value() then
			self:E()
		end
		if KoreanMechanics.Spell.R:Value() then
			self:R()
		end
	end
end

function Caitlyn:Q()
	if Ready(_Q) then
local target =  _G.SDK.TargetSelector:GetTarget(1350)
if target == nil then return end 	
	local pos = GetPred(target, 2200, (0.25 + Game.Latency())/1000)
	Control.CastSpell(HK_Q, pos)
end
end	

function Caitlyn:E()
	if Ready(_E) then
local target =  _G.SDK.TargetSelector:GetTarget(850)
if target == nil then return end 	
	local pos = GetPred(target, 2000, (0.25 + Game.Latency())/1000)
	Control.CastSpell(HK_E, pos)
end
end	

function Caitlyn:R()
	if Ready(_R) then
local target =  _G.SDK.TargetSelector:GetTarget(3000)
if target == nil then return end 	
	Control.CastSpell(HK_R, target.pos)
end
end		

function Caitlyn:Draw()
	if not myHero.dead then
	   	if KoreanMechanics.Draw.Enabled:Value() then
	   		local textPos = myHero.pos:To2D()
	   		if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then
				Draw.Text("Aimbot ON", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 000, 255, 000)) 		
			end
			if not KoreanMechanics.Enabled:Value() and not KoreanMechanics.Hold:Value() and KoreanMechanics.Draw.OFFDRAW:Value() then 
				Draw.Text("Aimbot OFF", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 255, 000, 000)) 
			end 
			if KoreanMechanics.Draw.QD.Enabled:Value() then
	    	    Draw.Circle(myHero.pos, KoreanMechanics.Spell.QR:Value(), KoreanMechanics.Draw.QD.Width:Value(), KoreanMechanics.Draw.QD.Color:Value())
	    	end
	    	if KoreanMechanics.Draw.ED.Enabled:Value() then
	    	    Draw.Circle(myHero.pos, KoreanMechanics.Spell.ER:Value(), KoreanMechanics.Draw.ED.Width:Value(), KoreanMechanics.Draw.ED.Color:Value())
	    	end
	    end		
	end
end

class "Brand"

function Brand:__init()
	print("Weedle's Brand Loaded")
	Callback.Add("Tick", function() self:Tick() end)
	Callback.Add("Draw", function() self:Draw() end)
	self:Menu()
end

function Brand:Menu()
	KoreanMechanics.Spell:MenuElement({id = "Q", name = "Q Key", key = string.byte("Q")})
	KoreanMechanics.Spell:MenuElement({id = "QR", name = "Q Range", value = 1150, min = 0, max = 1150, step = 10})
	KoreanMechanics.Spell:MenuElement({id = "W", name = "W Key", key = string.byte("W")})
	KoreanMechanics.Spell:MenuElement({id = "WR", name = "W Range", value = 1000, min = 0, max = 1000, step = 10})
	KoreanMechanics.Spell:MenuElement({id = "E", name = "E Key", key = string.byte("E")})
	KoreanMechanics.Spell:MenuElement({id = "ER", name = "E Range", value = 750, min = 0, max = 750, step = 10})
	KoreanMechanics.Spell:MenuElement({id = "R", name = "R Key", key = string.byte("R")})			

	KoreanMechanics.Draw:MenuElement({id = "QD", name = "Draw Q range", type = MENU})
    KoreanMechanics.Draw.QD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.QD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.QD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
    KoreanMechanics.Draw:MenuElement({id = "WD", name = "Draw W range", type = MENU})
    KoreanMechanics.Draw.WD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.WD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.WD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
    KoreanMechanics.Draw:MenuElement({id = "ED", name = "Draw E range", type = MENU})
    KoreanMechanics.Draw.ED:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.ED:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.ED:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
end

function Brand:Tick()
	if myHero.attackData.state == STATE_WINDUP then return end	
	if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then
		if KoreanMechanics.Spell.Q:Value() then
			self:Q()
		end
		if KoreanMechanics.Spell.W:Value() then
			self:W()
		end
		if KoreanMechanics.Spell.E:Value() then
			self:E()
		end	
		if KoreanMechanics.Spell.R:Value() then
			self:R()
		end				
	end
end

function Brand:Q()
	if Ready(_Q) then
local target =  _G.SDK.TargetSelector:GetTarget(1150)
if target == nil then return end 	
	local pos = GetPred(target, 1400, (0.25 + Game.Latency())/1000)
	Control.CastSpell(HK_Q, pos)
end
end		

function Brand:W()
	if Ready(_W) then
local target =  _G.SDK.TargetSelector:GetTarget(1000)	
if target == nil then return end 		
	local pos = GetPred(target, math.huge, 0.625 + Game.Latency()/1000)
	Control.CastSpell(HK_W, pos)
end
end	

function Brand:E()
	if Ready(_E) then
local target =  _G.SDK.TargetSelector:GetTarget(750)	
if target == nil then return end 		
	Control.CastSpell(HK_E, target.pos)
end
end	

function Brand:R()
	if Ready(_R) then
local target =  _G.SDK.TargetSelector:GetTarget(850)
if target == nil then return end 	
	Control.CastSpell(HK_R, target.pos)
end
end		

function Brand:Draw()
	if not myHero.dead then
	   	if KoreanMechanics.Draw.Enabled:Value() then
	   		local textPos = myHero.pos:To2D()
	   		if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then
				Draw.Text("Aimbot ON", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 000, 255, 000)) 		
			end
			if not KoreanMechanics.Enabled:Value() and not KoreanMechanics.Hold:Value() and KoreanMechanics.Draw.OFFDRAW:Value() then 
				Draw.Text("Aimbot OFF", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 255, 000, 000)) 
			end 
			if KoreanMechanics.Draw.QD.Enabled:Value() then
	    	    Draw.Circle(myHero.pos, KoreanMechanics.Spell.QR:Value(), KoreanMechanics.Draw.QD.Width:Value(), KoreanMechanics.Draw.QD.Color:Value())
	    	end
	    	if KoreanMechanics.Draw.WD.Enabled:Value() then
	    	    Draw.Circle(myHero.pos, KoreanMechanics.Spell.WR:Value(), KoreanMechanics.Draw.WD.Width:Value(), KoreanMechanics.Draw.WD.Color:Value())
	    	end
	    	if KoreanMechanics.Draw.ED.Enabled:Value() then
	    	    Draw.Circle(myHero.pos, KoreanMechanics.Spell.ER:Value(), KoreanMechanics.Draw.ED.Width:Value(), KoreanMechanics.Draw.ED.Color:Value())
	    	end	    	
	    end		
	end
end

class "Ziggs"

function Ziggs:__init()
	print("Weedle's Ziggs Loaded")
	Callback.Add("Tick", function() self:Tick() end)
	Callback.Add("Draw", function() self:Draw() end)
	self:Menu()
end	

function Ziggs:Menu()
	KoreanMechanics.Spell:MenuElement({id = "Q", name = "Q Key", key = string.byte("Q")})
	KoreanMechanics.Spell:MenuElement({id = "QR", name = "Q Range", value = 850, min = 0, max = 850, step = 10})
	KoreanMechanics.Spell:MenuElement({id = "W", name = "W Key", key = string.byte("W")})
	KoreanMechanics.Spell:MenuElement({id = "WR", name = "W Range", value = 1000, min = 0, max = 1000, step = 10})	
	KoreanMechanics.Spell:MenuElement({id = "E", name = "E Key", key = string.byte("E")})
	KoreanMechanics.Spell:MenuElement({id = "ER", name = "E Range", value = 900, min = 0, max = 900, step = 10})
	KoreanMechanics.Spell:MenuElement({id = "R", name = "R Key", key = string.byte("R")})	

	KoreanMechanics.Draw:MenuElement({id = "QD", name = "Draw Q range", type = MENU})
    KoreanMechanics.Draw.QD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.QD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.QD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
    KoreanMechanics.Draw:MenuElement({id = "WD", name = "Draw W range", type = MENU})
    KoreanMechanics.Draw.WD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.WD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.WD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
    KoreanMechanics.Draw:MenuElement({id = "ED", name = "Draw E range", type = MENU})
    KoreanMechanics.Draw.ED:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.ED:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.ED:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
end

function Ziggs:Tick()
	if myHero.attackData.state == STATE_WINDUP then return end	
	if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then
		if KoreanMechanics.Spell.Q:Value() then
			self:Q()
		end
		if KoreanMechanics.Spell.W:Value() then
			self:W()
		end
		if KoreanMechanics.Spell.E:Value() then
			self:E()
		end	
		if KoreanMechanics.Spell.R:Value() then
			self:R()
		end	
	end
end

function Ziggs:Q()
	if Ready(_Q) then
local target =  _G.SDK.TargetSelector:GetTarget(1500)
if target == nil then return end 	
	local pos = GetPred(target, 1750, (0.25 + Game.Latency())/1000)
	Control.CastSpell(HK_Q, pos)
end
end	

function Ziggs:W()
	if Ready(_W) then
local target =  _G.SDK.TargetSelector:GetTarget(1500)
if target == nil then return end 	
	local pos = GetPred(target, 1750, (0.25 + Game.Latency())/1000)
	Control.CastSpell(HK_W, pos)
end
end	

function Ziggs:E()
	if Ready(_E) then
local target =  _G.SDK.TargetSelector:GetTarget(1500)
if target == nil then return end 	
	local pos = GetPred(target, 1750, (0.25 + Game.Latency())/1000)
	Control.CastSpell(HK_E, pos)
end
end	

function Ziggs:R()
	if Ready(_R) then
local targety =  _G.SDK.TargetSelector:GetTarget()
	if targety == nil then return end 	
	local pos = GetPred(targety, 1750, 0.25 + Game.Latency()/1000)
	Control.CastSpell(HK_R, pos)
end
end

function Ziggs:Draw()
	if not myHero.dead then
	   	if KoreanMechanics.Draw.Enabled:Value() then
	   		local textPos = myHero.pos:To2D()
	   		if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then
				Draw.Text("Aimbot ON", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 000, 255, 000)) 		
			end
			if not KoreanMechanics.Enabled:Value() and not KoreanMechanics.Hold:Value() and KoreanMechanics.Draw.OFFDRAW:Value() then 
				Draw.Text("Aimbot OFF", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 255, 000, 000)) 
			end 
			if KoreanMechanics.Draw.QD.Enabled:Value() then
	    	    Draw.Circle(myHero.pos, KoreanMechanics.Spell.QR:Value(), KoreanMechanics.Draw.QD.Width:Value(), KoreanMechanics.Draw.QD.Color:Value())
	    	end
	    	if KoreanMechanics.Draw.WD.Enabled:Value() then
	    	    Draw.Circle(myHero.pos, KoreanMechanics.Spell.WR:Value(), KoreanMechanics.Draw.WD.Width:Value(), KoreanMechanics.Draw.WD.Color:Value())
	    	end
	    	if KoreanMechanics.Draw.ED.Enabled:Value() then
	    	    Draw.Circle(myHero.pos, KoreanMechanics.Spell.ER:Value(), KoreanMechanics.Draw.ED.Width:Value(), KoreanMechanics.Draw.ED.Color:Value())
	    	end	    	
	    end		
	end
end

class "Morgana"

function Morgana:__init()
	print("Weedle's Morgana Loaded")
	Callback.Add("Tick", function() self:Tick() end)
	Callback.Add("Draw", function() self:Draw() end)
	self:Menu()
end	

function Morgana:Menu()
	KoreanMechanics.Spell:MenuElement({id = "Q", name = "Q Key", key = string.byte("Q")})
	KoreanMechanics.Spell:MenuElement({id = "QR", name = "Q Range", value = 1300, min = 0, max = 1300, step = 10})
	KoreanMechanics.Spell:MenuElement({id = "W", name = "W Key", key = string.byte("W")})
	KoreanMechanics.Spell:MenuElement({id = "WR", name = "W Range", value = 900, min = 0, max = 900, step = 10})	

	KoreanMechanics.Draw:MenuElement({id = "QD", name = "Draw Q range", type = MENU})
    KoreanMechanics.Draw.QD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.QD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.QD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
    KoreanMechanics.Draw:MenuElement({id = "WD", name = "Draw W range", type = MENU})
    KoreanMechanics.Draw.WD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.WD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.WD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
end

function Morgana:Tick()
	if myHero.attackData.state == STATE_WINDUP then return end	
	if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then
		if KoreanMechanics.Spell.Q:Value() then
			self:Q()
		end
		if KoreanMechanics.Spell.W:Value() then
			self:W()
		end
	end
end

function Morgana:Q()
	if Ready(_Q) then
local target =  _G.SDK.TargetSelector:GetTarget(1400)
if target == nil then return end 	
	local pos = GetPred(target, 1200, (0.25 + Game.Latency())/1000)
	Control.CastSpell(HK_Q, pos)
end
end	

function Morgana:W()
	if Ready(_W) then
local target =  _G.SDK.TargetSelector:GetTarget(1000)
if target == nil then return end 	
	local pos = GetPred(target, math.huge, (0.25 + Game.Latency())/1000)
	Control.CastSpell(HK_W, pos)
end
end	

function Morgana:Draw()
	if not myHero.dead then
	   	if KoreanMechanics.Draw.Enabled:Value() then
	   		local textPos = myHero.pos:To2D()
	   		if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then
				Draw.Text("Aimbot ON", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 000, 255, 000)) 		
			end
			if not KoreanMechanics.Enabled:Value() and not KoreanMechanics.Hold:Value() and KoreanMechanics.Draw.OFFDRAW:Value() then 
				Draw.Text("Aimbot OFF", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 255, 000, 000)) 
			end 
			if KoreanMechanics.Draw.QD.Enabled:Value() then
	    	    Draw.Circle(myHero.pos, KoreanMechanics.Spell.QR:Value(), KoreanMechanics.Draw.QD.Width:Value(), KoreanMechanics.Draw.QD.Color:Value())
	    	end
	    	if KoreanMechanics.Draw.WD.Enabled:Value() then
	    	    Draw.Circle(myHero.pos, KoreanMechanics.Spell.WR:Value(), KoreanMechanics.Draw.WD.Width:Value(), KoreanMechanics.Draw.WD.Color:Value())
	    	end
	    end		
	end
end

class "Syndra"

function Syndra:__init()
	print("Weedle's Syndra Loaded")
	Callback.Add("Tick", function() self:Tick() end)
	Callback.Add("Draw", function() self:Draw() end)
	self:Menu()
end	

function Syndra:Menu()
	KoreanMechanics.Spell:MenuElement({id = "Q", name = "Q Key", key = string.byte("Q")})
	KoreanMechanics.Spell:MenuElement({id = "QR", name = "Q Range", value = 800, min = 0, max = 800, step = 10})
	KoreanMechanics.Spell:MenuElement({id = "W", name = "W Key", key = string.byte("W")})
	KoreanMechanics.Spell:MenuElement({id = "WR", name = "W Range", value = 925, min = 0, max = 925, step = 10})	
	KoreanMechanics.Spell:MenuElement({id = "E", name = "E Key", key = string.byte("E")})
	KoreanMechanics.Spell:MenuElement({id = "ER", name = "E Range", value = 650, min = 0, max = 650, step = 10})
	KoreanMechanics.Spell:MenuElement({id = "R", name = "R Key", key = string.byte("R")})			

	KoreanMechanics.Draw:MenuElement({id = "QD", name = "Draw Q range", type = MENU})
    KoreanMechanics.Draw.QD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.QD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.QD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
    KoreanMechanics.Draw:MenuElement({id = "WD", name = "Draw W range", type = MENU})
    KoreanMechanics.Draw.WD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.WD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.WD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
    KoreanMechanics.Draw:MenuElement({id = "ED", name = "Draw E range", type = MENU})
    KoreanMechanics.Draw.ED:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.ED:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.ED:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)}) 
end

function Syndra:Tick()
	if myHero.attackData.state == STATE_WINDUP then return end	
	if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then 
		if KoreanMechanics.Spell.Q:Value() then
			self:Q()
		end
		if KoreanMechanics.Spell.W:Value() and myHero:GetSpellData(_W).name == "SyndraWCast" then
			self:W()
		end
		if KoreanMechanics.Spell.E:Value() then
			self:E()
		end
		if KoreanMechanics.Spell.R:Value() then
			self:R()
		end		
	end
end

function Syndra:Q()
	if Ready(_Q) then
local target =  _G.SDK.TargetSelector:GetTarget(900)
if target == nil then return end 	
	local pos = GetPred(target, 1750, 0.25 + (Game.Latency()/1000))
	Control.CastSpell(HK_Q, pos)
end
end	

function Syndra:W()
	if Ready(_W) then
local target =  _G.SDK.TargetSelector:GetTarget(1025)
if target == nil then return end 	
	local pos = GetPred(target, 1450, (0.25 + Game.Latency())/1000)
	Control.CastSpell(HK_W, pos)
end
end		

function Syndra:E()
	if Ready(_E) then
local target =  _G.SDK.TargetSelector:GetTarget(900)
if target == nil then return end 	
	local pos = GetPred(target, 902, (0.25 + Game.Latency())/1000)
	Control.CastSpell(HK_E, pos)
end
end	

function Syndra:R()
	if Ready(_R) then
local target =  _G.SDK.TargetSelector:GetTarget(845)
if target == nil then return end 	
	Control.CastSpell(HK_R, target.pos)
end
end		

function Syndra:Draw()
	if not myHero.dead then
	   	if KoreanMechanics.Draw.Enabled:Value() then
	   		local textPos = myHero.pos:To2D()
	   		if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then
				Draw.Text("Aimbot ON", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 000, 255, 000)) 		
			end
			if not KoreanMechanics.Enabled:Value() and not KoreanMechanics.Hold:Value() and KoreanMechanics.Draw.OFFDRAW:Value() then 
				Draw.Text("Aimbot OFF", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 255, 000, 000)) 
			end 
			if KoreanMechanics.Draw.QD.Enabled:Value() then
	    	    Draw.Circle(myHero.pos, KoreanMechanics.Spell.QR:Value(), KoreanMechanics.Draw.QD.Width:Value(), KoreanMechanics.Draw.QD.Color:Value())
	    	end
	    	if KoreanMechanics.Draw.WD.Enabled:Value() then
	    	    Draw.Circle(myHero.pos, KoreanMechanics.Spell.WR:Value(), KoreanMechanics.Draw.WD.Width:Value(), KoreanMechanics.Draw.WD.Color:Value())
	    	end
	    	if KoreanMechanics.Draw.ED.Enabled:Value() then
	    	    Draw.Circle(myHero.pos, KoreanMechanics.Spell.ER:Value(), KoreanMechanics.Draw.ED.Width:Value(), KoreanMechanics.Draw.ED.Color:Value())
	    	end
	    end		
	end
end

class "KogMaw"

function KogMaw:__init()
	print("Weedle's Kog'Maw Loaded")
	Callback.Add("Tick", function() self:Tick() end)
	Callback.Add("Draw", function() self:Draw() end)
	self:Menu()
end	

function KogMaw:Menu()
	KoreanMechanics.Spell:MenuElement({id = "Q", name = "Q Key", key = string.byte("Q")})
	KoreanMechanics.Spell:MenuElement({id = "QR", name = "Q Range", value = 1175, min = 0, max = 1175, step = 25})
	KoreanMechanics.Spell:MenuElement({id = "E", name = "E Key", key = string.byte("E")})
	KoreanMechanics.Spell:MenuElement({id = "ER", name = "E Range", value = 1200, min = 0, max = 1200, step = 10})	
	KoreanMechanics.Spell:MenuElement({id = "R", name = "R Key", key = string.byte("R")})	

	KoreanMechanics.Draw:MenuElement({id = "QD", name = "Draw Q range", type = MENU})
    KoreanMechanics.Draw.QD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.QD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.QD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
    KoreanMechanics.Draw:MenuElement({id = "ED", name = "Draw E range", type = MENU})
    KoreanMechanics.Draw.ED:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.ED:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.ED:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)}) 
    KoreanMechanics.Draw:MenuElement({id = "RD", name = "Draw R range", type = MENU})
    KoreanMechanics.Draw.RD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.RD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.RD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})     
end

function KogMaw:Tick()
	if myHero.attackData.state == STATE_WINDUP then return end	
	if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then 
		if KoreanMechanics.Spell.Q:Value() then
			self:Q()
		end
		if KoreanMechanics.Spell.E:Value() then
			self:E()
		end
		if KoreanMechanics.Spell.R:Value() then
			self:R()
		end
	end
end

function KogMaw:Q()
	if Ready(_Q) then
local target =  _G.SDK.TargetSelector:GetTarget(1500)
if target == nil then return end 	
	local pos = GetPred(target, 1600, (0.25 + Game.Latency())/1000)
	Control.CastSpell(HK_Q, pos)
end
end	

function KogMaw:E()
	if Ready(_E) then
local target =  _G.SDK.TargetSelector:GetTarget(1500)
if target == nil then return end 	
	local pos = GetPred(target, 100, (0.33 + Game.Latency())/1000)
	Control.CastSpell(HK_E, pos)
end
end	

function KogMaw:R()
	if Ready(_R) then
local target =  _G.SDK.TargetSelector:GetTarget(1900)
if target == nil then return end 	
	local pos = GetPred(target, math.huge, 1 + (Game.Latency()/1000))
	Control.CastSpell(HK_R, pos)
end
end	

local function GetRlvl()
local lvl = myHero:GetSpellData(_R).level
	if lvl >= 1 then
		return (lvl + 1)
elseif lvl == nil then return 1
	end
end

function KogMaw:GetKogRange()
local level = GetRlvl()
	if level == nil then return 1
	end
local Range = (({0, 1200, 1500, 1800})[level])
	return Range 
end

function KogMaw:Draw()
	if not myHero.dead then
	   	if KoreanMechanics.Draw.Enabled:Value() then
	   		local textPos = myHero.pos:To2D()
	   		if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then
				Draw.Text("Aimbot ON", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 000, 255, 000)) 		
			end
			if not KoreanMechanics.Enabled:Value() and not KoreanMechanics.Hold:Value() and KoreanMechanics.Draw.OFFDRAW:Value() then 
				Draw.Text("Aimbot OFF", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 255, 000, 000)) 
			end 
			if KoreanMechanics.Draw.QD.Enabled:Value() then
	    	    Draw.Circle(myHero.pos, KoreanMechanics.Spell.QR:Value(), KoreanMechanics.Draw.QD.Width:Value(), KoreanMechanics.Draw.QD.Color:Value())
	    	end
	    	if KoreanMechanics.Draw.ED.Enabled:Value() then
	    	    Draw.Circle(myHero.pos, KoreanMechanics.Spell.ER:Value(), KoreanMechanics.Draw.ED.Width:Value(), KoreanMechanics.Draw.ED.Color:Value())
	    	end
	    	if KoreanMechanics.Draw.RD.Enabled:Value() then
	    	    Draw.Circle(myHero.pos, KogMaw:GetKogRange() , KoreanMechanics.Draw.RD.Width:Value(), KoreanMechanics.Draw.RD.Color:Value())
	    	end	    	
	    end		
	end
end

class "Lux"

function Lux:__init()
	print("Weedle's Lux Loaded")
	Callback.Add("Tick", function() self:Tick() end)
	Callback.Add("Draw", function() self:Draw() end)
	self:Menu()
end	

function Lux:Menu()
	KoreanMechanics.Spell:MenuElement({id = "Q", name = "Q Key", key = string.byte("Q")})
	KoreanMechanics.Spell:MenuElement({id = "QR", name = "Q Range", value = 1175, min = 0, max = 1175, step = 10})
	KoreanMechanics.Spell:MenuElement({id = "W", name = "W Key", key = string.byte("W")})	
	KoreanMechanics.Spell:MenuElement({id = "E", name = "E Key", key = string.byte("E")})
	KoreanMechanics.Spell:MenuElement({id = "ER", name = "E Range", value = 1200, min = 0, max = 1200, step = 10})	
	KoreanMechanics.Spell:MenuElement({id = "R", name = "R Key", key = string.byte("R")})

	KoreanMechanics.Draw:MenuElement({id = "QD", name = "Draw Q range", type = MENU})
    KoreanMechanics.Draw.QD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.QD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.QD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
    KoreanMechanics.Draw:MenuElement({id = "ED", name = "Draw E range", type = MENU})
    KoreanMechanics.Draw.ED:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.ED:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.ED:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)}) 
    KoreanMechanics.Draw:MenuElement({id = "RD", name = "Draw R range", type = MENU})
    KoreanMechanics.Draw.RD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.RD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.RD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})     
end

function Lux:Tick()
	if myHero.attackData.state == STATE_WINDUP then return end	
	if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then 
		if KoreanMechanics.Spell.Q:Value() then
			self:Q()
		end
		if KoreanMechanics.Spell.W:Value() then
			self:W()
		end		
		if KoreanMechanics.Spell.E:Value() and myHero:GetSpellData(_E).name == "LuxLightStrikeKugel" then
			self:E()
		end
		if KoreanMechanics.Spell.R:Value() then
			self:R()
		end
	end
end

function Lux:Q()
	if Ready(_Q) then
local target =  _G.SDK.TargetSelector:GetTarget(1500)
if target == nil then return end 	
	local pos = GetPred(target, 1200, (0.25 + Game.Latency())/1000)
	Control.CastSpell(HK_Q, pos)
end
end	

function Lux:W()
	if Ready(_W) then
local Heroes = nil
	for i = 1, Game.HeroCount() do
	local Heroes = Game.Hero(i)
		if Heroes.distance < 1000 and Heroes.isAlly and not Heroes.dead and Heroes.charName ~= "Lux" then
			local pos = GetPred(Heroes, 1400, (0.25 + Game.Latency())/1000)
			Control.CastSpell(HK_W, pos)
		end
	end
end
end

function Lux:E()
	if Ready(_E) then
local target =  _G.SDK.TargetSelector:GetTarget(1500)
if target == nil then return end 	
	local pos = GetPred(target, 1300, (0.25 + Game.Latency())/1000)
	Control.CastSpell(HK_E, pos)
end
end	

function Lux:R()
	if Ready(_R) then
local target =  _G.SDK.TargetSelector:GetTarget(3440)
if target == nil then return end 	
	local pos = GetPred(target, 3000, 1 + (Game.Latency()/1000))
	Control.CastSpell(HK_R, pos)
end
end	

function Lux:Draw()
	if not myHero.dead then
	   	if KoreanMechanics.Draw.Enabled:Value() then
	   		local textPos = myHero.pos:To2D()
	   		if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then
				Draw.Text("Aimbot ON", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 000, 255, 000)) 		
			end
			if not KoreanMechanics.Enabled:Value() and not KoreanMechanics.Hold:Value() and KoreanMechanics.Draw.OFFDRAW:Value() then 
				Draw.Text("Aimbot OFF", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 255, 000, 000)) 
			end 
			if KoreanMechanics.Draw.QD.Enabled:Value() then
	    	    Draw.Circle(myHero.pos, KoreanMechanics.Spell.QR:Value(), KoreanMechanics.Draw.QD.Width:Value(), KoreanMechanics.Draw.QD.Color:Value())
	    	end
	    	if KoreanMechanics.Draw.ED.Enabled:Value() then
	    	    Draw.Circle(myHero.pos, KoreanMechanics.Spell.ER:Value(), KoreanMechanics.Draw.ED.Width:Value(), KoreanMechanics.Draw.ED.Color:Value())
	    	end
	    	if KoreanMechanics.Draw.RD.Enabled:Value() then
	    	    Draw.CircleMinimap(myHero.pos, 3340 , KoreanMechanics.Draw.RD.Width:Value(), KoreanMechanics.Draw.RD.Color:Value())
	    	end	    	
	    end		
	end
end

class "Cassiopeia"

function Cassiopeia:__init()
	print("Weedle's Cassiopeia Loaded")
	Callback.Add("Tick", function() self:Tick() end)
	Callback.Add("Draw", function() self:Draw() end)
	self:Menu()
end	

function Cassiopeia:Menu()
	KoreanMechanics.Spell:MenuElement({id = "Q", name = "Q Key", key = string.byte("Q")})
	KoreanMechanics.Spell:MenuElement({id = "QR", name = "Q Range", value = 850, min = 0, max = 850, step = 10})
	KoreanMechanics.Spell:MenuElement({id = "W", name = "W Key", key = string.byte("W")})
	KoreanMechanics.Spell:MenuElement({id = "WR", name = "W Range", value = 800, min = 0, max = 800, step = 10})	
	KoreanMechanics.Spell:MenuElement({id = "E", name = "E Usage", key = string.byte("E")})	
	KoreanMechanics.Spell:MenuElement({id = "R", name = "R Key", key = string.byte("R")})

	KoreanMechanics.Draw:MenuElement({id = "QD", name = "Draw Q range", type = MENU})
    KoreanMechanics.Draw.QD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.QD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.QD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
    KoreanMechanics.Draw:MenuElement({id = "WD", name = "Draw W range", type = MENU})
    KoreanMechanics.Draw.WD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.WD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.WD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)}) 
    KoreanMechanics.Draw:MenuElement({id = "RD", name = "Draw R range", type = MENU})
    KoreanMechanics.Draw.RD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.RD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.RD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})     
end

function Cassiopeia:Tick()
	if myHero.attackData.state == STATE_WINDUP then return end	
	if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then 
		if KoreanMechanics.Spell.Q:Value() then
			self:Q()
		end
		if KoreanMechanics.Spell.W:Value() then
			self:W()
		end
		if KoreanMechanics.Spell.E:Value() then
			self:E()
		end		
		if KoreanMechanics.Spell.R:Value() then
			self:R()
		end
	end
end

function Cassiopeia:Q()
	if Ready(_Q) then
local target =  _G.SDK.TargetSelector:GetTarget(950)
if target == nil then return end 	
	local pos = GetPred(target, math.huge, 0.41 + (Game.Latency()/1000))
	Control.CastSpell(HK_Q, pos)
end
end	

function Cassiopeia:W()
	if Ready(_W) then
local target =  _G.SDK.TargetSelector:GetTarget(900)
if target == nil then return end 	
	local pos = GetPred(target, 1500, (0.25 + Game.Latency())/1000)
	Control.CastSpell(HK_W, pos)
end
end		

function Cassiopeia:E()
	if Ready(_E) then
local target =  _G.SDK.TargetSelector:GetTarget(800)
if target == nil then return end 	
	Control.CastSpell(HK_E, target)
end
end		

function Cassiopeia:R()
	if Ready(_R) then
local target =  _G.SDK.TargetSelector:GetTarget(925)
if target == nil then return end 	
	local pos = GetPred(target, 1500, (0.25 + Game.Latency())/1000)
	Control.CastSpell(HK_R, pos)
end
end			

function Cassiopeia:Draw()
	if not myHero.dead then
	   	if KoreanMechanics.Draw.Enabled:Value() then
	   		local textPos = myHero.pos:To2D()
	   		if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then
				Draw.Text("Aimbot ON", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 000, 255, 000)) 		
			end
			if not KoreanMechanics.Enabled:Value() and not KoreanMechanics.Hold:Value() and KoreanMechanics.Draw.OFFDRAW:Value() then 
				Draw.Text("Aimbot OFF", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 255, 000, 000)) 
			end 
			if KoreanMechanics.Draw.QD.Enabled:Value() then
	    	    Draw.Circle(myHero.pos, KoreanMechanics.Spell.QR:Value(), KoreanMechanics.Draw.QD.Width:Value(), KoreanMechanics.Draw.QD.Color:Value())
	    	end
	    	if KoreanMechanics.Draw.WD.Enabled:Value() then
	    	    Draw.Circle(myHero.pos, KoreanMechanics.Spell.WR:Value(), KoreanMechanics.Draw.WD.Width:Value(), KoreanMechanics.Draw.WD.Color:Value())
	    	end
	    	if KoreanMechanics.Draw.RD.Enabled:Value() then
	    	    Draw.Circle(myHero.pos, 825 , KoreanMechanics.Draw.RD.Width:Value(), KoreanMechanics.Draw.RD.Color:Value())
	    	end	    	
	    end		
	end
end

class "Karma"

function Karma:__init()
	print("Weedle's Karma Loaded")
	Callback.Add("Tick", function() self:Tick() end)
	Callback.Add("Draw", function() self:Draw() end)
	self:Menu()
end	

function Karma:Menu()
	KoreanMechanics.Spell:MenuElement({id = "Q", name = "Q Key", key = string.byte("Q")})
	KoreanMechanics.Spell:MenuElement({id = "QR", name = "Q Range", value = 950, min = 0, max = 950, step = 10})
	KoreanMechanics.Spell:MenuElement({id = "W", name = "W Key", key = string.byte("W")})		
	KoreanMechanics.Spell:MenuElement({id = "E", name = "E Key", key = string.byte("E")})
	KoreanMechanics.Spell:MenuElement({id = "EMode", name = "self E Toggle", key = string.byte("T"), toggle = true})	

	KoreanMechanics.Draw:MenuElement({id = "QD", name = "Draw Q range", type = MENU})
    KoreanMechanics.Draw.QD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.QD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.QD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
    KoreanMechanics.Draw:MenuElement({id = "WD", name = "Draw W range", type = MENU})
    KoreanMechanics.Draw.WD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.WD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.WD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})     
    KoreanMechanics.Draw:MenuElement({id = "ED", name = "Draw E range", type = MENU})
    KoreanMechanics.Draw.ED:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.ED:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.ED:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})     
end

function Karma:Tick()
	if myHero.attackData.state == STATE_WINDUP then return end	
	if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then 
		if KoreanMechanics.Spell.Q:Value() then
			self:Q()
		end
		if KoreanMechanics.Spell.W:Value() then
			self:W()
		end
		if KoreanMechanics.Spell.E:Value() then
			self:E()
		end			
	end
end

function Karma:Q()
	if Ready(_Q) then
local target =  _G.SDK.TargetSelector:GetTarget(1050)
if target == nil then return end 	
	local pos = GetPred(target, math.huge, (0.25 + Game.Latency())/1000)
	Control.CastSpell(HK_Q, pos)
end
end	

function Karma:W()
	if Ready(_W) then
local target =  _G.SDK.TargetSelector:GetTarget(775)
if target == nil then return end 	
	Control.CastSpell(HK_W, target)
end
end

function Karma:E()
	if Ready(_E) then
	if KoreanMechanics.Spell.EMode:Value() then
		Control.CastSpell(HK_E, myHero)
	end
	Control.CastSpell(HK_E, mousePos)
end
end

function Karma:Draw()
	if not myHero.dead then
		if KoreanMechanics.Draw.Enabled:Value() then
			local textPos = myHero.pos:To2D()
			if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then
				Draw.Text("Aimbot ON", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 000, 255, 000)) 		
			end
			if not KoreanMechanics.Enabled:Value() and not KoreanMechanics.Hold:Value() and KoreanMechanics.Draw.OFFDRAW:Value() then 
				Draw.Text("Aimbot OFF", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 255, 000, 000)) 
			end
			if KoreanMechanics.Spell.EMode:Value() then
				Draw.Text("Self Shield ON", 20, textPos.x - 80, textPos.y + 60, Draw.Color(255, 000, 255, 000)) 		
			end
			if not KoreanMechanics.Spell.EMode:Value()  then 
				Draw.Text("Self Shield OFF", 20, textPos.x - 80, textPos.y + 60, Draw.Color(255, 255, 000, 000)) 
			end 			 
			if KoreanMechanics.Draw.QD.Enabled:Value() then
			    Draw.Circle(myHero.pos, KoreanMechanics.Spell.QR:Value(), KoreanMechanics.Draw.QD.Width:Value(), KoreanMechanics.Draw.QD.Color:Value())
			end
	    	if KoreanMechanics.Draw.WD.Enabled:Value() then
	    	    Draw.Circle(myHero.pos, 675, KoreanMechanics.Draw.WD.Width:Value(), KoreanMechanics.Draw.WD.Color:Value())
	    	end			
	    	if KoreanMechanics.Draw.ED.Enabled:Value() then
	    	    Draw.Circle(myHero.pos, 800, KoreanMechanics.Draw.ED.Width:Value(), KoreanMechanics.Draw.ED.Color:Value())
	    	end	 			
		end
	end
end

class "Orianna"

function Orianna:__init()
	print("Weedle's Orianna Loaded")
	Callback.Add("Tick", function() self:Tick() end)
	Callback.Add("Draw", function() self:Draw() end)
	self:Menu()
end	

function Orianna:Menu()
	KoreanMechanics.Spell:MenuElement({id = "Q", name = "Q Key", key = string.byte("Q")})
	KoreanMechanics.Spell:MenuElement({id = "QR", name = "Q Range", value = 1225, min = 0, max = 1225, step = 25})
	KoreanMechanics.Spell:MenuElement({id = "E", name = "E Key", key = string.byte("E")})	
	KoreanMechanics.Spell:MenuElement({id = "EMode", name = "self E Toggle", key = string.byte("T"), toggle = true})

	KoreanMechanics.Draw:MenuElement({id = "QD", name = "Draw Max Q range", type = MENU})
    KoreanMechanics.Draw.QD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.QD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.QD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
end

function Orianna:Tick()
	if myHero.attackData.state == STATE_WINDUP then return end	
	if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then 
		if KoreanMechanics.Spell.Q:Value() then
			self:Q()
		end
		if KoreanMechanics.Spell.E:Value() then
			self:E()
		end
	end
end

function Orianna:Q()
	if Ready(_Q) then
local target =  _G.SDK.TargetSelector:GetTarget(1225)
if target == nil then return end 	
	local pos = GetPred(target, 1200, (0.25 + Game.Latency())/1000)
	Control.CastSpell(HK_Q, pos)
end
end	

function Orianna:E()
if Ready(_E) then
	if KoreanMechanics.Spell.EMode:Value() then
		Control.CastSpell(HK_E, myHero)
	end
end
end		

function Orianna:Draw()
	if not myHero.dead then
		if KoreanMechanics.Draw.Enabled:Value() then
			local textPos = myHero.pos:To2D()
			if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then
				Draw.Text("Aimbot ON", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 000, 255, 000)) 		
			end
			if not KoreanMechanics.Enabled:Value() and not KoreanMechanics.Hold:Value() and KoreanMechanics.Draw.OFFDRAW:Value() then 
				Draw.Text("Aimbot OFF", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 255, 000, 000)) 
			end 
			if KoreanMechanics.Spell.EMode:Value() then
				Draw.Text("Self E ON", 20, textPos.x - 80, textPos.y + 60, Draw.Color(255, 000, 255, 000)) 		
			end
			if not KoreanMechanics.Spell.EMode:Value()  then 
				Draw.Text("Self E OFF", 20, textPos.x - 80, textPos.y + 60, Draw.Color(255, 255, 000, 000)) 
			end 				
			if KoreanMechanics.Draw.QD.Enabled:Value() then
			    Draw.Circle(myHero.pos, KoreanMechanics.Spell.QR:Value(), KoreanMechanics.Draw.QD.Width:Value(), KoreanMechanics.Draw.QD.Color:Value())
			end
		end
	end
end

class "Ryze"

function Ryze:__init()
	print("Weedle's Ryze Loaded")
	Callback.Add("Tick", function() self:Tick() end)
	Callback.Add("Draw", function() self:Draw() end)
	self:Menu()
end	

function Ryze:Menu()
	KoreanMechanics.Spell:MenuElement({id = "Q", name = "Q Key", key = string.byte("Q")})
	KoreanMechanics.Spell:MenuElement({id = "QR", name = "Q Range", value = 1000, min = 0, max = 1000, step = 10})
	KoreanMechanics.Spell:MenuElement({id = "W", name = "W Key", key = string.byte("W")})
	KoreanMechanics.Spell:MenuElement({id = "WR", name = "W Range", value = 615, min = 0, max = 615, step = 10})	
	KoreanMechanics.Spell:MenuElement({id = "E", name = "E Usage", key = string.byte("E")})	
	KoreanMechanics.Spell:MenuElement({id = "ER", name = "E Range", value = 615, min = 0, max = 615, step = 10})

	KoreanMechanics.Draw:MenuElement({id = "QD", name = "Draw Q range", type = MENU})
    KoreanMechanics.Draw.QD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.QD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.QD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
    KoreanMechanics.Draw:MenuElement({id = "WD", name = "Draw W range", type = MENU})
    KoreanMechanics.Draw.WD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.WD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.WD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)}) 
    KoreanMechanics.Draw:MenuElement({id = "ED", name = "Draw E range", type = MENU})
    KoreanMechanics.Draw.ED:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.ED:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.ED:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})  
end

function Ryze:Tick()
	if myHero.attackData.state == STATE_WINDUP then return end	
	if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then 
		if KoreanMechanics.Spell.Q:Value() then
			self:Q()
		end
		if KoreanMechanics.Spell.W:Value() then
			self:W()
		end
		if KoreanMechanics.Spell.E:Value() then
			self:E()
		end	
	end
end

function Ryze:Q()
	if Ready(_Q) then
local target =  _G.SDK.TargetSelector:GetTarget(1100)
if target == nil then return end 	
	local pos = GetPred(target, 1700, (0.25 + Game.Latency())/1000)
	Control.CastSpell(HK_Q, pos)
end
end	

function Ryze:W()
	if Ready(_W) then
local target =  _G.SDK.TargetSelector:GetTarget(800)
if target == nil then return end 	
	Control.CastSpell(HK_W, pos)
end
end	

function Ryze:E()
	if Ready(_E) then
local target =  _G.SDK.TargetSelector:GetTarget(800)
if target == nil then return end 	
	Control.CastSpell(HK_E, target)
end
end	

function Ryze:Draw()
	if not myHero.dead then
	   	if KoreanMechanics.Draw.Enabled:Value() then
	   		local textPos = myHero.pos:To2D()
	   		if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then
				Draw.Text("Aimbot ON", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 000, 255, 000)) 		
			end
			if not KoreanMechanics.Enabled:Value() and not KoreanMechanics.Hold:Value() and KoreanMechanics.Draw.OFFDRAW:Value() then 
				Draw.Text("Aimbot OFF", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 255, 000, 000)) 
			end 
			if KoreanMechanics.Draw.QD.Enabled:Value() then
	    	    Draw.Circle(myHero.pos, KoreanMechanics.Spell.QR:Value(), KoreanMechanics.Draw.QD.Width:Value(), KoreanMechanics.Draw.QD.Color:Value())
	    	end
	    	if KoreanMechanics.Draw.WD.Enabled:Value() then
	    	    Draw.Circle(myHero.pos, KoreanMechanics.Spell.WR:Value(), KoreanMechanics.Draw.WD.Width:Value(), KoreanMechanics.Draw.WD.Color:Value())
	    	end
	    	if KoreanMechanics.Draw.ED.Enabled:Value() then
	    	    Draw.Circle(myHero.pos, KoreanMechanics.Spell.ER:Value(), KoreanMechanics.Draw.ED.Width:Value(), KoreanMechanics.Draw.ED.Color:Value())
	    	end	    	
	    end		
	end
end

class "Jhin"

function Jhin:__init()
	print("Weedle's Jhin Loaded")
	Callback.Add("Tick", function() self:Tick() end)
	Callback.Add("Draw", function() self:Draw() end)
	self:Menu()
end	

function Jhin:Menu()
	KoreanMechanics.Spell:MenuElement({id = "Q", name = "Q Key", key = string.byte("Q")})
	KoreanMechanics.Spell:MenuElement({id = "W", name = "W Key", key = string.byte("W")})
	KoreanMechanics.Spell:MenuElement({id = "WR", name = "W Range", value = 2500, min = 0, max = 600, step = 10})		
	KoreanMechanics.Spell:MenuElement({id = "R", name = "R Key", key = string.byte("R")})

	KoreanMechanics.Draw:MenuElement({id = "QD", name = "Draw Q range", type = MENU})
    KoreanMechanics.Draw.QD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.QD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.QD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
    KoreanMechanics.Draw:MenuElement({id = "WD", name = "Draw W range", type = MENU})
    KoreanMechanics.Draw.WD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.WD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.WD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})   
    KoreanMechanics.Draw:MenuElement({id = "RD", name = "Draw R range", type = MENU})
    KoreanMechanics.Draw.RD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.RD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.RD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})   
end

function Jhin:Tick()
	if myHero.attackData.state == STATE_WINDUP then return end	
	if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then 
		if KoreanMechanics.Spell.Q:Value() then
			self:Q()
		end
		if KoreanMechanics.Spell.W:Value() then
			self:W()
		end
		if KoreanMechanics.Spell.R:Value() then
			self:R()
		end				
	end
end

function Jhin:Q()
	if Ready(_Q) then
local target =  _G.SDK.TargetSelector:GetTarget(800)
if target == nil then return end 	
	Control.CastSpell(HK_Q, target)
end
end		

function Jhin:W()
	if Ready(_W) then	
local target =  _G.SDK.TargetSelector:GetTarget(2600)
if target == nil then return end 	
	local pos = GetPred(target, 5000, 0.25 + (Game.Latency()/1000))
	Control.CastSpell(HK_W, pos)
end
end	

function Jhin:R()
	if Ready(_R) or myHero:GetSpellData(_R).name == "JhinRShot" then
local target =  _G.SDK.TargetSelector:GetTarget(3100)
if target == nil then return end 	
	local pos = GetPred(target, 1200, 1 + (Game.Latency()/1000))
	Control.CastSpell(HK_R, pos)
end
end	

function Jhin:Draw()
	if not myHero.dead then
	   	if KoreanMechanics.Draw.Enabled:Value() then
	   		local textPos = myHero.pos:To2D()
	   		if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then
				Draw.Text("Aimbot ON", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 000, 255, 000)) 		
			end
			if not KoreanMechanics.Enabled:Value() and not KoreanMechanics.Hold:Value() and KoreanMechanics.Draw.OFFDRAW:Value() then 
				Draw.Text("Aimbot OFF", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 255, 000, 000)) 
			end 
			if KoreanMechanics.Draw.QD.Enabled:Value() then
	    	    Draw.Circle(myHero.pos, 600, KoreanMechanics.Draw.QD.Width:Value(), KoreanMechanics.Draw.QD.Color:Value())
	    	end
	    	if KoreanMechanics.Draw.WD.Enabled:Value() then
	    	    Draw.Circle(myHero.pos, KoreanMechanics.Spell.WR:Value(), KoreanMechanics.Draw.WD.Width:Value(), KoreanMechanics.Draw.WD.Color:Value())
	    	end
	    	if KoreanMechanics.Draw.RD.Enabled:Value() then
	    	    Draw.Circleminimap(myHero.pos, 3000 , KoreanMechanics.Draw.RD.Width:Value(), KoreanMechanics.Draw.RD.Color:Value())
	    	end	   	    	   	
	    end		
	end
end

class "Jayce"

function Jayce:__init()
	print("Weedle's Jayce Loaded")
	Callback.Add("Tick", function() self:Tick() end)
	Callback.Add("Draw", function() self:Draw() end)
	self:Menu()
end	

function Jayce:Menu()
	KoreanMechanics.Spell:MenuElement({id = "Q", name = "Q Key", key = string.byte("Q")})
	KoreanMechanics.Spell:MenuElement({id = "QR", name = "Q Max Range", value = 1600, min = 0, max = 1600, step = 10})

	KoreanMechanics.Draw:MenuElement({id = "QD", name = "Draw Q range", type = MENU})
    KoreanMechanics.Draw.QD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.QD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.QD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
end

function Jayce:Tick()
	if myHero.attackData.state == STATE_WINDUP then return end	
	if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then 
		if KoreanMechanics.Spell.Q:Value() and myHero:GetSpellData(_Q).name == "JayceShockBlast" then
			self:Q()
		end
	end
end

function Jayce:Q()
	if Ready(_Q) then
local target =  _G.SDK.TargetSelector:GetTarget(1600)
if target == nil then return end 	
	local pos = GetPred(target, 1382, (0.25 + Game.Latency())/1000)
	Control.CastSpell(HK_Q, pos)
end
end	

function Jayce:Draw()
	if not myHero.dead then
		if KoreanMechanics.Draw.Enabled:Value() then
			local textPos = myHero.pos:To2D()
			if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then
				Draw.Text("Aimbot ON", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 000, 255, 000)) 		
			end
			if not KoreanMechanics.Enabled:Value() and not KoreanMechanics.Hold:Value() and KoreanMechanics.Draw.OFFDRAW:Value() then 
				Draw.Text("Aimbot OFF", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 255, 000, 000)) 
			end 
			if KoreanMechanics.Draw.QD.Enabled:Value() then
			    Draw.Circle(myHero.pos, KoreanMechanics.Spell.QR:Value(), KoreanMechanics.Draw.QD.Width:Value(), KoreanMechanics.Draw.QD.Color:Value())
			end
		end
	end
end

class "Kennen"

function Kennen:__init()
	print("Weedle's Kennen Loaded")
	Callback.Add("Tick", function() self:Tick() end)
	Callback.Add("Draw", function() self:Draw() end)
	self:Menu()
end	

function Kennen:Menu()
	KoreanMechanics.Spell:MenuElement({id = "Q", name = "Q Key", key = string.byte("Q")})
	KoreanMechanics.Spell:MenuElement({id = "QR", name = "Q Range", value = 950, min = 0, max = 950, step = 10})

	KoreanMechanics.Draw:MenuElement({id = "QD", name = "Draw Q range", type = MENU})
    KoreanMechanics.Draw.QD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.QD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.QD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
end

function Kennen:Tick()
	if myHero.attackData.state == STATE_WINDUP then return end	
	if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then 
		if KoreanMechanics.Spell.Q:Value() then
			self:Q()
		end
	end
end

function Kennen:Q()
	if Ready(_Q) then
local target =  _G.SDK.TargetSelector:GetTarget(1050)
if target == nil then return end 	
	local pos = GetPred(target, 1700, (0.25 + Game.Latency())/1000)
	Control.CastSpell(HK_Q, pos)
end
end	

function Kennen:Draw()
	if not myHero.dead then
		if KoreanMechanics.Draw.Enabled:Value() then
			local textPos = myHero.pos:To2D()
			if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then
				Draw.Text("Aimbot ON", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 000, 255, 000)) 		
			end
			if not KoreanMechanics.Enabled:Value() and not KoreanMechanics.Hold:Value() and KoreanMechanics.Draw.OFFDRAW:Value() then 
				Draw.Text("Aimbot OFF", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 255, 000, 000)) 
			end 
			if KoreanMechanics.Draw.QD.Enabled:Value() then
			    Draw.Circle(myHero.pos, KoreanMechanics.Spell.QR:Value(), KoreanMechanics.Draw.QD.Width:Value(), KoreanMechanics.Draw.QD.Color:Value())
			end
		end
	end
end

class "Thresh"

function Thresh:__init()
	print("Weedle's Thresh Loaded")
	Callback.Add("Tick", function() self:Tick() end)
	Callback.Add("Draw", function() self:Draw() end)
	self:Menu()
end	

function Thresh:Menu()
	KoreanMechanics.Spell:MenuElement({id = "Q", name = "Q Key", key = string.byte("Q")})
	KoreanMechanics.Spell:MenuElement({id = "QR", name = "Q Range", value = 1050, min = 0, max = 1050, step = 10})
	KoreanMechanics.Spell:MenuElement({id = "E", name = "E Key", key = string.byte("E")})	
	KoreanMechanics.Spell:MenuElement({id = "EMode", name = "E Pull Toggle", key = string.byte("T"), toggle = true})	

	KoreanMechanics.Draw:MenuElement({id = "QD", name = "Draw Q range", type = MENU})
    KoreanMechanics.Draw.QD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.QD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.QD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
end

function Thresh:Tick()
	if myHero.attackData.state == STATE_WINDUP then return end	
	if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then 
		if KoreanMechanics.Spell.Q:Value() and myHero:GetSpellData(_Q).name == "ThreshQ" then
			self:Q()
		end
		if KoreanMechanics.Spell.E:Value() then
			self:E()
		end		
	end
end

function Thresh:Q()
	if Ready(_Q) then
local target =  _G.SDK.TargetSelector:GetTarget(1500)
if target == nil then return end 	
	local pos = GetPred(target, 1900, 0.5 + (Game.Latency()/1000))
	Control.CastSpell(HK_Q, pos)
end
end	

function Thresh:E()
	if Ready(_E) then
local target =  _G.SDK.TargetSelector:GetTarget(600)
if target == nil then return end 
	local pos = GetPred(target, 2000, 0.25 + (0.25 + Game.Latency())/1000)
	if KoreanMechanics.Spell.EMode:Value() then
		local pos2 = Vector(myHero.pos) + (Vector(myHero.pos) - Vector(pos)):Normalized()*400
				Control.CastSpell(HK_E, pos2)
	end
	Control.CastSpell(HK_E, pos)
end
end

function Thresh:Draw()
	if not myHero.dead then
		if KoreanMechanics.Draw.Enabled:Value() then
			local textPos = myHero.pos:To2D()
			if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then
				Draw.Text("Aimbot ON", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 000, 255, 000)) 		
			end
			if not KoreanMechanics.Enabled:Value() and not KoreanMechanics.Hold:Value() and KoreanMechanics.Draw.OFFDRAW:Value() then 
				Draw.Text("Aimbot OFF", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 255, 000, 000)) 
			end
			if KoreanMechanics.Spell.EMode:Value() then
				Draw.Text("E Pull Mode ON", 20, textPos.x - 80, textPos.y + 60, Draw.Color(255, 000, 255, 000)) 		
			end
			if not KoreanMechanics.Spell.EMode:Value()  then 
				Draw.Text("U Pull Mode OFF", 20, textPos.x - 80, textPos.y + 60, Draw.Color(255, 255, 000, 000)) 
			end 			 
			if KoreanMechanics.Draw.QD.Enabled:Value() then
			    Draw.Circle(myHero.pos, KoreanMechanics.Spell.QR:Value(), KoreanMechanics.Draw.QD.Width:Value(), KoreanMechanics.Draw.QD.Color:Value())
			end
		end
	end
end

class "Amumu"

function Amumu:__init()
	print("Weedle's Amumu Loaded")
	Callback.Add("Tick", function() self:Tick() end)
	Callback.Add("Draw", function() self:Draw() end)
	self:Menu()
end	

function Amumu:Menu()
	KoreanMechanics.Spell:MenuElement({id = "Q", name = "Q Key", key = string.byte("Q")})
	KoreanMechanics.Spell:MenuElement({id = "QR", name = "Q Range", value = 1100, min = 0, max = 1100, step = 10})

	KoreanMechanics.Draw:MenuElement({id = "QD", name = "Draw Q range", type = MENU})
    KoreanMechanics.Draw.QD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.QD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.QD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
end

function Amumu:Tick()
	if myHero.attackData.state == STATE_WINDUP then return end	
	if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then 
		if KoreanMechanics.Spell.Q:Value() then
			self:Q()
		end
	end
end

function Amumu:Q()
	if Ready(_Q) then
local target =  _G.SDK.TargetSelector:GetTarget(1200)
if target == nil then return end 	
	local pos = GetPred(target, 2000, 0.15 + (Game.Latency()/1000))
	Control.CastSpell(HK_Q, pos)
end
end	

function Amumu:Draw()
	if not myHero.dead then
		if KoreanMechanics.Draw.Enabled:Value() then
			local textPos = myHero.pos:To2D()
			if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then
				Draw.Text("Aimbot ON", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 000, 255, 000)) 		
			end
			if not KoreanMechanics.Enabled:Value() and not KoreanMechanics.Hold:Value() and KoreanMechanics.Draw.OFFDRAW:Value() then 
				Draw.Text("Aimbot OFF", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 255, 000, 000)) 
			end 
			if KoreanMechanics.Draw.QD.Enabled:Value() then
			    Draw.Circle(myHero.pos, KoreanMechanics.Spell.QR:Value(), KoreanMechanics.Draw.QD.Width:Value(), KoreanMechanics.Draw.QD.Color:Value())
			end
		end
	end
end

class "Elise"

function Elise:__init()
	print("Weedle's Elise Loaded")
	Callback.Add("Tick", function() self:Tick() end)
	Callback.Add("Draw", function() self:Draw() end)
	self:Menu()
end	

function Elise:Menu()
	KoreanMechanics.Spell:MenuElement({id = "Q", name = "Q Key", key = string.byte("Q")})
	KoreanMechanics.Spell:MenuElement({id = "QR", name = "max Q Range", value = 625, min = 0, max = 625, step = 10})
	KoreanMechanics.Spell:MenuElement({id = "W", name = "W Key", key = string.byte("W")})
	KoreanMechanics.Spell:MenuElement({id = "WR", name = "W Range", value = 950, min = 0, max = 950, step = 10})		
	KoreanMechanics.Spell:MenuElement({id = "E", name = "E Usage", key = string.byte("E")})	
	KoreanMechanics.Spell:MenuElement({id = "ER", name = "E Range", value = 1075, min = 0, max = 1075, step = 10})
	KoreanMechanics.Spell:MenuElement({id = "EMode", name = "Spider E on Enemy Toggle", key = string.byte("T"), toggle = true})		

	KoreanMechanics.Draw:MenuElement({id = "QD", name = "Draw Q range", type = MENU})
    KoreanMechanics.Draw.QD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.QD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.QD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
    KoreanMechanics.Draw:MenuElement({id = "WD", name = "Draw W range", type = MENU})
    KoreanMechanics.Draw.WD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.WD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.WD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)}) 
    KoreanMechanics.Draw:MenuElement({id = "ED", name = "Draw E range", type = MENU})
    KoreanMechanics.Draw.ED:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.ED:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.ED:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})  
end

function Elise:Tick()
	if myHero.attackData.state == STATE_WINDUP then return end	
	if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then 
		if KoreanMechanics.Spell.Q:Value() then
			self:Q()
		end
		if KoreanMechanics.Spell.W:Value() and myHero:GetSpellData(_W).name == "EliseHumanW" then
			self:W()
		end
		if KoreanMechanics.Spell.E:Value() then
			self:E()
		end	
	end
end

function Elise:Q()
	if Ready(_Q) then
local target =  _G.SDK.TargetSelector:GetTarget(725)
if target == nil then return end 	
	Control.CastSpell(HK_Q, pos)
end
end	

function Elise:W()
	if Ready(_W) then
local target =  _G.SDK.TargetSelector:GetTarget(1050)
if target == nil then return end 	
	local pos = GetPred(target, 2000, 0.25 + (Game.Latency()/1000))
	Control.CastSpell(HK_W, pos)
end
end	

function Elise:E()
	if Ready(_E) then
local target =  _G.SDK.TargetSelector:GetTarget(1175)
if target == nil then return end
	local pos = GetPred(target, 1600, 0.25 + (Game.Latency()/1000))
	if myHero:GetSpellData(_E).name == "EliseHumanE" then
		Control.CastSpell(HK_E, pos)
	end
	if myHero:GetSpellData(_E).name == "EliseSpiderEInitial" and KoreanMechanics.Spell.EMode:Value() then
			Control.CastSpell(HK_E, target)
	end
	Control.CastSpell(HK_E, mousePos)
end
end

function Elise:Draw()
	if not myHero.dead then
	   	if KoreanMechanics.Draw.Enabled:Value() then
	   		local textPos = myHero.pos:To2D()
	   		if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then
				Draw.Text("Aimbot ON", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 000, 255, 000)) 		
			end
			if not KoreanMechanics.Enabled:Value() and not KoreanMechanics.Hold:Value() and KoreanMechanics.Draw.OFFDRAW:Value() then 
				Draw.Text("Aimbot OFF", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 255, 000, 000)) 
			end
			if KoreanMechanics.Spell.EMode:Value() then
				Draw.Text("Spider E on Enemies ON", 20, textPos.x - 80, textPos.y + 60, Draw.Color(255, 000, 255, 000)) 		
			end
			if not KoreanMechanics.Spell.EMode:Value()  then 
				Draw.Text("Spider E on Enemies OFF", 20, textPos.x - 80, textPos.y + 60, Draw.Color(255, 255, 000, 000)) 
			end 	
			if KoreanMechanics.Draw.QD.Enabled:Value() and myHero:GetSpellData(_Q).name == "EliseHumanQ"  then
	    	    Draw.Circle(myHero.pos, KoreanMechanics.Spell.QR:Value(), KoreanMechanics.Draw.QD.Width:Value(), KoreanMechanics.Draw.QD.Color:Value())
	    	end
	    	if KoreanMechanics.Draw.QD.Enabled:Value() and myHero:GetSpellData(_Q).name ~= "EliseHumanQ" then
	    		 Draw.Circle(myHero.pos, 475, KoreanMechanics.Draw.QD.Width:Value(), KoreanMechanics.Draw.QD.Color:Value())
	    	end	 
	    	if KoreanMechanics.Draw.WD.Enabled:Value() then
	    	    Draw.Circle(myHero.pos, KoreanMechanics.Spell.WR:Value(), KoreanMechanics.Draw.WD.Width:Value(), KoreanMechanics.Draw.WD.Color:Value())
	    	end
	    	if KoreanMechanics.Draw.ED.Enabled:Value() and myHero:GetSpellData(_E).name == "EliseHumanE" then
	    	    Draw.Circle(myHero.pos, KoreanMechanics.Spell.ER:Value(), KoreanMechanics.Draw.ED.Width:Value(), KoreanMechanics.Draw.ED.Color:Value())
	    	end
	    	if KoreanMechanics.Draw.ED.Enabled:Value() and myHero:GetSpellData(_E).name ~= "EliseHumanE" then
	    	    Draw.Circle(myHero.pos, 800, KoreanMechanics.Draw.ED.Width:Value(), KoreanMechanics.Draw.ED.Color:Value())
	    	end		    		    	
	    end		
	end
end

class "Zilean"

function Zilean:__init()
	print("Weedle's Zilean Loaded")
	Callback.Add("Tick", function() self:Tick() end)
	Callback.Add("Draw", function() self:Draw() end)
	self:Menu()
end	

function Zilean:Menu()
	KoreanMechanics:MenuElement({id = "Speed", name = "Q Pred Speed", value = 1500, min = 500, max = 2000, step = 50})
	KoreanMechanics.Spell:MenuElement({id = "Q", name = "Q Key", key = string.byte("Q")})
	KoreanMechanics.Spell:MenuElement({id = "QR", name = "max Q Range", value = 900, min = 0, max = 900, step = 10})
	KoreanMechanics.Spell:MenuElement({id = "E", name = "E Usage", key = string.byte("E")})	
	KoreanMechanics.Spell:MenuElement({id = "ER", name = "E Range", value = 750, min = 0, max = 750, step = 10})
	KoreanMechanics.Spell:MenuElement({id = "EMode", name = "Auto target E Toggle", key = string.byte("T"), toggle = true})	
	KoreanMechanics.Spell:MenuElement({id = "RS", name = "R Settings", type = MENU})
	KoreanMechanics.Spell.RS:MenuElement({id = "R", name = "R Usage", value = true})				
	KoreanMechanics.Spell.RS:MenuElement({id = "RHP", name = "Smart R when HP% [?]", value = 10, min = 0, max = 100, step = 1})	

	KoreanMechanics.Draw:MenuElement({id = "QD", name = "Draw Q range", type = MENU})
    KoreanMechanics.Draw.QD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.QD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.QD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
    KoreanMechanics.Draw:MenuElement({id = "ED", name = "Draw E range", type = MENU})
    KoreanMechanics.Draw.ED:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.ED:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.ED:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})     
    KoreanMechanics.Draw:MenuElement({id = "RD", name = "Draw R range", type = MENU})
    KoreanMechanics.Draw.RD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.RD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.RD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})  
end

function Zilean:Tick()
	if myHero.attackData.state == STATE_WINDUP then return end	
	if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then 
		if KoreanMechanics.Spell.Q:Value() then
			self:Q()
		end
		if KoreanMechanics.Spell.E:Value() then
			self:E()
		end
		if KoreanMechanics.Spell.RS.R:Value() then
			self:R()
		end
	end
end

function Zilean:Q()
	if Ready(_Q) then
local target =  _G.SDK.TargetSelector:GetTarget(1000)
if target == nil then return end 	
	local pos = GetPred(target, KoreanMechanics.Speed:Value(), 0.25 + (Game.Latency()/1000))
	Control.CastSpell(HK_Q, pos)
end 
end	

function Zilean:E()
	if Ready(_E) then
local target =  _G.SDK.TargetSelector:GetTarget(850)
	if KoreanMechanics.Spell.EMode:Value() then 
		if target == nil then 	Control.CastSpell(HK_E, myHero) end
		if target then
				Control.CastSpell(HK_E, target)
		end
	end
	if not KoreanMechanics.Spell.EMode:Value() then 
		if target == nil then return end
		Control.CastSpell(HK_E, mousePos)
	end
end
end

function Zilean:R()
	if Ready(_R) then
local Heroes = nil
	if KoreanMechanics.Spell.RS.R:Value() and Ready(_R) then
		local target =  _G.SDK.TargetSelector:GetTarget(1500)
		if target == nil then return end
		if target then
			for i = 1, Game.HeroCount() do
			local Heroes = Game.Hero(i)
				if Heroes.distance < 900 and Heroes.isAlly and not Heroes.dead and (Heroes.health/Heroes.maxHealth) < (KoreanMechanics.Spell.RS.RHP:Value()/100) then
					Control.CastSpell(HK_R, Heroes)
				end
			end
			if (myHero.health/myHero.maxHealth) < (KoreanMechanics.Spell.RS.RHP:Value()/100) then
				Control.CastSpell(HK_R, myHero)
			end
		end
	end
end
end

function Zilean:Draw()
	if not myHero.dead then
		if KoreanMechanics.Draw.Enabled:Value() then
			local textPos = myHero.pos:To2D()
			if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then
				Draw.Text("Aimbot ON", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 000, 255, 000)) 		
			end
			if not KoreanMechanics.Enabled:Value() and not KoreanMechanics.Hold:Value() and KoreanMechanics.Draw.OFFDRAW:Value() then 
				Draw.Text("Aimbot OFF", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 255, 000, 000)) 
			end
			if KoreanMechanics.Spell.EMode:Value() then
				Draw.Text("Smart E ON", 20, textPos.x - 80, textPos.y + 60, Draw.Color(255, 000, 255, 000)) 		
			end
			if not KoreanMechanics.Spell.EMode:Value()  then 
				Draw.Text("Smart E OFF", 20, textPos.x - 80, textPos.y + 60, Draw.Color(255, 255, 000, 000)) 
			end 			 
			if KoreanMechanics.Draw.QD.Enabled:Value() then
			    Draw.Circle(myHero.pos, KoreanMechanics.Spell.QR:Value(), KoreanMechanics.Draw.QD.Width:Value(), KoreanMechanics.Draw.QD.Color:Value())
			end
	    	if KoreanMechanics.Draw.ED.Enabled:Value() then
	    	    Draw.Circle(myHero.pos, KoreanMechanics.Spell.ER:Value(), KoreanMechanics.Draw.ED.Width:Value(), KoreanMechanics.Draw.ED.Color:Value())
	    	end	
	    	if KoreanMechanics.Draw.RD.Enabled:Value() then
	    	    Draw.Circle(myHero.pos, 900 , KoreanMechanics.Draw.RD.Width:Value(), KoreanMechanics.Draw.RD.Color:Value())
	    	end	 	    	    			
		end
	end
end
	
class "Corki"

function Corki:__init()
	print("Weedle's Corki Loaded")
	Callback.Add("Tick", function() self:Tick() end)
	Callback.Add("Draw", function() self:Draw() end)
	self:Menu()
end	

function Corki:Menu()
	KoreanMechanics.Spell:MenuElement({id = "Q", name = "Q Key", key = string.byte("Q")})
	KoreanMechanics.Spell:MenuElement({id = "QR", name = "Q Range", value = 825, min = 0, max = 825, step = 25})
	KoreanMechanics.Spell:MenuElement({id = "R", name = "R Key", key = string.byte("R")})
	KoreanMechanics.Spell:MenuElement({id = "RR", name = "R Range", value = 1300, min = 0, max = 1300, step = 25})

	KoreanMechanics.Draw:MenuElement({id = "QD", name = "Draw Q range", type = MENU})
    KoreanMechanics.Draw.QD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.QD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.QD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
    KoreanMechanics.Draw:MenuElement({id = "RD", name = "Draw R range", type = MENU})
    KoreanMechanics.Draw.RD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.RD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.RD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})  
end

function Corki:Tick()
	if myHero.attackData.state == STATE_WINDUP then return end	
	if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then
		if KoreanMechanics.Spell.Q:Value() then
			self:Q()
		end
		if KoreanMechanics.Spell.R:Value() then
			self:R()
		end		
	end
end	

function Corki:Q()
	if Ready(_Q) then
local target =  _G.SDK.TargetSelector:GetTarget(925)
if target == nil then return end 	
	local pos = GetPred(target, 1125, (0.25 + Game.Latency())/1000)
	Control.CastSpell(HK_Q, pos)
end
end

function Corki:R()
	if Ready(_R) then
local target =  _G.SDK.TargetSelector:GetTarget(1400)
if target == nil then return end 	
	local pos = GetPred(target, 2000, (0.25 + Game.Latency())/1000)
	Control.CastSpell(HK_R, pos)
end
end	

function Corki:Draw()
	if not myHero.dead then
	   	if KoreanMechanics.Draw.Enabled:Value() then
	   		local textPos = myHero.pos:To2D()
	   		if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then
				Draw.Text("Aimbot ON", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 000, 255, 000)) 		
			end
			if not KoreanMechanics.Enabled:Value() and not KoreanMechanics.Hold:Value() and KoreanMechanics.Draw.OFFDRAW:Value() then 
				Draw.Text("Aimbot OFF", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 255, 000, 000)) 
			end 
			if KoreanMechanics.Draw.QD.Enabled:Value() then
	    	    Draw.Circle(myHero.pos, KoreanMechanics.Spell.QR:Value(), KoreanMechanics.Draw.QD.Width:Value(), KoreanMechanics.Draw.QD.Color:Value())
	    	end
	    	if KoreanMechanics.Draw.RD.Enabled:Value() then
	    	    Draw.Circle(myHero.pos, KoreanMechanics.Spell.RR:Value(), KoreanMechanics.Draw.RD.Width:Value(), KoreanMechanics.Draw.RD.Color:Value())
	    	end	 	    	
	    end		
	end
end

class "Sivir"

function Sivir:__init()
	print("Weedle's Sivir Loaded")
	Callback.Add("Tick", function() self:Tick() end)
	Callback.Add("Draw", function() self:Draw() end)
	self:Menu()
end	

function Sivir:Menu()
	KoreanMechanics.Spell:MenuElement({id = "Q", name = "Q Key", key = string.byte("Q")})
	KoreanMechanics.Spell:MenuElement({id = "QR", name = "Q Range", value = 1200, min = 0, max = 1200, step = 25})

	KoreanMechanics.Draw:MenuElement({id = "QD", name = "Draw Q range", type = MENU})
    KoreanMechanics.Draw.QD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.QD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.QD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
end

function Sivir:Tick()
	if myHero.attackData.state == STATE_WINDUP then return end	
	if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then
		if KoreanMechanics.Spell.Q:Value() then
			self:Q()
		end
	end
end	

function Sivir:Q()
	if Ready(_Q) then
local target =  _G.SDK.TargetSelector:GetTarget(1300)
if target == nil then return end 	
	local pos = GetPred(target, 1350, 0.25 + (Game.Latency()/1000))
	Control.CastSpell(HK_Q, pos)
end
end

function Sivir:Draw()
	if not myHero.dead then
	   	if KoreanMechanics.Draw.Enabled:Value() then
	   		local textPos = myHero.pos:To2D()
	   		if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then
				Draw.Text("Aimbot ON", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 000, 255, 000)) 		
			end
			if not KoreanMechanics.Enabled:Value() and not KoreanMechanics.Hold:Value() and KoreanMechanics.Draw.OFFDRAW:Value() then 
				Draw.Text("Aimbot OFF", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 255, 000, 000)) 
			end 
			if KoreanMechanics.Draw.QD.Enabled:Value() then
	    	    Draw.Circle(myHero.pos, KoreanMechanics.Spell.QR:Value(), KoreanMechanics.Draw.QD.Width:Value(), KoreanMechanics.Draw.QD.Color:Value())
	    	end
	    end		
	end
end

class "Aatrox"

function Aatrox:__init()
	print("Weedle's Aatrox Loaded")
	Callback.Add("Tick", function() self:Tick() end)
	Callback.Add("Draw", function() self:Draw() end)
	self:Menu()
end	

function Aatrox:Menu()
	KoreanMechanics.Spell:MenuElement({id = "Q", name = "Q Key", key = string.byte("Q")})
	KoreanMechanics.Spell:MenuElement({id = "QR", name = "Q Range", value = 650, min = 0, max = 650, step = 10})
	KoreanMechanics.Spell:MenuElement({id = "E", name = "E Key", key = string.byte("E")})
	KoreanMechanics.Spell:MenuElement({id = "ER", name = "E Range", value = 1075, min = 0, max = 1075, step = 10})	

	KoreanMechanics.Draw:MenuElement({id = "QD", name = "Draw Q range", type = MENU})
    KoreanMechanics.Draw.QD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.QD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.QD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
    KoreanMechanics.Draw:MenuElement({id = "ED", name = "Draw E range", type = MENU})
    KoreanMechanics.Draw.ED:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.ED:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.ED:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)}) 
end

function Aatrox:Tick()
	if myHero.attackData.state == STATE_WINDUP then return end	
	if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then
		if KoreanMechanics.Spell.Q:Value() then
			self:Q()
		end
		if KoreanMechanics.Spell.E:Value() then
			self:E()
		end		
	end
end	

function Aatrox:Q()
	if Ready(_Q) then
local target =  _G.SDK.TargetSelector:GetTarget(750)
if target == nil then return end 	
	local pos = GetPred(target, 2000, 0.6 + (Game.Latency()/1000))
	Control.CastSpell(HK_Q, pos)
end
end

function Aatrox:E()
	if Ready(_E) then
local target =  _G.SDK.TargetSelector:GetTarget(1350)
if target == nil then return end 	
	local pos = GetPred(target, 1250, 0.25 + (Game.Latency()/1000))
	Control.CastSpell(HK_E, pos)
end
end

function Aatrox:Draw()
	if not myHero.dead then
	   	if KoreanMechanics.Draw.Enabled:Value() then
	   		local textPos = myHero.pos:To2D()
	   		if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then
				Draw.Text("Aimbot ON", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 000, 255, 000)) 		
			end
			if not KoreanMechanics.Enabled:Value() and not KoreanMechanics.Hold:Value() and KoreanMechanics.Draw.OFFDRAW:Value() then 
				Draw.Text("Aimbot OFF", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 255, 000, 000)) 
			end 
			if KoreanMechanics.Draw.QD.Enabled:Value() then
	    	    Draw.Circle(myHero.pos, KoreanMechanics.Spell.QR:Value(), KoreanMechanics.Draw.QD.Width:Value(), KoreanMechanics.Draw.QD.Color:Value())
	    	end
	    	if KoreanMechanics.Draw.ED.Enabled:Value() then
	    	    Draw.Circle(myHero.pos, KoreanMechanics.Spell.ER:Value(), KoreanMechanics.Draw.ED.Width:Value(), KoreanMechanics.Draw.ED.Color:Value())
	    	end		    	
	    end		
	end
end

class "Jinx"

function Jinx:__init()
	print("Weedle's Jinx Loaded")
	Callback.Add("Tick", function() self:Tick() end)
	Callback.Add("Draw", function() self:Draw() end)
	self:Menu()
end	

function Jinx:Menu()
	KoreanMechanics.Spell:MenuElement({id = "W", name = "W Key", key = string.byte("Q")})
	KoreanMechanics.Spell:MenuElement({id = "WR", name = "W Range", value = 1500, min = 0, max = 1500, step = 25})
	KoreanMechanics.Spell:MenuElement({id = "E", name = "E Key", key = string.byte("R")})
	KoreanMechanics.Spell:MenuElement({id = "ER", name = "E Range", value = 900, min = 0, max = 900, step = 25})
	KoreanMechanics.Spell:MenuElement({id = "R", name = "R Key", key = string.byte("R")})	

	KoreanMechanics.Draw:MenuElement({id = "WD", name = "Draw W range", type = MENU})
    KoreanMechanics.Draw.WD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.WD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.WD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
    KoreanMechanics.Draw:MenuElement({id = "ED", name = "Draw E range", type = MENU})
    KoreanMechanics.Draw.ED:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.ED:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.ED:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})  
end

function Jinx:Tick()
	if myHero.attackData.state == STATE_WINDUP then return end	
	if KoreanMechanics.Enabled:Value() then
		if KoreanMechanics.Spell.W:Value() then
			self:W()
		end
		if KoreanMechanics.Spell.E:Value() then
			self:E()
		end		
		if KoreanMechanics.Spell.R:Value() then
			self:R()
		end			
	end
end

function Jinx:W()
	if Ready(_W) then
local target =  _G.SDK.TargetSelector:GetTarget(1600)
if target == nil then return end 	
	local pos = GetPred(target, 1500, (0.25 + Game.Latency())/1000)
	Control.CastSpell(HK_W, pos)
end
end

function Jinx:E()
	if Ready(_E) then
local target =  _G.SDK.TargetSelector:GetTarget(925)
if target == nil then return end 	
	local pos = GetPred(target, 900, (0.25 + Game.Latency())/1000)
	Control.CastSpell(HK_E, pos)
end
end

function Jinx:R()	
	if Ready(_R) then
local targety =  _G.SDK.TargetSelector:GetTarget()
	if targety == nil then return end 	
	local pos = GetPred(targety, 2500, 0.25 + Game.Latency()/1000)
	Control.CastSpell(HK_R, pos)
end
end

function Jinx:Draw()
	if not myHero.dead then
	   	if KoreanMechanics.Draw.Enabled:Value() then
	   		local textPos = myHero.pos:To2D()
	   		if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then
				Draw.Text("Aimbot ON", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 000, 255, 000)) 		
			end
			if not KoreanMechanics.Enabled:Value() and not KoreanMechanics.Hold:Value() and KoreanMechanics.Draw.OFFDRAW:Value() then 
				Draw.Text("Aimbot OFF", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 255, 000, 000)) 
			end 
			if KoreanMechanics.Draw.WD.Enabled:Value() then
	    	    Draw.Circle(myHero.pos, KoreanMechanics.Spell.WR:Value(), KoreanMechanics.Draw.WD.Width:Value(), KoreanMechanics.Draw.WD.Color:Value())
	    	end
	    	if KoreanMechanics.Draw.ED.Enabled:Value() then
	    	    Draw.Circle(myHero.pos, KoreanMechanics.Spell.ER:Value(), KoreanMechanics.Draw.ED.Width:Value(), KoreanMechanics.Draw.ED.Color:Value())
	    	end	 	    	
	    end		
	end
end

class "Warwick"

function Warwick:__init()
	print("Weedle's Warwick Loaded")
	Callback.Add("Tick", function() self:Tick() end)
	Callback.Add("Draw", function() self:Draw() end)
	self:Menu()
end	

function Warwick:Menu()
	KoreanMechanics.Spell:MenuElement({id = "R", name = "R Key", key = string.byte("R")})

    KoreanMechanics.Draw:MenuElement({id = "RD", name = "Draw R range", type = MENU})
    KoreanMechanics.Draw.RD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.RD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.RD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})  
end

function Warwick:Tick()
	if KoreanMechanics.Enabled:Value() then
		if KoreanMechanics.Spell.R:Value() then
			self:R()
		end			
	end
end

function Warwick:R()	
	if Ready(_R) then
		local targety =  _G.SDK.TargetSelector:GetTarget()
		if targety == nil then return end 	
		local pos = GetPred(targety, myHero:GetSpellData(R).range, 0.25 + Game.Latency()/1000)
		Control.CastSpell(HK_R, pos)
	end
end

function Warwick:Draw()
	local range = myHero:GetSpellData(R).range
	if not myHero.dead then
		if KoreanMechanics.Draw.Enabled:Value() then
			local textPos = myHero.pos:To2D()
			if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then
				Draw.Text("Aimbot ON", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 000, 255, 000)) 		
			end
			if not KoreanMechanics.Enabled:Value() and not KoreanMechanics.Hold:Value() and KoreanMechanics.Draw.OFFDRAW:Value() then 
				Draw.Text("Aimbot OFF", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 255, 000, 000)) 
			end
			if range == nil then return end
			if KoreanMechanics.Draw.RD.Enabled:Value() then
	    	    Draw.Circle(myHero.pos, range, KoreanMechanics.Draw.RD.Width:Value(), KoreanMechanics.Draw.RD.Color:Value())
	    	end	    	
	    end		
	end
end

class "Annie"

function Annie:__init()
	print("Weedle's Annie Loaded")
	Callback.Add("Tick", function() self:Tick() end)
	Callback.Add("Draw", function() self:Draw() end)
	self:Menu()
end	

function Annie:Menu()
	KoreanMechanics.Spell:MenuElement({id = "W", name = "W Key", key = string.byte("W")})
	KoreanMechanics.Spell:MenuElement({id = "WR", name = "W Range", value = 600, min = 0, max = 600, step = 25})
	KoreanMechanics.Spell:MenuElement({id = "R", name = "R Key", key = string.byte("R")})	
	KoreanMechanics.Spell:MenuElement({id = "RR", name = "R Range", value = 600, min = 0, max = 600, step = 25})

	KoreanMechanics.Draw:MenuElement({id = "WD", name = "Draw W range", type = MENU})
    KoreanMechanics.Draw.WD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.WD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.WD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
    KoreanMechanics.Draw:MenuElement({id = "RD", name = "Draw R range", type = MENU})
    KoreanMechanics.Draw.RD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.RD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.RD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})  
end

function Annie:Tick()
	if KoreanMechanics.Enabled:Value() then
		if KoreanMechanics.Spell.W:Value() then
			self:W()
		end
		if KoreanMechanics.Spell.R:Value() then
			self:R()
		end			
	end
end

function Annie:W()
	if Ready(_W) then
local target =  _G.SDK.TargetSelector:GetTarget(1600)
if target == nil then return end 	
	local pos = GetPred(target, 600, (0.25 + Game.Latency())/1000)
	Control.CastSpell(HK_W, pos)
end
end

function Annie:R()	
	if Ready(_R) then
local targety =  _G.SDK.TargetSelector:GetTarget()
	if targety == nil then return end 	
	local pos = GetPred(targety, 600, 0.25 + Game.Latency()/1000)
	Control.CastSpell(HK_R, pos)
end
end

function Annie:Draw()
	if not myHero.dead then
		if KoreanMechanics.Draw.Enabled:Value() then
			local textPos = myHero.pos:To2D()
			if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then
				Draw.Text("Aimbot ON", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 000, 255, 000)) 		
			end
			if not KoreanMechanics.Enabled:Value() and not KoreanMechanics.Hold:Value() and KoreanMechanics.Draw.OFFDRAW:Value() then 
				Draw.Text("Aimbot OFF", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 255, 000, 000)) 
			end 
			if KoreanMechanics.Draw.WD.Enabled:Value() then
				Draw.Circle(myHero.pos, KoreanMechanics.Spell.WR:Value(), KoreanMechanics.Draw.WD.Width:Value(), KoreanMechanics.Draw.WD.Color:Value())
			end
			if KoreanMechanics.Draw.RD.Enabled:Value() then
				Draw.Circle(myHero.pos, KoreanMechanics.Spell.RR:Value(), KoreanMechanics.Draw.RD.Width:Value(), KoreanMechanics.Draw.RD.Color:Value())
			end
		end	 	    	
	end		
end

class "Ashe"

function Ashe:__init()
	print("Weedle's Ashe Loaded")
	Callback.Add("Tick", function() self:Tick() end)
	Callback.Add("Draw", function() self:Draw() end)
	self:Menu()
end	

function Ashe:Menu()
	KoreanMechanics.Spell:MenuElement({id = "W", name = "W Key", key = string.byte("W")})
	KoreanMechanics.Spell:MenuElement({id = "WR", name = "W Range", value = 1200, min = 0, max = 1200, step = 25})
	KoreanMechanics.Spell:MenuElement({id = "R", name = "R Key", key = string.byte("R")})

	KoreanMechanics.Draw:MenuElement({id = "WD", name = "Draw W range", type = MENU})
    KoreanMechanics.Draw.WD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.WD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.WD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
    KoreanMechanics.Draw:MenuElement({id = "RD", name = "Draw R range", type = MENU})
    KoreanMechanics.Draw.RD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.RD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.RD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})  
end

function Ashe:Tick()
	if KoreanMechanics.Enabled:Value() then
		if KoreanMechanics.Spell.W:Value() then
			self:W()
		end
		if KoreanMechanics.Spell.R:Value() then
			self:R()
		end			
	end
end

function Ashe:W()
	if Ready(_W) then
local target =  _G.SDK.TargetSelector:GetTarget(1600)
if target == nil then return end 	
	local pos = GetPred(target, 1200, (0.25 + Game.Latency())/1000)
	Control.CastSpell(HK_W, pos)
end
end

function Ashe:R()	
	if Ready(_R) then
local targety =  _G.SDK.TargetSelector:GetTarget()
	if targety == nil then return end 	
	local pos = GetPred(targety, myHero:GetSpellData(R).range, 0.25 + Game.Latency()/1000)
	Control.CastSpell(HK_R, pos)
end
end

function Ashe:Draw()
	local range = myHero:GetSpellData(R).range
	if not myHero.dead then
		if KoreanMechanics.Draw.Enabled:Value() then
			local textPos = myHero.pos:To2D()
			if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then
				Draw.Text("Aimbot ON", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 000, 255, 000)) 		
			end
			if not KoreanMechanics.Enabled:Value() and not KoreanMechanics.Hold:Value() and KoreanMechanics.Draw.OFFDRAW:Value() then 
				Draw.Text("Aimbot OFF", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 255, 000, 000)) 
			end 
			if KoreanMechanics.Draw.WD.Enabled:Value() then
				Draw.Circle(myHero.pos, KoreanMechanics.Spell.WR:Value(), KoreanMechanics.Draw.WD.Width:Value(), KoreanMechanics.Draw.WD.Color:Value())
			end
			if range == nil then return end
			if KoreanMechanics.Draw.RD.Enabled:Value() then
				Draw.Circle(myHero.pos, range, KoreanMechanics.Draw.RD.Width:Value(), KoreanMechanics.Draw.RD.Color:Value())
			end
		end	 	    	
	end		
end

class "Bardo"

function Bardo:__init()
	print("Weedle's Bardo Loaded")
	Callback.Add("Tick", function() self:Tick() end)
	Callback.Add("Draw", function() self:Draw() end)
	self:Menu()
end	

function Bardo:Menu()
	KoreanMechanics.Spell:MenuElement({id = "Q", name = "Q Key", key = string.byte("Q")})
	KoreanMechanics.Spell:MenuElement({id = "QR", name = "Q Range", value = 925, min = 0, max = 925, step = 25})

	KoreanMechanics.Draw:MenuElement({id = "QD", name = "Draw Q range", type = MENU})
    KoreanMechanics.Draw.QD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.QD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.QD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
end

function Bardo:Tick()
	if KoreanMechanics.Enabled:Value() then
		if KoreanMechanics.Spell.Q:Value() then
			self:Q()
		end	
	end
end

function Bardo:Q()
	if Ready(_Q) then
local target =  _G.SDK.TargetSelector:GetTarget(1600)
if target == nil then return end 	
	local pos = GetPred(target, 925, (0.25 + Game.Latency())/1000)
	Control.CastSpell(HK_Q, pos)
end
end

function Bardo:Draw()
	local range = myHero:GetSpellData(R).range
	if not myHero.dead then
		if KoreanMechanics.Draw.Enabled:Value() then
			local textPos = myHero.pos:To2D()
			if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then
				Draw.Text("Aimbot ON", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 000, 255, 000)) 		
			end
			if not KoreanMechanics.Enabled:Value() and not KoreanMechanics.Hold:Value() and KoreanMechanics.Draw.OFFDRAW:Value() then 
				Draw.Text("Aimbot OFF", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 255, 000, 000)) 
			end 
			if KoreanMechanics.Draw.QD.Enabled:Value() then
				Draw.Circle(myHero.pos, KoreanMechanics.Spell.QR:Value(), KoreanMechanics.Draw.QD.Width:Value(), KoreanMechanics.Draw.QD.Color:Value())
			end
		end	 	    	
	end		
end

class "LeeSin"

function LeeSin:__init()
	print("Weedle's Lee Sin Loaded")
	Callback.Add("Tick", function() self:Tick() end)
	Callback.Add("Draw", function() self:Draw() end)
	self:Menu()
end

function LeeSin:Menu()
	KoreanMechanics.Spell:MenuElement({id = "Q", name = "Q Key", key = string.byte("Q")})
	KoreanMechanics.Spell:MenuElement({id = "QR", name = "Q Range", value = 1100, min = 0, max = 1100, step = 25})

	KoreanMechanics.Draw:MenuElement({id = "QD", name = "Draw Q range", type = MENU})
    KoreanMechanics.Draw.QD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.QD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.QD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
end

function LeeSin:Tick()
	if KoreanMechanics.Enabled:Value() then
		if KoreanMechanics.Spell.Q:Value() then
			self:Q()
		end
	end
end

function LeeSin:Q()
	if Ready(_Q) then
		local target = _G.SDK.TargetSelector:GetTarget(1350)
		if target == nil then return end
		local pos = GetPred(target, range, (0.25 + Game.Latency())/1000)
		if myHero:GetSpellData(_Q).name == "BlindMonkQOne" then
			Control.CastSpell(HK_Q, pos)
		end
	end
end

function LeeSin:Draw()
	if not myHero.dead then
	   	if KoreanMechanics.Draw.Enabled:Value() then
	   		local textPos = myHero.pos:To2D()
	   		if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then
				Draw.Text("Aimbot ON", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 000, 255, 000)) 		
			end
			if not KoreanMechanics.Enabled:Value() and not KoreanMechanics.Hold:Value() and KoreanMechanics.Draw.OFFDRAW:Value() then 
				Draw.Text("Aimbot OFF", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 255, 000, 000)) 
			end 
			if KoreanMechanics.Draw.QD.Enabled:Value() then
	    	    Draw.Circle(myHero.pos, KoreanMechanics.Spell.QR:Value(), KoreanMechanics.Draw.QD.Width:Value(), KoreanMechanics.Draw.QD.Color:Value())
	    	end
	    end		
	end
end

class "Lissandra"

function Lissandra:__init()
	print("Weedle's Lissandra Loaded")
	Callback.Add("Tick", function() self:Tick() end)
	Callback.Add("Draw", function() self:Draw() end)
	self:Menu()
end

function Lissandra:Menu()
	KoreanMechanics.Spell:MenuElement({id = "Q", name = "Q Key", key = string.byte("Q")})
	KoreanMechanics.Spell:MenuElement({id = "QR", name = "Q Range", value = 725, min = 0, max = 725, step = 25})
	KoreanMechanics.Spell:MenuElement({id = "E", name = "E Key", key = string.byte("E")})
	KoreanMechanics.Spell:MenuElement({id = "ER", name = "E Range", value = 1050, min = 0, max = 1050, step = 25})

	KoreanMechanics.Draw:MenuElement({id = "QD", name = "Draw Q range", type = MENU})
    KoreanMechanics.Draw.QD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.QD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.QD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
    KoreanMechanics.Draw:MenuElement({id = "ED", name = "Draw E range", type = MENU})
    KoreanMechanics.Draw.ED:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.ED:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.ED:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
end

function Lissandra:Tick()
	if KoreanMechanics.Enabled:Value() then
		if KoreanMechanics.Spell.Q:Value() then
			self:Q()
		end
		if KoreanMechanics.Spell.E:Value() then
			self:E()
		end
	end
end

function Lissandra:Q()
	if Ready(_Q) then
local target = _G.SDK.TargetSelector:GetTarget(950)
if target == nil then return end
    local pos = GetPred(target, 725, (0.25 + Game.Latency())/1000)
    Control.CastSpell(HK_Q, pos)
end
end

function Lissandra:E()
	if Ready(_E) then
local target = _G.SDK.TargetSelector:GetTarget(1250)
if target == nil then return end
    local pos = GetPred(target, 1050, (0.25 + Game.Latency())/1000)
    Control.CastSpell(HK_E, pos)
end
end

function Lissandra:Draw()
	if not myHero.dead then
	   	if KoreanMechanics.Draw.Enabled:Value() then
	   		local textPos = myHero.pos:To2D()
	   		if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then
				Draw.Text("Aimbot ON", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 000, 255, 000)) 		
			end
			if not KoreanMechanics.Enabled:Value() and not KoreanMechanics.Hold:Value() and KoreanMechanics.Draw.OFFDRAW:Value() then 
				Draw.Text("Aimbot OFF", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 255, 000, 000)) 
			end 
			if KoreanMechanics.Draw.QD.Enabled:Value() then
	    	    Draw.Circle(myHero.pos, KoreanMechanics.Spell.QR:Value(), KoreanMechanics.Draw.QD.Width:Value(), KoreanMechanics.Draw.QD.Color:Value())
	    	end
	    	if KoreanMechanics.Draw.ED.Enabled:Value() then
	    	    Draw.Circle(myHero.pos, KoreanMechanics.Spell.ER:Value(), KoreanMechanics.Draw.ED.Width:Value(), KoreanMechanics.Draw.ED.Color:Value())
	    	end
	    end		
	end
end

class "Nami"

function Nami:__init()
	print("Weedle's Nami Loaded")
	Callback.Add("Tick", function() self:Tick() end)
	Callback.Add("Draw", function() self:Draw() end)
	self:Menu()
end

function Nami:Menu()
	KoreanMechanics.Spell:MenuElement({id = "Q", name = "Q Key", key = string.byte("Q")})
	KoreanMechanics.Spell:MenuElement({id = "QR", name = "Q Range", value = 875, min = 0, max = 875, step = 25})
	KoreanMechanics.Spell:MenuElement({id = "R", name = "R Key", key = string.byte("R")})
	KoreanMechanics.Spell:MenuElement({id = "RR", name = "R Range", value = 2750, min = 0, max = 2750, step = 25})

	KoreanMechanics.Draw:MenuElement({id = "QD", name = "Draw Q range", type = MENU})
    KoreanMechanics.Draw.QD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.QD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.QD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
    KoreanMechanics.Draw:MenuElement({id = "RD", name = "Draw Q range", type = MENU})
    KoreanMechanics.Draw.RD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.RD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.RD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
end

function Nami:Tick()
	if KoreanMechanics.Enabled:Value() then
		if KoreanMechanics.Spell.Q:Value() then
			self:Q()
		end
		if KoreanMechanics.Spell.R:Value() then
			self:R()
		end
	end
end

function Nami:Q()
	if Ready(_Q) then
local target = _G.SDK.TargetSelector:GetTarget(925)
if target == nil then return end
    local pos = GetPred(target, 875, (0.25 + Game.Latency())/1000)
    Control.CastSpell(HK_Q, pos)
end
end

function Nami:R()
	if Ready(_R) then
local target = _G.SDK.TargetSelector:GetTarget(2850)
if target == nil then return end
    local pos = GetPred(target, 2750, (0.25 + Game.Latency())/1000)
    Control.CastSpell(HK_R, pos)
end
end

function Nami:Draw()
	if not myHero.dead then
	   	if KoreanMechanics.Draw.Enabled:Value() then
	   		local textPos = myHero.pos:To2D()
	   		if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then
				Draw.Text("Aimbot ON", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 000, 255, 000)) 		
			end
			if not KoreanMechanics.Enabled:Value() and not KoreanMechanics.Hold:Value() and KoreanMechanics.Draw.OFFDRAW:Value() then 
				Draw.Text("Aimbot OFF", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 255, 000, 000)) 
			end 
			if KoreanMechanics.Draw.QD.Enabled:Value() then
	    	    Draw.Circle(myHero.pos, KoreanMechanics.Spell.QR:Value(), KoreanMechanics.Draw.QD.Width:Value(), KoreanMechanics.Draw.QD.Color:Value())
	    	end
	    	if KoreanMechanics.Draw.RD.Enabled:Value() then
	    	    Draw.Circle(myHero.pos, KoreanMechanics.Spell.RR:Value(), KoreanMechanics.Draw.RD.Width:Value(), KoreanMechanics.Draw.RD.Color:Value())
	    	end
	    end		
	end
end

class "Rengar"

function Rengar:__init()
	print("Weedle's Rengar Loaded")
	Callback.Add("Tick", function() self:Tick() end)
	Callback.Add("Draw", function() self:Draw() end)
	self:Menu()
end

function Rengar:Menu()
	KoreanMechanics.Spell:MenuElement({id = "E", name = "E Key", key = string.byte("E")})
	KoreanMechanics.Spell:MenuElement({id = "ER", name = "E Range", value = 1000, min = 0, max = 1000, step = 25})

	KoreanMechanics.Draw:MenuElement({id = "ED", name = "Draw E range", type = MENU})
    KoreanMechanics.Draw.ED:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.ED:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.ED:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
end

function Rengar:Tick()
	if KoreanMechanics.Enabled:Value() then
		if KoreanMechanics.Spell.Q:Value() then
			self:E()
		end
	end
end

function Rengar:E()
	if Ready(_E) then
local target = _G.SDK.TargetSelector:GetTarget(1250)
if target == nil then return end
    local pos = GetPred(target, 1000, (0.25 + Game.Latency())/1000)
    Control.CastSpell(HK_E, pos)
end
end

function Rengar:Draw()
	if not myHero.dead then
	   	if KoreanMechanics.Draw.Enabled:Value() then
	   		local textPos = myHero.pos:To2D()
	   		if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then
				Draw.Text("Aimbot ON", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 000, 255, 000)) 		
			end
			if not KoreanMechanics.Enabled:Value() and not KoreanMechanics.Hold:Value() and KoreanMechanics.Draw.OFFDRAW:Value() then 
				Draw.Text("Aimbot OFF", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 255, 000, 000)) 
			end 
			if KoreanMechanics.Draw.ED.Enabled:Value() then
	    	    Draw.Circle(myHero.pos, KoreanMechanics.Spell.ER:Value(), KoreanMechanics.Draw.ED.Width:Value(), KoreanMechanics.Draw.ED.Color:Value())
	    	end
	    end		
	end
end

class "Veigar"

function Veigar:__init()
	print("Weedle's Veigar Loaded")
	Callback.Add("Tick", function() self:Tick() end)
	Callback.Add("Draw", function() self:Draw() end)
	self:Menu()
end

function Veigar:Menu()
	KoreanMechanics.Spell:MenuElement({id = "Q", name = "Q Key", key = string.byte("Q")})
	KoreanMechanics.Spell:MenuElement({id = "QR", name = "Q Range", value = 950, min = 0, max = 950, step = 25})
	KoreanMechanics.Spell:MenuElement({id = "W", name = "W Key", key = string.byte("W")})
	KoreanMechanics.Spell:MenuElement({id = "WR", name = "W Range", value = 900, min = 0, max = 900, step = 25})
	KoreanMechanics.Spell:MenuElement({id = "E", name = "E Key", key = string.byte("E")})
	KoreanMechanics.Spell:MenuElement({id = "ER", name = "E Range", value = 700, min = 0, max = 700, step = 25})
	KoreanMechanics.Spell:MenuElement({id = "R", name = "R Key", key = string.byte("R")})
	KoreanMechanics.Spell:MenuElement({id = "RR", name = "R Range", value = 650, min = 0, max = 650, step = 25})

	KoreanMechanics.Draw:MenuElement({id = "QD", name = "Draw Q range", type = MENU})
    KoreanMechanics.Draw.QD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.QD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.QD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
    KoreanMechanics.Draw:MenuElement({id = "WD", name = "Draw W range", type = MENU})
    KoreanMechanics.Draw.WD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.WD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.WD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
    KoreanMechanics.Draw:MenuElement({id = "ED", name = "Draw E range", type = MENU})
    KoreanMechanics.Draw.ED:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.ED:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.ED:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
    KoreanMechanics.Draw:MenuElement({id = "RD", name = "Draw R range", type = MENU})
    KoreanMechanics.Draw.RD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.RD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.RD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
end

function Veigar:Tick()
	if KoreanMechanics.Enabled:Value() then
		if KoreanMechanics.Spell.Q:Value() then
			self:Q()
		end
		if KoreanMechanics.Spell.W:Value() then
			self:W()
		end
		if KoreanMechanics.Spell.E:Value() then
			self:E()
		end
		if KoreanMechanics.Spell.R:Value() then
			self:R()
		end
	end
end

function Veigar:Q()
	if Ready(_Q) then
local target = _G.SDK.TargetSelector:GetTarget(1100)
if target == nil then return end
    local pos = GetPred(target, 950, (0.25 + Game.Latency())/1000)
    Control.CastSpell(HK_Q, pos)
end
end

function Veigar:W()
	if Ready(_W) then
local target = _G.SDK.TargetSelector:GetTarget(1100)
if target == nil then return end
    local pos = GetPred(target, 900, (0.25 + Game.Latency())/1000)
    Control.CastSpell(HK_W, pos)
end
end

function Veigar:E()
	if Ready(_E) then
local target = _G.SDK.TargetSelector:GetTarget(925)
if target == nil then return end
    local pos = GetPred(target, 700, (0.25 + Game.Latency())/1000)
    Control.CastSpell(HK_E, pos)
end
end

function Veigar:R()
	if Ready(_R) then
local target = _G.SDK.TargetSelector:GetTarget(925)
if target == nil then return end
    local pos = GetPred(target, 650, (0.25 + Game.Latency())/1000)
    Control.CastSpell(HK_R, pos)
end
end

function Veigar:Draw()
	if not myHero.dead then
	   	if KoreanMechanics.Draw.Enabled:Value() then
	   		local textPos = myHero.pos:To2D()
	   		if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then
				Draw.Text("Aimbot ON", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 000, 255, 000)) 		
			end
			if not KoreanMechanics.Enabled:Value() and not KoreanMechanics.Hold:Value() and KoreanMechanics.Draw.OFFDRAW:Value() then 
				Draw.Text("Aimbot OFF", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 255, 000, 000)) 
			end 
			if KoreanMechanics.Draw.QD.Enabled:Value() then
	    	    Draw.Circle(myHero.pos, KoreanMechanics.Spell.QR:Value(), KoreanMechanics.Draw.QD.Width:Value(), KoreanMechanics.Draw.QD.Color:Value())
	    	end
	    	if KoreanMechanics.Draw.WD.Enabled:Value() then
	    	    Draw.Circle(myHero.pos, KoreanMechanics.Spell.WR:Value(), KoreanMechanics.Draw.WD.Width:Value(), KoreanMechanics.Draw.WD.Color:Value())
	    	end
	    	if KoreanMechanics.Draw.ED.Enabled:Value() then
	    	    Draw.Circle(myHero.pos, KoreanMechanics.Spell.ER:Value(), KoreanMechanics.Draw.ED.Width:Value(), KoreanMechanics.Draw.ED.Color:Value())
	    	end
	    	if KoreanMechanics.Draw.RD.Enabled:Value() then
	    	    Draw.Circle(myHero.pos, KoreanMechanics.Spell.RR:Value(), KoreanMechanics.Draw.RD.Width:Value(), KoreanMechanics.Draw.RD.Color:Value())
	    	end
	    end		
	end
end

class "Soraka"

function Soraka:__init()
	print("Weedle's Soraka Loaded")
	Callback.Add("Tick", function() self:Tick() end)
	Callback.Add("Draw", function() self:Draw() end)
	self:Menu()
end

function Soraka:Menu()
	KoreanMechanics.Spell:MenuElement({id = "Q", name = "Q Key", key = string.byte("Q")})
	KoreanMechanics.Spell:MenuElement({id = "QR", name = "Q Range", value = 800, min = 0, max = 800, step = 25})
	KoreanMechanics.Spell:MenuElement({id = "E", name = "E Key", key = string.byte("E")})
	KoreanMechanics.Spell:MenuElement({id = "ER", name = "E Range", value = 925, min = 0, max = 925, step = 25})

	KoreanMechanics.Draw:MenuElement({id = "QD", name = "Draw Q range", type = MENU})
    KoreanMechanics.Draw.QD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.QD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.QD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
    KoreanMechanics.Draw:MenuElement({id = "ED", name = "Draw E range", type = MENU})
    KoreanMechanics.Draw.ED:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.ED:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.ED:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
end

function Soraka:Tick()
	if KoreanMechanics.Enabled:Value() then
		if KoreanMechanics.Spell.Q:Value() then
			self:Q()
		end
		if KoreanMechanics.Spell.E:Value() then
			self:E()
		end
	end
end

function Soraka:Q()
	if Ready(_Q) then
local target = _G.SDK.TargetSelector:GetTarget(950)
if target == nil then return end
    local pos = GetPred(target, 800, (0.25 + Game.Latency())/1000)
    Control.CastSpell(HK_Q, pos)
end
end

function Soraka:E()
	if Ready(_E) then
local target = _G.SDK.TargetSelector:GetTarget(1000)
if target == nil then return end
    local pos = GetPred(target, 925, (0.25 + Game.Latency())/1000)
    Control.CastSpell(HK_E, pos)
end
end

function Soraka:Draw()
	if not myHero.dead then
	   	if KoreanMechanics.Draw.Enabled:Value() then
	   		local textPos = myHero.pos:To2D()
	   		if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then
				Draw.Text("Aimbot ON", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 000, 255, 000)) 		
			end
			if not KoreanMechanics.Enabled:Value() and not KoreanMechanics.Hold:Value() and KoreanMechanics.Draw.OFFDRAW:Value() then 
				Draw.Text("Aimbot OFF", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 255, 000, 000)) 
			end 
			if KoreanMechanics.Draw.QD.Enabled:Value() then
	    	    Draw.Circle(myHero.pos, KoreanMechanics.Spell.QR:Value(), KoreanMechanics.Draw.QD.Width:Value(), KoreanMechanics.Draw.QD.Color:Value())
	    	end
	    	if KoreanMechanics.Draw.ED.Enabled:Value() then
	    	    Draw.Circle(myHero.pos, KoreanMechanics.Spell.ER:Value(), KoreanMechanics.Draw.ED.Width:Value(), KoreanMechanics.Draw.ED.Color:Value())
	    	end
	    end		
	end
end

class "Skarner"

function Skarner:__init()
	print("Weedle's Skarner Loaded")
	Callback.Add("Tick", function() self:Tick() end)
	Callback.Add("Draw", function() self:Draw() end)
	self:Menu()
end

function Skarner:Menu()
	KoreanMechanics.Spell:MenuElement({id = "E", name = "E Key", key = string.byte("E")})
	KoreanMechanics.Spell:MenuElement({id = "ER", name = "E Range", value = 1000, min = 0, max = 1000, step = 25})

	KoreanMechanics.Draw:MenuElement({id = "ED", name = "Draw E range", type = MENU})
    KoreanMechanics.Draw.ED:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.ED:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.ED:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
end

function Skarner:Tick()
	if KoreanMechanics.Enabled:Value() then
		if KoreanMechanics.Spell.E:Value() then
			self:E()
		end
	end
end

function Skarner:E()
	if Ready(_E) then
local target = _G.SDK.TargetSelector:GetTarget(1250)
if target == nil then return end
    local pos = GetPred(target, 1000, (0.25 + Game.Latency())/1000)
    Control.CastSpell(HK_E, pos)
end
end

function Skarner:Draw()
	if not myHero.dead then
	   	if KoreanMechanics.Draw.Enabled:Value() then
	   		local textPos = myHero.pos:To2D()
	   		if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then
				Draw.Text("Aimbot ON", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 000, 255, 000)) 		
			end
			if not KoreanMechanics.Enabled:Value() and not KoreanMechanics.Hold:Value() and KoreanMechanics.Draw.OFFDRAW:Value() then 
				Draw.Text("Aimbot OFF", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 255, 000, 000)) 
			end 
	    	if KoreanMechanics.Draw.ED.Enabled:Value() then
	    	    Draw.Circle(myHero.pos, KoreanMechanics.Spell.ER:Value(), KoreanMechanics.Draw.ED.Width:Value(), KoreanMechanics.Draw.ED.Color:Value())
	    	end
	    end		
	end
end

class "Twitch"

function Twitch:__init()
	print("Weedle's Twitch Loaded")
	Callback.Add("Tick", function() self:Tick() end)
	Callback.Add("Draw", function() self:Draw() end)
	self:Menu()
end

function Twitch:Menu()
	KoreanMechanics.Spell:MenuElement({id = "W", name = "W Key", key = string.byte("W")})
	KoreanMechanics.Spell:MenuElement({id = "WR", name = "W Range", value = 950, min = 0, max = 950, step = 25})

	KoreanMechanics.Draw:MenuElement({id = "WD", name = "Draw W range", type = MENU})
    KoreanMechanics.Draw.WD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.WD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.WD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
end

function Twitch:Tick()
	if KoreanMechanics.Enabled:Value() then
		if KoreanMechanics.Spell.W:Value() then
			self:W()
		end
	end
end

function Twitch:W()
	if Ready(_W) then
local target = _G.SDK.TargetSelector:GetTarget(1100)
if target == nil then return end
    local pos = GetPred(target, 950, (0.25 + Game.Latency())/1000)
    Control.CastSpell(HK_W, pos)
end
end

function Twitch:Draw()
	if not myHero.dead then
		if KoreanMechanics.Draw.Enabled:Value() then
			local textPos = myHero.pos:To2D()
			if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then
				Draw.Text("Aimbot ON", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 000, 255, 000)) 		
			end
			if not KoreanMechanics.Enabled:Value() and not KoreanMechanics.Hold:Value() and KoreanMechanics.Draw.OFFDRAW:Value() then 
				Draw.Text("Aimbot OFF", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 255, 000, 000)) 
			end
	    	if KoreanMechanics.Draw.WD.Enabled:Value() then
	    	    Draw.Circle(myHero.pos, KoreanMechanics.Spell.WR:Value(), KoreanMechanics.Draw.WD.Width:Value(), KoreanMechanics.Draw.WD.Color:Value())
	    	end
	    end		
	end
end

if _G[myHero.charName]() then print("Welcome back " ..myHero.name..", thank you for using my Scripts ^^") end