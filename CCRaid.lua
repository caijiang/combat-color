--CCRaid

local addonName, T = ...;
local D = T.jcc;

function CC_Raid_NoRush(unitid)
	unitid = unitid or "target";
	--融合怪15%以下  就别使用大招
	--软泥一直不用
	if UnitName(unitid)=="丑恶的融合怪" then
		return UnitHealth(unitid)/UnitHealthMax(unitid)<0.15;
	end
	if UnitName(unitid)=="堕落熔岩" then
		return true;
	end
	return false;
end

-- 需要制造伤害 但是绝对不可以杀死的目标
function CC_Raid_ShouldDMGWithoutKO(unitid)
	unitid = unitid or "target";
	if UnitName(unitid)=="腐蚀之触" then
		local spell, _, _, _, startTime, endTime, isTradeSkill, castID, notInterruptible = UnitCastingInfo(unitid);
		if spell=="灼热之握" then
			return true;
		end
	end
	return false;
end

-- 团队动作
-- 返回true 表示应该停止主函数运行
function CC_Raid_B(unitid)
	unitid = unitid or "target";
	if(UnitName(unitid)=="烬网织网蛛" and ((not WA_CheckBuff("暴戾",0,0,nil,unitid)) or (not WA_CheckDebuff("暴戾"))))then
		--嘲讽
		--print("嘲讽 嘲讽");
		--if(CC_Try_Chaofeng())then
		--	return true;
		--end
	end
	return false;
end
