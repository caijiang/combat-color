-- CCTrades.lua
local addonName, T = ...;
local D = T.jcc;

local P = D:NewModule("TRADE","AceEvent-3.0", "AceHook-3.0");

function P:OnEnable()
	print("Loaded Trade Module");
	P.MySpellDescs = {
		["分解"] ={slot=1,marco=format("/cast 分解\n/use %s",D.tradeTOFJ)},
	};
end

function P:OnDisable()
	print("Unloaded Trade Module");
	P.MySpellDescs = nil;
end

function P:Match()
	return false;
end

function P:SpellDescs()
	return P.MySpellDescs;
end

local count = 0;
local floor = math.floor;

local function getnumberofitem(name)
	-- TODO 增加自动归并的功能
	local total = 0;
	for i=0,4 do
			local numberOfFreeSlots = GetContainerNumSlots(i);
			for s=1,numberOfFreeSlots do
				local id = GetContainerItemID(i,s);
				if id then
					local texture, itemCount, locked, quality, readable = GetContainerItemInfo(i,s);
					local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount,itemEquipLoc, itemTexture, itemSellPrice=GetItemInfo(id);
					if itemName==D.tradeTOFJ then
						total =  total+itemCount;
					end
				end
			end
		end
	return total;
end

function P:Work(pvp)
	CombatColorRestAllFlag();
	local spell, _, _, _, startTime, endTime = UnitCastingInfo("player");
	if spell then
		return;
	end
	--大约 0.5秒 输出一个
	if D.tradeTOFJ then
		--先看看东西还在不在
		local nm = getnumberofitem(D.tradeTOFJ);
		--D:Error("数量",nm);
		if nm>0 then
			CCFlagSpell("分解");
			return;
		else
			D.tradeTOFJ = nil;
		end
	end
end