# Irresistible Gaming Development Framework
#### Copyright (C) 2011-2018

**Source Contributors:**  Lorenc ("Lorenc") Pekaj, Steven ("Stev") Howard

**BIG THANKS to Stev, Nibble, Banging7Grams, Kova, Queen and Panther for making this possible.**

### Script Callbacks

- `public SetPlayerRandomSpawn( playerid )`
    - Called when a player is attempting to be respawned somewhere randomly
- `public OnServerUpdate( )`
    - Called every second (or sooner) indefinitely
- `public OnPlayerUpdateEx( playerid )`
    - Same interval as OnServerUpdate, but it is called indefinitely for every player in-game
    - When you wish to update something frequently, but not use OnPlayerUpdate
- `OnServerGameDayEnd( )`
    - Called every 24 minutes in-game (basically when a new day starts)
- `OnNpcConnect( npcid )`
    - Called specifically when an NPC connects, as OnPlayerConnect will not
- `OnNpcDisconnect( npcid, reason )`
    - Called specifically when an NPC disconnects, as OnPlayerDisconnect will not
- `OnPlayerDriveVehicle( playerid, vehicleid )`
    - Called when a player enters a vehicle as a driver
- `OnPlayerLogin( playerid, accountid )`
    - Called when a player successfully logs into their account
- `OnHouseOwnerChange( houseid, ownerid )`
    - Called when the ownership of a home is changed
- `OnPlayerFirstSpawn( playerid )`
    - Called when a player spawns for the first time
- `OnPlayerMovieMode( playerid, toggled )`
    - Called when player toggles movie mode
- `OnPlayerAccessEntrance( playerid, entranceid )`
    - Called when a player accesses an entrance id
- `OnPlayerEndModelPreview( playerid, handleid )`
	- Called when a player closes a model preview
