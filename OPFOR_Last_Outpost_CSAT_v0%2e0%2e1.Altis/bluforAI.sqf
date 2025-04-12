/* =====================================================
   SISTEMA AVANZADO DE IA PARA BLUFOR
   - Control táctico de unidades
   - Toma de decisiones estratégicas
   - Reacción a amenazas
   ===================================================== */

// Configuración de comportamiento
BLUFOR_AttackThreshold = 0.5; // Umbral para lanzar ataques (0-1)
BLUFOR_DefenseThreshold = 0.4; // Umbral para reforzar defensas (0-1)
BLUFOR_ReconInterval = 180; // Intervalo entre reconocimientos

// Función para evaluar la situación táctica
fnc_assessTacticalSituation = {
    private _bluforStrength = 0;
    private _opforStrength = 0;
    
    // Calcular fuerza BLUFOR
    {
        if (side _x == west) then {
            private _unitValue = if (vehicle _x == _x) then {
                1 // Infantería
            } else {
                if (_x == driver vehicle _x || _x == gunner vehicle _x) then {
                    getNumber (configFile >> "CfgVehicles" >> typeOf vehicle _x >> "cost") / 1000
                } else {
                    0.5 // Pasajeros
                };
            };
            _bluforStrength = _bluforStrength + _unitValue;
        };
    } forEach allUnits;
    
    // Calcular fuerza OPFOR (jugadores)
    {
        if (side _x == east && isPlayer _x) then {
            private _unitValue = if (vehicle _x == _x) then {
                1.5 // Jugadores valen más
            } else {
                if (_x == driver vehicle _x || _x == gunner vehicle _x) then {
                    getNumber (configFile >> "CfgVehicles" >> typeOf vehicle _x >> "cost") / 500
                } else {
                    0.75 // Pasajeros
                };
            };
            _opforStrength = _opforStrength + _unitValue;
        };
    } forEach allUnits;
    
    // Calcular relación de fuerzas
    private _forceRatio = if (_opforStrength > 0) then {
        _bluforStrength / _opforStrength
    } else {
        2 // Ventaja significativa si no hay OPFOR
    };
    
    // Retornar evaluación
    [
        _bluforStrength, 
        _opforStrength, 
        _forceRatio,
        _forceRatio > BLUFOR_AttackThreshold, // ¿Debemos atacar?
        _forceRatio < BLUFOR_DefenseThreshold // ¿Debemos defender?
    ]
};

// Función para asignar prioridades de objetivos - VERSIÓN CORREGIDA
fnc_assignTargetPriorities = {
    private _allSites = [];
    for "_i" from 1 to 100 do {
        private _marker = format ["site_%1", _i];
        if (getMarkerPos _marker isEqualTo [0,0,0]) exitWith {};
        _allSites pushBack _marker;
    };
    
    // Clasificar sitios
    private _bluforSites = [];
    private _opforSites = [];
    private _neutralSites = [];
    
    {
        private _owner = missionNamespace getVariable [_x + "_owner", "NEUTRAL"];
        switch (_owner) do {
            case "BLUFOR": {_bluforSites pushBack _x};
            case "OPFOR": {_opforSites pushBack _x};
            default {_neutralSites pushBack _x};
        };
    } forEach _allSites;
    
    // Ordenar por importancia (sitios OPFOR primero, luego neutrales)
    private _priorityTargets = _opforSites + _neutralSites;
    
    // Ordenar por distancia a la base BLUFOR - FORMA CORRECTA
    if (count _priorityTargets > 0) then {
        _priorityTargets = [_priorityTargets, [], {BLUFOR_Base distance (getMarkerPos _x)}, "ASCEND"] call BIS_fnc_sortBy;
    };
    
    _priorityTargets
};

