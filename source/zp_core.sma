#include "include/zombieplague7.inc"

#include <cvar_util>
#include <flags32>
#include <cs_weap_restrict_api>
#include <cs_maxspeed_api>
#include <cs_player_models_api>
#include <cs_team_changer>
#include "include/md5_gamekey.inc"

#include <fakemeta>
#include <fm_item_stocks>

#include <hamsandwich>
#include <cs_ham_bots_api>

#pragma dynamic 2048

#define flag_get_bool(%1,%2)	!!(flag_get(%1,%2))
#define flag_get(%1,%2)			(%1 &   (1 << (%2 & 31)))
#define flag_set(%1,%2)			(%1 |=  (1 << (%2 & 31)))
#define flag_unset(%1,%2)		(%1 &= ~(1 << (%2 & 31)))

static g_flagConnected, g_flagAlive, g_flagZombie;

static 	g_fwReturn, g_fwThrowError, g_fwPlayerSpawn, g_fwPlayerDeath, g_fwBlockTeamChange,
		g_fwNewRound, g_fwRoundStart, g_fwRoundEnd, g_fwRefresh,
		g_fwUserCurePre, g_fwUserCure, g_fwUserCurePost,
		g_fwUserInfectPre, g_fwUserInfect, g_fwUserInfectPost;

static Array:g_modelList[2];
static Trie:g_modelTrie[2];
static g_modelNum[2];

static g_baseModels[2][32];
static Float:g_fBaseHealth[2];
static Float:g_fBaseGravity[2];
static Float:g_fBaseMaxspeed[2];

static ZP_MODEL:g_iUserModel[MAX_PLAYERS+1] = { ZP_MODEL:NULL, ... };
static Float:g_fUserHealth[MAX_PLAYERS+1] = { 100.0, ... };
static Float:g_fUserMaxspeed[MAX_PLAYERS+1] = { 1.0, ... };
static Float:g_fUserGravity[MAX_PLAYERS+1] = { 1.0, ... };

#define DEFAULT_WEAPONS_BITSUM (1<<CSW_KNIFE)
static g_allowedWeapons;
static const g_szWpnEntKnife[] = "weapon_knife";

static g_iPlayerShuffler[MAX_PLAYERS] = { 1, 2, ... };
static g_iCurShuffle;

static g_pCvar_AllowedWeapons, g_pCvar_ModelMode;

public zp_fw_command_registerCommands() {
	zp_command_register("check", "cmdCheck", _, "Check whether or not you're a zombie");
}

public cmdCheck(id) {
	zp_printColor(id, "You are%s a zombie", _isUserZombie(id) ? "" : " not");
}

public plugin_precache() {
	new szZPHomeDir[64];
	zp_getHomeDir(szZPHomeDir, 63);
	mkdir(szZPHomeDir);
	
	g_fwThrowError = CreateMultiForward("zp_fw_core_errorThrown", ET_CONTINUE, FP_CELL, FP_CELL, FP_STRING);

	new pCvar_ZombieModel = CvarRegister("zp_core_base_zombie_model", "zp_classic");
	get_pcvar_string(pCvar_ZombieModel, g_baseModels[ZP_ZOMBIE], 31);
	zp_precachePlayerModel(g_baseModels[ZP_ZOMBIE]);
	
	new pCvar_HumanModel = CvarRegister("zp_core_base_human_model", "");
	get_pcvar_string(pCvar_HumanModel, g_baseModels[ZP_HUMAN], 31);
	zp_precachePlayerModel(g_baseModels[ZP_HUMAN]);
	
	server_print("================================================================");
	server_print("Launching %s v%s written by %s...", _szPluginName, _szPluginVersion, _szPluginAuthor);
	
	new szGameKey[34], szFilePath[32];
	get_user_ip(0, szGameKey, 33, 1);
	new len = copy(szFilePath, 31, ZP_HOME_DIR);
	len += copy(szFilePath[len], 31, ZP_GAME_KEY_FILE);
	if (gamekey_validateKey(szFilePath, szGameKey)) {
		server_print("Game key validated [%s]", szGameKey);
	} else {
		set_fail_state("Invalid game key");
	}
	
	precacheBaseFiles();

	new fwZombiePlagueInitPre = CreateMultiForward("zp_fw_core_zombiePlagueInitPre", ET_CONTINUE);
	ExecuteForward(fwZombiePlagueInitPre, g_fwReturn);
	DestroyForward(fwZombiePlagueInitPre);
	
	new fwPrecacheModels = CreateMultiForward("zp_fw_core_precacheModels", ET_CONTINUE);
	ExecuteForward(fwPrecacheModels, g_fwReturn);
	DestroyForward(fwPrecacheModels);
	
	new fwZombiePlagueInit = CreateMultiForward("zp_fw_core_zombiePlagueInit", ET_CONTINUE);
	ExecuteForward(fwZombiePlagueInit, g_fwReturn);
	DestroyForward(fwZombiePlagueInit);
	
	server_print("done.");
	server_print("================================================================");
}



