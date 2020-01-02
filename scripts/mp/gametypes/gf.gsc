#using scripts\shared\array_shared;
#using scripts\shared\callbacks_shared;
#using scripts\shared\clientfield_shared;
#using scripts\shared\gameobjects_shared;
#using scripts\shared\math_shared;
#using scripts\shared\player_shared;
#using scripts\shared\util_shared;

#using scripts\mp\_util;

#using scripts\mp\killstreaks\_killstreaks;

#using scripts\mp\gametypes\_dogtags;
#using scripts\mp\gametypes\_globallogic;
#using scripts\mp\gametypes\_globallogic_audio;
#using scripts\mp\gametypes\_globallogic_defaults;
#using scripts\mp\gametypes\_globallogic_score;
#using scripts\mp\gametypes\_globallogic_spawn;
#using scripts\mp\gametypes\_globallogic_ui;
#using scripts\mp\gametypes\_globallogic_utils;
#using scripts\mp\gametypes\_spawning;
#using scripts\mp\gametypes\_spawnlogic;
#using scripts\mp\gametypes\dom;

#using scripts\mp\teams\_teams;

#insert scripts\shared\shared.gsh;
#insert scripts\shared\version.gsh;

#precache( "string", "MOD_OBJECTIVES_GUN" );
#precache( "string", "MOD_OBJECTIVES_GUN_SCORE" );
#precache( "string", "MOD_OBJECTIVES_GUN_HINT" );
#precache( "string", "MOD_ROUND_HAD_MORE_HP" );
#precache( "string", "MOD_REVIVE_TEAMMATE" );
#precache( "xmodel", "p7_dogtags_enemy" );

#define WEAPON_TABLE 		"gamedata/tables/mp/gf_weapons.csv"
#define WT_COL_SLOT 		0
#define WT_COL_PRIMARY 		1
#define WT_COL_SECONDARY 	2
#define WT_COL_LETHAL 		3
#define WT_COL_TACTICAL 	4
#define WT_COL_PERKS 		5
#define WT_COL_REFERENCE 	6
#define WT_COL_PRIMARY_ATTACHMENTS 		7
#define WT_COL_SECONDARY_ATTACHMENTS	8

