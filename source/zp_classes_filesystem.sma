#include "include/zombieplague7.inc"
#include "include/zp7/zp_classes.inc"
#include "include/zp7/zp_classes_files_const.inc"

#define VERSION "0.0.1"

#define flag_get_bool(%1,%2)	!!(flag_get(%1,%2))
#define flag_get(%1,%2)			(%1 &   (1 << (%2 & 31)))
#define flag_set(%1,%2)			(%1 |=  (1 << (%2 & 31)))
#define flag_unset(%1,%2)		(%1 &= ~(1 << (%2 & 31)))

enum _:keys_t {
	ck_isZombieClass,		// Is it?
	ck_inheritingClass,		// The class inheriting this one
	ck_szName,				// Name
	ck_szDesc,				// Description
	ck_fHealth,				// Health
	ck_fMaxspeed,			// Maxspeed
	ck_fGravity,			// Gravity
	ck_model,				// Model
	ck_abilityList,			// Ability list
	ck_abilityBits,			// Ability bitsums
	ck_bNoFallDamage,		// No fall damage
	ck_fKnockback,			// Knockback multiplier
	ck_iCost,				// Cost
	ck_iAdminFlags,			// Admin flags
	ck_iCurNumber,			// Current number
	ck_iMaxNumber			// Max Number
}

stock const _keyNames[keys_t][] = {
	"ZOMBIE",
	"INHERITOR",
	"NAME",
	"DESCRIPTION",
	"HEALTH",
	"SPEED",
	"GRAVITY",
	"MODEL",
	"ABILITIES",
	"NULL",
	"FALLDAMAGE",
	"KNOCKBACK",
	"COST",
	"ADMIN FLAGS",
	"CUR NUM",
	"MAX NUM"
}

static Trie:g_keyList;
static g_szHomeFolder[128];

const class_szFilename_length = class_szName_length+3;

static const _szTeamNames[][] = {
	"humans",
	"zombies"
}

static g_fwReturn, g_fwReadKey, g_fwWriteKey;

static Array:g_abilityList;
static Array:g_classList;
static Array:g_groupList;

static g_tempAbility[ability_t];
static g_tempClass[class_t];
static g_tempGroup[group_t];

public zp_fw_core_zombiePlagueInit() {
	server_print("ZP Class Filesystem Module loaded");
}

public plugin_init() {
	register_plugin("[ZP7] Classes (Filesystem Module)", VERSION, "Tirant");
}

public plugin_natives() {
	register_library("ZP_FileSystem");
	
	register_native("zp_class_createFileForClass", "_createFileForClass", 0);
}

public plugin_end() {
	server_print(">   Saving classes within file system...");
	new classSize, Array:classList, ZP_CLASS:class;
	new groupSize = zp_class_getGroupNum();
	for (new i; i < groupSize; i++) {
		ArrayGetArray(g_groupList, i, g_tempGroup);
		server_print(">   %d. %s", i+1, g_tempGroup[group_szName]);
		_createDefaultClassForGroup(ZP_GROUP:i);
		classList = g_tempGroup[group_classList];
		classSize = ArraySize(classList);
		for (new j; j < classSize; j++) {
			class = ZP_CLASS:ArrayGetCell(classList, j);
			ArrayGetArray(g_classList, _:class, g_tempClass);
			server_print(">       %c. %s", 65+j, g_tempClass[class_szName]);
			_createFileForClass(class, ZP_GROUP:i);
		}
	}
}

public zp_fw_class_registerClassesPre() {
	new len = zp_getHomeDir(g_szHomeFolder, 127);
	len += copy(g_szHomeFolder[len], 127, ZP_CLASS_FOLDER);
	
	new abilityListID = get_xvar_id("g_abilityList");
	if (abilityListID == -1) {
		zp_logError(AMX_ERR_GENERAL, "Cannot find ability list");
		set_fail_state("Cannot find ability list");
	}
	
	g_abilityList = Array:get_xvar_num(abilityListID);
	
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
	
	g_keyList = TrieCreate();
	for (new i; i < keys_t; i++) {
		TrieSetCell(g_keyList, _keyNames[i], i);
	}
	
	g_fwReadKey		= CreateMultiForward("zp_fw_class_file_readKey", ET_IGNORE, FP_STRING, FP_STRING, FP_STRING);
	g_fwWriteKey	= CreateMultiForward("zp_fw_class_file_writeKey", ET_IGNORE, FP_STRING, FP_CELL);
	
	cacheClassFiles();
}

