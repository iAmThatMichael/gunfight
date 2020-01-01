#using scripts\shared\callbacks_shared;
#using scripts\shared\clientfield_shared;
#using scripts\codescripts\struct;

#insert scripts\shared\shared.gsh;
#insert scripts\shared\version.gsh;

function main()
{
	clientfield::register( "toplayer", "gffriendlyteam_health_num", VERSION_SHIP, 20, "int", &gfFriendlyHealth, !CF_HOST_ONLY, !CF_CALLBACK_ZERO_ON_NEW_ENT );
	clientfield::register( "toplayer", "gffriendlyteam_size_num", VERSION_SHIP, 2, "int", &gfFriendlyCount, !CF_HOST_ONLY, !CF_CALLBACK_ZERO_ON_NEW_ENT );

	clientfield::register( "toplayer", "gfenemyteam_health_num", VERSION_SHIP, 20, "int", &gfEnemyHealth, !CF_HOST_ONLY, !CF_CALLBACK_ZERO_ON_NEW_ENT );
	clientfield::register( "toplayer", "gfenemyteam_size_num", VERSION_SHIP, 2, "int", &gfEnemyCount, !CF_HOST_ONLY, !CF_CALLBACK_ZERO_ON_NEW_ENT );

	callback::on_localplayer_spawned( &on_localplayer_spawned );
}


function onPrecacheGameType()
{
}

function onStartGameType()
{
}

function on_localplayer_spawned( local_client_num )
{
	if( self != GetLocalPlayer( local_client_num ) )
		return;
}

function gfFriendlyHealth( localClientNum, oldVal, newVal, bNewEnt, bInitialSnap, fieldName, bWasTimeJump )
{
	model = CreateUIModel( GetUIModelForController( localClientNum ), "hudItems.gffriendlyteam_health_num" );
	SetUIModelValue( model, newVal );
	//IPrintLnBold( sprintf( "LCN {0} | Field: {1}, Values: {2} {3}", localClientNum, fieldName, oldVal, newVal ) );
}

function gfFriendlyCount( localClientNum, oldVal, newVal, bNewEnt, bInitialSnap, fieldName, bWasTimeJump )
{
	model = CreateUIModel( GetUIModelForController( localClientNum ), "hudItems.gffriendlyteam_size_num" );
	SetUIModelValue( model, newVal );
	//IPrintLnBold( sprintf( "LCN {0} | Field: {1}, Values: {2} {3}", localClientNum, fieldName, oldVal, newVal ) );
}

function gfEnemyHealth( localClientNum, oldVal, newVal, bNewEnt, bInitialSnap, fieldName, bWasTimeJump )
{
	model = CreateUIModel( GetUIModelForController( localClientNum ), "hudItems.gfenemyteam_health_num" );
	SetUIModelValue( model, newVal );
	//IPrintLnBold( sprintf( "LCN {0} | Field: {1}, Values: {2} {3}", localClientNum, fieldName, oldVal, newVal ) );
}

function gfEnemyCount( localClientNum, oldVal, newVal, bNewEnt, bInitialSnap, fieldName, bWasTimeJump )
{
	model = CreateUIModel( GetUIModelForController( localClientNum ), "hudItems.gfenemyteam_size_num" );
	SetUIModelValue( model, newVal );
	//IPrintLnBold( sprintf( "LCN {0} | Field: {1}, Values: {2} {3}", localClientNum, fieldName, oldVal, newVal ) );
}
