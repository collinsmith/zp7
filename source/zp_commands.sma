#include <amxmodx>
#include <cvar_util>
#include "include/zombieplague7.inc"
#include "include/zp7/classes/command_t.inc"
#include "include/zp7/zp_commands.inc"

#pragma dynamic 2048

#define VERSION		"0.0.1"

static Array:g_aFunctions;
static Trie:g_tCommands;
static Array:g_aFunctionNames;
static g_functionNum;
static g_tempCommand[command_t];

enum _:eSayBits ( <<=1 )
{
	SAY_ALL = 1,
	SAY_TEAM,
	ZOMBIE_ONLY,
	HUMAN_ONLY,
	ALIVE_ONLY,
	DEAD_ONLY
}

static Trie:g_tPrefixes;

static g_szCommandListMotD[256];
static g_szCommandTable[1792];
static g_szCommandList[160];

static g_pcvar_prefix;

new g_fwReturn, g_fwCommandEnteredPre, g_fwCommandEnteredPost;

public zp_fw_core_zombiePlagueInit() {
	g_aFunctions = ArrayCreate(command_t, 8);

	g_aFunctionNames = ArrayCreate(1);
	for (new i; i < get_pluginsnum(); i++) {
		new Trie:tempTrie = TrieCreate();
		ArrayPushCell(g_aFunctionNames, tempTrie);
	}
	
	g_tCommands = TrieCreate();
	g_tPrefixes = TrieCreate();

	server_print("ZP Command Module loaded");
}

public plugin_init() {
	register_plugin("ZP Command Module", VERSION, "Tirant");
	
	register_clcmd("say",	   "cmdSay");
	register_clcmd("say_team", "cmdSayTeam");
	
	g_pcvar_prefix = CvarRegister("zp_command_prefixes", "/.!", "A list of all symbols that preceed commands");
	CvarHookChange(g_pcvar_prefix, "hookPrefixesAltered");
	
	static szPrefixes[32], c[2], i;
	get_pcvar_string(g_pcvar_prefix, szPrefixes, 31);
	while (szPrefixes[i] != '^0') {
		c[0] = szPrefixes[i];
		TrieSetCell(g_tPrefixes, c, i);
		i++;
	}
	
	register_dictionary("zp_core.txt");
	refreshCommandMotD();
	constructCommandTable();
	
	zp_command_register("commands", "displayCommandList", "abcdef", "Displays a printed list of all commands");
	zp_command_register("cmds", "displayCommandList");
	
	zp_command_register("commandlist", "displayCommandMotD", "abcdef", "Displays a detailed list of all commands");
	zp_command_register("cmdlist", "displayCommandMotD");
	
	new fwRegisterCommands = CreateMultiForward("zp_fw_command_registerCommands", ET_CONTINUE);
	ExecuteForward(fwRegisterCommands, g_fwReturn);
	DestroyForward(fwRegisterCommands);
	
	/* Forwards */
	/// Executed before a command function is executed. Can be stopped.
	g_fwCommandEnteredPre		= CreateMultiForward("zp_fw_command_pre", ET_CONTINUE, FP_CELL, FP_CELL);
	/// Executed after a command function is executed. Can't be stopped.
	g_fwCommandEnteredPost		= CreateMultiForward("zp_fw_command_post", ET_IGNORE, FP_CELL, FP_CELL);
}

public plugin_natives() {
	register_library("ZP_Commands");
	
	register_native("zp_command_register",				"_registerCommand",		0);
	register_native("zp_command_getCIDByName",			"_getCIDByName",		0);
}

public hookPrefixesAltered(handleCvar, const oldValue[], const newValue[], const cvarName[]) {
	TrieClear(g_tPrefixes);
	
	static i;
	while (newValue[i] != '^0') {
		TrieSetCell(g_tPrefixes, newValue[i], i);
		i++;
	}
	
	refreshCommandMotD();
}

public cmdSay(id) {
	new szMessage[32];
	read_args(szMessage, 31);
	forwardCommand(id, false, szMessage);
}

public cmdSayTeam(id) {
	new szMessage[32];
	read_args(szMessage, 31);
	forwardCommand(id, true, szMessage);
}

/**
 * Private method used to help simplify checking of a command
 * to see if it is used with a correct prefix.
 *
 * @param id		The player index who entered the command.
 * @param teamCommand	True if it is a team command, false otherwise.
 * @param message	The message being sent.
 */
forwardCommand(id, bool:teamCommand, message[]) {
	assert is_user_connected(id);
	strtolower(message);
	remove_quotes(message);
	
	new szTemp[2], i;
	szTemp[0] = message[0];
	if (!TrieGetCell(g_tPrefixes, szTemp, i)) {
		return PLUGIN_CONTINUE;
	}
	
	if (TrieGetCell(g_tCommands, message[1], i)) {
		executeCommand(i, id, teamCommand);
	}
	
	return PLUGIN_CONTINUE;
}

/**
 * Private method which takes a successful command and determines
 * whether or not the cirsumstances under which is was entered
 * obey the flags for the function tied into this command.
 *
 * @param cid		The unique command id to execute.
 * @param id		The player index to execute the command onto.
 * @param teamCommand	True if it is a team command, false otherwise.
 */
executeCommand(cid, id, bool:teamCommand) {
	ArrayGetArray(g_aFunctions, cid, g_tempCommand);
	new iFlags = g_tempCommand[command_flags];
	
	if (!(iFlags&(SAY_ALL)) && !(iFlags&(SAY_TEAM))) {
		return PLUGIN_CONTINUE;
	} else if ((iFlags&(SAY_TEAM)) && !teamCommand && !(iFlags&(SAY_ALL))) {
		return PLUGIN_CONTINUE;
	} else if ((iFlags&(SAY_ALL)) && teamCommand && !(iFlags&(SAY_TEAM))) {
		return PLUGIN_CONTINUE;
	}

	new isZombie = zp_core_isUserZombie(id);
	if (!(iFlags&(ZOMBIE_ONLY)) && !(iFlags&(HUMAN_ONLY))) {
		return PLUGIN_CONTINUE;
	} else if ((iFlags&(HUMAN_ONLY)) && isZombie && !(iFlags&(ZOMBIE_ONLY))) {
		return PLUGIN_CONTINUE;
	} else if ((iFlags&(ZOMBIE_ONLY)) && !isZombie && !(iFlags&(HUMAN_ONLY))) {
		return PLUGIN_CONTINUE;
	}

	new isAlive = is_user_alive(id);
	if (!(iFlags&(ALIVE_ONLY)) && !(iFlags&(DEAD_ONLY))) {
		return PLUGIN_CONTINUE;
	} else if ((iFlags&(DEAD_ONLY)) && isAlive && !(iFlags&(ALIVE_ONLY))) {
		return PLUGIN_CONTINUE;
	} else if ((iFlags&(ALIVE_ONLY)) && !isAlive && !(iFlags&(DEAD_ONLY))) {
		return PLUGIN_CONTINUE;
	}
	
	ExecuteForward(g_fwCommandEnteredPre, g_fwReturn, id, cid);
	if (g_fwReturn == ZP_BLOCK) {
		return PLUGIN_CONTINUE;
	}
	
	callfunc_begin_i(g_tempCommand[command_funcID], g_tempCommand[command_pluginID]); {
	callfunc_push_int(id);
	} callfunc_end();
	
	ExecuteForward(g_fwCommandEnteredPost, g_fwReturn, id, cid);
	
	return PLUGIN_CONTINUE;
}

/**
 * Public method used to display all initial command tied in with a function.
 * This method will not display duplicate commands tied into a single function.
 *
 * @param id		The player index to display the command list to.
 */
public displayCommandList(id) {
	static tempstring[sizeof g_szCommandList-2];
	add(tempstring, strlen(g_szCommandList)-2, g_szCommandList);
	zp_printColor(id, "^3%L^1: %s", id, "COMMANDS", tempstring);
}

/**
 * Public method used to display the command list MotD to a player.  This method
 * must combine all different pre-cached portions of the message including: the
 * header with prefixes, the command list table, and the footer.
 *
 * @param id		The player index to display the command list MotD to.
 */
public displayCommandMotD(id) {
	static szMotDText[2048];
	add(szMotDText, 2047, g_szCommandListMotD);
	add(szMotDText, 2047, g_szCommandTable);
	add(szMotDText, 2047, "</table></blockquote></font></body></html>");
	show_motd(id, szMotDText, "ZP Commands: Command List");
}

/**
 * Private method used to format the header and prefixes portion of the command
 * list MotD.  This is called whenever the command prefixes change.
 */
