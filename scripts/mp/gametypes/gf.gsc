#using scripts\shared\array_shared;
#using scripts\shared\callbacks_shared;
#using scripts\shared\gameobjects_shared;
#using scripts\shared\math_shared;
#using scripts\shared\player_shared;
#using scripts\shared\util_shared;

#using scripts\mp\_util;

#using scripts\mp\killstreaks\_killstreaks;

#using scripts\mp\gametypes\_dogtags;
#using scripts\mp\gametypes\_globallogic;
#using scripts\mp\gametypes\_globallogic_audio;
#using scripts\mp\gametypes\_globallogic_score;
#using scripts\mp\gametypes\_globallogic_spawn;
#using scripts\mp\gametypes\_globallogic_ui;
#using scripts\mp\gametypes\_globallogic_utils;
#using scripts\mp\gametypes\_spawning;
#using scripts\mp\gametypes\_spawnlogic;
#using scripts\mp\gametypes\dom;

#insert scripts\shared\shared.gsh;

#precache( "string", "MOD_OBJECTIVES_GUN" );
#precache( "string", "MOD_OBJECTIVES_GUN_SCORE" );
#precache( "string", "MOD_OBJECTIVES_GUN_HINT" );
#precache( "xmodel", "p7_dogtags_enemy" );

function main()
{
	globallogic::init();
	// Gamemode util
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

	// Sets the scoreboard columns and determines with data is sent across the network
	globallogic::setvisiblescoreboardcolumns( "score", "kills", "deaths", "kdratio", "captures" );
	//
	level.endGameOnScoreLimit = false;
	level.overrideTeamScore = true;
	level.respawnMechanic = GetDvarInt("scr_gf_respawn", 0);
	level.teamBased = true;
	level.timeLimitOverride = false;
	//
	//level.giveCustomLoadout = &giveCustomLoadout;
	//
	level.onDeadEvent = &onDeadEvent;
	//
	level.onPlayerDamage = &onPlayerDamage;
	level.onPlayerKilled = &onPlayerKilled;
	//
	level.onRoundSwitch = &onRoundSwitch;
	//
	level.onSpawnPlayer = &onSpawnPlayer;
	//
	level.onStartGameType = &onStartGameType;
	//
	level.onTimeLimit = &onTimeLimit;
	// Callbacks
	callback::on_connect( &onPlayerConnect );
	callback::on_spawned( &onPlayerSpawned );
	callback::on_start_gametype( &onCBStartGametype );
	// DVars
	// disable deathicons - if respawn is enabled
	SetDvar( "ui_hud_showdeathicons", !level.respawnMechanic );
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
}

function onStartGameType()
{
	setClientNameMode("manual_change");

	if ( !isdefined( game["switchedsides"] ) )
		game["switchedsides"] = false;

	if ( game["switchedsides"] )
	{
		oldAttackers = game["attackers"];
		oldDefenders = game["defenders"];
		game["attackers"] = oldDefenders;
		game["defenders"] = oldAttackers;
	}

	level.displayRoundEndText = false;

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

		spawnlogic::add_spawn_points( team, "mp_tdm_spawn" );


		spawnlogic::place_spawn_points( spawning::getTDMStartSpawnName(team) );
	}

	spawning::updateAllSpawnPoints();

	level.spawn_start = [];
	level.alwaysUseStartSpawns = true;

	foreach ( team in level.teams )
	{
		level.spawn_start[ team ] =  spawnlogic::get_spawnpoint_array( spawning::getTDMStartSpawnName(team) );
	}
	// need this for DOM script
	level.startPos["allies"] = level.spawn_start[ "allies" ][0].origin;
	level.startPos["axis"] = level.spawn_start[ "axis" ][0].origin;

	level.mapCenter = math::find_box_center( level.spawnMins, level.spawnMaxs );
	SetMapCenter( level.mapCenter );

	spawnpoint = spawnlogic::get_random_intermission_point();
	SetDemoIntermissionPoint( spawnpoint.origin, spawnpoint.angles );

	// init DOM stuff - vars and flags
	dom::updateGametypeDvars();
	thread dom::domFlags();
	gunfightFlagUpdate();
}

function onPlayerConnect()
{
	self thread loadPlayer();
	// hide compass
	self killstreaks::hide_compass();
}

function onSpawnPlayer(predictedSpawn)
{
	spawning::onSpawnPlayer(predictedSpawn);
}

function onPlayerSpawned()
{
	self endon( "death" );
	self endon( "disconnect" );

	// Freeze bots for development
	if ( GetDvarInt( "scr_gf_dev_stop_bots", 1 ) && self IsTestClient() )
		self FreezeControlsAllowLook( true );
	//
	self thread watchGrenadeUsage();
	// hide compass
	self killstreaks::hide_compass();
}

