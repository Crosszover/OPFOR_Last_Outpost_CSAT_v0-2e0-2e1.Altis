// Main Initialization Script
// Place in the mission root folder

// Load unit configurations
call compile preprocessFileLineNumbers "opforUnits.sqf";
call compile preprocessFileLineNumbers "bluforUnits.sqf";
call compile preprocessFileLineNumbers "intel.sqf";
// Global variables
if (isNil "available_funds") then {
    available_funds = 5000; // Initial funds
    publicVariable "available_funds";
};

// Command vehicle tracking
if (isNil "command_vehicle_active") then {
    command_vehicle_active = false;
    publicVariable "command_vehicle_active";
};

// Hide spawn marker
"main_spawn" setMarkerAlpha 0;

// Función mejorada para encontrar una posición segura de spawn
fnc_findSafePosition = {
    params ["_minRadius", "_maxRadius"];
    
    private _basePosition = getMarkerPos "main_spawn";
    private _foundPosition = [];
    private _attempts = 0;
    private _maxAttempts = 50;
    
    // Tipos de objetos a evitar (agregados árboles y objetos decorativos)
    private _objectTypes = [
        "Building", "House", "Wall", "Car", "Tank", "Ship", "Air", 
        "Tree", "Bush", "Fence", "Barrier", "Rocks", "Stone"
    ];
    
    while {count _foundPosition == 0 && _attempts < _maxAttempts} do {
        private _radius = _minRadius + random (_maxRadius - _minRadius);
        private _direction = random 360;
        private _testPosition = _basePosition getPos [_radius, _direction];
        
        // Comprobar objetos cercanos con la lista ampliada
        private _nearbyObjects = nearestObjects [_testPosition, _objectTypes, 5];
        
        // Comprobar si la posición está libre de objetos y no está en agua
        if (count _nearbyObjects == 0 && !surfaceIsWater _testPosition) then {
            // Verificación manual del terreno plano
            private _isFlat = true;
            
            // Comprobar varios puntos alrededor para asegurar que el área es plana
            for "_i" from 0 to 3 do {
                private _checkPos = _testPosition getPos [2, _i * 90];
                if (abs((_testPosition select 2) - (_checkPos select 2)) > 0.5) then {
                    _isFlat = false;
                };
            };
            
            if (_isFlat) then {
                _foundPosition = _testPosition;
            };
        };
        
        _attempts = _attempts + 1;
    };
    
    if (count _foundPosition == 0) then {
        hint "Warning: Could not find a safe position. Using default position.";
        _foundPosition = _basePosition getPos [10, random 360];
    };
    
    _foundPosition
};

// Check funds (helper function to avoid code duplication)
fnc_checkFunds = {
    params ["_cost"];
    
    if (available_funds < _cost) exitWith {
        hint format ["Not enough funds. You need %1 credits (Available: %2)", _cost, available_funds];
        false
    };
    
    available_funds = available_funds - _cost;
    publicVariable "available_funds";
    true
};

// Function to buy infantry
fnc_buyInfantry = {
    params ["_unitArray", ["_spawnPos", []]];
    _classname = _unitArray select 0;
    _cost = _unitArray select 2;

    if !([_cost] call fnc_checkFunds) exitWith { false };

    // Find a safe spawn position if not provided
    _pos = if (count _spawnPos > 0) then {_spawnPos} else {[5, 15] call fnc_findSafePosition};

    // Create unit on the server
    [_classname, _pos, group player, clientOwner] remoteExecCall ["fnc_createRemoteUnit", 2];

    // Confirmation message (solo para este jugador)
    _unitName = getText (configFile >> "CfgVehicles" >> _classname >> "displayName");
    private _message = format ["You have recruited: %1\nRemaining funds: %2", _unitName, available_funds];
    [_message, "hint", clientOwner] call BIS_fnc_MP;
    
    // Mensaje de sistema solo para este jugador
    ["New unit added to your group", "systemChat", clientOwner] call BIS_fnc_MP;
    playSound "FD_Finish_F"; // Sonido de confirmación (solo para este jugador)
    true
};