precacheBaseFiles() {
	new szTemp[64];
	for (new i; i < 2; i++) {
		if (g_baseModels[i][0] != '^0') {
			if (!zp_precachePlayerModel(g_baseModels[i])) {
				formatex(szTemp, 63, "Error locating essential file to run engine (^"%s^")", g_baseModels[i]);
				set_fail_state(szTemp);
			}
		}
		
		g_modelList[i] = ArrayCreate(32, 8);
		g_modelTrie[i] = TrieCreate();
	}
}

public plugin_init() {
	register_plugin(_szPluginName, _szPluginVersion, _szPluginAuthor);
	CvarRegister("zp7_version", _szPluginVersion, "The current version of Zombie Plague 7 being used", FCVAR_SPONLY|FCVAR_SERVER);
	set_cvar_string("zp7_version", _szPluginVersion);
	
	register_clcmd("chooseteam", "blockTeamChange");
	register_clcmd("jointeam", "blockTeamChange");
	
	register_concmd("core.dump", "dumpPlayerInfo");
	
	register_event("HLTV", "eventRoundStart", "a", "1=0", "2=0");
	register_logevent("logeventRoundStart",2, "1=Round_Start");
	register_logevent("logeventRoundEnd", 2, "1=Round_End");
	
	RegisterHam(Ham_Spawn, 		"player", "ham_PlayerSpawn_Post", 	1);
	RegisterHamBots(Ham_Spawn,	"ham_PlayerSpawn_Post", 			1);
	RegisterHam(Ham_Killed, 	"player", "ham_PlayerKilled", 		0);
	RegisterHamBots(Ham_Killed, "ham_PlayerKilled", 				0);
	
	new pCvar_ZombieHealth = CvarRegister("zp_core_base_zombie_health", "2500", _, _, true, 1.0);
	CvarCache(pCvar_ZombieHealth, CvarType_Float, g_fBaseHealth[ZP_ZOMBIE]);
	
	new pCvar_ZombieGravity = CvarRegister("zp_core_base_zombie_gravity", "0.85");
	CvarCache(pCvar_ZombieGravity, CvarType_Float, g_fBaseGravity[ZP_ZOMBIE]);
	
	new pCvar_ZombieMaxspeed = CvarRegister("zp_core_base_zombie_maxspeed", "1.10");
	CvarCache(pCvar_ZombieMaxspeed, CvarType_Float, g_fBaseMaxspeed[ZP_ZOMBIE]);
	
	new pCvar_HumanHealth = CvarRegister("zp_core_base_human_health", "100", _, _, true, 1.0);
	CvarCache(pCvar_HumanHealth, CvarType_Float, g_fBaseHealth[ZP_HUMAN]);
	
	new pCvar_HumanGravity = CvarRegister("zp_core_base_human_gravity", "1.00");
	CvarCache(pCvar_HumanGravity, CvarType_Float, g_fBaseGravity[ZP_HUMAN]);
	
	new pCvar_HumanMaxspeed = CvarRegister("zp_core_base_human_maxspeed", "1.00");
	CvarCache(pCvar_HumanMaxspeed, CvarType_Float, g_fBaseMaxspeed[ZP_HUMAN]);
	
	new szTemp[33];
	get_flags32(DEFAULT_WEAPONS_BITSUM, szTemp, 32);
	g_pCvar_AllowedWeapons = CvarRegister("zp_core_allowedZombieWeapons", szTemp, "Controls the weapons zombies are allowed to use");
	CvarHookChange(g_pCvar_AllowedWeapons, "hookBitsumChange");
	
	g_pCvar_ModelMode = CvarRegister("zp_core_obeyAssignedModels", "1", _, _, true, 0.0, true, 1.0);
	CvarCache(g_pCvar_ModelMode, CvarType_Int, g_pCvar_ModelMode);

	new temp;
	for (new i; i < MAX_PLAYERS; i++) {
		g_iCurShuffle = random(MAX_PLAYERS);
		temp = g_iPlayerShuffler[i];
		g_iPlayerShuffler[i] = g_iPlayerShuffler[g_iCurShuffle];
		g_iPlayerShuffler[g_iCurShuffle] = temp;
	}
	
	g_iCurShuffle = 0;
	
	g_fwUserInfectPre	= CreateMultiForward("zp_fw_core_infect_pre", ET_CONTINUE, FP_CELL, FP_CELL);
	g_fwUserInfect		= CreateMultiForward("zp_fw_core_infect", ET_IGNORE, FP_CELL, FP_CELL);
	g_fwUserInfectPost	= CreateMultiForward("zp_fw_core_infect_post", ET_IGNORE, FP_CELL, FP_CELL);
	
	g_fwUserCurePre		= CreateMultiForward("zp_fw_core_cure_pre", ET_CONTINUE, FP_CELL, FP_CELL);
	g_fwUserCure		= CreateMultiForward("zp_fw_core_cure", ET_IGNORE, FP_CELL, FP_CELL);
	g_fwUserCurePost	= CreateMultiForward("zp_fw_core_cure_post", ET_IGNORE, FP_CELL, FP_CELL);
	
	g_fwPlayerSpawn		= CreateMultiForward("zp_fw_core_playerSpawn", ET_IGNORE, FP_CELL, FP_CELL);
	g_fwPlayerDeath		= CreateMultiForward("zp_fw_core_playerDeath", ET_IGNORE, FP_CELL, FP_CELL);
	g_fwBlockTeamChange	= CreateMultiForward("zp_fw_core_blockTeamChange", ET_IGNORE, FP_CELL);
	g_fwRefresh			= CreateMultiForward("zp_fw_core_refresh", ET_IGNORE, FP_CELL, FP_CELL);
	
	g_fwNewRound		= CreateMultiForward("zp_fw_core_newRound", ET_IGNORE);
	g_fwRoundStart		= CreateMultiForward("zp_fw_core_roundStart", ET_IGNORE);
	g_fwRoundEnd		= CreateMultiForward("zp_fw_core_roundEnd", ET_IGNORE);
}

