// Array para almacenar los marcadores creados
playerTrackingMarkers = [];

// Función para actualizar los marcadores
fn_updateMarkers = {
    // Eliminar marcadores antiguos
    {
        deleteMarker _x;
    } forEach playerTrackingMarkers;
    playerTrackingMarkers = [];
    
    // Crear nuevos marcadores para cada jugador OPFOR humano
    {
        if (side _x == east && isPlayer _x) then {
            private _pos = getPos _x;
            private _name = name _x;
            
            // Crear marcador global
            private _marker = createMarker [format ["opformarker_%1_%2", _name, random 1000], _pos];
            _marker setMarkerShape "ICON";
            _marker setMarkerType "mil_dot";
            _marker setMarkerColor "ColorRed";
            _marker setMarkerText _name;
            
            // Añadir marcador al array
            playerTrackingMarkers pushBack _marker;
        };
    } forEach allUnits;
};

// La actualización de marcadores debe ejecutarse en el servidor para que todos vean los marcadores
if (isServer) then {
    // Bucle principal para actualizar los marcadores cada segundo
    [] spawn {
        while {true} do {
            call fn_updateMarkers;
            sleep 1;
        };
    };
    
    // Mensaje de confirmación global
    ["OPFOR player tracking started."] remoteExec ["hint", 0];
};