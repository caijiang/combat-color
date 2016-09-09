-- CCShareHoly.lua

local addonName, T = ...;
local D = T.jcc;

CCShareHoly = {};

function CCShareHoly.isEquals(unitid1,unitid2)
	if (not UnitExists(unitid1)) or (not UnitExists(unitid2)) then
		return false;
	end
	return UnitGUID(unitid1)==UnitGUID(unitid2);
end

function CCShareHoly.isHelp(unitid)
	if(not unitid)then
		unitid = "target";
	end
	if UnitGUID("player")==UnitGUID(unitid) then
		return true;
	end
	return UnitExists(unitid) and (not UnitIsDead(unitid)) and (not UnitIsGhost(unitid)) and UnitCanCooperate("player",unitid);
end

function CCShareHoly.isHarm(unitid)
	if(not unitid)then
		unitid = "target";
	end
	return UnitExists(unitid) and (not UnitIsDead(unitid)) and (not UnitIsGhost(unitid)) and UnitCanAttack("player",unitid);
end

local alwaysHoly = false;

local function hdebug(s)
--	print(s);
end

--最后一个意图读条的对象
local last_dutiao_guid
--当前读条开始时间
local current_dutiao_time;
--当前读条对象
local current_dutiao_guid;

function CCShareHoly.updateDutiaoTarget(time)
	if(time~=current_dutiao_time)then		
		current_dutiao_guid = last_dutiao_guid
		current_dutiao_time = time;
		hdebug(format("设置新的治疗ID:%s",current_dutiao_guid or "<无目标>"));
	end
end

function CCShareHoly.setLastDuTiaoTarget(unitid)
	last_dutiao_guid = UnitGUID(unitid);
end

function CCShareHoly.GetCurrentDutiaoUnitid()
	return CC_guidTounitid(current_dutiao_guid);
end


--需要控制 最近1分钟最小治疗 和最后最小治疗
local loged_time = 0,loged_health;
local big_loged_time = 0,big_loged_health;
--- localable

function CCShareHoly.updateBigShengguanshuHealth(time,health)
	if(big_loged_health)then
		if(GetTime()*1000-big_loged_time>60000)then
			--已超时 覆盖
			big_loged_time = time;
			big_loged_health = health;
		elseif(health<big_loged_health)then
			big_loged_time = time;
			big_loged_health = health;
			hdebug(format("更新最低治疗量:%d",big_loged_health));
		end
	else
		big_loged_time = time;
		big_loged_health = health;
		hdebug(format("获取最低治疗量:%d",big_loged_health));
	end	
end

function CCShareHoly.updateShengguanshuHealth(time,health)
	if(loged_health)then
		if(GetTime()*1000-loged_time>60000)then
			--已超时 覆盖
			loged_time = time;
			loged_health = health;
		elseif(health<loged_health)then
			loged_time = time;
			loged_health = health;
			hdebug(format("更新最低治疗量:%d",loged_health));
		end
	else
		loged_time = time;
		loged_health = health;
		hdebug(format("获取最低治疗量:%d",loged_health));
	end	
end

-- 是否需要 直接 快速治疗
function CCShareHoly.raid_quickdirectNeedable(mytarget)
	return not WA_CheckDebuff("磨难",0,0,nil,mytarget);
end

-- 是否应该禁止 快速治疗
function CCShareHoly.raid_noLittleHeal(mytarget)
	return not WA_CheckDebuff("深度腐蚀",0,0,nil,mytarget);
end

-- localable
function CCShareHoly.raid_safe(mytarget)
	if(UnitGUID(mytarget)==UnitGUID("focus") and UnitGUID("player")~=UnitGUID("focus"))then
		--目标是坦克 而且我没有设自己为焦点
		return false;
	end
	--腐蚀烂泥 4w hp
	if((not WA_CheckBuff("芬克的混合剂",0,0,nil,mytarget)) and WA_CheckDebuff("生命值过低",0,0,nil,mytarget) and (not WA_CheckDebuff("腐蚀烂泥",0,0,nil,mytarget)))then
		--有腐蚀
		return UnitHealth(mytarget)>40000;
	end
	if((not WA_CheckBuff("芬克的混合剂",0,0,nil,mytarget)) and WA_CheckDebuff("生命值过低",0,0,nil,mytarget))then		
		return true;
	end
	return false;
end