public plugin_cfg() {
	new szConfigsDir[64];
	get_configsdir(szConfigsDir, 63);
	server_cmd("exec %s/zombieplague7.cfg", szConfigsDir);
}

public dumpPlayerInfo(id) {
	new size = get_playersnum(), szTemp[32];
	if (size) {
		for (new i = 1; i <= size; i++) {
			szTemp[0] = '^0';
			get_user_name(i, szTemp, 31);
			console_print(id, "%d. %c, %s", i, flag_get(g_flagZombie,i) ? 'Z' : 'H', szTemp);
		}
		
		return PLUGIN_HANDLED;
	}
	
	console_print(id, "No players found");
	return PLUGIN_HANDLED;
}

public plugin_natives() {
	register_library("ZombiePlague7");
	
	register_native("zp_core_throwError",			"_throwError",		0);
	
	register_native("zp_core_isUserConnected",		"_isUserConnected",	1);
	register_native("zp_core_isUserAlive",			"_isUserAlive",		1);
	register_native("zp_core_isUserZombie",			"_isUserZombie",	1);
	
	register_native("zp_core_registerModel",		"_registerModel",	0);
	register_native("zp_core_getModelID",			"_getModelID",		0);
	register_native("zp_core_getModelName",			"_getModelName",	0);
	register_native("zp_core_isValidModel",			"_isValidModel",	1);
	
	register_native("zp_core_refresh",				"_refresh",			1);
	register_native("zp_core_respawn",				"_respawn",			1);
	register_native("zp_core_infect",				"_infect",			1);
	register_native("zp_core_cure",					"_cure",			1);
	register_native("zp_core_infectPercent",		"_infectPercent",	1);
	
	register_native("zp_core_getUserModel",			"_getUserModel",	1);
	register_native("zp_core_setUserModel",			"_setUserModel",	1);
	
	register_native("zp_core_getUserHealth",		"_getUserHealth",	1);
	register_native("zp_core_setUserHealth",		"_setUserHealth",	1);
	
	register_native("zp_core_getUserMaxspeed",		"_getUserMaxspeed",	1);
	register_native("zp_core_setUserMaxspeed",		"_setUserMaxspeed",	1);
	
	register_native("zp_core_getUserGravity",		"_getUserGravity",	1);
	register_native("zp_core_setUserGravity",		"_setUserGravity",	1);
	
	register_native("zp_core_getZombieWeaponBits",	"_getZombieWeaponBits",		1);
	register_native("zp_core_setZombieWeaponBits",	"_setZombieWeaponBits",		1);
	register_native("zp_core_isAllowedZombieWeapon","_isAllowedZombieWeapon",	1);
}

