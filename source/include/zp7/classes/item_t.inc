#if defined _item_t_included
	#endinput
#endif
#define _item_t_included

#define ZP_ITEM:						_:

#define item_szName_length				31
#define item_szName_DEFAULT				""

#define item_szDesc_length				63
#define item_szDesc_DEFAULT				""

#define item_iCost_DEFAULT				0
#define	item_iCost_MIN					0
#define item_iCost_MAX					cellmax

enum _:item_t {
					item_szName[item_szName_length+1],		// Name
					item_szDesc[item_szDesc_length+1],		// Description
					item_iCost								// Cost
};

public _item_t_default(item[item_t]) {
	//...
}