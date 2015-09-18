#include "include/zombieplague7.inc"
#include "include/zp7/zp_classes.inc"
#include "include/zp7/classes/guns_t.inc"
#include "include/fm_item_stocks.inc"

#include <cvar_util>
#include <flags32>
#include <fakemeta>
#include <cstrike>

#pragma dynamic 2048

#define VERSION "0.0.1"

#define flag_get_bool(%1,%2)	!!(flag_get(%1,%2))
#define flag_get(%1,%2)			(%1 &   (1 << (%2 & 31)))
#define flag_set(%1,%2)			(%1 |=  (1 << (%2 & 31)))
#define flag_unset(%1,%2)		(%1 &= ~(1 << (%2 & 31)))

native zp_guns_registerGunsMenu(const guns[]);
native zp_guns_addGunList(const ZP_GUNS:gunID, const guns[]);

static Array:g_gunsList;
static g_gunsNum;

static g_tempGuns[guns_t];

enum _:menu_t {
	menu_iData,
	menu_endString
};

static g_tempMenu[menu_t];

static g_pCvar_RandomWeapons, g_pCvar_CustomGunMenus, g_pCvar_WeaponPrices, g_pCvar_WeaponPrice[CSW_P90+1];

static g_fwReturn, g_fwShowGunsMenu, g_fwItemSelectedPre, g_fwItemSelectedPost;

static const g_iGrenadeWeapons = (1<<CSW_HEGRENADE)|(1<<CSW_FLASHBANG)|(1<<CSW_SMOKEGRENADE);
static const g_iSecondaryWeapons = (1<<CSW_GLOCK18)|(1<<CSW_USP)|(1<<CSW_P228)|(1<<CSW_DEAGLE)|(1<<CSW_FIVESEVEN)|(1<<CSW_ELITE);
static const g_iPrimaryWeapons = (1<<CSW_AK47)|(1<<CSW_AUG)|(1<<CSW_AWP)|(1<<CSW_FAMAS)|(1<<CSW_G3SG1)|(1<<CSW_GALIL)|(1<<CSW_M249)|
				(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<CSW_MAC10)|(1<<CSW_MP5NAVY)|(1<<CSW_P90)|(1<<CSW_SCOUT)|(1<<CSW_SG550)|(1<<CSW_SG552)|
				(1<<CSW_TMP)|(1<<CSW_UMP45)|(1<<CSW_XM1014);

static g_pCvar_DefaultPrimaryWeapons, g_pCvar_DefaultSecondaryWeapons;
static ZP_GUNS:g_DefaultGuns;

static ZP_GUNS:g_curGunMenu[MAX_PLAYERS+1] = { ZP_GUNS:NULL, ... };
static g_curGunList[MAX_PLAYERS+1] = { NULL, ... };
static g_bObeyRandom, g_bHasSelectedGuns;

static const g_szWeaponEntNames[][] = {
	"", "weapon_p228", "", "weapon_scout", "weapon_hegrenade", "weapon_xm1014", "weapon_c4", "weapon_mac10",
	"weapon_aug", "weapon_smokegrenade", "weapon_elite", "weapon_fiveseven", "weapon_ump45", "weapon_sg550",
	"weapon_galil", "weapon_famas", "weapon_usp", "weapon_glock18", "weapon_awp", "weapon_mp5navy", "weapon_m249",
	"weapon_m3", "weapon_m4a1", "weapon_tmp", "weapon_g3sg1", "weapon_flashbang", "weapon_deagle", "weapon_sg552",
	"weapon_ak47", "weapon_knife", "weapon_p90"
};

static g_pCvar_WeaponAmmo[CSW_P90+1];

static const g_iWeaponAmmoDefaults[] = {
	0, 52, 0, 90, 0, 32, 0, 90,
	90, 0, 120, 60, 100, 90,
	115, 75, 60, 120, 30, 120, 200,
	32, 90, 120, 90, 0, 35, 90,
	90,	0, 100
}

static const g_iWeaponPriceDefaults[] = {
	-1, 600, -1, 2750, -1, 3000, -1, 1400,
	3500, -1, 1000, 750, 1700, 4200,
	2000, 2250, 400, 400, 4750, 1500, 5750,
	1700, 3100, 1250, 5000, -1, 650, 3500,
	2500, -1, 2350
};

