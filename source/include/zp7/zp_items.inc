#if defined _zp_items_included
	#endinput
#endif
#define _zp_items_included

#if AMXX_VERSION_NUM >= 175
	#pragma reqlib ZP_Items
	#if !defined AMXMODX_NOAUTOLOAD
		#pragma loadlib ZP_Items
	#endif
#else
	#pragma library ZP_Items
#endif

#include "include/zp7/classes/item_t.inc"

forward zp_fw_items_registerItems();