#using scripts\shared\array_shared;
#using scripts\shared\callbacks_shared;
#using scripts\shared\gameobjects_shared;
#using scripts\shared\math_shared;
#using scripts\shared\util_shared;

#insert scripts\shared\shared.gsh;

#using scripts\mp\gametypes\_dogtags;
#using scripts\mp\gametypes\_globallogic;
#using scripts\mp\gametypes\_globallogic_audio;
#using scripts\mp\gametypes\_globallogic_score;
#using scripts\mp\gametypes\_globallogic_spawn;
#using scripts\mp\gametypes\_globallogic_ui;
#using scripts\mp\gametypes\_spawning;
#using scripts\mp\gametypes\_spawnlogic;

#using scripts\mp\_util;

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

	globallogic_audio::set_leader_gametype_dialog( undefined, undefined, "gameBoost", "gameBoost" );

	// Sets the scoreboard columns and determines with data is sent across the network
	globallogic::setvisiblescoreboardcolumns( "score", "kills", "deaths", "kdratio", "captures" );
	//
	level.teamBased = true;
	level.overrideTeamScore = true;
	level.endGameOnScoreLimit = false;
	level.respawnMechanic = GetDvarInt("scr_gf_respawn", 0);
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
	// Callbacks
	callback::on_connect( &onPlayerConnect );
	callback::on_spawned( &onPlayerSpawned );
	// DVars
	SetDvar( "ui_hud_showdeathicons", "0" ); // disable deathicons
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

	foreach( team in level.teams )
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

	foreach( team in level.teams )
	{
		level.spawn_start[ team ] =  spawnlogic::get_spawnpoint_array( spawning::getTDMStartSpawnName(team) );
	}

	level.mapCenter = math::find_box_center( level.spawnMins, level.spawnMaxs );
	setMapCenter( level.mapCenter );

	spawnpoint = spawnlogic::get_random_intermission_point();
	setDemoIntermissionPoint( spawnpoint.origin, spawnpoint.angles );

	dogtags::init();
}

function onPlayerConnect()
{
	self thread loadPlayer();
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
	if ( self IsTestClient() )
		self FreezeControlsAllowLook( true );
}

function loadPlayer()
{
	level endon("game_ended");
	self endon("death");
	self endon("disconnect");
	self endon("spawned");

	if( IS_TRUE( self.hasSpawned ) )
	{
		return;
	}

	if( isdefined( self.pers["team"] ) && self.pers["team"] == "spectator" )
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

		if( should_spawn_tags && getPlayersInTeam( self.team, true ).size > 0 )
		{
			IPrintLnBold( "SPAWNED DOGTAGS" );
			self thread createPlayerRespawn( attacker );
		}
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
	if ( isdefined( winningTeam ) )
		globallogic_score::giveTeamScoreForObjective_DelayPostProcessing( winningTeam, 1 );

	thread globallogic::endGame( winningTeam, endReasonText );
}

function getPlayersInTeam( team, b_isAlive = false )
{
	players = [];
	foreach( player in level.players )
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

function createPlayerRespawn( attacker )
{
	player = self;

	// model
	model = Spawn( "script_model", player.origin );
	model SetModel( "p7_dogtags_enemy" );
	visuals = Array( model );

	// trigger
	trigger = Spawn( "trigger_radius_use", player.origin + (0,0,16), 0, 32, 32 );
	trigger SetCursorHint( "HINT_NOICON" );
	trigger TriggerIgnoreTeam();
	trigger UseTriggerRequireLookAt();

	// gameobject - carry
	obj = gameobjects::create_use_object( player.team, trigger, visuals, (0,0,0), IString( "headicon_dead" ) );
	obj gameobjects::set_use_time( 5 );
	obj gameobjects::set_use_text( "Press &&1 to Revive Teammate" );
	obj gameobjects::set_use_hint_text( "Press &&1 to Revive Teammate" );
	obj gameobjects::allow_use( "friendly" );
	obj gameobjects::set_visible_team( "friendly" );
	obj gameobjects::set_owner_team( player.team );
	obj thread bounce();
	obj thread deleteOnEnd(); // TODO: waittill game ends delete the tags

	obj.onBeginUse = &on_begin_use_base;
	obj.onUse = &on_use_base;
	obj.targetPlayer = player;
	//obj.onEndUse = &onEndUse;
	// hide from enemy team(s)
	foreach( team in level.teams )
		model HideFromTeam( team );
	// only show to friendly team
	model ShowToTeam( player.team );
}

function on_begin_use_base( player )
{
	IPrintLnBold( "REVIVING BY: " + player.name );
}

function on_use_base( player )
{
	IPrintLnBold( "REVIVED: " + self.targetPlayer.name );

	self.targetPlayer.pers["lives"] = 1;
	self.targetPlayer [[level.spawnClient]]();
	self.targetPlayer SetOrigin( self.origin - (0,0,32));
	self.targetPlayer.health = 65; // TODO: experiment
	self.targetPlayer.maxhealth = 65; // TODO: experiment

	// TODO:
	// fix the class give, change health to 75 or whatever
	//self.targetPlayer

	self gameobjects::destroy_object();
}

function onEndUse( team, player, result )
{
	//IPrintLnBold( "RESULT: " + result + "?");
	//self destroy_object();
}

function private deleteOnEnd()
{
	self.trigger endon( "destroyed" );

	level waittill( "game_ended" );

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