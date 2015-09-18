#if defined _md5_gamekey_included
	#endinput
#endif
#define _md5_gamekey_included

#include <amxmodx>
#include <amxmisc>

stock bool:gamekey_validateKey(const szFileName[], key[34]) {
	gamekey_encrypt(key);

	new szGameKey[128];
	new len = get_configsdir(szGameKey, 127);
	szGameKey[len++] = '/';
	copy(szGameKey[len], 127, szFileName);
	new file = fopen(szGameKey, "rt");
	if (!file_exists(szGameKey)) {
		set_fail_state("No game key exists");
	}
	
	fgets(file, szGameKey, 33);
	fclose(file);
	return bool:equali(szGameKey, key, 34);
}

stock gamekey_createKeyFile(const szFileName[], key[34]) {
	new szGameKey[128];
	new len = get_configsdir(szGameKey, 127);
	szGameKey[len++] = '/';
	copy(szGameKey[len], 127, szFileName);
	new file = fopen(szGameKey, "wt");
	gamekey_encrypt(key);
	fprintf(file, key);
	fclose(file);
}

stock gamekey_encrypt(key[34]) {
	new tokens[4][8];
	for (new i; i < 4; i++) {
		strtok(key, tokens[i], 3, key, 33, '.', 1);
		formatex(tokens[i], 3, "%03d", str_to_num(tokens[i]));
	}
	
	formatex(key, 33, "%s%s%s%s", tokens[0], tokens[1], tokens[2], tokens[3]);
	md5(key, key);
	strtoupper(key);
	copy(tokens[0], 5, key[0]);
	copy(tokens[1], 7, key[5]);
	copy(tokens[2], 5, key[12]);
	formatex(key, 33, "%s-%s-%s", tokens[0], tokens[1], tokens[2]);
}