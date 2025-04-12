/* =====================================================
   INICIALIZACIÓN DE UNIDADES ENEMIGAS (BLUFOR)
   - Crea grupos iniciales de BLUFOR
   - Configura comportamientos base
   - Prepara sistema de refuerzos
   ===================================================== */

// Configuración principal
BLUFOR_Base = getMarkerPos "blufor_site";
BLUFOR_InitialGroups = 6; // Número de grupos iniciales
BLUFOR_ReinforcementInterval = 400; // Intervalo de refuerzos en segundos
BLUFOR_ReinforcementChance = 0.85; // Probabilidad de recibir refuerzos

// Función para crear un grupo BLUFOR
fnc_createBluforGroup = {
    params ["_type", "_position"];
    
    private _group = createGroup west;
    private _units = [];
    
    // Configuración de unidades según tipo
    switch (_type) do {
        case "INFANTRY": {
            // Líder de escuadrón
            private _leader = _group createUnit [BLUFOR_SquadLeader select 0, _position, [], 0, "NONE"];
            
            // Unidades básicas
            for "_i" from 1 to 8 do {
                private _unitType = selectRandom [
                    BLUFOR_SquadLeader,
                    BLUFOR_AutoRifleman,
                    BLUFOR_AT,
                    BLUFOR_Marksman,
                    BLUFOR_Grenadier,
                    BLUFOR_Marksman
                ];
                private _unit = _group createUnit [_unitType select 0, _position, [], 0, "NONE"];
                _units pushBack _unit;
            };
            
            // Especialista (AT o AA)
            private _specialistType = selectRandom [BLUFOR_AT, BLUFOR_AA];
            private _specialist = _group createUnit [_specialistType select 0, _position, [], 0, "NONE"];
        };
        
        case "MECHANIZED": {
            // Crear vehículo
            private _vehicleType = selectRandom [
                BLUFOR_Vehicle_APC,
                BLUFOR_Vehicle_APC2,
                BLUFOR_Vehicle_IFV
            ];
            private _vehicle = createVehicle [_vehicleType select 0, _position, [], 0, "NONE"];
            createVehicleCrew _vehicle;
            
            // Añadir infantería si es un transporte
            if (_vehicle emptyPositions "cargo" > 0) then {
                for "_i" from 1 to (4 min (_vehicle emptyPositions "cargo")) do {
                    private _unitType = selectRandom [
                        BLUFOR_SquadLeader,
						BLUFOR_AutoRifleman,
						BLUFOR_AT,
						BLUFOR_Marksman,
						BLUFOR_Grenadier,
						BLUFOR_AutoRifleman,
						BLUFOR_AT,
						BLUFOR_Marksman
                    ];
                    private _unit = _group createUnit [_unitType select 0, _position, [], 0, "NONE"];
                    _unit moveInCargo _vehicle;
                };
            };
            
            // Configurar comportamiento del vehículo
            _vehicle setFuel 1;
            _vehicle setVehicleAmmo 1;
            _vehicle setDamage 0;
        };
        
        case "ARMOR": {
            // Crear vehículo blindado
            private _vehicleType = selectRandom [
                BLUFOR_Vehicle_Tank_Light,
                BLUFOR_Vehicle_Tank_Heavy
            ];
            private _vehicle = createVehicle [_vehicleType select 0, _position, [], 0, "NONE"];
            createVehicleCrew _vehicle;
        };
    };
    
    // Configuración común del grupo
    _group deleteGroupWhenEmpty true;
    
    // Retornar el grupo creado
    _group
};

