#if defined _zp_core_const_included
	#endinput
#endif
#define _zp_core_const_included

stock const ZP_PLUGIN_NAME[]	= "Zombie Plague 7";
stock const ZP_PLUGIN_VERSION[]	= "0.0.1"

stock const ZP_HOME_DIR[]		= "zp7/";
stock const ZP_GAME_KEY_FILE[]	= "zp_gamekey.txt";

#define MAX_PLAYERS		32
#define null			-1
#define NULL			null

#define ZP_HUMAN		0
#define ZP_ZOMBIE		1

#define isValidPlayer(%1)		(0 < %1 && %1 <= MAX_PLAYERS)