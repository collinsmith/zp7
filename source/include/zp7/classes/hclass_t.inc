#if defined _humanclass_t_included
	#endinput
#endif
#define _humanclass_t_included

#include "include/zp7/classes/guns_t.inc"

#define hclass_fHealth_DEFAULT			100

#define ZP_HCLASS:						_:

#define hclass_parentClass_DEFAULT		ZP_CLASS:NULL

#define hclass_guns_DEFAULT				ZP_GUNS:NULL

enum _:hclass_t {
	ZP_CLASS:		hclass_parentClass,							// Parent class
	ZP_GUNS:		hclass_guns									// Available guns
};

public _hclass_t_default(hclass[hclass_t]) {
	_hclass_t_setClass(hclass,		hclass_parentClass_DEFAULT);
	hclass[hclass_guns] = 			hclass_guns_DEFAULT;
}

stock ZP_CLASS:_humanclass_t_getClass(const hclass[hclass_t]) {
	return hclass[hclass_parentClass];
}

stock _hclass_t_setClass(hclass[hclass_t], ZP_CLASS:class) {
	hclass[hclass_parentClass] = class;
}