#include "include/zombieplague7.inc"
#include "include/zp7/zp_classes_const.inc"

#include <cvar_util>

#define VERSION "0.0.1"

#define flag_get_bool(%1,%2)	!!(flag_get(%1,%2))
#define flag_get(%1,%2)			(%1 &   (1 << (%2 & 31)))
#define flag_set(%1,%2)			(%1 |=  (1 << (%2 & 31)))
#define flag_unset(%1,%2)		(%1 &= ~(1 << (%2 & 31)))

static g_fwReturn, g_fwClassLoaded, g_fwAbilityRegistered, g_fwClassRegistered, g_fwGroupRegistered, g_fwRequestCost;
static g_pCvar_AdminMode, g_pCvar_XPMode, g_pCvar_ClassLimits;

public Array:g_abilityList;
static Trie:g_abilityTrie;
static g_abilityNum;

public Array:g_classList;
static Trie:g_classTrie;
static g_classNum;

public Array:g_groupList;
static Trie:g_groupTrie;
static g_groupNum;

public Array:g_zombieGroupList;
public Array:g_humanGroupList;

static g_tempAbility[ability_t];
static g_tempClass[class_t];
static g_tempGroup[group_t];

static ZP_CLASS:g_curClass[MAX_PLAYERS+1] = { ZP_CLASS:NULL, ... };
static ZP_CLASS:g_nextClass[MAX_PLAYERS+1] = { ZP_CLASS:NULL, ... };

#define CLASS_ABILITIES		0
#define CLASS_FILESYSTEM	1
#define CLASS_REGISTERABLE	2
#define CLASS_CANTREGISTER	3
static g_registerMode;

public zp_fw_core_zombiePlagueInitPre() {
	g_abilityList = ArrayCreate(ability_t, 8);
	g_abilityTrie = TrieCreate();
	
	g_classList = ArrayCreate(class_t, 8);
	g_classTrie = TrieCreate();
	
	g_groupList = ArrayCreate(group_t, 2);
	g_groupTrie = TrieCreate();
	
	g_zombieGroupList = ArrayCreate(1, 1);
	g_humanGroupList = ArrayCreate(1, 1);
}

public zp_fw_core_zombiePlagueInit() {
	server_print("ZP Class Module loaded");

	g_fwAbilityRegistered	= CreateMultiForward("zp_fw_class_abilityRegistered", ET_CONTINUE, FP_CELL);
	g_fwClassRegistered		= CreateMultiForward("zp_fw_class_classRegistered", ET_CONTINUE, FP_CELL);
	g_fwGroupRegistered		= CreateMultiForward("zp_fw_class_groupRegistered", ET_CONTINUE, FP_CELL);
	
	g_registerMode = CLASS_ABILITIES;
	new fwRegisterAbilities = CreateMultiForward("zp_fw_class_registerAbilities", ET_CONTINUE);
	ExecuteForward(fwRegisterAbilities, g_fwReturn);
	DestroyForward(fwRegisterAbilities);
	
	g_registerMode = CLASS_FILESYSTEM;
	new classFileSystemPlugin = find_plugin_byfile("zp_classes_filesystem.amxx", 1);
	new fwRegisterClassesPre = CreateOneForward(classFileSystemPlugin, "zp_fw_class_registerClassesPre");
	ExecuteForward(fwRegisterClassesPre, g_fwReturn);
	DestroyForward(fwRegisterClassesPre);
	
	g_registerMode = CLASS_REGISTERABLE;
	new fwRegisterClasses = CreateMultiForward("zp_fw_class_registerClasses", ET_CONTINUE);
	ExecuteForward(fwRegisterClasses, g_fwReturn);
	DestroyForward(fwRegisterClasses);
	g_registerMode = CLASS_CANTREGISTER;
}

public zp_fw_command_registerCommands() {
	zp_command_register("currentclass",	"cmdCurrentClass", _, "Displays your current class");
	zp_command_register("curclass",		"cmdCurrentClass");
	
	zp_command_register("nextclass",	"cmdNextClass", _, "Displays your next class");
}

