// Esperar hasta que comience la misión
waitUntil {time > 0};

// Verificar si existe el objeto laptop
if (isNil "laptop") exitWith {
    diag_log "HC Module Error: 'laptop' object not found in mission";
};

// Agregar acción al laptop
laptop addAction [
    "<t color='#FFD700'>Initialize Communications Center</t>",
    {
        params ["_target", "_caller", "_actionId", "_arguments"];
        
        // Verificar si existe HC_module.sqf y ejecutarlo
        if (isClass (configFile >> "CfgPatches" >> "A3_Modules_F")) then {
            // Configurar el laptop como centro de comunicaciones
            [_target] call fnc_setupCommsCenter;
            
            // Eliminar esta acción después del primer uso
            _target removeAction _actionId;
            
            hint "Communications Center Initialized";
            
            // Efecto de sonido para la inicialización
            playSound3D ["a3\sounds_f\sfx\beep_target.wss", _target, false, getPosASL _target, 1, 1, 20];
        } else {
            hint "Error: Required modules not found. Please contact mission administrator.";
        };
    },
    nil,
    10,
    true,
    true,
    "",
    "alive _target && _this distance _target < 3",
    3
];

// Registrar inicialización exitosa
diag_log "HC Laptop initialized successfully";