function main()
{
	globallogic::init();

	util::registerRoundSwitch( 0, 9 );
	util::registerTimeLimit( 0, 1440 );
	util::registerScoreLimit( 0, 500 );
	util::registerRoundLimit( 0, 12 );
	util::registerRoundWinLimit( 0, 10 );
	util::registerNumLives( 0, 100 );

	globallogic::registerFriendlyFireDelay( level.gameType, 15, 0, 1440 );

	gameobjects::register_allowed_gameobject( level.gameType );
	gameobjects::register_allowed_gameobject( "dom" ); // need dom flags

	globallogic_audio::set_leader_gametype_dialog( undefined, undefined, "gameBoost", "gameBoost" );

	globallogic::setvisiblescoreboardcolumns( "score", "kills", "deaths", "kdratio", "captures" );

	// Gamemode vars
	level.endGameOnScoreLimit = false;
	level.gunfightClassIdx = GetDvarInt( "scr_gf_class_idx", -1 );
	level.gunfightClassExcl = GetDvarString( "scr_gf_class_excl", "" );
	level.gunfightExtraMvmt = GetDvarInt( "scr_gf_extra_movement", 0 );
	level.gunfightOverTime = false;
	level.overrideTeamScore = true;
	level.respawnMechanic = GetDvarInt( "scr_gf_respawn", 0 );
	level.teamBased = true;
	level.timeLimitOverride = false;
	level.timePausesWhenInZone = GetGametypeSetting( "timePausesWhenInZone" );

	// Gamemode functions
	level.giveCustomLoadout = &giveCustomLoadout;
	level.onDeadEvent = &onDeadEvent;
	level.onPlayerDamage = &onPlayerDamage;
	level.onPlayerKilled = &onPlayerKilled;
	level.onRoundSwitch = &onRoundSwitch;
	level.onSpawnPlayer = &onSpawnPlayer;
	level.onStartGameType = &onStartGameType;
	level.onTimeLimit = &onTimeLimit;

	// Callbacks
	callback::on_connect( &onPlayerConnect );
	callback::on_disconnect( &onPlayerDisconnect );
	callback::on_spawned( &onPlayerSpawned );
	callback::on_start_gametype( &onCBStartGametype );

	// DVars
	// disable deathicons - if respawn is enabled
	SetDvar( "ui_hud_showdeathicons", !level.respawnMechanic );
	// disable medals overlaps with the gunfight hud
	SetDvar( "scr_game_medalsenabled", 0 );

	// LUI
	clientfield::register( "toplayer", "gffriendlyteam_health_num", VERSION_SHIP, 20, "int" );
	clientfield::register( "toplayer", "gffriendlyteam_size_num", VERSION_SHIP, 2, "int" );

	clientfield::register( "toplayer", "gfenemyteam_health_num", VERSION_SHIP, 20, "int" );
	clientfield::register( "toplayer", "gfenemyteam_size_num", VERSION_SHIP, 2, "int" );

	// DOM stuff
	game["dialog"]["securing_a"] = "domFriendlySecuringA";
	game["dialog"]["securing_b"] = "domFriendlySecuringB";
	game["dialog"]["securing_c"] = "domFriendlySecuringC";
	game["dialog"]["secured_a"] = "domFriendlySecuredA";
	game["dialog"]["secured_b"] = "domFriendlySecuredB";
	game["dialog"]["secured_c"] = "domFriendlySecuredC";
	game["dialog"]["secured_all"] = "domFriendlySecuredAll";
	game["dialog"]["losing_a"] = "domEnemySecuringA";
	game["dialog"]["losing_b"] = "domEnemySecuringB";
	game["dialog"]["losing_c"] = "domEnemySecuringC";
	game["dialog"]["lost_a"] = "domEnemySecuredA";
	game["dialog"]["lost_b"] = "domEnemySecuredB";
	game["dialog"]["lost_c"] = "domEnemySecuredC";
	game["dialog"]["lost_all"] = "domEnemySecuredAll";
	game["dialog"]["enemy_a"] = "domEnemyHasA";
	game["dialog"]["enemy_b"] = "domEnemyHasB";
	game["dialog"]["enemy_c"] = "domEnemyHasC";
	game["dialogTime"] = [];
	game["dialogTime"]["securing_a"] = 0;
	game["dialogTime"]["securing_b"] = 0;
	game["dialogTime"]["securing_c"] = 0;
	game["dialogTime"]["losing_a"] = 0;
	game["dialogTime"]["losing_b"] = 0;
	game["dialogTime"]["losing_c"] = 0;

	// uses gungame hud basically removes the specialist weapon from the hud
	SetDvar( "tu11_enableClassicMode", 1 );
}