cacheClassFiles() {
	new szZPClassDir[128];
	new lenBase = zp_getHomeDir(szZPClassDir, 127);
	lenBase += copy(szZPClassDir[lenBase], 127, ZP_CLASS_FOLDER);
	mkdir(szZPClassDir);
	
	new classCounter;
	new classCache[512];
	new tempCache[64], ZP_GROUP:group;
	new szFileName[class_szFilename_length+1];
	new lenTeam, lenGroup, lenClass, lenDefaultClass;
	new baseDirHandle, groupDirHandle;
	server_print(">   Caching classes within file system...");
	for (new i; i < 2; i++) {
		lenTeam = lenBase + copy(szZPClassDir[lenBase], 127, _szTeamNames[i]);
		szZPClassDir[lenTeam] = '^0';
		mkdir(szZPClassDir);
		baseDirHandle = open_dir(szZPClassDir, szFileName, class_szFilename_length);
		while (next_file(baseDirHandle, szFileName, class_szFilename_length)) {
			lenGroup = lenTeam + formatex(szZPClassDir[lenTeam], 127, "/%s", szFileName);
			szZPClassDir[lenGroup] = '^0';
			if (!dir_exists(szZPClassDir) || contain(szZPClassDir, "..") != -1) {
				continue;
			}
			
			lenGroup += copy(szZPClassDir[lenGroup], 127, "/");
			formatex(tempCache, 63, "(Default) %s", szFileName);
			lenDefaultClass = lenGroup + formatex(szZPClassDir[lenGroup], 127, "%s%s", tempCache, ZP_GROUP_EXT);
			szZPClassDir[lenDefaultClass] = '^0';
			if (file_exists(szZPClassDir)) {
				szZPClassDir[lenGroup] = '^0';
				server_print(">  Found %s", tempCache);
				cacheDefaultClassFromFile(bool:i, szZPClassDir, tempCache, classCache);
			} else {
				_group_t_default(g_tempGroup);
			}
			
			if (i) {
				group = zp_class_createZGroup2(g_tempGroup);
			} else {
				group = zp_class_createHGroup2(g_tempGroup);
			}
			
			if (!zp_class_isValidGroup(group)) {
				continue;
			}
			
			szZPClassDir[lenGroup] = '^0';
			groupDirHandle = open_dir(szZPClassDir, szFileName, class_szFilename_length);
			while (next_file(groupDirHandle, szFileName, class_szFilename_length)) {
				lenClass = lenGroup + copy(szZPClassDir[lenGroup], 127, szFileName);
				szZPClassDir[lenClass] = '^0';
				if (!file_exists(szZPClassDir)) {
					continue;
				}

				replace(szZPClassDir[lenGroup], class_szFilename_length, ZP_CLASS_EXT, "");
				server_print(">   %d. %s", ++classCounter, szZPClassDir[lenGroup]);
				cacheClassFromFile(bool:i, group, szZPClassDir[lenGroup], szZPClassDir, classCache);
			}
			close_dir(groupDirHandle);
		}
		close_dir(baseDirHandle);
	}
}

