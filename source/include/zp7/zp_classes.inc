#if defined _zp_classes_included
	#endinput
#endif
#define _zp_classes_included

#if AMXX_VERSION_NUM >= 175
	#pragma reqlib ZP_Classes
	#if !defined AMXMODX_NOAUTOLOAD
		#pragma loadlib ZP_Classes
	#endif
#else
	#pragma library ZP_Classes
#endif

#include "include/zp7/zp_classes_const.inc"
#include "include/zp7/zp_zclasses.inc"
#include "include/zp7/zp_hclasses.inc"

/******************************************************************************************************************************
Forwards
******************************************************************************************************************************/
/**
 * Called when abilities should be registered.
 */
forward zp_fw_class_registerAbilities();

/**
 * Called for the zp_classes_filesystem module only.
 * 
 * @note 				This only works with the filesystem.
 */
forward zp_fw_class_registerClassesPre();

/**
 * Called when classes are able to be registered.
 */
forward zp_fw_class_registerClasses();

/**
 * Called after the next class has been moved into the current
 * one. This should be used to change the next class or reset it.
 * 
 * @param id			Player index triggering event
 * @param nextClass		The current next class
 */
forward zp_fw_class_classLoaded(id, ZP_CLASS:nextClass);

/**
 * Called when a player tries to use a class with a cost. Return
 * an arbitrary cost that determines whether or not the player can
 * use it.
 * 
 * @param id			Player index triggering event
 * @param class			The class attempting to be selected
 * @param cost			The cost of this class
 * @return				Return the amount of XP this player has
 */
forward g_fw_classes_requestCosts(id, ZP_CLASS:class, cost);

/**
 * Called after an ability is registered.
 * 
 * @param ability		The ability registered
 */
forward zp_fw_class_abilityRegistered(ZP_ABILITY:ability);

/**
 * Called after a class is registered.
 * 
 * @param class			The class registered
 */
forward zp_fw_class_classRegistered(ZP_CLASS:class);

/**
 * Called after a group is registered.
 * 
 * @param group			The group registered
 */
forward zp_fw_class_groupRegistered(ZP_GROUP:group);

/**
 * Called when requesting the "cost" a player has.
 * 
 * @note				This is completely arbitrary, and only manages
 * 						whether or not the user should have access to
 * 						this class. You can manage whether this is a
 * 						monetary or experience cost yourself.
 * 
 * @param id			Player index requesting
 * @param class			The class checking
 * @param cost			The cost of this class
 * @return				The amount of exp/money this player has
 */
forward zp_fw_class_requestCosts(id, ZP_CLASS:class, cost);

/******************************************************************************************************************************
Natives
******************************************************************************************************************************/

/**
 * Registers an ability with the engine.
 * 
 * @param ability		The ability data to use
 * @return				ZP_ABILITY:NULL implies failure to register,
 * 						_:X > NULL implies a valid ability
 */
native ZP_ABILITY:zp_class_registerAbility(ability[ability_t]);

/**
 * Registers an ability with the engine.
 * 
 * @param name			Name of the ability
 * @param description	Description of the ability
 * @param cost			The arbitrary cost for using this ability
 * @return				ZP_ABILITY:NULL implies failure to register,
 * 						_:X > NULL implies a valid ability
 */
native ZP_ABILITY:zp_class_registerAbility2(const name[], const description[], const cost = ability_iCost_DEFAULT);

/**
 * Registers a class with the engine.
 * 
 * @param class			The class data to use
 * @return				ZP_CLASS:NULL implies failure to register,
 * 						_:X > NULL implies a valid class
 */
native ZP_CLASS:zp_class_registerClass(class[class_t]);

/**
 * Registers a group with the engine.
 * 
 * @param group			The class data to use
 * @return				ZP_GROUP:NULL implies failure to register,
 * 						_:X > NULL implies a valid group
 */
native ZP_GROUP:zp_class_registerGroup(group[group_t]);

/**
 * Adds an ability to a class.
 * 
 * @note				Classes can have as many abilities as you want
 * @param ability		The ability to add
 * @param class			The class to add the ability to
 * @return				True implies successful addition, otherwise
 * 						false implies the class already posesses this
 * 						ability
 */
native bool:zp_class_addAbilityToClass(ZP_ABILITY:ability, ZP_CLASS:class);

/**
 * Adds a class to a group.
 * 
 * @note				Classes can only belong to a single group, so
 * 						this effectively breaks any former relationship
 * @param class			The class to add
 * @param group			The group to add the class to
 */
native bool:zp_class_addClassToGroup(ZP_CLASS:class, ZP_GROUP:group);

/**
 * Adds a group to a type.
 * 
 * @note				Groups can only belong to a single type, so this
 * 						effectively breaks any former relationship
 * @param group			The group to
 */