public zp_fw_core_zombiePlagueInit() {
	g_gunsList = ArrayCreate(guns_t, 2);
	
	server_print("ZP Guns Module loaded");

	new szTemp[33];
	get_flags32(g_iPrimaryWeapons, szTemp, 32);
	g_pCvar_DefaultPrimaryWeapons = CvarRegister("zp_guns_defaultPrimaryWeapons", szTemp);
	g_DefaultGuns = zp_guns_registerGunsMenu(szTemp);
	CvarHookChange(g_pCvar_DefaultPrimaryWeapons, "defaultWeaponsCallback");
	get_flags32(g_iSecondaryWeapons, szTemp, 32);
	g_pCvar_DefaultSecondaryWeapons = CvarRegister("zp_guns_defaultSecondaryWeapons", szTemp);
	zp_guns_addGunList(g_DefaultGuns, szTemp);
	CvarHookChange(g_pCvar_DefaultSecondaryWeapons, "defaultWeaponsCallback");
	
	new fwRegisterGuns = CreateMultiForward("zp_fw_guns_registerGuns", ET_CONTINUE);
	ExecuteForward(fwRegisterGuns, g_fwReturn);
	DestroyForward(fwRegisterGuns);
}

public zp_fw_command_registerCommands() {
	zp_command_register("guns",			"cmdGuns", "abde", "Opens your weapon selection menu");
	zp_command_register("weapons",		"cmdGuns");
	zp_command_register("gunmenu",		"cmdGuns");
	zp_command_register("weaponmenu",	"cmdGuns");
}

public cmdGuns(id) {
	if (flag_get(g_bHasSelectedGuns, id)) {
		zp_printColor(id, "You cannot use this option right now");
		return;
	}
	
	fm_strip_user_weapons(id);
	fm_give_item(id, g_szWeaponEntNames[CSW_KNIFE]);
	// Auto give items here...
	
	if (!g_pCvar_CustomGunMenus) {
		_showGunsMenu(id, g_DefaultGuns, true);
		return;
	}
	
	ExecuteForward(g_fwShowGunsMenu, g_fwReturn, id);
	if (!_isValidGuns(g_fwReturn)) {
		_showGunsMenu(id, g_DefaultGuns, true);
		return;
	}
	
	_showGunsMenu(id, g_fwReturn, true);
}

public plugin_init() {
	register_plugin("[ZP7] Guns Module", VERSION, "Tirant");
	
	g_pCvar_RandomWeapons = CvarRegister("zp_guns_randomWeapons", "0", _, _, true, 0.0, true, 1.0);
	CvarCache(g_pCvar_RandomWeapons, CvarType_Int, g_pCvar_RandomWeapons);
	
	g_pCvar_WeaponPrices = CvarRegister("zp_guns_weaponPrices", "1", _, _, true, 0.0, true, 1.0);
	CvarCache(g_pCvar_WeaponPrices, CvarType_Int, g_pCvar_WeaponPrices);
	
	g_pCvar_CustomGunMenus = CvarRegister("zp_guns_customGunMenus", "1", _, _, true, 0.0, true, 1.0);
	CvarCache(g_pCvar_CustomGunMenus, CvarType_Int, g_pCvar_CustomGunMenus);
	
	new szCvarName[128], szTemp[33];
	for (new i = CSW_P228; i < CSW_P90+1; i++) {
		if (_isGrenadeWeapon(i) || _isSecondaryWeapon(i) || _isPrimaryWeapon(i)) {
			formatex(szCvarName, 127, "zp_guns_bpammo_%s", g_szWeaponEntNames[i][7]);
			num_to_str(g_iWeaponAmmoDefaults[i], szTemp, 32);
			g_pCvar_WeaponAmmo[i] = CvarRegister(szCvarName, szTemp, _, _, true, 0.0, true, 255.0);
			CvarCache(g_pCvar_WeaponAmmo[i], CvarType_Int, g_pCvar_WeaponAmmo[i]);

			formatex(szCvarName, 127, "zp_guns_price_%s", g_szWeaponEntNames[i][7]);
			num_to_str(g_iWeaponPriceDefaults[i], szTemp, 32);
			g_pCvar_WeaponPrice[i] = CvarRegister(szCvarName, szTemp, _, _, true, 0.0);
			CvarCache(g_pCvar_WeaponPrice[i], CvarType_Int, g_pCvar_WeaponPrice[i]);
		}
	}
	
	g_fwShowGunsMenu	= CreateMultiForward("zp_fw_guns_showGunsMenu", ET_CONTINUE, FP_CELL);
	g_fwItemSelectedPre	= CreateMultiForward("zp_fw_guns_itemSelectedPre", ET_IGNORE, FP_CELL, FP_CELL);
	g_fwItemSelectedPost= CreateMultiForward("zp_fw_guns_itemSelectedPost", ET_IGNORE, FP_CELL, FP_CELL);
	
	register_dictionary("common.txt");
	register_dictionary("zp_guns.txt");
}

