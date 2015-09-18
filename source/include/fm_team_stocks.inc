#if defined _fm_team_stocks_included
	#endinput
#endif
#define _fm_team_stocks_included

#include <fakemeta>

#define EXTRAOFFSET	5
#define OFFSET_TEAM	114
 
enum CsTeams {
	CS_TEAM_UNASSIGNED = 0,
	CS_TEAM_T,
	CS_TEAM_CT,
	CS_TEAM_SPECTATOR
};

static const team_names[CsTeams][] = {
	"UNASSIGNED",
	"TERRORIST",
	"CT",
	"SPECTATOR"
};
 
stock fm_cs_set_user_team(client, {CsTeams,_}:team) {
	set_pdata_int(client, OFFSET_TEAM, _:team, EXTRAOFFSET);
	dllfunc(DLLFunc_ClientUserInfoChanged, client, engfunc(EngFunc_GetInfoKeyBuffer, client));
	
	static TeamInfo;
	if(TeamInfo || (TeamInfo = get_user_msgid("TeamInfo"))) {
		emessage_begin(MSG_BROADCAST, TeamInfo); {
		ewrite_byte(client);
		ewrite_string(team_names[team]);
		} emessage_end();
	}
}

stock CsTeams:fm_cs_get_user_team(client) {
	return CsTeams:get_pdata_int(client, OFFSET_TEAM, EXTRAOFFSET);
}