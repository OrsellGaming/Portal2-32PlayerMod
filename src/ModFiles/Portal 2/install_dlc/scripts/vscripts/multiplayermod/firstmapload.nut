//---------------------------------------------------
//         *****!Do not edit this file!*****
//---------------------------------------------------
//   ___ _        _          __  __
//  | __(_)_ _ __| |_       |  \/  |__ _ _ __
//  | _|| | '_(_-<  _|      | |\/| / _` | '_ \
//  |_| |_|_| /__/\__|      |_|  |_\__,_| .__/
//           | |   ___  __ _ __| (_)    |_|
//           | |__/ _ \/ _` / _` |_|
//           |____\___/\__,_\__,_(_)
//---------------------------------------------------
// Purpose: Only runs on first map load of session
//---------------------------------------------------

// Reset dev level
if (Config_DevMode) {
    EntFire("p2mm_servercommand", "command", "developer 1")
}
else {
    EntFire("p2mm_servercommand", "command", "clear; developer 0")
}

if (!PluginLoaded) {
    // Remove Portal Gun (Map transition will sound less abrupt)
    // Can't use UTIL_Team.Spawn_PortalGun(false) since the .nut file has not been loaded
    Entities.CreateByClassname("info_target").__KeyValueFromString("targetname", "supress_blue_portalgun_spawn")
    Entities.CreateByClassname("info_target").__KeyValueFromString("targetname", "supress_orange_portalgun_spawn")

    EntFire("p2mm_servercommand", "command", "script printl(\"(P2:MM): Attempting to load the P2:MM plugin...\")", 0.03)
    EntFire("p2mm_servercommand", "command", "plugin_load p2mm", 0.05) // This should never fail the first time through addons... try loading it from root DLC path
} else {
    printlP2MM("Plugin has already been loaded! Not attempting to load it...")
}

// Facilitate first load after game launch
function MakeProgressCheck() {
    printlP2MM("First map load detected! Checking to see if we need to change/reset maps...")

    local ChangeToThisMap = "mp_coop_start"
    for (local course = 1; course <= 6; course++) {  // 6 courses is the highest that coop has
        for (local level = 1; level <= 9; level++) { // 9 levels is the highest that a course has
            if (IsLevelComplete(course - 1, level - 1)) {
                ChangeToThisMap = "mp_coop_lobby_3"
            }
        }
    }

    // We will always need to reset the map since there is no way to preserve a map load without
    // forcing the game to not wait at least one second for a progress check
    // if ((GetMapName() != ChangeToThisMap) || !PluginLoaded) {
        // printlP2MM("Resetting map (Destination map is not the same as " + GetMapName() + " OR our plugin was not loaded!")
        printlP2MM("Forcing map reset.")
        EntFire("p2mm_servercommand", "command", "stopvideos; changelevel " + ChangeToThisMap)
    // }
}

EntFire("p2mm_servercommand", "command", "script MakeProgressCheck()", 1) // Must be delayed
