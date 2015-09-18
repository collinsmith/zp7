#include "include/zombieplague7.inc"
#include "include/zp7/zp_classes.inc"
#include "include/zp7/classes/zclass_t.inc"

#include <cvar_util>
#include <cs_weap_models_api>

native zp_class_registerHandModel(const model[]);
native zp_class_getHandModelName(ZP_HANDMODEL:modelid, str[], len);

#define VERSION "0.0.1"
#define handmodel_szName_length 31

static const g_szHandModelPath[] = "zp7/hands/";

static Array:g_classList;

static Array:g_modelList;
static Trie:g_modelTrie;
static g_modelNum;

static Array:g_zombieList;
static g_zombieNum;

static g_tempZClass[zclass_t];
static g_tempClass[class_t];
static g_tempGroup[group_t];

static g_fwReturn;

static g_szBaseHandModel[handmodel_szName_length+1];
static ZP_HANDMODEL:g_defaultHandModel;

public zp_fw_core_zombiePlagueInitPre() {
	g_zombieList = ArrayCreate(zclass_t, 4);

	g_modelList = ArrayCreate(handmodel_szName_length+1, 4);
	g_modelTrie = TrieCreate();
	
	new pCvar_HandModel = CvarRegister("zp_class_base_hand_model", "v_bloodyhands");
	get_pcvar_string(pCvar_HandModel, g_szBaseHandModel, handmodel_szName_length);
	g_defaultHandModel = zp_class_registerHandModel(g_szBaseHandModel);
	
	new classListID = get_xvar_id("g_classList");
	if (classListID == -1) {
		zp_logError(AMX_ERR_GENERAL, "Cannot find class list");
		set_fail_state("Cannot find class list");
	}
	
	g_classList = Array:get_xvar_num(classListID);
}

public zp_fw_class_registerClasses() {
	server_print("ZP Zombie Class Module loaded");
	
	new fwRegisterZClasses = CreateMultiForward("zp_fw_class_registerZombies", ET_CONTINUE);
	ExecuteForward(fwRegisterZClasses, g_fwReturn);
	DestroyForward(fwRegisterZClasses);
}

public plugin_init() {
	register_plugin("[ZP7] Classes (Zombie Module)", VERSION, "Tirant");
}

public plugin_natives() {
	register_library("ZP_ZClasses");
	
	register_native("zp_class_registerHandModel",	"_registerHandModel",	0);
	register_native("zp_class_getHandModelID",		"_getHandModelID",		0);
	register_native("zp_class_getHandModelName",	"_getHandModelName",	0);
	register_native("zp_class_isValidHandModel",	"_isValidHandModel",	1);
	
	register_native("zp_class_createZGroup",		"_createZGroup",		0);
	register_native("zp_class_createZGroup2",		"_createZGroup2",		0);
	register_native("zp_class_registerZClass",		"_registerZClass",		0);
	register_native("zp_class_registerZClass2",		"_registerZClass2",		0);
}

public zp_fw_core_infect_post(id, attacker) {
	new ZP_CLASS:curClass = zp_class_getUserClass(id);
	new szModelName[handmodel_szName_length+1];
	if (curClass != ZP_CLASS:NULL) {
		ArrayGetArray(g_classList, curClass, g_tempClass);
		ArrayGetArray(g_zombieList, _:g_tempClass[class_inheritingClass], g_tempZClass);
		if (g_tempClass[class_inheritingClass] == ZP_HANDMODEL:NULL) {
			zp_class_getHandModelName(ZP_HANDMODEL:0, szModelName, handmodel_szName_length);
		} else {
			zp_class_getHandModelName(_zclass_t_getHandModel(g_tempZClass), szModelName, handmodel_szName_length);
		}
	} else {
		zp_class_getHandModelName(ZP_HANDMODEL:0, szModelName, handmodel_szName_length);
	}
	
	new szModelPath[64];
	formatex(szModelPath, 127, "models/%s%s.mdl", g_szHandModelPath, szModelName);
	cs_set_player_view_model(id, CSW_KNIFE, szModelPath);
	cs_set_player_weap_model(id, CSW_KNIFE, "");
}

