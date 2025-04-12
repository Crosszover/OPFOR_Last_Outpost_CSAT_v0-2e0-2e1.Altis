/* =====================================================
   SISTEMA DE CAPTURA DE ZONAS (VERSIÓN FINAL)
   - Todos los sitios comienzan neutrales
   - Revelación automática de unidades enemigas
   - Generación de recursos periódicos
   - Sistema simplificado sin codenames
   - Feedback visual claro
   ===================================================== */

// ************ CONFIGURACIÓN PRINCIPAL ************ //
_resourceInterval = 300;      // Intervalo de generación de recursos (segundos)
_resourceAmount = 300;        // Recursos generados por intervalo
_markerRadius = 150;          // Radio de captura (metros)
_revealInterval = 60;         // Frecuencia de revelación (segundos)
_allowNeutralRecapture = true; // ¿Los sitios pueden volver a neutral?

// ************ FUNCIONES DEL SISTEMA ************ //

// Obtiene el nombre del marcador de texto más cercano
fnc_getDisplayName = {
    params ["_pos"];
    private _textMarkers = allMapMarkers select {markerType _x == "hd_dot" && markerText _x != ""};
    if (_textMarkers isEqualTo []) exitWith {""};
    
    _textMarkers sort [_pos] distance _x;
    markerText (_textMarkers select 0)
};

// Inicializa un sitio de captura (VERSIÓN CORREGIDA)
fnc_initializeSite = {
    params ["_markerName", "_pos"];
    
    // Configurar marcadores
    _markerName setMarkerAlpha 0; // Oculta el marcador original
    
    // Crear área de captura
    private _circle = createMarker [_markerName + "_zone", _pos];
    _circle setMarkerShape "ELLIPSE";
    _circle setMarkerSize [_markerRadius, _markerRadius];
    _circle setMarkerColor "ColorYellow";
    _circle setMarkerAlpha 0.4;
    
    // Nombre display (usar texto de marcador cercano o nombre por defecto)
    private _displayName = [_pos] call fnc_getDisplayName;
    if (_displayName == "") then {_displayName = _markerName};
    
    private _textMarker = createMarker [_markerName + "_text", _pos];
    _textMarker setMarkerType "hd_flag";
    _textMarker setMarkerText _displayName;
    _textMarker setMarkerColor "ColorYellow";
    
    // Inicializar variables
    missionNamespace setVariable [_markerName + "_owner", "NEUTRAL", true];
    missionNamespace setVariable [_markerName + "_lastReveal", 0, true];
    missionNamespace setVariable [_markerName + "_lastChange", time, true]; // Nueva variable para tiempo de último cambio
    
    // Trigger de captura mejorado
    private _trigger = createTrigger ["EmptyDetector", _pos, true];
    _trigger setTriggerArea [_markerRadius, _markerRadius, 0, false];
    _trigger setTriggerActivation ["ANY", "PRESENT", true];
    _trigger setTriggerInterval 5;
    _trigger setTriggerStatements [
        "this",
        format ["[thisTrigger, '%1'] call fnc_checkOwnership;", _markerName],
        ""
    ];
    
    // Hilo de generación de recursos (versión mejorada con verificación de dueño)
    [_markerName, _resourceInterval, _resourceAmount] spawn {
        params ["_marker", "_interval", "_amount"];
        while {true} do {
            sleep _interval;
            private _owner = missionNamespace getVariable [_marker + "_owner", "NEUTRAL"];
            private _lastChange = missionNamespace getVariable [_marker + "_lastChange", 0];
            
            // Solo generar recursos si el sitio ha sido controlado por al menos 1 intervalo completo
            if (_owner in ["BLUFOR","OPFOR"] && {time - _lastChange > _interval}) then {
                if (_owner == "BLUFOR") then {
                    available_funds = available_funds + _amount;
                    publicVariable "available_funds";
                    systemChat format ["[RECURSOS] +%1 por controlar %2", _amount, _marker];
                };
            };
        };
    };
    
    _markerName
};


