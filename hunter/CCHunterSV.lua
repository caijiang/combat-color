-- CCHunterSV.lua

--溅射>暴击≈全能>精通>急速

--[[
爆炸射击
黑箭
夺命黑鸦(如果选择)
凶暴野兽(如果选择)
奥术射击(毒蛇钉刺)
弹幕射击(如果选择)
飞刃(如果选择)
强风射击(如果选择)
兽群奔腾(如果选择)
奥术射击
眼镜蛇射击

aoe

爆炸射击(荷枪实弹)
弹幕射击(如果选择)
爆炸射击(目标<5)
黑箭
爆炸陷阱
夺命黑鸦(如果选择)
凶暴野兽(如果选择)
兽群奔腾(如果选择)
多重射击
飞刃(如果选择)
强风射击(如果选择)
眼镜蛇射击

技巧 奥术打鼠标 多重打鼠标 黑鸭打鼠标
]]

local addonName, TT = ...;
local D = TT.jcc;

local _,clzz = UnitClass("player");
if clzz~="HUNTER" then return;end

local Q = D.HUNTER;

local F = Q:NewModule("HUNTER3", "AceEvent-3.0", "AceHook-3.0","CCTalent-1.0");

F.TalentSpellDescs = {
	["爆炸射击"] = {slot=31,havecd=true},
	["黑箭"] = {slot=32,havecd=true},--触发 2次荷枪实弹
	["眼镜蛇射击"] = 33,
};


function F:Work(pvp,inFarRange,inNearRange)

	local targetpct = UnitHealth("target")/UnitHealthMax("target")
	local power = UnitPower("player");
--AOE模式
	if CCFightType==2 or D.FightHSMode then

		if WA_CheckSpellUsable("爆炸射击") and not WA_CheckBuff("荷枪实弹") then
			CCFlagSpell("爆炸射击");
			return;
		end

		--弹幕射击(如果选择)
		if CCFightType==2 and WA_CheckSpellUsable("弹幕射击") then
			CCFlagSpell("弹幕射击");
			return;
		end

		-- 横扫模式 <5
		if D.FightHSMode and WA_CheckSpellUsable("爆炸射击") then
			CCFlagSpell("爆炸射击");
			return;
		end



		if not CC_Raid_ShouldDMGWithoutKO() and WA_CheckSpellUsable("黑箭") then

			CCFlagSpell("黑箭");

			return;
		end



		if not CC_Raid_ShouldDMGWithoutKO() and WA_CheckSpellUsable("夺命黑鸦") then
			CCFlagSpell("夺命黑鸦");

			return;
		end

		if not CC_Raid_ShouldDMGWithoutKO() and WA_CheckSpellUsable("凶暴野兽") then
			CCFlagSpell("凶暴野兽");

			return;
		end

		if not CC_Raid_ShouldDMGWithoutKO() and WA_CheckSpellUsable("兽群奔腾") then

			CCFlagSpell("兽群奔腾");

			return;
		end


		if WA_CheckSpellUsable("多重射击") then
			CCFlagSpell("多重射击");
			return;
		end
		Q:DoWengu();

		return;
	end

	--普通阶段

	if D:CastReadable() and Q.ToRush and (not WA_CheckBuff("急速射击") or D:IsSXing() ) then
		CCWA_RacePink();
	elseif D:CastReadable() and Q.ToRush then
		CCWA_RacePink(false,Q.checktouseitem);
	end





	if WA_CheckSpellUsable("爆炸射击") then

		CCFlagSpell("爆炸射击");

		return;
	end

	if not CC_Raid_ShouldDMGWithoutKO() and WA_CheckSpellUsable("黑箭") then

		CCFlagSpell("黑箭");
		return;
	end

	if not CC_Raid_ShouldDMGWithoutKO() and WA_CheckSpellUsable("夺命黑鸦") then

		CCFlagSpell("夺命黑鸦");

		return;
	end

	if not CC_Raid_ShouldDMGWithoutKO() and WA_CheckSpellUsable("凶暴野兽") then

		CCFlagSpell("凶暴野兽");

		return;

	end

	if WA_CheckSpellUsable("奥术射击") and WA_CheckDebuff("毒蛇钉刺",1.5,0,true) then
		CCFlagSpell("奥术射击");
		return;

	end

	-- 这个必须提供明确的条件！

	if false and WA_CheckSpellUsable("弹幕射击") then

		CCFlagSpell("弹幕射击");

		return;

	end



	if not CC_Raid_ShouldDMGWithoutKO() and WA_CheckSpellUsable("飞刃") then
		CCFlagSpell("飞刃");
		return true;
	end

	if not CC_Raid_ShouldDMGWithoutKO() and WA_CheckSpellUsable("强风射击") then
		CCFlagSpell("强风射击");
		return true;
	end



	if not CC_Raid_ShouldDMGWithoutKO() and WA_CheckSpellUsable("兽群奔腾") then

		CCFlagSpell("兽群奔腾");

		return;
	end

	if WA_CheckSpellUsable("奥术射击") then
		CCFlagSpell("奥术射击");
		return;
	end

	Q:DoWengu();
end
