#if defined _zp_datatypes_included
	#endinput
#endif
#define _zp_datatypes_included

// Basic ZP returns
#define ZP_RETURN:			_:
#define ZP_CONTINUE			ZP_RETURN:1000 // Implies continue
#define ZP_BLOCK			ZP_RETURN:1001 // Implies break
#define ZP_ERROR			ZP_RETURN:1002 // Implies an error occured (invalid param number)
#define ZP_SUCCESS			ZP_RETURN:1003 // Implies operation was carried out successfully

// Return tag for thrown events
#define ZP_THROW:			_:
#define ZP_UNCAUGHT			ZP_THROW:2000 // Implies uncaught and left unhandled
#define ZP_CAUGHT_UNHANDLED	ZP_THROW:2001 // Implies caught and left unhandled
#define	ZP_CAUGHT_HANDLED	ZP_THROW:2002 // Implies caught and handled
#define ZP_UNRESOLVED		ZP_THROW:2003 // Implies the error was left unresolved
#define ZP_RESOLVED			ZP_THROW:2004 // Implies the error has been resolved

// ZP player state changes (zombie to human, visa-versa, etc.)
#define ZP_PLAYERSTATE:		_:
#define ZP_NOCHANGE			ZP_PLAYERSTATE:3000 // There was no change made
#define ZP_CHANGED			ZP_PLAYERSTATE:3001 // The class was changed
#define ZP_INVALID			ZP_PLAYERSTATE:3002 // This player is dead or otherwise cannot be changed

//#define CS_TEAM_CT		2
//#define CS_TEAM_T			1

// ZP team constants (for returns only!)
#define ZP_TEAM:			_:
enum ZP_TEAM:ZP_TEAM_size {
	ZP_TEAM_UNASSIGNED = 0,
	ZP_TEAM_ZOMBIE,
	ZP_TEAM_HUMAN,
	ZP_TEAM_SPECTATOR
};

// ZP model
#define ZP_MODEL:			_: