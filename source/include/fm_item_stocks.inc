#if defined _fm_item_stocks_included
	#endinput
#endif
#define _fm_item_stocks_included

#define fm_create_entity(%1) engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, %1))

#define EXTRAOFFSET	5
 
enum {
	OFFSET_AMMO_AWP = 377,
	OFFSET_AMMO_SCOUT, // AK47, G3SG1
	OFFSET_AMMO_M249,
	OFFSET_AMMO_M4A1, // FAMAS, AUG, SG550, GALIL, SG552
	OFFSET_AMMO_M3, // XM1014
	OFFSET_AMMO_USP, // UMP45, MAC10
	OFFSET_AMMO_FIVESEVEN, // P90
	OFFSET_AMMO_DEAGLE,
	OFFSET_AMMO_P228,
	OFFSET_AMMO_GLOCK18, // MP5NAVY, TMP, ELITE
	OFFSET_AMMO_FLASHBANG,
	OFFSET_AMMO_HEGRENADE,
	OFFSET_AMMO_SMOKEGRENADE,
	OFFSET_AMMO_C4
};

static const _CSW_to_offset[] = {
	0, OFFSET_AMMO_P228, OFFSET_AMMO_SCOUT, OFFSET_AMMO_HEGRENADE, OFFSET_AMMO_M3, OFFSET_AMMO_C4, OFFSET_AMMO_USP, OFFSET_AMMO_SMOKEGRENADE,
	OFFSET_AMMO_GLOCK18, OFFSET_AMMO_FIVESEVEN, OFFSET_AMMO_USP, OFFSET_AMMO_M4A1, OFFSET_AMMO_M4A1, OFFSET_AMMO_M4A1, OFFSET_AMMO_USP, OFFSET_AMMO_GLOCK18,
	OFFSET_AMMO_AWP, OFFSET_AMMO_GLOCK18, OFFSET_AMMO_M249, OFFSET_AMMO_M3, OFFSET_AMMO_M4A1, OFFSET_AMMO_GLOCK18, OFFSET_AMMO_SCOUT, OFFSET_AMMO_FLASHBANG,
	OFFSET_AMMO_DEAGLE, OFFSET_AMMO_M4A1, OFFSET_AMMO_SCOUT, 0, OFFSET_AMMO_FIVESEVEN
};

stock fm_strip_user_weapons(index) {
	new ent = fm_create_entity("player_weaponstrip");
	if (!pev_valid(ent)) {
		return 0;
	}

	dllfunc(DLLFunc_Spawn, ent);
	dllfunc(DLLFunc_Use, ent, index);
	engfunc(EngFunc_RemoveEntity, ent);

	return 1;
}

stock fm_give_item(index, const item[]) {
	if (!equal(item, "weapon_", 7) && !equal(item, "ammo_", 5) && !equal(item, "item_", 5) && !equal(item, "tf_weapon_", 10)) {
		return 0;
	}

	new ent = fm_create_entity(item);
	if (!pev_valid(ent)) {
		return 0;
	}

	new Float:origin[3];
	pev(index, pev_origin, origin);
	set_pev(ent, pev_origin, origin);
	set_pev(ent, pev_spawnflags, pev(ent, pev_spawnflags) | SF_NORESPAWN);
	dllfunc(DLLFunc_Spawn, ent);

	new save = pev(ent, pev_solid);
	dllfunc(DLLFunc_Touch, ent, index);
	if (pev(ent, pev_solid) != save) {
		return ent;
	}

	engfunc(EngFunc_RemoveEntity, ent);

	return -1;
}

stock fm_get_weaponbox_type(entity) {
	static max_clients, max_entities;
	if (!max_clients) {
		max_clients = global_get(glb_maxClients);
	}
	if (!max_entities) {
		max_entities = global_get(glb_maxEntities);
	}

	for (new i = max_clients + 1; i < max_entities; ++i) {
		if (pev_valid(i) && entity == pev(i, pev_owner)) {
			new wname[32];
			pev(i, pev_classname, wname, sizeof wname - 1);
			return get_weaponid(wname);
		}
	}

	return 0;
}

stock fm_cs_get_user_bpammo(client, weapon) {
	return get_pdata_int(client, _CSW_to_offset[weapon], EXTRAOFFSET);
}

stock fm_cs_set_user_bpammo(client, weapon, ammo) {
	set_pdata_int(client, _CSW_to_offset[weapon], ammo, EXTRAOFFSET);
}