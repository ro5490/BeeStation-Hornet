
/mob/living/simple_animal/revenant/ClickOn(atom/A, params) //revenants can't interact with the world directly.
	if(check_click_intercept(params,A))
		return

	var/list/modifiers = params2list(params)
	if(LAZYACCESS(modifiers, SHIFT_CLICK))
		ShiftClickOn(A)
		return
	if(LAZYACCESS(modifiers, ALT_CLICK))
		AltClickNoInteract(src, A)
		return

	if(LAZYACCESS(modifiers, CTRL_CLICK))
		CtrlClickOn(A)
		return

	if(ishuman(A))
		if(A in drained_mobs)
			to_chat(src, span_revenwarning("[A]'s soul is dead and empty.") )
		else if(in_range(src, A))
			Harvest(A)

	if(isturf(A))
		var/turf/T = A
		if(T == get_turf(src))
			T.show_zmove_radial(src)


// double-click or ctrl-click for two abilities
/mob/living/simple_animal/revenant/CtrlClickOn(atom/A)
	if(incorporeal_move == INCORPOREAL_MOVE_JAUNT)
		check_orbitable(A)
		return
	..() // pull the thing

/mob/living/simple_animal/revenant/DblClickOn(atom/A, params)
	if(get_dist(src, A) < 5) // message spam when you spam phase shift is annoying
		check_orbitable(A)
	..()

// Orbit: literally obrits people like how ghosts do
/mob/living/simple_animal/revenant/check_orbitable(atom/A)
	if(revealed)
		to_chat(src, span_revenwarning("You can't orbit while you're revealed!"))
		return
	if(!Adjacent(A))
		to_chat(src, span_revenwarning("You can only orbit things that are next to you!"))
		return
	if(isobserver(A) || isrevenant(A))
		to_chat(src, span_revenwarning("You can't orbit a ghost!"))
		return
	if(notransform || inhibited || !incorporeal_move_check(A))
		return
	..()

/mob/living/simple_animal/revenant/orbit(atom/target)
	setDir(SOUTH) // reset dir so the right directional sprites show up
	REMOVE_TRAIT(src, TRAIT_MOVE_FLOATING, "ghost")
	return ..()


