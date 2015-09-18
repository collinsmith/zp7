#include "include/zombieplague7.inc"
#include "include/zp7/zp_modemanager.inc"

#include <cvar_util>

#pragma dynamic 2048

#define VERSION "0.0.1"

#define TASK_RESPAWNUSER	123456

static Float:g_fRespawnDelay;
static Float:g_fInfectPercent;

static ZP_MODE:g_modeZombieEscape = ZP_MODE:NULL;
static bool:g_bIsActive = false;

public zp_fw_mode_registerModes() {
	g_modeZombieEscape = zp_mode_registerMode("Zombie Escape", "Humans run to the rescue area. Infection.", 1);
}

public plugin_init() {
	register_plugin("[ZP7] Mode: Zombie Escape", VERSION, "Tirant");
	
	new pCvar_RespawnDelay = CvarRegister("zp_mode_ze_respawnDelay", "2.5", _, _, true, 0.0);
	CvarCache(pCvar_RespawnDelay, CvarType_Float, g_fRespawnDelay);
	
	new pCvar_InfectPercent = CvarRegister("zp_mode_ze_infectPercent", "0.30", _, _, true, 0.0, true, 1.0);
	CvarCache(pCvar_InfectPercent, CvarType_Float, g_fInfectPercent);
}

public client_disconnect(id) {
	remove_task(id+TASK_RESPAWNUSER);
}

public zp_fw_core_playerSpawn(id, bool:isZombie) {
	if (!g_bIsActive) {
		return;
	}

	//...
}

public zp_fw_core_playerDeath(killer, victim) {
	if (!g_bIsActive) {
		return;
	}
	
	if (!zp_core_isUserZombie(victim)) {
		zp_core_infect(victim, killer, true);
		set_hudmessage(255, 255, 255, _, _, _, 0.1, g_fRespawnDelay, _, _, MODE_HUD_CHANNEL);
		show_hudmessage(victim, "You have been infected!^nYou will respawn in %.1f seconds...", g_fRespawnDelay);
	}
	
	if (g_fRespawnDelay == 0.0) {
		zp_core_respawn(victim);
	} else {
		set_task(g_fRespawnDelay, "task_respawnEvent", victim+TASK_RESPAWNUSER);
	}
}

public zp_fw_mode_newRound_Pre(ZP_MODE:mode) {
	zp_mode_setNextMode(g_modeZombieEscape);
}

public zp_fw_mode_newRound_Post(ZP_MODE:mode) {
	g_bIsActive = bool:(mode == g_modeZombieEscape);
	if (!g_bIsActive) {
			
		return;
	}
}

public zp_fw_core_roundStart() {
	if (!g_bIsActive) {
		return;
	}
	
	zp_core_infectPercent(g_fInfectPercent);
}

public task_respawnEvent(taskid) {
	if (taskid > MAX_PLAYERS) {
		taskid -= TASK_RESPAWNUSER;
	}
	
	zp_core_respawn(taskid);
}