public cmdCurrentClass(id) {
	if (g_curClass[id] == ZP_CLASS:NULL) {
		zp_printColor(id, "Your current class: ^4None");
	} else {
		ArrayGetArray(g_classList, _:g_curClass[id], g_tempClass);
		zp_printColor(id, "Your current class: ^4%s", g_tempClass[class_szName]);
	}
}

public cmdNextClass(id) {
	if (g_nextClass[id] == ZP_CLASS:NULL) {
		zp_printColor(id, "Your next class: ^4None");
	} else {
		ArrayGetArray(g_classList, _:g_nextClass[id], g_tempClass);
		zp_printColor(id, "Your next class: ^4%s", g_tempClass[class_szName]);
	}
}

public plugin_init() {
	register_plugin("[ZP7] Classes", VERSION, "Tirant");
	
	register_concmd("classes.dump", "dumpClassInfo");
	
	g_pCvar_AdminMode = CvarRegister("zp_classes_adminMode", "1", _, _, true, 0.0, true, 1.0);
	CvarCache(g_pCvar_AdminMode, CvarType_Int, g_pCvar_AdminMode);
	
	g_pCvar_XPMode = CvarRegister("zp_classes_xpMode", "1", _, _, true, 0.0, true, 1.0);
	CvarCache(g_pCvar_XPMode, CvarType_Int, g_pCvar_XPMode);	
	
	g_pCvar_ClassLimits = CvarRegister("zp_classes_classLimits", "0", _, _, true, 0.0, true, 1.0);
	CvarCache(g_pCvar_ClassLimits, CvarType_Int, g_pCvar_ClassLimits);
	
	g_fwClassLoaded		= CreateMultiForward("zp_fw_class_classLoaded", ET_IGNORE, FP_CELL, FP_CELL);
	g_fwRequestCost		= CreateMultiForward("zp_fw_class_requestCosts", ET_CONTINUE, FP_CELL, FP_CELL, FP_CELL);
}

public plugin_natives() {
	register_library("ZP_Classes");
	
	register_native("zp_class_registerAbility",			"_registerAbility",			0);
	register_native("zp_class_registerAbility2",		"_registerAbility2",		0);
	register_native("zp_class_registerClass",			"_registerClass",			0);
	register_native("zp_class_registerGroup",			"_registerGroup",			0);
	
	register_native("zp_class_getAbilityFromName",		"_getAbilityFromName",		0);
	register_native("zp_class_getClassFromName",		"_getClassFromName",		0);
	register_native("zp_class_getGroupFromName",		"_getGroupFromName",		0);
	
	register_native("zp_class_addAbilityToClass",		"_addAbilityToClass",		1);
	register_native("zp_class_addClassToGroup",			"_addClassToGroup",			1);
	register_native("zp_class_addGroupToType",			"_addGroupToType",			1);
	
	register_native("zp_class_removeAbilityFromClass",	"_removeAbilityFromClass",	1);
	register_native("zp_class_removeClassFromGroup",	"_removeClassFromGroup",	1);
	register_native("zp_class_removeGroupFromType",		"_removeGroupFromType",		1);
	
	register_native("zp_class_classHasAbility",			"_classHasAbility",			1);
	
	register_native("zp_class_isValidAbility",			"_isValidAbility",			1);
	register_native("zp_class_isValidClass",			"_isValidClass",			1);
	register_native("zp_class_isValidGroup",			"_isValidGroup",			1);
	register_native("zp_class_isZombieClass",			"_isZombieClass",			1);
	register_native("zp_class_isHumanClass",			"_isHumanClass",			1);
	
	register_native("zp_class_getUserClass",			"_getUserClass",			1);
	register_native("zp_class_setUserClass",			"_setUserClass",			1);
	register_native("zp_class_getUserNextClass",		"_getUserNextClass",		1);
	register_native("zp_class_setUserNextClass",		"_setUserNextClass",		1);
	
	register_native("zp_class_getClassNum",				"_getClassNum",				1);
	register_native("zp_class_getGroupNum",				"_getGroupNum",				1);
	
	register_native("zp_class_canUseClass",				"_canUseClass",				1);
}

