#if defined _zp_hclasses_included
	#endinput
#endif
#define _zp_hclasses_included

#if AMXX_VERSION_NUM >= 175
	#pragma reqlib ZP_Classes
	#pragma reqlib ZP_HClasses
	#if !defined AMXMODX_NOAUTOLOAD
		#pragma loadlib ZP_Classes
		#pragma loadlib ZP_HClasses
	#endif
#else
	#pragma library ZP_Classes
	#pragma library ZP_HClasses
#endif

#include "include/zp7/zp_guns.inc"
#include "include/zp7/zp_classes_const.inc"
#include "include/zp7/classes/hclass_t.inc"

forward zp_fw_class_registerHumans();

native ZP_GROUP:zp_class_createHGroup(const name[]);
native ZP_GROUP:zp_class_createHGroup2(const group[group_t]);

native ZP_CLASS:zp_class_registerHClass(const ZP_GROUP:group, const name[], const description[], const ZP_GUNS:gunList = ZP_GUNS:NULL, const model[] = "", 
								const health = hclass_fHealth_DEFAULT, const Float:speed = class_fMaxspeed_DEFAULT, const Float:gravity = class_fGravity_DEFAULT,
								const bool:noFallDamage = class_bNoFallDamage_DEFAULT, const Float:knockback = class_fKnockback_DEFAULT,
								const cost = class_iCost_DEFAULT, const adminflags = class_iAdminFlags_DEFAULT, const maxnum = class_iMaxNumber_DEFAULT);

native ZP_CLASS:zp_class_registerHClass2(const ZP_GROUP:group, class[class_t]);