public eventRoundStart() {
	new players[32], num, player;
	get_players(players, num, "e", "TERRORIST"); 
	for (new i; i < num; i++) {
		player = players[i];
		cure(player, 0, false);
	}
	
	ExecuteForward(g_fwNewRound, g_fwReturn);
}

public logeventRoundStart() {
	ExecuteForward(g_fwRoundStart, g_fwReturn);
}

public logeventRoundEnd() {
	ExecuteForward(g_fwRoundEnd, g_fwReturn);
}

public hookBitsumChange(handleCvar, const oldValue[], const newValue[], const cvarName[]) {
	g_allowedWeapons = read_flags32(newValue);
}

public client_putinserver(id) {
	flag_set(g_flagConnected,id);
	flag_unset(g_flagAlive,id);
	flag_unset(g_flagZombie,id);
}

public client_disconnect(id) {
	flag_unset(g_flagConnected,id);
	flag_unset(g_flagAlive,id);
	flag_unset(g_flagZombie,id);
}

public ham_PlayerSpawn_Post(id) {
	if (!is_user_alive(id)) {
		return HAM_IGNORED;
	}
	
	flag_set(g_flagAlive,id);
	ExecuteForward(g_fwPlayerSpawn, g_fwReturn, id, flag_get_bool(g_flagZombie,id));
	refresh(id);
	return HAM_IGNORED;
}

public ham_PlayerKilled(killer, victim, shouldgib) {
	if (is_user_alive(victim) || killer == victim) {
		return HAM_IGNORED;
	}
	
	flag_unset(g_flagAlive,victim);
	ExecuteForward(g_fwPlayerDeath, g_fwReturn, killer, victim);
	return HAM_IGNORED;
}

public blockTeamChange(id) {
	new ZP_TEAM:curTeam = ZP_TEAM:get_user_team(id);
	if (curTeam == ZP_TEAM_SPECTATOR || curTeam == ZP_TEAM_UNASSIGNED) {
		return PLUGIN_CONTINUE;
	}
	
	ExecuteForward(g_fwBlockTeamChange, g_fwReturn, id);
	return PLUGIN_HANDLED;
}

