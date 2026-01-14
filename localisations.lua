MH_TitleID = "ID"
MH_TitleTexture="Texture"

MH_Player = "Player"
MH_Target = "Target"
MH_Party1 = "Party" .. "1"
MH_Party2 = "Party" .. "2"
MH_Party3 = "Party" .. "3"
MH_Party4 = "Party" .. "4"
MH_TitleName = "Model"
MH_TITLEMANUALID = "Manual ID Entry:"
MH_DEFAULTMINIMAPPOS = 320

MH_PRESETS = "Presets"
MH_NEWPRESET = "New Preset"
MH_ADDPRESETS = "+"
MH_DELETEPRESET = "-"
MH_APPLYPRESET = "Apply"
MH_PRESETSTOOLTIP = "Click to select a preset"
MH_ADDPRESETSTOOLTIP = "Click to add new preset"
MH_DELETEPRESETTOOLTIP = "Click to delete current preset"
MH_APPLYPRESETTOOLTIP = "Click to apply current preset"
MH_PRESETMODETOOLTIP = "Click to enable preset mode.\nMorphs won't actually apply in this mode, unit's won't be checked."

MH_TOOLTIPMORPH = "Click to morph %s"
MH_TOOLTIPMORPHMOUNT = "Click to morph %s's mount"
MH_TOOLTIPMORPHRESET = "Click to reset %s's morphs\nRelogging will clear morphs if this fails"
MH_TOOLTIPMORPHINFO = "Click to see %s's displayID"
MH_TOOLTIPMOUNTINFO = "Click to see %s's mount displayID"
MH_TOOLTIPMOUNTRESET = "Click to reset %s's mount morphs\nRelogging will clear morphs if this fails"
MH_TOOLTIPNOUNIT = "Unit not found"
MH_TOOLTIPFAVORITES = "Click to add to favorites"
MH_TOOLTIPFAVORITESDELETE = "Click to remove from favorites"

MH_CATEGORY_ALL = "All"
MH_CATEGORY_RACES = "Races"
MH_CATEGORY_MOUNTS = "Mounts"
MH_CATEGORY_FAVORITES = "Favorites"

MH_IDSWAPS = "DisplayID Swap"
MH_MOUNTIDSWAPS = "Mount ID Swap"
MH_IDSWAPSTOOLTIP = "Click to enter ID\n|ccf3CE13FTIP:|r Click list after for ID"
MH_OLDIDTITLE = "Old ID:"
MH_NEWIDTITLE = "New ID:"

MH_MINIMAPTOOLTIP = "MorphHelper\nClick to open options\nRight click and drag to move"

MH_DEFAULT_PRESETS = {
    {
        Name="Full Orc Male",
        Morphs = {
            { --player
                ID = 51,
                MID = -1;
            },
            { --target
                ID = 51,
                MID = -1;
            },
            { --party1
                ID = 51,
                MID = -1;
            },
            { --party2
                ID = 51,
                MID = -1;
            },
            { --party3
                ID = 51,
                MID = -1;
            },
            { --party4
                ID = 51,
                MID = -1;
            },
        };
    },    
    {
        Name="Gnomish Motorcycle Gang",
        Morphs = {
            { --player
                ID = 1563,
                MID = 33086;
            },
            { --target
                ID = 1563,
                MID = 33086;
            },
            { --party1
                ID = 1563,
                MID = 33086;
            },
            { --party2
                ID = 1563,
                MID = 33086;
            },
            { --party3
                ID = 1563,
                MID = 33086;
            },
            { --party4
                ID = 1563,
                MID = 33086;
            },
        };
    },
    {
        Name="Set All",
        Morphs = {
            { --player
                ID = 240,
                MID = 235;
            },
            { --target
                ID = 240,
                MID = 235;
            },
            { --party1
                ID = 240,
                MID = 235;
            },
            { --party2
                ID = 240,
                MID = 235;
            },
            { --party3
                ID = 240,
                MID = 235;
            },
            { --party4
                ID = 240,
                MID = 235;
            },
        }
    },
    {
        Name="Reset All",
        Morphs = {
            { --player
                ID = 0,
                MID = 0;
            },
            { --target
                ID = 0,
                MID = 0;
            },
            { --party1
                ID = 0,
                MID = 0;
            },
            { --party2
                ID = 0,
                MID = 0;
            },
            { --party3
                ID = 0,
                MID = 0;
            },
            { --party4
                ID = 0,
                MID = 0;
            },
        }
    }
}

MH_TEST = "ERROR"
MH_TESTID = "ERROR"

MH_STARDISABLEDICO = "Interface\\AddOns\\MorphHelper\\Assets\\star_disabled.tga"
MH_STARICO = "Interface\\AddOns\\MorphHelper\\Assets\\star2.tga"