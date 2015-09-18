#if defined _class_t_included
	#endinput
#endif
#define _class_t_included

#define ZP_CLASS:						_:

#define class_isZombieClass_DEFAULT		true

#define class_inheritingClass_DEFAULT	ZP_CLASS:NULL

#define class_szName_length				31
#define class_szName_DEFAULT			"Classic"

#define class_szDesc_length				31
#define class_szDesc_DEFAULT			"Need brains!!! Arrrrggghh!"

#define class_fHealth_DEFAULT			2000.0
#define class_fHealth_MIN				1.0
#define class_fHealth_MAX				1000000000.0

#define class_fMaxspeed_DEFAULT			1.0
#define class_fMaxspeed_MIN				0.1
#define class_fMaxspeed_MAX				32000.0

#define class_fGravity_DEFAULT			1.0
#define class_fGravity_MIN				0.1
#define class_fGravity_MAX				3200.0

#define class_model_DEFAULT				ZP_MODEL:NULL

#define class_abilityList_DEFAULT		ArrayCreate(1, 4)

#define class_abilityBits_DEFAULT		ArrayCreate(1, 2)

#define class_bNoFallDamage_DEFAULT		false

#define class_fKnockback_DEFAULT		1.0
#define class_fKnockback_MIN			0.1
#define class_fKnockback_MAX			3200.0

#define class_iCost_DEFAULT				0
#define class_iCost_MIN					0
#define class_iCost_MAX					cellmax

#define class_iAdminFlags_DEFAULT		ADMIN_ALL
#define class_iAdminFlags_MAX			cellmax

#define class_iCurNumber_DEFAULT		0
#define class_iCurNumber_MIN			0
#define class_iCurNumber_MAX			cellmax

#define class_iMaxNumber_DEFAULT		0
#define class_iMaxNumber_MIN			0
#define class_iMaxNumber_MAX			cellmax

enum _:class_t {
	bool:		class_isZombieClass,						// Is it?
	any:		class_inheritingClass,						// The class inheriting this one
				class_szName[class_szName_length+1],		// Name
				class_szDesc[class_szDesc_length+1],		// Description
	Float:		class_fHealth,								// Health
	Float:		class_fMaxspeed,							// Maxspeed
	Float:		class_fGravity,								// Gravity
	ZP_MODEL:	class_model,								// Model
	Array:		class_abilityList,							// Ability list
	Array:		class_abilityBits,							// Ability bitsums
	bool:		class_bNoFallDamage,						// No fall damage
	Float:		class_fKnockback,							// Knockback multiplier
				class_iCost,								// Cost
				class_iAdminFlags,							// Admin flags
				class_iCurNumber,							// Current number
				class_iMaxNumber							// Max number
};

public _class_t_default(class[class_t]) {
	_class_t_setZombieClass(class,		class_isZombieClass_DEFAULT			);
	_class_t_setInheritingClass(class,	class_inheritingClass_DEFAULT		);
	_class_t_setName(class,				class_szName_DEFAULT				);
	_class_t_setDescription(class,		class_szDesc_DEFAULT				);
	_class_t_setHealth(class,			class_fHealth_DEFAULT,			true);
	_class_t_setMaxspeed(class,			class_fMaxspeed_DEFAULT,		true);
	_class_t_setGravity(class,			class_fGravity_DEFAULT,			true);
	_class_t_setModel(class,			class_model_DEFAULT					);
	_class_t_setAbilityList(class,		class_abilityList_DEFAULT			);
	_class_t_setAbilityBits(class,		class_abilityBits_DEFAULT			);
	_class_t_setNoFallDamage(class, 	class_bNoFallDamage_DEFAULT			);
	_class_t_setKnockback(class,		class_fKnockback_DEFAULT,		true);
	_class_t_setCost(class,				class_iCost_DEFAULT,			true);
	_class_t_setAdminFlags(class,		class_iAdminFlags_DEFAULT,		true);
	_class_t_setCurNumber(class,		class_iCurNumber_DEFAULT,		true);
	_class_t_setMaxNumber(class,		class_iMaxNumber_DEFAULT,		true);
}

stock bool:_class_t_getZombieClass(const class[class_t]) {
	return class[class_isZombieClass];
}

stock _class_t_setZombieClass(class[class_t], bool:isZombieClass) {
	class[class_isZombieClass] = isZombieClass;
}

stock ZP_CLASS:_class_t_getInheritingClass(const class[class_t]) {
	return class[class_inheritingClass];
}

stock _class_t_setInheritingClass(class[class_t], any:inheritingClass) {
	class[class_inheritingClass] = inheritingClass;
}

stock _class_t_getName(const class[class_t], buffer[], len) {
	copy(buffer, len, class[class_szName]);
}

stock _class_t_setName(class[class_t], const str[]) {
	assert str[0] != '^0';
	copy(class[class_szName], class_szName_length, str);
}

stock _class_t_getDescription(const class[class_t], buffer[], len) {
	copy(buffer, len, class[class_szDesc]);
}

stock _class_t_setDescription(class[class_t], const str[]) {
	assert str[0] != '^0';
	copy(class[class_szDesc], class_szDesc_length, str);
}

stock Float:_class_t_getHealth(const class[class_t]) {
	return class[class_fHealth];
}

