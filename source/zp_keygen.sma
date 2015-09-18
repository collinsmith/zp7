#include <amxmodx>
#include <amxmisc>

#include "include/zp7/zp_core_const.inc"
#include "include/md5_gamekey.inc"

static KEY_TO_ENCRYPT[34] = "192.168.1.86";

public plugin_init() {
	register_plugin("ZP KeyGen", "0.0.1", "Tirant");
	
	new szTemp[32];
	formatex(szTemp, 31, "%s%s", ZP_HOME_DIR, ZP_GAME_KEY_FILE);
	gamekey_createKeyFile(szTemp, KEY_TO_ENCRYPT);
}