native bool:zp_class_addGroupToType(ZP_GROUP:group, bool:isZombieGroup);

/**
 * Removes an ability from a class.
 * 
 * @param ability		The ability to remove
 * @param class			The class to remove the ability from
 * @return				True if the ability was removed, otherwise false
 */
native bool:zp_class_removeAbilityFromClass(ZP_ABILITY:ability, ZP_CLASS:class);

/**
 * Removes a class from a group.
 * 
 * @note				This will remove the class from the group it belongs to
 * @param class			The class to remove
 * @param group			The group to remove the class from
 * @return				True if the class was removed, otherwise false
 */
native bool:zp_class_removeClassFromGroup(ZP_CLASS:class, ZP_GROUP:group);

/**
 * Removes a group from a type.
 * 
 * @note				This will remove the group from the type it belongs to
 * @param group			The group to remove
 * @return				True if the group was removed, otherwise false
 */
native bool:zp_class_removeGroupFromType(ZP_GROUP:group);

/**
 * Checks whether a class has an ability.
 * 
 * @param class			The class to look at
 * @param ability		The ability to check
 * @return				True if the class has the ability, otherwise false
 */
native bool:zp_class_classHasAbility(ZP_CLASS:class, ZP_ABILITY:ability);

/**
 * Checks whether or not an ability is valid.
 * 
 * @param ability		The ability to check
 * @return				True if the ability is valid, otherwise false
 */
native bool:zp_class_isValidAbility(ZP_ABILITY:ability);

/**
 * Checks whether or not a class is valid.
 * 
 * @param class			The class to check
 * @return				True if the class is valid, otherwise false
 */
native bool:zp_class_isValidClass(ZP_CLASS:class);

/**
 * Checks whether or not a group is valid.
 * 
 * @param group			The group to check
 * @return				True if the group is valid, otherwise false
 */
native bool:zp_class_isValidGroup(ZP_GROUP:group);

/**
 * Checks whether or not a class is a zombie one or not.
 * 
 * @param class			The class to check
 * @return				True if the class is a zombie class, otherwise false
 */
native bool:zp_class_isZombieClass(ZP_CLASS:class);

/**
 * Checks whether or not a class is a human one or not.
 * 
 * @param class			The class to check
 * @return				True if the class is a human class, otherwise false
 */
native bool:zp_class_isHumanClass(ZP_CLASS:class);

/**
 * Retrieves the current class applied on a user.
 * 
 * @param id			Player index to check
 * @return				The current class applied on this player
 */
native ZP_CLASS:zp_class_getUserClass(id);

/**
 * Sets a new class for a user.
 * 
 * @note				This class will be loaded immediately
 * @param id			Player index to set
 * @param class			The new class for this user
 */
native ZP_CLASS:zp_class_setUserClass(id, ZP_CLASS:class);

/**
 * Retrieves the current next class for a user.
 * 
 * @param id			Player index to check
 * @return				The current next class for this player
 */
native ZP_CLASS:zp_class_getUserNextClass(id);

/**
 * Sets a new next class for a user.
 * 
 * @note				This class will be loaded on the clients next
 * 						refresh event
 * @param id			Player index to set
 * @param class			The new next class for this user
 */
native ZP_CLASS:zp_class_setUserNextClass(id, ZP_CLASS:class);

/**
 * Retrieves the number of classes registered.
 * 
 * @return				The total number of classes registered
 */
native zp_class_getClassNum();

/**
 * Retrieves the number of groups registered.
 * 
 * @return				The total number of groups registered
 */
native zp_class_getGroupNum();

/**
 * Retrieves a given ability that matches a specified name.
 * 
 * @param name			The name to look up
 * @return				ZP_ABILITY:NULL implies failure to search,
 * 						_:X > NULL implies a valid ability
 */
native ZP_ABILITY:zp_class_getAbilityFromName(const name[]);

/**
 * Retrieves a given class that matches a specified name.
 * 
 * @param name			The name to look up
 * @return				ZP_CLASS:NULL implies failure to search,
 * 						_:X > NULL implies a valid class
 */
native ZP_CLASS:zp_class_getClassFromName(const name[]);

/**
 * Retrieves a given group that matches a specified name.
 * 
 * @param name			The name to look up
 * @return				ZP_GROUP:NULL implies failure to search,
 * 						_:X > NULL implies a valid group
 */
native ZP_GROUP:zp_class_getGroupFromName(const name[]);

/**
 * Retrieves whether or not a class is usable by a user, and
 * prints the reason (if any) why it can't be.
 * 
 * @param id			Player index
 * @param class			The class to query
 * @return				True if possible, false otherwise
 */
native bool:zp_class_canUseClass(id, ZP_CLASS:class);