refreshCommandMotD() {
	static tempstring[128];
	formatex(g_szCommandListMotD, 255, "<html><body bgcolor=^"#474642^"><font size=^"3^" face=^"courier new^" color=^"FFFFFF^">");
	formatex(tempstring, 127, "<center><h1>Zombie Plague: Commands v%s</h1>By Tirant</center><br><br>", VERSION);
	add(g_szCommandListMotD, 255, tempstring);
	formatex(tempstring, 127, "%L: ", LANG_SERVER, "COMMAND_PREFIXES");
	add(g_szCommandListMotD, 255, tempstring);
	get_pcvar_string(g_pcvar_prefix, tempstring, 127);
	add(g_szCommandListMotD, 255, tempstring);
}

/**
 * Private method used to construct the initial header for the command table.
 * This method should only be called before commands are registered, because
 * this resets the entire command list table.
 */
constructCommandTable() {
	formatex(g_szCommandTable, 1791, "<br><br>%L:<blockquote>", LANG_SERVER, "COMMANDS");
	add(g_szCommandTable, 1791, "<STYLE TYPE=^"text/css^"><!--TD{color: ^"FFFFFF^"}---></STYLE><table><tr><td>Command:</td><td>&nbsp;&nbsp;Description:</td></tr>");
}

/**
 * Private method used to add a new function into all displays where it will
 * need to be displayed.
 *
 * @param command		The command that will execute the function.
 * @param description		The description to be displayed for this command.
 */
addCommandToTable(command[], description[]) {
	static tempstring[256];
	formatex(tempstring, 255, "<tr><td>%s</td><td>: %s</td></tr>", command, description);
	add(g_szCommandTable, 1791, tempstring);
	
	formatex(tempstring, 255, "^4%s^1, ", command);
	add(g_szCommandList, 159, tempstring);
}

/**
 * @see ZP_Commands.inc
 */
public ZP_COMMAND:_registerCommand(iPlugin, iParams) {
	if (iParams != 4) {
		return ZP_COMMAND:NULL;
	}
	
	new tempCommand[command_t], i;
	get_string(1, tempCommand[command_szName], command_szName_length);
	strtolower(tempCommand[command_szName]);
	if (TrieGetCell(g_tCommands, tempCommand[command_szName], i)) {
		zp_logError(AMX_ERR_NATIVE, "A command already exists under this name (%s)", tempCommand[command_szName]);
		return ZP_COMMAND:NULL;
	}
	
	new szTemp[command_szName_length+1];
	get_string(2, szTemp, command_szName_length);

	new Trie:tempTrie;
	tempTrie = ArrayGetCell(g_aFunctionNames, iPlugin);
	if (TrieGetCell(tempTrie, szTemp, i)) {
		TrieSetCell(g_tCommands, tempCommand[command_szName], i);
		
		return ZP_COMMAND:i;
	} else {
		tempCommand[command_funcID] = get_func_id(szTemp, iPlugin);
		if (tempCommand[command_funcID] < 0) {
			zp_logError(AMX_ERR_NATIVE, "Invalid command handle (%s)", tempCommand[command_szName]);
			return ZP_COMMAND:-2;
		}

		TrieSetCell(tempTrie, szTemp, g_functionNum);
		ArraySetCell(g_aFunctionNames, iPlugin, tempTrie);

		tempCommand[command_pluginID] = iPlugin;
		get_string(3, szTemp, 31);
		tempCommand[command_flags] = read_flags(szTemp);
		get_string(4, tempCommand[command_szDesc], command_szDesc_length);

		ArrayPushArray(g_aFunctions, tempCommand);
		TrieSetCell(g_tCommands, tempCommand[command_szName], g_functionNum);
		
		addCommandToTable(tempCommand[command_szName], tempCommand[command_szDesc]);
		
		g_functionNum++;
		return ZP_COMMAND:(g_functionNum-1);
	}
	
	return ZP_COMMAND:NULL;
}

/**
 * @see ZP_Commands.inc
 */
public ZP_COMMAND:_getCIDByName(iPlugin, iParams) {
	if (iParams != 1) {
		return ZP_COMMAND:NULL;
	}
	
	new command[32], i;
	get_string(1, command, 31);
	if (TrieGetCell(g_tCommands, command, i)) {
		return ZP_COMMAND:i;
	}
	
	return ZP_COMMAND:NULL;
}