// Función remota modificada para crear unidad
fnc_createRemoteUnit = {
    params ["_classname", "_pos", "_group", "_clientOwner"];
    _unit = _group createUnit [_classname, _pos, [], 0, "NONE"];
    _unit doFollow leader _group;
};

fnc_buyVehicle = {
    params ["_vehicleArray"];
    _classname = _vehicleArray select 0;
    _cost = _vehicleArray select 2;

    if !([_cost] call fnc_checkFunds) exitWith { false };

    // Find a safe spawn position
    _pos = [20, 50] call fnc_findSafePosition;

    // Get vehicle name for marker and messages
    _vehicleName = getText (configFile >> "CfgVehicles" >> _classname >> "displayName");

    // Create vehicle on the server and pass the vehicle name
    [_classname, _pos, clientOwner, _vehicleName] remoteExecCall ["fnc_createRemoteVehicle", 2];

    // Additional handling for command vehicle
    if (_classname == OPFOR_Vehicle_Command select 0) then {
        if (command_vehicle_active) then {
            ["Command vehicle already exists. Only one can be active at a time.", "hint", clientOwner] call BIS_fnc_MP;
            available_funds = available_funds + _cost;
            publicVariable "available_funds";
            false
        } else {
            [_pos] remoteExecCall ["fnc_setupCommandVehicle", 2];
            true
        };
    } else {
        private _message = format ["You have acquired: %1\nRemaining funds: %2", _vehicleName, available_funds];
        [_message, "hint", clientOwner] call BIS_fnc_MP;
        playSound "FD_Finish_F";
        true
    };
};

fnc_createRemoteVehicle = {
    params ["_classname", "_pos", "_clientOwner", "_vehicleName"];
    
    // Create the vehicle
    _vehicle = createVehicle [_classname, _pos, [], 0, "NONE"];
    _vehicle setDir (random 360);
    clearWeaponCargoGlobal _vehicle;
    clearMagazineCargoGlobal _vehicle;
    clearItemCargoGlobal _vehicle;
    clearBackpackCargoGlobal _vehicle;
    
    // Create temporary marker
    _markerName = format ["vehicle_spawn_%1_%2", _classname, round(time)];
    _marker = createMarker [_markerName, _pos];
    _marker setMarkerType "hd_start";
    _marker setMarkerColor "ColorRed";
    _marker setMarkerText _vehicleName;
    _marker setMarkerSize [0.7, 0.7];
    
    // Send marker to all players (optional)
    publicVariable _markerName;
    
    // Delete marker after 60 seconds
    [_markerName] spawn {
        params ["_marker"];
        sleep 60;
        deleteMarker _marker;
    };
};

