#include "include/zombieplague7.inc"
#include "include/zp7/zp_modemanager.inc"

#define MAX_MODES		32
#define TASK_CHVOMOD	8675309

static Array:g_modeList;
static g_tempMode[mode_t];
static g_iVoteCounter[MAX_MODES];

public zp_fw_mode_registerModes() {
	g_modeList = zp_mode_getModeList();
}

public plugin_init() {
}

public _startVote() {
	//g_alreadyvoted = true;
	//remove_task(TASK_VOTEMOD);
	remove_task(TASK_CHVOMOD);
	
	new szMenu[512], mkeys;
	new pos = format(szMenu, 511, "\y%L:\w^n^n", LANG_PLAYER, "MM_CHOOSE")
	new modeNum = zp_mode_getModeNum();
	for (new i; i < modeNum && i < MAX_MODES; i++) {
		ArrayGetArray(g_modeList, i, g_tempMode);
		pos += format(szMenu[pos], 511, "%d. %s^n", (i+1), g_tempMode[mode_szName]);
		g_iVoteCounter[i] = 0;
		mkeys |= (1<<i);
	}
	
	zp_log("Vote: Voting started for next round mode^n%s %d", szMenu, mkeys);
	show_menu(0, mkeys, szMenu, 15);
	client_cmd(0, "spk Gman/Gman_Choose2");
	
	set_task(15.0, "checkVote", TASK_CHVOMOD);
	return;
}

public checkVote() {
	new b = 0;
	new modeNum = zp_mode_getModeNum();
	for(new a; a <= modeNum; a++) {
		if(g_iVoteCounter[b] < g_iVoteCounter[a]) {
			b = a;
		}
	}
	
	if (g_iVoteCounter[b] == 0) {
		b = random(modeNum);
	}
	
	new szMode[mode_szName_length+1];
	zp_mode_getModeName(ZP_MODE:b, szMode, mode_szName_length);
	zp_mode_setNextMode(ZP_MODE:b);
	zp_printColor(0, "^4Vote: Voting for the next MOD finished. The next MOD will be ^1%s", szMode);
	zp_log("Vote: Voting finished. Map chosen: %s", szMode);
}