public defaultWeaponsCallback(handleCvar, const oldValue[], const newValue[], const cvarName[]) {
	ArrayGetArray(g_gunsList, g_DefaultGuns, g_tempGuns);
	new Array:gunList = g_tempGuns[guns_BitArray];
	if (handleCvar == g_pCvar_DefaultPrimaryWeapons) {
		ArraySetCell(gunList, 0, read_flags32(newValue));
	} else {
		ArraySetCell(gunList, 1, read_flags32(newValue));
	}
}

public plugin_natives() {
	register_library("ZP_Guns");
	
	register_native("zp_guns_registerGunsMenu",		"_registerGuns",		0);
	register_native("zp_guns_registerGunsMenu2",	"_registerGuns2",		0);
	register_native("zp_guns_addGunList",			"_addGunsMenu",			0);
	
	register_native("zp_guns_showGunsMenu",			"_showGunsMenu",		1);
	register_native("zp_guns_showGunsMenu2",		"_showGunsMenu2",		0);
	register_native("zp_guns_showGunsMenu3",		"_showGunsMenu3",		1);
	
	register_native("zp_guns_isPrimaryWeapon",		"_isPrimaryWeapon",		1);
	register_native("zp_guns_isSecondaryWeapon",	"_isSecondaryWeapon",	1);
	register_native("zp_guns_isGrenadeWeapon",		"_isGrenadeWeapon",		1);
}

public client_disconnect(id) {
	g_curGunMenu[id] = NULL;
	g_curGunList[id] = NULL;
}

public ZP_RETURN:_addGunsMenu(plugin, params) {
	if (params != 2) {
		zp_logError(AMX_ERR_NATIVE, "Invalid params passed: %d - Expected: 2", params);
		return ZP_ERROR;
	}
	
	if (g_gunsList == Invalid_Array) {
		return ZP_ERROR;
	}
	
	new ZP_GUNS:guns = ZP_GUNS:get_param(1);
	if (!_isValidGuns(guns)) {
		zp_logError(AMX_ERR_NATIVE, "ZP Guns object does not exist (%d)", guns);
		return ZP_ERROR;
	}
	
	ArrayGetArray(g_gunsList, _:guns, g_tempGuns);
	
	new szGunFlags[33];
	get_string(2, szGunFlags, 32);
	ArrayPushCell(g_tempGuns[guns_BitArray], read_flags32(szGunFlags));
	ArraySetArray(g_gunsList, _:guns, g_tempGuns);
	
	return ZP_SUCCESS;
}

public ZP_GUNS:_registerGuns(plugin, params) {
	if (params != 1) {
		zp_logError(AMX_ERR_NATIVE, "Invalid params passed: %d - Expected: 1", params);
		return ZP_GUNS:NULL;
	}
	
	if (g_gunsList == Invalid_Array) {
		return ZP_GUNS:NULL;
	}
	
	_guns_t_default(g_tempGuns);
	
	new szGunFlags[33];
	get_string(1, szGunFlags, 32);
	ArrayPushCell(g_tempGuns[guns_BitArray], read_flags32(szGunFlags));
	
	ArrayPushArray(g_gunsList, g_tempGuns);
	g_gunsNum++;
	return ZP_GUNS:(g_gunsNum-1);
}

