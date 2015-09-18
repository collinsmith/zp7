#include "include/zombieplague7.inc"
#include "include/zp7/zp_classes.inc"

#include <cvar_util>
#include <cs_maxspeed_api>

#define VERSION "0.0.1"
#define KNIFE_MAXSPEED 250.0

static Array:g_classList;
static Array:g_groupList;
static Array:g_zombieGroupList;
static Array:g_humanGroupList;

static g_tempClass[class_t];
static g_tempGroup[group_t];

enum _:menu_t {
	menu_iData,
	menu_iData2,
	menu_endString
};

#define MENU_OFFSET 32768
static g_tempMenu[menu_t];

static g_pCvar_GroupClasses;

public zp_fw_core_zombiePlagueInit() {
	server_print("ZP Class Menu Module loaded");
}

public zp_fw_command_registerCommands() {
	zp_command_register("class",		"cmdClassMenu", _, "Opens the class selection menu");
	zp_command_register("classmenu",	"cmdClassMenu");
	zp_command_register("changeclass",	"cmdClassMenu");
}

public cmdClassMenu(id) {
	_showMenu(id, true);
}

public plugin_init() {
	register_plugin("[ZP7] Classes (Menu Module)", VERSION, "Tirant");
	
	g_pCvar_GroupClasses = CvarRegister("zp_classes_groupClasses", "1", _, _, true, 0.0, true, 1.0);
	CvarCache(g_pCvar_GroupClasses, CvarType_Int, g_pCvar_GroupClasses);
	
	new classListID = get_xvar_id("g_classList");
	if (classListID == -1) {
		zp_logError(AMX_ERR_GENERAL, "Cannot find class list");
		set_fail_state("Cannot find class list");
	}
	
	g_classList = Array:get_xvar_num(classListID);
	
	new groupListID = get_xvar_id("g_groupList");
	if (groupListID == -1) {
		zp_logError(AMX_ERR_GENERAL, "Cannot find group list");
		set_fail_state("Cannot find group list");
	}
	
	g_groupList = Array:get_xvar_num(groupListID);
	
	new zombieGroupListID = get_xvar_id("g_zombieGroupList");
	if (zombieGroupListID == -1) {
		zp_logError(AMX_ERR_GENERAL, "Cannot find zombie group list");
		set_fail_state("Cannot find zombie group list");
	}
	
	g_zombieGroupList = Array:get_xvar_num(zombieGroupListID);
	
	new humanGroupListID = get_xvar_id("g_humanGroupList");
	if (humanGroupListID == -1) {
		zp_logError(AMX_ERR_GENERAL, "Cannot find zombie group list");
		set_fail_state("Cannot find zombie group list");
	}
	
	g_humanGroupList = Array:get_xvar_num(humanGroupListID);
	
	register_dictionary("common.txt");
	register_dictionary("zp_core.txt");
	register_dictionary("zp_classes.txt");
}

public zp_fw_core_playerSpawn(id, bool:isZombie) {
	_showMenu(id, false);
}

public zp_fw_core_infect_post(id, attacker) {
	_showMenu(id, false);
}

public zp_fw_core_cure_post(id, curer) {
	_showMenu(id, false);
}

public bool:_showMenu(id, bool:canExit) {
	assert ArraySize(g_classList);
	if (!is_user_connected(id)) {
		return false;
	}
	
	if (g_pCvar_GroupClasses) {
		return _showMenuOfGroups(id, canExit);
	} else {
		return _showMenuOfClasses(id, canExit);
	}
	
	return false;
}