// Function to add terminal actions to the command vehicle
fnc_addCommandVehicleActions = {
    params ["_vehicle"];
    
    // Check Available Funds action
    _vehicle addAction [
        "<t color='#FFFF00'>Check Available Funds</t>",
        { hint format ["Available funds: %1 credits", available_funds]; },
        nil, 1.5, true, true, "", "true", 20
    ];
    
    _vehicle addAction [
        "<t color='#00FFFF'>UNIT CAMERA</t>",
        { call fnc_activateUnitSelector; },
        nil, 1.5, true, true, "", "true", 20
    ];

    _vehicle addAction [
        "<t color='#00FFFF'>INTEL Report (60s) - 1000 cr</t>",
        { [1000] call fnc_buyIntel; },
        nil, 1.5, true, true, "", "true", 20
    ];
  
    // ===== INFANTRY SECTION =====
    _vehicle addAction [
        "<t color='#FF8C00'>===== INFANTRY =====</t>",
        { hint "Select a unit type to purchase"; },
        nil, 1.5, true, true, "", "true", 20
    ];
    
    _vehicle addAction [
        "<t color='#00FF00'>Buy Rifleman - 75 cr</t>",
        { [OPFOR_Rifleman] call fnc_buyInfantry; },
        nil, 1.5, true, true, "", "true", 20
    ];
    
    _vehicle addAction [
        "<t color='#00FF00'>Buy Grenadier - 100 cr</t>",
        { [OPFOR_Grenadier] call fnc_buyInfantry; },
        nil, 1.5, true, true, "", "true", 20
    ];
    
    _vehicle addAction [
        "<t color='#00FF00'>Buy Auto Rifleman - 125 cr</t>",
        { [OPFOR_AutoRifleman] call fnc_buyInfantry; },
        nil, 1.5, true, true, "", "true", 20
    ];
    
    _vehicle addAction [
        "<t color='#00FF00'>Buy Marksman - 150 cr</t>",
        { [OPFOR_Marksman] call fnc_buyInfantry; },
        nil, 1.5, true, true, "", "true", 20
    ];
    
    _vehicle addAction [
        "<t color='#00FF00'>Buy Light AT (RPG) - 175 cr</t>",
        { [OPFOR_AT] call fnc_buyInfantry; },
        nil, 1.5, true, true, "", "true", 20
    ];
    
    _vehicle addAction [
        "<t color='#00FF00'>Buy Heavy AT (HAT) - 250 cr</t>",
        { [OPFOR_HAT] call fnc_buyInfantry; },
        nil, 1.5, true, true, "", "true", 20
    ];
    
    _vehicle addAction [
        "<t color='#00FF00'>Buy AA (Missiles) - 200 cr</t>",
        { [OPFOR_AA] call fnc_buyInfantry; },
        nil, 1.5, true, true, "", "true", 20
    ];
    
    _vehicle addAction [
        "<t color='#00FF00'>Buy Medic - 125 cr</t>",
        { [OPFOR_Medic] call fnc_buyInfantry; },
        nil, 1.5, true, true, "", "true", 20
    ];
    
    _vehicle addAction [
        "<t color='#00FF00'>Buy Engineer - 125 cr</t>",
        { [OPFOR_Engineer] call fnc_buyInfantry; },
        nil, 1.5, true, true, "", "true", 20
    ];
    
    _vehicle addAction [
        "<t color='#00FF00'>Buy Squad Leader - 150 cr</t>",
        { [OPFOR_SquadLeader] call fnc_buyInfantry; },
        nil, 1.5, true, true, "", "true", 20
    ];
    
    _vehicle addAction [
        "<t color='#00FF00'>Buy Officer - 200 cr</t>",
        { [OPFOR_Officer] call fnc_buyInfantry; },
        nil, 1.5, true, true, "", "true", 20
    ];
    
    _vehicle addAction [
        "<t color='#00FF00'>Buy Crew - 100 cr</t>",
        { [OPFOR_Crew] call fnc_buyInfantry; },
        nil, 1.5, true, true, "", "true", 20
    ];
    
    _vehicle addAction [
        "<t color='#00FF00'>Buy Pilot - 150 cr</t>",
        { [OPFOR_Pilot] call fnc_buyInfantry; },
        nil, 1.5, true, true, "", "true", 20
    ];
    
    // ===== LIGHT VEHICLES SECTION =====
    _vehicle addAction [
        "<t color='#FF8C00'>===== LIGHT VEHICLES =====</t>",
        { hint "Select a light vehicle to purchase"; },
        nil, 1.5, true, true, "", "true", 20
    ];
    
    _vehicle addAction [
        "<t color='#00FF00'>Buy Car - 300 cr</t>",
        { [OPFOR_Vehicle_Car] call fnc_buyVehicle; },
        nil, 1.5, true, true, "", "true", 20
    ];
    
    _vehicle addAction [
        "<t color='#00FF00'>Buy Car MG - 500 cr</t>",
        { [OPFOR_Vehicle_CarMG] call fnc_buyVehicle; },
        nil, 1.5, true, true, "", "true", 20
    ];
    
    _vehicle addAction [
        "<t color='#00FF00'>Buy Car AT - 750 cr</t>",
        { [OPFOR_Vehicle_CarAT] call fnc_buyVehicle; },
        nil, 1.5, true, true, "", "true", 20
    ];
    
    _vehicle addAction [
        "<t color='#00FF00'>Buy Truck - 400 cr</t>",
        { [OPFOR_Vehicle_Truck] call fnc_buyVehicle; },
        nil, 1.5, true, true, "", "true", 20
    ];
    
    _vehicle addAction [
        "<t color='#00FF00'>Buy APC - 1000 cr</t>",
        { [OPFOR_Vehicle_APC] call fnc_buyVehicle; },
        nil, 1.5, true, true, "", "true", 20
    ];
    
    _vehicle addAction [
        "<t color='#00FF00'>Buy APC 2 - 1000 cr</t>",
        { [OPFOR_Vehicle_APC2] call fnc_buyVehicle; },
        nil, 1.5, true, true, "", "true", 20
    ];
    
    _vehicle addAction [
        "<t color='#00FF00'>Buy Repair Vehicle - 800 cr</t>",
        { [OPFOR_Vehicle_Repair] call fnc_buyVehicle; },
        nil, 1.5, true, true, "", "true", 20
    ];
    
    _vehicle addAction [
        "<t color='#00FF00'>Buy Ammo Vehicle - 800 cr</t>",
        { [OPFOR_Vehicle_Ammo] call fnc_buyVehicle; },
        nil, 1.5, true, true, "", "true", 20
    ];
    
    _vehicle addAction [
        "<t color='#00FF00'>Buy Fuel Vehicle - 800 cr</t>",
        { [OPFOR_Vehicle_Fuel] call fnc_buyVehicle; },
        nil, 1.5, true, true, "", "true", 20
    ];
    
    // ===== HEAVY VEHICLES SECTION =====
    _vehicle addAction [
        "<t color='#FF8C00'>===== HEAVY VEHICLES =====</t>",
        { hint "Select a heavy vehicle to purchase"; },
        nil, 1.5, true, true, "", "true", 20
    ];
    
    _vehicle addAction [
        "<t color='#00FF00'>Buy IFV - 1500 cr</t>",
        { [OPFOR_Vehicle_IFV] call fnc_buyVehicle; },
        nil, 1.5, true, true, "", "true", 20
    ];
    
    _vehicle addAction [
        "<t color='#00FF00'>Buy Light AA - 1000 cr</t>",
        { [OPFOR_Vehicle_AA_Light] call fnc_buyVehicle; },
        nil, 1.5, true, true, "", "true", 20
    ];
    
    _vehicle addAction [
        "<t color='#00FF00'>Buy Artillery - 2000 cr</t>",
        { [OPFOR_Vehicle_Artillery] call fnc_buyVehicle; },
        nil, 1.5, true, true, "", "true", 20
    ];
    
    _vehicle addAction [
        "<t color='#00FF00'>Buy Light Tank - 2000 cr</t>",
        { [OPFOR_Vehicle_Tank_Light] call fnc_buyVehicle; },
        nil, 1.5, true, true, "", "true", 20
    ];
    
    _vehicle addAction [
        "<t color='#00FF00'>Buy Heavy Tank - 2500 cr</t>",
        { [OPFOR_Vehicle_Tank_Heavy] call fnc_buyVehicle; },
        nil, 1.5, true, true, "", "true", 20
    ];
    
    _vehicle addAction [
        "<t color='#00FF00'>Buy Heavy AA - 1800 cr</t>",
        { [OPFOR_Vehicle_AA_Heavy] call fnc_buyVehicle; },
        nil, 1.5, true, true, "", "true", 20
    ];
    
    // ===== AIR ASSETS SECTION =====
    _vehicle addAction [
        "<t color='#FF8C00'>===== AIR ASSETS =====</t>",
        { hint "Select an air asset to purchase"; },
        nil, 1.5, true, true, "", "true", 20
    ];
    
    _vehicle addAction [
        "<t color='#00FF00'>Buy Light Helicopter - 2000 cr</t>",
        { [OPFOR_Heli_Light] call fnc_buyVehicle; },
        nil, 1.5, true, true, "", "true", 20
    ];
    
    _vehicle addAction [
        "<t color='#00FF00'>Buy Transport Helicopter - 2500 cr</t>",
        { [OPFOR_Heli_Transport] call fnc_buyVehicle; },
        nil, 1.5, true, true, "", "true", 20
    ];
    
    _vehicle addAction [
        "<t color='#00FF00'>Buy Attack Helicopter - 20500 cr</t>",
        { [OPFOR_Heli_Attack] call fnc_buyVehicle; },
        nil, 1.5, true, true, "", "true", 20
    ];
    
    _vehicle addAction [
        "<t color='#00FF00'>Buy Heavy Attack Helicopter - 4000 cr</t>",
        { [OPFOR_Heli_Attack_Heavy] call fnc_buyVehicle; },
        nil, 1.5, true, true, "", "true", 20
    ];
    
    _vehicle addAction [
        "<t color='#00FF00'>Buy Light Plane - 1500 cr</t>",
        { [OPFOR_Plane_Light] call fnc_buyVehicle; },
        nil, 1.5, true, true, "", "true", 20
    ];
    
    _vehicle addAction [
        "<t color='#00FF00'>Buy CAS Plane - 4500 cr</t>",
        { [OPFOR_Plane_CAS] call fnc_buyVehicle; },
        nil, 1.5, true, true, "", "true", 20
    ];
};