function onStartGameType()
{
	SetClientNameMode( "manual_change" );

	if ( !isdefined( game["switchedsides"] ) )
	{
		game["switchedsides"] = false;
	}

	if ( game["switchedsides"] )
	{
		oldAttackers = game["attackers"];
		oldDefenders = game["defenders"];
		game["attackers"] = oldDefenders;
		game["defenders"] = oldAttackers;
	}

	level.displayRoundEndText = true;

	// now that the game objects have been deleted place the influencers
	spawning::create_map_placed_influencers();

	level.spawnMins = ( 0, 0, 0 );
	level.spawnMaxs = ( 0, 0, 0 );

	foreach ( team in level.teams )
	{
		util::setObjectiveText( team, &"MOD_OBJECTIVES_GUN" );
		util::setObjectiveHintText( team, &"MOD_OBJECTIVES_GUN_HINT" );

		if ( level.splitscreen )
		{
			util::setObjectiveScoreText( team, &"MOD_OBJECTIVES_GUN" );
		}
		else
		{
			util::setObjectiveScoreText( team, &"MOD_OBJECTIVES_GUN_SCORE" );
		}
	}

	// set SD spawnpoints
	spawnlogic::place_spawn_points( "mp_sd_spawn_attacker" );
	spawnlogic::place_spawn_points( "mp_sd_spawn_defender" );

	// set SD start spawnpoints
	level.spawn_start = [];
	level.spawn_start["axis"] = spawnlogic::get_spawnpoint_array( "mp_sd_spawn_defender" );
	level.spawn_start["allies"] = spawnlogic::get_spawnpoint_array( "mp_sd_spawn_attacker" );

	// force use startspawns to stop a few issues from the respawn mechanic
	level.useStartSpawns = true;
	level.alwaysUseStartSpawns = true;

	// need this for DOM script
	level.startPos["allies"] = level.spawn_start["allies"][0].origin;
	level.startPos["axis"] = level.spawn_start["axis"][0].origin;

	// map center
	level.mapCenter = math::find_box_center( level.spawnMins, level.spawnMaxs );
	SetMapCenter( level.mapCenter );

	// demo spawnpoint
	spawnpoint = spawnlogic::get_random_intermission_point();
	SetDemoIntermissionPoint( spawnpoint.origin, spawnpoint.angles );

	// init DOM stuff - vars and flags
	dom::updateGametypeDvars();
	thread dom::domFlags();

	// GF stuff
	gunfightUpdateDvars();
	gunfightFlagUpdate();
	gunfightPickClass();
}

function onPlayerConnect()
{
	self thread loadPlayer();

	self killstreaks::hide_compass();

	// because _globallogic::updateGameEvents isn't working have to manually update
	// all these sorts of functions manually
	if ( level.gameForfeited && util::totalPlayerCount() > 1 )
	{
		level.gameForfeited = false;
		level notify( "abort forfeit" );
	}
}

function onPlayerDisconnect()
{
	level endon( "game_ended" );

	// play sound first before code deletes player
	self thread playGFSound();
	// save this before the code delete
	leftTeam = self.team;

	// wait a network frame for various things to process
	util::wait_network_frame();

	thread updateGFHud();

	// check to see if game is going to now forfeit
	if ( !level.gameForfeited )
	{
		// don't end the game if we're now into forfeit
		if ( globallogic::checkForForfeit() )
			return;
	}

	// check to see if the team disconnected from has 0 players alive
	if ( globallogic::isTeamAllDead( leftTeam ) )
		[[level.onDeadEvent]]( leftTeam );
}

function onSpawnPlayer( predictedSpawn )
{
	spawning::onSpawnPlayer( predictedSpawn );
}

function onPlayerSpawned()
{
	self endon( "death" );
	self endon( "disconnect" );

	// Freeze bots for development
	if ( GetDvarInt( "scr_gf_dev_stop_bots", 1 ) && self IsTestClient() )
		self FreezeControlsAllowLook( true );

	self thread watchGrenadeUsage();

	self killstreaks::hide_compass();
	// TODO: need to research custom matches vs live matches in
	// dedicated servers because some code here may break i.e. forfeit
	//IPrintLn( sprintf( "mpCustomMatch: {0} | rankedMatch: {1}", level.mpCustomMatch, level.rankedMatch ) );

	thread updateGFHud();
}

