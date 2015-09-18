#if defined _zp_modemanager_included
	#endinput
#endif
#define _zp_modemanager_included

#if AMXX_VERSION_NUM >= 175
	#pragma reqlib ZP_ModeManager
	#if !defined AMXMODX_NOAUTOLOAD
		#pragma loadlib ZP_ModeManager
	#endif
#else
	#pragma library ZP_ModeManager
#endif

#include "include/zp7/zp_modemanager_const.inc"

/******************************************************************************************************************************
Forwards
******************************************************************************************************************************/

/**
 * Called when modes can be registered.
 */
forward zp_fw_mode_registerModes();

/**
 * Called when a new round starts.
 * 
 * @note			The mode passed is the mode that will be used.
 * 					To change, use {zp_mode_setNextMode(mode)}
 * @param mode		The game mode going to be used
 */
forward zp_fw_mode_newRound_Pre(ZP_MODE:mode);

/**
 * Called when a new round starts.
 * 
 * @note			The mode passed is the mode that has already been
 * 					loaded by the mod (cannot be changed)
 * @param mode		The game mode this round
 */
forward zp_fw_mode_newRound_Post(ZP_MODE:mode);

/******************************************************************************************************************************
Natives
******************************************************************************************************************************/

/**
 * Registers a game mode into the mode manager.
 * 
 * @param name		The name of this game mode.
 * @param desc		(Optional) A brief description of the game mode
 * @param weight	(Optional) The number of times this mode will be
 * 					entered in the random mode drawing pool.
 * @return			_:NULL for an invalid mode, _:X > 0 for a ZP_MODE
 * 					that was created, or already exists under this name.
 */
native ZP_MODE:zp_mode_registerMode(const name[], const desc[] = "", weight = 1);

/**
 * Retrieves a mode id using a name.
 * 
 * @param name		The name of the mode to look up
 * @return			ZP_MODE:NULL for no mode found (or error), _:X > 0 for
 * 					a valid mode
 */
native ZP_MODE:zp_mode_getModeID(const name[]);

/**
 * Copies a mode name into a specified string with a given length.
 * 
 * @param modes		The mode to retrieve the name for
 * @param str		The string to fill
 * @param len		The length of the string to fill
 * @return			ZP_SUCCESS for success, otherwise ZP_ERROR
 */
native ZP_RETURN:zp_mode_getModeName(mode, str[], len);

/**
 * Checks whether a specified game mode is valid or not.
 * 
 * @param mode		The game mode to check
 * @return			True if valid, otherwise false
 */
native bool:zp_mode_isValidMode(ZP_MODE:mode);

/**
 * Returns the current mode played.
 * 
 * @return			The current mode being played
 */
native ZP_MODE:zp_mode_getCurMode();

/**
 * Returns the next mode.
 * 
 * @return			The current next mode
 */
native ZP_MODE:zp_mode_getNextMode();

/**
 * Sets the next mode to a specified one.
 * 
 * @param modes		The new next mode
 * @return			ZP_SUCCESS implies success, otherwise ZP_ERROR
 */
native ZP_RETURN:zp_mode_setNextMode(ZP_MODE:mode);

/**
 * Retrives the array index for the mode list.
 * 
 * @return			The array index for the mode list
 */
native Array:zp_mode_getModeList();

/**
 * Retrieves the number of modes registered.
 * 
 * @return			The number of modes registered
 */
native zp_mode_getModeNum();