cacheDefaultClassFromFile(bool:isZombie, path[], name[], classCache[]) {
	_group_t_default(g_tempGroup);
	
	new ZP_ABILITY:ability;
	new key[32], i;
	new file = fopen(path, "rt");
	while (!feof(file)) {
		fgets(file, classCache, 511);
		
		replace(classCache, 511, "^n", "");
		if (!classCache[0] || classCache[0] == ';') {
			continue;
		}
		
		strtok(classCache, key, 31, classCache, 511, '=');
		trim(key);
		trim(classCache);
		
		if (TrieGetCell(g_keyList, key, i)) {
			switch (i) {
				case ck_isZombieClass: {
					// Not allowed to change, bound to group
				}
				case ck_inheritingClass: {
					// Not allowed to change
				}
				case ck_szName: {
					// Not allowed to change, but rename file if internal change
				}
				case ck_szDesc: {
					// Not allowed to change
				}
				case ck_fHealth: {
					g_tempGroup[group_defaultClass][class_fHealth] = _:str_to_float(classCache);
				}
				case ck_fMaxspeed: {
					g_tempGroup[group_defaultClass][class_fMaxspeed] = _:str_to_float(classCache);
				}
				case ck_fGravity: {
					g_tempGroup[group_defaultClass][class_fGravity] = _:str_to_float(classCache);
				}
				case ck_model: {
					g_tempGroup[group_defaultClass][class_model] = zp_core_registerModel(isZombie, classCache);
				}
				case ck_abilityList: {
					while (classCache[0] != '^0' && strtok(classCache, key, 31, classCache, 511, ',')) {
						trim(key);
						ability = zp_class_getAbilityFromName(key);
						new Array:abilityList = g_tempGroup[group_defaultClass][class_abilityList];
						new abilityNum = ArraySize(abilityList), bool:shouldContinue;
						for (new i; i < abilityNum; i++) {
							if (ZP_ABILITY:ArrayGetCell(abilityList, i) == ability) {
								shouldContinue = true;
								break;
							}
						}
						
						if (shouldContinue) {
							continue;
						}
						
						ArrayPushCell(abilityList, _:ability);
						new Array:abilityBits = g_tempGroup[group_defaultClass][class_abilityBits];
						if (ArraySize(abilityBits) <= _:ability/cellbits) {
							ArrayPushCell(abilityBits, 0);
						}
						
						new cell = ArrayGetCell(abilityBits, _:ability/cellbits);
						flag_set(cell, _:ability%cellbits);
						ArraySetCell(abilityBits, _:ability/cellbits, cell);
					}
				}
				case ck_bNoFallDamage: {
					g_tempGroup[group_defaultClass][class_bNoFallDamage] = bool:equali(classCache, "true");
				}
				case ck_fKnockback: {
					g_tempGroup[group_defaultClass][class_fKnockback] = _:str_to_float(classCache);
				}
				case ck_iCost: {
					g_tempGroup[group_defaultClass][class_iCost] = str_to_num(classCache);
				}
				case ck_iAdminFlags: {
					g_tempGroup[group_defaultClass][class_iAdminFlags] = read_flags(classCache);
				}
				case ck_iCurNumber: {
					g_tempGroup[group_defaultClass][class_iCurNumber] = 0;
				}
				case ck_iMaxNumber: {
					g_tempGroup[group_defaultClass][class_iMaxNumber] = str_to_num(classCache);
				}
			}
		} else {
			ExecuteForward(g_fwReadKey, g_fwReturn, name, key, classCache);
		}
	}
	fclose(file);
}

