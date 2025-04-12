// Function to buy INTEL Report (información genérica de unidades BLUFOR)
fnc_buyIntel = {
    params ["_cost"];

    // Verificar fondos
    if !([_cost] call fnc_checkFunds) exitWith {
        hint "Not enough funds for INTEL Report";
        false
    };

    // Crear y gestionar los marcadores
    [] spawn {
        _markers = [];
        _bluforGroups = allGroups select {side _x == west};
        
        {
            _group = _x;
            _units = units _group;
            _leader = leader _group;
            _unitCount = count _units;
            _groupType = "";
            
            // Determinar el tipo de grupo
            if (_leader isKindOf "Man") then {
                _vehicles = [];
                {
                    _vehicle = vehicle _x;
                    if (_vehicle != _x && !(_vehicle in _vehicles)) then {
                        _vehicles pushBack _vehicle;
                    };
                } forEach _units;
                
                if (count _vehicles > 0) then {
                    _vehicleType = typeOf (_vehicles select 0);
                    _groupType = getText (configFile >> "CfgVehicles" >> _vehicleType >> "displayName");
                } else {
                    _groupType = format ["Infantry (%1 units)", _unitCount];
                };
            } else {
                _vehicle = vehicle _leader;
                _vehicleType = typeOf _vehicle;
                _groupType = getText (configFile >> "CfgVehicles" >> _vehicleType >> "displayName");
            };
            
            // Crear marcador
            _markerName = format ["blufor_marker_%1_%2", _forEachIndex, random 1000];
            _marker = createMarker [_markerName, getPos _leader];
            _marker setMarkerShape "ICON";
            _marker setMarkerType "mil_dot";
            _marker setMarkerColor "ColorBLUFOR";
            _marker setMarkerText _groupType;
            _markers pushBack _marker;
            
        } forEach _bluforGroups;

        sleep 60;
        { deleteMarker _x } forEach _markers;
    };

    // Mensaje de confirmación
    private _message = format ["INTEL Report activated\nEnemy units visible for 60 seconds\nRemaining funds: %1", available_funds];
    [_message, "hint", clientOwner] call BIS_fnc_MP;
    
    ["INTEL Report purchased", "systemChat", clientOwner] call BIS_fnc_MP;
    playSound "FD_Finish_F";
    
    true
};