public bool:_showMenuOfGroups(id, bool:canExit) {
	new bool:isZombie = zp_core_isUserZombie(id);
	new szMenu[128], menu;
	formatex(szMenu, 127, "%L", id, "ZP_GROUP_MENU");
	menu = menu_create(szMenu, "showMenuOfGroupsHandle");
	g_tempMenu[menu_iData2] = _:canExit + MENU_OFFSET;

	new Array:groupArray = isZombie ? g_zombieGroupList : g_humanGroupList;
	new groupNum = ArraySize(groupArray);
	new ZP_GROUP:group;
	for (new i; i < groupNum; i++) {
		group = ZP_GROUP:ArrayGetCell(groupArray, i);
		g_tempMenu[menu_iData] = _:group + MENU_OFFSET;
		ArrayGetArray(g_groupList, _:group, g_tempGroup);
		menu_additem(menu, g_tempGroup[group_szName], g_tempMenu);
	}
	
	formatex(szMenu, 127, "%L", id, "BACK");
	menu_setprop(menu, MPROP_BACKNAME, szMenu);
	formatex(szMenu, 127, "%L", id, "MORE");
	menu_setprop(menu, MPROP_NEXTNAME, szMenu);
	
	if (canExit) {
		formatex(szMenu, 127, "%L", id, "EXIT");
		menu_setprop(menu, MPROP_EXITNAME, szMenu);
	} else {
		menu_setprop(menu, MPROP_EXIT, MEXIT_NEVER);
	}

	if (menu_items(menu) == 1) {
		new dummy;
		menu_item_getinfo(menu, 0, dummy, g_tempMenu, menu_t-1, _, _, dummy);
		menu_destroy(menu);
		return _showClassGroupMenu(id, canExit, ZP_GROUP:g_tempMenu[menu_iData]);
	}

	menu_display(id, menu);
	return true;
}

public showMenuOfGroupsHandle(id, menuid, item) {
	if (item == MENU_EXIT) {
		menu_destroy(menuid);
		return PLUGIN_HANDLED;
	}
	
	new dummy;
	menu_item_getinfo(menuid, item, dummy, g_tempMenu, menu_t-1, _, _, dummy);
	_showClassGroupMenu(id, bool:g_tempMenu[menu_iData2], ZP_GROUP:g_tempMenu[menu_iData]);
	menu_destroy(menuid);
	return PLUGIN_HANDLED;
}

public bool:_showClassGroupMenu(id, bool:canExit, ZP_GROUP:group) {
	assert zp_class_isValidGroup(group);
	ArrayGetArray(g_groupList, _:group, g_tempGroup);
	
	new szMenu[128], menu;
	menu = menu_create(g_tempGroup[group_szName], "showClassGroupMenuHandle");
	g_tempMenu[menu_iData2] = _:canExit + MENU_OFFSET;
	
	new ZP_CLASS:class, classNum = ArraySize(g_tempGroup[group_classList]);
	for (new i; i < classNum; i++) {
		class = ZP_CLASS:ArrayGetCell(g_tempGroup[group_classList], i);
		g_tempMenu[menu_iData] = _:class + MENU_OFFSET;
		ArrayGetArray(g_classList, _:class, g_tempClass);
		formatex(szMenu, 127, "%s \y[\w%s\y]", g_tempClass[class_szName], g_tempClass[class_szDesc]);
		menu_additem(menu, szMenu, g_tempMenu, g_tempClass[class_iAdminFlags]);
	}
	
	menu_addblank(menu, 0);
	formatex(szMenu, 127, "%L", id, "BACK");
	g_tempMenu[menu_iData] = _:NULL + MENU_OFFSET;
	menu_additem(menu, szMenu, g_tempMenu);
	menu_addblank(menu, 0);
	
	formatex(szMenu, 127, "%L", id, "BACK");
	menu_setprop(menu, MPROP_BACKNAME, szMenu);
	formatex(szMenu, 127, "%L", id, "MORE");
	menu_setprop(menu, MPROP_NEXTNAME, szMenu);
	
	if (canExit) {
		formatex(szMenu, 127, "%L", id, "EXIT");
		menu_setprop(menu, MPROP_EXITNAME, szMenu);
	} else {
		menu_setprop(menu, MPROP_EXIT, MEXIT_NEVER);
	}
	
	menu_display(id, menu);
	return true;
}