function gunfightFlagUpdate()
{
	foreach ( flagObj in level.domFlags )
	{
		// delete all flags that isn't the B flag
		if ( flagObj.label != "_b" )
		{
			flagObj gameobjects::destroy_object();
		}
		else
		{
			// B flag disable
			flagObj gameobjects::disable_object();
			flagObj gameobjects::allow_use( "none" );
			flagObj gameobjects::set_model_visibility( false );
			level.gunfightFlag = flagObj;
		}
	}
}

function gunfightSpawnFlag()
{
	// TODO: fix the model/FX
	// show the B flag and monitor for flag-cap
	level.gunfightFlag gameobjects::enable_object();
	level.gunfightFlag gameobjects::allow_use( "any" );
	level.gunfightFlag gameobjects::set_model_visibility( true );
	level.gunfightFlag gameobjects::set_use_time( 2.5 );
	level thread watchForFlagCap();
}

function watchForFlagCap()
{
	level endon( "game_ended" );

	level waittill( "b_flag_captured", player );

	gf_endGame( player.team, &"MP_DOM_YOUR_FLAG_WAS_CAPTURED" );
}

function gunfightTimer()
{
	level endon( "game_ended" );
	// override the time
	level.timeLimitOverride = true;
	// calculate new time limit
	additionalTime = 30 * 1000;
	timeLimit = Int( GetTime() + additionalTime );
	// set the new time
	SetGameEndTime( timeLimit );
	// assign new timelimit var, internal one keeps changing
	level._timeLimit = timeLimit;
	// don't think MW has a sound effect when timer is counting down
	//level.bombTimer = timeLimit;
	//thread globallogic_utils::playTickingSound( "mpl_sab_ui_suitcasebomb_timer" );
	while ( game["state"] == "playing" )
	{
		// returns as milliseconds, so divide by 1000 for seconds
		timeRemaining = (level._timeLimit - GetTime());
		// if time is less than or equal to 0 AND we have made a flag, end the round
		if ( timeRemaining <= 0 )
		{
			[[level.onTimeLimit]]();
		}

		WAIT_SERVER_FRAME;
	}
}

function onDeadEvent( team )
{
	//winningTeam = (losingTeam === game["attackers"] ? game["defenders"] : game["attackers"]);
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
	IPrintLnBold( "Damage from: " + sWeapon.rootWeapon.name + " is: ^1" + iDamage );

	return iDamage;
}

function onPlayerKilled( eInflictor, attacker, iDamage, sMeansOfDeath, weapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration )
{
	if ( level.respawnMechanic )
	{
		should_spawn_tags = self dogtags::should_spawn_tags(eInflictor, attacker, iDamage, sMeansOfDeath, weapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration);

		// we should spawn tags if one the previous statements were true and we may not spawn
		should_spawn_tags = should_spawn_tags && !globallogic_spawn::maySpawn();

		if ( should_spawn_tags && getPlayersInTeam( self.team, true ).size > 0 )
			self thread createPlayerRespawn( attacker );
	}
}

function onRoundSwitch()
{
	if ( !isdefined( game["switchedsides"] ) )
		game["switchedsides"] = false;

	if ( game["teamScores"]["allies"] == level.scorelimit - 1 && game["teamScores"]["axis"] == level.scorelimit - 1 )
	{
		// overtime! team that's ahead in kills gets to defend.
		aheadTeam = getBetterTeam();
		if ( aheadTeam != game["defenders"] )
		{
			game["switchedsides"] = !game["switchedsides"];
		}
		level.halftimeType = "overtime";
	}
	else
	{
		level.halftimeType = "halftime";
		game["switchedsides"] = !game["switchedsides"];
	}
}

function onTimeLimit()
{
	if ( !level.timeLimitOverride )
	{
		gunfightSpawnFlag();
		thread gunfightTimer();
		return;
	}
	// once time runs out from the OBJ flag determine the winnner
	alliesHealth = calculateHealthForTeam( "allies" );
	axisHealth = calculateHealthForTeam( "axis" );
	// if the health for the teams are the same it's a draw
	if ( alliesHealth == axisHealth )
	{
		// draw tie message
		gf_endGame( "tie", "Round ended in a draw" );
		return;
	}
	// determine the winner from best health
	winner = (alliesHealth > axisHealth ? "allies" : "axis" );
	// end the round and give the winner team score
	gf_endGame( winner, "Team had more health!" );
}

