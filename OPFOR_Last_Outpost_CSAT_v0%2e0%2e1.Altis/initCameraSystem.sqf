// Archivo: initViewSystem.sqf
// Coloca este archivo en la carpeta de tu misión

// Variables globales
CAMERA_ACTIVE = false;
CAMERA_TARGET = objNull;
CAMERA_OBJECT = objNull;
CAMERA_DISTANCE = 5;
CAMERA_HEIGHT = 2;
CAMERA_ANGLE = 0;
NIGHT_VISION_ACTIVE = false; // Nueva variable para controlar la visión nocturna

// Función para activar el selector de unidades en el mapa
fnc_activateUnitSelector = {
    openMap true;
    ["CameraUnitSelector", "onMapSingleClick", {
        params ["_units", "_pos", "_alt", "_shift"];
        
        // Buscar todas las unidades en un radio amplio
        private _nearUnits = _pos nearEntities [["Man", "Car", "Tank", "Helicopter", "Air"], 300];
        private _opforUnits = _nearUnits select {side _x == east};
        
        // Filtrar basado en tipo y distancia
        private _selectedUnit = objNull;
        private _minDistance = 999999;
        
        {
            private _unit = _x;
            private _unitPos = getPosASL _unit;
            private _distance2D = _pos distance2D _unitPos;
            private _height = _unitPos select 2; // Altura Z
            private _isAir = _unit isKindOf "Air";
            
            // Lógica de "hongo":
            // - Para unidades terrestres: máximo 50m de radio
            // - Para unidades aéreas: hasta 300m dependiendo de la altura
            private _inRange = false;
            
            if (_isAir) then {
                // Para aire, permitir hasta 300m dependiendo de altura
                _inRange = _distance2D < (50 + (_height min 250));
            } else {
                // Para tierra, solo 50m
                _inRange = _distance2D < 50;
            };
            
            // Si está en rango y es la unidad más cercana hasta ahora
            if (_inRange && (_distance2D < _minDistance)) then {
                _selectedUnit = _unit;
                _minDistance = _distance2D;
            };
        } forEach _opforUnits;
        
        if (!isNull _selectedUnit) then {
            // Cerrar el mapa y activar la vista en tercera persona
            openMap false;
            ["CameraUnitSelector", "onMapSingleClick"] call BIS_fnc_removeStackedEventHandler;
            [_selectedUnit] call fnc_activateCamera;
        } else {
            hint "No OPFOR units near this position";
        };
    }, []] call BIS_fnc_addStackedEventHandler;
    
    // Añadir instrucciones en pantalla
    hint "Click en el mapa cerca de una unidad OPFOR para activar la vista en tercera persona.\nPulsa ESC para cancelar.";
    
    // Configurar el manejo de tecla ESC para cancelar la selección
    (findDisplay 12) displayAddEventHandler ["KeyDown", {
        params ["_displayOrControl", "_key", "_shift", "_ctrl", "_alt"];
        if (_key == 1) then { // ESC key
            ["CameraUnitSelector", "onMapSingleClick"] call BIS_fnc_removeStackedEventHandler;
            hint "Selección de unidad cancelada";
            true
        };
        false
    }];
};

// Función para activar la visión nocturna
fnc_toggleNightVision = {
    if (NIGHT_VISION_ACTIVE) then {
        // Desactivar visión nocturna
        NIGHT_VISION_ACTIVE = false;
        false setCamUseTI 0;
        camUseNVG false;
        hint "Night Vision deactivated";
    } else {
        // Activar visión nocturna
        NIGHT_VISION_ACTIVE = true;
        camUseNVG true;
        hint "Night Vision active";
    };
};

// Función para activar la visión térmica
fnc_toggleThermalVision = {
    if (NIGHT_VISION_ACTIVE) then {
        // Si la visión nocturna está activa, desactivarla primero
        NIGHT_VISION_ACTIVE = false;
        camUseNVG false;
        
        // Ciclar entre modos térmicos
        private _currentMode = camUseTI;
        if (_currentMode == 0) then {
            true setCamUseTI 0; // Activar visión térmica blanco-caliente
            hint "Visión térmica: Blanco-caliente";
        } else {
            if (_currentMode == 1) then {
                true setCamUseTI 1; // Visión térmica negro-caliente
                hint "Visión térmica: Negro-caliente";
            } else {
                false setCamUseTI 0; // Desactivar visión térmica
                hint "Visión térmica desactivada";
            };
        };
    } else {
        // Activar visión térmica directamente
        true setCamUseTI 0; // Blanco-caliente
        hint "Visión térmica: Blanco-caliente";
    };
};

