
# Executed every time the actor is available.

# clean pyro info, after combustion
actions=stop_pyro_chain,if=prev_off_gcd.combustion
PutState
# steal it
actions+=/counterspell,if=target.debuff.casting.react
actions+=/time_warp,if=target.health.pct<25|time>5
actions+=/call_action_list,name=movement,if=raid_event.movement.exists
# talents
actions+=/rune_of_power,if=buff.rune_of_power.remains<cast_time
actions+=/call_action_list,name=combust_sequence,if=pyro_chain
actions+=/call_action_list,name=crystal_sequence,if=talent.prismatic_crystal.enabled&pet.prismatic_crystal.active
actions+=/call_action_list,name=init_combust,if=!pyro_chain
# Utilize level 90 active talents while avoiding pyro munching
actions+=/rune_of_power,if=buff.rune_of_power.remains<action.fireball.execute_time+gcd.max&!(buff.heating_up.up&action.fireball.in_flight)
actions+=/mirror_image,if=!(buff.heating_up.up&action.fireball.in_flight)
actions+=/call_action_list,name=aoe,if=active_enemies>10
actions+=/call_action_list,name=single_target

actions.movement=blink,if=movement.distance>10
actions.movement+=/blazing_speed,if=movement.remains>0
actions.movement+=/ice_floes,if=buff.ice_floes.down&(raid_event.movement.distance>0|raid_event.movement.in<action.fireball.cast_time)

晶体
# Action list while Prismatic Crystal is up
actions.crystal_sequence=choose_target,name=prismatic_crystal
# Spread Combustion from PC
actions.crystal_sequence+=/inferno_blast,if=dot.combustion.ticking&active_dot.combustion<active_enemies+1
# Spread Combustion on multitarget fights
actions.crystal_sequence+=/inferno_blast,cycle_targets=1,if=dot.combustion.ticking&active_dot.combustion<active_enemies
急速冷却 为了龙息
actions.crystal_sequence+=/cold_snap,if=!cooldown.dragons_breath.up
actions.crystal_sequence+=/dragons_breath,if=glyph.dragons_breath.enabled
actions.crystal_sequence+=/blast_wave
# Use pyros before PC's expiration
actions.crystal_sequence+=/pyroblast,if=execute_time=gcd.max&pet.prismatic_crystal.remains<gcd.max+travel_time&pet.prismatic_crystal.remains>travel_time
actions.crystal_sequence+=/call_action_list,name=single_target

# Combustion sequence initialization
# This sequence lists the requirements for preparing a Combustion combo with each talent choice
# Meteor Combustion
actions.init_combust=start_pyro_chain,if=talent.meteor.enabled&cooldown.meteor.up&(legendary_ring.cooldown.remains<gcd.max|legendary_ring.cooldown.remains>target.time_to_die+15|!legendary_ring.has_cooldown)&((cooldown.combustion.remains<gcd.max*3&buff.pyroblast.up&(buff.heating_up.up^action.fireball.in_flight))|(buff.pyromaniac.up&(cooldown.combustion.remains<ceil(buff.pyromaniac.remains%gcd.max)*gcd.max)))
# Prismatic Crystal Combustion
actions.init_combust+=/start_pyro_chain,if=talent.prismatic_crystal.enabled&cooldown.prismatic_crystal.up&(legendary_ring.cooldown.remains<gcd.max&(!equipped.112320|trinket.proc.crit.react)|legendary_ring.cooldown.remains+20>target.time_to_die|!legendary_ring.has_cooldown)&((cooldown.combustion.remains<gcd.max*2&buff.pyroblast.up&(buff.heating_up.up^action.fireball.in_flight))|(buff.pyromaniac.up&(cooldown.combustion.remains<ceil(buff.pyromaniac.remains%gcd.max)*gcd.max)))
# Unglyphed Combustions between Prismatic Crystals
actions.init_combust+=/start_pyro_chain,if=talent.prismatic_crystal.enabled&!glyph.combustion.enabled&cooldown.prismatic_crystal.remains>20&((cooldown.combustion.remains<gcd.max*2&buff.pyroblast.up&buff.heating_up.up&action.fireball.in_flight)|(buff.pyromaniac.up&(cooldown.combustion.remains<ceil(buff.pyromaniac.remains%gcd.max)*gcd.max)))
# Kindling or Level 90 Combustion
actions.init_combust+=/start_pyro_chain,if=!talent.prismatic_crystal.enabled&!talent.meteor.enabled&((cooldown.combustion.remains<gcd.max*4&buff.pyroblast.up&buff.heating_up.up&action.fireball.in_flight)|(buff.pyromaniac.up&cooldown.combustion.remains<ceil(buff.pyromaniac.remains%gcd.max)*(gcd.max+talent.kindling.enabled)))

