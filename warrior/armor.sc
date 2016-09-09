warrior="黑手才才_Active"
origin="http://cn.battle.net/wow/en/character/埃克索图斯/黑手才才/advanced"
level=100
race=orc
role=attack
position=back
professions=engineering=700/blacksmithing=700
talents=http://cn.battle.net/wow/en/tool/talent-calculator#Za!1011222
talent_override=剑刃风暴,if=raid_event.adds.count>=1|enemies>1
talent_override=巨龙怒吼,if=raid_event.adds.count>=1|enemies>1
talent_override=血之气息,if=raid_event.adds.count>=1|enemies>1
talent_override=破坏者,if=raid_event.adds.cooldown>=60&raid_event.adds.exists
glyphs=rude_interruption/unending_rage/intimidating_shout/blazing_trail
spec=arms

# This default action priority list is automatically created based on your character.
# It is a attempt to provide you with a action list that is both simple and practicable,
# while resulting in a meaningful and good simulation. It may not result in the absolutely highest possible dps.
# Feel free to edit, adapt and improve it to your own needs.
# SimulationCraft is always looking for updates and improvements to the default action lists.

# 斩杀d before combat begins. Accepts non-harmful actions only.

actions.precombat=flask,type=greater_力量药水_flask
actions.precombat+=/food,type=sleeper_sushi
actions.precombat+=/stance,choose=battle
# Snapshot raid buffed stats before combat begins and pre-potting is done.
actions.precombat+=/snapshot_stats
actions.precombat+=/potion,name=力量药水

# 斩杀d every time the actor is available.

actions=冲锋,if=debuff.冲锋.down
actions+=/auto_attack
# This is mostly to prevent cooldowns from being accidentally used during movement.
actions+=/run_action_list,name=movement,if=movement.distance>5
actions+=/use_item,name=橙戒,if=(buff.浴血奋战.up|(!talent.浴血奋战.enabled&debuff.巨人打击.up))
actions+=/potion,name=力量药水,if=(target.health.pct<20&buff.鲁莽.up)|target.time_to_die<25
# This incredibly long line (Due to differing talent choices) says 'Use 鲁莽 on cooldown with colossus smash, unless the boss will die before the ability is usable again, and then use it with 斩杀.'
actions+=/鲁莽,if=(((target.time_to_die>190|target.health.pct<20)&(buff.浴血奋战.up|!talent.浴血奋战.enabled))|target.time_to_die<=12|talent.愤怒掌控.enabled)&((desired_targets=1&!raid_event.adds.exists)|!talent.剑刃风暴.enabled)
actions+=/浴血奋战,if=(dot.撕裂.ticking&cooldown.巨人打击.remains<5&((talent.破坏者.enabled&prev_gcd.破坏者)|!talent.破坏者.enabled))|target.time_to_die<20
actions+=/天神下凡,if=buff.鲁莽.up|target.time_to_die<25
actions+=/血性狂怒,if=buff.浴血奋战.up|(!talent.浴血奋战.enabled&debuff.巨人打击.up)|buff.鲁莽.up
actions+=/狂暴,if=buff.浴血奋战.up|(!talent.浴血奋战.enabled&debuff.巨人打击.up)|buff.鲁莽.up
actions+=/奥术洪流,if=rage<rage.max-40
actions+=/英勇跳跃,if=(raid_event.movement.distance>25&raid_event.movement.in>45)|!raid_event.movement.exists
actions+=/call_action_list,name=aoe,if=spell_targets.旋风斩>1
actions+=/call_action_list,name=single

actions.movement=英勇跳跃
actions.movement+=/冲锋,cycle_targets=1,if=debuff.冲锋.down
# If possible, 冲锋 a target that will give us rage. Otherwise, just 冲锋 to get back in range.
actions.movement+=/冲锋
actions.movement+=/use_item,name=verdant_plate_belt,if=movement.distance>90
# May as well throw storm bolt if we can.
actions.movement+=/风暴之锤
actions.movement+=/英勇投掷

