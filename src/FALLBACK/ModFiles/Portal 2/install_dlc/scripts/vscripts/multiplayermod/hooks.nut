//---------------------------------------------------
//         *****!Do not edit this file!*****
//---------------------------------------------------
//   _  _            _                            
//  | || | ___  ___ | |__                         
//  | __ |/ _ \/ _ \| / /                         
//  |_||_|\___/\___/|_\_\_    _                 _ 
//  | __|_  _  _ _   __ | |_ (_) ___  _ _   ___(_)
//  | _|| || || ' \ / _||  _|| |/ _ \| ' \ (_-< _ 
//  |_|  \_,_||_||_|\__| \__||_|\___/|_||_|/__/(_)
//---------------------------------------------------
// Purpose: Define miscellaneous functions used to
//          hook onto player info and chat commands
//             supplied directly from our plugin
//---------------------------------------------------

// Runs when a player enters the server
function OnPlayerJoin(p, script_scope) {

    // GlobalSpawnClass Teleport
    if (GlobalSpawnClass.useautospawn) {
        TeleportToSpawnPoint(p, null)
    }

    //# Get player's index and store it #//
    PlayerID <- p.GetRootMoveParent()
    PlayerID <- PlayerID.entindex()

    //# Assign every new targetname to the player after blue and red are used #//
    if (PlayerID >= 3) {
        p.__KeyValueFromString("targetname", "player" + PlayerID)
    }

    //# Change player portal targetname #//
    local ent1 = null
    local ent2 = null
    local ent = null
    local portal1 = null
    local portal2 = null
    while (ent = Entities.FindByClassname(ent, "prop_portal")) {
        if (ent.GetName() == "") {
            if (ent1 == null) {
                ent1 = ent
            } else {
                ent2 = ent
            }
        }
    }

    try {
        if (ent1.entindex() > ent2.entindex()) {
            ent1.__KeyValueFromString("targetname", "player" + p.entindex() + "_portal" + "2")
            ent2.__KeyValueFromString("targetname", "player" + p.entindex() + "_portal" + "1")
            portal1 = ent2
            portal2 = ent1
        } else {
            ent1.__KeyValueFromString("targetname", "player" + p.entindex() + "_portal" + "1")
            ent2.__KeyValueFromString("targetname", "player" + p.entindex() + "_portal" + "2")
            portal1 = ent1
            portal2 = ent2
        }
        CreateEntityClass(portal1)
        CreateEntityClass(portal2)
        FindEntityClass(portal1).linkedprop <- null
        FindEntityClass(portal2).linkedprop <- null
    } catch (exception) {
        if (GetDeveloperLevel()) {
            printl("(P2:MM): Failed to rename portals" + exception)
        }
    }

    //# Set viewmodel targetnames so we can tell them apart #//
    local ent = null
    while (ent=Entities.FindByClassname(ent, "predicted_viewmodel")) {
        EntFireByHandle(ent, "addoutput", "targetname viewmodel_player" + ent.GetRootMoveParent().entindex(), 0, null, null)
        // printl("(P2:MM): Renamed predicted_viewmodel to viewmodel_player" + ent.GetRootMoveParent().entindex())
        // printl("" + ent.GetRootMoveParent().entindex() + " rotation " + ent.GetAngles())
        // printl("" + ent.GetRootMoveParent().entindex() + "    origin " + ent.GetOrigin())
    }

    // If the player is the first player to join, fix OrangeOldPlayerPos
    if (p.GetTeam() == 2) {
        if (OrangeCacheFailed) {
            OrangeOldPlayerPos <- p.GetOrigin()
            OrangeCacheFailed <- false
        }
    }

    // Run general map code after a player loads into the game
    if (PlayerID == 1) {
        PostMapLoad()
    }

    // Run code after player 2 joins
    if (PlayerID == 2) {
        PostPlayer2Join()
    }

    //# Set cvars on joining players' client #//
    SendToConsoleP232("sv_timeout 3")
    EntFireByHandle(clientcommand, "Command", "stopvideos", 0, p, p)
    EntFireByHandle(clientcommand, "Command", "r_portal_fastpath 0", 0, p, p)
    EntFireByHandle(clientcommand, "Command", "r_portal_use_pvs_optimization 0", 0, p, p)
    MapSupport(false, false, false, false, true, false, false)

    //# Say join message on HUD #//
    if (PluginLoaded) {
        JoinMessage <- GetPlayerName(PlayerID) + " joined the game"
    } else {
        JoinMessage <- "Player " + PlayerID + " joined the game"
    }
    // Set join message to player name
    JoinMessage = JoinMessage.tostring()
    joinmessagedisplay.__KeyValueFromString("message", JoinMessage)
    EntFireByHandle(joinmessagedisplay, "display", "", 0.0, null, null)
    if (PlayerID >= 2) {
        onscreendisplay.__KeyValueFromString("y", "0.075")
    }

    //# Set player color #//

    // Set a random color for clients that join after 16 have joined
    local pcolor = GetPlayerColor(p, false)

    // Set color of player's in-game model
    script_scope.Colored <- true
    EntFireByHandle(p, "Color", (pcolor.r + " " + pcolor.g + " " + pcolor.b), 0, null, null)

    // SETUP THE CLASS /////////////////
    local currentplayerclass = CreateGenericPlayerClass(p)

    // UPDATE THE CLASS
    currentplayerclass.portal1 <- portal1
    currentplayerclass.portal2 <- portal2

    // PRINT THE CLASS
    if (GetDeveloperLevel()) {
        printl("")
        printl("===== New player joined =====")
        printl("======== Class Info =========")
        foreach (thing in FindPlayerClass(p)) {
            printl(thing)
        }
        printl("=================================")
        print("")
    }

    /////////////////////////////////////

    //# SET THE COSMETICS #//
    SetCosmetics(p)

    // Set fog controller
    if (HasSpawned) {
        if (usefogcontroller) {
            EntFireByHandle(p, "setfogcontroller", defaultfog, 0, null, null)
        }
    }
}