// Función para asignar fuerzas a objetivos
fnc_assignForcesToObjectives = {
    params ["_shouldAttack", "_priorityTargets"];
    
    private _availableGroups = allGroups select {
        side _x == west && 
        !isPlayer leader _x && 
        {count waypoints _x < 2} && // Grupos con pocas o ninguna waypoint
        {{alive _x} count units _x > 0}
    };
    
    if (count _availableGroups == 0 || count _priorityTargets == 0) exitWith {};
    
    if (_shouldAttack) then {
        // Modo ofensivo - asignar grupos a objetivos de forma más distribuida
        private _groupsAssigned = 0;
        private _targetIndex = 0;
        
        // Primero asignar grupos mecanizados/armor a objetivos aleatorios
        {
            if (vehicle (leader _x) != leader _x) then {
                private _target = _priorityTargets select (_targetIndex % count _priorityTargets);
                
                // Asignar grupo a este objetivo
                private _wp = _x addWaypoint [getMarkerPos _target, 50];
                _wp setWaypointType "SAD";
                _wp setWaypointBehaviour "AWARE";
                _wp setWaypointCombatMode "RED";
                _wp setWaypointCompletionRadius 50;
                
                // Waypoint de ciclo
                private _wpCycle = _x addWaypoint [getMarkerPos _target, 50];
                _wpCycle setWaypointType "CYCLE";
                
                _groupsAssigned = _groupsAssigned + 1;
                _targetIndex = _targetIndex + 1;
                
                // Registrar objetivo
                _x setVariable ["currentObjective", _target, true];
            };
        } forEach _availableGroups;
        
        // Luego asignar infantería a objetivos diferentes
        {
            if (vehicle (leader _x) == leader _x) then {
                private _target = _priorityTargets select (_targetIndex % count _priorityTargets);
                
                // Asignar grupo a este objetivo
                private _wp = _x addWaypoint [getMarkerPos _target, 30];
                _wp setWaypointType "SAD";
                _wp setWaypointBehaviour "AWARE";
                _wp setWaypointCombatMode "RED";
                _wp setWaypointCompletionRadius 30;
                
                // Waypoint de ciclo
                private _wpCycle = _x addWaypoint [getMarkerPos _target, 30];
                _wpCycle setWaypointType "CYCLE";
                
                _groupsAssigned = _groupsAssigned + 1;
                _targetIndex = _targetIndex + 1;
                
                // Registrar objetivo
                _x setVariable ["currentObjective", _target, true];
            };
        } forEach _availableGroups;
    } else {
        // Modo defensivo - reforzar sitios BLUFOR de forma más inteligente
        private _bluforSites = allMapMarkers select {
            _x find "site_" == 0 && 
            {missionNamespace getVariable [_x + "_owner", "NEUTRAL"] == "BLUFOR"}
        };
        
        if (count _bluforSites > 0) then {
            // Ordenar sitios por proximidad a enemigos
            _bluforSites = [_bluforSites, [], {
                private _nearestEnemy = [allUnits select {side _x == east && alive _x}, getMarkerPos _x] call BIS_fnc_nearestPosition;
                if (isNil "_nearestEnemy") then { 10000 } else { (getMarkerPos _x) distance _nearestEnemy }
            }, "ASCEND"] call BIS_fnc_sortBy;
            
            // Asignar más grupos a sitios más amenazados
            private _groupsPerSite = [];
            private _remainingGroups = count _availableGroups;
            private _totalWeight = count _bluforSites * (count _bluforSites + 1) / 2; // Peso triangular
            
            for "_i" from 0 to (count _bluforSites - 1) do {
                private _weight = (count _bluforSites - _i) / _totalWeight;
                _groupsPerSite pushBack ceil (_remainingGroups * _weight);
            };
            
            // Asignar grupos
            {
                private _site = _x;
                private _groupsToAssign = _groupsPerSite select _forEachIndex;
                private _assignedGroups = 0;
                
                {
                    if (_assignedGroups < _groupsToAssign) then {
                        // Asignar grupo a este sitio para defensa
                        [_x, getMarkerPos _site, 100] call BIS_fnc_taskPatrol;
                        _assignedGroups = _assignedGroups + 1;
                        
                        // Registrar objetivo
                        _x setVariable ["currentObjective", _site, true];
                    };
                } forEach _availableGroups;
            } forEach _bluforSites;
        };
    };
};

