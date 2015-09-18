#if defined _zombieclass_t_included
	#endinput
#endif
#define _zombieclass_t_included

#define zclass_fHealth_DEFAULT			2000

#define ZP_ZCLASS:						_:
#define ZP_HANDMODEL:					_:

#define zclass_parentClass_DEFAULT		ZP_CLASS:NULL

#define zclass_handModel_DEFAULT		ZP_HANDMODEL:NULL

enum _:zclass_t {
	ZP_CLASS:	zclass_parentClass,							// Parent class
	ZP_HANDMODEL:zclass_handModel						// Claw model
};

public _zclass_t_default(zclass[zclass_t]) {
	_zclass_t_setClass(zclass,		zclass_parentClass_DEFAULT);
	_zclass_t_setHandModel(zclass,	zclass_handModel_DEFAULT);
}

stock ZP_CLASS:_zombieclass_t_getClass(const zclass[zclass_t]) {
	return zclass[zclass_parentClass];
}

stock _zclass_t_setClass(zclass[zclass_t], ZP_CLASS:class) {
	zclass[zclass_parentClass] = class;
}

stock ZP_HANDMODEL:_zclass_t_getHandModel(const class[zclass_t]) {
	return class[zclass_handModel];
}

stock _zclass_t_setHandModel(class[zclass_t], ZP_HANDMODEL:handModel) {
	class[zclass_handModel] = _:handModel;
}