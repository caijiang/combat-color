---threats.lua
---85:  25 300 10 200 5 100

local pID = {}
local ptID = {}
local ppID = {}
local pptID = {}
local rID = {}
local rtID = {}
local rpID = {}
local rptID = {}
for i = 1, 4 do
	pID[i] = format("party%d", i)
	ptID[i] = format("party%dtarget", i)
	ppID[i] = format("partypet%d", i)
	pptID[i] = format("partypet%dtarget", i)
end
for i = 1, 40 do
	rID[i] = format("raid%d", i)
	rtID[i] = format("raid%dtarget", i)
	rpID[i] = format("raidpet%d", i)
	rptID[i] = format("raidpet%dtarget", i)
end

function CC_guidTounitid(guid)
	if(not guid)then return nil; end
	if inParty or inRaid then
		if inRaid then
			for i = 1, GetNumGroupMembers() do
				if(UnitGUID(rID[i])==guid)then return rID[i]; end
				if(UnitGUID(rpID[i])==guid)then return rpID[i]; end
				if(UnitGUID(rtID[i])==guid)then return rtID[i]; end
				if(UnitGUID(rptID[i])==guid)then return rptID[i]; end
			end
		else
			for i = 1, GetNumSubgroupMembers() do
				if(UnitGUID(pID[i])==guid)then return pID[i]; end
				if(UnitGUID(ppID[i])==guid)then return ppID[i]; end
				if(UnitGUID(ptID[i])==guid)then return ptID[i]; end
				if(UnitGUID(pptID[i])==guid)then return pptID[i]; end
			end
		end
	end
	if not inRaid then
		if(UnitGUID("player")==guid)then return "player"; end
		if(UnitGUID("pet")==guid)then return "pet"; end
		if(UnitGUID("target")==guid)then return "target"; end
		if(UnitGUID("pettarget")==guid)then return "pettarget"; end
	end
	if(UnitGUID("target")==guid)then return "target"; end
	if(UnitGUID("targettarget")==guid)then return "targettarget"; end
	if(UnitGUID("focus")==guid)then return "focus"; end
	if(UnitGUID("focustarget")==guid)then return "focustarget"; end
	if(UnitGUID("mouseover")==guid)then return "mouseover"; end
	if(UnitGUID("mouseovertarget")==guid)then return "mouseovertarget"; end
	return nil;
end

-- 估计下目标 在多少秒内可以存活 如果可以存活返回true否者返回false
function CC_reckon_target_liveon(time,unit)
	local dps = CC_reckon_dps();
	if inParty or inRaid then
		if inRaid then
			local rnumbers = GetNumGroupMembers();
			if(rnumbers<15)then
				dps = dps * 6;
			else
				dps = dps * 17;
			end
		else
			dps = dps * 3;
		end
	end
	return UnitHealth(unit or "target")>time*dps;
end

--根据等级 团队类型 决定大致的dps
--而仇恨阀值 大概是这个数字*100*gcd
--经过计算wow的伤害公式应该是以1.1为底数的指数曲线 常数为 0.16494845147960308
function CC_reckon_dps()
	--1.4^90/70875023
	local dps = math.pow(1.4,UnitLevel("player"))/7087502355; -- add 55
	if inParty or inRaid then
		if inRaid then
			local rnumbers = GetNumGroupMembers();
			if(rnumbers<15)then
				dps = dps * 0.9;
			end
		else
			dps = dps * 0.9 * 0.8;
		end
	end
	if not inRaid then
		dps = dps * 0.9 * 0.7;
	end
	return dps;
end

--默认关闭！
CC_threat_control = false;



function CC_Toogle_Threat()
	CC_threat_control = not CC_threat_control;
	if(CC_threat_control)then
		jcmessage("仇恨控制模式");
	else
		jcmessage("无视仇恨模式");
	end
end


local inParty,inRaid;
local myGUID;
local threatTable           -- Format: threatTable[guid] = threatValue
local tankGUID;
local mystate,mythreatpct;
local loged_tt = 0;

function cc_test_threat()
	local old_CC_threat_control = CC_threat_control;
	CC_threat_control = true;
	cc_updateThreats(false);
	local ct = threatTable[myGUID];
	if(not ct)then
		loged_tt = 0;
	else
		jcmessage("仇恨增加:"..(ct-loged_tt));
		loged_tt = ct;
	end
	CC_threat_control = old_CC_threat_control
end

function cc_PARTY_MEMBERS_CHANGED()
	myGUID = UnitGUID("player");
	inParty = GetNumSubgroupMembers() > 0
	inRaid = IsInRaid();
end

local pchz_times = 0
function print_chzhi(tx)
	if(pchz_times==0)then
		jcmessage("仇恨差值："..tx);
	end
	pchz_times = pchz_times+1;
	if(pchz_times>=100)then
		pchz_times = 0;
	end
end

