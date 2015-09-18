#if defined _zp_core_included
	#endinput
#endif
#define _zp_core_included

#include <amxmisc>
#include "include/zp7/zp_core_const.inc"

/******************************************************************************************************************************
Stocks
******************************************************************************************************************************/
stock zp_getHomeDir(str[], len) {
	new curLen = get_configsdir(str, len);
	str[curLen++] = '/';
	return curLen+copy(str[curLen], len, ZP_HOME_DIR);
}

/******************************************************************************************************************************
Forwards
******************************************************************************************************************************/

/**
 * Called before all other plugins are initialized. Initialize
 * all potent data structures here.
 */
forward zp_fw_core_zombiePlagueInitPre();

/**
 * Called when the mod initializes and when you should
 *  load anything pre-registers. Set up data structs here.
 */
forward zp_fw_core_zombiePlagueInit();

/**
 * Called when models are available to be precached.
 * 
 * @note			Cannot be blocked.
 */
forward zp_fw_core_precacheModels();

/**
 * Called when an error is thrown.
 * 
 * @param errorid			The error id (for easier identification)
 * @param id				(Optional) Player index associated with the error.
 * @param szErrorMessage	The error message (detailed)
 * @return					Should return either ZP_RESOLVED or ZP_UNRESOLVED for whether
 * 							or not the error was caught and handled.
 */
forward ZP_THROW:zp_fw_core_errorThrown(errorid, id, const szErrorMessage[]);

/**
 * Called when a user is infected, before actual infection.
 * 
 * @param id		Player index being infected
 * @param attacker	The user (if any) infecting the id
 * @return			Should return ZP_BLOCK to prevent infection, otherwise ZP_CONTINUE
 */
forward zp_fw_core_infect_pre(id, attacker);

/**
 * Called when a user is infecting, before.
 * 
 * @note 			Cannot be stopped.
 * @param id		Player index being infected
 * @param attacker	The user (if any) infecting the id
 */
forward zp_fw_core_infect(id, attacker);

/**
 * Called after a user has been infected.
 * 
 * @note 			Cannot be stopped.
 * @param id		Player index infected
 * @param attacker	The user (if any) who infected the id
 */
forward zp_fw_core_infect_post(id, attacker);

/**
 * Called when a user is cured, before actual cure.
 * 
 * @param id		Player index being cured
 * @param curer		The user (if any) curing the id
 * @return			Should return ZP_BLOCK to prevent cure, otherwise ZP_CONTINUE
 */
forward zp_fw_core_cure_pre(id, curer);

/**
 * Called when a user is curing, before.
 * 
 * @note 			Cannot be stopped.
 * @param id		Player index being cured
 * @param curer		The user (if any) curing the id
 */
forward zp_fw_core_cure(id, curer);

/**
 * Called after a user has been cured.
 * 
 * @note 			Cannot be stopped.
 * @param id		Player index cured
 * @param curer		The user (if any) who cured the id
 */
forward zp_fw_core_cure_post(id, curer);

/**
 * Called when a player is spawned.
 * 
 * @param id		Player index spawned
 * @param isZombie	True if the player is a zombie, otherwise false
 */
forward zp_fw_core_playerSpawn(id, bool:isZombie);

/**
 * Called when a player is killed.
 * 
 * @param killer	Player index of killer
 * @param victim	Player index of victim
 */
forward zp_fw_core_playerDeath(killer, victim);

/**
 * Called when a team change is blocked.
 * 
 * @param id		Player index whos team change was blocked
 */
forward zp_fw_core_blockTeamChange(id);

/**
 * Called when a player is going to be refreshed. This is generic
 * for a zombie or human and created primarily for class usage.
 * 
 * @param id		Player index refreshing
 * @param isZombie	True if the player is a zombie, otherwise false
 */
forward zp_fw_core_refresh(id, bool:isZombie);

/**
 * Called when the round has started, after zombies have been cured.
 */
forward zp_fw_core_newRound();

/**
 * Called on logevent round start (after freezetime)
 */
forward zp_fw_core_roundStart();

/**
 * Called on logevent round end
 */
forward zp_fw_core_roundEnd();

/******************************************************************************************************************************
Natives
******************************************************************************************************************************/

/**
 * Retrives whether or not a specified player is connected.
 * 
 * @param id		Player index
 * @return			True if the player is connected, otherwise false.
 */
native bool:zp_core_isUserConnected(id);

/**
 * Retrives whether or not a specified player is alive.
 * 
 * @param id		Player index
 * @return			True if the player is alive, otherwise false.
 */
native bool:zp_core_isUserAlive(id);

/**
 * Retrives whether or not a specified player is a zombie.
 * 
 * @param id		Player index
 * @return			True if the player is a zombie, otherwise false.
 */
native bool:zp_core_isUserZombie(id);

/**
 * Throws an error to all plugins requesting a resolution.
 * 
 * @param errorid			The error id for easy identification
 * @param id				(Optional) Player index associated with error
 * @param szErrorMessage	(Optional) The error message (detailed)
 * @return					ZP_CONTINUE for unhandled, ZP_HANDLED for handled.
 */
native ZP_RETURN:zp_core_throwError(const errorid, const id = 0, const szErrorMessage[] = "");

/**
 * Registers a model into the engine.
 * 
 * @param isZombieModel		True if this is a zombie model, otherwise false
 * @param model				The name of the model to register (filename without .mdl extension)
 * @return					_:NULL for a bad register, _:X > NULL for valid model
 */
native ZP_MODEL:zp_core_registerModel(bool:isZombieModel, const model[]);

