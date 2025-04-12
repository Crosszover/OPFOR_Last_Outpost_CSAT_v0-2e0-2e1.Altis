// Script para añadir la acción de acceso al Arsenal Virtual
// Coloca este código en el init.sqf o en un archivo separado que se ejecute al inicio

// Busca el objeto llamado "arsenal"
_arsenalObj = missionNamespace getVariable ["arsenal", objNull];

// Comprueba si se encontró el objeto
if (isNull _arsenalObj) then {
    // Si no se encuentra, muestra un mensaje de error en el registro
    diag_log "ERROR: No se encontró el objeto 'arsenal'. Asegúrate de que existe un objeto con variable 'arsenal'.";
} else {
    // Añade la acción al objeto arsenal
    _arsenalObj addAction [
        "<t color='#45f442'>Open Virtual Arsenal</t>",  // Texto que se muestra en la acción (verde)
        {
            // Código que se ejecuta cuando el jugador selecciona la acción
            ["Open", true] spawn BIS_fnc_arsenal;
        },
        nil,        // Argumentos (ninguno en este caso)
        6,          // Prioridad (mayor número = mayor prioridad)
        true,       // Mostrar a distancia
        true,       // Mostrar sólo si la condición es verdadera
        "",         // Condición (vacía significa siempre verdadera)
        "",         // Radio de la acción en metros (vacío usa el predeterminado)
        3           // Distancia máxima para mostrar la acción
    ];
    
    // Mensaje en el registro para confirmar que se ha añadido la acción
    diag_log "Se ha añadido correctamente la acción de Arsenal Virtual al objeto 'arsenal'.";
};