# Combustion Sequence
晶体
actions.combust_sequence=prismatic_crystal
actions.combust_sequence+=/blood_fury
actions.combust_sequence+=/berserking
actions.combust_sequence+=/arcane_torrent
actions.combust_sequence+=/use_item,slot=finger2
actions.combust_sequence+=/potion,name=draenic_intellect
流星
actions.combust_sequence+=/meteor,if=active_enemies<=2
炎爆术
actions.combust_sequence+=/pyroblast,if=set_bonus.tier17_4pc&buff.pyromaniac.up
炼狱冲击
actions.combust_sequence+=/inferno_blast,if=set_bonus.tier16_4pc_caster&(buff.pyroblast.up^buff.heating_up.up)
actions.combust_sequence+=/fireball,if=!dot.ignite.ticking&!in_flight
actions.combust_sequence+=/fireball,if=crit_pct_current-1>(1000%13)&prev_gcd.pyroblast&buff.pyroblast.up&buff.heating_up.up&12-pet.prismatic_crystal.remains<action.fireball.execute_time+3*gcd.max&spell_haste<0.7
actions.combust_sequence+=/pyroblast,if=buff.pyroblast.up&dot.ignite.tick_dmg*(6-ceil(dot.ignite.remains-travel_time))<crit_damage*mastery_value
# Meteor Combustions can run out of Pyro procs before impact. Use IB to delay Combustion
actions.combust_sequence+=/inferno_blast,if=talent.meteor.enabled&cooldown.meteor.duration-cooldown.meteor.remains<gcd.max*3
actions.combust_sequence+=/inferno_blast,if=dot.ignite.tick_dmg*(6-dot.ignite.ticks_remain)<crit_damage*mastery_value
actions.combust_sequence+=/combustion

# Active talents usage
actions.active_talents=meteor,if=active_enemies>=3|(glyph.combustion.enabled&(!talent.incanters_flow.enabled|buff.incanters_flow.stack+incanters_flow_dir>=4)&cooldown.meteor.duration-cooldown.combustion.remains<10)
actions.active_talents+=/call_action_list,name=living_bomb,if=talent.living_bomb.enabled&(active_enemies>1|raid_event.adds.in<10)
actions.active_talents+=/cold_snap,if=glyph.dragons_breath.enabled&!talent.prismatic_crystal.enabled&!cooldown.dragons_breath.up
actions.active_talents+=/dragons_breath,if=glyph.dragons_breath.enabled&(!talent.prismatic_crystal.enabled|cooldown.prismatic_crystal.remains>8|legendary_ring.cooldown.remains>10)
actions.active_talents+=/blast_wave,if=(!talent.incanters_flow.enabled|buff.incanters_flow.stack>=4)&(target.time_to_die<10|!talent.prismatic_crystal.enabled|(charges>=1&cooldown.prismatic_crystal.remains>recharge_time))

# Living Bomb application
actions.living_bomb=inferno_blast,cycle_targets=1,if=dot.living_bomb.ticking&active_enemies-active_dot.living_bomb>1
actions.living_bomb+=/living_bomb,if=target!=pet.prismatic_crystal&(((!talent.incanters_flow.enabled|incanters_flow_dir<0|buff.incanters_flow.stack=5)&remains<3.6)|((incanters_flow_dir>0|buff.incanters_flow.stack=1)&remains<gcd.max))&target.time_to_die>remains+12

# AoE sequence
actions.aoe=inferno_blast,cycle_targets=1,if=(dot.combustion.ticking&active_dot.combustion<active_enemies)|(dot.pyroblast.ticking&active_dot.pyroblast<active_enemies)
actions.aoe+=/call_action_list,name=active_talents
actions.aoe+=/pyroblast,if=buff.pyroblast.react|buff.pyromaniac.react
actions.aoe+=/cold_snap,if=!cooldown.dragons_breath.up
actions.aoe+=/dragons_breath
actions.aoe+=/flamestrike,if=mana.pct>10&remains<2.4

# Single target sequence
actions.single_target=inferno_blast,if=dot.combustion.ticking&active_dot.combustion<active_enemies
# Use Pyro procs before they run out
actions.single_target+=/pyroblast,if=buff.pyroblast.up&buff.pyroblast.remains<action.fireball.execute_time
actions.single_target+=/pyroblast,if=set_bonus.tier16_2pc_caster&buff.pyroblast.up&buff.potent_flames.up&buff.potent_flames.remains<gcd.max
actions.single_target+=/pyroblast,if=set_bonus.tier17_4pc&buff.pyromaniac.react
# Pyro camp during regular sequence; Do not use Pyro procs without HU and first using fireball
actions.single_target+=/pyroblast,if=buff.pyroblast.up&buff.heating_up.up&action.fireball.in_flight
# Heating Up conversion to Pyroblast
actions.single_target+=/inferno_blast,if=buff.pyroblast.down&buff.heating_up.up&!(dot.living_bomb.remains>10&active_enemies>1)
actions.single_target+=/call_action_list,name=active_talents
# Adding Heating Up to Pyroblast
actions.single_target+=/inferno_blast,if=buff.pyroblast.up&buff.heating_up.down&!action.fireball.in_flight&!(dot.living_bomb.remains>10&active_enemies>1)
actions.single_target+=/fireball
actions.single_target+=/scorch,moving=1
