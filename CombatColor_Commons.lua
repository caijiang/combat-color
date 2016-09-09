-- CombatColor_Commons.lua

-- 一些游戏直接相关的简便函数

local addonName, T = ...;
local D = T.jcc or {};

local pID = {}
local rID = {}
for i = 1, 4 do
	pID[i] = format("party%d", i)
end
pID[5]= "player";
for i = 1, 40 do
	rID[i] = format("raid%d", i)
end

--运行频率 单位秒
D.WorkRate = 0.10;
-- 最后一次实战技能的时间
-- spellname:GetTime()
D.MaxDelayMS = 300;
D.MaxDelayS = 0.3;
D.LastCastedTime = {};
D.moving = false;
D.moveingStateChange = GetTime();

-- 最后 施展法术或者引导法术的信息

D.Casting = {
	name=nil,
	startTime=0,
	endTime=0,
	ttf=0,-- time to finish

	process=0,--完成度
	channeling=false,
};

function D:ResetCasting()
	D.Casting.name = nil;
	D.Casting.startTime = 0;
	D.Casting.endTime = 0;
	D.Casting.ttf = 0;

	D.Casting.process = 0;
	D.Casting.channeling = false;
end

D.TargetCasting = {
	name=nil,
	startTime=0,
	endTime=0,
	ttf=0,-- time to finish

	process=0,--完成度
	channeling=false,
	willbreakplayer=false,
};

function D:ResetTargetCasting()
	D.TargetCasting.name = nil;
	D.TargetCasting.startTime = 0;
	D.TargetCasting.endTime = 0;
	D.TargetCasting.ttf = 0;

	D.TargetCasting.process = 0;
	D.TargetCasting.channeling = false;
	D.TargetCasting.willbreakplayer = false;
end


local function ismyxlzz(name,rank,iconTexture,count,debuffType,duration,expirationTime,unitCaster,canStealOrPurge, shouldConsolidate, spellId)
	return spellId==96267;
end
--这里是检查一个技能是否可以安全的运行 避免被打断
-- bug 引导法术问题！
-- 单元测试1 瞬发技能的time到底是多少 获得的瞬发技能呢？0 <0
-- 单元测试2 powerType 是否可以代表这个技能可否被打断！
-- 整体测试 第一模拟 willbreakplayer的TargetCasting
-- 好了 就剩下那个打断技能是否真的可以用了！bug 引导法术问题！！！！
function D:AbleToCast(sn,casting)
	if D.TargetCasting.name==nil or (not D.TargetCasting.willbreakplayer) then
		return true;
	end
	---如果拥有无敌 或者其他可以抵抗沉默和打断的buf
	if not WA_CheckBuff("平静")
		or not WA_CheckBuff("圣盾术")
		or not WA_CheckBuff("心灵专注",0,0,true,"player",ismyxlzz)
		then
		return true;
	end

	--获得这个法术信息 确定是否是会被打断！
	--0 for Mana  Number - The cast time, in milliseconds.
	local _, _, _, castTime =  GetSpellInfo(sn);
	if sn=="眼镜蛇射击" then return true; end
	if sn=="苦修" then
		castTime = 4000;
	end
	--if powerType~=0 then return true; end

	if castTime<0 then return true; end

	if casting then
		D:Debug("读条中 打断！");
		return false;
	end
	if castTime/1000 > D.TargetCasting.ttf then
		D:Debug("来不及读出来了 打断！");
		return false;
	else
		return true;
	end
end

--[[
local meleeChecker = rc:GetFriendMaxChecker(rc.MeleeRange) -- 5 yds
for i = 1, 4 do
    if meleeChecker("party" .. i) then
        print("Party member " .. i .. " is in Melee range")
    end
end
]]

D.rc = LibStub("LibRangeCheck-2.0", true);

function D:Distance(unitid)
	unitid = unitid or "target";
	return D.rc and D.rc:GetRange(target) or 0;
end


-- 是否可以吟唱施法
function D:CastReadable(spellname)
	if not D:IsMoving() then return true end
	if ALWAYS_CastReadable then return true end
	if (spellname=="灾难之握" or spellname=="烧尽" or spellname=="暗影箭") and GetSpellInfo("基尔加丹的狡诈") then return true end
	return not WA_CheckBuff("飞行") or not WA_CheckBuff("熔火之羽") or not WA_CheckBuff("灵魂行者的恩赐") or not WA_CheckBuff("浮冰") or not WA_CheckBuff("灵狐守护") or not WA_CheckDebuff("暴乱狂风",0,0,false,"player") or not WA_CheckBuff("浮冰");