// Function to setup the command vehicle with terminal capabilities
fnc_setupCommandVehicle = {
    params ["_pos"];
    
    // Mark that a command vehicle is active
    command_vehicle_active = true;
    publicVariable "command_vehicle_active";
    
    // Find the command vehicle we just created (should be the closest OPFOR_Vehicle_Command to _pos)
    _commandVehicle = nearestObject [_pos, OPFOR_Vehicle_Command select 0];
    
    if (!isNull _commandVehicle) then {
        // Create a respawn position that follows the vehicle
        [_commandVehicle] spawn {
            params ["_vehicle"];
            _respawnMarker = createMarker ["respawn_east_2", getPos _vehicle];
            
            // Set up event handlers
            _vehicle addEventHandler ["Deleted", {
                deleteMarker "respawn_east_2";
                command_vehicle_active = false;
                publicVariable "command_vehicle_active";
            }];
            
            _vehicle addEventHandler ["Killed", {
                deleteMarker "respawn_east_2";
                command_vehicle_active = false;
                publicVariable "command_vehicle_active";
            }];
            
            // Update marker position continuously
            while {alive _vehicle && !isNull _vehicle} do {
                "respawn_east_2" setMarkerPos (getPos _vehicle);
                sleep 1;
            };
        };
        
        // Add terminal actions to the command vehicle
        [_commandVehicle] remoteExec ["fnc_addCommandVehicleActions", 0, true];
        
        // Add HC module actions to the command vehicle
        [_commandVehicle] remoteExec ["fnc_addHCModuleActions", 0, true];
        
        // Confirmation message
        _vehicleName = getText (configFile >> "CfgVehicles" >> OPFOR_Vehicle_Command select 0 >> "displayName");
        hint format ["Command Vehicle deployed: %1\nRemaining funds: %2\nMobile respawn point active.", _vehicleName, available_funds];
    };
};