public ZP_THROW:_throwError(plugin, params) {
	if (params != 3) {
		return ZP_UNCAUGHT;
	}
	
	new iErrorID = get_param(1);
	new iPlayerID = get_param(2);
	
	new szErrorMessage[256];
	get_string(3, szErrorMessage, 255);
	
	new szPluginName[32];
	get_plugin(plugin, szPluginName, 31);
	
	ExecuteForward(g_fwThrowError, g_fwReturn, iErrorID, iPlayerID, szErrorMessage);
	if (g_fwReturn == ZP_RESOLVED) {
		return ZP_CAUGHT_HANDLED;
	} else if (iPlayerID) {
		zp_logError(AMX_ERR_NATIVE, "unresolved %-4d %s: (%d) %s", iErrorID, szPluginName, iPlayerID, szErrorMessage);
	} else {
		zp_logError(AMX_ERR_NATIVE, "unresolved %-4d %s: %s", iErrorID, szPluginName, szErrorMessage);
	}
	
	return ZP_CAUGHT_UNHANDLED;
}

public bool:_isUserConnected(id) {
	return flag_get_bool(g_flagConnected,id);
}

public bool:_isUserAlive(id) {
	return flag_get_bool(g_flagAlive,id);
}

public bool:_isUserZombie(id) {
	return flag_get_bool(g_flagZombie,id);
}

public ZP_MODEL:_registerModel(plugin, params) {
	if (params != 2) {
		zp_logError(AMX_ERR_NATIVE, "Invalid params passed: %d - Expected: 2", params);
		return ZP_MODEL:NULL;
	}
	
	new szModel[32];
	get_string(2, szModel, 31);
	if (szModel[0] == '^0') {
		return ZP_MODEL:NULL;
	}
	
	new isZombie = get_param(1);
	if (g_modelTrie[isZombie] == Invalid_Trie || g_modelList[isZombie] == Invalid_Array) {
		zp_logError(AMX_ERR_NATIVE, "Cannot register player model yet (^"%s^")", szModel);
		return ZP_MODEL:NULL;
	}
	
	new szTemp[32], i;
	copy(szTemp, 31, szModel);
	strtolower(szTemp);
	if (TrieGetCell(g_modelTrie[isZombie], szTemp, i)) {
		return ZP_MODEL:i;
	}
	
	if (!zp_precachePlayerModel(szModel)) {
		zp_logError(AMX_ERR_NATIVE, "Could not find model (%s)", szModel);
		return ZP_MODEL:NULL;
	}
	
	ArrayPushString(g_modelList[isZombie], szModel);
	TrieSetCell(g_modelTrie[isZombie], szTemp, g_modelNum[isZombie]);
	g_modelNum[isZombie]++;
	return ZP_MODEL:(g_modelNum[isZombie]-1);
}

public ZP_MODEL:_getModelID(plugin, params) {
	if (params != 1) {
		zp_logError(AMX_ERR_NATIVE, "Invalid params passed: %d - Expected: 1", params);
		return ZP_MODEL:NULL;
	}
	
	new szModel[32], iModel;
	get_string(1, szModel, 31);
	strtolower(szModel);
	for (new i; i < 2; i++) {
		if (g_modelTrie[i] == Invalid_Trie || g_modelList[i] == Invalid_Array) {
			zp_logError(AMX_ERR_NATIVE, "Cannot search for player model (^"%s^")", szModel);
			return ZP_MODEL:NULL;
		}
		
		if (TrieGetCell(g_modelTrie[i], szModel, iModel)) {
			return ZP_MODEL:iModel;
		}
	}

	return ZP_MODEL:NULL;
}

public ZP_RETURN:_getModelName(plugin, params) {
	if (params != 4) {
		zp_logError(AMX_ERR_NATIVE, "Invalid params passed: %d - Expected: 4", params);
		return ZP_ERROR;
	}

	new isZombie = get_param(1);
	new ZP_MODEL:iModel = ZP_MODEL:get_param(2);
	new szModelName[32];
	new iLen = get_param(4);
	if (g_modelList[isZombie] == Invalid_Array) {
		zp_logError(AMX_ERR_NATIVE, "Cannot search for player model (%d)", iModel);
		return ZP_ERROR;
	} else if (iModel == ZP_MODEL:NULL) {
		set_string(3, g_baseModels[isZombie], iLen);
		return ZP_SUCCESS;
	} else if (!_isValidModel(!!isZombie, iModel)) {
		return ZP_ERROR;
	}
	
	ArrayGetString(g_modelList[isZombie], iModel, szModelName, iLen);
	set_string(3, szModelName, iLen);
	return ZP_SUCCESS;
}

