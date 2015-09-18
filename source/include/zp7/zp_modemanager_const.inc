#if defined _zp_modemanager_const_included
	#endinput
#endif
#define _zp_modemanager_const_included

// ZP Game Mode
#define ZP_MODE:			_:

#define MODE_HUD_CHANNEL 4

#define mode_szName_length 31
#define mode_szDesc_length 127

enum _:mode_t {
	mode_szName[mode_szName_length+1],
	mode_szDesc[mode_szDesc_length+1],
	mode_iWeight
}