public _createDefaultClassForGroup(ZP_GROUP:group) {
	assert zp_class_isValidGroup(group);
	ArrayGetArray(g_groupList, _:group, g_tempGroup);
	
	new temp[128], bool:isZombie = g_tempGroup[group_isZombieGroup], tempLen, tempLen2, tempStorage, classInfo[32];
	tempLen = formatex(temp, 127, "%s%s/%s/", g_szHomeFolder, _szTeamNames[isZombie], g_tempGroup[group_szName]);
	formatex(temp[tempLen], 127, "(Default) %s%s", g_tempGroup[group_szName], ZP_GROUP_EXT);
	if (file_exists(temp)) {
		return;
	}
	
	tempLen2 = tempLen;
	tempStorage = temp[tempLen2];
	temp[tempLen2] = '^0';
	if (!dir_exists(temp)) {
		new temp2[128];
		tempLen = formatex(temp2, 127, "%s%s/", g_szHomeFolder, _szTeamNames[isZombie]);
		mkdir(temp2);
		
		tempLen += copy(temp2[tempLen], 127, g_tempGroup[group_szName]);
		mkdir(temp2);
	}
	
	temp[tempLen2] = tempStorage;
	new file;
	do {
		file = fopen(temp, "wt");
	} while (!file);
	
	fprintf(file, "; Generated for %s v%s^n", ZP_PLUGIN_NAME, ZP_PLUGIN_VERSION);
	fprintf(file, "; Class system developed by Tirant^n");
	fprintf(file, "; ^n");
	fprintf(file, "; Team: %s^n", _szTeamNames[isZombie]);
	fprintf(file, "^n");
	fprintf(file, "; Health for this group^n");
	fprintf(file, "%s = %d", _keyNames[ck_fHealth], floatround(g_tempGroup[group_defaultClass][class_fHealth]));
	fprintf(file, "^n^n; Speed for this group^n");
	fprintf(file, "%s = %.2f", _keyNames[ck_fMaxspeed], g_tempGroup[group_defaultClass][class_fMaxspeed]);
	fprintf(file, "^n^n; Gravity for this group^n");
	fprintf(file, "%s = %.2f", _keyNames[ck_fGravity], g_tempGroup[group_defaultClass][class_fGravity]);
	fprintf(file, "^n^n; The model for this group^n");
	zp_core_getModelName(isZombie, g_tempGroup[group_defaultClass][class_model], classInfo, 31);
	fprintf(file, "%s = %s", _keyNames[ck_model], classInfo);
	
	fprintf(file, "^n^n; Abilities for this group^n");
	if (g_tempGroup[group_defaultClass][class_abilityList] != Invalid_Array) {
		new size = ArraySize(g_tempGroup[group_defaultClass][class_abilityList]);
		if (size > 0) {
			new abilities[512], ZP_ABILITY:ability;
			formatex(abilities, 511, "%s = ", _keyNames[ck_abilityList]);
			for (new i; i < size; i++) {
				ability = ArrayGetCell(g_tempGroup[group_defaultClass][class_abilityList], i);
				ArrayGetArray(g_abilityList, _:ability, g_tempAbility);
				format(abilities, 511, "%s, %s", g_tempAbility[ability_szName]);
			}
		}
	} else {
		fprintf(file, "%s = ", _keyNames[ck_abilityList]);
	}
	
	fprintf(file, "^n^n; XP Requirement for this group^n");
	fprintf(file, "%s = %d", _keyNames[ck_iCost], g_tempGroup[group_defaultClass][class_iCost]);
	fprintf(file, "^n^n; Admin flags required this group^n");
	get_flags(g_tempGroup[group_defaultClass][class_iAdminFlags], classInfo, 31);
	fprintf(file, "%s = %s", _keyNames[ck_iAdminFlags], classInfo);
	fprintf(file, "^n^n; Maximum number of people who can use classes within this group at once^n");
	fprintf(file, "%s = %d", _keyNames[ck_iMaxNumber], g_tempGroup[group_defaultClass][class_iMaxNumber]);
	
	replace(temp[tempLen2], 127, ZP_GROUP_EXT, "");
	ExecuteForward(g_fwWriteKey, g_fwReturn, temp[tempLen2], file);
	
	fclose(file);
}

