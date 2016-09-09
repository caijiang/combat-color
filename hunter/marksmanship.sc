
# Executed every time the actor is available.

actions=auto_shot
actions+=/use_item,name=maalus_the_blood_drinker
actions+=/arcane_torrent,if=focus.deficit>=30
actions+=/blood_fury
actions+=/berserking
actions+=/potion,name=draenic_agility,if=((buff.急速射击.up|buff.嗜血.up)&(cooldown.群兽奔腾.remains<1))|target.time_to_die<=25

actions+=/奇美拉射击
actions+=/夺命射击
actions+=/急速射击
actions+=/群兽奔腾,if=buff.急速射击.up|buff.嗜血.up|target.time_to_die<=25
actions+=/call_action_list,name=精确瞄准,if=buff.精确瞄准.up
actions+=/爆炸陷阱,if=spell_targets.爆炸陷阱_tick>1
actions+=/夺命黑鸦
actions+=/凶暴野兽,if=cast_regen+action.瞄准射击.cast_regen<focus.deficit
actions+=/飞刃
actions+=/强风射击,if=cast_regen<focus.deficit
actions+=/弹幕射击
# Pool max focus for rapid fire so we can spam AimedShot with Careful Aim buff
actions+=/稳固射击,if=focus.deficit*cast_time%(14+cast_regen)>cooldown.急速射击.remains
actions+=/专注射击,if=focus.deficit*cast_time%(50+cast_regen)>cooldown.急速射击.remains&focus<100
# Cast a second shot for steady focus if that won't cap us.
稳固集中天赋 产生的稳固集中buf
actions+=/稳固射击,if=buff.pre_steady_focus.up&(14+cast_regen+action.瞄准射击.cast_regen)<=focus.deficit
actions+=/多重射击,if=spell_targets.multi_shot>6
actions+=/瞄准射击,if=talent.专注射击.enabled
actions+=/瞄准射击,if=focus+cast_regen>=85
actions+=/瞄准射击,if=buff.狩猎刺激.react&focus+cast_regen>=65
# Allow FS to over-cap by 10 if we have nothing else to do
actions+=/专注射击,if=50+cast_regen-10<focus.deficit
actions+=/稳固射击

actions.精确瞄准=飞刃,if=active_enemies>2
FocusCastingRegen
actions.精确瞄准+=/强风射击,if=spell_targets.强风射击>1&cast_regen<focus.deficit
actions.精确瞄准+=/弹幕射击,if=spell_targets.弹幕射击>1
actions.精确瞄准+=/瞄准射击
actions.精确瞄准+=/专注射击,if=50+cast_regen<focus.deficit
actions.精确瞄准+=/稳固射击

head=rancorbite_hood,id=128132
neck=choker_of_reciprocity,id=127976,bonus_id=563,gems=75crit,enchant=75crit
shoulders=morningscale_spaulders,id=109949,bonus_id=642/643
back=gossamer_felscorched_scarf,id=127971,enchant=gift_of_critical_strike,initial_cd=nan
chest=rancorbite_chain_shirt,id=128126,bonus_id=560
tabard=thunder_bluff_tabard,id=45584
wrists=bracers_of_fel_empowerment,id=124314
hands=eredar_felchain_gloves,id=124291,bonus_id=566
waist=rockhide_links,id=109835,bonus_id=642/760
legs=leggings_of_the_savage_hunt,id=124301
feet=diecast_ringmail_sabatons,id=124285
finger1=portal_key_signet,id=124189,bonus_id=41,enchant=50crit
finger2=maalus_the_blood_drinker,id=124636,bonus_id=631/650,enchant=50crit
trinket1=blood_seal_of_azzakel,id=109995,bonus_id=642/644
trinket2=chipped_soul_prism,id=124545
main_hand=baleful_rifle,id=124626,bonus_id=168/648/653,enchant=megawatt_filament,initial_cd=nan

# Gear Summary
# gear_ilvl=704.73
# gear_agility=3782
# gear_stamina=4915
# gear_crit_rating=2419
# gear_haste_rating=560
# gear_mastery_rating=739
# gear_multistrike_rating=1307
# gear_versatility_rating=889
# gear_leech_rating=103
# gear_armor=1483
# set_bonus=tier18lfr_2pc=1
summon_pet=cat
