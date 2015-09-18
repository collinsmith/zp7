#if defined _zp_zclasses_included
	#endinput
#endif
#define _zp_zclasses_included

#if AMXX_VERSION_NUM >= 175
	#pragma reqlib ZP_Classes
	#pragma reqlib ZP_ZClasses
	#if !defined AMXMODX_NOAUTOLOAD
		#pragma loadlib ZP_Classes
		#pragma loadlib ZP_ZClasses
	#endif
#else
	#pragma library ZP_Classes
	#pragma library ZP_ZClasses
#endif

#include "include/zp7/zp_classes_const.inc"
#include "include/zp7/classes/zclass_t.inc"

forward zp_fw_class_registerZombies();

native ZP_GROUP:zp_class_createZGroup(const name[]);
native ZP_GROUP:zp_class_createZGroup2(const group[group_t]);

native ZP_CLASS:zp_class_registerZClass(const ZP_GROUP:group, const name[], const description[], const model[] = "zp_classic",
								const handModel[] = "v_bloodyhands", const health = zclass_fHealth_DEFAULT, const Float:speed = class_fMaxspeed_DEFAULT,
								const Float:gravity = class_fGravity_DEFAULT, const bool:noFallDamage = class_bNoFallDamage_DEFAULT,
								const Float:knockback = class_fKnockback_DEFAULT, const cost = class_iCost_DEFAULT,
								const adminflags = class_iAdminFlags_DEFAULT, const maxnum = class_iMaxNumber_DEFAULT);
								
native ZP_CLASS:zp_class_registerZClass2(const ZP_GROUP:group, class[class_t]);