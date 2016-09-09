-- 一些帮助函数 用于更好的使用Ovale
local addonName, T = ...;
local D = T.jcc;

-- private
local OvaleHealth = T.OvaleHealth;
local OvaleEnemies = T.OvaleEnemies;
local OvalePower = T.OvalePower;
local OvaleState = T.OvaleState;
local OvaleFuture = T.OvaleFuture;
local OvaleSpellBook = T.OvaleSpellBook;
local OvaleEquipment = T.OvaleEquipment;

local function TimeToDieHelper(time,unit,die)
  unit = unit or "target";
  local to = OvaleHealth:UnitTimeToDie("target");
  if to==INFINITY then
    return true;
  end
  D:Debug("unit:",unit," todie:",to," mode:",die);
  if die then
    return time>to;
  end
  return time<=to;
end

local function SnapshotCritChance(name,defaultValue)
  local state = OvaleState.state;
  local value = state[name] or defaultValue;
  return value>100 and 100 or value;
end
local function Snapshot(name,defaultValue)
  local state = OvaleState.state;
  return state[name] or defaultValue;
end

-- public
--- 图腾存在时间
function D:TotemRemaining(id)
  local state = OvaleState.state;
  if type(id) == "string" then
    local _, name, startTime, duration = state:GetTotemInfo(id)
    if startTime and duration > 0 then
      local start, ending = startTime, startTime + duration
      return ending-GetTime();
    end
  else -- if type(id) == "number" then
    local count, start, ending = state:GetTotemCount(id, atTime)
    if count > 0 then
      return ending-GetTime();
    end
  end
  return 0;
end
--- Get the current percent increase to spell haste of the player.
function D:SpellHaste()
  return Snapshot("spellHaste", 0);
end
--各种暴击率 ?% 如果是100% 则返回100
function D:MeleeCritChance()
  return SnapshotCritChance("meleeCrit",0);
end
function D:RangedCritChance()
  return SnapshotCritChance("rangedCrit",0);
end
function D:SpellCritChance()
  return SnapshotCritChance("spellCrit",0);
end


-- 获取一个debuf在多少个目标中激活
function D:DebuffCountOnAny(auraId)
  local state = OvaleState.state;
  local count, stacks, startChangeCount, endingChangeCount, startFirst, endingLast = state:AuraCount(auraId, "HARMFUL", true);
  return count;
end

-- 套装奖励是否激活  T17 T16_caster count 为数量
function D:ArmorSetBonus(name,count)
  return OvaleEquipment:GetArmorSetCount(name) >= count;
end

-- 正在飞向目标的法术，参数必须为法术id
function D:InFlightToTarget(spellId)
  local state = OvaleState.state;
  return (state.currentSpellId == spellId) or OvaleFuture:InFlight(spellId);
end
-- 使用一个技能所消耗的时间(秒)，包括GCD 技能可以为id或者名字
function D:GetSpellCostTime(spell)
  local state = OvaleState.state;
  local castTime = OvaleSpellBook:GetCastTime(spell) or 0;
	local gcd = state:GetGCD();
	local castSeconds = (castTime > gcd) and castTime or gcd;
  return castSeconds;
end

function D:PreviousOffGCDSpell(spellId)
  local state = OvaleState.state;
  return spellId == state.lastOffGCDSpellId;
end
function D:PreviousGCDSpell(spellId)
  local state = OvaleState.state;
  return spellId == state.lastGCDSpellId;
end
-- 初始化当前状态 check Frame#OnUpdate
function D:InitializeState()
  local state = OvaleState.state;
  state:Initialize();
  state:Reset();
	OvaleFuture:ApplyInFlightSpells(state);
end
-- 获取时间（秒）到当前能量到某值
function D:TimeToPower(powerType,level)
  local state = OvaleState.state;
  level = level or 0;
  local power = state[powerType] or 0
  local powerRegen = state.powerRate[powerType] or 1
  if power >= level then
    return 0;
  end
  if powerRegen <= 0 then
    return 99999999999999;
  else
    return (level - power) / powerRegen;
  end
end
-- 获取时间（秒）到当前能量到最大值
function D:TimeToMaxPower(powerType)
  local level = OvalePower.maxPower[powerType] or 0;
  return D:TimeToPower(powerType,level);
end
function D:TimeToMaxFocus()
  return D:TimeToMaxPower("focus");
end
function D:TimeToFocus(level)
  return D:TimeToPower("focus",level);
end
-- 获取当前能量或者指定能量的差额（最大和当前之间）
function OvalePower:GetPowerDeficit(powerType)
  powerType = powerType or OvalePower.powerType;
  local power = OvalePower:GetPower(powerType);
  local powerMax = OvalePower.maxPower[powerType];
  return powerMax-power;
end
-- 目标存活时间检测，默认unit为target
-- 为了让函数顺畅运行，如果返回为未知数，则必然返回true
-- 会在time（开环）内死亡
function D:TimeToDie(time,unit)
  return TimeToDieHelper(time,unit,true);
end
-- 会在time(闭环)中存活
function D:TimeToLive(time,unit)
  return TimeToDieHelper(time,unit,false);
end

function D:Enemies()
  -- taggedEnemies
  return OvaleEnemies.activeEnemies or 0;
end

function D:hasEnemies(number)
	-- taggedEnemies
	D:Debug("ask for ",number," current:",OvaleEnemies.activeEnemies);
	if OvaleEnemies.activeEnemies ~= nil then
		return OvaleEnemies.activeEnemies>=number;
	end
	return true;
end

function D:notEnoughEnemies(number)
	-- taggedEnemies
	D:Debug("ask for ",number," current:",OvaleEnemies.activeEnemies);
	if OvaleEnemies.activeEnemies ~= nil then
		return OvaleEnemies.activeEnemies<number;
	end
	return true;
end
