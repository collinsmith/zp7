#include "include/zombieplague7.inc"
#include "include/zp7/zp_classes.inc"
#include "include/zp7/zp_guns.inc"
#include "include/zp7/classes/hclass_t.inc"

#include <cvar_util>

#define VERSION "0.0.1"

static Array:g_classList;

static Array:g_humanList;
static g_humanNum;

static g_tempHClass[hclass_t];
static g_tempClass[class_t];
static g_tempGroup[group_t];

static g_fwReturn;

public zp_fw_core_zombiePlagueInitPre() {
	g_humanList = ArrayCreate(hclass_t, 4);
	
	new classListID = get_xvar_id("g_classList");
	if (classListID == -1) {
		zp_logError(AMX_ERR_GENERAL, "Cannot find class list");
		set_fail_state("Cannot find class list");
	}
	
	g_classList = Array:get_xvar_num(classListID);
}

public zp_fw_class_registerClasses() {
	server_print("ZP Human Class Module loaded");
	
	new fwRegisterHClasses = CreateMultiForward("zp_fw_class_registerHumans", ET_CONTINUE);
	ExecuteForward(fwRegisterHClasses, g_fwReturn);
	DestroyForward(fwRegisterHClasses);
}

public plugin_init() {
	register_plugin("[ZP7] Classes (Human Module)", VERSION, "Tirant");
}

public plugin_natives() {
	register_library("ZP_HClasses");
	
	register_native("zp_class_createHGroup",		"_createHGroup",		0);
	register_native("zp_class_createHGroup2",		"_createHGroup2",		0);
	register_native("zp_class_registerHClass",		"_registerHClass",		0);
	register_native("zp_class_registerHClass2",		"_registerHClass2",		0);
}

public zp_fw_core_infect_post(id, attacker) {
}

public zp_fw_core_cure_post(id, curer) {
}

public zp_fw_guns_showGunsMenu(id) {
	new ZP_CLASS:curClass = zp_class_getUserClass(id);
	if (!zp_class_isValidClass(curClass)) {
		return ZP_GUNS:NULL;
	}
	
	ArrayGetArray(g_classList, _:curClass, g_tempClass);
	ArrayGetArray(g_humanList, _:g_tempClass[class_inheritingClass], g_tempHClass);
	return g_tempHClass[hclass_guns];
}

public ZP_GROUP:_createHGroup(plugin, params) {
	if (params != 1) {
		zp_logError(AMX_ERR_NATIVE, "Invalid params passed: %d - Expected: 1", params);
		return ZP_GROUP:NULL;
	}
	
	_group_t_default(g_tempGroup);
	get_string(1, g_tempGroup[group_szName], group_szName_length);
	new ZP_GROUP:group = zp_class_registerGroup(g_tempGroup);
	if (zp_class_isValidGroup(group)) {
		zp_class_addGroupToType(group, false);
	}
	
	return group;
}

public ZP_GROUP:_createHGroup2(plugin, params) {
	if (params != 1) {
		zp_logError(AMX_ERR_NATIVE, "Invalid params passed: %d - Expected: 1", params);
		return ZP_GROUP:NULL;
	}
	
	get_array(1, g_tempGroup, group_t);
	new ZP_GROUP:group = zp_class_registerGroup(g_tempGroup);
	if (zp_class_isValidGroup(group)) {
		zp_class_addGroupToType(group, false);
	}
	
	return group;
}

public ZP_CLASS:_registerHClass(plugin, params) {
	if (params != 13) {
		zp_logError(AMX_ERR_NATIVE, "Invalid params passed: %d - Expected: 13", params);
		return ZP_CLASS:NULL;
	}
	
	if (g_humanList == Invalid_Array) {
		return ZP_CLASS:NULL;
	}
	
	new ZP_GROUP:group = ZP_GROUP:get_param(1);
	assert zp_class_isValidGroup(group);
	_class_t_default(g_tempClass);
	get_string(2, g_tempClass[class_szName], class_szName_length);
	get_string(3, g_tempClass[class_szDesc], class_szDesc_length);
	
	new szTemp[32];
	get_string(5, szTemp, 31);
	g_tempClass[class_model			] = zp_core_registerModel(false, szTemp);
	g_tempClass[class_fHealth		] = _:float(get_param(6));
	g_tempClass[class_fMaxspeed		] = _:get_param_f(7);
	g_tempClass[class_fGravity		] = _:get_param_f(8);
	g_tempClass[class_bNoFallDamage	] = bool:get_param(9);
	g_tempClass[class_fKnockback	] = _:get_param_f(10);
	g_tempClass[class_iCost			] = get_param(11);
	g_tempClass[class_iAdminFlags	] = get_param(12);
	g_tempClass[class_iMaxNumber	] = get_param(13);
	
	new ZP_CLASS:class = zp_class_registerClass(g_tempClass);
	if (class == ZP_CLASS:NULL) {
		return class;
	}
	
	g_tempHClass[hclass_parentClass	] = class;
	g_tempHClass[hclass_guns		] = get_param(4);
		
	_class_t_setInheritingClass(g_tempClass, g_humanNum);
	ArraySetArray(g_classList, _:class, g_tempClass);

	ArrayPushArray(g_humanList, g_tempHClass);
	g_humanNum++;
	
	zp_class_addClassToGroup(class, group);
	return class;
}

public ZP_CLASS:_registerHClass2(plugin, params) {
	if (params != 2) {
		zp_logError(AMX_ERR_NATIVE, "Invalid params passed: %d - Expected: 2", params);
		return ZP_CLASS:NULL;
	}
	
	if (g_humanList == Invalid_Array) {
		return ZP_CLASS:NULL;
	}
	
	new ZP_GROUP:group = ZP_GROUP:get_param(1);
	assert zp_class_isValidGroup(group);
	
	get_array(2, g_tempClass, class_t);
	new ZP_CLASS:class = zp_class_registerClass(g_tempClass);
	if (class == ZP_CLASS:NULL) {
		return class;
	}
	
	g_tempHClass[hclass_parentClass	] = class;
	g_tempHClass[hclass_guns		] = ZP_GUNS:NULL;
	
	_class_t_setInheritingClass(g_tempClass, g_humanNum);
	ArraySetArray(g_classList, _:class, g_tempClass);
	
	ArrayPushArray(g_humanList, g_tempHClass);
	g_humanNum++;
	
	zp_class_addClassToGroup(class, group);	
	return class;
}