public client_putinserver(id) {
}

public client_disconnect(id) {
	resetEvent(id)
}

public zp_fw_core_infect_post(id, infector) {
	resetEvent(id)
}

public zp_fw_core_cure_post(id, curer) {
	resetEvent(id)
}

resetEvent(id) {
	g_curClass[id] = ZP_CLASS:NULL;
	g_nextClass[id] = ZP_CLASS:NULL;
}

public dumpClassInfo(id) {
	console_print(id, "Dumping class info...");
	console_print(id, "Groups: %d", g_groupNum);
	console_print(id, "Classes: %d", g_classNum);
	
	new Array:classList, classNum;
	new Array:abilityList, abilityNum;
	for (new i; i < g_groupNum; i++) {
		ArrayGetArray(g_groupList, i, g_tempGroup);
		console_print(id, "%s", g_tempGroup[group_szName]);
		classList = _group_t_getClassList(g_tempGroup);
		classNum = ArraySize(classList);
		if (!classNum) {
			console_print(id, "    NULL");
			continue;
		}
		
		for (new j; j < classNum; j++) {
			ArrayGetArray(g_classList, ArrayGetCell(classList, j), g_tempClass);
			if (g_pCvar_ClassLimits) {
				if (g_tempClass[class_iMaxNumber]) {
					console_print(id, "    %d. %s [%d/%d]", (j+1), g_tempClass[class_szName], g_tempClass[class_iCurNumber], g_tempClass[class_iMaxNumber]);
				} else {
					console_print(id, "    %d. %s [%d/%c]", (j+1), g_tempClass[class_szName], g_tempClass[class_iCurNumber], 236);
				}
			} else {
				console_print(id, "    %d. %s", (j+1), g_tempClass[class_szName]);
			}
			
			abilityList = _class_t_getAbilityList(g_tempClass);
			abilityNum = ArraySize(abilityList);
			if (!abilityNum) {
				console_print(id, "        NULL");
				continue;
			}
			
			for (new x; x < abilityNum; x++) {
				ArrayGetArray(g_abilityList, ArrayGetCell(abilityList, x), g_tempAbility);
				console_print(id, "        %c. %s", 65+x, g_tempAbility[ability_szName]);
			}
		}
	}
	
	console_print(id, "--- DONE ---");
	return PLUGIN_HANDLED;
}

public zp_fw_core_refresh(id, bool:isZombie) {
	if (g_nextClass[id] == ZP_CLASS:NULL) {
		return;
	}
	
	if (_isZombieClass(g_nextClass[id]) != isZombie && _isHumanClass(g_nextClass[id]) != isZombie) {
		g_curClass[id] = ZP_CLASS:NULL;
		g_nextClass[id] = ZP_CLASS:NULL;
		return;
	}
	
	g_pCvar_ClassLimits && _class_t_getMaxNumber(g_tempClass);
	
	if (!_canUseClass(id, g_nextClass[id])) {
		return;
	}
	
	ArrayGetArray(g_classList, _:g_curClass[id], g_tempClass);
	_class_t_setCurNumber(g_tempClass, _class_t_getCurNumber(g_tempClass)-1, true);
	
	g_curClass[id] = g_nextClass[id];
	ArrayGetArray(g_classList, _:g_curClass[id], g_tempClass);
	zp_core_setUserModel(id,	_class_t_getModel(g_tempClass));
	zp_core_setUserHealth(id,	floatround(_class_t_getHealth(g_tempClass)));
	zp_core_setUserMaxspeed(id,	_class_t_getMaxspeed(g_tempClass));
	zp_core_setUserGravity(id,	_class_t_getGravity(g_tempClass));
	
	_class_t_setCurNumber(g_tempClass, _class_t_getCurNumber(g_tempClass)+1, true);
	
	ExecuteForward(g_fwClassLoaded, g_fwReturn, id, g_nextClass[id]);
}