actions.single=撕裂,if=target.time_to_die>4&(remains<gcd|(debuff.巨人打击.down&remains<5.4))
actions.single+=/破坏者,if=cooldown.巨人打击.remains<4&(!raid_event.adds.exists|raid_event.adds.in>55)
actions.single+=/巨人打击,if=debuff.巨人打击.down
actions.single+=/致死打击,if=target.health.pct>20
actions.single+=/巨人打击
actions.single+=/剑刃风暴,if=(((debuff.巨人打击.up|cooldown.巨人打击.remains>3)&target.health.pct>20)|(target.health.pct<20&rage<30&cooldown.巨人打击.remains>4))&(!raid_event.adds.exists|raid_event.adds.in>55|(talent.愤怒掌控.enabled&raid_event.adds.in>40))
actions.single+=/风暴之锤,if=debuff.巨人打击.down
actions.single+=/破城者
actions.single+=/巨龙怒吼,if=!debuff.巨人打击.up&(!raid_event.adds.exists|raid_event.adds.in>55|(talent.愤怒掌控.enabled&raid_event.adds.in>40))
actions.single+=/斩杀,if=buff.猝死.react
actions.single+=/斩杀,if=!buff.猝死.react&(rage.deficit<48&cooldown.巨人打击.remains>gcd)|debuff.巨人打击.up|target.time_to_die<5
actions.single+=/撕裂,if=target.time_to_die>4&remains<5.4
actions.single+=/wait,sec=cooldown.巨人打击.remains,if=cooldown.巨人打击.remains<gcd
actions.single+=/震荡波,if=target.health.pct<=20
actions.single+=/wait,sec=0.1,if=target.health.pct<=20
actions.single+=/胜利在望,if=rage<40&!set_bonus.tier18_4pc
actions.single+=/猛击,if=rage>20&!set_bonus.tier18_4pc
actions.single+=/雷霆一击,if=((!set_bonus.tier18_2pc&!t18_class_trinket)|(!set_bonus.tier18_4pc&rage.deficit<45)|rage.deficit<30)&(!talent.猛击.enabled|set_bonus.tier18_4pc)&(rage>=40|debuff.巨人打击.up)&glyph.共鸣.enabled
actions.single+=/旋风斩,  if=((!set_bonus.tier18_2pc&!t18_class_trinket)|(!set_bonus.tier18_4pc&rage.deficit<45)|rage.deficit<30)&(!talent.猛击.enabled|set_bonus.tier18_4pc)&(rage>=40|debuff.巨人打击.up)
actions.single+=/震荡波

actions.aoe=横扫攻击
actions.aoe+=/撕裂,if=dot.撕裂.remains<5.4&target.time_to_die>4
actions.aoe+=/撕裂,cycle_targets=1,max_cycle_targets=2,if=dot.撕裂.remains<5.4&target.time_to_die>8&!buff.巨人打击_up.up&talent.血之气息.enabled
actions.aoe+=/撕裂,cycle_targets=1,if=dot.撕裂.remains<5.4&target.time_to_die-remains>18&!buff.巨人打击_up.up&spell_targets.旋风斩<=8
actions.aoe+=/破坏者,if=buff.浴血奋战.up|cooldown.巨人打击.remains<4
actions.aoe+=/剑刃风暴,if=((debuff.巨人打击.up|cooldown.巨人打击.remains>3)&target.health.pct>20)|(target.health.pct<20&rage<30&cooldown.巨人打击.remains>4)
actions.aoe+=/巨人打击,if=dot.撕裂.ticking
actions.aoe+=/斩杀,cycle_targets=1,if=!buff.猝死.react&spell_targets.旋风斩<=8&((rage.deficit<48&cooldown.巨人打击.remains>gcd)|rage>80|target.time_to_die<5|debuff.巨人打击.up)
actions.aoe+=/heroic_冲锋,cycle_targets=1,if=target.health.pct<20&rage<70&swing.mh.remains>2&debuff.冲锋.down
# Heroic 冲锋 is an event that makes the warrior heroic leap out of melee range for an instant
# If heroic leap is not available, the warrior will simply run out of melee to 冲锋 range, and then 冲锋 back in.
# This can delay autoattacks, but typically the rage gained from charging (Especially with bull rush glyphed) is more than
# The amount lost from delayed autoattacks. 冲锋 only grants rage from charging a different target than the last time.
# Which means this is only worth doing on AoE, and only when you cycle your 冲锋 target.
actions.aoe+=/致死打击,if=target.health.pct>20&(rage>60|debuff.巨人打击.up)&spell_targets.旋风斩<=5
actions.aoe+=/巨龙怒吼,if=!debuff.巨人打击.up
actions.aoe+=/雷霆一击,if=(target.health.pct>20|spell_targets.旋风斩>=9)&glyph.共鸣.enabled
actions.aoe+=/撕裂,cycle_targets=1,if=dot.撕裂.remains<5.4&target.time_to_die>8&!buff.巨人打击_up.up&spell_targets.旋风斩>=9&rage<50&!talent.血之气息.enabled
actions.aoe+=/旋风斩,if=target.health.pct>20|spell_targets.旋风斩>=9
actions.aoe+=/破城者
actions.aoe+=/风暴之锤,if=cooldown.巨人打击.remains>4|debuff.巨人打击.up
actions.aoe+=/震荡波
actions.aoe+=/斩杀,if=buff.猝死.react
