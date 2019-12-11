require("ui.t7.utility.lobbyutilityog") -- Ripped original file from Wraith

function Engine.GetLobbyMaxClients()
	local maxPlayers = 4
	Engine.SetDvar("sv_maxclients", maxPlayers)
	Engine.SetDvar("com_maxclients", maxPlayers)
	Engine.SetLobbyMaxClients(Enum.LobbyType.LOBBY_TYPE_GAME, maxPlayers)
	Engine.SetLobbyMaxClients(Enum.LobbyType.LOBBY_TYPE_PRIVATE, maxPlayers)
	return maxPlayers
end