public ZP_ABILITY:_registerAbility(plugin, params) {
	if (params != 1) {
		zp_logError(AMX_ERR_NATIVE, "Invalid params passed: %d - Expected: 1", params);
		return ZP_ABILITY:NULL;
	}

	get_array(1, g_tempAbility, ability_t);
	if (g_registerMode != CLASS_ABILITIES || g_abilityTrie == Invalid_Trie || g_abilityList == Invalid_Array) {
		zp_logError(AMX_ERR_NATIVE, "Cannot register abilities yet");
		return ZP_ABILITY:NULL;
	}
	
	new szTemp[ability_szName_length+1], i;
	_ability_t_getName(g_tempAbility, szTemp, ability_szName_length);
	strtolower(szTemp);
	if (TrieGetCell(g_abilityTrie, szTemp, i)) {
		return ZP_ABILITY:i;
	}
		
	ArrayPushArray(g_abilityList, g_tempAbility);
	TrieSetCell(g_abilityTrie, szTemp, g_abilityNum);
	g_abilityNum++;
	if (g_registerMode == CLASS_REGISTERABLE) {
		ExecuteForward(g_fwAbilityRegistered, g_fwReturn, g_abilityNum-1);
	}
	
	return ZP_ABILITY:(g_abilityNum-1);
}

public ZP_ABILITY:_registerAbility2(plugin, params) {
	if (params != 3) {
		zp_logError(AMX_ERR_NATIVE, "Invalid params passed: %d - Expected: 3", params);
		return ZP_ABILITY:NULL;
	}
	
	if (g_registerMode != CLASS_ABILITIES || g_abilityTrie == Invalid_Trie || g_abilityList == Invalid_Array) {
		zp_logError(AMX_ERR_NATIVE, "Cannot register abilities yet");
		return ZP_ABILITY:NULL;
	}

	new szTemp[ability_szName_length+1], i;
	_ability_t_default(g_tempAbility);
	get_string(1, g_tempAbility[ability_szName], ability_szName_length);
	_ability_t_getName(g_tempAbility, szTemp, ability_szName_length);
	strtolower(szTemp);
	if (TrieGetCell(g_abilityTrie, szTemp, i)) {
		return ZP_ABILITY:i;
	}
	
	get_string(2, g_tempAbility[ability_szDesc], ability_szDesc_length);
	g_tempAbility[ability_iCost] = get_param(3);
	
	ArrayPushArray(g_abilityList, g_tempAbility);
	TrieSetCell(g_abilityTrie, szTemp, g_abilityNum);
	g_abilityNum++;
	if (g_registerMode == CLASS_REGISTERABLE) {
		ExecuteForward(g_fwAbilityRegistered, g_fwReturn, g_abilityNum-1);
	}
	
	return ZP_ABILITY:(g_abilityNum-1);
}

public ZP_CLASS:_registerClass(plugin, params) {
	if (params != 1) {
		zp_logError(AMX_ERR_NATIVE, "Invalid params passed: %d - Expected: 1", params);
		return ZP_CLASS:NULL;
	}
	
	if (!g_registerMode || g_classTrie == Invalid_Trie || g_classList == Invalid_Array) {
		zp_logError(AMX_ERR_NATIVE, "Cannot register classes yet");
		return ZP_CLASS:NULL;
	}

	get_array(1, g_tempClass, class_t);
	new szTemp[class_szName_length+1], i;
	copy(szTemp, class_szName_length, g_tempClass[class_szName]);
	strtolower(szTemp);
	if (TrieGetCell(g_classTrie, szTemp, i)) {
		return ZP_CLASS:i;
	}
	
	ArrayPushArray(g_classList, g_tempClass);
	TrieSetCell(g_classTrie, szTemp, g_classNum);
	g_classNum++;
	if (g_registerMode == CLASS_REGISTERABLE) {
		ExecuteForward(g_fwClassRegistered, g_fwReturn, g_classNum-1);
	}
	
	return ZP_CLASS:(g_classNum-1);
}