/**
 * Retrieves a model attached with a given name (if it exists).
 * 
 * @param model				The model to look up
 * @return					_:NULL for an invalid model, _:X > 0 for valid model
 */
native ZP_MODEL:zp_core_getModelID(const model[]);

/**
 * Gets a model name for a given model id and places the information
 * into a specified string.
 * 
 * @param isZombieModel		True if this model is a zombie one, otherwise false
 * @param modelid			The model to look up
 * @param str				The string to put the name into
 * @param len				The length of the string to copy
 * @return					ZP_SUCCESS for success, ZP_ERROR for failure
 */
native ZP_RETURN:zp_core_getModelName(bool:isZombieModel, modelid, str[], len);

/**
 * Retrieves whether or not a given model is valid or not.
 * 
 * @param isZombieModel		True if this model is a zombie one, otherwise false
 * @param modelid			The model to check
 * @return					True if this is a valid mode, otherwise false
 */
native bool:zp_core_isValidModel(bool:isZombieModel, modelid);

/**
 * Refreshes and reloads all of a users information (model, health, maxspeed, and gravity)
 * 
 * @param id		Player index to refresh
 * @return			True if the player is refreshed, otherwise false
 */
native bool:zp_core_refresh(id);

/**
 * Respawns a user (alive or dead)
 * 
 * @param id		Player index to respawn
 * @return			True if successful, otherwise false
 */
native bool:zp_core_respawn(id);

/**
 * Infects a player and turns him into a zombie.
 * 
 * @param id		Player index to infect
 * @param infector	(Optional) The player infecting this person
 * @param blockable	(Optional) True if this event can be blocked via other
 * 					plugins, otherwise false
 * @return			ZP_NOCHANGE	- There was no change made
 * 					ZP_CHANGED	- The the player state has changed
 * 					ZP_INVALID	- This player is dead or state cannot be changed
 */
native ZP_PLAYERSTATE:zp_core_infect(id, infector = 0, bool:blockable = true);

/**
 * Cures a player and turns him into a human.
 * 
 * @param id		Player index to cure
 * @param infector	(Optional) The player curing this person
 * @param blockable	(Optional) True if this event can be blocked via other
 * 					plugins, otherwise false
 * @return			ZP_NOCHANGE	- There was no change made
 * 					ZP_CHANGED	- The the player state has changed
 * 					ZP_INVALID	- This player is dead or state cannot be changed
 */
native ZP_PLAYERSTATE:zp_core_cure(id, curer = 0, bool:blockable = true);

/**
 * Infects a certain percentage of all users (already infected players included
 * within the pool).
 * 
 * @note			This was intended for use at the beginning of the round
 * 					when all players are humans, using this at any other time
 * 					can potentially infect ALL players.
 * @param percent	The percentage (0.0 - 1.0) of players to effect. (30% = 0.30)
 * @return			The number of players infected
 */
native zp_core_infectPercent(Float:percent);

/**
 * Gets a users model.
 * 
 * @note			Dependant on whether they are a zombie as well
 * @param id		Player index to check
 * @return			The model attached to this player
 */
native ZP_MODEL:zp_core_getUserModel(id);

/**
 * Sets a new model on a player to be loaded at their next refresh event.
 * 
 * @note 			Make sure this model is correct for their team
 * @param id		Player index to set the model for
 * @param model		The model index to apply
 * @return			ZP_SUCCESS for success, ZP_ERROR for failure
 */
native ZP_RETURN:zp_core_setUserModel(id, ZP_MODEL:model);

/**
 * Gets a users health.
 * 
 * @param id		Player index to check
 * @return			The users full health
 */
native Float:zp_core_getUserHealth(id);

/**
 * Sets a players health to be loaded at their next refresh event.
 * 
 * @param id		Player index to set health for
 * @param health	The amount of health to set
 * @return			ZP_SUCCESS for success, ZP_ERROR for failure
 */
native ZP_RETURN:zp_core_setUserHealth(id, health);

/**
 * Gets a users maxspeed.
 * 
 * @param id		Player index to check
 * @return			The users maxspeed
 */
native Float:zp_core_getUserMaxspeed(id);

/**
 * Sets a players maxspeed to be loaded at their next refresh event.
 * 
 * @param id		Player index to set maxspeed for
 * @param maxspeed	The amount of maxspeed to set
 * @return			ZP_SUCCESS for success, ZP_ERROR for failure
 */
native ZP_RETURN:zp_core_setUserMaxspeed(id, Float:maxspeed);

/**
 * Gets a users gravity.
 * 
 * @param id		Player index to check
 * @return			The users gravity
 */
native Float:zp_core_getUserGravity(id);

/**
 * Sets a players gravity to be loaded at their next refresh event.
 * 
 * @param id		Player index to set gravity for
 * @param gravity	The amount of gravity to set
 * @return			ZP_SUCCESS for success, ZP_ERROR for failure
 */
native ZP_RETURN:zp_core_setUserGravity(id, Float:gravity);

/**
 * Retrieves a bitsum of available weapons that the zombies can use.
 * 
 * @return			A bitsum of all weapons available for use on the zombie team.
 */
native zp_core_getZombieWeaponBits();

/**
 * Sets the bitsum of zombie weapons to a new value.
 * 
 * @note			The knife is always included
 * @param bitsum	The new bitsum to use
 */
native zp_core_setZombieWeaponBits(bits);

/**
 * Retrieve whether or not a weapon is allowed for use by zombies.
 * 
 * @param csw		The weapon CSW_* to check
 * @return			True if it is allowed, otherwise false
 */
native bool:zp_core_isAllowedZombieWeapon(csw);