stock bool:_class_t_setHealth(class[class_t], Float:health, const bool:shouldClamp) {
	if (shouldClamp) {
		class[class_fHealth] = _:floatclamp(health, class_fHealth_MIN, class_fHealth_MAX);
	} else {
		if (health < class_fHealth_MIN) {
			return false;
		} else if (health > class_fHealth_MAX) {
			return false;
		} else {
			class[class_fHealth] = _:health;
		}
	}

	return true;
}

stock Float:_class_t_getMaxspeed(const class[class_t]) {
	return class[class_fMaxspeed];
}

stock bool:_class_t_setMaxspeed(class[class_t], Float:maxspeed, const bool:shouldClamp) {
	if (shouldClamp) {
		class[class_fMaxspeed] = _:floatclamp(maxspeed, class_fMaxspeed_MIN, class_fMaxspeed_MAX);
	} else {
		if (maxspeed < class_fMaxspeed_MIN) {
			return false;
		} else if (maxspeed > class_fMaxspeed_MAX) {
			return false;
		} else {
			class[class_fMaxspeed] = _:maxspeed;
		}
	}

	return true;
}

stock Float:_class_t_getGravity(const class[class_t]) {
	return class[class_fGravity];
}

stock bool:_class_t_setGravity(class[class_t], Float:gravity, const bool:shouldClamp) {
	if (shouldClamp) {
		class[class_fGravity] = _:floatclamp(gravity, class_fGravity_MIN, class_fGravity_MAX);
	} else {
		if (gravity < class_fGravity_MIN) {
			return false;
		} else if (gravity > class_fGravity_MAX) {
			return false;
		} else {
			class[class_fGravity] = _:gravity;
		}
	}

	return true;
}

stock _class_t_getModel(const class[class_t]) {
	return class[class_model];
}

stock _class_t_setModel(class[class_t], ZP_MODEL:model) {
	class[class_model] = model;
}

stock Array:_class_t_getAbilityList(const class[class_t]) {
	return class[class_abilityList];
}

stock _class_t_setAbilityList(class[class_t], Array:abilityList) {
	class[class_abilityList] = _:abilityList;
}

stock Array:_class_t_getAbilityBits(const class[class_t]) {
	return class[class_abilityBits];
}

stock _class_t_setAbilityBits(class[class_t], Array:abilityBits) {
	class[class_abilityBits] = _:abilityBits;
}

stock bool:_class_t_getNoFallDamage(const class[class_t]) {
	return class[class_bNoFallDamage];
}

stock _class_t_setNoFallDamage(class[class_t], bool:bNoFallDamage) {
	class[class_bNoFallDamage] = bNoFallDamage;
}

stock Float:_class_t_getKnockback(const class[class_t]) {
	return class[class_fKnockback];
}

stock bool:_class_t_setKnockback(class[class_t], Float:knockback, const bool:shouldClamp) {
	if (shouldClamp) {
		class[class_fKnockback] = _:floatclamp(knockback, class_fKnockback_MIN, class_fKnockback_MAX);
	} else {
		if (knockback < class_fKnockback_MIN) {
			return false;
		} else if (knockback > class_fKnockback_MAX) {
			return false;
		} else {
			class[class_fKnockback] = _:knockback;
		}
	}

	return true;
}

stock _class_t_getCost(const class[class_t]) {
	return class[class_iCost];
}

stock bool:_class_t_setCost(class[class_t], cost, bool:shouldClamp) {
	if (shouldClamp) {
		class[class_iCost] = clamp(cost, class_iCost_MIN, class_iCost_MAX);
	} else {
		if (cost < class_iCost_MIN) {
			return false;
		} else if (cost > class_iCost_MAX) {
			return false;
		} else {
			class[class_iCost] = cost;
		}
	}

	return true;
}

stock _class_t_getAdminFlags(const class[class_t]) {
	return class[class_iAdminFlags];
}

stock bool:_class_t_setAdminFlags(class[class_t], flags, bool:shouldClamp) {
	if (shouldClamp) {
		class[class_iAdminFlags] = flags&class_iAdminFlags_MAX;
	} else {
		if (flags != flags&class_iAdminFlags_MAX) {
			return false;
		} else {
			class[class_iAdminFlags] = flags;
		}
	}

	return true;
}

stock _class_t_getCurNumber(const class[class_t]) {
	return class[class_iCurNumber];
}

stock bool:_class_t_setCurNumber(class[class_t], cur, bool:shouldClamp) {
	if (shouldClamp) {
		class[class_iCurNumber] = clamp(cur, class_iCurNumber_MIN, class_iCurNumber_MAX);
	} else {
		if (cur < class_iCurNumber_MIN) {
			return false;
		} else if (cur > class_iCurNumber_MAX) {
			return false;
		} else {
			class[class_iCurNumber] = cur;
		}
	}

	return true;
}

stock _class_t_getMaxNumber(const class[class_t]) {
	return class[class_iMaxNumber];
}

stock bool:_class_t_setMaxNumber(class[class_t], max, bool:shouldClamp) {
	if (shouldClamp) {
		class[class_iMaxNumber] = clamp(max, class_iMaxNumber_MIN, class_iMaxNumber_MAX);
	} else {
		if (max < class_iMaxNumber_MIN) {
			return false;
		} else if (max > class_iMaxNumber_MAX) {
			return false;
		} else {
			class[class_iMaxNumber] = max;
		}
	}

	return true;
}