end

function D:ShouldQusan(unitid,types)
	if not D.autoqusan then
		return false;
	end
	local i=1;
	while 1 do
		local name,_,_,count,debuffType,_,expirationTime,_,isStealable = UnitDebuff(unitid,i);
		i=i+1;
		if(not name)then
			return false;
		end
		--expirationTime = expirationTime-GetTime();
		D:Debug("自动驱散检查DEBUF:",name,i);
		if name=="血之腐蚀：大地" then
			--目标已经有2层血液 则驱散
			local gid = GetInstanceDifficulty();
			local cs = 2;
			if gid==4 then cs=1;end
			if WA_CheckBuff("奈萨里奥的血液",0,cs,false,unitid) then
				--没满
				--如果当前角色是T或者标注为主坦克 那么不驱散
				--主坦克不知道怎么获取哦
				if UnitGroupRolesAssigned(unitid)=="TANK" then
					return false;
				end
				--检查本团所有tank 都已经满了
				local alltankfull = true;
				for j = 1, 40 do
					if CCShareHoly.isHelp(rID[j]) then
						if UnitGroupRolesAssigned(rID[j])=="TANK" and WA_CheckBuff("奈萨里奥的血液",0,cs,false,rID[j]) then
							alltankfull = false;
						end
					end
				end
				if alltankfull then return false;end
			end
		end
		if name=="干扰之影" then
			--周围10码不可以有人
			local gid = GetInstanceDifficulty();
			if (gid==3 or gid==4) and CCShareHoly.isAnyoneAroundTarget(unitid,false,10,true) then
				return false;
			end
			local minhp = 50000;
			if UnitHealth(unitid)<minhp then
				return false;
			end
		end
		if name=="电离反应" then
			if not WA_CheckDebuff("流体",0,0,false,unitid) then
				return false;
			end
			if CCShareHoly.isAnyoneAroundTarget(unitid,false,8,true) then
				return false;
			end
			if UnitHealth(unitid)<450000 then
				return false;
			end
		end
		if name=="霜冻" then
			--必须同时拥有 水壕  debuf
			if WA_CheckDebuff("水壕",0,0,false,unitid) then
				return false;
			end
		end
		if name=="致命瘟疫" and count<2 then
			return false;
		end
		-- [燃烬] 5 直接驱吧
		-- 有害变异  有益变异 完全变异
		if strfind(name,"变异")==7 then
			return false;
		end

		--  物质交换 5-7
		if name=="物质交换" and (expirationTime-GetTime()<5 or expirationTime-GetTime()>7) then
			return false;
		end

		if debuffType and D:tcheckforval(types,strupper(debuffType)) then
			D:Debug("自动驱散检查DEBUF:",name," 执行驱散 , type:",debuffType);
			return true;
		else
			D:Debug("自动驱散检查DEBUF:",name,"不在可驱散范围 , type:",debuffType);
		end
	end
	return false;
end

local not_able_pulls = {};

function D:AbleToPull()
	if not WA_NeedAttack() then
		return false;
	end
	if not UnitExists("target") then
		return false;
	end
	if UnitIsPlayer("target") then
		return false;
	end
	if not UnitExists("targettarget") then
		return false;
	end

	if UnitExists("targettarget")==UnitName("player") then
		return false;
	end

	--加入一些无法嘲讽的目标
	local nm = UnitName("target");
	if strfind(nm,"结界") or strfind(nm,"图腾") then
		return false;
	end
	if(tContains(not_able_pulls,nm))then
		return false;
	end

	return true;
end

function D:InFashuyishang(unitid)
	unitid = unitid or "target";
	return not (WA_CheckDebuff("元素诅咒",1,0,false,unitid) and WA_CheckDebuff("奇毒",1,0,false,unitid))
end

-- 目标易伤
function D:IsDamageIncrement()
	--当血量过低 也计算为易伤
	if UnitHealth("target")/UnitHealthMax("target")<0.02 then
		return true;
	end
	return false;
end

function D:IsSXing()
	local a1,a2 = WA_CheckBuff("嗜血");
	if not a1 then
		return true,a2;
	end
	a1,a2 = WA_CheckBuff("英勇");
	if not a1 then
		return true,a2;
	end
	a1,a2 = WA_CheckBuff("远古狂乱");
	if not a1 then
		return true,a2;
	end
	a1,a2 = WA_CheckBuff("时间扭曲");
	if not a1 then
		return true,a2;
	end
	return false;