cacheClassFromFile(bool:isZombie, ZP_GROUP:group, name[], path[], classCache[]) {
	new ZP_CLASS:class;
	ArrayGetArray(g_groupList, _:group, g_tempGroup);

	_class_t_setZombieClass(g_tempClass,	isZombie													);
	_class_t_setInheritingClass(g_tempClass,NULL														);
	_class_t_setName(g_tempClass,			name														);
	_class_t_setDescription(g_tempClass,	class_szDesc_DEFAULT										);
	_class_t_setHealth(g_tempClass,			g_tempGroup[group_defaultClass][class_fHealth],			true);
	_class_t_setMaxspeed(g_tempClass,		g_tempGroup[group_defaultClass][class_fMaxspeed],		true);
	_class_t_setGravity(g_tempClass,		g_tempGroup[group_defaultClass][class_fGravity],		true);
	_class_t_setModel(g_tempClass,			g_tempGroup[group_defaultClass][class_model]				);
	_class_t_setAbilityList(g_tempClass,	g_tempGroup[group_defaultClass][class_abilityList]			);
	_class_t_setAbilityBits(g_tempClass,	g_tempGroup[group_defaultClass][class_abilityBits]			);
	_class_t_setNoFallDamage(g_tempClass, 	g_tempGroup[group_defaultClass][class_bNoFallDamage]		);
	_class_t_setKnockback(g_tempClass,		g_tempGroup[group_defaultClass][class_fKnockback],		true);
	_class_t_setCost(g_tempClass,			g_tempGroup[group_defaultClass][class_iCost],			true);
	_class_t_setAdminFlags(g_tempClass,		g_tempGroup[group_defaultClass][class_iAdminFlags],		true);
	_class_t_setCurNumber(g_tempClass,		0,														true);
	_class_t_setMaxNumber(g_tempClass,		g_tempGroup[group_defaultClass][class_iMaxNumber],		true);
	
	if (isZombie) {
		zp_class_registerZClass2(group, g_tempClass);
	} else {
		zp_class_registerHClass2(group, g_tempClass);
	}
	
	if (!zp_class_isValidClass(class)) {
		return;
	}
	
	new key[32], i;
	new file = fopen(path, "rt");
	while (!feof(file)) {
		fgets(file, classCache, 511);
		
		replace(classCache, 511, "^n", "");
		if (!classCache[0] || classCache[0] == ';') {
			continue;
		}
		
		strtok(classCache, key, 31, classCache, 511, '=');
		trim(key);
		trim(classCache);
		
		if (TrieGetCell(g_keyList, key, i)) {
			switch (i) {
				case ck_isZombieClass: {
					// Not allowed to change, bound to group
				}
				case ck_inheritingClass: {
					ExecuteForward(g_fwReadKey, g_fwReturn, name, key, classCache);
				}
				case ck_szName: {
					// Not allowed to change, but rename file if internal change
				}
				case ck_szDesc: {
					_class_t_setDescription(g_tempClass, classCache);
				}
				case ck_fHealth: {
					_class_t_setHealth(g_tempClass, str_to_float(classCache), true);
				}
				case ck_fMaxspeed: {
					_class_t_setMaxspeed(g_tempClass, str_to_float(classCache),	true);
					
				}
				case ck_fGravity: {
					_class_t_setGravity(g_tempClass, str_to_float(classCache),	true);
				}
				case ck_model: {
					_class_t_setModel(g_tempClass, zp_core_registerModel(isZombie, classCache));
				}
				case ck_abilityList: {
					while (classCache[0] != '^0' && strtok(classCache, key, 31, classCache, 511, ',')) {
						trim(key);
						zp_class_addAbilityToClass(zp_class_getAbilityFromName(key), class);
					}
				}
				case ck_bNoFallDamage: {
					_class_t_setNoFallDamage(g_tempClass, bool:equali(classCache, "true"));
				}
				case ck_fKnockback: {
					_class_t_setKnockback(g_tempClass, str_to_float(classCache), true);
				}
				case ck_iCost: {
					_class_t_setCost(g_tempClass, str_to_num(classCache), true);
				}
				case ck_iAdminFlags: {
					_class_t_setAdminFlags(g_tempClass,	read_flags(classCache), true);
				}
				case ck_iCurNumber: {
					_class_t_setCurNumber(g_tempClass, 0, true);
				}
				case ck_iMaxNumber: {
					_class_t_setMaxNumber(g_tempClass, str_to_num(classCache), true);
				}
			}
		} else {
			ExecuteForward(g_fwReadKey, g_fwReturn, name, key, classCache);
		}
	}
	fclose(file);
}