// Verifica el control del sitio (VERSIÓN FINAL CORREGIDA)
fnc_checkOwnership = {
    params ["_trigger", "_marker"];
    private _pos = getPos _trigger;
    private _currentOwner = missionNamespace getVariable [_marker + "_owner", "NEUTRAL"];
    
    // Función mejorada para verificar unidades válidas
    private _fnc_isValidUnit = {
        params ["_unit"];
        private _isValid = false;
        
        if (alive _unit) then {
            if (_unit isKindOf "CAManBase") then {
                // Infantería: válida si está viva y consciente (no incapacitada)
                _isValid = alive _unit && (_unit getVariable ["ACE_isUnconscious", false] != true);
            } else {
                // Vehículos: debe estar operativo (no destruido) y con tripulación viva o capacidad de movimiento
                _isValid = alive _unit && (canMove _unit || {count crew _unit > 0});
            };
        };
        
        _isValid
    };
    
    // Contar unidades por bando (excluyendo vehículos destruidos/vacíos y unidades incapacitadas)
    private _blufor = {
        private _unit = _x;
        side _unit == WEST && 
        ([_unit] call _fnc_isValidUnit) && 
        (isPlayer _unit || {count crew _unit > 0})
    } count (allUnits inAreaArray _trigger);
    
    private _opfor = {
        private _unit = _x;
        side _unit == EAST && 
        ([_unit] call _fnc_isValidUnit) && 
        (isPlayer _unit || {count crew _unit > 0})
    } count (allUnits inAreaArray _trigger);
    
    // Determinar nuevo dueño con lógica mejorada
    private _newOwner = switch (true) do {
        case (_opfor == 0 && _blufor == 0): {"NEUTRAL"};
        case (_opfor > 0 && _blufor > 0): {"CONTESTED"};
        case (_opfor > 0 && _blufor == 0): {"OPFOR"};  // Cambio explícito cuando BLUFOR es eliminado
        case (_blufor > 0 && _opfor == 0): {"BLUFOR"}; // Cambio explícito cuando OPFOR es eliminado
        default {_currentOwner};
    };
    
    // Debug information
    systemChat format ["[DEBUG] %1 - BLUFOR: %2, OPFOR: %3, Current: %4, New: %5", 
        _marker, _blufor, _opfor, _currentOwner, _newOwner];
    
    // Cambiar propiedad si es necesario
    if (_newOwner != _currentOwner && _newOwner != "CONTESTED") then {
        // Actualizar dueño
        missionNamespace setVariable [_marker + "_owner", _newOwner, true];
        
        // Actualizar marcadores
        private _color = switch (_newOwner) do {
            case "OPFOR": {"ColorRed"};
            case "BLUFOR": {"ColorBlue"};
            default {"ColorYellow"};
        };
        
        (_marker + "_zone") setMarkerColor _color;
        (_marker + "_text") setMarkerColor _color;
        
        // Notificación mejorada
        private _displayName = markerText (_marker + "_text");
        if (isNil "_displayName" || {_displayName == ""}) then {_displayName = _marker};
        
        private _msg = switch (_newOwner) do {
            case "NEUTRAL": {format ["%1 ha sido liberado (ningún bando presente)", _displayName]};
            case "OPFOR": {format ["%1 capturado por OPFOR (BLUFOR eliminado)", _displayName]};
            case "BLUFOR": {format ["%1 capturado por BLUFOR (OPFOR eliminado)", _displayName]};
        };
        systemChat _msg;
    };
    
    // Revelar enemigos periódicamente
    if (_newOwner in ["OPFOR","BLUFOR"] && {time - (missionNamespace getVariable [_marker + "_lastReveal", 0]) > _revealInterval}) then {
        [_marker, _pos] call fnc_revealEnemies;
        missionNamespace setVariable [_marker + "_lastReveal", time, true];
    };
};

// Revela unidades enemigas
fnc_revealEnemies = {
    params ["_marker", "_pos"];
    private _owner = missionNamespace getVariable [_marker + "_owner", "NEUTRAL"];
    
    private _enemies = allUnits select {
        alive _x && 
        _x distance _pos < _markerRadius && 
        ((_owner == "OPFOR" && side _x == WEST) || (_owner == "BLUFOR" && side _x == EAST))
    };
    
    private _allies = allUnits select {side _x == ([WEST,EAST] select (_owner == "BLUFOR"))};
    
    {_x reveal [_enemies, 1.5]} forEach _allies;
    systemChat format ["[INTEL] Unidades enemigas detectadas en %1", _marker];
};

// ************ INICIALIZACIÓN ************ //

// Busca todos los marcadores site_X
private _sites = [];
for "_i" from 1 to 100 do {
    private _marker = format ["site_%1", _i];
    if (getMarkerPos _marker isEqualTo [0,0,0]) exitWith {};
    _sites pushBack _marker;
};

// Inicializa todos los sitios
{
    [_x, getMarkerPos _x] call fnc_initializeSite;
} forEach _sites;

// Mensaje final
if (_sites isNotEqualTo []) then {
    systemChat format ["Sistema de captura activo (%1 zonas)", count _sites];
} else {
    systemChat "Error: No se encontraron marcadores site_X";
};