// Wait until the game is fully initialized
waitUntil {!isNull player && time > 0.5};

// Verify key objects
if (isNull terminal) exitWith {
    hint "Error: The 'terminal' object does not exist in the mission.";
};

if (getMarkerPos "main_spawn" isEqualTo [0,0,0]) exitWith {
    hint "Error: The 'main_spawn' marker does not exist in the mission.";
};

// Wait until mission parameters are loaded
waitUntil {!isNil "paramsArray"};

// Set mission start time
private _startTime = if (paramsArray select 0 == -1) then {
    random 24
} else {
    paramsArray select 0
};

// Set time acceleration
private _timeAcceleration = paramsArray select 1;

// Apply settings
skipTime (_startTime - daytime + 24 % 24);
setTimeMultiplier _timeAcceleration;

// Log settings for debugging
diag_log format ["Mission parameters set - Start Time: %1, Time Acceleration: x%2", _startTime, _timeAcceleration];

// Terminal actions
terminal addAction [
    "<t color='#FFFF00'>Check Available Funds</t>",
    { hint format ["Available funds: %1 credits", available_funds]; },
    nil, 1.5, true, true, "", "true", 20
];

// Infantry purchase menu
terminal addAction [
    "<t color='#00FF00'>Buy Rifleman - 75 cr</t>",
    { [OPFOR_Rifleman] call fnc_buyInfantry; },
    nil, 1.5, true, true, "", "true", 20
];