public ZP_GROUP:_registerGroup(plugin, params) {
	if (params != 1) {
		zp_logError(AMX_ERR_NATIVE, "Invalid params passed: %d - Expected: 1", params);
		return ZP_GROUP:NULL;
	}
	
	get_array(1, g_tempGroup, group_t);
	if (!g_registerMode || g_groupTrie == Invalid_Trie || g_groupList == Invalid_Array) {
		zp_logError(AMX_ERR_NATIVE, "Cannot register group yet (^"%s^")", g_tempGroup[group_szName]);
		return ZP_GROUP:NULL;
	}
	
	new szTemp[group_szName_length+1], i;
	copy(szTemp, group_szName_length, g_tempGroup[group_szName]);
	strtolower(szTemp);
	if (TrieGetCell(g_groupTrie, szTemp, i)) {
		return ZP_GROUP:i;
	}
	
	g_tempGroup[group_ID] = g_groupNum;
	ArrayPushArray(g_groupList, g_tempGroup);
	TrieSetCell(g_groupTrie, szTemp, g_groupNum);
	g_groupNum++;
	if (g_registerMode == CLASS_REGISTERABLE) {
		ExecuteForward(g_fwGroupRegistered, g_fwReturn, g_groupNum-1);
	}
	
	return ZP_GROUP:(g_groupNum-1);
}

public bool:_addAbilityToClass(ZP_ABILITY:ability, ZP_CLASS:class) {
	assert _isValidAbility(ability) && _isValidClass(class);
	ArrayGetArray(g_classList, _:class, g_tempClass);
	new Array:abilityList = _class_t_getAbilityList(g_tempClass);
	new abilityNum = ArraySize(abilityList);
	for (new i; i < abilityNum; i++) {
		if (ZP_ABILITY:ArrayGetCell(abilityList, i) == ability) {
			return false;
		}
	}
	
	ArrayPushCell(abilityList, _:ability);
	new Array:abilityBits = _class_t_getAbilityBits(g_tempClass);
	if (ArraySize(abilityBits) <= _:ability/cellbits) {
		ArrayPushCell(abilityBits, 0);
	}
	
	new cell = ArrayGetCell(abilityBits, _:ability/cellbits);
	flag_set(cell, _:ability%cellbits);
	ArraySetCell(abilityBits, _:ability/cellbits, cell);
	return true;
}

public bool:_addClassToGroup(ZP_CLASS:class, ZP_GROUP:group) {
	assert _isValidClass(class) && _isValidGroup(group);
	ArrayGetArray(g_classList, _:class, g_tempClass);
	ArrayGetArray(g_groupList, _:group, g_tempGroup);
	new Array:classList = _group_t_getClassList(g_tempGroup);
	new classNum = ArraySize(classList);
	for (new i; i < classNum; i++) {
		if (ZP_CLASS:ArrayGetCell(classList, i) == class) {
			return false;
		}
	}
	
	_class_t_setZombieClass(g_tempClass, g_tempGroup[group_isZombieGroup]);
	ArrayPushCell(classList, _:class);
	ArraySetArray(g_classList, _:class, g_tempClass);
	return true;
}

public bool:_addGroupToType(ZP_GROUP:group, bool:isZombieGroup) {
	assert _isValidGroup(group);
	ArrayGetArray(g_groupList, _:group, g_tempGroup);
	_removeGroupFromType(group);
	
	new Array:typeList = isZombieGroup ? g_zombieGroupList : g_humanGroupList;
	new typeNum = ArraySize(typeList);
	for (new i; i < typeNum; i++) {
		if (ZP_GROUP:ArrayGetCell(typeList, i) == group) {
			return false;
		}
	}
	
	ArrayPushCell(typeList, _:group);
	_group_t_setZombieGroup(g_tempGroup, isZombieGroup);
	ArraySetArray(g_groupList, _:group, g_tempGroup);
	return true;
}