public zp_fw_core_cure_post(id, curer) {
	cs_reset_player_view_model(id, CSW_KNIFE);
	cs_reset_player_weap_model(id, CSW_KNIFE);
}

public ZP_GROUP:_createZGroup(plugin, params) {
	if (params != 1) {
		zp_logError(AMX_ERR_NATIVE, "Invalid params passed: %d - Expected: 1", params);
		return ZP_GROUP:NULL;
	}
	
	_group_t_default(g_tempGroup);
	get_string(1, g_tempGroup[group_szName], group_szName_length);
	new ZP_GROUP:group = zp_class_registerGroup(g_tempGroup);
	if (zp_class_isValidGroup(group)) {
		zp_class_addGroupToType(group, true);
	}
	
	return group;
}

public ZP_CLASS:_createZGroup2(plugin, params) {
	if (params != 1) {
		zp_logError(AMX_ERR_NATIVE, "Invalid params passed: %d - Expected: 1", params);
		return ZP_GROUP:NULL;
	}
	
	get_array(1, g_tempGroup, group_t);
	new ZP_GROUP:group = zp_class_registerGroup(g_tempGroup);
	if (zp_class_isValidGroup(group)) {
		zp_class_addGroupToType(group, true);
	}
	
	return group;
}

public ZP_CLASS:_registerZClass(plugin, params) {
	if (params != 13) {
		zp_logError(AMX_ERR_NATIVE, "Invalid params passed: %d - Expected: 13", params);
		return ZP_CLASS:NULL;
	}
	
	if (g_zombieList == Invalid_Array) {
		return ZP_CLASS:NULL;
	}
	
	new ZP_GROUP:group = ZP_GROUP:get_param(1);
	assert zp_class_isValidGroup(group);
	
	_class_t_default(g_tempClass);
	get_string(2, g_tempClass[class_szName], class_szName_length);
	get_string(3, g_tempClass[class_szDesc], class_szDesc_length);
	
	new szTemp[32];
	get_string(4, szTemp, 31);
	g_tempClass[class_model] = zp_core_registerModel(true, szTemp);
	
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
	
	g_tempZClass[zclass_parentClass] = class;
	
	get_string(5, szTemp, handmodel_szName_length);
	g_tempZClass[zclass_handModel] = zp_class_registerHandModel(szTemp);
	if (g_tempZClass[zclass_handModel] == ZP_HANDMODEL:NULL) {
		g_tempZClass[zclass_handModel] = g_defaultHandModel;
	}
	
	_class_t_setInheritingClass(g_tempClass, g_zombieNum);
	ArraySetArray(g_classList, _:class, g_tempClass);
	
	ArrayPushArray(g_zombieList, g_tempZClass);
	g_zombieNum++;
	
	zp_class_addClassToGroup(class, group);	
	return class;
}

public ZP_CLASS:_registerZClass2(plugin, params) {
	if (params != 2) {
		zp_logError(AMX_ERR_NATIVE, "Invalid params passed: %d - Expected: 2", params);
		return ZP_CLASS:NULL;
	}
	
	if (g_zombieList == Invalid_Array) {
		return ZP_CLASS:NULL;
	}
	
	new ZP_GROUP:group = ZP_GROUP:get_param(1);
	assert zp_class_isValidGroup(group);
	
	get_array(2, g_tempClass, class_t);
	new ZP_CLASS:class = zp_class_registerClass(g_tempClass);
	if (class == ZP_CLASS:NULL) {
		return class;
	}
	
	g_tempZClass[zclass_parentClass	] = class;
	g_tempZClass[zclass_handModel	] = g_defaultHandModel;

	_class_t_setInheritingClass(g_tempClass, g_zombieNum);
	ArraySetArray(g_classList, _:class, g_tempClass);
	
	ArrayPushArray(g_zombieList, g_tempZClass);
	g_zombieNum++;
	
	zp_class_addClassToGroup(class, group);	
	return class;
}

