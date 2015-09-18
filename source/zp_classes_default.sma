#include <amxmodx>
#include <flags32>
#include "include/zombieplague7.inc"
#include "include/zp7/zp_classes.inc"
#include "include/zp7/zp_zclasses.inc"
#include "include/zp7/zp_hclasses.inc"

#define VERSION "0.0.1"

// Classic Zombie Attributes
#define zclass1_name			"Classic Zombie"
#define zclass1_desc			"=Balanced="
#define zclass1_model			"zp_classic"
#define zclass1_handmodel		"v_bloodyhands"
#define zclass1_health			1800
#define zclass1_speed			1.00
#define zclass1_gravity			1.00
#define zclass1_nofalldamage	false
#define zclass1_knockback		1.00
#define zclass1_cost			0
#define zclass1_adminflags		ADMIN_ALL
#define zclass1_maxnum			0

// Raptor Zombie Attributes
#define zclass2_name			"Raptor Zombie"
#define zclass2_desc			"HP-- Speed++ Knockback++"
#define zclass2_model			"zp_classic"
#define zclass2_handmodel		"v_bloodyhands"
#define zclass2_health			900
#define zclass2_speed			1.10
#define zclass2_gravity			1.00
#define zclass2_nofalldamage	false
#define zclass2_knockback		1.00
#define zclass2_cost			0
#define zclass2_adminflags		ADMIN_ALL
#define zclass2_maxnum			5

// Poison Zombie Attributes
#define zclass3_name			"Poison Zombie"
#define zclass3_desc			"HP- Jump+ Knockback+"
#define zclass3_model			"zp_classic"
#define zclass3_handmodel		"v_bloodyhands"
#define zclass3_health			1400
#define zclass3_speed			1.00
#define zclass3_gravity			0.75
#define zclass3_nofalldamage	false
#define zclass3_knockback		1.25
#define zclass3_cost			0
#define zclass3_adminflags		ADMIN_ALL
#define zclass3_maxnum			5

// Big Zombie Attributes
#define zclass4_name			"Big Zombie"
#define zclass4_desc			"HP++ Speed- Knockback--"
#define zclass4_model			"zp_classic"
#define zclass4_handmodel		"v_bloodyhands"
#define zclass4_health			2700
#define zclass4_speed			0.75
#define zclass4_gravity			1.00
#define zclass4_nofalldamage	false
#define zclass4_knockback		0.50
#define zclass4_cost			0
#define zclass4_adminflags		ADMIN_ALL
#define zclass4_maxnum			5

// Leech Zombie Attributes
#define zclass5_name			"Leech Zombie"
#define zclass5_desc			"HP- Knockback+ Leech++"
#define zclass5_model			"zp_classic"
#define zclass5_handmodel		"v_bloodyhands"
#define zclass5_health			1300
#define zclass5_speed			1.00
#define zclass5_gravity			1.00
#define zclass5_nofalldamage	false
#define zclass5_knockback		1.25
#define zclass5_cost			0
#define zclass5_adminflags		ADMIN_ALL
#define zclass5_maxnum			5
//const zclass5_infecthp = 200 // extra hp for infections

public zp_fw_class_registerZombies() {
	new ZP_GROUP:groupid = zp_class_createZGroup("Default Zombies");
	zp_class_registerZClass(groupid, zclass1_name, zclass1_desc, zclass1_model, zclass1_handmodel, zclass1_health, zclass1_speed,
									zclass1_gravity, zclass1_nofalldamage, zclass1_knockback, zclass1_cost, zclass1_adminflags, zclass1_maxnum);
	zp_class_registerZClass(groupid, zclass2_name, zclass2_desc, zclass2_model, zclass2_handmodel, zclass2_health, zclass2_speed,
									zclass2_gravity, zclass2_nofalldamage, zclass2_knockback, zclass2_cost, zclass2_adminflags, zclass2_maxnum);
	zp_class_registerZClass(groupid, zclass3_name, zclass3_desc, zclass3_model, zclass3_handmodel, zclass3_health, zclass3_speed,
									zclass3_gravity, zclass3_nofalldamage, zclass3_knockback, zclass3_cost, zclass3_adminflags, zclass3_maxnum);
	zp_class_registerZClass(groupid, zclass4_name, zclass4_desc, zclass4_model, zclass4_handmodel, zclass4_health, zclass4_speed,
									zclass4_gravity, zclass4_nofalldamage, zclass4_knockback, zclass4_cost, zclass4_adminflags, zclass4_maxnum);
	zp_class_registerZClass(groupid, zclass5_name, zclass5_desc, zclass5_model, zclass5_handmodel, zclass5_health, zclass5_speed,
									zclass5_gravity, zclass5_nofalldamage, zclass5_knockback, zclass5_cost, zclass5_adminflags, zclass5_maxnum);
}

public zp_fw_class_registerHumans() {
	new ZP_GROUP:groupid = zp_class_createHGroup("Default Humans");
	zp_class_registerHClass(groupid, "Classic Human", "=Balanced=");
}

public plugin_init() {
	register_plugin("[ZP7] Classes (Default Classes)", VERSION, "Tirant");
}