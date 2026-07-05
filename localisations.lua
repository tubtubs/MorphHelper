-- addon info
MH_NAME		= "MorphHelper";
MH_VERSION	= "1.6";
MH_NAMEVERSION	= MH_NAME.." v"..MH_VERSION;
MH_AUTHOR = "Tubtubs"

MH_ABOUT = MH_NAMEVERSION .. " by " .. MH_AUTHOR

--on load splashes
MH_S_TWOW = MH_NAME .. ": Turtle Detected"
MH_S_WC = MH_NAME .. ": Wallcraft Detected"
MH_S_VWOW = MH_NAME .. ": Vanilla Detected"

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

-- Addon Messages
MH_AMPREFIX = "MHE"
MH_AMMORPHPLAYER = 0
MH_AMMORPHMOUNT = 1

MH_PRESETS = "Presets"
MH_NEWPRESET = "New Preset"
MH_ADDPRESETS = "+"
MH_DELETEPRESET = "-"
MH_APPLYPRESET = "Apply"
MH_RESETALL = "Reset All"
MH_PRESETSTOOLTIP = "Click to select a preset"
MH_ADDPRESETSTOOLTIP = "Click to add new preset"
MH_DELETEPRESETTOOLTIP = "Click to delete current preset"
MH_APPLYPRESETTOOLTIP = "Click to apply current preset"
MH_PRESETMODETITLE = "Preset Mode:"
MH_PRESETMODETOOLTIP = "Click to enable preset mode.\nMorphs won't actually apply in this mode, unit's won't be checked."
MH_RESETALLTOOLTIP = "Click to reset all available unit's morphs"
MH_MINIMAPTOGGLETOOLTIP = "Show minimap icon"

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
MH_IDSWAPSTOOLTIP = "Click to enter ID\n|ccf3CE13FTIP:|r Click list or info buttons after for ID"
MH_OLDIDTITLE = "Old ID:"
MH_NEWIDTITLE = "New ID:"
MH_SWAPBUTTONTIP = "Click to swap the old and the new IDs"

MH_MINIMAPTOOLTIP = "MorphHelper\nClick to open options\nRight click and drag to move"

--Wallcraft Presets
MH_WC_PRESETS = {
    {
        Name="Gnomish Motorcycle Gang",
        ID=1,
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
}

--TurtleWoW presets
--Don't have any to add to turtle, but will stage
MH_TW_PRESETS = {

}

--Vanilla Presets, always loaded
MH_DEFAULT_PRESETS = {
    {
        Name="Full Orc Male",
        ID=2,
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
    }
}

MH_TEST = "ERROR"
MH_TESTID = "ERROR"

MH_STARDISABLEDICO = "Interface\\AddOns\\MorphHelper\\Assets\\star2_disabled.tga"
MH_STARICO = "Interface\\AddOns\\MorphHelper\\Assets\\star2.tga"

--drop down menu stuff
MH_Menu=
{
    {
        text = "Open Window",
        tooltipTitle =  "Open Window",
        tooltipText =  "Opens the MorphHelper window",
        func =  function() 
            MH_DisplayList:Show() 
            MH_Dewdrop:Close()
        end,
        value=nil,
        hasArrow=false
    },
    {
        text = "Reset Window",
        tooltipTitle = "Reset Window",
        tooltipText = "Resets the MorphHelper window's position",
        func =  function() MH_DisplayList_ResetPos() MH_Dewdrop:Close() end,
        value=nil,
        hasArrow=false
    },
    {
        text = "Enable Morph Broadcast",
        tooltipTitle = "Enable Morph Broadcast",
        tooltipText = "When morphing it will share with your group",
        checked = function() return MH_Vars.MsgSend  end, 
        func =  function() MH_Vars.MsgSend = not MH_Vars.MsgSend end,
        notCheckable = false,
        value=nil,
        hasArrow=false
    },
    {
        text = "Enable Receiving Morph Broadcasts",
        tooltipTitle = "Enable Receiving Morph Broadcast",
        tooltipText = "Morphs from other party members will apply locally",
        checked = function() return MH_Vars.MsgRecv  end, 
        func =  function() MH_Vars.MsgRecv = not MH_Vars.MsgRecv end,
        notCheckable = false,
        value=nil,
        hasArrow=false
    },
    {
        text = "Presets",
        tooltipTitle =  "Presets",
        tooltipText =  "Apply one of the saved presets...",
        value=2,
        hasArrow=true
    },
    {
        text = "Reset All",
        tooltipTitle = "Reset All",
        tooltipText = "Resets all morphs",
        func =  function() MH_ResetAll() MH_Dewdrop:Close() end,
        value=nil,
        hasArrow=false
    },
    {
        text = "ReloadUI",
        tooltipTitle = "ReloadUI",
        tooltipText = "Resets all morphs, even if soft reset fails.\n\nIf this fails, you'll need to relog.",
        func =  function() MH_ResetAll() MH_Dewdrop:Close() end,
        value=nil,
        hasArrow=false
    }
}

MH_CloseButton = 
{
    text = "Close Menu",
    'textR', 0,
    'textG', 1,
    'textB', 1,
    func =  function() MH_Dewdrop:Close() end,
    'notCheckable', true
}

MH_WI_Examples = 
{
    {
        name = "MorphHelper Example",
        tooltip = "Morphs the player into a murloc\nType /mh for more commands",
        example = "\n/mh morph player 31",
        check = function() return true end,
    },
    {
        name = "MorphHelper Presets",
        tooltip = "Pick a preset",
        example = "",
        value = "MH_Presets",
        check = function() return true end,
    },
}