// Sistema de reconocimiento
fnc_reconSystem = {
    while {true} do {
        sleep BLUFOR_ReconInterval;
        
        // Obtener sitios controlados por BLUFOR
        private _bluforSites = allMapMarkers select {
            _x find "site_" == 0 && 
            {missionNamespace getVariable [_x + "_owner", "NEUTRAL"] == "BLUFOR"}
        };
        
        // Enviar equipos de reconocimiento a sitios cercanos
        {
            private _sitePos = getMarkerPos _x;
            private _nearEnemies = allUnits select {
                side _x == east && 
                alive _x && 
                _x distance _sitePos < 500 && 
                (isPlayer _x || {count crew vehicle _x > 0})
            };
            
            if (count _nearEnemies > 0) then {
                // Notificar a grupos BLUFOR cercanos
                private _nearBlufor = allGroups select {
                    side _x == west && 
                    {leader _x distance _sitePos < 800} && 
                    {count waypoints _x < 3}
                };
                
                {
                    // Asignar waypoint de ataque a la posición del enemigo
                    private _enemyPos = getPos (selectRandom _nearEnemies);
                    private _wp = _x addWaypoint [_enemyPos, 50];
                    _wp setWaypointType "SAD";
                    _wp setWaypointBehaviour "AWARE";
                    _wp setWaypointCombatMode "RED";
                    
                    // Waypoint de ciclo en el sitio original
                    private _wpCycle = _x addWaypoint [_sitePos, 100];
                    _wpCycle setWaypointType "CYCLE";
                    
                    // Registrar objetivo
                    _x setVariable ["currentObjective", _x, true];
                } forEach _nearBlufor;
            };
        } forEach _bluforSites;
    };
};

// Bucle principal de toma de decisiones
[] spawn {
    while {true} do {
        sleep 60; // Re-evaluar cada 1 minutos
        
        // Evaluar situación táctica
        private _assessment = call fnc_assessTacticalSituation;
        _assessment params ["_bluforStr", "_opforStr", "_ratio", "_shouldAttack", "_shouldDefend"];
        
        // Obtener prioridades de objetivos
        private _priorityTargets = call fnc_assignTargetPriorities;
        
        // Asignar fuerzas según la evaluación
        [_shouldAttack, _priorityTargets] call fnc_assignForcesToObjectives;
        
        // Debug (opcional)
        diag_log format ["BLUFOR AI Assessment - Fuerza BLUFOR: %1, OPFOR: %2, Ratio: %3, Atacar: %4, Defender: %5", 
            _bluforStr, _opforStr, _ratio, _shouldAttack, _shouldDefend];
    };
};

// Iniciar sistemas auxiliares
[] spawn fnc_reconSystem;


// Sistema de retirada táctica - VERSIÓN CORREGIDA
[] spawn {
    while {true} do {
        sleep 30;
        
        {
            if (side _x == west && !isPlayer leader _x) then {
                private _aliveUnits = {alive _x} count units _x;
                if (_aliveUnits > 0) then {
                    private _combatStrength = _aliveUnits;
                    private _enemies = leader _x targets [true, 300];
                    private _enemyStrength = count _enemies;
                    
                    // Verificar si están en desventaja (con protección mejorada contra división por cero)
                    if (_enemyStrength > 0 && _combatStrength > 0) then {
                        private _ratio = _combatStrength / _enemyStrength;
                        if (_ratio < 0.5) then {
                            // Retirarse a la base o sitio BLUFOR más cercano
                            private _retreatPos = if (random 1 > 0.7) then {
                                BLUFOR_Base
                            } else {
                                private _bluforSites = allMapMarkers select {
                                    _x find "site_" == 0 && 
                                    {missionNamespace getVariable [_x + "_owner", "NEUTRAL"] == "BLUFOR"}
                                };
                                
                                if (count _bluforSites > 0) then {
                                    _bluforSites sort [leader _x] distance (getMarkerPos _x);
                                    getMarkerPos (_bluforSites select 0)
                                } else {
                                    BLUFOR_Base
                                };
                            };
                            
                            // Limpiar waypoints existentes
                            while {count waypoints _x > 0} do {
                                deleteWaypoint [_x, 0];
                            };
                            
                            // Crear waypoint de retirada
                            private _wp = _x addWaypoint [_retreatPos, 50];
                            _wp setWaypointType "MOVE";
                            _wp setWaypointBehaviour "AWARE";
                            _wp setWaypointSpeed "FULL";
                            _wp setWaypointFormation "COLUMN";
                            
                            // Mensaje de debug
                            if (random 1 > 0.8) then {
                                private _msg = format ["%1 se retira para reagruparse", groupId _x];
                                [_msg, "systemChat"] remoteExec ["call", -2];
                            };
                        };
                    };
                };
            };
        } forEach allGroups;
    };
};

systemChat "BLUFOR AI táctica inicializada";