-- 判断目标是否立刻就要挂了！
-- 如果安全线已拉好 那么。。。算了 不管它先
function CCShareHoly.isGoingDead(mytarget,safehp,absrate,ag)
	if(safehp)then
		return false;
	end
	if(CCShareHoly.raid_safe(mytarget))then return false; end
	if(not absrate)then
		absrate = 0.05;
	end
	local incoming = UnitGetIncomingHeals(mytarget) or 0;
	if ag then
		return UnitHealth(mytarget)/UnitHealthMax(mytarget)<absrate;
	end
	return UnitHealth(mytarget)+incoming/UnitHealthMax(mytarget)<absrate;
end

function CCShareHoly.isDanger(mytarget,safehp)
	if not CCShareHoly.isHelp(mytarget) then return false; end
	if(CCShareHoly.raid_safe(mytarget))then return false; end
	local incoming = UnitGetIncomingHeals(mytarget) or 0;
	if(safehp)then
		return UnitHealth(mytarget)+incoming<safehp;
	end
--[[	if(loged_health)then
		return UnitHealthMax(mytarget)-UnitHealth(mytarget)-incoming>4*loged_health or (UnitHealth(mytarget)+incoming)/UnitHealthMax(mytarget)<0.1;
	end
]]
	return (UnitHealth(mytarget)+incoming)/UnitHealthMax(mytarget)<0.5;
end

function CCShareHoly.isHolyAbleBig(mytarget)
	if alwaysHoly then return true; end
	if(CCShareHoly.raid_safe(mytarget))then return false; end
	if not WA_CheckDebuff("灼热血浆",0,0,nil,mytarget) then
		return true;
	end
	if not WA_CheckDebuff("上古屏障",0,0,nil,mytarget) then
		return true;
	end
	if not WA_CheckDebuff("虚弱的上古屏障",0,0,nil,mytarget) then
		return true;
	end
	if not big_loged_health then return true; end
	local incoming = UnitGetIncomingHeals(mytarget) or 0;
	local futurehealth = UnitHealth(mytarget)+incoming;
	return UnitHealthMax(mytarget)-futurehealth>big_loged_health;
end
-- 需要治疗，血量阀值高于最低治疗量
function CCShareHoly.isHolyAble(mytarget,bs)
	if(alwaysHoly and bs<5)then
		return true;
	end
	if not WA_CheckDebuff("上古屏障",0,0,nil,mytarget) then
		return true;
	end
	if not WA_CheckDebuff("虚弱的上古屏障",0,0,nil,mytarget) then
		return true;
	end
	if(CCShareHoly.raid_safe(mytarget))then return false; end
	if(not bs)then
		bs = 1;
	end
	--bs<=4 and 
	if not WA_CheckDebuff("灼热血浆",0,0,nil,mytarget) then
		return true;
	end

	local incoming = UnitGetIncomingHeals(mytarget) or 0;
	local futurehealth = UnitHealth(mytarget)+incoming;

	if type(bs)=="function" then
		return bs(futurehealth,UnitHealthMax(mytarget),mytarget);
	end

	if(loged_health)then		
		--print("有记录最低治疗量："..loged_health);
		if(UnitHealthMax(mytarget)-futurehealth<loged_health*bs)then
			--无需治疗
			return false;
		end
		return true;
	end
	if(bs<=2)then --是为了在没有记录基础治疗量的情况下 进行治疗测试用的
		return true;
	end
	return false;
end

function CCShareHoly.isYichu(mytarget,spell,endTime)
	
	if not WA_CheckDebuff("灼热血浆",0,0,nil,mytarget) then return false; end
	if not WA_CheckDebuff("上古屏障",0,0,nil,mytarget) then return false; end
	if not WA_CheckDebuff("虚弱的上古屏障",0,0,nil,mytarget) then return false; end

	local incoming = UnitGetIncomingHeals(mytarget) or 0;
	local myincoming = UnitGetIncomingHeals(mytarget, "player") or 0;
	local lastincoming = 0;

	if((spell=="圣光术" or spell=="治疗波" or spell=="治疗术") and myincoming>0)then
		CCShareHoly.updateShengguanshuHealth(endTime,myincoming);
		lastincoming = loged_health;
	end
	if((spell=="神圣之光" or spell=="强效治疗波" or spell=="强效治疗术") and myincoming>0)then
		CCShareHoly.updateBigShengguanshuHealth(endTime,myincoming);
		lastincoming = big_loged_health;
	end

	if(alwaysHoly)then
		return false;
	end
	if(CCShareHoly.raid_safe(mytarget))then return true; end

	incoming = incoming or lastincoming;
	
	local futurehealth = UnitHealth(mytarget)+incoming;
	--myincoming>0 and 
	return UnitHealthMax(mytarget)<=futurehealth