public bool:_removeAbilityFromClass(ZP_ABILITY:ability, ZP_CLASS:class) {
	assert _isValidAbility(ability) && _isValidClass(class);
	ArrayGetArray(g_classList, _:class, g_tempClass);
	
	new Array:abilityList = _class_t_getAbilityList(g_tempClass);
	new Array:abilityBits = _class_t_getAbilityBits(g_tempClass);
	new abilityNum = ArraySize(abilityList);
	for (new i; i < abilityNum; i++) {
		if (ZP_ABILITY:ArrayGetCell(abilityList, i) == ability) {
			ArrayDeleteItem(abilityList, i);
			new cell = ArrayGetCell(abilityBits, _:ability/cellbits);
			flag_unset(cell, _:ability%cellbits);
			ArraySetArray(g_classList, _:class, g_tempClass);
			return true;
		}
	}
	
	return false;
}

public bool:_removeClassFromGroup(ZP_CLASS:class, ZP_GROUP:group) {
	assert _isValidClass(class) && _isValidGroup(group);
	new Array:classList = _group_t_getClassList(g_tempGroup);
	ArrayGetArray(g_groupList, _:group, g_tempGroup);
	new classNum = ArraySize(classList);
	for (new i; i < classNum; i++) {
		if (ZP_CLASS:ArrayGetCell(classList, i) == class) {
			ArrayDeleteItem(classList, i);
			return true;
		}
	}
	
	return false;
}

public bool:_removeGroupFromType(ZP_GROUP:group) {
	assert _isValidGroup(group);
	ArrayGetArray(g_groupList, _:group, g_tempGroup);
	new Array:groupList = _group_t_getZombieGroup(g_tempGroup) ? g_zombieGroupList : g_humanGroupList;
	new groupNum = ArraySize(groupList);
	for (new i; i < groupNum; i++) {
		if (ZP_GROUP:ArrayGetCell(groupList, i) == group) {
			ArrayDeleteItem(groupList, i);
			return true;
		}
	}
	
	return false;
}

public bool:_isValidAbility(ZP_ABILITY:ability) {
	return !(_:ability < 0 || g_abilityNum <= _:ability);
}

public bool:_isValidClass(ZP_CLASS:class) {
	return !(_:class < 0 || g_classNum <= _:class);
}

public bool:_isValidGroup(ZP_GROUP:group) {
	return !(_:group < 0 || g_groupNum <= _:group);
}

public bool:_isZombieClass(ZP_CLASS:class) {
	if (!_isValidClass(class)) {
		return false;
	}
	
	ArrayGetArray(g_classList, _:class, g_tempClass);
	return bool:_class_t_getZombieClass(g_tempClass);
}

public bool:_isHumanClass(ZP_CLASS:class) {
	if (!_isValidClass(class)) {
		return false;
	}
	
	ArrayGetArray(g_classList, _:class, g_tempClass);
	return !bool:_class_t_getZombieClass(g_tempClass);
}

public ZP_CLASS:_getUserClass(id) {
	assert isValidPlayer(id);
	return g_curClass[id];
}

public ZP_CLASS:_setUserClass(id, ZP_CLASS:class) {
	assert isValidPlayer(id) && _isValidClass(class);
	new ZP_CLASS:oldClass = g_curClass[id];
	_setUserNextClass(id, class);
	zp_core_refresh(id);
	return oldClass;
}

public ZP_CLASS:_getUserNextClass(id) {
	assert isValidPlayer(id);
	return g_nextClass[id];
}

public ZP_CLASS:_setUserNextClass(id, ZP_CLASS:class) {
	assert isValidPlayer(id) && _isValidClass(class);
	if (zp_core_isUserZombie(id) != _isZombieClass(class) && zp_core_isUserZombie(id) != _isHumanClass(class)) {
		zp_logError(AMX_ERR_NATIVE, "Player state does not match class");
		return ZP_CLASS:NULL;
	}
	
	new ZP_CLASS:oldClass = g_nextClass[id];
	g_nextClass[id] = class;
	return oldClass;
}

