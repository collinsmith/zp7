#if defined _command_t_included
	#endinput
#endif
#define _command_t_included

#define ZP_COMMAND:					_:

#define command_szName_length		31
#define command_szDesc_length		63

enum _:command_t {
				command_szName[command_szName_length+1],	// Name
				command_szDesc[command_szDesc_length+1],	// Description
				command_pluginID,							// Plugin ID #
				command_funcID,								// Function ID #
				command_flags								// Flags for activation
};