public bool:_isValidModel(bool:isZombie, ZP_MODEL:model) {
	return !(_:model < 0 || g_modelNum[isZombie] <= _:model);
}

public bool:_refresh(id) {
	if (!flag_get(g_flagConnected,id)) {
		return false;
	}
	
	refresh(id);
	return true;
}

refresh(id) {
	if (!flag_get(g_flagAlive,id)) {
		return false;
	}
	
	new isZombie = flag_get_bool(g_flagZombie,id);
	ExecuteForward(g_fwRefresh, g_fwReturn, id, isZombie);
	if (isZombie) {
		fm_strip_user_weapons(id);
		fm_give_item(id, g_szWpnEntKnife);
		cs_set_player_weap_restrict(id, true, g_allowedWeapons|(1<<CSW_KNIFE), CSW_KNIFE);
	} else {
		cs_set_player_weap_restrict(id, false);
	}
	
	switch (get_user_team(id)) {
		case ZP_TEAM_ZOMBIE: {
			if (!isZombie) {
				cs_set_team(id, ZP_TEAM_HUMAN);
			}
		}
		case ZP_TEAM_HUMAN: {
			if (isZombie) {
				cs_set_team(id, ZP_TEAM_ZOMBIE);
			}
		}
	}
	
	set_pev(id, pev_health, g_fUserHealth[id]);
	set_pev(id, pev_gravity, g_fUserGravity[id]);
	cs_set_player_maxspeed_auto(id, g_fUserMaxspeed[id]);
	
	static szModel[32];
	if (g_iUserModel[id] == ZP_MODEL:NULL || !g_modelNum[isZombie]) {
		if (g_baseModels[isZombie][0]) {
			cs_set_player_model(id, g_baseModels[isZombie]);
		} else {
			cs_reset_player_model(id);
		}
	} else if (!g_pCvar_ModelMode) {
		ArrayGetString(g_modelList[isZombie], random(g_modelNum[isZombie]), szModel, 31);
		cs_set_player_model(id, szModel);
	} else {
		ArrayGetString(g_modelList[isZombie], g_iUserModel[id], szModel, 31);
		cs_set_player_model(id, szModel);
	}
	
	return true;
}

public ZP_MODEL:_getUserModel(id) {
	assert isValidPlayer(id);
	return g_iUserModel[id];
}

public ZP_RETURN:_setUserModel(id, ZP_MODEL:model) {
	assert isValidPlayer(id);
	if (!_isValidModel(flag_get_bool(g_flagZombie,id), model)) {
		return ZP_ERROR;
	}
	
	g_iUserModel[id] = model;
	return ZP_SUCCESS;
}

public Float:_getUserHealth(id) {
	assert isValidPlayer(id);
	return g_fUserHealth[id];
}

public ZP_RETURN:_setUserHealth(id, health) {
	assert isValidPlayer(id);
	if (health < 0) {
		return ZP_ERROR;
	}
	
	g_fUserHealth[id] = float(health);
	return ZP_SUCCESS;
}

public Float:_getUserMaxspeed(id) {
	assert isValidPlayer(id);
	return g_fUserMaxspeed[id];
}

public ZP_RETURN:_setUserMaxspeed(id, Float:maxspeed) {
	assert isValidPlayer(id);
	if (maxspeed <= 0.0) {
		return ZP_ERROR;
	}
	
	g_fUserMaxspeed[id] = maxspeed;
	return ZP_SUCCESS;
}

public Float:_getUserGravity(id) {
	assert isValidPlayer(id);
	return g_fUserGravity[id];
}

public ZP_RETURN:_setUserGravity(id, Float:gravity) {
	assert isValidPlayer(id);
	if (gravity <= 0.0) {
		return ZP_ERROR;
	}
	
	g_fUserGravity[id] = gravity;
	return ZP_SUCCESS;
}