terminal addAction [
    "<t color='#00FF00'>Buy Grenadier - 100 cr</t>",
    { [OPFOR_Grenadier] call fnc_buyInfantry; },
    nil, 1.5, true, true, "", "true", 20
];

terminal addAction [
    "<t color='#00FF00'>Buy Auto Rifleman - 125 cr</t>",
    { [OPFOR_AutoRifleman] call fnc_buyInfantry; },
    nil, 1.5, true, true, "", "true", 20
];

terminal addAction [
    "<t color='#00FF00'>Buy Marksman - 150 cr</t>",
    { [OPFOR_Marksman] call fnc_buyInfantry; },
    nil, 1.5, true, true, "", "true", 20
];

terminal addAction [
    "<t color='#00FF00'>Buy Light AT (RPG) - 175 cr</t>",
    { [OPFOR_AT] call fnc_buyInfantry; },
    nil, 1.5, true, true, "", "true", 20
];

terminal addAction [
    "<t color='#00FF00'>Buy Heavy AT (HAT) - 250 cr</t>",
    { [OPFOR_HAT] call fnc_buyInfantry; },
    nil, 1.5, true, true, "", "true", 20
];

terminal addAction [
    "<t color='#00FF00'>Buy AA (Missiles) - 200 cr</t>",
    { [OPFOR_AA] call fnc_buyInfantry; },
    nil, 1.5, true, true, "", "true", 20
];

terminal addAction [
    "<t color='#00FF00'>Buy Medic - 125 cr</t>",
    { [OPFOR_Medic] call fnc_buyInfantry; },
    nil, 1.5, true, true, "", "true", 20
];

terminal addAction [
    "<t color='#00FF00'>Buy Engineer - 125 cr</t>",
    { [OPFOR_Engineer] call fnc_buyInfantry; },
    nil, 1.5, true, true, "", "true", 20
];

terminal addAction [
    "<t color='#00FF00'>Buy Squad Leader - 150 cr</t>",
    { [OPFOR_SquadLeader] call fnc_buyInfantry; },
    nil, 1.5, true, true, "", "true", 20
];

terminal addAction [
    "<t color='#00FF00'>Buy Officer - 200 cr</t>",
    { [OPFOR_Officer] call fnc_buyInfantry; },
    nil, 1.5, true, true, "", "true", 20
];

terminal addAction [
    "<t color='#00FF00'>Buy Crew - 100 cr</t>",
    { [OPFOR_Crew] call fnc_buyInfantry; },
    nil, 1.5, true, true, "", "true", 20
];

