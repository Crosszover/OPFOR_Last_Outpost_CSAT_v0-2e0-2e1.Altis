// Archivo de configuración de unidades OPFOR
// Guardar en la carpeta raíz como "opforUnits.sqf"
// Infantry - CSAT estándar (convertido)
OPFOR_Officer         = ["O_Officer_F", 15, 200];
OPFOR_SquadLeader    = ["O_Soldier_SL_F", 10, 150];
OPFOR_Grenadier      = ["O_Soldier_GL_F", 10, 100];
OPFOR_AutoRifleman   = ["O_Soldier_AR_F", 10, 125];
OPFOR_Rifleman       = ["O_Soldier_F", 8, 75];
OPFOR_Marksman       = ["O_Soldier_M_F", 12, 150];
OPFOR_Engineer       = ["O_Engineer_F", 10, 125];
OPFOR_Medic          = ["O_Medic_F", 10, 125];
OPFOR_MachineGunner  = ["O_Soldier_MG_F", 12, 150];
OPFOR_AA             = ["O_Soldier_AA_F", 15, 200];
OPFOR_AT             = ["O_Soldier_AT_F", 12, 175];
OPFOR_HAT            = ["O_Soldier_HAT_F", 15, 250];
OPFOR_Crew          = ["O_Crew_F", 8, 100];
OPFOR_Pilot         = ["O_Helipilot_F", 10, 150];
// Light Vehicles - SLA (modified)
OPFOR_Vehicle_Car     = ["CUP_O_Tigr_M_233114_CSAT", 20, 300];
OPFOR_Vehicle_CarMG   = ["CUP_O_Tigr_M_233114_KORD_CSAT", 25, 500];
OPFOR_Vehicle_CarAT   = ["CUP_O_BRDM2_ATGM_CSAT_T", 30, 750];
OPFOR_Vehicle_Truck   = ["O_Truck_02_covered_F", 25, 400];
OPFOR_Vehicle_APC     = ["CUP_O_BTR60_CSAT", 35, 1000];
OPFOR_Vehicle_APC2    = ["O_APC_Wheeled_02_rcws_v2_F", 35, 1200];
OPFOR_Vehicle_IFV     = ["O_APC_Tracked_02_cannon_F", 40, 1500];
OPFOR_Vehicle_AA_Light = ["CUP_O_Ural_ZU23_SLA", 30, 1000];
OPFOR_Vehicle_Artillery = ["CUP_O_BM21_SLA", 45, 2000];
// Heavy Vehicles - SLA (modified)
OPFOR_Vehicle_Tank_Light = ["O_MBT_02_cannon_F", 45, 2000];
OPFOR_Vehicle_Tank_Heavy = ["CUP_O_T90MS_CSAT", 50, 2500];
OPFOR_Vehicle_AA_Heavy   = ["O_APC_Tracked_02_AA_F", 40, 1800];
// Support Vehicles - SLA (modified)
OPFOR_Vehicle_Command    = ["CUP_O_BRDM2_HQ_SLA", 30, 5000];
OPFOR_Vehicle_Repair     = ["O_Truck_02_Box_F", 25, 800];
OPFOR_Vehicle_Ammo       = ["O_Truck_02_Ammo_F", 25, 800];
OPFOR_Vehicle_Fuel       = ["O_Truck_03_fuel_F", 25, 800];
// Air Assets - SLA (modified)
OPFOR_Heli_Light        = ["CUP_O_UH1H_SLA", 40, 2000];
OPFOR_Heli_Transport    = ["O_Heli_Light_02_unarmed_F", 45, 2500];
OPFOR_Heli_Attack       = ["CUP_O_Mi24_D_Dynamic_CSAT_T", 50, 3500];
OPFOR_Heli_Attack_Heavy = ["O_Heli_Attack_02_dynamicLoadout_F", 60, 4000];
OPFOR_Plane_Light       = ["CUP_O_C47_SLA", 35, 1500];
OPFOR_Plane_CAS         = ["O_Plane_CAS_02_dynamicLoadout_F", 60, 4500];
// Arrays for iteration if needed
OPFOR_ALL_UNITS = [
    OPFOR_Officer,
    OPFOR_SquadLeader,
    OPFOR_Grenadier,
    OPFOR_AutoRifleman,
    OPFOR_Rifleman,
    OPFOR_Marksman,
    OPFOR_Engineer,
    OPFOR_Medic,
    OPFOR_MachineGunner,
    OPFOR_AA,
    OPFOR_AT,
    OPFOR_HAT,
    OPFOR_Crew,
    OPFOR_Pilot
];
OPFOR_ALL_VEHICLES = [
    OPFOR_Vehicle_Car,
    OPFOR_Vehicle_CarMG,
    OPFOR_Vehicle_CarAT,
    OPFOR_Vehicle_Truck,
    OPFOR_Vehicle_APC,
    OPFOR_Vehicle_APC2,
    OPFOR_Vehicle_IFV,
    OPFOR_Vehicle_AA_Light,
    OPFOR_Vehicle_Artillery,
    OPFOR_Vehicle_Tank_Light,
    OPFOR_Vehicle_Tank_Heavy,
    OPFOR_Vehicle_AA_Heavy,
    OPFOR_Vehicle_Command,
    OPFOR_Vehicle_Repair,
    OPFOR_Vehicle_Ammo,
    OPFOR_Vehicle_Fuel
];
OPFOR_ALL_AIR = [
    OPFOR_Heli_Light,
    OPFOR_Heli_Transport,
    OPFOR_Heli_Attack,
    OPFOR_Heli_Attack_Heavy,
    OPFOR_Plane_Light,
    OPFOR_Plane_CAS
];