// Runs after a player dies
function OnPlayerDeath(player) {
    if (GetDeveloperLevel()) {
        printl("(P2:MM): Player died!")
        MapSupport(false, false, false, false, false, player, false)
    }
}

// Runs after a player respawns
function OnPlayerRespawn(player) {
    // GlobalSpawnClass teleport
    if (GlobalSpawnClass.useautospawn) {
        TeleportToSpawnPoint(player, null)
    }

    MapSupport(false, false, false, false, false, false, player)

    if (GetDeveloperLevel()) {
        printl("(P2:MM): Player respawned!")
    }
}

// Runs after the host loads in
function PostMapLoad() {
    //# Discord Hook #//
    SendPythonOutput("hookdiscord Portal 2 Playing On: " + GetMapName())

    //## Cheat detection ##//
    SendToConsoleP232("prop_dynamic_create cheatdetectionp2mm")
    SendToConsoleP232("script SetCheats()")

    // Add a hook to the chat command function
    if (PluginLoaded) {
        printl("(P2:MM): Plugin Loaded")
        AddChatCallback("ChatCommands")
    }
    // Edit cvars & set server name
    SendToConsoleP232("mp_allowspectators 0")
    if (PluginLoaded) {
        SendToConsoleP232("hostname Portal 2: Multiplayer Mod Server hosted by " + GetPlayerName(1))
    } else {
        SendToConsoleP232("hostname Portal 2: Multiplayer Mod Server")
    }
    // Force spawn players in map
    AddBranchLevelName( 1, "P2 MM" )
    MapSupport(false, false, false, true, false, false, false)
    CreatePropsForLevel(true, false, false)
    // Enable fast download
    SendToConsoleP232("sv_downloadurl \"https://github.com/kyleraykbs/Portal2-32PlayerMod/raw/main/WebFiles/FastDL/portal2/\"")
    SendToConsoleP232("sv_allowdownload 1")
    SendToConsoleP232("sv_allowupload 1")
	
	// Elastic Player Collision
	EntFire("p2mm_servercommand", "command", "portal_use_player_avoidance 1", 1)
	
    if (DevMode) {
        SendToConsoleP232("developer 1")
        StartDevModeCheck <- true
    }

    if (RandomTurrets) {
        PrecacheModel("npcs/turret/turret_skeleton.mdl")
        PrecacheModel("npcs/turret/turret_backwards.mdl")
    }

	// Gelocity alias, put gelocity1(2,or 3) into console to easier changelevel
	SendToConsoleP232("alias gelocity1 changelevel workshop/596984281130013835/mp_coop_gelocity_1_v02")
	SendToConsoleP232("alias gelocity2 changelevel workshop/594730048530814099/mp_coop_gelocity_2_v01")
	SendToConsoleP232("alias gelocity3 changelevel workshop/613885499245125173/mp_coop_gelocity_3_v02")

    // Set original angles
    EntFire("p2mm_servercommand", "command", "script CanCheckAngle <- true", 0.32)

    local plr = Entities.FindByClassname(null, "player")
    // OriginalPosMain <- Entities.FindByClassname(null, "player").GetOrigin()
    // Entities.FindByClassname(null, "player").SetOrigin(Vector(plr.GetOrigin().x + 0.24526, plr.GetOrigin().y + 0.23458, OriginalPosMain.z + 0.26497))

    plr.SetHealth(230053963)

    EntFireByHandle(plr, "addoutput", "MoveType 8", 0, null, null)

    EntFire("p2mm_servercommand", "command", "script Entities.FindByName(null, \"blue\").SetHealth(230053963)", 0.9)
    EntFire("p2mm_servercommand", "command", "script CanHook <- true", 1)
    PostMapLoadDone <- true
}