terminal addAction [
    "<t color='#00FF00'>Buy Pilot - 150 cr</t>",
    { [OPFOR_Pilot] call fnc_buyInfantry; },
    nil, 1.5, true, true, "", "true", 20
];

// Light vehicles purchase menu
radio addAction [
    "<t color='#FFFF00'>Check Available Funds</t>",
    { hint format ["Available funds: %1 credits", available_funds]; },
    nil, 1.5, true, true, "", "true", 20
];

radio addAction [
    "<t color='#00FF00'>Buy Car - 300 cr</t>",
    { [OPFOR_Vehicle_Car] call fnc_buyVehicle; },
    nil, 1.5, true, true, "", "true", 20
];

radio addAction [
    "<t color='#00FF00'>Buy Car MG - 500 cr</t>",
    { [OPFOR_Vehicle_CarMG] call fnc_buyVehicle; },
    nil, 1.5, true, true, "", "true", 20
];

radio addAction [
    "<t color='#00FF00'>Buy Car AT - 750 cr</t>",
    { [OPFOR_Vehicle_CarAT] call fnc_buyVehicle; },
    nil, 1.5, true, true, "", "true", 20
];

radio addAction [
    "<t color='#00FF00'>Buy Truck - 400 cr</t>",
    { [OPFOR_Vehicle_Truck] call fnc_buyVehicle; },
    nil, 1.5, true, true, "", "true", 20
];

radio addAction [
    "<t color='#00FF00'>Buy APC - 1000 cr</t>",
    { [OPFOR_Vehicle_APC] call fnc_buyVehicle; },
    nil, 1.5, true, true, "", "true", 20
];

radio addAction [
    "<t color='#00FF00'>Buy APC 2 - 2000 cr</t>",
    { [OPFOR_Vehicle_APC2] call fnc_buyVehicle; },
    nil, 1.5, true, true, "", "true", 20
];

radio addAction [
    "<t color='#00FF00'>Buy Repair Vehicle - 800 cr</t>",
    { [OPFOR_Vehicle_Repair] call fnc_buyVehicle; },
    nil, 1.5, true, true, "", "true", 20
];

radio addAction [
    "<t color='#00FF00'>Buy Ammo Vehicle - 800 cr</t>",
    { [OPFOR_Vehicle_Ammo] call fnc_buyVehicle; },
    nil, 1.5, true, true, "", "true", 20
];

radio addAction [
    "<t color='#00FF00'>Buy Fuel Vehicle - 800 cr</t>",
    { [OPFOR_Vehicle_Fuel] call fnc_buyVehicle; },
    nil, 1.5, true, true, "", "true", 20
];

// Heavy vehicles purchase menu
radio addAction [
    "<t color='#00FF00'>Buy IFV - 1500 cr</t>",
    { [OPFOR_Vehicle_IFV] call fnc_buyVehicle; },
    nil, 1.5, true, true, "", "true", 20
];

radio addAction [
    "<t color='#00FF00'>Buy Light AA - 1000 cr</t>",
    { [OPFOR_Vehicle_AA_Light] call fnc_buyVehicle; },
    nil, 1.5, true, true, "", "true", 20
];

radio addAction [
    "<t color='#00FF00'>Buy Artillery - 2000 cr</t>",
    { [OPFOR_Vehicle_Artillery] call fnc_buyVehicle; },
    nil, 1.5, true, true, "", "true", 20
];

radio addAction [
    "<t color='#00FF00'>Buy Light Tank - 2000 cr</t>",
    { [OPFOR_Vehicle_Tank_Light] call fnc_buyVehicle; },
    nil, 1.5, true, true, "", "true", 20
];

radio addAction [
    "<t color='#00FF00'>Buy Heavy Tank - 2500 cr</t>",
    { [OPFOR_Vehicle_Tank_Heavy] call fnc_buyVehicle; },
    nil, 1.5, true, true, "", "true", 20
];