local lastWarningMessage = 0;
--true 表示不应该继续！
function CC_check_threat_dps()
	local tstate,trate,tx = cc_updateThreats(false);

	if(tstate==2)then
		if(GetTime()-lastWarningMessage>3)then
			jcmessage("即将OT，请控制节奏");
			lastWarningMessage = GetTime();
		end
		return true;
	end
	if(not(tstate==3 or tstate==0))then
		if(GetTime()-lastWarningMessage>3)then
			jcmessage("已OT! 停止输出！");
			lastWarningMessage = GetTime();
		end
		return true;
	end
	return false;
end


--更新所有仇恨
--保持自己和最高仇恨拥有者（tanking）
--threatpct  到达100就会OT所以 这个值很重要
--仇恨相差值
--返回值
-- state 3 = securely tanking, 2 = insecurely tanking, 1 = not tanking but higher threat than tank, 0 = not tanking and lower threat than tank
-- threatpct  到达100就会OT所以 这个值很重要
-- xvalue = 相差值
-- 参数 tank 是否tank模式
function cc_updateThreats(tank)
	if((not CC_threat_control) and (not tank))then
		return 0,0,9999999999;
	else
		threatTable = {};
		local mob = "target";
		local mobTarget = mob.."target"
		if inParty or inRaid then
			if inRaid then
				for i = 1, GetNumGroupMembers() do
					c_updatethreat(rID[i], mob)
					c_updatethreat(rpID[i], mob)
					c_updatethreat(rtID[i], mob)
					c_updatethreat(rptID[i], mob)
				end
			else
				for i = 1, GetNumSubgroupMembers() do
					c_updatethreat(pID[i], mob)
					c_updatethreat(ppID[i], mob)
					c_updatethreat(ptID[i], mob)
					c_updatethreat(pptID[i], mob)
				end
			end

		end
		if not inRaid then
			c_updatethreat("player", mob)
			c_updatethreat("pet", mob)
			c_updatethreat("target", mob)
			c_updatethreat("pettarget", mob)
		end
		c_updatethreat("target", mob)
		c_updatethreat("targettarget", mob)
		c_updatethreat("focus", mob)
		c_updatethreat("focustarget", mob)
		c_updatethreat(mobTarget, mob)
		c_updatethreat("mouseover", mob)
		c_updatethreat("mouseovertarget", mob)
		if(tank)then
			if((not tankGUID) or tankGUID~=myGUID)then
				return 2,0,0;
			end
			if(not threatTable[myGUID])then
				return 2,0,0;
			end
			local minsap = 9999999999999;
			for guid,tvalue in pairs(threatTable) do
				if(guid~=myGUID and guid~=tankGUID and threatTable[myGUID]-tvalue<minsap)then
					minsap = threatTable[myGUID]-tvalue;
				end
			end
			if(minsap< CC_reckon_dps()*100*1.5*2)then
				mystate = 2;
			end
			return mystate,mythreatpct,minsap;
			--无视双T的情况了
			--遍历寻找仇恨跟我接近的

		end
		if(myGUID==tankGUID)then
			--print("mystate:"..mystate);
			return 2,100,0;
		end
		--必须支持没有tank存在的模式！
		if(not tankGUID)then
			if(threatTable[myGUID])then
				return mystate,mythreatpct,threatTable[myGUID]
			end
			return 0,0,9999999999;
		end
		if(threatTable[myGUID] and threatTable[tankGUID])then
			if(mystate~=2)then
				--gcd TODO 暂定为1.5
				if(threatTable[tankGUID]-threatTable[myGUID]<CC_reckon_dps()*100*1.5)then
					mystate = 2
				end
				--
			end
			return mystate,mythreatpct,threatTable[tankGUID]-threatTable[myGUID]
		end
		return 0,0,9999999999;
	end
end




function c_updatethreat(unitid, mobunitid)
	local guid = UnitGUID(unitid)
	if guid and not threatTable[guid] then
		local isTanking, state, scaledPercent, rawPercent, threatValue = UnitDetailedThreatSituation(unitid, mobunitid)
		if threatValue then
			--if threatValue > topthreat then topthreat = threatValue end
			if isTanking then tankGUID = guid end
			threatTable[guid] = threatValue
			if(guid==myGUID)then
				mystate = state;
				mythreatpct = scaledPercent;
			end
		else
			-- We use the special value -1 to indicate nil here.
			threatTable[guid] = -1
		end
	end
end

local function _i_need_zhengjiu(unitid)
	if(myGUID==UnitGUID(unitid))then
		return;
	end
	local _,cname= UnitClass(unitid);
	if(UnitExists(unitid) and (not UnitIsDead(unitid)) and (not UnitIsGhost(unitid)) and "PALADIN"==cname)then
		SendChatMessage("紧急：我的仇恨已经非常紧张，请丢我一个拯救，谢谢啊","WHISPER",nil,UnitName(unitid));
	end
end

--向骑士求救 UnitClass Paladin
function cc_i_need_zhengjiu()
	if inParty or inRaid then
		if inRaid then
			for i = 1, GetNumGroupMembers() do
				_i_need_zhengjiu(rID[i])
			end
		else
			for i = 1, GetNumSubgroupMembers() do
				_i_need_zhengjiu(pID[i])
			end
		end
	end
end