// Función para desvolcar vehículo
fnc_unflipVehicle = {
    if (!CAMERA_ACTIVE || isNull CAMERA_TARGET) exitWith {hint "No hay vehículo seleccionado";};
    
    // Comprobar si el objetivo es un vehículo
    if (CAMERA_TARGET isKindOf "LandVehicle") then {
        // Obtener posición actual y vector up
        private _pos = getPosATL CAMERA_TARGET;
        
        // Añadir una pequeña elevación para prevenir que se quede atascado en el terreno
        _pos set [2, (_pos select 2) + 0.5];
        
        // Resetear la orientación del vehículo
        CAMERA_TARGET setPosATL _pos;
        CAMERA_TARGET setVectorUp [0, 0, 1];
        
        hint "Vehículo desvolcado";
    } else {
        hint "El objetivo no es un vehículo";
    };
};

// Función para activar la vista en tercera persona
fnc_activateCamera = {
    params ["_unit"];
    
    if (CAMERA_ACTIVE) then {
        // Desactivar la vista actual si existe
        call fnc_deactivateCamera;
    };
    
    // Configurar las variables de la vista en 3ra persona
    CAMERA_ACTIVE = true;
    CAMERA_TARGET = _unit;
    NIGHT_VISION_ACTIVE = false; // Reiniciar el estado de visión nocturna
    
    // Crear la vista en tercera persona
    CAMERA_OBJECT = "camera" camCreate (position _unit);
    CAMERA_OBJECT cameraEffect ["internal", "back"];
    
    // Crear un control permanente en pantalla con tamaño aumentado
    [] spawn {
        disableSerialization;
        _displayControl = findDisplay 46 ctrlCreate ["RscStructuredText", -1];
        // Aumentar el tamaño vertical del panel para asegurar que ESC sea visible
        _displayControl ctrlSetPosition [0.00, 0.85, 0.3, 0.25]; // Aumentado el alto y ajustada la posición
        _displayControl ctrlSetBackgroundColor [0, 0, 0, 0.5];
        _displayControl ctrlSetTextColor [1, 1, 1, 1];
        _displayControl ctrlSetStructuredText parseText "<t size='0.8' align='left'>Camera Controls:<br/>A/D - Rotate Camera<br/>W/S - Zoom In/Out<br/>Q/E - Adjust Height<br/>N - Night Vision<br/>T - Thermal Vision<br/>Z - Unflip Vehicle<br/>ESC - Exit</t>";
        _displayControl ctrlCommit 0;
        
        // Mantener visible mientras la vista en tercera persona esté activa
        waitUntil {!CAMERA_ACTIVE};
        ctrlDelete _displayControl;
    };

    // Actualizar la posición inicial de la vista
    call fnc_updateCameraPosition;
    
    // Añadir manejadores de eventos para controlar la vista
    CAMERA_KEY_HANDLER = (findDisplay 46) displayAddEventHandler ["KeyDown", {
        params ["_displayOrControl", "_key", "_shift", "_ctrl", "_alt"];
        
        // ESC para salir
        if (_key == 1) then {
            call fnc_deactivateCamera;
            true
        } else {
            // A/D para rotar la vista
            if (_key == 30) then { // A
                CAMERA_ANGLE = CAMERA_ANGLE + 5;
                call fnc_updateCameraPosition;
                true
            } else {
                if (_key == 32) then { // D
                    CAMERA_ANGLE = CAMERA_ANGLE - 5;
                    call fnc_updateCameraPosition;
                    true
                } else {
                    // W/S para acercar/alejar
                    if (_key == 17) then { // W
                        CAMERA_DISTANCE = CAMERA_DISTANCE - 0.5;
                        if (CAMERA_DISTANCE < 1) then { CAMERA_DISTANCE = 1; };
                        call fnc_updateCameraPosition;
                        true
                    } else {
                        if (_key == 31) then { // S
                            CAMERA_DISTANCE = CAMERA_DISTANCE + 0.5;
                            if (CAMERA_DISTANCE > 15) then { CAMERA_DISTANCE = 15; };
                            call fnc_updateCameraPosition;
                            true
                        } else {
                            // Q/E para ajustar altura
                            if (_key == 16) then { // Q
                                CAMERA_HEIGHT = CAMERA_HEIGHT + 0.5;
                                call fnc_updateCameraPosition;
                                true
                            } else {
                                if (_key == 18) then { // E
                                    CAMERA_HEIGHT = CAMERA_HEIGHT - 0.5;
                                    call fnc_updateCameraPosition;
                                    true
                                } else {
                                    // N para activar/desactivar visión nocturna
                                    if (_key == 49) then { // N
                                        call fnc_toggleNightVision;
                                        true
                                    } else {
                                        // T para activar/desactivar visión térmica
                                        if (_key == 20) then { // T
                                            call fnc_toggleThermalVision;
                                            true
                                        } else {
                                            // Z para desvolcar vehículo
                                            if (_key == 44) then { // Z
                                                call fnc_unflipVehicle;
                                                true
                                            };
                                        };
                                    };
                                };
                            };
                        };
                    };
                };
            };
            false
        };
    }];
    
    // Añadir un bucle para mantener la vista siguiendo a la unidad
    [] spawn {
        while {CAMERA_ACTIVE} do {
            if (isNull CAMERA_TARGET || !alive CAMERA_TARGET) then {
                hint "This unit is not available";
                call fnc_deactivateCamera;
            } else {
                call fnc_updateCameraPosition;
            };
            sleep 0.01;
        };
    };
    
    // Añadir instrucciones en pantalla
    hint parseText "View control:<br/>
					A/D - Rotate Camera<br/>
					W/S - Zoom In/Out<br/>
					Q/E - Adjust Height<br/>
					N - Night Vision<br/>
					T - Thermal Vision<br/>
					Z - Unflip Vehicle<br/>
					ESC - Exit";
};

