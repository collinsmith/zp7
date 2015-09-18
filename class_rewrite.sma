static g_tempClass[class_t];

zp_class_registerGroup(true, "Default Classes", "[NO DESC]", ZP_CLASS:classid);

public _registerGroup(plugin, params) {
	if (params != 1) {
		//...
		return ZP_GROUP:NULL;
	}
	
	//...
}

public _registerClass(plugin, params) {
	if (params != 1) {
		//...
		return ZP_CLASS:NULL;
	}
	
	ArrayGetArray(g_groupList, _:group, g_tempGroup);
	ArrayGetArray(g_classList, g_tempGroup[group_defaultClass], g_tempClass);
	ArrayPushArray(g_classList, g_tempClass);
	//...
}