public bool:_classHasAbility(ZP_CLASS:class, ZP_ABILITY:ability) {
	assert _isValidClass(class) && _isValidAbility(ability);
	ArrayGetArray(g_classList, _:class, g_tempClass);
	new Array:abilityBits = _class_t_getAbilityBits(g_tempClass);
	new cell = ArrayGetCell(abilityBits, _:ability/cellbits);
	return flag_get_bool(cell, _:ability%cellbits);
}

public _getClassNum() {
	return g_classNum;
}

public _getGroupNum() {
	return g_groupNum;
}

public ZP_ABILITY:_getAbilityFromName(plugin, params) {
	if (params != 1) {
		zp_logError(AMX_ERR_NATIVE, "Invalid params passed: %d - Expected: 1", params);
		return ZP_ABILITY:NULL;
	}

	if (g_abilityTrie == Invalid_Trie) {
		zp_logError(AMX_ERR_NATIVE, "Cannot look up abilities yet");
		return ZP_ABILITY:NULL;
	}
	
	new szAbilityName[ability_szName_length+1], i;
	get_string(1, szAbilityName, ability_szName_length);
	strtolower(szAbilityName);
	if (TrieGetCell(g_abilityTrie, szAbilityName, i)) {
		return ZP_ABILITY:i;
	}
	
	return ZP_ABILITY:NULL;
}

public ZP_CLASS:_getClassFromName(plugin, params) {
	if (params != 1) {
		zp_logError(AMX_ERR_NATIVE, "Invalid params passed: %d - Expected: 1", params);
		return ZP_CLASS:NULL;
	}
	
	if (g_classTrie == Invalid_Trie) {
		zp_logError(AMX_ERR_NATIVE, "Cannot look up classes yet");
		return ZP_CLASS:NULL;
	}
	
	new szClassName[class_szName_length+1], i;
	get_string(1, szClassName, class_szName_length);
	strtolower(szClassName);
	if (TrieGetCell(g_classTrie, szClassName, i)) {
		return ZP_CLASS:i;
	}
	
	return ZP_CLASS:NULL;
}

public ZP_GROUP:_getGroupFromName(plugin, params) {
	if (params != 1) {
		zp_logError(AMX_ERR_NATIVE, "Invalid params passed: %d - Expected: 1", params);
		return ZP_GROUP:NULL;
	}
	
	if (g_groupTrie == Invalid_Trie) {
		zp_logError(AMX_ERR_NATIVE, "Cannot look up groups yet");
		return ZP_GROUP:NULL;
	}
	
	new szGroupName[group_szName_length+1], i;
	get_string(1, szGroupName, group_szName_length);
	strtolower(szGroupName);
	if (TrieGetCell(g_groupTrie, szGroupName, i)) {
		return ZP_GROUP:i;
	}
	
	return ZP_GROUP:NULL;
}

public bool:_canUseClass(id, ZP_CLASS:class) {
	assert _isValidClass(class);
	ArrayGetArray(g_classList, _:class, g_tempClass);
	if (g_pCvar_ClassLimits && _class_t_getMaxNumber(g_tempClass)) {
		if (_class_t_getCurNumber(g_tempClass) >= _class_t_getMaxNumber(g_tempClass)) {
			zp_printColor(id, "The number of users using this class has reached its' limit. ^1(^4%s^1)", g_tempClass[class_szName]);
			return false;
		}
	}
	
	if (g_pCvar_XPMode) {
		new iXPCost = _class_t_getCost(g_tempClass);
		ExecuteForward(g_fwRequestCost, g_fwReturn, id, class, iXPCost);
		if (g_fwReturn < iXPCost) {
			zp_printColor(id, "You do not have the required experience for this class. ^1(^4%s^1)", g_tempClass[class_szName]);
			return false;
		}
	}
	
	if (g_pCvar_AdminMode && !access(id, _class_t_getAdminFlags(g_tempClass))) {
		new szFlags[27];
		get_flags(_class_t_getAdminFlags(g_tempClass), szFlags, 26);
		zp_printColor(id, "You do not have the required access level for this class. ^1('^4%s^1')", szFlags);
		return false;
	}
	
	return true;
}