public ZP_GUNS:_registerGuns2(plugin, params) {
	if (params != 1) {
		zp_logError(AMX_ERR_NATIVE, "Invalid params passed: %d - Expected: 1", params);
		return ZP_GUNS:NULL;
	}
	
	if (g_gunsList == Invalid_Array) {
		return ZP_GUNS:NULL;
	}
	
	_guns_t_default(g_tempGuns);
	ArrayPushCell(g_tempGuns[guns_BitArray], get_param(1));
	
	ArrayPushArray(g_gunsList, g_tempGuns);
	g_gunsNum++;
	return ZP_GUNS:(g_gunsNum-1);
}

public zp_fw_class_classLoaded(id, ZP_CLASS:next) {
	if (zp_core_isUserZombie(id)) {
		return;
	}
	
	flag_unset(g_bHasSelectedGuns, id);
	cmdGuns(id);
}

public bool:_showGunsMenu(id, ZP_GUNS:guns, bool:obeyRandom) {
	assert _isValidGuns(guns)
	g_curGunMenu[id] = guns;
	ArrayGetArray(g_gunsList, _:guns, g_tempGuns);
	g_curGunList[id] = ArraySize(g_tempGuns[guns_BitArray])-1;
	obeyRandom ? flag_set(g_bObeyRandom, id) : flag_unset(g_bObeyRandom, id);
	return showGunsMenu(id, ArrayGetCell(g_tempGuns[guns_BitArray], g_curGunList[id]), obeyRandom);
}

public bool:_showGunsMenu2(plugin, params) {
	if (params != 3) {
		zp_logError(AMX_ERR_NATIVE, "Invalid params passed: %d - Expected: 3", params);
		return false;
	}
	
	new szGunFlags[33];
	get_string(2, szGunFlags, 32);
	return showGunsMenu(get_param(1), read_flags32(szGunFlags), bool:get_param(3));
}

public bool:_showGunsMenu3(id, guns, bool:obeyRandom) {
	return showGunsMenu(id, guns, obeyRandom);
}

bool:showGunsMenu(id, guns, bool:obeyRandom) {
	new szMenu[128], menu, money = fm_cs_get_user_money(id);
	if (g_pCvar_WeaponPrices) {
		formatex(szMenu, 127, "%L - $%d", id, "ZP_GUNS_MENU", money);
	} else {
		formatex(szMenu, 127, "%L", id, "ZP_GUNS_MENU");
	}
	
	menu = menu_create(szMenu, "showGunsMenuHandle");

	new lowestCost, lowestCostCSW, numAvailable;
	for (new i; guns; i++, guns >>>= 1) {
		if (guns&1 == 0 || g_szWeaponEntNames[i][0] == '^0') {
			continue;
		}

		g_tempMenu[menu_iData] = i;
		if (g_pCvar_WeaponPrices) {
			if (money >= g_pCvar_WeaponPrice[i]) {
				formatex(szMenu, 127, "%L [$%d]", "en", g_szWeaponEntNames[i], g_pCvar_WeaponPrice[i]);
				numAvailable++;
			} else {
				formatex(szMenu, 127, "\d%L [$%d]", "en", g_szWeaponEntNames[i], g_pCvar_WeaponPrice[i]);
				if (lowestCostCSW == 0 || g_pCvar_WeaponPrice[i] < lowestCost) {
					lowestCost = g_pCvar_WeaponPrice[i];
					lowestCostCSW = i;
				}
			}
		} else {
			formatex(szMenu, 127, "%L", "en", g_szWeaponEntNames[i]);
		}
		
		menu_additem(menu, szMenu, g_tempMenu);
	}
	
	if (g_pCvar_WeaponPrices && numAvailable == 0) {
		menu_destroy(menu);
		fm_cs_set_user_money(id, 0);
		giveWeapon(id, lowestCostCSW);
		showNextMenu(id);
		return true;
	}
	
	formatex(szMenu, 127, "%L", id, "BACK");
	menu_setprop(menu, MPROP_BACKNAME, szMenu);
	formatex(szMenu, 127, "%L", id, "MORE");
	menu_setprop(menu, MPROP_NEXTNAME, szMenu);
	menu_setprop(menu, MPROP_EXIT, MEXIT_NEVER);
	//formatex(szMenu, 127, "%L", id, "EXIT");
	//menu_setprop(menu, MPROP_EXITNAME, szMenu);
	if ((!g_pCvar_RandomWeapons || !obeyRandom) && !is_user_bot(id)) {
		menu_display(id, menu);
	} else {
		new dummy;
		menu_item_getinfo(menu, random(menu_items(menu))+1, dummy, g_tempMenu, menu_t-1, _, _, dummy);
		giveWeapon(id, g_tempMenu[menu_iData]);
		menu_destroy(menu);
		showNextMenu(id)
	}
	
	return true;
}

