#if defined _zombieplague7_included
	#endinput
#endif
#define _zombieplague7_included

#include <amxmodx>
#include <amxmisc>

#if AMXX_VERSION_NUM >= 175
	#pragma reqlib ZombiePlague7
	#if !defined AMXMODX_NOAUTOLOAD
		#pragma loadlib ZombiePlague7
	#endif
#else
	#pragma library ZombiePlague7
#endif

#include "include/zp7/zp_version.inc"
#include "include/zp7/zp_datatags.inc"
#include "include/zp7/zp_core.inc"
#include "include/zp7/zp_log.inc"
#include "include/zp7/zp_precache.inc"
#include "include/zp7/zp_colorchat.inc"
#include "include/zp7/zp_commands.inc"