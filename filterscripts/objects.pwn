/*
 *	SF Custom Objects
 *
 *
*/

#include <a_samp>
#include <streamer>
#include <zcmd>

#define SetObjectInvisible(%0) 		SetDynamicObjectMaterialText(%0, 0, " ", 140, "Arial", 64, 1, -32256, 0, 1)
stock tmpVariable;

public OnFilterScriptInit()
{
	// Liv Entrance
	SetDynamicObjectMaterial( CreateDynamicObject( 18981, -1620.385498, 1074.161499, 7.046798, 0.000000, 0.000000, 0.000000 ), 0, 12923, "sw_block05", "sw_wallbrick_06", 0 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18980, -1620.121459, 1030.832885, 1.209059, 0.000000, 0.000000, 0.000000 ), 0, 13691, "bevcunto2_lahills", "stonewall3_la", 0 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18980, -1620.121459, 1031.822875, 1.209059, 0.000000, 0.000000, 0.000000 ), 0, 13691, "bevcunto2_lahills", "stonewall3_la", 0 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18980, -1620.121459, 1038.794921, 1.209059, 0.000000, 0.000000, 0.000000 ), 0, 13691, "bevcunto2_lahills", "stonewall3_la", 0 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18980, -1620.121459, 1039.785888, 1.209059, 0.000000, 0.000000, 0.000000 ), 0, 13691, "bevcunto2_lahills", "stonewall3_la", 0 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18980, -1620.121459, 1046.796630, 1.209059, 0.000000, 0.000000, 0.000000 ), 0, 13691, "bevcunto2_lahills", "stonewall3_la", 0 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18980, -1620.121459, 1047.786865, 1.209059, 0.000000, 0.000000, 0.000000 ), 0, 13691, "bevcunto2_lahills", "stonewall3_la", 0 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18980, -1620.121459, 1054.790527, 1.209059, 0.000000, 0.000000, 0.000000 ), 0, 13691, "bevcunto2_lahills", "stonewall3_la", 0 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18980, -1620.121459, 1055.771484, 1.209059, 0.000000, 0.000000, 0.000000 ), 0, 13691, "bevcunto2_lahills", "stonewall3_la", 0 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18980, -1620.155029, 1043.545776, 13.317501, 0.000000, -90.000000, 90.000000 ), 0, 13691, "bevcunto2_lahills", "stonewall3_la", 0 );
	CreateDynamicObject( 3525, -1619.450927, 1031.315917, 7.839063, 0.000000, 0.000000, 90.000000 );
	CreateDynamicObject( 3471, -1618.692260, 1047.278442, 7.149063, 0.000000, 0.000000, 0.000000 );
	CreateDynamicObject( 3471, -1618.692260, 1039.217163, 7.149063, 0.000000, 0.000000, 0.000000 );
	CreateDynamicObject( 3525, -1619.450927, 1055.288818, 7.839063, 0.000000, 0.000000, 90.000000 );
	CreateDynamicObject( 17951, -1619.889282, 1083.247680, 7.927502, 0.000000, 0.000000, 0.000000 );
	CreateDynamicObject( 17951, -1619.889282, 1075.208618, 7.927502, 0.000000, 0.000000, 0.000000 );
	CreateDynamicObject( 17951, -1619.889282, 1067.257934, 7.927502, 0.000000, 0.000000, 0.000000 );
	CreateDynamicObject( 17951, -1619.889282, 1059.277832, 7.927502, 0.000000, 0.000000, 0.000000 );
	CreateDynamicObject( 17951, -1619.889282, 1027.337402, 7.927502, 0.000000, 0.000000, 0.000000 );
	CreateDynamicObject( 17951, -1619.889282, 1019.317565, 7.927502, 0.000000, 0.000000, 0.000000 );
	CreateDynamicObject( 17951, -1619.889282, 1011.277709, 7.927502, 0.000000, 0.000000, 0.000000 );
	CreateDynamicObject( 638, -1617.368774, 1039.254516, 6.609056, 0.000000, 0.000000, 0.000000 );
	CreateDynamicObject( 638, -1618.989257, 1038.293579, 6.609056, 0.000000, 0.000000, -90.000000 );
	CreateDynamicObject( 638, -1618.989257, 1040.265136, 6.609056, 0.000000, 0.000000, -90.000000 );
	CreateDynamicObject( 638, -1617.368774, 1047.306274, 6.609056, 0.000000, 0.000000, 180.000000 );
	CreateDynamicObject( 638, -1618.989257, 1046.327880, 6.609056, 0.000000, 0.000000, -90.000000 );
	CreateDynamicObject( 638, -1618.989257, 1048.289428, 6.609056, 0.000000, 0.000000, -90.000000 );
	CreateDynamicObject( 1491, -1619.903198, 1041.870849, 6.146792, 0.000000, 0.000000, 90.000000 );
	CreateDynamicObject( 1491, -1619.923217, 1044.891845, 6.146792, 0.000000, 0.000000, -90.000000 );
	CreateDynamicObject( 1557, -1619.884277, 1033.802978, 6.159057, 0.000000, 0.000000, 90.000000 );
	CreateDynamicObject( 1557, -1619.884277, 1036.822875, 6.159057, 0.000000, 0.000000, -90.000000 );
	CreateDynamicObject( 1557, -1619.884277, 1052.964721, 6.159057, 0.000000, 0.000000, -90.000000 );
	CreateDynamicObject( 1557, -1619.884277, 1049.952758, 6.159057, 0.000000, 0.000000, 90.000000 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18980, -1620.121459, 1022.822387, 1.209059, 0.000000, 0.000000, 0.000000 ), 0, 13691, "bevcunto2_lahills", "stonewall3_la", 0 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18980, -1620.121459, 1023.802978, 1.209059, 0.000000, 0.000000, 0.000000 ), 0, 13691, "bevcunto2_lahills", "stonewall3_la", 0 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18980, -1620.121459, 1015.752441, 1.209059, 0.000000, 0.000000, 0.000000 ), 0, 13691, "bevcunto2_lahills", "stonewall3_la", 0 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18980, -1620.121459, 1014.771728, 1.209059, 0.000000, 0.000000, 0.000000 ), 0, 13691, "bevcunto2_lahills", "stonewall3_la", 0 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18980, -1620.121459, 1007.770263, 1.209059, 0.000000, 0.000000, 0.000000 ), 0, 13691, "bevcunto2_lahills", "stonewall3_la", 0 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18980, -1620.121459, 1062.775268, 1.209059, 0.000000, 0.000000, 0.000000 ), 0, 13691, "bevcunto2_lahills", "stonewall3_la", 0 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18980, -1620.121459, 1063.765991, 1.209059, 0.000000, 0.000000, 0.000000 ), 0, 13691, "bevcunto2_lahills", "stonewall3_la", 0 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18980, -1620.121459, 1070.746582, 1.209059, 0.000000, 0.000000, 0.000000 ), 0, 13691, "bevcunto2_lahills", "stonewall3_la", 0 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18980, -1620.121459, 1071.727172, 1.209059, 0.000000, 0.000000, 0.000000 ), 0, 13691, "bevcunto2_lahills", "stonewall3_la", 0 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18980, -1620.121459, 1078.738159, 1.209059, 0.000000, 0.000000, 0.000000 ), 0, 13691, "bevcunto2_lahills", "stonewall3_la", 0 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18980, -1620.121459, 1079.728759, 1.209059, 0.000000, 0.000000, 0.000000 ), 0, 13691, "bevcunto2_lahills", "stonewall3_la", 0 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18980, -1620.121459, 1086.759521, 1.209059, 0.000000, 0.000000, 0.000000 ), 0, 13691, "bevcunto2_lahills", "stonewall3_la", 0 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18980, -1620.145019, 1018.465515, 13.317501, 0.000000, -90.000000, 90.000000 ), 0, 13691, "bevcunto2_lahills", "stonewall3_la", 0 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18980, -1620.145019, 1074.493164, 13.317501, 0.000000, -90.000000, 90.000000 ), 0, 13691, "bevcunto2_lahills", "stonewall3_la", 0 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18980, -1620.145019, 1049.504028, 13.317501, 0.000000, -90.000000, 90.000000 ), 0, 13691, "bevcunto2_lahills", "stonewall3_la", 0 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18981, -1620.385498, 1049.161376, 7.046798, 0.000000, 0.000000, 0.000000 ), 0, 12923, "sw_block05", "sw_wallbrick_06", 0 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18981, -1620.385498, 1024.181884, 7.046798, 0.000000, 0.000000, 0.000000 ), 0, 12923, "sw_block05", "sw_wallbrick_06", 0 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18981, -1620.385498, 999.192260, 7.046798, 0.000000, 0.000000, 0.000000 ), 0, 12923, "sw_block05", "sw_wallbrick_06", 0 );
	SetDynamicObjectMaterial( CreateDynamicObject( 19369, -1618.217163, 1043.370361, 6.099058, 0.000000, -90.000000, 0.000000 ), 0, 8839, "vgsecarshow", "lightred2_32", -4012 );
	CreateDynamicObject( 3525, -1619.731201, 1041.104370, 7.839063, 0.000000, 0.000000, 90.000000 );
	CreateDynamicObject( 3525, -1619.731201, 1045.614990, 7.839063, 0.000000, 0.000000, 90.000000 );
	CreateDynamicObject( 3525, -1619.450927, 1023.255676, 7.839063, 0.000000, 0.000000, 90.000000 );
	CreateDynamicObject( 3525, -1619.450927, 1015.263854, 7.839063, 0.000000, 0.000000, 90.000000 );
	CreateDynamicObject( 3525, -1619.450927, 1063.247802, 7.839063, 0.000000, 0.000000, 90.000000 );
	CreateDynamicObject( 3525, -1619.450927, 1071.229125, 7.839063, 0.000000, 0.000000, 90.000000 );
	CreateDynamicObject( 3525, -1619.450927, 1079.239379, 7.839063, 0.000000, 0.000000, 90.000000 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18764, -1621.487304, 1043.385253, 6.387504, 0.000000, 0.000000, 0.000000 ), 0, 0, "0", "0", 0 );
	return 1;
}

public OnFilterScriptExit()
{
	return 1;
}

public OnPlayerConnect(playerid)
{
	return 1;
}