// Runs when the second player loads in
function PostPlayer2Join() {
    if (!CheatsOn) {
        SendToConsoleP232("sv_cheats 0")
    }
    Player2Joined <- true
}

// Runs once the game begins
// (Two players have loaded in by now)
function GeneralOneTime() {
    EntFire("p2mm_servercommand", "command", "script ForceRespawnAll()", 1)

    // Single player maps with chapter titles
    local CHAPTER_TITLES =
    [
        { map = "sp_a1_intro1", title_text = "#portal2_Chapter1_Title", subtitle_text = "#portal2_Chapter1_Subtitle", displayOnSpawn = false,		displaydelay = 1.0 },
        { map = "sp_a2_laser_intro", title_text = "#portal2_Chapter2_Title", subtitle_text = "#portal2_Chapter2_Subtitle", displayOnSpawn = true,	displaydelay = 2.5 },
        { map = "sp_a2_sphere_peek", title_text = "#portal2_Chapter3_Title", subtitle_text = "#portal2_Chapter3_Subtitle", displayOnSpawn = true,	displaydelay = 2.5 },
        { map = "sp_a2_column_blocker", title_text = "#portal2_Chapter4_Title", subtitle_text = "#portal2_Chapter4_Subtitle", displayOnSpawn = true, displaydelay = 2.5 },
        { map = "sp_a2_bts3", title_text = "#portal2_Chapter5_Title", subtitle_text = "#portal2_Chapter5_Subtitle", displayOnSpawn = true,			displaydelay = 1.0 },
        { map = "sp_a3_00", title_text = "#portal2_Chapter6_Title", subtitle_text = "#portal2_Chapter6_Subtitle", displayOnSpawn = true,			displaydelay = 1.5 },
        { map = "sp_a3_speed_ramp", title_text = "#portal2_Chapter7_Title", subtitle_text = "#portal2_Chapter7_Subtitle", displayOnSpawn = true,	displaydelay = 1.0 },
        { map = "sp_a4_intro", title_text = "#portal2_Chapter8_Title", subtitle_text = "#portal2_Chapter8_Subtitle", displayOnSpawn = true,			displaydelay = 2.5 },
        { map = "sp_a4_finale1", title_text = "#portal2_Chapter9_Title", subtitle_text = "#portal2_Chapter9_Subtitle", displayOnSpawn = false,		displaydelay = 1.0 },
    ]

    local ent = Entities.FindByName(null, "blue")
    local playerclass = FindPlayerClass(ent)

    if (!fogs) {
        usefogcontroller <- false
        if (GetDeveloperLevel()) {
            printl("(P2:MM): No fog controller found, disabling fog controller")
        }
    } else {
        usefogcontroller <- true
        if (GetDeveloperLevel()) {
            printl("(P2:MM): Fog controller found, enabling fog controller")
        }
    }

    if (usefogcontroller) {
        foreach (fog in fogs) {
            EntFireByHandle(Entities.FindByName(null, fog.name), "addoutput", "OnTrigger p2mm_servercommand:command:script p2mmfogswitch(\"" + fog.fogname + "\")", 0, null, null)
        }

        defaultfog <- fogs[0].fogname

        local p = null
        while (p = Entities.FindByClassname(p, "player")) {
            EntFireByHandle(p, "setfogcontroller", defaultfog, 0, null, null)
        }
    }

    // Attempt to display chapter title
    foreach (index, level in CHAPTER_TITLES)
	{
		if (level.map == GetMapName() && level.displayOnSpawn )
		{
            foreach (index, level in CHAPTER_TITLES)
            {
                if (level.map == GetMapName() )
                {
                    EntFire( "@chapter_title_text", "SetTextColor", "210 210 210 128", 0.0 )
                    EntFire( "@chapter_title_text", "SetTextColor2", "50 90 116 128", 0.0 )
                    EntFire( "@chapter_title_text", "SetPosY", "0.32", 0.0 )
                    EntFire( "@chapter_title_text", "SetText", level.title_text, 0.0 )
                    EntFire( "@chapter_title_text", "display", "", level.displaydelay )

                    EntFire( "@chapter_subtitle_text", "SetTextColor", "210 210 210 128", 0.0 )
                    EntFire( "@chapter_subtitle_text", "SetTextColor2", "50 90 116 128", 0.0 )
                    EntFire( "@chapter_subtitle_text", "SetPosY", "0.35", 0.0 )
                    EntFire( "@chapter_subtitle_text", "settext", level.subtitle_text, 0.0 )
                    EntFire( "@chapter_subtitle_text", "display", "", level.displaydelay )
                }
            }
		}
	}

    // Clear all cached models from our temp cache as they are already cached
    // CanClearCache <- true

    // Set a variable to tell the map loaded
    HasSpawned <- true

    // Cache orange players original position
    local p = null
    while (p = Entities.FindByClassname(p, "player")) {
        if (p.GetTeam()==2) {
            OrangeOldPlayerPos <- p.GetOrigin()
        }
    }
    try {
        if (OrangeOldPlayerPos) { }
    } catch(exception) {
        if (GetDeveloperLevel()) {
            printl("(P2:MM): OrangeOldPlayerPos not set (Blue probably moved before Orange could load in) Setting OrangeOldPlayerPos to BlueOldPlayerPos")
        }
        OrangeOldPlayerPos <- OldPlayerPos
        OrangeCacheFailed <- true
    }

    // Force open the blue player droppers
    try {
        local ent = null
        while(ent = Entities.FindByClassnameWithin(ent, "prop_dynamic", Vector(OldPlayerPos.x, OldPlayerPos.y, OldPlayerPos.z-300), 100)) {
            if (ent.GetModelName() == "models/props_underground/underground_boxdropper.mdl" || ent.GetModelName() == "models/props_backstage/item_dropper.mdl") {
                EntFireByHandle(ent, "setanimation", "open", 0, null, null)
                if (ent.GetModelName() == "models/props_backstage/item_dropper.mdl") {
                    EntFireByHandle(ent, "setanimation", "item_dropper_open", 0, null, null)
                }
                ent.__KeyValueFromString("targetname", "BlueDropperForcedOpenMPMOD")
            }
        }
    } catch(exception) {
        if (GetDeveloperLevel()) {
            printl("(P2:MM): Blue dropper not found!")
        }
    }

    // Force open the red player droppers
    printl(OrangeOldPlayerPos)
    printl(OldPlayerPos)

    local radius = 150

    if (OrangeCacheFailed) {
        radius = 350
    }

    try {
        local ent = null
        while(ent = Entities.FindByClassnameWithin(ent, "prop_dynamic", Vector(OrangeOldPlayerPos.x, OrangeOldPlayerPos.y, OldPlayerPos.z-300), radius)) {
            if (ent.GetModelName() == "models/props_underground/underground_boxdropper.mdl" || ent.GetModelName() == "models/props_backstage/item_dropper.mdl") {
                EntFireByHandle(ent, "setanimation", "open", 0, null, null)
                if (ent.GetModelName() == "models/props_backstage/item_dropper.mdl") {
                    EntFireByHandle(ent, "setanimation", "item_dropper_open", 0, null, null)
                }
                ent.__KeyValueFromString("targetname", "RedDropperForcedOpenMPMOD")
            }
        }
    } catch(exception) {
        if (GetDeveloperLevel()) {
            printl("(P2:MM): Red dropper not found!")
        }
    }
    local radius = null

    //# Attempt to fix some general map issues #//
    local DoorEntities = [
        "airlock_1-door1-airlock_entry_door_close_rl",
        "airlock_2-door1-airlock_entry_door_close_rl",
        "last_airlock-door1-airlock_entry_door_close_rl",
        "airlock_1-door1-door_close",
        "airlock1-door1-door_close",
        "camera_door_3-relay_doorclose",
        "entry_airlock-door1-airlock_entry_door_close_rl",
        "door1-airlock_entry_door_close_rl",
        "airlock-door1-airlock_entry_door_close_rl",
        "orange_door_1-ramp_close_start",
        "blue_door_1-ramp_close_start",
        "orange_door_1-airlock_player_block",
        "blue_door_1-airlock_player_block",
        "airlock_3-door1-airlock_entry_door_close_rl",  //mp_coop_sx_bounce (Sixense map)
    ]

    if (!IsOnSingleplayer) {
        foreach (DoorType in DoorEntities) {
            try {
                Entities.FindByName(null, DoorType).Destroy()
            } catch(exception) { }
        }
    }

    // Create props after cache
    SendToConsoleP232("script CreatePropsForLevel(false, true, false)")

    MapSupport(false, false, true, false, false, false, false)
}

