#using scripts\shared\array_shared;
#using scripts\shared\callbacks_shared;
#using scripts\shared\gameobjects_shared;
#using scripts\shared\math_shared;
#using scripts\shared\util_shared;

#insert scripts\shared\shared.gsh;

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

	self waitForStreamer();

	self.pers["class"] = level.defaultClass;
	self.curClass = level.defaultClass;

	self globallogic_ui::closeMenus();
	self CloseMenu("ChooseClass_InGame");
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
		if( player.pers["team"] == team && b_isAlive )
			array::add( players, player );
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