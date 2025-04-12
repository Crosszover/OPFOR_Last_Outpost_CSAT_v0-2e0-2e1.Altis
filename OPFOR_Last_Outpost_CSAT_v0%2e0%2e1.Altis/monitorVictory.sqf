/*
    monitorVictory.sqf
    Monitors zone control and declares victory when one side controls all required sites
    Call from init.sqf with: [] execVM "monitorVictory.sqf";
    
    Configuration:
    - Set _requiredSitesForVictory to the number of sites needed to win
    - Set _monitorInterval to control how often the check runs (in seconds)
*/

// ============= CONFIGURATION ============= //
_requiredSitesForVictory = 12;    // Number of sites required to win
_monitorInterval = 10;             // How often to check site control (seconds)
// ========================================= //

// Function to count controlled sites
fnc_countControlledSites = {
    params ["_side"];
    private _count = 0;
    
    // Check all possible site markers (up to 100)
    for "_i" from 1 to 100 do {
        private _marker = format ["site_%1", _i];
        if (getMarkerPos _marker isEqualTo [0,0,0]) exitWith {}; // Exit when no more markers
        
        private _owner = missionNamespace getVariable [_marker + "_owner", "NEUTRAL"];
        if (_owner == _side) then {
            _count = _count + 1;
        };
    };
    
    _count
};

// Victory declaration functions
fnc_declareVictory = {
    params ["_winningSide"];
    
    private _victoryMessage = "";
    private _endMissionParam = "";
    
    switch (_winningSide) do {
        case "OPFOR": {
            _victoryMessage = "OPFOR VICTORY! All required sites have been captured!";
            _endMissionParam = "OPFORVictory";
        };
        case "BLUFOR": {
            _victoryMessage = "BLUFOR VICTORY! All required sites have been captured!";
            _endMissionParam = "BLUFORVictory";
        };
    };
    
    // Show victory message to all players
    [_victoryMessage] remoteExec ["hint", 0];
    [_victoryMessage] remoteExec ["systemChat", 0];
    
    // End the mission for all players after delay
    sleep 5;
    [_endMissionParam, true] remoteExec ["BIS_fnc_endMission", 0];
};

// Main monitoring function
fnc_monitorSites = {
    params ["_requiredSites", "_interval"];
    
    systemChat format ["Victory monitor active - Control %1 sites to win", _requiredSites];
    hint format ["Victory Condition: Control %1 sites simultaneously", _requiredSites];
    
    while {true} do {
        sleep _interval;
        
        // Count sites controlled by each side
        private _opforCount = ["OPFOR"] call fnc_countControlledSites;
        private _bluforCount = ["BLUFOR"] call fnc_countControlledSites;
        
        // Check victory conditions
        if (_opforCount >= _requiredSites) then {
            ["OPFOR"] call fnc_declareVictory;
            break;
        };
        
        if (_bluforCount >= _requiredSites) then {
            ["BLUFOR"] call fnc_declareVictory;
            break;
        };
    };
};

// Start monitoring
[_requiredSitesForVictory, _monitorInterval] spawn fnc_monitorSites;