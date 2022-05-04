require('mysqloo')

hub_data.conn = mysqloo.connect(hub_data.db_config.hostname, hub_data.db_config.username, hub_data.db_config.password, hub_data.db_config.database, hub_data.db_config.port)

hub_data.conn.onConnectionFailed = function(self, err)
	print("hub-data connection error:", err)
end

hub_data.conn:connect()

do
	local query = hub_data.conn:query(("REPLACE INTO `ServerInfo` VALUES ('%s', '%s', '%s', %s, %s)"):format(game.GetIPAddress(), GetConVar('hostname'):GetString(), game.GetMap(), player.GetCount(), game.MaxPlayers()))

	query.onError = function(self, err, sql)
		print("query error: ", err, "\nsql:", sql)
	end

	query:start()
end

local preparedError = function(self, err)
	print('query error: ', err)
end

local updatePlayerCount = hub_data.conn:prepare("UPDATE `ServerInfo` SET `players` = ?")
updatePlayerCount.onError = preparedError

hook.Add("PlayerInitialSpawn", "hub-data", function(pl)
	updatePlayerCount:setNumber(1, player.GetCount())
	updatePlayerCount:start()
end)

hook.Add("PlayerDisconnected", "hub-data", function(pl)
	timer.Simple(0, function()
		updatePlayerCount:setNumber(1, player.GetCount())
		updatePlayerCount:start()
	end)
end)

local updateHostname = hub_data.conn:prepare("UPDATE `ServerInfo` SET `hostname` = ?")
updateHostname.onError = preparedError

cvars.AddChangeCallback('hostname', function(convar, old, new)
	updateHostname:setString(1, new)
	updateHostname:start()
end)