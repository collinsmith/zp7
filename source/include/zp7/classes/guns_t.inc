#if defined _guns_t_included
	#endinput
#endif
#define _guns_t_included

#define guns_BitArray_DEFAULT			ArrayCreate(1, 2)

#define ZP_GUNS:						_:

enum _:guns_t {
	Array:			guns_BitArray							// Parent class
};

public _guns_t_default(guns[guns_t]) {
	guns[guns_BitArray] = _:guns_BitArray_DEFAULT;
}

stock Array:_guns_t_getGuns(const guns[guns_t]) {
	return guns[guns_BitArray];
}