function getBetterTeam()
{
	kills["allies"] = 0;
	kills["axis"] = 0;
	deaths["allies"] = 0;
	deaths["axis"] = 0;

	for ( i = 0; i < level.players.size; i++ )
	{
		player = level.players[i];
		team = player.pers["team"];
		if ( isdefined( team ) && (team == "allies" || team == "axis") )
		{
			kills[ team ] += player.kills;
			deaths[ team ] += player.deaths;
		}
	}

	if ( kills["allies"] > kills["axis"] )
		return "allies";
	else if ( kills["axis"] > kills["allies"] )
		return "axis";

	// same number of kills

	if ( deaths["allies"] < deaths["axis"] )
		return "allies";
	else if ( deaths["axis"] < deaths["allies"] )
		return "axis";

	// same number of deaths

	if ( randomint(2) == 0 )
		return "allies";
	return "axis";
}


function gf_endGame( winningTeam, endReasonText )
{
	// if match ended in a tie don't give points
	if ( isdefined( winningTeam ) && winningTeam != "tie" )
		globallogic_score::giveTeamScoreForObjective_DelayPostProcessing( winningTeam, 1 );

	thread globallogic::endGame( winningTeam, endReasonText );
}

function getPlayersInTeam( team, b_isAlive = false )
{
	players = [];
	foreach ( player in level.players )
	{
		if ( player.pers["team"] == team )
		{
			if ( b_isAlive )
			{
				if ( b_isAlive == IsAlive( player ) )
					array::add( players, player );
			}
			else
				array::add( players, player );
		}
	}
	return players;
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

	// model
	model = Spawn( "script_model", player.origin );
	model SetModel( player GetFriendlyDogTagModel() );
	model DontInterpolate();
	// hide from enemy team(s)
	foreach ( team in level.teams )
		model HideFromTeam( team );
	// only show to friendly team
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
	obj gameobjects::set_use_text( "Press &&1 to Revive Teammate" );
	obj gameobjects::set_use_hint_text( "Press &&1 to Revive Teammate" );
	obj gameobjects::allow_use( "friendly" );
	obj gameobjects::set_visible_team( "friendly" );
	obj gameobjects::set_owner_team( player.team );

	// object - functionality
	obj.onUse = &onTagUse;
	obj.targetPlayer = player;

	// makes the dogtags bounce
	obj thread bounce();
	// delete the gameobject when round/match ends or when player DC's
	obj thread deleteOnEnd(); // TODO: waittill game ends delete the tags
}

function onTagUse( player )
{
	self.targetPlayer.pers["lives"] = 1;
	self.targetPlayer [[level.spawnClient]]();
	// set the origin back to the deathpoint
	self.targetPlayer SetOrigin( self.origin - (0,0,32) );
	self.targetPlayer.health = 65;
	self.targetPlayer.maxhealth = 65;
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
	// spawn a CUAV in order to prevent the minimap
	// from revealing info when you hit ESC or other
	// locations for it to show up.

	// have to wait until it exists (well the script)
	while ( !isdefined( level.activeCounterUAVs ) )
		WAIT_SERVER_FRAME;
	// increment CUAV for both teams
	level.activeCounterUAVs[ "allies" ]++;
	level.activeCounterUAVs[ "axis" ]++;
	// notify that CUAV is in
	level notify( "counter_uav_updated" );
}

function loadPlayer()
{
	level endon("game_ended");
	self endon("death");
	self endon("disconnect");
	self endon("spawned");

	if ( IS_TRUE( self.hasSpawned ) )
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
	// wait for streamer
	self waitForStreamer();
	// set a default class
	self.pers["class"] = level.defaultClass;
	self.curClass = level.defaultClass;
	// close all menus
	self globallogic_ui::closeMenus();
	self CloseMenu( "ChooseClass_InGame" );
	// just spawn the player
	self thread [[level.spawnClient]]();
}

function waitForStreamer()
{
	started_waiting = GetTime();
	while( !self IsStreamerReady( -1, 1 ) && started_waiting + 90000 > GetTime() )
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

function private watchGrenadeUsage()
{
	self endon( "death" );
	self endon( "disconnect" );
	// custom monitor system to handle equipment -- handles both
	self._throwingGrenade = level.weaponNone;
	// monitor for when the grenade "ends"
	self thread watchGrenadeEnd();

	while ( true )
	{
		self waittill ( "grenade_pullback", weapon );

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
		self.visuals[0] moveTo( topPos, 0.5, 0.15, 0.15 );
		self.visuals[0] rotateYaw( 180, 0.5 );

		wait( 0.5 );

		self.visuals[0] moveTo( bottomPos, 0.5, 0.15, 0.15 );
		self.visuals[0] rotateYaw( 180, 0.5 );

		wait( 0.5 );
	}
}