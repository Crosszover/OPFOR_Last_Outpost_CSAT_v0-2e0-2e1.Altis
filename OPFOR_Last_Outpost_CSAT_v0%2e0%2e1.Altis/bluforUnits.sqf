// BLUFOR Units Configuration File
// Save in the root folder as "bluforUnits.sqf"
// Infantry - NATO Original
BLUFOR_Officer         = ["B_officer_F", 15, 200];
BLUFOR_SquadLeader     = ["B_Soldier_SL_F", 10, 150];
BLUFOR_Grenadier       = ["B_Soldier_GL_F", 10, 100];
BLUFOR_AutoRifleman    = ["B_soldier_AR_F", 10, 125];
BLUFOR_Rifleman        = ["B_Soldier_F", 8, 75];
BLUFOR_Marksman        = ["B_soldier_M_F", 12, 150];
BLUFOR_Engineer        = ["B_engineer_F", 10, 125];
BLUFOR_Medic           = ["B_medic_F", 10, 125];
BLUFOR_MachineGunner   = ["B_soldier_AR_F", 12, 150];
BLUFOR_AA              = ["B_soldier_AA_F", 15, 200];
BLUFOR_AT              = ["B_soldier_AT_F", 12, 175];
BLUFOR_HAT             = ["B_soldier_LAT_F", 15, 250];
BLUFOR_Crew            = ["B_crew_F", 8, 100];
BLUFOR_Pilot           = ["B_Helipilot_F", 10, 150];
// Light Vehicles - NATO Original
BLUFOR_Vehicle_Car     = ["B_MRAP_01_F", 20, 300];
BLUFOR_Vehicle_CarMG   = ["B_MRAP_01_hmg_F", 25, 500];
BLUFOR_Vehicle_CarAT   = ["B_MRAP_01_gmg_F", 30, 750];
BLUFOR_Vehicle_Truck   = ["B_Truck_01_covered_F", 25, 400];
BLUFOR_Vehicle_APC     = ["B_APC_Wheeled_01_cannon_F", 35, 1000];
BLUFOR_Vehicle_APC2    = ["B_APC_Tracked_01_rcws_F", 35, 1200];
BLUFOR_Vehicle_IFV     = ["B_APC_Tracked_01_CRV_F", 40, 1500];
BLUFOR_Vehicle_AA_Light = ["B_APC_Tracked_01_AA_F", 30, 1000];
BLUFOR_Vehicle_Artillery = ["B_MBT_01_arty_F", 45, 2000];
// Heavy Vehicles - NATO Original
BLUFOR_Vehicle_Tank_Light = ["B_MBT_01_TUSK_F", 45, 2000];
BLUFOR_Vehicle_Tank_Heavy = ["B_MBT_01_cannon_F", 50, 2500];
BLUFOR_Vehicle_AA_Heavy   = ["B_APC_Tracked_01_AA_F", 40, 1800];
// Support Vehicles - NATO Original
BLUFOR_Vehicle_Command    = ["B_MRAP_01_F", 30, 5000];
BLUFOR_Vehicle_Repair     = ["B_Truck_01_Repair_F", 25, 800];
BLUFOR_Vehicle_Ammo       = ["B_Truck_01_ammo_F", 25, 800];
BLUFOR_Vehicle_Fuel       = ["B_Truck_01_fuel_F", 25, 800];
// Air Assets - NATO Original
BLUFOR_Heli_Light         = ["B_Heli_Light_01_F", 40, 2000];
BLUFOR_Heli_Transport     = ["B_Heli_Transport_01_F", 45, 2500];
BLUFOR_Heli_Attack        = ["B_Heli_Attack_01_dynamicLoadout_F", 50, 3500];
BLUFOR_Heli_Attack_Heavy  = ["B_Heli_Transport_03_F", 60, 4000];
BLUFOR_Plane_Light        = ["B_Plane_CAS_01_dynamicLoadout_F", 35, 1500];
BLUFOR_Plane_CAS          = ["B_Plane_Fighter_01_F", 60, 4500];
// Arrays for iteration if needed
BLUFOR_ALL_UNITS = [
    BLUFOR_Officer,
    BLUFOR_SquadLeader,
    BLUFOR_Grenadier,
    BLUFOR_AutoRifleman,
    BLUFOR_Rifleman,
    BLUFOR_Marksman,
    BLUFOR_Engineer,
    BLUFOR_Medic,
    BLUFOR_MachineGunner,
    BLUFOR_AA,
    BLUFOR_AT,
    BLUFOR_HAT,
    BLUFOR_Crew,
    BLUFOR_Pilot
];
BLUFOR_ALL_VEHICLES = [
    BLUFOR_Vehicle_Car,
    BLUFOR_Vehicle_CarMG,
    BLUFOR_Vehicle_CarAT,
    BLUFOR_Vehicle_Truck,
    BLUFOR_Vehicle_APC,
    BLUFOR_Vehicle_APC2,
    BLUFOR_Vehicle_IFV,
    BLUFOR_Vehicle_AA_Light,
    BLUFOR_Vehicle_Artillery,
    BLUFOR_Vehicle_Tank_Light,
    BLUFOR_Vehicle_Tank_Heavy,
    BLUFOR_Vehicle_AA_Heavy,
    BLUFOR_Vehicle_Command,
    BLUFOR_Vehicle_Repair,
    BLUFOR_Vehicle_Ammo,
    BLUFOR_Vehicle_Fuel
];
BLUFOR_ALL_AIR = [
    BLUFOR_Heli_Light,
    BLUFOR_Heli_Transport,
    BLUFOR_Heli_Attack,
    BLUFOR_Heli_Attack_Heavy,
    BLUFOR_Plane_Light,
    BLUFOR_Plane_CAS
];