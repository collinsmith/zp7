#if defined _zp_guns_included
	#endinput
#endif
#define _zp_guns_included

#if AMXX_VERSION_NUM >= 175
	#pragma reqlib ZP_Guns
	#if !defined AMXMODX_NOAUTOLOAD
		#pragma loadlib ZP_Guns
	#endif
#else
	#pragma library ZP_Guns
#endif

#include "include/zp7/classes/guns_t.inc"

forward zp_fw_guns_registerGuns();
forward zp_fw_guns_showGunsMenu(id);
forward zp_fw_guns_itemSelectedPre(id, csw);
forward zp_fw_guns_itemSelectedPost(id, csw);

native ZP_GUNS:zp_guns_registerGunsMenu(const szGunFlags[]);
native ZP_GUNS:zp_guns_registerGunsMenu2(const guns[guns_t]);
native ZP_RETURN:zp_guns_addGunList(ZP_GUNS:guns, const szGunFlags[]);

native bool:zp_guns_showGunsMenu(id, ZP_GUNS:guns, bool:obeyRandom = true);
native bool:zp_guns_showGunsMenu2(id, const szGunFlags[], bool:obeyRandom = true);
native bool:zp_guns_showGunsMenu3(id, gunBitsum, bool:obeyRandom = true);

native bool:zp_guns_isPrimaryWeapon(const csw);
native bool:zp_guns_isSecondaryWeapon(const csw);