function giveCustomLoadout()
{
	// copy the class
	weaponClass = level.gunfightClass;

	// take all weapons & perks
	self TakeAllWeapons();
	self ClearPerks();

	// weapon attachments are handled differently
	primary = ( isdefined( weaponClass["primaryAttachments"] ) ? GetWeapon( weaponClass["primary"], weaponClass["primaryAttachments"] ) : GetWeapon( weaponClass["primary"] ) );
	secondary = ( isdefined( weaponClass["secondaryAttachments"] ) ? GetWeapon( weaponClass["secondary"], weaponClass["secondaryAttachments"] ) : GetWeapon( weaponClass["secondary"] ) );

	// get equipment
	// TODO: implement them in a timer(?)
	lethal = GetWeapon( weaponClass["lethal"] );
	tactical = GetWeapon( weaponClass["tactical"] );

	// give primary & secondary, set primary as spawn weapon
	self GiveWeapon( primary );
	self GiveStartAmmo( primary );

	self SwitchToWeaponImmediate( primary );
	self SetSpawnWeapon( primary );

	self GiveWeapon( secondary );
	self GiveStartAmmo( secondary );

	// lethal grenade information
	lethalCount = ( lethal != level.nullPrimaryOffhand ? lethal.startAmmo : 0 );
	self GiveWeapon( lethal );
	self SetWeaponAmmoClip( lethal, lethalCount );
	self SwitchToOffHand( lethal );
	self.grenadeTypePrimary = lethal;
	self.grenadeTypePrimaryCount = lethalCount;

	// tactical grenade information
	tacticalCount = ( tactical != level.nullSecondaryOffhand ? tactical.startAmmo : 0 );
	self GiveWeapon( tactical );
	self SetWeaponAmmoClip( tactical, tacticalCount );
	self SwitchToOffHand( tactical );
	self.grenadeTypeSecondary = tactical;
	self.grenadeTypeSecondaryCount = tacticalCount;

	// disable T7 movement if needed
	if ( !level.gunfightExtraMvmt )
	{
		self AllowDoubleJump( false );
		self AllowSlide( false );
		self AllowWallRun( false );
	}

	// return the primary weapon
	return primary;
}

function gunfightUpdateDvars()
{
	// reset the class dvars if it's the first round (for example from fast_restart/map_restart)
	if ( util::getRoundsPlayed() == 0 )
	{
		SetDvar( "scr_gf_class_idx", -1 );
		SetDvar( "scr_gf_class_excl", "" );
	}

	level.gunfightClassIdx = GetDvarInt( "scr_gf_class_idx" );
	level.gunfightClassExcl = GetDvarString( "scr_gf_class_excl" );
	level.gunfightExtraMvmt = GetDvarInt( "scr_gf_extra_movement" );
}

function gunfightPickClass()
{
	// TODO: possibly add specific playlist-style only tiers? i.e. shotguns classes only
	tiers = [];
	ARRAY_ADD( tiers, "random" );
	//ARRAY_ADD( tiers, "random_<>" );

	gunfightGenerateClasses( array::random( tiers ) );

	if ( level.gunfightClassIdx == -1 )
	{
		// remove classes that have been used
		if ( isdefined( level.gunfightClassExcl ) && level.gunfightClassExcl != "" )
		{
			exclClasses = StrTok( level.gunfightClassExcl, " " );

			foreach ( exclIdx in exclClasses )
			{
				// just do some sanity check in case some host tries to mess with stuff
				if ( exclIdx != " " && Int( exclIdx ) > 0 )
					ArrayRemoveIndex( level.gunfightWeaponTable, Int( exclIdx ) );
			}
		}

		weaponClass = array::random( level.gunfightWeaponTable );
		SetDvar( "scr_gf_class_idx", weaponClass["index"] );
	}
	else
		weaponClass = level.gunfightWeaponTable[ level.gunfightClassIdx ];

	level.gunfightClass = weaponClass;
}