// Chat command hooks provided by our plugin
function ChatCommands(ccuserid, ccmessage) {

    ///////////////////////////////////////////
    local Message = RemoveDangerousChars(ccmessage)
    ///////////////////////////////////////////

    //////////////////////////////////////////////
    if (ShouldIgnoreMessage(Message)) { return }
    //////////////////////////////////////////////

    //////////////////////////////////////////////
    local Player = GetPlayerFromUserID(ccuserid)
    local Inputs = SplitBetween(Message, "!@", true)
    local PlayerClass = FindPlayerClass(Player)
    local Username = PlayerClass.username
    local AdminLevel = GetAdminLevel(Player)
    //////////////////////////////////////////////

    ////////////////////////////////////////////////////////////////
    function Rem(s) { return Replace(Replace(s, "!", ""), "@", "") }
    ////////////////////////////////////////////////////////////////

    ////////////////////////////////////////
    local Commands = []
    local Selectors = []

    foreach (Input in Inputs) {
        if (StartsWith(Input, "!")) {
            Commands.push(Rem(Input))
        } else if (StartsWith(Input, "@")) {
            Selectors.push(Rem(Input))
        }
    }
    ////////////////////////////////////////

    ////////////////////////////////////////////////////
    local Runners = []
    local UsedRunners = true

    foreach (Selector in Selectors) {
        if (Selector == "all" || Selector == "*" || Selector == "everyone") {
            Runners = []
            local p = null
            while (p = Entities.FindByClassname(p, "player")) {
                Runners.push(p)
            }
            break
        }
        local NewRunner = FindPlayerByName(Selector)

        if (NewRunner) {
            Runners.push(NewRunner)
        }
    }

    if (Runners.len() == 0) {
        Runners.push(Player)
        UsedRunners = false
    }
    ////////////////////////////////////////////////////

    ///////////////////////////////////////////////////////////
    foreach (Command in Commands) {
        printl("(P2:MM): Command: " + Command)
        Command = Strip(Command)

        if (!ValidateCommand(Command)) { ErrorOutCommand(0) ; continue }
        local Args = SplitBetween(Command, " ", true); if (Args.len() > 0) { Args.remove(0) }
        Command = GetCommandFromString(Command)

        if (!ValidateCommandAdminLevel(Command, AdminLevel)) { ErrorOutCommand(1, Command); continue }

        if (UsedRunners) { if (!ValidateAlowedRunners(Command, AdminLevel)) { ErrorOutCommand(3, Command); continue } }


        foreach (CurPlayer in Runners) {
            RunChatCommand(Command, Args, CurPlayer)
        }
    }
    ///////////////////////////////////////////////////////////

}