public showGunsMenuHandle(id, menuid, item) {
	if (item == MENU_EXIT) {
		menu_destroy(menuid);
		return PLUGIN_HANDLED;
	}
	
	flag_set(g_bHasSelectedGuns, id);
	new dummy, money = fm_cs_get_user_money(id), csw, price;
	menu_item_getinfo(menuid, item, dummy, g_tempMenu, menu_t-1, _, _, dummy);
	csw = g_tempMenu[menu_iData];
	if (g_pCvar_WeaponPrices) {
		price = g_pCvar_WeaponPrice[csw];
		if (money < price) {
			zp_printColor(id, "You need more money ($%d) to purchase this weapon", -(money-price));
			player_menu_info(id, dummy, dummy, dummy);
			menu_display(id, menuid, dummy);
			return PLUGIN_HANDLED;
		} else {
			fm_cs_set_user_money(id, money-price);
		}
	}	
	
	giveWeapon(id, csw);
	menu_destroy(menuid);
	showNextMenu(id)
	
	return PLUGIN_HANDLED;
}

showNextMenu(id) {
	if (--g_curGunList[id] != NULL) {
		ArrayGetArray(g_gunsList, _:g_curGunMenu[id], g_tempGuns);
		showGunsMenu(id, ArrayGetCell(g_tempGuns[guns_BitArray], g_curGunList[id]), flag_get_bool(g_bObeyRandom, id));
	} else {
		flag_unset(g_bObeyRandom, id);
		g_curGunMenu[id] = ZP_GUNS:NULL;
	}
}

giveWeapon(id, csw) {
	ExecuteForward(g_fwItemSelectedPre, g_fwReturn, id, csw);
	if (g_fwReturn == ZP_BLOCK) {
		return;
	}

	fm_give_item(id, g_szWeaponEntNames[csw]);
	cs_set_user_bpammo(id, csw, g_pCvar_WeaponAmmo[csw]);
	//server_print("Setting %d's %s bpammo to %d... !%d!", id, g_szWeaponEntNames[csw], g_pCvar_WeaponAmmo[csw], fm_cs_get_user_bpammo(id, csw));
	ExecuteForward(g_fwItemSelectedPost, g_fwReturn, id, csw);
}

public bool:_isValidGuns(ZP_GUNS:guns) {
	return !(_:guns < 0 || g_gunsNum <= _:guns);
}

public bool:_isPrimaryWeapon(csw) {
	if (g_iPrimaryWeapons&(1<<csw)) {
		return true;
	}
	
	return false;
}

public bool:_isSecondaryWeapon(csw) {
	if (g_iSecondaryWeapons&(1<<csw)) {
		return true;
	}
	
	return false;
}

public bool:_isGrenadeWeapon(csw) {
	if (g_iGrenadeWeapons&(1<<csw)) {
		return true;
	}
	
	return false;
}

stock fm_cs_get_user_money(id) {
	return get_pdata_int(id, 115, 5);
}

stock fm_cs_set_user_money(id, money, flash = 1) {
	set_pdata_int(id, 115, money, 5);
	
	static iMoney;
	if( iMoney || (iMoney = get_user_msgid("Money")) ) {
		emessage_begin(MSG_ONE_UNRELIABLE, iMoney, _, id); {
		ewrite_long(money);
		ewrite_byte(flash ? 1 : 0);
		} emessage_end();
	}
}