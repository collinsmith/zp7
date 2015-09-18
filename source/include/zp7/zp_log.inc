#if defined _zp_log_included
	#endinput
#endif
#define _zp_log_included

#include <amxmisc>
#include "include/zp7/zp_version.inc"

stock zp_log(message[], any:...) {
	new formattedMessage[256];
	vformat(formattedMessage, 255, message, 2);
	
	static fileName[96];
	if(fileName[0] == '^0') {
		new dir[64];
		get_basedir(dir, 63);
		format_time(fileName, 95, "%Y%m%d");
		format(fileName, 95, "%s/logs/ZP7_%s.log", dir, fileName);
	}
	
	log_to_file(fileName, formattedMessage);
}

stock zp_logError(error, szError[], any:...) {
	if (numargs() == 1) {
		zp_log(szError);
		log_error(error, "%s %s", _szMessageHeader, szError);
	} else {
		new szBuffer[128];
		vformat(szBuffer, 127, szError, 2);
		zp_log(szBuffer);
		log_error(error, "%s %s", _szMessageHeader, szBuffer);
	}
}