public showClassGroupMenuHandle(id, menuid, item) {
	if (item == MENU_EXIT) {
		menu_destroy(menuid);
		return PLUGIN_HANDLED;
	}
	
	new dummy, ZP_CLASS:class;
	menu_item_getinfo(menuid, item, dummy, g_tempMenu, menu_t-1, _, _, dummy);
	class = g_tempMenu[menu_iData];
	if (zp_class_isValidClass(class) && zp_class_canUseClass(id, class)) {
		menu_destroy(menuid);
		classMenuSelected(id, class);
	} else {
		menu_destroy(menuid);
		_showMenuOfGroups(id, bool:g_tempMenu[menu_iData2]);
	}
	
	return PLUGIN_HANDLED;
}

public bool:_showMenuOfClasses(id, bool:canExit) {
	new bool:isZombie = zp_core_isUserZombie(id);
	new szMenu[128], menu;
	formatex(szMenu, 127, "%L", id, "ZP_CLASS_MENU");
	menu = menu_create(szMenu, "showMenuOfClassesHandle");
	g_tempMenu[menu_iData2] = _:canExit + MENU_OFFSET;
	
	new size = zp_class_getClassNum();
	for (new i; i < size; i++) {
		if (zp_class_isZombieClass(i) != isZombie) {
			continue;
		}
		
		g_tempMenu[menu_iData] = i + MENU_OFFSET;
		ArrayGetArray(g_classList, i, g_tempClass);
		formatex(szMenu, 127, "%s \y[\w%s\y]", g_tempClass[class_szName], g_tempClass[class_szDesc]);
		menu_additem(menu, szMenu, g_tempMenu, g_tempClass[class_iAdminFlags]);
	}
	
	formatex(szMenu, 127, "%L", id, "BACK");
	menu_setprop(menu, MPROP_BACKNAME, szMenu);
	formatex(szMenu, 127, "%L", id, "MORE");
	menu_setprop(menu, MPROP_NEXTNAME, szMenu);
	
	if (canExit) {
		formatex(szMenu, 127, "%L", id, "EXIT");
		menu_setprop(menu, MPROP_EXITNAME, szMenu);
	} else {
		menu_setprop(menu, MPROP_EXIT, MEXIT_NEVER);
	}
	
	menu_display(id, menu);
	return true;
}

public showMenuOfClassesHandle(id, menuid, item) {
	if (item == MENU_EXIT) {
		menu_destroy(menuid);
		return PLUGIN_HANDLED;
	}
	
	new dummy, ZP_CLASS:class;
	menu_item_getinfo(menuid, item, dummy, g_tempMenu, menu_t-1, _, _, dummy);
	class = g_tempMenu[menu_iData];
	if (zp_class_canUseClass(id, class)) {
		menu_destroy(menuid);
		classMenuSelected(id, class);
	} else {
		menu_destroy(menuid);
		_showMenuOfClasses(id, bool:g_tempMenu[menu_iData2]);
	}
	
	return PLUGIN_HANDLED;
}

classMenuSelected(id, ZP_CLASS:class) {
	assert zp_class_isValidClass(class);
	ArrayGetArray(g_classList, _:class, g_tempClass);
	if (zp_class_getUserClass(id) == ZP_CLASS:NULL) {
		zp_class_setUserClass(id, class);
		zp_printColor(id, "You're ^3current ^1class has been changed to: ^4%s", g_tempClass[class_szName]);
	} else {
		zp_class_setUserNextClass(id, class);
		zp_printColor(id, "You're ^3next ^1class has been changed to: ^4%s", g_tempClass[class_szName]);
	}
	
	zp_printColor(id, "Health: ^4%d^1, Speed: ^4%d^1, Gravity: ^4%d",
				floatround(g_tempClass[class_fHealth]),
				(_class_t_getMaxspeed(g_tempClass) <=  MAXSPEED_BARRIER_MAX ? floatround(_class_t_getMaxspeed(g_tempClass) * KNIFE_MAXSPEED) : floatround(_class_t_getMaxspeed(g_tempClass))), 
				floatround(_class_t_getGravity(g_tempClass) * 800.0));
}