public ZP_HANDMODEL:_registerHandModel(plugin, params) {
	if (params != 1) {
		zp_logError(AMX_ERR_NATIVE, "Invalid params passed: %d - Expected: 1", params);
		return ZP_HANDMODEL:NULL;
	}
	
	new szModel[handmodel_szName_length+1];
	get_string(1, szModel, handmodel_szName_length);
	if (szModel[0] == '^0') {
		return ZP_HANDMODEL:NULL;
	}
	
	if (g_modelTrie == Invalid_Trie || g_modelList == Invalid_Array) {
		zp_logError(AMX_ERR_NATIVE, "Cannot register hand model yet (^"%s^")", szModel);
		return ZP_HANDMODEL:NULL;
	}
	
	new szTemp[handmodel_szName_length+1], i;
	copy(szTemp, handmodel_szName_length, szModel);
	strtolower(szTemp);
	if (TrieGetCell(g_modelTrie, szTemp, i)) {
		return ZP_HANDMODEL:i;
	}
	
	new szModelPath[128];
	formatex(szModelPath, 127, "models/%s%s.mdl", g_szHandModelPath, szModel);
	if (!zp_precacheModel(szModelPath)) {
		zp_logError(AMX_ERR_NATIVE, "Could not find model (%s)", szModel);
		return ZP_HANDMODEL:NULL;
	}
	
	ArrayPushString(g_modelList, szModel);
	TrieSetCell(g_modelTrie, szTemp, g_modelNum);
	g_modelNum++;
	return ZP_HANDMODEL:(g_modelNum-1);
}

public ZP_HANDMODEL:_getHandModelID(plugin, params) {
	if (params != 1) {
		zp_logError(AMX_ERR_NATIVE, "Invalid params passed: %d - Expected: 1", params);
		return ZP_HANDMODEL:NULL;
	}
	
	new szModel[handmodel_szName_length+1], iModel;
	get_string(1, szModel, handmodel_szName_length);
	strtolower(szModel);
	for (new i; i < 2; i++) {
		if (g_modelTrie == Invalid_Trie || g_modelList == Invalid_Array) {
			zp_logError(AMX_ERR_NATIVE, "Cannot search for player model (^"%s^")", szModel);
			return ZP_HANDMODEL:NULL;
		}
		
		if (TrieGetCell(g_modelTrie, szModel, iModel)) {
			return ZP_HANDMODEL:iModel;
		}
	}

	return ZP_HANDMODEL:NULL;
}

public ZP_RETURN:_getHandModelName(plugin, params) {
	if (params != 3) {
		zp_logError(AMX_ERR_NATIVE, "Invalid params passed: %d - Expected: 4", params);
		return ZP_ERROR;
	}

	new ZP_HANDMODEL:iModel = ZP_HANDMODEL:get_param(1);
	new szModelName[handmodel_szName_length+1];
	new iLen = get_param(3);
	if (g_modelList == Invalid_Array) {
		zp_logError(AMX_ERR_NATIVE, "Cannot search for hand model (%d)", iModel);
		return ZP_ERROR;
	} else if (iModel == ZP_HANDMODEL:NULL) {
		set_string(2, g_szBaseHandModel, iLen);
		return ZP_SUCCESS;
	} else if (!_isValidHandModel(iModel)) {
		return ZP_ERROR;
	}
	
	ArrayGetString(g_modelList, _:iModel, szModelName, iLen);
	set_string(2, szModelName, iLen);
	return ZP_SUCCESS;
}

public bool:_isValidHandModel(ZP_HANDMODEL:model) {
	return !(_:model < 0 || g_modelNum <= _:model);
}