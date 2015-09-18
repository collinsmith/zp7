/*
	Counter-Strike Team Changer

	by Hattrick
*/

#if defined _cs_team_changer_included
	#endinput
#endif // defined _cs_team_changer_included

#define _cs_team_changer_included

#include "svn_version.inc"

#if AMXX_VERSION_NUM >= 175
	#pragma reqlib cs_team_changer

	#if !defined AMXMODX_NOAUTOLOAD
		#pragma loadlib cs_team_changer
	#endif // !defined AMXMODX_NOAUTOLOAD
#else // AMXX_VERSION_NUM < 175
	#pragma library cs_team_changer
#endif // AMXX_VERSION_NUM >= 175

/*
	There are the teams you can use
*/
enum
{
	TEAM_UNASSIGNED = 0,	// (0)
	TEAM_TERRORIST,		// (1)
	TEAM_CT,			// (2)
	TEAM_SPECTATOR		// (3)
};

/*
	You can do sixty transfers per second with this extension! The server won't crash!
	The CStrike extension with cs_set_user_team native will crash the server when twenty-five transfers reached!
*/

/*
	Changes a player from a team to other. The player's model will be untouched. The server won't be forged.
	This native will automaticaly send a TeamInfo message. Will also change the team offset and the team index.
*/
native cs_set_team( _index, _team );

/*
	Changes the player's team index. The team offset and the table score will be untouched. There won't be any TeamInfo message.
*/
native cs_set_team_id( _index, _team );

/*
	Changes the player's team offset. Table score remain untouched.
*/
native cs_set_team_offset( _index, _team );

/*
	Sends a fast TeamInfo message. The player will be transfered at the team you want but only in table score.
*/
native cs_set_team_tablescore( _index, _team );