//Harvest; activated by clicking the target, will try to drain their essence.
/mob/living/simple_animal/revenant/proc/Harvest(mob/living/carbon/human/target)
	if(!castcheck(0))
		return
	if(draining)
		to_chat(src, span_revenwarning("You are already siphoning the essence of a soul!"))
		return
	if(orbiting)
		to_chat(src, span_revenwarning("You can't siphon essence during orbiting!"))
		return
	if(!target.stat && !HAS_TRAIT_FROM(target, TRAIT_INCAPACITATED, STAMINA))
		to_chat(src, span_revennotice("[target.p_their(TRUE)] soul is too strong to harvest."))
		if(prob(10))
			to_chat(target, "You feel as if you are being watched.")
		return
	draining = TRUE
	essence_drained += rand(15, 20)
	to_chat(src, span_revennotice("You search for the soul of [target]."))
	if(do_after(src, rand(10, 20), target, timed_action_flags = IGNORE_HELD_ITEM)) //did they get deleted in that second?
		if(target.ckey)
			to_chat(src, span_revennotice("[target.p_their(TRUE)] soul burns with intelligence."))
			essence_drained += rand(20, 30)
		if(target.stat != DEAD)
			to_chat(src, span_revennotice("[target.p_their(TRUE)] soul blazes with life!"))
			essence_drained += rand(40, 50)
		else
			to_chat(src, span_revennotice("[target.p_their(TRUE)] soul is weak and faltering."))
		if(do_after(src, rand(15, 20), target, timed_action_flags = IGNORE_HELD_ITEM)) //did they get deleted NOW?
			switch(essence_drained)
				if(1 to 30)
					to_chat(src, span_revennotice("[target] will not yield much essence. Still, every bit counts."))
				if(30 to 70)
					to_chat(src, span_revennotice("[target] will yield an average amount of essence."))
				if(70 to 90)
					to_chat(src, span_revenboldnotice("Such a feast! [target] will yield much essence to you."))
				if(90 to INFINITY)
					to_chat(src, span_revenbignotice("Ah, the perfect soul. [target] will yield massive amounts of essence to you."))
			if(do_after(src, rand(15, 25), target, timed_action_flags = IGNORE_HELD_ITEM)) //how about now
				if(!target.stat && !HAS_TRAIT_FROM(target, TRAIT_INCAPACITATED, STAMINA))
					to_chat(src, span_revenwarning("[target.p_theyre(TRUE)] now powerful enough to fight off your draining."))
					to_chat(target, span_boldannounce("You feel something tugging across your body before subsiding."))
					draining = 0
					essence_drained = 0
					return //hey, wait a minute...
				to_chat(src, span_revenminor("You begin siphoning essence from [target]'s soul."))
				if(target.stat != DEAD)
					to_chat(target, span_warning("You feel a horribly unpleasant draining sensation as your grip on life weakens..."))
				if(target.stat == SOFT_CRIT)
					target.Stun(46)
				reveal(46)
				stun(46)
				target.visible_message(span_warning("[target] suddenly rises slightly into the air, [target.p_their()] skin turning an ashy gray."))
				if(target.anti_magic_check(FALSE, TRUE))
					to_chat(src, span_revenminor("Something's wrong! [target] seems to be resisting the siphoning, leaving you vulnerable!"))
					target.visible_message(span_warning("[target] slumps onto the ground."), \
											   span_revenwarning("Violet lights, dancing in your vision, receding--"))
					draining = FALSE
					return
				var/datum/beam/B = Beam(target,icon_state="drain_life")
				if(do_after(src, 46, target, timed_action_flags = IGNORE_HELD_ITEM)) //As one cannot prove the existance of ghosts, ghosts cannot prove the existance of the target they were draining.
					change_essence_amount(essence_drained, FALSE, target)
					if(essence_drained <= 90 && target.stat != DEAD)
						essence_regen_cap += 5
						to_chat(src, span_revenboldnotice("The absorption of [target]'s living soul has increased your maximum essence level. Your new maximum essence is [essence_regen_cap]."))
					if(essence_drained > 90)
						essence_regen_cap += 15
						perfectsouls++
						to_chat(src, span_revenboldnotice("The perfection of [target]'s soul has increased your maximum essence level. Your new maximum essence is [essence_regen_cap]."))
					to_chat(src, span_revennotice("[target]'s soul has been considerably weakened and will yield no more essence for the time being."))
					target.visible_message(span_warning("[target] slumps onto the ground."), \
										   span_revenwarning("Violets lights, dancing in your vision, getting clo--"))
					drained_mobs.Add(target)
					if(target.stat != DEAD)
						target.investigate_log("has died from revenant harvest.", INVESTIGATE_DEATHS)
					target.death(FALSE)
				else
					to_chat(src, span_revenwarning("[target ? "[target] has":"[target.p_theyve(TRUE)]"] been drawn out of your grasp. The link has been broken."))
					if(target) //Wait, target is WHERE NOW?
						target.visible_message(span_warning("[target] slumps onto the ground."), \
											   span_revenwarning("Violets lights, dancing in your vision, receding--"))
				qdel(B)
			else
				to_chat(src, span_revenwarning("You are not close enough to siphon [target ? "[target]'s":"[target.p_their()]"] soul. The link has been broken."))
	draining = FALSE
	essence_drained = 0

// -------------------------------------------
// ------------- action skills ---------------
// -------------------------------------------

//Toggle night vision: lets the revenant toggle its night vision
/obj/effect/proc_holder/spell/targeted/night_vision/revenant
	charge_max = 0
	panel = "Revenant Abilities"
	message = span_revennotice("You toggle your night vision.")
	action_icon = 'icons/hud/actions/actions_revenant.dmi'
	action_icon_state = "r_nightvision"
	action_background_icon_state = "bg_revenant"

// Recall to Station: teleport & recall to the station
/obj/effect/proc_holder/spell/self/rev_teleport
	name = "Recall to Station"
	desc = "Teleport to the station."
	charge_max = 0
	panel = "Revenant Abilities"
	action_icon = 'icons/hud/actions/actions_revenant.dmi'
	action_icon_state = "r_teleport"
	action_background_icon_state = "bg_revenant"
	clothes_req = FALSE

/obj/effect/proc_holder/spell/self/rev_teleport/cast(mob/living/simple_animal/revenant/user = usr)
	if(!isrevenant(user))
		to_chat(user, span_revenwarning("You are not revenant."))
		return
	if(is_station_level(user.z))
		to_chat(user, span_revenwarning("Recalling yourself to the station is only available when you're not in the station."))
		return
	else
		if(user.revealed)
			to_chat(user, span_revenwarning("Recalling yourself to the station is only available when you're invisible."))
			return

		to_chat(user, span_revennotice("You start to concentrate recalling yourself to the station."))
		if(do_after(user, 30) && !user.revealed)
			if(QDELETED(src)) // it's bad when someone spams this...
				return
			var/turf/targetturf = get_random_station_turf()
			if(!do_teleport(user, targetturf, channel = TELEPORT_CHANNEL_CULT, bypass_area_restriction=TRUE))
				to_chat(user,  span_revenwarning("You have failed to recall yourself to the station... You should try again."))
			else
				user.reveal(80)
				user.stun(40)

//Transmit: the revemant's only direct way to communicate. Sends a single message silently to a single mob
/obj/effect/proc_holder/spell/targeted/telepathy/revenant
	name = "Revenant Transmit"
	panel = "Revenant Abilities"
	action_icon = 'icons/hud/actions/actions_revenant.dmi'
	action_icon_state = "r_transmit"
	action_background_icon_state = "bg_revenant"
	notice = "revennotice"
	boldnotice = "revenboldnotice"
	holy_check = TRUE

/obj/effect/proc_holder/spell/targeted/telepathy/revenant/cast(list/targets, mob/living/simple_animal/revenant/user = usr)
	for(var/mob/living/M in targets)
		if(istype(M.get_item_by_slot(ITEM_SLOT_HEAD), /obj/item/clothing/head/costume/foilhat))
			to_chat(user, span_warning("It appears the target's mind is ironclad! No getting a message in there!"))
			return
		if(M.anti_magic_check(magic_check, holy_check)) //hear no evil
			to_chat(user, "<span class='[boldnotice]'>Something is blocking your power into their mind!</span>")
			return


		var/msg = stripped_input(usr, "What do you wish to tell [M]?", null, "")
		if(!msg)
			charge_counter = charge_max
			return
		if(CHAT_FILTER_CHECK(msg))
			to_chat(user, span_warning("Your message contains forbidden words."))
			return
		msg = user.treat_message_min(msg)
		log_directed_talk(user, M, msg, LOG_SAY, "[name]")

		to_chat(user, "<span class='[boldnotice]'>You transmit to [M]:</span> <span class='[notice]'>[msg]</span>")
		to_chat(M, "<span class='[boldnotice]'>You hear something haunting...</span> <span class='[notice]'>[msg]</span>")
		user.create_private_chat_message(message="...[msg]",
									message_language = /datum/language/metalanguage,
									hearers=list(user, M))
		for(var/ded in GLOB.dead_mob_list)
			if(!isobserver(ded))
				continue
			var/follow_rev = FOLLOW_LINK(ded, user)
			var/follow_whispee = FOLLOW_LINK(ded, M)
			to_chat(ded, "[follow_rev] <span class='[boldnotice]'>[user] [name]:</span> <span class='[notice]'>\"[msg]\" to</span> [follow_whispee] [span_name("[M]")]")


/obj/effect/proc_holder/spell/self/revenant_phase_shift
	name = "Phase Shift"
	desc = "Shift in and out of your corporeal form"
	panel = "Revenant Abilities"
	action_icon = 'icons/hud/actions/actions_revenant.dmi'
	action_icon_state = "r_phase"
	action_background_icon_state = "bg_revenant"
	clothes_req = FALSE
	charge_max = 0

/obj/effect/proc_holder/spell/self/revenant_phase_shift/cast(mob/user = usr)
	if(!isrevenant(user))
		return FALSE
	var/mob/living/simple_animal/revenant/revenant = user
	if(!revenant.castcheck(0))
		return FALSE
	// if they're trapped in consecrated tiles, they can get out with this. but they can't hide back on these tiles.
	if(revenant.incorporeal_move != INCORPOREAL_MOVE_JAUNT)
		var/turf/open/floor/stepTurf = get_turf(user)
		if(stepTurf)
			var/obj/effect/decal/cleanable/food/salt/salt = locate() in stepTurf
			if(salt)
				to_chat(user, span_warning("[salt] blocks your way to spirit realm!"))
				// the purpose is just letting not them hide onto salt tiles incorporeally. no need to stun.
				return
			if(stepTurf.flags_1 & NOJAUNT_1)
				to_chat(user, span_warning("Some strange aura blocks your way to spirit realm."))
				return
			if(stepTurf.is_holy())
				to_chat(user, span_warning("Holy energies block your way to spirit realm!"))
				return
	revenant.phase_shift()
	revenant.orbiting?.end_orbit(revenant)

/obj/effect/proc_holder/spell/aoe_turf/revenant
	clothes_req = 0
	action_icon = 'icons/hud/actions/actions_revenant.dmi'
	action_background_icon_state = "bg_revenant"
	panel = "Revenant Abilities (Locked)"
	name = "Report this to a coder"
	var/reveal = 80 //How long it reveals the revenant in deciseconds
	var/stun = 20 //How long it stuns the revenant in deciseconds
	var/locked = TRUE //revenant needs to pay essence to learn their ability
	var/unlock_amount = 100 //How much essence it costs to unlock
	var/cast_amount = 50 //How much essence it costs to use

/obj/effect/proc_holder/spell/aoe_turf/revenant/Initialize(mapload)
	. = ..()
	update_button_info()

/obj/effect/proc_holder/spell/aoe_turf/revenant/proc/update_button_info()
	if(!locked)
		action.name = "[initial(name)][cast_amount ? " ([cast_amount]E to cast)" : ""]"
	else
		action.name = "[initial(name)][unlock_amount ? " ([unlock_amount]SE to learn)" : ""]"
	action.UpdateButtonIcon()

/obj/effect/proc_holder/spell/aoe_turf/revenant/can_cast(mob/living/simple_animal/revenant/user = usr)
	if(charge_counter < charge_max)
		return FALSE
	if(!isrevenant(user)) // If you're not a revenant, it works anyway.
		return TRUE
	if(user.inhibited)
		return FALSE
	if(locked)
		if(user.essence_excess <= unlock_amount)
			return FALSE
	if(user.essence <= cast_amount)
		return FALSE
	return TRUE

/obj/effect/proc_holder/spell/aoe_turf/revenant/proc/attempt_cast(mob/living/simple_animal/revenant/user = usr)
	// If you're not a revenant, it works anyway.
	if(!isrevenant(user))
		if(locked)
			locked = FALSE
			panel = "Revenant Abilities"
			action.name = "[initial(name)]"
		action.UpdateButtonIcon()
		return TRUE

	// actual revenant check
	if(locked)
		if (!user.unlock(unlock_amount))
			charge_counter = charge_max
			return FALSE
		to_chat(user, span_revennotice("You have unlocked [initial(name)]!"))
		panel = "Revenant Abilities"
		locked = FALSE
		charge_counter = charge_max
		update_button_info()
		return FALSE
	if(!user.castcheck(-cast_amount))
		charge_counter = charge_max
		return FALSE
	user.reveal(reveal)
	user.stun(stun)
	if(action)
		action.UpdateButtonIcon()
	return TRUE

//Overload Light: Breaks a light that's online and sends out lightning bolts to all nearby people.
/obj/effect/proc_holder/spell/aoe_turf/revenant/overload
	name = "Overload Lights"
	desc = "Directs a large amount of essence into nearby electrical lights, causing lights to shock those nearby."
	charge_max = 200
	range = 5
	stun = 30
	unlock_amount = 25
	cast_amount = 40
	var/shock_range = 2
	var/shock_damage = 15
	action_icon_state = "overload_lights"

/obj/effect/proc_holder/spell/aoe_turf/revenant/overload/cast(list/targets, mob/living/simple_animal/revenant/user = usr)
	if(attempt_cast(user))
		for(var/turf/T in targets)
			INVOKE_ASYNC(src, PROC_REF(overload), T, user)

/obj/effect/proc_holder/spell/aoe_turf/revenant/overload/proc/overload(turf/T, mob/user)
	for(var/obj/machinery/light/L in T)
		if(!L.on)
			return
		L.visible_message(span_warning("<b>\The [L] suddenly flares brightly and begins to spark!"))
		var/datum/effect_system/spark_spread/s = new /datum/effect_system/spark_spread
		s.set_up(4, 0, L)
		s.start()
		new /obj/effect/temp_visual/revenant(get_turf(L))
		addtimer(CALLBACK(src, PROC_REF(overload_shock), L, user), 20)

/obj/effect/proc_holder/spell/aoe_turf/revenant/overload/proc/overload_shock(obj/machinery/light/L, mob/user)
	if(!L.on) //wait, wait, don't shock me
		return
	flick("[L.base_state]2", L)
	for(var/mob/living/carbon/human/M in hearers(shock_range, L))
		if(M == user)
			continue
		L.Beam(M,icon_state="purple_lightning", time = 5)
		if(!M.anti_magic_check(FALSE, TRUE))
			M.electrocute_act(shock_damage, L, flags = SHOCK_NOGLOVES)
		do_sparks(4, FALSE, M)
		playsound(M, 'sound/machines/defib_zap.ogg', 50, 1, -1)

//Defile: Corrupts nearby stuff, unblesses floor tiles.
/obj/effect/proc_holder/spell/aoe_turf/revenant/defile
	name = "Defile"
	desc = "Twists and corrupts the nearby area as well as dispelling holy auras on floors."
	charge_max = 150
	range = 4
	stun = 20
	reveal = 40
	unlock_amount = 10
	cast_amount = 30
	action_icon_state = "defile"

/obj/effect/proc_holder/spell/aoe_turf/revenant/defile/cast(list/targets, mob/living/simple_animal/revenant/user = usr)
	if(attempt_cast(user))
		for(var/turf/T in targets)
			INVOKE_ASYNC(src, PROC_REF(defile), T)

/obj/effect/proc_holder/spell/aoe_turf/revenant/defile/proc/defile(turf/T)
	for(var/obj/effect/blessing/B in T)
		qdel(B)
		new /obj/effect/temp_visual/revenant(T)

	if(!isplatingturf(T) && !istype(T, /turf/open/floor/engine/cult) && isfloorturf(T) && prob(15))
		var/turf/open/floor/floor = T
		if(floor.overfloor_placed && floor.floor_tile)
			new floor.floor_tile(floor)
		floor.broken = 0
		floor.burnt = 0
		floor.make_plating(1)
	if(T.type == /turf/closed/wall && prob(15))
		new /obj/effect/temp_visual/revenant(T)
		T.AddElement(/datum/element/rust)
	if(T.type == /turf/closed/wall/r_wall && prob(10))
		new /obj/effect/temp_visual/revenant(T)
		T.AddElement(/datum/element/rust)
	for(var/obj/effect/decal/cleanable/food/salt/salt in T)
		new /obj/effect/temp_visual/revenant(T)
		qdel(salt)
	for(var/obj/structure/closet/closet in T.contents)
		closet.open()
	for(var/obj/structure/bodycontainer/corpseholder in T)
		if(corpseholder.connected.loc == corpseholder)
			corpseholder.open()
	for(var/obj/machinery/dna_scannernew/dna in T)
		dna.open_machine()
	for(var/obj/structure/window/window in T)
		window.take_damage(rand(30,80))
		if(window && window.fulltile)
			new /obj/effect/temp_visual/revenant/cracks(window.loc)
	for(var/obj/machinery/light/light in T)
		light.flicker(20) //spooky

//Malfunction: Makes bad stuff happen to robots and machines.
/obj/effect/proc_holder/spell/aoe_turf/revenant/malfunction
	name = "Malfunction"
	desc = "Corrupts and damages nearby machines and mechanical objects."
	charge_max = 200
	range = 4
	cast_amount = 60
	unlock_amount = 125
	action_icon_state = "malfunction"

//A note to future coders: do not replace this with an EMP because it will wreck malf AIs and everyone will hate you.
/obj/effect/proc_holder/spell/aoe_turf/revenant/malfunction/cast(list/targets, mob/living/simple_animal/revenant/user = usr)
	if(attempt_cast(user))
		for(var/turf/T in targets)
			INVOKE_ASYNC(src, PROC_REF(malfunction), T, user)

/obj/effect/proc_holder/spell/aoe_turf/revenant/malfunction/proc/malfunction(turf/T, mob/user)
	for(var/mob/living/simple_animal/bot/bot in T)
		if(!bot.emagged)
			new /obj/effect/temp_visual/revenant(bot.loc)
			bot.locked = FALSE
			bot.open = TRUE
			bot.use_emag()
	for(var/mob/living/carbon/human/human in T)
		if(human == user)
			continue
		if(human.anti_magic_check(FALSE, TRUE))
			continue
		to_chat(human, span_revenwarning("You feel [pick("your sense of direction flicker out", "a stabbing pain in your head", "your mind fill with static")]."))
		new /obj/effect/temp_visual/revenant(human.loc)
		human.emp_act(EMP_HEAVY)
	for(var/obj/thing in T)
		if(istype(thing, /obj/machinery/power/apc) || istype(thing, /obj/machinery/power/smes)) //Doesn't work on SMES and APCs, to prevent kekkery
			continue
		if(prob(20))
			if(prob(50))
				new /obj/effect/temp_visual/revenant(thing.loc)
			thing.use_emag(null)
		else
			if(!istype(thing, /obj/machinery/clonepod)) //I hate everything but mostly the fact there's no better way to do this without just not affecting it at all
				thing.emp_act(EMP_HEAVY)
	for(var/mob/living/silicon/robot/S in T) //Only works on cyborgs, not AI
		playsound(S, 'sound/machines/warning-buzzer.ogg', 50, 1)
		new /obj/effect/temp_visual/revenant(S.loc)
		S.spark_system.start()
		S.emp_act(EMP_HEAVY)

//Blight: Infects nearby humans and in general messes living stuff up.
/obj/effect/proc_holder/spell/aoe_turf/revenant/blight
	name = "Blight"
	desc = "Causes nearby living things to waste away."
	charge_max = 200
	range = 3
	cast_amount = 50
	unlock_amount = 75
	action_icon_state = "blight"

/obj/effect/proc_holder/spell/aoe_turf/revenant/blight/cast(list/targets, mob/living/simple_animal/revenant/user = usr)
	if(attempt_cast(user))
		for(var/turf/T in targets)
			INVOKE_ASYNC(src, PROC_REF(blight), T, user)

/obj/effect/proc_holder/spell/aoe_turf/revenant/blight/proc/blight(turf/T, mob/user)
	for(var/mob/living/mob in T)
		if(mob == user)
			continue
		if(mob.anti_magic_check(FALSE, TRUE))
			continue
		new /obj/effect/temp_visual/revenant(mob.loc)
		if(iscarbon(mob))
			if(ishuman(mob))
				var/mob/living/carbon/human/H = mob
				if(H.dna?.species)
					H.dna.species.handle_hair(H,"#1d2953") //will be reset when blight is cured
				var/blightfound = FALSE
				for(var/datum/disease/revblight/blight in H.diseases)
					blightfound = TRUE
					if(blight.stage < 5)
						blight.stage++
				if(!blightfound)
					H.ForceContractDisease(new /datum/disease/revblight(), FALSE, TRUE)
					to_chat(H, span_revenminor("You feel [pick("suddenly sick", "a surge of nausea", "like your skin is <i>wrong</i>")]."))
			else
				if(mob.reagents)
					mob.reagents.add_reagent(/datum/reagent/toxin/plasma, 5)
		else
			mob.adjustToxLoss(5)
	for(var/obj/structure/spacevine/vine in T) //Fucking with botanists, the ability.
		vine.add_atom_colour("#823abb", TEMPORARY_COLOUR_PRIORITY)
		new /obj/effect/temp_visual/revenant(vine.loc)
		QDEL_IN(vine, 10)
	for(var/obj/structure/glowshroom/shroom in T)
		shroom.add_atom_colour("#823abb", TEMPORARY_COLOUR_PRIORITY)
		new /obj/effect/temp_visual/revenant(shroom.loc)
		QDEL_IN(shroom, 10)
	for(var/obj/machinery/hydroponics/tray in T)
		new /obj/effect/temp_visual/revenant(tray.loc)
		tray.pestlevel = rand(8, 10)
		tray.weedlevel = rand(8, 10)
		tray.toxic = rand(45, 55)

// -------------------------------------------
// ------------- Spook Ability ---------------
// -------------------------------------------

/obj/effect/proc_holder/spell/aoe_turf/revenant/spook
	name = "Spook"
	desc = "Cause freaky, weird, creepy, or spooky stuff to happen in an area around you."
	charge_max = 200
	reveal = 80 //How long it reveals the revenant in deciseconds
	stun = 10
	cast_amount = 30
	unlock_amount = 10
	action_icon_state = "spook"
	var/static/list/effects = list("Flip light switches" = 1, "Burn out lights" = 2, "Create smoke" = 3, "Create ectoplasm" = 4, "Sap APC" = 5, "Open doors, lockers, crates" = 6, "Random" = 7)

/obj/effect/proc_holder/spell/aoe_turf/revenant/spook/cast(list/targets, mob/living/simple_animal/revenant/user = usr)
	if(attempt_cast(user))
		var/effect_text = input(user, "Choose a spooky effect:", "Spook") as null|anything in effects
		if(!effect_text)
			return
		var/effect = effects[effect_text] // Convert text to the assigned numerical value
		INVOKE_ASYNC(src, PROC_REF(do_spook_ability), effect, user)

/obj/effect/proc_holder/spell/aoe_turf/revenant/spook/proc/do_spook_ability(var/effect, mob/user)
	if (effect == 7) // "Random" effect
		effect = rand(1, 6) // Randomly select one of the other effects

	switch(effect)
		if (1) // Flip light switches
			to_chat(user, span_revennotice("You flip some light switches near your location!!"))
			for (var/obj/machinery/light_switch/L in circleview(user, 10))
				L.interact(user)
			return
		if (2) // Burn out lights
			to_chat(user, span_revennotice("You cause a few lights to burn out near your location!."))
			var/c_prob = 100
			for (var/obj/machinery/light/L in circleview(user, 10))
				if (L.status == 2 || L.status == 1)
					continue
				if (prob(c_prob))
					L.break_light_tube()
					c_prob *= 0.5
			return
		if (3) // Create smoke
			to_chat(user, span_revennotice("Smoke rises in your location."))
			var/turf/T = get_turf(user)
			if (T && isturf(T))
				var/datum/effect_system/smoke_spread/bad/smoke = new
				smoke.set_up(15, T)
				smoke.start()
			return
		if (4) // Create ectoplasm
			to_chat(user, span_revennotice("Matter from your realm appears near your location!"))
			var/c_prob = 100
			for (var/turf/T in circleview(user, 7))
				if (prob(c_prob))
					new /obj/item/food/ectoplasmicgoo(T)
					c_prob *= 0.70
			return
		if (5) // Sap APC
			var/sapped_amt = 1250
			var/obj/machinery/power/apc/apc = locate() in get_area(user)
			if (!apc)
				to_chat(user, span_revenwarning("Power sap failed: local APC not found."))
				return
			var/obj/item/stock_parts/cell/cell = apc.cell
			if (cell)
				to_chat(user, span_revennotice("You sap the power of the chamber's power source."))
				apc.visible_message(span_warning("<b>\The [apc] suddenly flares brightly and begins to spark!"))
				var/datum/effect_system/spark_spread/s = new /datum/effect_system/spark_spread
				s.set_up(4, 0, apc)
				s.start()
				new /obj/effect/temp_visual/revenant(get_turf(apc))
				cell.use(sapped_amt)
				apc.Beam(user,icon_state="purple_lightning", time = 3)
				return
			else
				to_chat(user, span_revenwarning("Power sap failed: local APC has no power cell."))
				return
		if (6) // Open doors, lockers, crates
			to_chat(user, span_revennotice("Crates, lockers, and doors mysteriously open and close in your area!"))
			var/c_prob = 100
			for(var/obj/machinery/door/G in circleview(user, 7))
				if (prob(c_prob))
					c_prob *= 0.4
					addtimer(CALLBACK(G, G.density ? /obj/machinery/door.proc/open : /obj/machinery/door.proc/close), 1)
			c_prob = 100
			for(var/obj/structure/closet/F in circleview(user, 7))
				if (prob(c_prob))
					c_prob *= 0.4
					addtimer(CALLBACK(F, F.opened ? /obj/structure/closet.proc/close : /obj/structure/closet.proc/open), 1)
			return



// -------------------------------------------
// ------------- BloodWriting Ability --------
// -------------------------------------------

#define RANDOM_GRAFFITI "Random Graffiti"
#define RANDOM_LETTER "Random Letter"
#define RANDOM_PUNCTUATION "Random Punctuation"
#define RANDOM_NUMBER "Random Number"
#define RANDOM_SYMBOL "Random Symbol"
#define RANDOM_DRAWING "Random Drawing"
#define RANDOM_ORIENTED "Random Oriented"
#define RANDOM_RUNE "Random Rune"
#define RANDOM_ANY "Random Anything"

#define PAINT_NORMAL	1
#define PAINT_LARGE_HORIZONTAL	2
#define PAINT_LARGE_HORIZONTAL_ICON	'icons/effects/96x32.dmi'

/obj/effect/proc_holder/spell/aoe_turf/revenant/blood_writing
	name = "Blood Writing"
	desc = "Write a spooky character, symbol, or drawing on the ground using blood."
	charge_max = 50
	range = 1
	cast_amount = 5
	unlock_amount = 10
	action_icon = 'icons/hud/actions/actions_revenant.dmi'
	action_icon_state = "blood_writing"
	action_background_icon_state = "bg_revenant"
	var/in_use = FALSE
	var/datum/revenant_writing/writingdatum

/datum/revenant_writing
	var/name = "revenant writing"
	var/paint_color = "#9b0000" // Blood color
	var/drawtype
	var/text_buffer = ""
	var/static/list/graffiti = list("amyjon","face","matt","revolution","engie","guy","end","dwarf","uboa","body","cyka","star","poseur tag","prolizard","antilizard")
	var/static/list/symbols = list("danger","firedanger","electricdanger","biohazard","radiation","safe","evac","space","med","trade","shop","food","peace","like","skull","nay","heart","credit")
	var/static/list/drawings = list("smallbrush","brush","largebrush","splatter","snake","stickman","carp","ghost","clown","taser","disk","fireaxe","toolbox","corgi","cat","toilet","blueprint","beepsky","scroll","bottle","shotgun")
	var/static/list/oriented = list("arrow","line","thinline","shortline","body","chevron","footprint","clawprint","pawprint") // These turn to face the same way as the drawer
	var/static/list/runes = list("rune1","rune2","rune3","rune4","rune5","rune6")
	var/static/list/randoms = list(RANDOM_ANY, RANDOM_RUNE, RANDOM_ORIENTED,
		RANDOM_NUMBER, RANDOM_GRAFFITI, RANDOM_LETTER, RANDOM_SYMBOL, RANDOM_PUNCTUATION, RANDOM_DRAWING)
	var/static/list/graffiti_large_h = list("secborg", "paint")
	var/static/list/all_drawables = graffiti + symbols + drawings + oriented + runes + graffiti_large_h
	var/paint_mode = PAINT_NORMAL
	var/mob/living/simple_animal/revenant/revenant

/datum/revenant_writing/ui_host(mob/user)
	return revenant

/obj/effect/proc_holder/spell/aoe_turf/revenant/blood_writing/cast(list/targets, mob/living/simple_animal/revenant/user = usr)
	if(attempt_cast(user))
		to_chat(user, span_notice("Opening Blood Writing UI...")) // Debug message, Remove before final merge
		writingdatum = new /datum/revenant_writing(user)
		writingdatum.start(user)// Open the UI when the spell is cast

/datum/revenant_writing/proc/start(mob/user)
	ui_interact(user)

/datum/revenant_writing/proc/isValidSurface(surface)
	return istype(surface, /turf/open/floor)

/datum/revenant_writing/ui_state(mob/user)
	return GLOB.self_state

/datum/revenant_writing/ui_interact(mob/user, datum/tgui/ui)
	to_chat(user, span_notice("Attempting to open UI...")) // Debug message, Remove before final merge
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		to_chat(user, span_notice("Creating new UI...")) // Debug message, Remove before final merge
		ui = new(user, src, "BloodWriting")
		ui.open()
	else
		to_chat(user, span_notice("Updating existing UI...")) // Debug message, Remove before final merge
	return TRUE

/datum/revenant_writing/proc/staticDrawables()
	. = list()

	var/list/g_items = list()
	. += list(list("name" = "Graffiti", "items" = g_items))
	for(var/g in graffiti)
		g_items += list(list("item" = g))

	var/list/glh_items = list()
	. += list(list("name" = "Graffiti Large Horizontal", "items" = glh_items))
	for(var/glh in graffiti_large_h)
		glh_items += list(list("item" = glh))

	var/list/S_items = list()
	. += list(list("name" = "Symbols", "items" = S_items))
	for(var/S in symbols)
		S_items += list(list("item" = S))

	var/list/D_items = list()
	. += list(list("name" = "Drawings", "items" = D_items))
	for(var/D in drawings)
		D_items += list(list("item" = D))

	var/list/O_items = list()
	. += list(list(name = "Oriented", "items" = O_items))
	for(var/O in oriented)
		O_items += list(list("item" = O))

	var/list/R_items = list()
	. += list(list(name = "Runes", "items" = R_items))
	for(var/R in runes)
		R_items += list(list("item" = R))

	var/list/rand_items = list()
	. += list(list(name = "Random", "items" = rand_items))
	for(var/i in randoms)
		rand_items += list(list("item" = i))

/datum/revenant_writing/ui_data(mob/user)
	var/static/list/crayon_drawables

	if (!crayon_drawables)
		crayon_drawables = staticDrawables()

	. = list()
	.["drawables"] = crayon_drawables
	.["selected_stencil"] = drawtype
	.["text_buffer"] = text_buffer
	return .

/datum/revenant_writing/ui_act(action, list/params)
	if(..())
		return
	switch(action)
		if("select_stencil")
			var/stencil = params["item"]
			if(stencil in (all_drawables + randoms))
				drawtype = stencil
				. = TRUE
				text_buffer = ""
			if(stencil in graffiti_large_h)
				paint_mode = PAINT_LARGE_HORIZONTAL
				text_buffer = ""
			else
				paint_mode = PAINT_NORMAL
		if("enter_text")
			var/txt = stripped_input(usr,"Choose what to write.",
				"Scribbles",default = text_buffer)
			text_buffer = crayon_text_strip(txt)
			. = TRUE
			paint_mode = PAINT_NORMAL
			drawtype = "a"
	return TRUE

/datum/revenant_writing/proc/crayon_text_strip(text)
	var/static/regex/crayon_r = new /regex(@"[^\w!?,.=%#&+\/\-]")
	return replacetext(LOWER_TEXT(text), crayon_r, "")

/datum/revenant_writing/proc/drawblood(atom/target, mob/user, params)
	var/static/list/punctuation = list("!","?",".",",","/","+","-","=","%","#","&")

	if(istype(target, /obj/effect/decal))
		target = target.loc

	if(!isValidSurface(target))
		return

	var/drawing = drawtype
	switch(drawtype)
		if(RANDOM_LETTER)
			drawing = ascii2text(rand(97, 122)) // a-z
		if(RANDOM_PUNCTUATION)
			drawing = pick(punctuation)
		if(RANDOM_SYMBOL)
			drawing = pick(symbols)
		if(RANDOM_DRAWING)
			drawing = pick(drawings)
		if(RANDOM_GRAFFITI)
			drawing = pick(graffiti)
		if(RANDOM_RUNE)
			drawing = pick(runes)
		if(RANDOM_ORIENTED)
			drawing = pick(oriented)
		if(RANDOM_NUMBER)
			drawing = ascii2text(rand(48, 57)) // 0-9
		if(RANDOM_ANY)
			drawing = pick(all_drawables)

	var/temp = "rune"
	if(is_alpha(drawing))
		temp = "letter"
	else if(is_digit(drawing))
		temp = "number"
	else if(drawing in punctuation)
		temp = "punctuation mark"
	else if(drawing in symbols)
		temp = "symbol"
	else if(drawing in drawings)
		temp = "drawing"
	else if(drawing in (graffiti | oriented))
		temp = "graffiti"

	var/graf_rot
	if(drawing in oriented)
		switch(user.dir)
			if(EAST)
				graf_rot = 90
			if(SOUTH)
				graf_rot = 180
			if(WEST)
				graf_rot = 270
			else
				graf_rot = 0

	var/list/modifiers = params2list(params)
	var/clickx
	var/clicky

	if(LAZYACCESS(modifiers, ICON_X) && LAZYACCESS(modifiers, ICON_Y))
		clickx = clamp(text2num(LAZYACCESS(modifiers, ICON_X)) - 16, -(world.icon_size/2), world.icon_size/2)
		clicky = clamp(text2num(LAZYACCESS(modifiers, ICON_Y)) - 16, -(world.icon_size/2), world.icon_size/2)

	if(length(text_buffer))
		drawing = text_buffer[1]

	var/list/turf/affected_turfs = list()

	switch(paint_mode)
		if(PAINT_NORMAL)
			var/obj/effect/decal/cleanable/blood/writing/W = new(target, paint_color, drawing, temp, graf_rot)
			W.add_hiddenprint(user)
			W.pixel_x = clickx
			W.pixel_y = clicky
			affected_turfs += target
		if(PAINT_LARGE_HORIZONTAL)
			var/turf/left = locate(target.x-1,target.y,target.z)
			var/turf/right = locate(target.x+1,target.y,target.z)
			if(isValidSurface(left) && isValidSurface(right))
				var/obj/effect/decal/cleanable/blood/writing/W = new(left, paint_color, drawing, temp, graf_rot, PAINT_LARGE_HORIZONTAL_ICON)
				W.add_hiddenprint(user)
				affected_turfs += left
				affected_turfs += right
				affected_turfs += target
			else
				to_chat(user, span_warning("There isn't enough space to paint!"))
				return

	if(length(text_buffer) > 1)
		text_buffer = copytext(text_buffer, length(text_buffer[1]) + 1)
		SStgui.update_uis(src)

#undef RANDOM_GRAFFITI
#undef RANDOM_LETTER
#undef RANDOM_PUNCTUATION
#undef RANDOM_SYMBOL
#undef RANDOM_DRAWING
#undef RANDOM_NUMBER
#undef RANDOM_ORIENTED
#undef RANDOM_RUNE
#undef RANDOM_ANY

#undef PAINT_NORMAL
#undef PAINT_LARGE_HORIZONTAL
#undef PAINT_LARGE_HORIZONTAL_ICON