function gunfightGenerateClasses( tblReference )
{
	level.gunfightWeaponTable = [];

	for( i = 0; i < TableLookupRowCount( WEAPON_TABLE ); i++ )
	{
		itemRow = TableLookupRowNum( WEAPON_TABLE, WT_COL_SLOT, i );

		if ( itemRow > -1 )
		{
			reference = TableLookupColumnForRow( WEAPON_TABLE, itemRow, WT_COL_REFERENCE );
			// strtok reference for more options?
			// TODO: something about classes I need to remove indexes that are used
			// or avoid them rather possible randomize and store as a dvar (a numbered list?)
			if ( tblReference == reference )
			{
				primary = TableLookupColumnForRow( WEAPON_TABLE, itemRow, WT_COL_PRIMARY );
				secondary = TableLookupColumnForRow( WEAPON_TABLE, itemRow, WT_COL_SECONDARY );
				lethal = TableLookupColumnForRow( WEAPON_TABLE, itemRow, WT_COL_LETHAL );
				tactical = TableLookupColumnForRow( WEAPON_TABLE, itemRow, WT_COL_TACTICAL );
				perks = TableLookupColumnForRow( WEAPON_TABLE, itemRow, WT_COL_PERKS );
				primaryAttachments = TableLookupColumnForRow( WEAPON_TABLE, itemRow, WT_COL_PRIMARY_ATTACHMENTS );
				secondaryAttachments = TableLookupColumnForRow( WEAPON_TABLE, itemRow, WT_COL_SECONDARY_ATTACHMENTS );

				level.gunfightWeaponTable[i]["index"] = itemRow - 1; // have to decrement because itemRow isn't actually the "index"
				level.gunfightWeaponTable[i]["primary"] = primary;
				level.gunfightWeaponTable[i]["secondary"] = secondary;
				level.gunfightWeaponTable[i]["lethal"] = lethal;
				level.gunfightWeaponTable[i]["tactical"] = tactical;
				level.gunfightWeaponTable[i]["perks"] = perks;
				level.gunfightWeaponTable[i]["reference"] = reference;

				if ( isdefined( primaryAttachments ) )
				{
					primaryAttachments = StrTok( primaryAttachments, "+" );
					level.gunfightWeaponTable[i]["primaryAttachments"] = primaryAttachments;
				}
				if ( isdefined( secondaryAttachments ) )
				{
					secondaryAttachments = StrTok( secondaryAttachments, "+" );
					level.gunfightWeaponTable[i]["secondaryAttachments"] = secondaryAttachments;
				}

				// DEBUG
				//IPrintLnBold( sprintf( "IDX: {0} | Primary: {1} | Secondary: {2} | Lethal: {3} | Tactical: {4} | Perks: {5} | Reference: {6} | ARRAY IDX: {7}", itemRow - 1, primary, secondary, lethal, tactical, perks, reference, i ) );
			}
		}
	}
}

function gunfightFlagUpdate()
{
	foreach ( flagObj in level.domFlags )
	{
		// delete all flags that isn't the B flag
		// TODO: maybe just disable them instead? Could be used for
		// custom gamemodes I guess
		if ( flagObj.label != "_b" )
		{
			flagObj gameobjects::destroy_object();
		}
		else
		{
			// disable B flag and update the model
			flagObj gameobjects::disable_object();
			flagObj gameobjects::allow_use( "none" );
			flagObj gameobjects::set_model_visibility( false );
			flagObj.visuals[0] SetModel( teams::get_flag_model( "neutral" ) );
			level.gunfightFlag = flagObj;
		}
	}
}

function gunfightSpawnFlag()
{
	// show the B flag and monitor for flag-cap
	level.gunfightFlag gameobjects::enable_object();
	level.gunfightFlag gameobjects::allow_use( "any" );
	level.gunfightFlag gameobjects::set_model_visibility( true );
	level.gunfightFlag gameobjects::set_use_time( 2.5 );
	level.gunfightFlag.onBeginUse = &gfFlagOnBeginUse;
	level.gunfightFlag.onEndUse = &gfFlagOnEndUse;

	level thread watchForFlagCap();
}

function gfFlagOnBeginUse( player )
{
	pause_time();
	self dom::onBeginUse( player );
}

function gfFlagOnEndUse( team, player, success )
{
	resume_time();
	self dom::onEndUse( team, player, success );
}

