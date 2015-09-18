#if defined _zp_precache_included
	#endinput
#endif
#define _zp_precache_included

#include <amxmodx>
#include <amxmisc>
#include <fakemeta>

#include "include/zp7/zp_log.inc"

stock bool:zp_precachePlayerModel(model[]) {
	new temp[64];
	formatex(temp, 63, "models/player/%s/%s.mdl", model, model);
	return zp_precache(temp);
}

stock bool:zp_precacheModel(model[]) {
	if (file_exists(model)) {
		engfunc(EngFunc_PrecacheModel, model);
		return true;
	}
	
	return false;
}

stock bool:zp_precacheSound(sound[]) {
	new temp[64];
	formatex(temp, 63, "sound/%s", sound);
	return zp_precache(temp);
}

stock bool:zp_precache(file[]) {
	if (file_exists(file)) {
		engfunc(EngFunc_PrecacheGeneric, file);
		return true;
	}
	
	return false;
}