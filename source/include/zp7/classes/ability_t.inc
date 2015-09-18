#if defined _ability_t_included
	#endinput
#endif
#define _ability_t_included

#define ZP_ABILITY:					_:

#define ability_szName_length		31

#define ability_szDesc_length		63

#define ability_iCost_DEFAULT		0
#define ability_iCost_MIN			0
#define ability_iCost_MAX			cellmax

enum _:ability_t {
				ability_szName[ability_szName_length+1],	// Name
				ability_szDesc[ability_szDesc_length+1],	// Description
				ability_iCost								// Cost
};

stock _ability_t_default(ability[ability_t]) {
	ability[ability_szName][0]	= '^0';
	ability[ability_szDesc][0]	= '^0';
	ability[ability_iCost]		= ability_iCost_DEFAULT;
}

stock _ability_t_getName(const ability[ability_t], buffer[], len) {
	copy(buffer, len, ability[ability_szName]);
}

stock _ability_t_setName(ability[ability_t], const str[]) {
	assert strlen(str);
	copy(ability[ability_szName], ability_szName_length, str);
}

stock _ability_t_getDescription(const ability[ability_t], buffer[], len) {
	copy(buffer, len, ability[ability_szDesc]);
}

stock _ability_t_setDescription(ability[ability_t], const str[]) {
	assert strlen(str);
	copy(ability[ability_szDesc], ability_szDesc_length, str);
}

stock _ability_t_getCost(const ability[ability_t]) {
	return ability[ability_iCost];
}

stock bool:_ability_t_setCost(ability[ability_t], cost, bool:shouldClamp) {
	if (shouldClamp) {
		ability[ability_iCost] = clamp(cost, ability_iCost_MIN, ability_iCost_MAX);
	} else {
		if (cost < ability_iCost_MIN) {
			return false;
		} else if (cost > ability_iCost_MAX) {
			return false;
		} else {
			ability[ability_iCost] = cost;
		}
	}

	return true;
}