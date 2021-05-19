//********************************************************************************************
//MAPSPAWN.nut is called on newgame or transitions
//********************************************************************************************
CheatsOff <- 0
ReadyCheatsOff <- 0
PlayerJoined <- 0
CurrentPlayerCount <- 0
GBIsMultiplayer <- 0

function init(){
    timer <- Entities.CreateByClassname("logic_timer");
    timer.__KeyValueFromString("targetname", "timer");
    EntFireByHandle(timer, "AddOutput", "RefireTime 0.1", 0, null, null);
    EntFireByHandle(timer, "AddOutput", "classname move_rope", 0, null, null);
    EntFireByHandle(timer, "AddOutput", "OnTimer worldspawn:RunScriptCode:SetColor():0:-1", 0, null, null);
    EntFireByHandle(timer, "Enable", "", 0.1, null, null);
    //Create An Entity That Sends A Client Command
    clientcommand <- Entities.CreateByClassname("point_clientcommand");
}

try {
    if ( ::IsMultiplayer() ){
        GBIsMultiplayer <- 1
    }
} catch(exception) {
    GBIsMultiplayer <- 0
}


if (GBIsMultiplayer==1) {
//Multiplayer Code

SetColor <- function(){
    local p = null;
    while (p = Entities.FindByClassname(p, "player")){
        loop()
        if (p.ValidateScriptScope()){
            local script_scope = p.GetScriptScope();
            if (!("Colored" in script_scope)){
                PlayerJoined <- 1
                CurrentPlayerCount <- CurrentPlayerCount + 1
                local coj = "say Player " + CurrentPlayerCount + " Joined The Game"
                coj = coj.tostring()
                printl("Player " + CurrentPlayerCount + " Joined The Game")
                SendToConsole(coj)
                //Set Random Color If Over 16
                if (CurrentPlayerCount != 1) {
                    R <- RandomInt(0, 255), G <- RandomInt(0, 255), B <- RandomInt(0, 255);
                    ReadyCheatsOff <- 1
                }
                //Set Preset Colors Up To 16
                if (CurrentPlayerCount == 1) {
                    R <- 255, G <- 255,  B <- 255;
                }
                if (CurrentPlayerCount == 2) {
                    R <- 255, G <- 255,  B <- 255;
                }
                if (CurrentPlayerCount == 3) {
                    R <- 180, G <- 255,  B <- 180;
                }
                if (CurrentPlayerCount == 4) {
                    R <- 120, G <- 140,  B <- 255;
                }
                if (CurrentPlayerCount == 5) {
                    R <- 255, G <- 170,  B <- 120;
                }
                if (CurrentPlayerCount == 6) {
                    R <- 255, G <- 100,  B <- 100;
                }
                if (CurrentPlayerCount == 7) {
                    R <- 255, G <- 180,  B <- 255;
                }
                if (CurrentPlayerCount == 8) {
                    R <- 255, G <- 255,  B <- 180;
                }
                if (CurrentPlayerCount == 9) {
                    R <- 0, G <- 255,  B <- 240;
                }
                if (CurrentPlayerCount == 10) {
                    R <- 75, G <- 75,  B <- 75;
                }
                if (CurrentPlayerCount == 11) {
                    R <- 120, G <- 155,  B <- 25;
                }
                if (CurrentPlayerCount == 12) {
                    R <- 0, G <- 80,  B <- 100;
                }
                if (CurrentPlayerCount == 13) {
                    R <- 100, G <- 80,  B <- 0;
                }
                if (CurrentPlayerCount == 14) {
                    R <- 0, G <- 0,  B <- 100;
                }
                if (CurrentPlayerCount == 15) {
                    R <- 80, G <- 0,  B <- 0;
                }
                if (CurrentPlayerCount == 16) {
                    R <- 0, G <- 75,  B <- 0;
                }
                script_scope.Colored <- true;
                EntFireByHandle(p, "Color", (R+" "+G+" "+B), 0, null, null);
                return
            }
        }
    }
}

function loop() {
	local entity = null;
    local p = null;
//Disable Collision
    //local j = "solid ";
	local k = "CollisionGroup ";
	//EntFire("player", "addoutput", j+4);
	EntFire("player", "addoutput", k+2);
    
//sv_cheats 0
    //check if ready to turn cheats off
    if (ReadyCheatsOff==1) {
        if (CheatsOff==0) {
            SendToConsole("sv_cheats 0")
            CheatsOff <- 1
        }
    }

//r_portal_fastpath 0 Fix
    while (PlayerJoined==1) {
        while (p = Entities.FindByClassname(p, "player")) {
            EntFireByHandle(clientcommand, "Command", "r_portal_fastpath 0", 0, p, p)
            PlayerJoined <- 0
        }
    } 


}

Entities.First().ConnectOutput("OnUser1", "init");
DoEntFire("worldspawn", "FireUser1", "", 0.0, null, null);
command <- Entities.CreateByClassname("point_servercommand")
if (GetMapName() == "mp_coop_lobby_3") {
	DoEntFire("!self", "Command", "sv_cheats 1", 0.0, null, command)

	DoEntFire("!self", "Command", "ent_remove_all func_portal_bumper", 0.0, null, command) // 165 entities removed
} else {
	printl("map not lobby_3")
}
DoEntFire("!self", "Kill", "", 0.0, null, command)
} else {
//Singleplayer Code
printl("Playing Map In Single Player [Multiplayer Mod Disabled]")
GlobalRunSingleplayer <- 1

SetColor <- function(){
    local p = null;
    while (p = Entities.FindByClassname(p, "player")){
        if (p.ValidateScriptScope()){
            local script_scope = p.GetScriptScope();
            if (GlobalRunSingleplayer==1){
                SendToConsole("script_execute singleplayer")
                GlobalRunSingleplayer <- 0
                return
            }
        }
    }
}

Entities.First().ConnectOutput("OnUser1", "init");
DoEntFire("worldspawn", "FireUser1", "", 0.0, null, null);
}