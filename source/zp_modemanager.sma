#include "include/zombieplague7.inc"
#include "include/zp7/zp_modemanager_const.inc"

#include <cvar_util>

#pragma dynamic 2048

#define VERSION "0.0.1"

static g_pCvar_ForceNonconsecutive;

static	g_fwReturn, g_fwNewRoundPre, g_fwNewRoundPost;

static Array:g_modePool;
static Array:g_modeList;
static Trie:g_modeTrie;
static g_modeNum;

static ZP_MODE:g_curMode = ZP_MODE:NULL;
static ZP_MODE:g_nextMode = ZP_MODE:NULL;
static g_tempMode[mode_t];

public zp_fw_core_zombiePlagueInit() {
	g_modePool = ArrayCreate(1, 4);	
	g_modeList = ArrayCreate(mode_t, 4);
	g_modeTrie = TrieCreate();
	
	server_print("ZP Mode Module loaded");
	
	new fwRegisterModes = CreateMultiForward("zp_fw_mode_registerModes", ET_CONTINUE);
	ExecuteForward(fwRegisterModes, g_fwReturn);
	DestroyForward(fwRegisterModes);
}

public zp_fw_command_registerCommands() {
	zp_command_register("mode",			"cmdCheckMode", _, "Checks what the current mode is");
	zp_command_register("currentmode",	"cmdCheckMode");
}

public cmdCheckMode(id) {
	if (!_isValidMode(g_curMode)) {
		zp_printColor(id, "Current Mode: ^4None");
	} else {
		ArrayGetArray(g_modeList, _:g_curMode, g_tempMode);
		zp_printColor(id, "Current Mode: ^4%s", g_tempMode[mode_szName]);
	}
}

public plugin_init() {
	register_plugin("[ZP7] Mode Manager", VERSION, "Tirant");
	
	register_concmd("mode.dump", "dumpModeInfo");
	
	g_pCvar_ForceNonconsecutive = CvarRegister("zp_mode_forceNonconsecutive", "1", _, _, true, 0.0, true, 1.0);
	CvarCache(g_pCvar_ForceNonconsecutive, CvarType_Int, g_pCvar_ForceNonconsecutive);
	
	g_fwNewRoundPre		= CreateMultiForward("zp_fw_mode_newRound_Pre", ET_CONTINUE, FP_CELL);
	g_fwNewRoundPost	= CreateMultiForward("zp_fw_mode_newRound_Post", ET_CONTINUE, FP_CELL);
}

public plugin_natives() {
	register_library("ZP_ModeManager");
	
	register_native("zp_mode_registerMode",			"_registerMode",		0);
	register_native("zp_mode_getModeID",			"_getModeID",			0);
	register_native("zp_mode_getModeName",			"_getModeName",			0);
	register_native("zp_mode_isValidMode",			"_isValidMode",			1);
	
	register_native("zp_mode_getCurMode",			"_getCurMode",			1);
	register_native("zp_mode_getNextMode",			"_getNextMode",			1);
	register_native("zp_mode_setNextMode",			"_setNextMode",			1);
	
	register_native("zp_mode_getModeList",			"_getModeList",			1);
	register_native("zp_mode_getModeNum",			"_getModeNum",			1);
}

public dumpModeInfo(id) {
	if (g_modeNum) {
		if (g_curMode == ZP_MODE:NULL) {
			console_print(id, "Current Mode: NULL");
		} else {
			ArrayGetArray(g_modeList, _:g_curMode, g_tempMode);
			console_print(id, "Current Mode: %s", g_tempMode[mode_szName]);
		}
		
		for (new i; i < g_modeNum; i++) {
			ArrayGetArray(g_modeList, i, g_tempMode);
			console_print(id, "%d. %s [%d]", i+1, g_tempMode[mode_szName], g_tempMode[mode_iWeight]);
		}
		
		return PLUGIN_HANDLED;
	}
	
	console_print(id, "No modes found");
	return PLUGIN_HANDLED;
}

