Config = {}

Config.UI = {
    type = 'ox_lib', -- Dont touch
}
Config.Elevators = {
    PillboxElevatorNorth = {
        settings = {
            name = 'Pillbox Hospital North',
            icon = 'fa-solid fa-hospital', -- Font Awesome icon
            theme = {
                primary = '#3498db',
                secondary = '#2980b9',
                text = '#ffffff'
            }
        },
        floors = {
            {
                level = 2,
                coords = vec3(332.37, -595.56, 43.28),
                heading = 70.65,
                title = 'Floor 2',
                description = 'Main Floor',
                icon = 'fa-solid fa-building',
                target = {
                    width = 5,
                    length = 4
                },
                groups = {
                    'police',
                    'ambulance'
                },
            },
            {
                level = 1,
                coords = vec3(344.31, -586.12, 28.79),
                heading = 252.84,
                title = 'Floor 1',
                description = 'Lower Floor',
                icon = 'fa-solid fa-square-parking',
                target = {
                    width = 5,
                    length = 4
                }
            },
        }
    },
    FIBElevator = {
        settings = {
            name = 'FIB Building',
            icon = 'fa-solid fa-building', -- Font Awesome icon
            theme = {
                primary = '#3498db',
                secondary = '#2980b9',
                text = '#ffffff'
            }
        },
        floors = {
            {
                level = 3,
                coords = vec3(156.84, -757.29, 258.15),
                heading = 70.65,
                title = 'Floor 3',
                description = 'Top Floor',
                icon = 'fa-solid fa-building',
                target = {
                    width = 5,
                    length = 4
                },
                groups = {
                    'police'
                },
            },
            {
                level = 2,
                coords = vec3(136.07, -762.02, 242.15),
                heading = 70.65,
                title = 'Floor 2',
                description = 'Main Floor',
                icon = 'fa-solid fa-building',
                target = {
                    width = 5,
                    length = 4
                },
                groups = {
                    'police'
                },
            },
            {
                level = 1,
                coords = vec3(138.93, -763.08, 45.75),
                heading = 70.65,
                title = 'Floor 1',
                description = 'Lower Floor',
                icon = 'fa-solid fa-square-parking',
                target = {
                    width = 5,
                    length = 4
                }
            },
        }
    }
}

-- Dont edit if you dont know what you are doing
Config.Animations = {
    entering = {
        dict = "anim@apt_trans@elevator",
        name = "elev_1",
        flags = 0
    },
    waiting = {
        dict = "mini@safe_cracking",
        name = "idle_base",
        flags = 1
    }
}

Config.Sounds = {
    elevatorArrived = 'elevator-ding',
    elevatorMoving = 'elevator-moving',
    buttonPress = 'button-press'
}
