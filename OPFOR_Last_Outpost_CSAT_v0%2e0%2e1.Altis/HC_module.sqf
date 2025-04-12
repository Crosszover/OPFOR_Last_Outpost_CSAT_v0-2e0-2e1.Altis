// HC_module.sqf - Versión con Fix Alternativo

// Global variables
if (isServer) then {
    if (isNil "HC_GROUPS") then {
        HC_GROUPS = createHashMap;
        publicVariable "HC_GROUPS";
    };
    
    if (isNil "HC_SUBMODULES_POOL") then {
        HC_SUBMODULES_POOL = createHashMap;
        publicVariable "HC_SUBMODULES_POOL";
    };
};

// Function to initialize HC modules pool
fnc_initHCModulesPool = {
    params ["_player"];
    private _uid = getPlayerUID _player;
    
    if (!isServer) exitWith {};
    
    // Clear existing modules
    private _existingPool = HC_SUBMODULES_POOL getOrDefault [_uid, []];
    {
        if (!isNull _x) then {
            deleteVehicle _x;
        };
    } forEach _existingPool;
    
    private _existingModule = _player getVariable ["HC_MODULE", objNull];
    if (!isNull _existingModule) then {
        deleteVehicle _existingModule;
    };
    
    // 1. Create HC Commander module
    private _logicGroupHC = createGroup [sideLogic, true];
    private _mainModule = _logicGroupHC createUnit ["HighCommand", [0,0,0], [], 0, "NONE"];
    _mainModule allowDamage false;
    _mainModule enableSimulation true;
    
    // 2. Synchronize HC Commander module with the player
    _player synchronizeObjectsAdd [_mainModule];
    
    // 3. Save main module reference
    _player setVariable ["HC_MODULE", _mainModule, true];
    _player setVariable ["BIS_HC_isCommanding", true, true];
    
    // 4. Create pool of 10 submodules
    private _submodules = [];
    for "_i" from 1 to 20 do {
        private _logicGroup = createGroup [sideLogic, true];
        private _submodule = _logicGroup createUnit ["HighCommandSubordinate", [0,0,0], [], 0, "NONE"];
        _submodule allowDamage false;
        _submodule enableSimulation true;
        
        // 5. Synchronize submodule with main module
        _mainModule synchronizeObjectsAdd [_submodule];
        
        _submodule setVariable ["isOccupied", false, true];
        _submodules pushBack _submodule;
    };
    
    HC_SUBMODULES_POOL set [_uid, _submodules];
    publicVariable "HC_SUBMODULES_POOL";
    
    ["HC Modules pool initialized"] remoteExec ["systemChat", _player];
    diag_log "HC Modules pool initialized";
};

// Function to get an available submodule
fnc_getAvailableSubmodule = {
    params ["_player"];
    private _uid = getPlayerUID _player;
    private _pool = HC_SUBMODULES_POOL getOrDefault [_uid, []];
    
    private _availableModule = objNull;
    {
        if (!(_x getVariable ["isOccupied", false])) exitWith {
            _availableModule = _x;
        };
    } forEach _pool;
    
    _availableModule
};

// Helper function to get yellow team units and vehicles
fnc_getYellowTeamUnits = {
    params ["_player"];
    private _group = group _player;
    private _yellowTeam = [];
    private _vehicles = [];
    
    {
        if (assignedTeam _x == "YELLOW" && {_x != _player}) then {
            private _vehicle = vehicle _x;
            if (_vehicle != _x) then {
                // If unit is in a vehicle
                if !(_vehicle in _vehicles) then {
                    _vehicles pushBack _vehicle;
                };
            } else {
                // If unit is on foot
                _yellowTeam pushBack _x;
            };
        };
    } forEach (units _group);
    
    [_yellowTeam, _vehicles]
};