function watchForFlagCap()
{
	level endon( "game_ended" );

	level waittill( "b_flag_captured", player );

	gf_endGame( player.team, &"MP_DOM_YOUR_FLAG_WAS_CAPTURED" );
}

function onDeadEvent( team )
{
	if ( team == game["attackers"] )
	{
		gf_endGame( game["defenders"], game["strings"][game["attackers"]+"_eliminated"] );
	}
	else if ( team == game["defenders"] )
	{
		gf_endGame( game["attackers"], game["strings"][game["defenders"]+"_eliminated"] );
	}
}

function onPlayerDamage( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime )
{
	//IPrintLnBold( "Damage from: " + sWeapon.rootWeapon.name + " is: ^1" + iDamage );
	thread updateGFHud();

	return iDamage;
}

function onPlayerKilled( eInflictor, attacker, iDamage, sMeansOfDeath, weapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration )
{
	self thread playGFSound();

	thread updateGFHud();

	if ( level.respawnMechanic )
	{
		should_spawn_tags = self dogtags::should_spawn_tags( eInflictor, attacker, iDamage, sMeansOfDeath, weapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration );

		// we should spawn tags if one the previous statements were true and we may not spawn
		should_spawn_tags = should_spawn_tags && !globallogic_spawn::maySpawn();

		if ( should_spawn_tags && level.aliveCount[ self.team ] > 0 )
			self thread createPlayerRespawn( attacker );
	}
}

function onRoundSwitch()
{
	if ( !isdefined( game["switchedsides"] ) )
		game["switchedsides"] = false;

	level.halftimeType = "halftime";
	game["switchedsides"] = !game["switchedsides"];

	// reset the class dvar
	SetDvar( "scr_gf_class_idx", -1 );
	// add this class to excl classes
	SetDvar( "scr_gf_class_excl", ( level.gunfightClassIdx + " " + level.gunfightClassExcl ) );
}

function pause_time()
{
	if ( level.timePausesWhenInZone )
	{
		globallogic_utils::pauseTimer();
		level.timerPaused = true;
	}
}

function resume_time()
{
	if ( level.timePausesWhenInZone )
	{
    	globallogic_utils::resumeTimer();
    	level.timerPaused = false;
	}
}

function gfGetTimeLimit()
{
	// override the game's default timelimit func to add 20s on top of
	// the timeLimit in order to support timer funcs and a few other bits
	// that begins to fail if you use level.timeLimitOverride
	return globallogic_defaults::default_getTimeLimit() + (20/60); // add 20s
}

function onTimeLimit()
{
	if ( !level.gunfightOverTime )
	{
		level.gunfightOverTime = true;
		level.getTimeLimit = &gfGetTimeLimit;

		// show the flag and start the new timer
		gunfightSpawnFlag();
		return;
	}

	// once time runs out from the OBJ flag determine the winnner
	alliesHealth = calculateHealthForTeam( "allies" );
	axisHealth = calculateHealthForTeam( "axis" );

	// if the health for the teams are the same it's a draw
	if ( alliesHealth == axisHealth )
	{
		gf_endGame( "tie", &"MP_ROUND_DRAW" );
		return;
	}

	// determine the winner from best health
	winner = ( alliesHealth > axisHealth ? "allies" : "axis" );
	gf_endGame( winner, &"MOD_ROUND_HAD_MORE_HP" );
}

function gf_endGame( winningTeam, endReasonText )
{
	// if match ended in a tie don't give points, also should I use delay in case players die before 15 sec
	if ( isdefined( winningTeam ) && winningTeam != "tie" )
		globallogic_score::giveTeamScoreForObjective_DelayPostProcessing( winningTeam, 1 );

	thread globallogic::endGame( winningTeam, endReasonText );
}