// Función para asignar objetivos al grupo
// Función para asignar objetivos al grupo - VERSIÓN CORREGIDA
// Función para asignar objetivos al grupo - VERSIÓN NATIVA ARMA 3
fnc_assignGroupObjective = {
    params ["_group"];
    
    // Obtener sitios controlados por OPFOR o neutrales
    private _allSites = [];
    for "_i" from 1 to 100 do {
        private _marker = format ["site_%1", _i];
        if (getMarkerPos _marker isEqualTo [0,0,0]) exitWith {};
        _allSites pushBack _marker;
    };
    
    // Filtrar sitios no controlados por BLUFOR
    private _targetSites = _allSites select {
        private _owner = missionNamespace getVariable [_x + "_owner", "NEUTRAL"];
        _owner != "BLUFOR"
    };
    
    if (count _targetSites == 0) exitWith {
        // Todos los sitios están bajo control BLUFOR - patrullar área segura
        private _patrolArea = [BLUFOR_Base, 300, 500, 10, 0, 0.5, 0] call BIS_fnc_findSafePos;
        
        // Crear waypoints de patrulla
        for "_i" from 0 to 3 do {
            private _wpPos = [_patrolArea, 0, 150, 10, 0, 0.5, 0] call BIS_fnc_findSafePos;
            private _wp = _group addWaypoint [_wpPos, 0];
            _wp setWaypointType "MOVE";
            _wp setWaypointBehaviour "AWARE";
            _wp setWaypointSpeed "NORMAL";
            _wp setWaypointCombatMode "RED"; // Asegurarse que está en modo agresivo
        };
        
        // Waypoint cíclico
        private _wpCycle = _group addWaypoint [_patrolArea, 0];
        _wpCycle setWaypointType "CYCLE";
    };
    
    // Seleccionar sitio objetivo más cercano
    private _groupPos = getPos (leader _group);
    _targetSites = [_targetSites, [], { _groupPos distance (getMarkerPos _x) }, "ASCEND"] call BIS_fnc_sortBy;
    private _targetSite = _targetSites select 0;
    private _targetPos = getMarkerPos _targetSite;
    
    // Limpiar waypoints existentes
    while {count waypoints _group > 0} do {
        deleteWaypoint [_group, 0];
    };
    
    // Asignar tarea según tipo de grupo
    if (vehicle (leader _group) == leader _group) then {
        // Grupo de infantería
        private _wp = _group addWaypoint [_targetPos, 50];
        _wp setWaypointType "SAD"; // Search And Destroy
        _wp setWaypointBehaviour "AWARE";
        _wp setWaypointCombatMode "RED";
        _wp setWaypointSpeed "NORMAL";
        _wp setWaypointFormation "WEDGE";
    } else {
        // Grupo mecanizado/armor
        private _wp = _group addWaypoint [_targetPos, 100];
        _wp setWaypointType "SAD";
        _wp setWaypointBehaviour "AWARE";
        _wp setWaypointCombatMode "RED";
        _wp setWaypointSpeed "NORMAL";
        _wp setWaypointFormation "LINE";
    };
    
    // Monitorear estado del grupo
    [_group, _targetSite] spawn {
        params ["_group", "_site"];
        
        while {{alive _x} count units _group > 0} do {
            sleep 30;
            
            // Verificar si han llegado al sitio
            if ((leader _group) distance (getMarkerPos _site) < 200) then {
                // Cambiar a modo defensivo (patrulla)
                while {count waypoints _group > 0} do {
                    deleteWaypoint [_group, 0];
                };
                
                for "_i" from 0 to 3 do {
                    private _wpPos = [getPos (leader _group), 0, 75, 10, 0, 0.5, 0] call BIS_fnc_findSafePos;
                    private _wp = _group addWaypoint [_wpPos, 0];
                    _wp setWaypointType "MOVE";
                    _wp setWaypointBehaviour "AWARE";
                    _wp setWaypointSpeed "LIMITED";
                };
                
                private _wpCycle = _group addWaypoint [getPos (leader _group), 0];
                _wpCycle setWaypointType "CYCLE";
                break;
            };
        };
    };
};

// Sistema de refuerzos
fnc_reinforcementSystem = {
    while {true} do {
        sleep BLUFOR_ReinforcementInterval;
        
        // Verificar si se envían refuerzos
        if (random 1 < BLUFOR_ReinforcementChance) then {
            // Determinar tipo de refuerzo basado en sitios controlados
            private _bluforSites = count (allMapMarkers select {
                _x find "site_" == 0 && 
                {missionNamespace getVariable [_x + "_owner", "NEUTRAL"] == "BLUFOR"}
            });
            
            private _reinforcementType = if (_bluforSites > 2 && random 1 > 0.6) then {
                selectRandom ["MECHANIZED", "ARMOR"]
            } else {
                "INFANTRY"
            };
            
            // Crear refuerzos
            private _spawnPos = [BLUFOR_Base, 10, 50, 5, 0, 0.5, 0] call BIS_fnc_findSafePos;
            private _reinforcementGroup = [_reinforcementType, _spawnPos] call fnc_createBluforGroup;
            [_reinforcementGroup] call fnc_assignGroupObjective;
            
            // Notificación a jugadores
            private _typeName = switch (_reinforcementType) do {
                case "INFANTRY": {"refuerzos de infantería"};
                case "MECHANIZED": {"refuerzos mecanizados"};
                case "ARMOR": {"refuerzos blindados"};
            };
            ["BLUFOR está recibiendo " + _typeName, "systemChat"] remoteExec ["call", -2];
        };
    };
};

// Inicialización de grupos iniciales
for "_i" from 1 to BLUFOR_InitialGroups do {
    private _spawnPos = [BLUFOR_Base, 10, 50, 5, 0, 0.5, 0] call BIS_fnc_findSafePos;
    private _groupType = if (_i <= 2) then {
        "INFANTRY" // Primeros dos grupos son infantería
    } else {
        if (_i <= 5) then {
            "MECHANIZED" // Grupos 3-5 son mecanizados
        } else {
            if (random 1 > 0.3) then {
                "ARMOR" // 70% de probabilidad para los últimos grupos
            } else {
                "MECHANIZED"
            }
        }
    };
    
    private _group = [_groupType, _spawnPos] call fnc_createBluforGroup;
    [_group] call fnc_assignGroupObjective;
    sleep 5;
};

// Iniciar sistema de refuerzos
[] spawn fnc_reinforcementSystem;

// Sistema de monitorización de sitios
[] spawn {
    while {true} do {
        sleep 60;
        
        // Reasignar objetivos a grupos sin tareas
        {
            if (!isNull _x && {count waypoints _x == 0} && {{alive _x} count units _x > 0}) then {
                [_x] call fnc_assignGroupObjective;
            };
        } forEach allGroups select {side _x == west && !isPlayer leader _x};
    };
};

systemChat "BLUFOR AI inicializada correctamente";