#include "include/zombieplague7.inc"
#include "include/zp7/classes/item_t.inc"

#include <cvar_util>

//#pragma dynamic 2048

#define VERSION "0.0.1"

static Array:g_itemList;
static Trie:g_itemTrie;
static g_itemNum;

static g_fwReturn;

public zp_fw_core_zombiePlagueInit() {
	g_itemList = ArrayCreate(item_t, 2);
	g_itemTrie = TrieCreate();
	
	server_print("ZP Item Module loaded");
	
	new fwRegisterItems = CreateMultiForward("zp_fw_items_registerItems", ET_CONTINUE);
	ExecuteForward(fwRegisterItems, g_fwReturn);
	DestroyForward(fwRegisterItems);
}

public plugin_init() {
	register_plugin("[ZP7] Guns Module", VERSION, "Tirant");
}

public plugin_natives() {
	register_library("ZP_Items");
}