function createPlayerRespawn( attacker )
{
	player = self;

	// save the weapondata
	foreach ( weapon in player GetWeaponsList( true ) )
	{
		// grenades are dropped upon death, so we need to ignore the weapon if we were holding it
		if ( self._throwingGrenade === weapon )
			continue;

		ARRAY_ADD( player._weapons, player::get_weapondata( weapon ) );
	}

	model = Spawn( "script_model", player.origin );
	model SetModel( player GetFriendlyDogTagModel() );
	model DontInterpolate();
	model HideFromTeam( util::getOtherTeam( player.team ) );
	model ShowToTeam( player.team );

	visuals = Array( model );

	// trigger
	trigger = Spawn( "trigger_radius_use", player.origin + (0,0,16), 0, 32, 32 );
	trigger SetCursorHint( "HINT_NOICON" );
	trigger TriggerIgnoreTeam();
	trigger UseTriggerRequireLookAt();

	// object - base
	obj = gameobjects::create_use_object( player.team, trigger, visuals, (0,0,0), IString( "headicon_dead" ) );
	obj gameobjects::set_use_time( 5 );
	obj gameobjects::set_use_text( &"MOD_REVIVE_TEAMMATE" );
	obj gameobjects::set_use_hint_text( &"MOD_REVIVE_TEAMMATE" );
	obj gameobjects::allow_use( "friendly" );
	obj gameobjects::set_visible_team( "friendly" );
	obj gameobjects::set_owner_team( player.team );

	// object - functionality
	obj.onUse = &onTagUse;
	obj.targetPlayer = player;

	// makes the dogtags bounce
	obj thread bounce();

	// delete the gameobject when round/match ends or when player DC's
	obj thread deleteOnEnd();
}

function onTagUse( player )
{
	const maxHealth = 65;

	self.targetPlayer.pers["lives"] = 1;
	self.targetPlayer [[level.spawnClient]]();

	// set the origin back to the deathpoint
	self.targetPlayer SetOrigin( self.origin - (0,0,32) );

	// make the player take some damage
	// TODO: since we're just overriding the health I believe we need to actually send
	// some damage through in order for clientside to pick up we're hurt
	self.targetPlayer.health = maxHealth;
	self.targetPlayer.maxhealth = maxHealth;

	// wait a server frame to ensure player is back
	WAIT_SERVER_FRAME;

	// make sure to take away their inventory before giving it back
	self.targetPlayer TakeAllWeapons();
	self.targetPlayer player::give_back_weapons( true );

	// delete the gameobject afterwards
	self gameobjects::destroy_object();
}

function onCBStartGametype()
{
	// act like a CUAV is there in order to disable the minimap
	// have to wait until it exists
	while ( !isdefined( level.activeCounterUAVs ) )
		WAIT_SERVER_FRAME;

	// increment CUAV for both teams
	level.activeCounterUAVs["allies"]++;
	level.activeCounterUAVs["axis"]++;

	// notify that CUAV is in
	level notify( "counter_uav_updated" );

	level.gracePeriod = 0;
}

function loadPlayer()
{
	level endon( "game_ended" );
	self endon( "death" );
	self endon( "disconnect" );
	self endon( "spawned" );

	if ( IS_TRUE( self.hasSpawned ) || !level.inGracePeriod )
	{
		return;
	}

	if ( isdefined( self.pers["team"] ) && self.pers["team"] == "spectator" )
	{
		return;
	}

	// satisfy globallogic_spawn maySpawn() to prevent errors on spawn
	self.pers["lives"] = 1;
	self.waitingToSpawn = true;

	// satisfy matchRecordLogAdditionalDeathInfo 5th parameter (_globallogic_player)
	self.class_num = 0;

	// set a default class
	self.pers["class"] = level.defaultClass;
	self.curClass = level.defaultClass;

	// close all menus
	self globallogic_ui::closeMenus();
	self CloseMenu( "ChooseClass_InGame" );

	// wait for streamer
	self waitForStreamer();

	self thread [[level.spawnClient]]();
}

function waitForStreamer()
{
	started_waiting = GetTime();
	while ( !self IsStreamerReady( -1, 1 ) && started_waiting + 90000 > GetTime() )
	{
		WAIT_SERVER_FRAME;
	}
}