public ZP_PLAYERSTATE:_infect(id, infector, bool:blockable)  {
	if (!flag_get(g_flagConnected,id)) {
		zp_logError(AMX_ERR_NATIVE, "Invalid Player (%d)", id);
		return ZP_INVALID;
	}
	
	if (flag_get(g_flagZombie,id)) {
		zp_logError(AMX_ERR_NATIVE, "Player already infected (%d)", id);
		refresh(id);
		return ZP_NOCHANGE;
	}
	
	infect(id, infector, blockable);
	return ZP_CHANGED;
}

infect(id, infector, bool:blockable) {
	assert isValidPlayer(id);
	g_fUserHealth[id] = g_fBaseHealth[ZP_ZOMBIE];
	g_fUserMaxspeed[id] = g_fBaseMaxspeed[ZP_ZOMBIE];
	g_fUserGravity[id] = g_fBaseGravity[ZP_ZOMBIE];
	
	ExecuteForward(g_fwUserInfectPre, g_fwReturn, id, infector);
	if (blockable && g_fwReturn == ZP_BLOCK) {
		return;
	}
	
	ExecuteForward(g_fwUserInfect, g_fwReturn, id, infector);
	flag_set(g_flagZombie,id);
	cs_set_team(id, ZP_TEAM_ZOMBIE);
	refresh(id);
	ExecuteForward(g_fwUserInfectPost, g_fwReturn, id, infector);
}

public ZP_PLAYERSTATE:_cure(id, curer, bool:blockable)  {
	if (!flag_get(g_flagConnected,id)) {
		zp_logError(AMX_ERR_NATIVE, "Invalid Player (%d)", id);
		return ZP_INVALID;
	}
	
	if (!flag_get(g_flagZombie,id)) {
		zp_logError(AMX_ERR_NATIVE, "Player already cured (%d)", id);
		refresh(id);
		return ZP_NOCHANGE;
	}
	
	cure(id, curer, blockable);
	return ZP_CHANGED;
}

cure(id, curer, bool:blockable) {
	assert isValidPlayer(id);
	g_fUserHealth[id] = g_fBaseHealth[ZP_HUMAN];
	g_fUserMaxspeed[id] = g_fBaseMaxspeed[ZP_HUMAN];
	g_fUserGravity[id] = g_fBaseGravity[ZP_HUMAN];
	
	ExecuteForward(g_fwUserCurePre, g_fwReturn, id, curer);
	if (blockable && g_fwReturn == ZP_BLOCK) {
		return;
	}
	
	ExecuteForward(g_fwUserCure, g_fwReturn, id, curer);
	flag_unset(g_flagZombie,id);
	cs_set_team(id, ZP_TEAM_HUMAN);
	refresh(id);
	ExecuteForward(g_fwUserCurePost, g_fwReturn, id, curer);
}

public _getZombieWeaponBits() {
	return g_allowedWeapons;
}

public _setZombieWeaponBits(bits) {
	bits |= (1<<(CSW_KNIFE&31));
	g_allowedWeapons = bits;
	return bits;
}

public bool:_isAllowedZombieWeapon(csw) {
	return !!(g_allowedWeapons&(1<<(csw&31)));
}

public bool:_respawn(id) {
	if (!flag_get(g_flagConnected,id)) {
		zp_logError(AMX_ERR_NATIVE, "Invalid Player (%d)", id);
		return false;
	}
	
	ExecuteHamB(Ham_CS_RoundRespawn, id);
	return true;
}

public _infectPercent(Float:percent) {
	new iPlayerNum = get_playersnum();
	if (iPlayerNum <= 1) {
		return 0;
	}
	
	new iInfectedNum = clamp(floatround(iPlayerNum*percent, floatround_ceil), 1, iPlayerNum);
	for (new i; i < iInfectedNum; i++) {
		do {
			g_iCurShuffle++;
			if (g_iCurShuffle == MAX_PLAYERS) {
				g_iCurShuffle = 0;
			}
		} while (!flag_get(g_flagConnected,g_iPlayerShuffler[g_iCurShuffle]));
		
		infect(g_iPlayerShuffler[g_iCurShuffle], 0, false);
	}
	
	return iInfectedNum;
}