radio addAction [
    "<t color='#00FF00'>Buy Heavy AA - 1800 cr</t>",
    { [OPFOR_Vehicle_AA_Heavy] call fnc_buyVehicle; },
    nil, 1.5, true, true, "", "true", 20
];

laptop addAction [
    "<t color='#00FF00'>Buy Command Vehicle - 5000 cr</t>",
    { [OPFOR_Vehicle_Command] call fnc_buyVehicle; },
    nil, 1.5, true, true, "", "true", 20
];

// Acción para el laptop (similar a tu ejemplo)
laptop addAction [
    "<t color='#00FFFF'>INTEL Report (60s) - 1000 cr</t>",
    { [1000] call fnc_buyIntel; },
    nil, 1.5, true, true, "", "true", 20
];

laptop addAction [
    "<t color='#00FFFF'>UNIT CAMERA - (free)</t>",
    { [] call fnc_activateUnitSelector; },
    nil, 1.5, true, true, "", "true", 20
];

// Air assets purchase menu
radio addAction [
    "<t color='#00FF00'>Buy Light Helicopter - 2000 cr</t>",
    { [OPFOR_Heli_Light] call fnc_buyVehicle; },
    nil, 1.5, true, true, "", "true", 20
];

radio addAction [
    "<t color='#00FF00'>Buy Transport Helicopter - 2500 cr</t>",
    { [OPFOR_Heli_Transport] call fnc_buyVehicle; },
    nil, 1.5, true, true, "", "true", 20
];

radio addAction [
    "<t color='#00FF00'>Buy Attack Helicopter - 3500 cr</t>",
    { [OPFOR_Heli_Attack] call fnc_buyVehicle; },
    nil, 1.5, true, true, "", "true", 20
];

radio addAction [
    "<t color='#00FF00'>Buy Heavy Attack Helicopter - 4000 cr</t>",
    { [OPFOR_Heli_Attack_Heavy] call fnc_buyVehicle; },
    nil, 1.5, true, true, "", "true", 20
];

radio addAction [
    "<t color='#00FF00'>Buy Light Plane - 1500 cr</t>",
    { [OPFOR_Plane_Light] call fnc_buyVehicle; },
    nil, 1.5, true, true, "", "true", 20
];

radio addAction [
    "<t color='#00FF00'>Buy CAS Plane - 4500 cr</t>",
    { [OPFOR_Plane_CAS] call fnc_buyVehicle; },
    nil, 1.5, true, true, "", "true", 20
];

radio addAction [
    "<t color='#00FF00'>Buy Towing Tractor - 200 cr</t>",
    { [["CUP_C_Tractor_CIV", "", 200]] call fnc_buyVehicle; },
    nil, 1.5, true, true, "", "true", 20
];

// Mensaje único para todos los jugadores (incluyendo el que activó el terminal)
["Welcome to the unit purchase system. Approach the terminal to buy troops and vehicles.", "systemChat"] remoteExec ["call", 0];  
hint "Purchase terminal activated.\n\nUse the terminal to buy troops and vehicles.\n\nInitial funds: 5000 credits.";  

// Call flag and capture mechanics script
call compile preprocessFileLineNumbers "flagMechanics.sqf";

// Call enemy initialization script
call compile preprocessFileLineNumbers "enemyInit.sqf";
call compile preprocessFileLineNumbers "bluforAI.sqf";
call compile preprocessFileLineNumbers "init_hc_laptop.sqf";
call compile preprocessFileLineNumbers "virtual_arsenal.sqf";
call compile preprocessFileLineNumbers "playerTracking.sqf";
call compile preprocessFileLineNumbers "initCameraSystem.sqf";
call compile preprocessFileLineNumbers "monitorVictory.sqf";

// Al final de tu init.sqf, después de TODAS las otras definiciones:
if (isServer) then {
    call compile preprocessFileLineNumbers "HC_module.sqf";
};