// Function to set up communications center
fnc_setupCommsCenter = {
    params ["_building"];
    
    // Action to convert yellow team into High Command group
    _building addAction [
        "<t color='#FFD700'>Convert Yellow Team to High Command Group</t>",
        {
            params ["_target", "_caller", "_actionId", "_arguments"];
            
            // Check if player has units or vehicles in yellow team
            private _result = [_caller] call fnc_getYellowTeamUnits;
            _result params ["_yellowTeam", "_vehicles"];
            
            if (count _yellowTeam == 0 && count _vehicles == 0) exitWith {
                hint "You have no units or vehicles in the yellow team. Assign units to yellow team first.";
            };
            
            // Initialize modules pool if it doesn't exist
            if (count (HC_SUBMODULES_POOL getOrDefault [getPlayerUID _caller, []]) == 0) then {
                if (isServer) then {
                    [_caller] call fnc_initHCModulesPool;
                } else {
                    // Solución directa para remoteExec
                    _null = [_caller] remoteExec ["fnc_initHCModulesPool", 2];
                };
                sleep 1;
            };
            
            // Get available submodule
            private _submodule = [_caller] call fnc_getAvailableSubmodule;
            
            if (isNull _submodule) exitWith {
                hint "No more High Command slots available (maximum 20 groups).";
            };
            
            // 1. Create a new temporary group for High Command
            private _newGroup = createGroup [side _caller, true];
            private _groupCount = count (HC_GROUPS getOrDefault [getPlayerUID _caller, []]);
            _newGroup setGroupIdGlobal [format ["HC_Group_%1_%2", name _caller, _groupCount]];
            
            // 2. Transfer vehicles and units to new group
            {
                private _vehicle = _x;
                private _crew = crew _vehicle;
                
                // Transfer entire vehicle and its crew as a unit
                [_vehicle] joinSilent _newGroup;
                {
                    [_x] joinSilent _newGroup;
                } forEach _crew;
                
                // Ensure crew stays in vehicle
                {
                    [_x] orderGetIn true;
                } forEach _crew;
                
                // Set appropriate marker type based on vehicle
                private _markerType = switch (true) do {
                    case (_vehicle isKindOf "Tank"): { "o_armor" };
                    case (_vehicle isKindOf "Wheeled_APC_F"): { "o_mech_inf" };
                    case (_vehicle isKindOf "Car"): { "o_motor_inf" };
                    case (_vehicle isKindOf "Helicopter"): { "o_air" };
                    case (_vehicle isKindOf "Plane"): { "o_plane" };
                    case (_vehicle isKindOf "Ship"): { "o_naval" };
                    default { "n_unknown" };
                };
                
                // Usar setGroupIconParams con los parámetros correctos
                _newGroup setGroupIconParams [[0.8,0.8,0,1], _markerType, 1, true];
            } forEach _vehicles;
            
            // Transfer foot units and set infantry marker if no vehicles
            {
                [_x] joinSilent _newGroup;
            } forEach _yellowTeam;
            
            // Establecer el icono para grupos de infantería
            if (count _vehicles == 0) then {
                _newGroup setGroupIconParams [[0.8,0.8,0,1], "o_inf", 1, true];
            };
            
            // 3. Synchronize in correct order: Leader -> Submodule -> Main Module -> Player
            private _leader = leader _newGroup;
            
            // Step 1: Leader -> Submodule
            _leader synchronizeObjectsAdd [_submodule];
            
            // Mark submodule as occupied
            _submodule setVariable ["isOccupied", true, true];
            _newGroup setVariable ["HC_SUBMODULE", _submodule, true];
            
            // Register new group
            private _playerGroups = HC_GROUPS getOrDefault [getPlayerUID _caller, []];
            _playerGroups pushBack _newGroup;
            HC_GROUPS set [getPlayerUID _caller, _playerGroups];
            publicVariable "HC_GROUPS";
            
            // Force High Command update
            _caller hcSetGroup [_newGroup];
            
            hint format ["High Command group created with %1 units and %2 vehicles. Use CTRL + SPACEBAR to access High Command mode.", count _yellowTeam, count _vehicles];
        },
        nil,
        1.5,
        true,
        true,
        "",
        "true",
        20
    ];
    
    // Action to view current HC groups
    _building addAction [
        "<t color='#87CEEB'>View High Command Groups</t>",
        {
            params ["_target", "_caller", "_actionId", "_arguments"];
            
            private _playerGroups = HC_GROUPS getOrDefault [getPlayerUID _caller, []];
            _playerGroups = _playerGroups select {!isNull _x};
            
            if (count _playerGroups == 0) exitWith {
                hint "You have no active High Command groups.";
            };
            
            private _text = "Active High Command groups:\n\n";
            {
                private _units = units _x;
                private _vehicles = _units select {vehicle _x != _x} apply {vehicle _x};
                _vehicles = _vehicles arrayIntersect _vehicles;
                
                _text = _text + format ["%1: %2 units", groupId _x, count _units];
                if (count _vehicles > 0) then {
                    _text = _text + format [" (%1 vehicles)", count _vehicles];
                };
                _text = _text + "\n";
            } forEach _playerGroups;
            
            hint _text;
        },
        nil,
        1.4,
        true,
        true,
        "",
        "true",
        20
    ];
    
    // Action to dissolve an HC group
    _building addAction [
        "<t color='#FF4444'>Dissolve High Command Group</t>",
        {
            params ["_target", "_caller", "_actionId", "_arguments"];
            
            private _playerGroups = HC_GROUPS getOrDefault [getPlayerUID _caller, []];
            _playerGroups = _playerGroups select {!isNull _x};
            
            if (count _playerGroups == 0) exitWith {
                hint "You have no High Command groups to dissolve.";
            };
            
            // Remove existing selection actions if any
            {
                private _actionID = _target getVariable [format ["HC_Action_%1", _forEachIndex], -1];
                if (_actionID != -1) then {
                    _target removeAction _actionID;
                    _target setVariable [format ["HC_Action_%1", _forEachIndex], nil];
                };
            } forEach _playerGroups;
            
            // Add cancel action
            private _cancelId = _target addAction [
                "<t color='#FFFFFF'>Cancel Dissolution</t>",
                {
                    params ["_target", "_caller", "_actionId", "_arguments"];
                    
                    // Remove all temporary actions
                    {
                        private _actionID = _target getVariable [format ["HC_Action_%1", _forEachIndex], -1];
                        if (_actionID != -1) then {
                            _target removeAction _actionID;
                            _target setVariable [format ["HC_Action_%1", _forEachIndex], nil];
                        };
                    } forEach (HC_GROUPS getOrDefault [getPlayerUID _caller, []]);
                    
                    // Remove cancel action
                    _target removeAction _actionId;
                    
                    hint "Operation cancelled.";
                },
                nil,
                1.0,
                true,
                true,
                "",
                "true",
                20
            ];
            
            // Add dissolution actions for each group
            {
                private _group = _x;
                private _units = units _group;
                private _vehicles = _units select {vehicle _x != _x} apply {vehicle _x};
                _vehicles = _vehicles arrayIntersect _vehicles;
                
                private _actionId = _target addAction [
                    format ["<t color='#FF8888'>Dissolve: %1 (%2 units%3)</t>", 
                        groupId _group, 
                        count _units,
                        if (count _vehicles > 0) then {format [", %1 vehicles", count _vehicles]} else {""}
                    ],
                    {
                        params ["_target", "_caller", "_actionId", "_arguments"];
                        private _group = _arguments select 0;
                        private _cancelId = _arguments select 1;
                        
                        if (!isNull _group) then {
                            // 1. Desynchronize in reverse order
                            private _leader = leader _group;
                            private _submodule = _group getVariable ["HC_SUBMODULE", objNull];
                            
                            if (!isNull _submodule) then {
                                // Leader -> Submodule
                                _leader synchronizeObjectsRemove [_submodule];
                                _submodule setVariable ["isOccupied", false, true];
                            };
                            
                            // 2. Remove group from HC_GROUPS
                            private _playerGroups = HC_GROUPS getOrDefault [getPlayerUID _caller, []];
                            _playerGroups = _playerGroups - [_group]; // Safer than deleteAt
                            HC_GROUPS set [getPlayerUID _caller, _playerGroups];
                            publicVariable "HC_GROUPS";
                            
                            // 3. Rejoin units with player's group
                            {
                                [_x] joinSilent (group _caller);
                            } forEach (units _group);
                            
                            // 4. Delete empty group
                            deleteGroup _group;
                            
                            // 5. Clean up temporary actions
                            {
                                private _actionID = _target getVariable [format ["HC_Action_%1", _forEachIndex], -1];
                                if (_actionID != -1) then {
                                    _target removeAction _actionID;
                                    _target setVariable [format ["HC_Action_%1", _forEachIndex], nil];
                                };
                            } forEach (_playerGroups + [_group]);
                            
                            // Remove cancel action
                            _target removeAction _cancelId;
                            
                            hint "Group dissolved and units reintegrated into your group.";
                        };
                    },
                    [_group, _cancelId],
                    1.1,
                    true,
                    true,
                    "",
                    "true",
                    20
                ];
                
                // Store action ID for later removal
                _target setVariable [format ["HC_Action_%1", _forEachIndex], _actionId];
            } forEach _playerGroups;
            
            hint "Select a High Command group to dissolve, or cancel the operation.";
        },
        nil,
        1.3,
        true,
        true,
        "",
        "true",
        20
    ];
};