--	return not (WA_CheckBuff("嗜血") and WA_CheckBuff("英勇") and WA_CheckBuff("远古狂乱") and WA_CheckBuff("时间扭曲"));
end

D.unitDPSInfos={};

local function updateDPSInfo(unit)
	if CCShareHoly.isHarm(unit) then
		-- 是否已经存在结构体
		local guid = UnitGUID(unit);
		local dpsinfos = D.unitDPSInfos[guid];
		local ctime = GetTime();
		local hp = UnitHealth(unit);
		if not dpsinfos then
			D.unitDPSInfos[guid] = {
				lastTimeA=ctime,
				lastHPA=hp,
				lastTimeB=ctime,
				lastHPB=hp,
				};
			dpsinfos = D.unitDPSInfos[guid];
		end
		-- 分别记录2组 每3秒 更新一次数据
		if ctime-math.max(dpsinfos.lastTimeA,dpsinfos.lastTimeB)<5 then
			return;
		end
		-- 选择较久的数据替换之 这里就是替换B
		if dpsinfos.lastTimeA>dpsinfos.lastTimeB then
			dpsinfos.lastTimeB = ctime;
			dpsinfos.lastHPB = hp;
		else
			dpsinfos.lastTimeA = ctime;
			dpsinfos.lastHPA = hp;
		end
	end
end

-- 核心系统会调用该函数
function D:RemoveDPSInfo(guid)
	D.unitDPSInfos[guid] = nil;
end

-- 客户代码调用
-- 判断unit是否会在s秒内死亡 数据不足直接返回NO
-- function D:TimeToDie(s,unit)
-- 	if not unit then unit = "target"; end
-- 	local guid = UnitGUID(unit);
-- 	local dpsinfos = D.unitDPSInfos[guid];
-- 	if not dpsinfos then return false;end
--
-- 	local ctime = GetTime();
-- 	local hp = UnitHealth(unit);
--
-- 	if ctime-math.min(dpsinfos.lastTimeA,dpsinfos.lastTimeB)<1.5 then
-- 		D:Debug("数据不足无法预判");
-- 		return false;
-- 	end
--
-- 	local octime,ohp;
-- 	if dpsinfos.lastTimeA>dpsinfos.lastTimeB then
-- 		octime = dpsinfos.lastTimeB;
-- 		ohp = dpsinfos.lastHPB;
-- 	else
-- 		octime = dpsinfos.lastTimeA;
-- 		ohp = dpsinfos.lastHPA;
-- 	end
--
-- 	local costTime = ctime-octime;
-- 	local costHp = ohp - hp;
--
-- 	if costHp<0 then
-- 		D:Debug("HP恢复 无法预判");
-- 		return false;
-- 	end
--
-- 	local dps = costHp/costTime;
-- 	D:Debug("当前整体DPS:",dps);
-- 	return hp<dps*s;
-- end

-- 每次都会被调用
function D:WorkUpdate()
-- 自动管理4boss
-- 所有unit分开管理 根据UUID
-- 数据结构UUID:[lastTime:GetTime(),lastHp:UnitHealth]
	-- updateDPSInfo("boss1");
	-- updateDPSInfo("boss2");
	-- updateDPSInfo("boss3");
	-- updateDPSInfo("boss4");
	-- updateDPSInfo("target");
	-- updateDPSInfo("focus");
end

-- 目前角色是否在移动
function D:IsMoving()
	return D.moving;
end

-- 目前的移动状态是否维持了time秒？
function D:MovingStateKeep(time)
	return GetTime()-D.moveingStateChange>time;
end

function D:UpdatePosition()
	local posX, posY = GetPlayerMapPosition("player");
	local oldX = D.posX or 0;
	local oldY = D.posY or 0;
	local newMstate;
	if posX==oldX and posY==oldY then
		newMstate = false;
	else
		newMstate = true;
	end
	if D.moving ~= newMstate then
		D.moveingStateChange = GetTime();
	end
	D.moving = newMstate;
	D.posX = posX;
	D.posY = posY;
end

function D:LastCasted(spell)
	return D.LastCastedTime[spell] or 0;
end