end


function CCShareHoly.check_user_invslot_huilan(ssid)
	local _,d,e = GetInventoryItemCooldown("player",ssid);
	local itemtext = GetInventoryItemTexture("player",ssid);
	if(strfind(itemtext,"PVP")~=nil)then
		return false;
	end
	local itemid = GetInventoryItemID("player",ssid);
	if(itemid~=52354  --精神sp
		and itemid~=56136 --pt鸡蛋壳
		and itemid~=58184 
		and itemid~=94509 --影踪突袭营的抚慰护符
		)then
		return false;
	end
	if(d<2 and e>0)then
		if(ssid==INVSLOT_HAND)then
			CCFlagSpell("手套");
			return true;
		elseif(ssid==INVSLOT_TRINKET1)then
			CCFlagSpell("饰品1");
			return true;
		elseif(ssid==INVSLOT_TRINKET2)then
			CCFlagSpell("饰品2");
			return true;
		end
	end
	return false;
end

local pID = {}
local rID = {}
for i = 1, 4 do
	pID[i] = format("party%d", i)
end
pID[5]= "player";
for i = 1, 40 do
	rID[i] = format("raid%d", i)
end

function CCShareHoly.RaidHealth()
	local health = 0;
	if(IsInRaid())then
		for i = 1, GetNumGroupMembers() do
			if(CCShareHoly.isHelp(rID[i]))then
				health = health+UnitHealth(rID[i]);
			end
		end
	else
		for i = 1, 5 do
			if(CCShareHoly.isHelp(pID[i]))then
				health = health+UnitHealth(pID[i]);
			end
		end
	end
	return health;
end

function CCShareHoly.RaidHealthMax()
	local health = 0;
	if(IsInRaid())then
		for i = 1, GetNumGroupMembers() do
			if(CCShareHoly.isHelp(rID[i]))then
				health = health+UnitHealthMax(rID[i]);
			end
		end
	else
		for i = 1, 5 do
			if(CCShareHoly.isHelp(pID[i]))then
				health = health+UnitHealthMax(pID[i]);
			end
		end
	end
	return health;
end

function CCShareHoly.AtMyFront(mytarget)
	local x0,y0 = GetPlayerMapPosition("player");
	if x0==0 and y0==0 then return false end;
	local orientation = GetPlayerFacing();
	local P = orientation + math.pi / 2;
	local xs = math.sin(math.pi / 2 - P) / math.sin(P);
        local n = xs * x0 - y0;

	local x,y = GetPlayerMapPosition(mytarget);
	if x==0 and y==0 then return false end;
	local test = y-xs*x+n;
	if(orientation < math.pi / 2 or orientation > math.pi * 1.5)then
		return test>0;
	else
		return test<0;
	end
end

local function isHolyAbleCrow_(thecenter,mytarget,myfront,yards,bs,dims)	
	if(myfront and (not CCShareHoly.AtMyFront(mytarget)))then
		return false;
	end
	if yards==0 then
		return CCShareHoly.isHolyAble(mytarget,bs);
	end
	local startX, startY = GetPlayerMapPosition(mytarget);
	local endX, endY = GetPlayerMapPosition(thecenter);
	local dX = (startX - endX);
	if(dims)then
		dX = dX*dims[1];
	end
	local dY = (startY - endY);
	if(dims)then
		dY = dY*dims[2];
	end
	local myyards = math.sqrt(dX * dX + dY * dY);
	if(myyards>yards)then
		return false;
	end
	return CCShareHoly.isHolyAble(mytarget,bs);
end

-- 检查unit附近几码内 需要治疗的人
function CCShareHoly.isHolyAbleCrowNew(mytarget,yards,bs,numbers)
	
end