// Función para actualizar la posición de la vista en tercera persona
fnc_updateCameraPosition = {
    if (!CAMERA_ACTIVE || isNull CAMERA_TARGET) exitWith {};
    
    private _targetPos = ASLToAGL (getPosASL CAMERA_TARGET);
    private _cameraPos = [
        (_targetPos select 0) + (sin CAMERA_ANGLE * CAMERA_DISTANCE),
        (_targetPos select 1) + (cos CAMERA_ANGLE * CAMERA_DISTANCE),
        (_targetPos select 2) + CAMERA_HEIGHT
    ];
    
    CAMERA_OBJECT camSetPos _cameraPos;
    CAMERA_OBJECT camSetTarget CAMERA_TARGET;
    CAMERA_OBJECT camCommit 0;
};

// Función para desactivar la vista en tercera persona
fnc_deactivateCamera = {
    CAMERA_ACTIVE = false;
    
    // Desactivar la visión nocturna y térmica si estaban activas
    if (NIGHT_VISION_ACTIVE) then {
        camUseNVG false;
    };
    false setCamUseTI 0;
    
    if (!isNull CAMERA_OBJECT) then {
        CAMERA_OBJECT cameraEffect ["terminate", "back"];
        camDestroy CAMERA_OBJECT;
    };
    
    CAMERA_OBJECT = objNull;
    CAMERA_TARGET = objNull;
    
    if (!isNil "CAMERA_KEY_HANDLER") then {
        (findDisplay 46) displayRemoveEventHandler ["KeyDown", CAMERA_KEY_HANDLER];
    };
    
    // Restaurar vista normal del jugador
    player switchCamera "internal";
    
    // Eliminar cualquier control en pantalla
    disableSerialization;
    {
        if (ctrlText _x find "Camera Controls" != -1) then {
            ctrlDelete _x;
        };
    } forEach (allControls findDisplay 46);
};

// Crear el addAction para la laptop
//fnc_setupLaptopCameraAction = {
//    params ["_laptop"];
    
//    _laptop addAction [
//        "<t color='#00FFFF'>Activate Unit Camera View</t>",
//        { [] call fnc_activateUnitSelector; },
//        nil, 1.4, true, true, "", "true", 20
//    ];
//};