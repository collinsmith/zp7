#if defined _group_t_included
	#endinput
#endif
#define _group_t_included

#include "include/arraycopy.inc"

#define ZP_GROUP:						_:

#define group_szName_length				31

#define group_classList_DEFAULT			ArrayCreate(1, 4)

enum _:group_t {
	bool:		group_isZombieGroup,						// Is it?
	ZP_GROUP:	group_ID,									// Group ID
				group_szName[group_szName_length+1],		// Name
				group_defaultClass[class_t],				// Default class
	Array:		group_classList								// Class list
};

stock _group_t_default(group[group_t]) {
	_group_t_setZombieGroup(group,	true					);
	_group_t_setID(group,			ZP_GROUP:NULL			);
	_group_t_setName(group,			"NULL"					);
	
	new tempClass[class_t]
	_class_t_default(tempClass);
	_group_t_setDefaultClass(group,	tempClass				);
	
	_group_t_setClassList(group,	group_classList_DEFAULT	);
}

stock bool:_group_t_getZombieGroup(const group[group_t]) {
	return group[group_isZombieGroup];
}

stock _group_t_setZombieGroup(group[group_t], bool:isZombieGroup) {
	group[group_isZombieGroup] = isZombieGroup;
}

stock ZP_GROUP:_group_t_getID(const group[group_t]) {
	return group[group_ID];
}

stock _group_t_setID(group[group_t], ZP_GROUP:id) {
	group[group_ID] = id;
}

stock _group_t_getName(const group[group_t], str[], len) {
	copy(str, len, group[group_szName]);
}

stock _group_t_setName(group[group_t], const str[]) {
	copy(group[group_szName], group_szName_length, str);
}

stock _group_t_getDefaultClass(const group[group_t], class[class_t]) {
	arraycopy(class, group[group_defaultClass], class_t);
}

stock _group_t_setDefaultClass(group[group_t], class[class_t]) {
	arraycopy(group[group_defaultClass], class, class_t);
}

stock Array:_group_t_getClassList(const group[group_t]) {
	return group[group_classList];
}

stock _group_t_setClassList(group[group_t], Array:classList) {
	group[group_classList] = _:classList;
}