public zp_fw_core_newRound() {
	ExecuteForward(g_fwNewRoundPre, g_fwReturn, g_nextMode);
	g_curMode = g_nextMode;
	
	ArrayGetArray(g_modeList, _:g_curMode, g_tempMode);
	zp_log("New game mode loaded: %s", g_tempMode[mode_szName]);
	
	ExecuteForward(g_fwNewRoundPost, g_fwReturn, g_curMode);
}

public ZP_MODE:_registerMode(plugin, params) {
	if (params != 3) {
		zp_logError(AMX_ERR_NATIVE, "Invalid params passed: %d - Expected: 3", params);
		return ZP_MODE:NULL;
	}
	
	get_string(1, g_tempMode[mode_szName], mode_szName_length);
	if (g_modeTrie == Invalid_Trie || g_modeList == Invalid_Array) {
		zp_logError(AMX_ERR_NATIVE, "Cannot register player model yet (^"%s^")", g_tempMode[mode_szName]);
		return ZP_MODE:NULL;
	}
	
	new szTemp[mode_szName_length+1], i;
	copy(szTemp, mode_szName_length, g_tempMode[mode_szName]);
	strtolower(szTemp);
	if (TrieGetCell(g_modeTrie, szTemp, i)) {
		return ZP_MODE:i;
	}
	
	get_string(2, g_tempMode[mode_szDesc], mode_szDesc_length);
	g_tempMode[mode_iWeight] = get_param(3);
	for (new i; i < g_tempMode[mode_iWeight]; i++) {
		ArrayPushCell(g_modePool, ZP_MODE:g_modeNum);
	}
	
	ArrayPushArray(g_modeList, g_tempMode);
	TrieSetCell(g_modeTrie, szTemp, g_modeNum);
	g_modeNum++;
	return ZP_MODE:(g_modeNum-1);
}

public ZP_MODE:_getModeID(plugin, params) {
	if (params != 1) {
		zp_logError(AMX_ERR_NATIVE, "Invalid params passed: %d - Expected: 1", params);
		return ZP_MODE:NULL;
	}
	
	new szMode[32], iMode;
	get_string(1, szMode, 31);
	strtolower(szMode);
	if (g_modeTrie == Invalid_Trie || g_modeList == Invalid_Array) {
		zp_logError(AMX_ERR_NATIVE, "Cannot search for mode (^"%s^")", szMode);
		return ZP_MODEL:NULL;
	}
	
	if (TrieGetCell(g_modeTrie, szMode, iMode)) {
		return ZP_MODE:iMode;
	}

	return ZP_MODE:NULL;
}

public ZP_RETURN:_getModeName(plugin, params) {
	if (params != 4) {
		zp_logError(AMX_ERR_NATIVE, "Invalid params passed: %d - Expected: 3", params);
		return ZP_ERROR;
	}

	new ZP_MODE:iMode = ZP_MODE:get_param(1);
	new iLen = get_param(3);
	if (g_modeList == Invalid_Array) {
		zp_logError(AMX_ERR_NATIVE, "Cannot search for mode (%d)", iMode);
		return ZP_ERROR;
	} else if (!_isValidMode(iMode)) {
		return ZP_ERROR;
	}
	
	ArrayGetArray(g_modeList, iMode, g_tempMode);
	set_string(3, g_tempMode[mode_szName], iLen);
	return ZP_SUCCESS;
}

public bool:_isValidMode(ZP_MODE:mode) {
	return !(_:mode < 0 || g_modeNum <= _:mode);
}

public ZP_MODE:_getCurMode() {
	return g_curMode;
}

public ZP_MODE:_getNextMode() {
	return g_nextMode;
}

public ZP_RETURN:_setNextMode(ZP_MODE:mode) {
	if (!_isValidMode(mode)) {
		return ZP_ERROR;
	}
	
	g_nextMode = mode;
	ArrayGetArray(g_modeList, _:g_nextMode, g_tempMode);
	zp_printColor(0, "Next game mode: ^4%s", g_tempMode[mode_szName]);
	return ZP_SUCCESS;
}

public Array:_getModeList() {
	return g_modeList;
}

public _getModeNum() {
	return g_modeNum;
}