// Event Handler to clean up HC modules when a player disconnects
if (isServer) then {
    addMissionEventHandler ["HandleDisconnect", {
        params ["_unit", "_id", "_uid"];
        
        // 1. Clean up groups and their synchronizations
        private _playerGroups = HC_GROUPS getOrDefault [_uid, []];
        {
            if (!isNull _x) then {
                private _leader = leader _x;
                private _submodule = _x getVariable ["HC_SUBMODULE", objNull];
                
                if (!isNull _submodule) then {
                    _leader synchronizeObjectsRemove [_submodule];
                    _submodule setVariable ["isOccupied", false, true];
                };
                
                deleteGroup _x;
            };
        } forEach _playerGroups;
        
        // 2. Clean up main module and its synchronization
        private _mainModule = _unit getVariable ["HC_MODULE", objNull];
        if (!isNull _mainModule) then {
            _unit synchronizeObjectsRemove [_mainModule];
            deleteVehicle _mainModule;
        };
        
        // 3. Clean up submodules
        private _submodules = HC_SUBMODULES_POOL getOrDefault [_uid, []];
        {
            if (!isNull _x) then {
                deleteVehicle _x;
            };
        } forEach _submodules;
        
        HC_GROUPS deleteAt _uid;
        HC_SUBMODULES_POOL deleteAt _uid;
        publicVariable "HC_GROUPS";
        publicVariable "HC_SUBMODULES_POOL";
    }];
};

// Publish necessary functions
publicVariable "fnc_setupCommsCenter";
publicVariable "fnc_getYellowTeamUnits";
publicVariable "fnc_initHCModulesPool";
publicVariable "fnc_getAvailableSubmodule";