function calculateHealthForTeam( team )
{
	teamHealth = 0;

	foreach ( player in level.players )
	{
		if ( !IsAlive( player ) )
			continue;

		if ( player.team != team )
			continue;

		teamHealth += player.health;
	}

	return teamHealth;
}

function updateGFHud()
{
	level endon ( "game_ended" );

	level notify ( "updateGFHud_singleton" );
	level endon ( "updateGFHud_singleton" );

	// wait a network frame to process the damage completely
	util::wait_network_frame();

	alliesHealth = calculateHealthForTeam( "allies" );
	alliesCount = level.aliveCount[ "allies" ];

	axisHealth = calculateHealthForTeam( "axis" );
	axisCount = level.aliveCount[ "axis" ];

	foreach ( player in level.players )
	{
		friendlyTeam = player.team;
		enemy_team = util::getOtherTeam( player.team );

		friendlyHealth = ( friendlyTeam == "allies" ? alliesHealth : axisHealth );
		friendlyCount = ( friendlyTeam == "allies" ? alliesCount : axisCount );

		enemyHealth = ( enemy_team == "axis" ? axisHealth : alliesHealth );
		enemyCount = ( enemy_team == "axis" ? axisCount : alliesCount );

		// update friendly first
		player clientfield::set_to_player( "gffriendlyteam_health_num", Int( friendlyHealth ) );
		player clientfield::set_to_player( "gffriendlyteam_size_num", Int( friendlyCount ) );

		// update enemy team after
		player clientfield::set_to_player( "gfenemyteam_health_num", Int( enemyHealth ) );
		player clientfield::set_to_player( "gfenemyteam_size_num", Int( enemyCount ) );
	}
}

function playGFSound()
{
	friendlySnd = "cyber_friendly_dies";
	enemySnd = "cyber_enemy_dies";

	// only 1 left alive aka we now process to final death
	if ( level.aliveCount[ self.team ] == 1 )
	{
		friendlySnd += "_final";
		enemySnd += "_final";
	}

	self PlaySoundToTeam( friendlySnd, self.team );
	self PlaySoundToTeam( enemySnd, util::getOtherTeam( self.team ) );
}

function private watchGrenadeUsage()
{
	self endon( "death" );
	self endon( "disconnect" );

	// custom monitor system to handle equipment -- handles lethal/tactical
	self._throwingGrenade = level.weaponNone;

	// monitor for when the grenade "ends"
	self thread watchGrenadeEnd();

	while ( true )
	{
		self waittill( "grenade_pullback", weapon );

		self._throwingGrenade = weapon;
	}
}

function private watchGrenadeEnd()
{
	self endon( "death" );
	self endon( "disconnect" );

	while ( true )
	{
		// we consider end on cancelled or fired
		msg = self util::waittill_any_return( "grenade_fire", "grenade_throw_cancelled" );

		if ( self._throwingGrenade == level.weaponNone )
			continue;

		self._throwingGrenade = level.weaponNone;
	}
}

function private deleteOnEnd()
{
	self.trigger endon( "destroyed" );

	util::waittill_any_ents_two( self.targetPlayer, "disconnect", level, "game_ended" );

	if ( isdefined( self ) )
		self gameobjects::destroy_object();
}

function private bounce()
{
	level endon( "game_ended" );
	self endon( "reset" );
	self.trigger endon( "destroyed" );

	bottomPos = self.curOrigin;
	topPos = self.curOrigin + (0,0,12);

	while( isdefined( self ) )
	{
		self.visuals[0] MoveTo( topPos, 0.5, 0.15, 0.15 );
		self.visuals[0] RotateYaw( 180, 0.5 );

		wait( 0.5 );

		self.visuals[0] MoveTo( bottomPos, 0.5, 0.15, 0.15 );
		self.visuals[0] RotateYaw( 180, 0.5 );

		wait( 0.5 );
	}
}