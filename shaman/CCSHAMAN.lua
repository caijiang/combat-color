-- CCSHAMAN.lua

local addonName, T = ...;
local D = T.jcc;

local _,clzz = UnitClass("player");
if clzz~="SHAMAN" then return;end

local S = T.jcc:NewModule("SHAMAN", "AceEvent-3.0", "AceHook-3.0","CCClass-1.0");
T.jcc.SHAMAN = S;

local mouseovertargetfocus = "/cast [@mouseover,help,nodead][@target,help,nodead][@focus,help,nodead]%s";
S.breakingSpell = "风剪";
S.testRangeHitSpell = "根源打击";
S.testGCDSpell="闪电箭";
S.ClassSpellDescs = {
		["闪电箭"] =1,
		["治疗之涌"] ={slot=2,marco=mouseovertargetfocus},
		["根源打击"] ={slot=3,havecd=true},
		["大地震击"]={slot=4,havecd=true},
		["闪电之盾"]=5,
		["烈焰震击"] ={slot=6,havecd=true},
		["灼热图腾"]=7,
		["净化灵魂"] = {slot=8,marco=mouseovertargetfocus},
		["风剪"] ={slot=9,havecd=true},
		["水之护盾"] =10,
		["冰霜震击"]={slot=11,havecd=true},
		["地缚图腾"]={slot=12,havecd=true},
		["闪电链"]={slot=13,havecd=true},
		["图腾召回"] = 14,
		["治疗之泉图腾"] = {slot=15,havecd=true},
		["熔岩图腾"] = 16,
		["根基图腾"] = {slot=17,havecd=true},
		["治疗链"] ={slot=18,marco=mouseovertargetfocus},
		["战栗图腾"] = {slot=19,havecd=true},
		["治疗之雨"] = {slot=20,havecd=true},
		["电能图腾"] = {slot=21,havecd=true},
		--治疗之潮
		["元素释放"] = {slot=22,havecd=true},
		["风剪M"] ={slot=23,havecd=true,marco="/cast [@mouseover,harm,nodead]风剪"},
	};

function S:matchGCD(time)
	D:Error("居然运行到这里了哦");
	local hastsr = 1.5/((GetCombatRatingBonus(CR_HASTE_SPELL)+100)/100);
	--format("%.2f%%",time)==format("%.2f%%",hastsr)
	return time==1.5 or time<hastsr;
end

S.FlameShocks = {};
-- 脱离
--[[
]]
function S:PLAYER_REGEN_ENABLED()
	--D:Error("脱离战斗，覆盖了原有函数");
	S.FlameShocks = {};
end

