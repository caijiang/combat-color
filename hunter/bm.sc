
# Executed every time the actor is available.

actions=auto_shot
actions+=/use_item,name=maalus_the_blood_drinker
actions+=/arcane_torrent,if=focus.deficit>=30
actions+=/blood_fury
actions+=/berserking
actions+=/potion,name=draenic_agility,if=!talent.群兽奔腾.enabled&((buff.狂野怒火.up&(legendary_ring.up|!legendary_ring.has_cooldown)&target.health.pct<=20)|target.time_to_die<=20)
actions+=/potion,name=draenic_agility,if=talent.群兽奔腾.enabled&((buff.群兽奔腾.remains&(legendary_ring.up|!legendary_ring.has_cooldown)&(buff.嗜血.up|buff.集中火力.up))|target.time_to_die<=40)
actions+=/群兽奔腾,if=((buff.嗜血.up|buff.集中火力.up)&(legendary_ring.up|!legendary_ring.has_cooldown))|target.time_to_die<=25
actions+=/凶暴野兽
actions+=/集中火力,if=buff.集中火力.down&((cooldown.狂野怒火.remains<1&buff.狂野怒火.down)|(talent.群兽奔腾.enabled&buff.群兽奔腾.remains)|pet.cat.buff.frenzy.remains<1)
actions+=/狂野怒火,if=focus>30&!buff.狂野怒火.up
actions+=/多重射击,if=spell_targets.multi_shot>1&pet.cat.buff.野兽顺劈斩.remains<0.5
actions+=/集中火力,min_frenzy=5
actions+=/弹幕射击,if=spell_targets.弹幕射击>1
actions+=/爆炸陷阱,if=spell_targets.爆炸陷阱_tick>5
actions+=/多重射击,if=spell_targets.multi_shot>5
actions+=/杀戮命令
actions+=/夺命黑鸦
actions+=/夺命射击,if=focus.time_to_max>gcd
actions+=/专注射击,if=focus<50
# Cast a second shot for steady focus if that won't cap us.
actions+=/眼镜蛇射击,if=buff.pre_steady_focus.up&buff.steady_focus.remains<7&(14+cast_regen)<focus.deficit
actions+=/爆炸陷阱,if=spell_targets.爆炸陷阱_tick>1
# Prepare for steady focus refresh if it is running out.
actions+=/眼镜蛇射击,if=talent.steady_focus.enabled&buff.steady_focus.remains<4&focus<50
actions+=/飞刃
actions+=/弹幕射击
actions+=/强风射击,if=focus.time_to_max>cast_time
actions+=/眼镜蛇射击,if=spell_targets.multi_shot>5
actions+=/奥术射击,if=(buff.狩猎刺激.react&focus>35)|buff.狂野怒火.up
actions+=/奥术射击,if=focus>=75
actions+=/眼镜蛇射击