public _createFileForClass(ZP_CLASS:class, ZP_GROUP:group) {
	assert zp_class_isValidClass(class);
	
	ArrayGetArray(g_classList, _:class, g_tempClass);
	ArrayGetArray(g_groupList, _:group, g_tempGroup);
	
	new temp[128], bool:isZombie = g_tempClass[class_isZombieClass], tempLen, tempLen2, tempStorage;
	tempLen = formatex(temp, 127, "%s%s/%s/", g_szHomeFolder, _szTeamNames[isZombie], g_tempGroup[group_szName]);
	formatex(temp[tempLen], 127, "%s%s", g_tempClass[class_szName], ZP_CLASS_EXT);
	if (file_exists(temp)) {
		return;
	}
	
	tempLen2 = tempLen;
	tempStorage = temp[tempLen2];
	temp[tempLen2] = '^0';
	if (!dir_exists(temp)) {
		new temp2[128];
		tempLen = formatex(temp2, 127, "%s%s/", g_szHomeFolder, _szTeamNames[isZombie]);
		mkdir(temp2);
		
		tempLen += copy(temp2[tempLen], 127, g_tempGroup[group_szName]);
		mkdir(temp2);
	}

	temp[tempLen2] = tempStorage;
	new file;
	do {
		file = fopen(temp, "wt");
	} while (!file);

	fprintf(file, "; Generated for %s v%s^n", ZP_PLUGIN_NAME, ZP_PLUGIN_VERSION);
	fprintf(file, "; Class system developed by Tirant^n");
	fprintf(file, "; ^n");
	fprintf(file, "; Team: %s^n", _szTeamNames[isZombie]);
	fprintf(file, "; Group: %s^n", g_tempGroup[group_szName]);
	fprintf(file, "; Class: %s^n", g_tempClass[class_szName]);
	//fprintf(file, "^n");
	//fprintf(file, "; The name of this class^n");
	//fprintf(file, "%s = %s", _keyNames[ck_szName], g_tempClass[class_szName]);
	fprintf(file, "^n^n; The description for this class^n");
	fprintf(file, "%s = %s", _keyNames[ck_szDesc], g_tempClass[class_szDesc]);
	fprintf(file, "^n^n; The model for this class^n");
	zp_core_getModelName(isZombie, g_tempClass[class_model], temp, 127);
	fprintf(file, "%s = %s", _keyNames[ck_model], temp);
	fprintf(file, "^n^n; Health for this class^n");
	fprintf(file, "%s = %d", _keyNames[ck_fHealth], floatround(g_tempClass[class_fHealth]));
	fprintf(file, "^n^n; Speed for this class^n");
	fprintf(file, "%s = %.2f", _keyNames[ck_fMaxspeed], g_tempClass[class_fMaxspeed]);
	fprintf(file, "^n^n; Gravity for this class^n");
	fprintf(file, "%s = %.2f", _keyNames[ck_fGravity], g_tempClass[class_fGravity]);
	
	fprintf(file, "^n^n; Abilities for this class^n");
	new size = ArraySize(g_tempClass[class_abilityList]);
	if (size > 0) {
		new abilities[512], ZP_ABILITY:ability;
		formatex(abilities, 511, "%s = ", _keyNames[ck_abilityList]);
		for (new i; i < size; i++) {
			ability = ArrayGetCell(g_tempClass[class_abilityList], i);
			ArrayGetArray(g_abilityList, _:ability, g_tempAbility);
			format(abilities, 511, "%s, %s", g_tempAbility[ability_szName]);
		}
	} else {
		fprintf(file, "%s = ", _keyNames[ck_abilityList]);
	}
	
	fprintf(file, "^n^n; XP Requirement for this class^n");
	fprintf(file, "%s = %d", _keyNames[ck_iCost], g_tempClass[class_iCost]);
	fprintf(file, "^n^n; Admin flags required this class^n");
	get_flags(g_tempClass[class_iAdminFlags], temp, 127);
	fprintf(file, "%s = %s", _keyNames[ck_iAdminFlags], temp);
	fprintf(file, "^n^n; Maximum number of people who can use this class at once^n");
	fprintf(file, "%s = %d", _keyNames[ck_iMaxNumber], g_tempClass[class_iMaxNumber]);
	
	ExecuteForward(g_fwWriteKey, g_fwReturn, g_tempClass[class_szName], file);
	
	fclose(file);
}