function S:AddFlameShock(guid)
	tinsert(S.FlameShocks,guid);
	--D:Error("增加了一个烈焰震击目标",guid," 目前数量:",#S.FlameShocks);
end

function S:RmoveFlameShock(guid)
	for index,value in ipairs(S.FlameShocks) do
		if value==guid then
			tremove(S.FlameShocks,index);
		end
	end
	--D:Error("减少了一个烈焰震击目标",guid," 目前数量:",#S.FlameShocks);
end

function S:SPELL_AURA_APPLIED(timestamp, event, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, spellId, spellName, spellSchool, auraType, amount)
	if sourceGUID==UnitGUID("player") and spellId==8050 then
		S:AddFlameShock(destGUID);
	end
end


function S:SPELL_AURA_REMOVED(timestamp, event, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, spellId, spellName, spellSchool, auraType, amount)
	if sourceGUID==UnitGUID("player") and spellId==8050 then
		S:RmoveFlameShock(destGUID);
	end
end


function S:UnitOffline(GUID)
	S:RmoveFlameShock(GUID);
end


function S:AllowWork(inputpvp)
	if(S.TalentType~=3 and ((not InCombat)or(not WA_NeedAttack())))then return end

	if((not inputpvp) and CC_Raid_B())then return end

	if(S.TalentType~=3 and UnitIsBeFear("target") or UnitIsNotAbleAttack("target") or UnitIsBeOutControl("target"))then
		return;
	end

	local pvp = UnitIsPlayer("target");
	if(inputpvp)then
		pvp = true;
	end

	if(CCWA_Check_PreToCasts(pvp))then return end

	if(not pvp and S.TalentType~=3)then
		if(CC_check_threat_dps())then return end
	end

	if(S.TalentType~=3 and CC_TargetisWudi())then
		jcmessage("换目标");
		return;
	end

--[[	if(pvp and (CC_PVP_Enable or inputpvp))then
		if(CC_PVP())then return end
	end]]

--[[	if(not CC_InRange())then
		--不在范围 就暂时不管啦
		return;
	end]]

	return true;
end

function S:RushDps()
end

S.SpellIDs={
    StoneSkin = 8071,
    StoneClaw = 5730,
    EarthBind = 2484,
    StrengthOfEarth = 8075,
    Tremor = 8143,
    EarthElemental = 2062,

    Searing = 3599,
    FireNova = 1535,
    Magma = 8190,
    FlameTongue = 8227,
    FireElemental = 2894,

    HealingStream = 5394,
    ManaSpring = 5675,
    ManaTide = 16190,
    ElementalResistance = 8184,
    TranquilMind = 87718,

    Grounding = 8177,
    Windfury = 8512,
    WrathOfAir = 3738,
    SpiritLink = 98008,

    Ankh = 20608,
    LightningShield = 324,
    WaterShield = 52127,
    EarthShield = 974,
    TotemicCall = 36936,
    WindfuryWeapon = 8232,
    RockbiterWeapon = 8017,
    FlametongueWeapon = 8024,
    FrostbrandWeapon = 8033,
    EarthlivingWeapon = 51730,

    StormStrike = 17364,
    PrimalStrike = 73899,
    EarthShock = 8042,
    FrostShock = 8056,
    FlameShock = 8050,
    LavaLash = 60103,
    LightningBolt = 403,
    ChainLightning = 421,
    LavaBurst = 51505,
    Maelstrom = 53817,
    WindShear = 57994,
    ShamanisticRage = 30823,
    FeralSpirit = 51533,
    ElementalMastery = 16166,
    Thunderstorm = 51490,
    HealingRain = 73920,
    Riptide = 61295,
    UnleashElements = 73680,
    SpiritwalkersGrace = 79206,


	CallofSpirits = 66844,
	CallofElements = 66842,
	CallofAncestors = 66843,


    LavaSurge = 77762,

    Hex = 51514,
    BindElemental = 76780,
}

-- 灵魂链接 98008  法力之潮 ManaTide = 16190, 土元素图腾 2062 地缚图腾 2484  火元素图腾 2894 石爪图腾 5730 战栗图腾 8143 根基图腾 8177
S.CDSpellIDs={
	98008,16190,2062,2484,2894,5730,8143,8177
}

local function isCDtotem(icon)
	for s,v in pairs(S.CDSpellIDs) do
		local iicon = select(3,GetSpellInfo(v));
		if iicon and iicon==icon then
			return true;
		end
	end
	return false;
end

local SpellIDs = S.SpellIDs;

local MultiCastActions = {
    [FIRE_TOTEM_SLOT]  = {[SpellIDs.CallofElements]=133,[SpellIDs.CallofAncestors]=137,[SpellIDs.CallofSpirits]=141},
    [EARTH_TOTEM_SLOT] = {[SpellIDs.CallofElements]=134,[SpellIDs.CallofAncestors]=138,[SpellIDs.CallofSpirits]=142},
    [WATER_TOTEM_SLOT] = {[SpellIDs.CallofElements]=135,[SpellIDs.CallofAncestors]=139,[SpellIDs.CallofSpirits]=143},
    [AIR_TOTEM_SLOT]   = {[SpellIDs.CallofElements]=136,[SpellIDs.CallofAncestors]=140,[SpellIDs.CallofSpirits]=144},
}

local ignore_totems = {};

-- 检查图腾
-- batslot 元素的召唤 133 134 135 136
--         先祖的召唤 137 138 139 140
--                    141 142 143 144
-- 核心思想 缺失一个图腾 或者 当前图腾中包含有长cd图腾 时补充单个图腾 否者补充所有图腾
function S:CheckTotem(batspellid)
	--某些图腾是有buf供应的 如果提供了某个图腾 但是没有供应buf 也算是失败的
	local unvalids = 0;
	local longcds = 0;
	local unvalidspellid = 0;
	for type,ids in pairs(MultiCastActions) do
		local haveTotem, totemName, startTime, duration, icon = GetTotemInfo(type);
		if not startTime or startTime==0 then
			unvalids = unvalids+1;
			unvalidspellid = select(2,GetActionInfo(ids[batspellid]));
		else
			if isCDtotem(icon) then
				longcds = longcds+1;
			else
				--这里复杂了。。 有效性检测
				if GetTime()-startTime>2 and TotemTimers and not TotemTimers.GetPlayerRange(type) then
					--如果4秒的时候 还是not range 则设置不再检查这个图腾
					if not ignore_totems[icon] or GetTime()-ignore_totems[icon]>30*60 then
						if GetTime()-startTime<4 then
							ignore_totems[icon] = GetTime();
						else
							unvalids = unvalids+1;
							unvalidspellid = select(2,GetActionInfo(ids[batspellid]));
						end
					end
				end
			end
		end
	end
	if unvalids==0 then return false; end;
	local tocastspell = batspellid;
	if unvalids==1 or longcds>0 then
		tocastspell = unvalidspellid;
	end

	local spellName = select(1,GetSpellInfo(tocastspell));
	if WA_CheckSpellUsable(spellName) then
		CCFlagSpell(spellName);
		return true;
	end
	return false;
end

function S:TotemActive(totemslot,ttl)
	local haveTotem, totemName, startTime, duration, icon = GetTotemInfo(totemslot);
	if(not startTime)then
		return false;
	end
	return startTime+duration-GetTime()>ttl;
end