-- 检测是否有群体需要治疗
-- 群体治疗的标准是 有4个目标 或者60%以上的目标需要治疗
-- mytarget 指定目标
-- myfront true 为自己的正前方 mytarget也应当为我自己
-- yards 距离
-- bs
-- numbers
-- rate
function CCShareHoly.isHolyAbleCrow(mytarget,myfront,yards,bs,numbers)
	local mapName = GetMapInfo();
	local dims;
	if DBM then
		local mapSizes = DBM.MapSizes;
		dims = mapSizes[mapName] and mapSizes[mapName][GetCurrentMapDungeonLevel()];
	end	
	if(not dims)then
		--无法比较详尽yards 只要依靠目标和自己之间的距离进行判断
		--但如果治疗的是自己呢？ 就没办法了。。。
		if(UnitGUID(mytarget)==UnitGUID("player") and yards>0)then
			D:Debug("CC canot check yards in no DMB via player.");
			return false;
		end
		local startX, startY = GetPlayerMapPosition(mytarget);
		local endX, endY = GetPlayerMapPosition("player");
		if startX==0 and startY==0 then return false end;
		if endX==0 and endY==0 then return false end;
		local dX = (startX - endX);
		local dY = (startY - endY);
		yards = math.sqrt(dX * dX + dY * dY);
		--print(format("重新计算距离:%d",yards));
	end
	if(myfront)then
		mytarget = "player";
	end
	--if(not CCShareHoly.isHelp(mytarget))then
	--	return false;
	--end
	numbers = numbers or 4;
	--rates = rates or 60;
	local total = 0;
	local hits = 0;
	if(IsInRaid())then
		for i = 1, GetNumGroupMembers() do
			if(CCShareHoly.isHelp(rID[i]))then
				total =total+1;
				if(isHolyAbleCrow_(mytarget,rID[i],myfront,yards,bs,dims))then
					hits= hits+1;
				end
			end
		end
	else
		for i = 1, 5 do
			if(CCShareHoly.isHelp(pID[i]))then
				total =total+1;
				if(isHolyAbleCrow_(mytarget,pID[i],myfront,yards,bs,dims))then
					hits= hits+1;
				end
			end
		end
	end
	--print(format("总人数：%d, 可以a到的需奶人数:%d   rates",total,hits));
	if type(numbers)=="function" then
		return numbers(hits);
	end
	return hits>=numbers or hits/total>=0.6;
end

local function isAnyoneAroundTarget_(thecenter,mytarget,myfront,yards,dims)
	if(myfront and (not CCShareHoly.AtMyFront(mytarget)))then
		return false;
	end
	local startX, startY = GetPlayerMapPosition(mytarget);
	local endX, endY = GetPlayerMapPosition(thecenter);
	local dX = (startX - endX);
	if(dims)then
		dX = dX*dims[1];
	end
	local dY = (startY - endY);
	if(dims)then
		dY = dY*dims[2];
	end
	local myyards = math.sqrt(dX * dX + dY * dY);
	if(myyards>yards)then
		return false;
	end
	return true;
end

-- 检查目标身边有没有其他人 有返回true 没有返回false
function CCShareHoly.isAnyoneAroundTarget(mytarget,myfront,yards,defaultrs)
	local mapName = GetMapInfo();
	local dims;
	if DBM then
		local mapSizes = DBM.MapSizes;
		dims  = mapSizes[mapName] and mapSizes[mapName][GetCurrentMapDungeonLevel()];
	end
	if(not dims)then
		--无法比较详尽yards 只要依靠目标和自己之间的距离进行判断
		--但如果治疗的是自己呢？ 就没办法了。。。
		if(UnitGUID(mytarget)==UnitGUID("player"))then
			return defaultrs;
		end
		local startX, startY = GetPlayerMapPosition(mytarget);
		local endX, endY = GetPlayerMapPosition("player");
		if startX==0 and startY==0 then return defaultrs end;
		if endX==0 and endY==0 then return defaultrs end;
		local dX = (startX - endX);
		local dY = (startY - endY);
		yards = math.sqrt(dX * dX + dY * dY);
		--print(format("重新计算距离:%d",yards));
	end	
	--[[if(not CCShareHoly.isHelp(mytarget))then
		return false;
	end]]

	local total = 0;
	local hits = 0;
	if(IsInRaid())then
		for i = 1, GetNumGroupMembers() do
			if(CCShareHoly.isHelp(rID[i]) and UnitGUID(rID[i])~=UnitGUID(mytarget))then
				total =total+1;
				if(isAnyoneAroundTarget_(mytarget,rID[i],myfront,yards,dims))then
					hits= hits+1;
				end
			end
		end
	else
		for i = 1, 5 do
			if(CCShareHoly.isHelp(pID[i]) and UnitGUID(pID[i])~=UnitGUID(mytarget))then
				total =total+1;
				if(isAnyoneAroundTarget_(mytarget,pID[i],myfront,yards,dims))then
					hits= hits+1;
				end
			end
		end
	end
	return hits>0;
end

local function alwaystrue()
	return true;
end

local function alwaysfalse()
	return false;
end

if false then
	CCShareHoly.isDanger = alwaystrue;
	CCShareHoly.isHolyAbleBig = alwaystrue;
	CCShareHoly.isHolyAble = alwaystrue;
	CCShareHoly.isYichu = alwaysfalse;
end