function D:isT(target)
end
function D:isDPS(target)
end
function D:isN(target)
end
-- 爆发前置条件 这里分别为好几种 talnet载入时 会具体选择一种
-- 返回 nlok,nlid,nltrid  如果是true表示是准备就绪 或者已cd或使用 或者根本没有佩戴该sp的
-- 如果返回的nlid也是nil 那就真是没佩戴该sp
local function Check_OB_Trinkets(itemId,bufName,times)
	local nlok = not (GetInventoryItemID("player",INVSLOT_TRINKET1)==itemId or GetInventoryItemID("player",INVSLOT_TRINKET2)==itemId);
	if(nlok)then
		return nlok;
	end
	return not WA_CheckBuff(bufName,0,times);
end
local function Check_NL_Trinkets(itemId,preBufName,preTimes,bufName)
	local nlok = not (GetInventoryItemID("player",INVSLOT_TRINKET1)==itemId or GetInventoryItemID("player",INVSLOT_TRINKET2)==itemId);
	if(nlok)then
		return nlok;
	end
	local sssssid = 0;
	if(GetInventoryItemID("player",INVSLOT_TRINKET1)==itemId)then
		sssssid = INVSLOT_TRINKET1;
	else
		sssssid = INVSLOT_TRINKET2;
	end
	--那么仪器呢？
	-- 68972 泰坦能量  塑造者的祝福
	-- checkcd
	nlok = not WA_CheckBuff(preBufName,0,preTimes);
	if(nlok)then
		--如果buf堆够了
		local _,_,e = GetInventoryItemCooldown("player",sssssid);
		if(not e)then
			nlok = false;
		end
	end

	--也许已经开启了呢？
	if(not nlok)then
		nlok = not WA_CheckBuff(bufName);
	end
		--必须等待nl cd
	return nlok,itemId,sssssid;
end

local function rush_str()
	local checkok = Check_NL_Trinkets(59461,"原始狂怒",5,"铸炼怒火");
	--仪器
	if checkok then
		checkok = Check_NL_Trinkets(68972,"泰坦能量",5,"塑造者的祝福");
	end
	if checkok then
		checkok = Check_NL_Trinkets(69113,"泰坦能量",5,"塑造者的祝福");
	end
	--灭世之魔眼
	if checkok then
		checkok = Check_OB_Trinkets(77977,"泰坦之力",10);
	end
	if checkok then
		checkok = Check_OB_Trinkets(77200,"泰坦之力",10);
	end
	if checkok then
		checkok = Check_OB_Trinkets(77997,"泰坦之力",10);
	end
	return checkok;
end
local function rush_int()
	local checkok = true;
	--不羁之意志
	if checkok then
		checkok = Check_OB_Trinkets(77975,"战斗意念",10);
	end
	if checkok then
		checkok = Check_OB_Trinkets(77198,"战斗意念",10);
	end
	if checkok then
		checkok = Check_OB_Trinkets(77995,"战斗意念",10);
	end
	return checkok;
end
local function rush_agi()
	local checkok = true;
	--无拘之怒火
	if checkok then
		checkok = Check_OB_Trinkets(77974,"战斗专注",10);
	end
	if checkok then
		checkok = Check_OB_Trinkets(77197,"战斗专注",10);
	end
	if checkok then
		checkok = Check_OB_Trinkets(77994,"战斗专注",10);
	end
	if checkok then
		checkok = (not WA_CheckBuff("兔妖之啮"))
		or (not WA_CheckBuff("暗影之刃"))
		or (not WA_CheckBuff("凶猛"))
		or (not WA_CheckBuff("恶意"))
		or (not WA_CheckBuff("永恒敏捷"))
		or (not WA_CheckBuff("机敏"));
	end
	return checkok;
end
function D:FetchRushPrepose(target)
	if target:GetName()=="DEATHKNIGHT" or target:GetName()=="WARRIOR" then
		return rush_str;
	end
	if target:GetName()=="HUNTER" or target:GetName()=="ROGUE" then
		return rush_agi;
	end
	if target:GetName()=="DRUID" then
		if target.TalentType==2 then
			return rush_agi;
		else
			return rush_int;
		end
	end

	if target:GetName()=="SHAMAN" then
		if target.TalentType==2 then
			return rush_agi;
		else
			return rush_int;
		end
	end

	if target:GetName()=="PALADIN" then
		if target.TalentType==1 then
			return rush_int;
		else
			return rush_str;
		end
	end
	--MAGE	PRIEST	还有ss Warlock
	return rush_int;
end
