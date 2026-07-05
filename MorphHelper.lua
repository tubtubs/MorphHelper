--[[
MorphHelper
By: Tubtubs
Assists in using the morph lua commands provided by Vanilla Helpers.
Slash commands, and morph window avaiable. Type /mh show to display the window  or /mh to learn more.

Requires VanillaHelpers, be sure to install that mod before using this addon.
https://github.com/isfir/VanillaHelpers
Supports WoWInit (https://github.com/tubtubs/wowinit), includes example commands.
Great for setting morphs up on login

TODO:
Investigate Items
]]--
--MorphHelper_Icon = nil
local libIcon = LibStub("LibDBIcon-1.0");
local libData = LibStub("LibDataBroker-1.1");
MH_Dewdrop = AceLibrary("Dewdrop-2.0");
local MH_Presets_Dewdrop = AceLibrary("Dewdrop-2.0");
local mountMorphBuff  = ""
local mountMorphed = false;
local mountDisplayID = 0;
local FPMorphed = false;

MH_DISPLAY_LISTS ={}
MH_CurrentMorphs ={}
--event handler and init

TT_Total = ""
function DeepPrint (e)
    -- if e is a table, we should iterate over its elements
    if type(e) == "table" then
        for k,v in pairs(e) do -- for every element in the table
            --DEFAULT_CHAT_FRAME:AddMessage(k)
            if type (v == "table") then
                TT_Total = TT_Total .. k .. ":"
                DeepPrint(v)       -- recursively repeat the same procedure
            else
                TT_Total = TT_Total .. v .. ":" .. k .. "\n"
            end
        end
    else -- if not, we can just print it
        TT_Total = TT_Total .. e .. "\n"
    end
end


function MH_VariablesLoaded()
    if (event=="PLAYER_TARGET_CHANGED" or event=="PARTY_MEMBERS_CHANGED") then
        if MH_DisplayList:IsShown() then
            MH_DisplayList_UpdateButtons()
        end
    elseif (event=="PLAYER_LOGIN") then -- Variables Loaded
        MH_Init()
    elseif event=="BUFF_ADDED_SELF" then 
        --arg3 is spellID 
        --DEFAULT_CHAT_FRAME:AddMessage(GetSpellRecField(arg3,"effectMechanic"))
        local spellEffectName = GetSpellRecField(arg3,"effectApplyAuraName")
        if spellEffectName[1] == 78 then
            --Morph me...
            local d = MH_CurrentMorphs.Morphs[1].MID 
            if d == -1 then -- manually morph mount to account for bug...
                local spellEffectUnit = GetSpellRecField(arg3,"effectMiscValue")
                C_CreatureInfo.RequestLoadCreatureByID(spellEffectUnit[1])
                local cinfo = C_CreatureInfo.GetCreatureInfoByID(spellEffectUnit[1])
                SetUnitMountDisplayID("player", cinfo.displayID)
            else
                SetUnitMountDisplayID("player", d)
            end
        end
        --test = GetSpellRec(arg3)
        --DeepPrint(test)
        --TT_TestFrame_ScrollFrame_EditBox:SetText(TT_Total)
        --TT_TestFrame:Show()
        --if (mountMorphed and (not MH_CheckBuff(mountMorphBuff)) ) then
            --DEFAULT_CHAT_FRAME:AddMessage("GAIN4")
        --    SetUnitMountDisplayID("player", 0)
        --    mountMorphed = false
        --elseif mountMorphed==false and mountMorphBuff ~= "" and MH_CheckBuff(mountMorphBuff) then
            --DEFAULT_CHAT_FRAME:AddMessage("GAIN5")
        --    SetUnitMountDisplayID("player", mountDisplayID)
        --    mountMorphed = true
        --end
    elseif event=="BUFF_REMOVED_SELF" then
        local spellEffectName = GetSpellRecField(arg3,"effectApplyAuraName")
        if spellEffectName[1] == 78 then
            --deMorph me...
            DEFAULT_CHAT_FRAME:AddMessage("Test")
            SetUnitMountDisplayID("player", 0)
        end
        --test = GetSpellRec(arg3)
        --DeepPrint(test)
        --TT_TestFrame_ScrollFrame_EditBox:SetText(TT_Total)
        --TT_TestFrame:Show()
    elseif event=="BUFF_ADDED_OTHER" then
        --scan party for matching GUIDs
        local token = nil
        for i=1, 4 do
            if GetUnitGUID("party"..i) == arg1 then
                token = "party"..i
            end
        end
        if token ~= nil then --found the player, find their morph...
            DEFAULT_CHAT_FRAME:AddMessage("TEST")
            SetUnitMountDisplayID(token, MH_GetMountMorph(token))
        end
    elseif event=="BUFF_REMOVED_OTHER" then
        --scan party for matching GUIDs
        local token = nil
        for i=1, 4 do
            if GetUnitGUID("party"..i) == arg1 then
                token = "party"..i
            end
        end
        if token ~= nil then --found the player, find their morph...
            DEFAULT_CHAT_FRAME:AddMessage("TEST1")

            local spellEffectName = GetSpellRecField(arg3,"effectApplyAuraName")
            if spellEffectName[1] == 78 then
                --deMorph me...
                SetUnitMountDisplayID(token, 0)
            end
        end
        --local spellEffectName = GetSpellRecField(arg3,"effectApplyAuraName")
        --if spellEffectName[1] == 78 then
            --deMorph me...
        --    DEFAULT_CHAT_FRAME:AddMessage("Test")
        --    SetUnitMountDisplayID("player", 0)
        --end
    elseif (event == "UNIT_FLAGS") then
        if (FPMorphed and not UnitOnTaxi("player")) then 
            SetUnitMountDisplayID("player", 0)
            FPMorphed = false
        elseif (MH_Vars.FPMorph ~= -1 and UnitOnTaxi("player")) then
            SetUnitMountDisplayID("player", MH_Vars.FPMorph)
            FPMorphed = true
        end
    elseif event == "CHAT_MSG_ADDON" then
        if arg4 ~= UnitName("PLAYER") and arg1==MH_AMPREFIX then
            MH_AMHandler(arg2,arg3,arg4)
        end
    end
end

function MH_Init()
    local firstrun = 0
    if (not MH_Vars) then
        MH_Vars = {
            Presets=MH_DEFAULT_PRESETS,
            Favorites = {},
            FavoritesLen = 0,
            FPMorph = -1,
        };
        firstrun = 1
    elseif (not MH_Vars.FPMorph) then
        MH_Vars.FPMorph = -1;
    end
    --initialize display lists
    r = GetRealmName()
    find = 0
    find = string.find(r,"Wallcraft")
    if find==nil then --Standard, or Turtle?
        if (TWMinimapShopFrame~=nil or TWMiniMapBattlefieldFrame~=nil or LFT_Minimap~=nil) then --turtle
            MH_DISPLAY_LISTS = {
                {
                    list=MH_CreatureList_TW,
                    len=MH_CreatureList_TWLen
                },
                {
                    list=MH_RaceList_TW,
                    len=MH_RaceList_TWLen
                },
                {
                    list=MH_MountList_TW,
                    len=MH_MountList_TWLen
                },
                {
                    list=MH_Vars.Favorites,
                    len=MH_Vars.FavoritesLen
                }
            }
            DEFAULT_CHAT_FRAME:AddMessage(MH_S_TWOW)
        else --standard vanilla
            MH_DISPLAY_LISTS = {
                {
                    list=MH_CreatureList_V,
                    len=MH_CreatureList_VLen
                },
                {
                    list=MH_RaceList_V,
                    len=MH_RaceList_VLen
                },
                {
                    list=MH_MountList_V,
                    len=MH_MountList_VLen
                },
                {
                    list=MH_Vars.Favorites,
                    len=MH_Vars.FavoritesLen
                }
            }
            if firstrun == 1 then
                for i,j in pairs(MH_TW_PRESETS) do
                    table.insert(MH_Vars.Presets,j)
                end
            end
            DEFAULT_CHAT_FRAME:AddMessage(MH_S_VWOW)
        end
    else --Wallcraft
        MH_DISPLAY_LISTS = {
            {
                list=MH_CreatureList_WC,
                len=MH_CreatureList_WCLen
            },
            {
                list=MH_RaceList_WC,
                len=MH_RaceList_WCLen
            },
            {
                list=MH_MountList_WC,
                len=MH_MountList_WCLen
            },
            {
                list=MH_Vars.Favorites,
                len=MH_Vars.FavoritesLen
            },
        }
        if firstrun == 1 then
            for i,j in pairs(MH_WC_PRESETS) do
                table.insert(MH_Vars.Presets,j)
            end
        end
        DEFAULT_CHAT_FRAME:AddMessage(MH_S_WC)
    end
    --Initialize WoWInit's list of presets
    if (WI_Vars) then 
        --Example Morph and Presets Menu Stub
        for i,j in pairs(MH_WI_Examples) do
            table.insert(WI_EXAMPLES[1], j)
        end

        --Presets Menu
        MH_UpdateWoWInitPresets()
    end
    --Initialize empty tables
    MH_CurrentMorphs = {
        Dirty=false,
        Morphs = {  
            { --player
                ID = -1,
                MID = -1;
            },
            { --target
                ID = -1,
                MID = -1;
            },
            { --party1
                ID = -1,
                MID = -1;
            },
            { --party2
                ID = -1,
                MID = -1;
            },
            { --party3
                ID = -1,
                MID = -1;
            },
            { --party4
                ID = -1,
                MID = -1;
            },
        }
    }
    if MorphHelper_Icon == nil then
        MorphHelper_Icon = {
            hide = false
        };
    end
    MH_MinimapIconRegister()
    MH_DewdropRegister()
    MH_Presets_DewdropRegister()
    DEFAULT_CHAT_FRAME:AddMessage(MH_NAMEVERSION .. " loaded.")
end

function MH_UpdateWoWInitPresets()
    --Presets Menu Purge
    if (WI_Vars) then
        l = getn(WI_EXAMPLES[2])
        for i=1, l do
            v = l + 1 - i
            j = {}
            j = WI_EXAMPLES[2][v]
            --DEFAULT_CHAT_FRAME:AddMessage(j.name)
            if j.value == "MH_Presets" then
                table.remove(WI_EXAMPLES[2],v)
            end
        end

        --Presets Menu Re-Add
        for i,j in pairs(MH_Vars.Presets) do
            t = {}
            t =         
            {
                name = j.ID .. ". " .. j.Name,
                tooltip = "",
                example = "\n/mh applyPreset " .. j.ID,
                value = "MH_Presets",
                check = function() 
                    return true
                end,
        }
        table.insert(WI_EXAMPLES[2], t)
        end    
    end
end

--Dropdown Menu Code
function MH_PresetsDewDropGen(minimapBtn)

    for i,j in ipairs(MH_Vars.Presets) do
        chk = false

        if minimapBtn then
            if j.ID == MH_AppliedPresetID then
                chk=true;
            end
            MH_Dewdrop:AddLine(
                'text', j.ID .. ". " ..  j.Name,
                'textR', 1,
                'textG', 0.82,
                'textB', 0,
                'func', MH_ApplyPresetID,
                'arg1', j.ID,
                'notCheckable', false,
                'checked', chk
            )
        else
            if j.ID == MH_CurrentPresetID then
                chk=true;
            end
            MH_Dewdrop:AddLine(
                'text', j.ID .. ". " .. j.Name,
                'textR', 1,
                'textG', 0.82,
                'textB', 0,
                'func', MH_SetCurrentPresetID,
                'arg1', j.ID,
                'notCheckable', false,
                'checked', chk
            )
        end
    end

    MH_Dewdrop:AddLine(
        'text' , "Close Menu",
        'textR', 0,
        'textG', 1,
        'textB', 1,
        'func' , function() MH_Dewdrop:Close() end,
        'notCheckable', true
    )
end

function MH_Presets_DewdropRegister()
    MH_Presets_Dewdrop:Register(MH_DisplayList_PresetsButton, --Bound Frame
		'point', function(parent) --Point
			return "TOP", "BOTTOM"
		end,
		'children', function(level, value) --Children
			if level == 1 then
                MH_PresetsDewDropGen(false)
            end
		end,
		'dontHook', true
	)
end

function MH_DewdropRegister()
    if not MorphHelper_Icon.hide then
        MH_Dewdrop:Register(libIcon:GetMinimapButton("MorphHelper icon"), --Bound Frame
            'point', function(parent) --Point
                return "TOP", "BOTTOM"
            end,
            'children', function(level, value) --Children
                if level == 1 then
                    for i,j in ipairs(MH_Menu) do
                            MH_Dewdrop:AddLine(
                                'text', j.text,
                                'tooltipTitle', j.tooltipTitle,
                                'tooltipText', j.tooltipText,  
                                'textR', 1,
                                'textG', 0.82,
                                'textB', 0,
                                'func', j.func,
                                'hasArrow', j.hasArrow,
                                'value', j.value,
                                'notCheckable', true
                            )
                    end

                    --Close button
                    MH_Dewdrop:AddLine(
                        'text' , "Close Menu",
                        'textR', 0,
                        'textG', 1,
                        'textB', 1,
                        'func' , function() MH_Dewdrop:Close() end,
                        'notCheckable', true
                    )
                elseif level == 2 then
                    MH_PresetsDewDropGen(true)
                end
            end,
            'dontHook', true
        )
    end
end

--Minimap Button Setup
function MH_MinimapIconRegister()
    if not MorphHelper_Icon.hide then
        local iconData = libData:NewDataObject("MorphHelper icon data", {
            OnClick = function()
                if MH_Dewdrop:IsOpen() then
                    MH_Dewdrop:Close();
                else
                    MH_Dewdrop:Open(this);
                end
            end,
            OnTooltipShow = function(tooltip)
                tooltip:SetText(MH_NAMEVERSION);
            end,
            icon = "Interface\\Icons\\INV_Wand_02"
        });

        libIcon:Register("MorphHelper icon", iconData, MorphHelper_Icon);
    end
end

-- slashcommands
SLASH_MORPHHELPER1 = '/MorphHelper'
SLASH_MORPHHELPER2 = '/Morph'
SLASH_MORPHHELPER3 = '/MH'
MH_OPT1 = "morph"
MH_OPT2 = "morphMount"
MH_OPT3 = "remap"
MH_OPT4 = "remapMount"
MH_OPT5 = "remapItem"
MH_OPT6 = "getUnit"
MH_OPT7 = "getItem"
MH_OPT8 = "morphUnitItem"
MH_OPT9 = "show"
MH_OPT10 = "resetWindow"
MH_OPT11 = "genderSwap"
MH_OPT12 = "secretCowPowers"
MH_OPT13 = "resetAll"
MH_OPT14 = "applyPreset"
MH_OPT15 = "listPresets"
MH_OPT16 = "FPMorph"
MH_OPT17 = "minimap"

MH_SLASHHELP0 = "|cFF00FF00" .. MH_NAME .. ":|r This is the help topic for |cFFFFFF00".. SLASH_MORPHHELPER1 .. " " ..
                    SLASH_MORPHHELPER2  .." " .. SLASH_MORPHHELPER3 .. ".|r\n"
MH_SLASHHELP9 = "|cFFFFFF00 " ..SLASH_MORPHHELPER3.. " " .. MH_OPT9 ..
"|r - Shows the morph helper window.\n"
MH_SLASHHELP10 = "|cFFFFFF00 " ..SLASH_MORPHHELPER3.. " " .. MH_OPT10 ..
"|r - Resets the morph helper window position (center screen).\n"
MH_SLASHHELP13 = "|cFFFFFF00 " ..SLASH_MORPHHELPER3.. " " .. MH_OPT13 ..
"|r - Resets all morphs, won't undo swaps. ReloadUI if this fails.\n"
MH_SLASHHELP14 = "|cFFFFFF00 " ..SLASH_MORPHHELPER3.. " " .. MH_OPT14 ..
"|cFF00FF00 presetIndex |r - Applies a preset, at specified index.\n"
MH_SLASHHELP15 = "|cFFFFFF00 " ..SLASH_MORPHHELPER3.. " " .. MH_OPT15 ..
"|r - Lists saved presets, and their index.\n"
MH_SLASHHELP16 = "|cFFFFFF00 " ..SLASH_MORPHHELPER3.. " " .. MH_OPT16 ..
"|cFF00FF00 displayID|r - On taxis morph mount to displayID. Set to -1 to disable.\n"
MH_SLASHHELP17 = "|cFFFFFF00 " ..SLASH_MORPHHELPER3.. " " .. MH_OPT17 ..
"|cFF00FF00 {hide/show}|r - Show or hide the minimap button\n"

MH_SLASHHELP99 = [[Mount Morph Helper Functions:]] .. "\n"
MH_SLASHHELP98 = [[|cFFFFFF00 /run MH_MountSpell("SpellName","BuffName",displayID)|r]] .. "\n"
MH_SLASHHELP97 = [[|cFFFFFF00 /run MH_MountItem("ItemName","BuffName",displayID)|r]] .. "\n"

MH_SLASHHELP1 = "|cFFFFFF00 " ..SLASH_MORPHHELPER3.. " " .. MH_OPT1 ..
"|cFF00FF00 unitToken displayID|r - Morphs unit to a displayID.\n"
MH_SLASHHELP2 = "|cFFFFFF00 " ..SLASH_MORPHHELPER3.. " " .. MH_OPT2 ..
"|cFF00FF00 unitToken displayID|r - Morphs unit's mount to a displayID.\n"
MH_SLASHHELP3 = "|cFFFFFF00 " ..SLASH_MORPHHELPER3.. " " .. MH_OPT3 ..
"|cFF00FF00 oldDisplayID displayID|r - Swap a unit displayID for a new one.\n"
MH_SLASHHELP4 = "|cFFFFFF00 " ..SLASH_MORPHHELPER3.. " " .. MH_OPT4 ..
"|cFF00FF00 oldDisplayID displayID|r - Swap a mount displayID.\n"
MH_SLASHHELP5 = "|cFFFFFF00 " ..SLASH_MORPHHELPER3.. " " .. MH_OPT5 ..
"|cFF00FF00 itemID inventoryslot itemID|r - Morphs a itemID at a slot.\n"
MH_SLASHHELP6 = "|cFFFFFF00 " ..SLASH_MORPHHELPER3.. " " .. MH_OPT6 ..
"|cFF00FF00 unitToken|r - Displays a unit's display info in chat.\n"
MH_SLASHHELP7 = "|cFFFFFF00 " ..SLASH_MORPHHELPER3.. " " .. MH_OPT7 ..
"|cFF00FF00 itemID|r - Displays an item's display info in chat.\n"
MH_SLASHHELP8 = "|cFFFFFF00 " ..SLASH_MORPHHELPER3.. " " .. MH_OPT8 ..
"|cFF00FF00 unitToken inventorySlot itemID|r - Morphs a unit's item.\n"

MH_SLASHHELP = MH_SLASHHELP0 .. MH_SLASHHELP9 .. MH_SLASHHELP17 .. MH_SLASHHELP10 .. MH_SLASHHELP13 .. MH_SLASHHELP15 .. MH_SLASHHELP14 .. MH_SLASHHELP1 .. MH_SLASHHELP2 .. MH_SLASHHELP16 .. MH_SLASHHELP3 .. MH_SLASHHELP4 ..
                 MH_SLASHHELP5 .. MH_SLASHHELP8 .. MH_SLASHHELP6 .. MH_SLASHHELP7 .. MH_SLASHHELP99 .. MH_SLASHHELP97 .. MH_SLASHHELP98 
MH_SLASHUNKNOWN = "|cFF00FF00".. MH_NAME .. ":|r unknown command"

function MH_GenderFlipMode()
    p = {
        {49,50}, --human
        {51,52}, --orc
        {53,54}, --dwarf
        {55,56}, --NE
        {57,58}, --UD
        {59,60}, --Tauren
        {1563, 1564}, --gnome  
        {1478,1479}, --troll 
    }
    l_p = getn(p)
    for i=1, l_p do
        RemapDisplayID(p[i][1],p[i][2])
        RemapDisplayID(p[i][2],p[i][1])
    end
    DEFAULT_CHAT_FRAME:AddMessage("Secret gender swap mode engaged!")
end

function MH_SecretCowPowers()
    t_w = 60
    t_m = 59
    p = {
        {49,50}, --human
        {51,52}, --orc
        {53,54}, --dwarf
        {55,56}, --NE
        {57,58}, --UD
        {59,60}, --Tauren
        {1563, 1564}, --gnome  
        {1478,1479}, --troll 
    }
    l_p = getn(p)
    for i=1, l_p do
        RemapDisplayID(p[i][1],t_m)
        RemapDisplayID(p[i][2],t_w)
    end
    DEFAULT_CHAT_FRAME:AddMessage("Secret cow powers engaged!")
end

function MH_ListPresets()
    DEFAULT_CHAT_FRAME:AddMessage(MH_NAME .. " " .. MH_PRESETS .. ":")
    for i,j in pairs(MH_Vars.Presets) do
        DEFAULT_CHAT_FRAME:AddMessage(j.ID .. ". " .. j.Name)
    end

end

function MH_HideMinimap()
    MorphHelper_Icon.hide = true
    libIcon:Hide("MorphHelper icon")
end

function MH_ShowMinimap()
	MorphHelper_Icon.hide = false
	if (libIcon:GetMinimapButton("MorphHelper icon")) then
		libIcon:Show("MorphHelper icon")
	else
        MH_MinimapIconRegister()
        MH_DewdropRegister()
	end
end

local function doCommand(parsed_args)
    l = getn(parsed_args)
    if (l==1) then
        if parsed_args[1]==string.lower(MH_OPT9) then
            MH_DisplayList:Show();
        elseif parsed_args[1]==string.lower(MH_OPT10) then
            MH_DisplayList_ResetPos()
        elseif parsed_args[1]==string.lower(MH_OPT11) then
            MH_GenderFlipMode()
        elseif parsed_args[1]==string.lower(MH_OPT12) then
            MH_SecretCowPowers()
        elseif parsed_args[1]==string.lower(MH_OPT13) then
            MH_ResetAll()
        elseif parsed_args[1]==string.lower(MH_OPT15) then
            MH_ListPresets()
        else
            DEFAULT_CHAT_FRAME:AddMessage(MH_SLASHUNKNOWN,1,0.3,0.3)
        end
    elseif (l==2) then --info commands
        if parsed_args[1] == string.lower(MH_OPT6) then 
            local displayID, nativeDisplayID, mountDisplayID = UnitDisplayInfo(parsed_args[2])
            DEFAULT_CHAT_FRAME:AddMessage(format("DisplayID: %s nativeDisplayID: %s mountDisplayID: %s",
             displayID, nativeDisplayID, mountDisplayID))
        elseif parsed_args[1] == string.lower(MH_OPT7) then
            itemDisplayID = GetItemDisplayID(parsed_args[2])
            DEFAULT_CHAT_FRAME:AddMessage(format("ItemID: %s DisplayID: %s",
             parsed_args[2], itemDisplayID))
        elseif parsed_args[1] == string.lower(MH_OPT16) then
            MH_Vars.FPMorph = tonumber(parsed_args[2])
            if (MH_Vars.FPMorph ~= -1) then
                DEFAULT_CHAT_FRAME:AddMessage(format("Set Flight Path Morph to: %s", MH_Vars.FPMorph))
            else
                DEFAULT_CHAT_FRAME:AddMessage("Disabled Flight Path Morph")
            end
        elseif parsed_args[1] == string.lower(MH_OPT14) then
            MH_ApplyPresetID(tonumber(parsed_args[2]))
        elseif parsed_args[1] == string.lower(MH_OPT17) then
            if parsed_args[2] == string.lower("hide") then
                MH_HideMinimap()
            elseif parsed_args[2] == string.lower("show") then
                MH_ShowMinimap()
            end
        else
            DEFAULT_CHAT_FRAME:AddMessage(MH_SLASHUNKNOWN,1,0.3,0.3)
        end
    elseif (l==3) then -- morph commands
        if parsed_args[1] == string.lower(MH_OPT1) then 
            SetUnitDisplayID(parsed_args[2], tonumber(parsed_args[3]))
        elseif parsed_args[1] == string.lower(MH_OPT2) then
            SetUnitMountDisplayID(parsed_args[2], tonumber(parsed_args[3]))
        elseif parsed_args[1] == string.lower(MH_OPT3) then
            RemapDisplayID(tonumber(parsed_args[2]), tonumber(parsed_args[3]))
        elseif parsed_args[1] == string.lower(MH_OPT4) then
            RemapMountDisplayID(tonumber(parsed_args[2]), tonumber(parsed_args[3]))
        else
            DEFAULT_CHAT_FRAME:AddMessage(MH_SLASHUNKNOWN,1,0.3,0.3)
        end
    elseif (l==4) then -- item morph commands
        if parsed_args[1] == string.lower(MH_OPT8) then
            SetUnitVisibleItemID(parsed_args[2], tonumber(parsed_args[3]),tonumber(parsed_args[4]))
        elseif parsed_args[1] == string.lower(MH_OPT5) then 
            RemapVisibleItemID(tonumber(parsed_args[2]), tonumber(parsed_args[3]),tonumber(parsed_args[4]))
        else
            DEFAULT_CHAT_FRAME:AddMessage(MH_SLASHUNKNOWN,1,0.3,0.3)
        end
    else
        DEFAULT_CHAT_FRAME:AddMessage(MH_SLASHUNKNOWN,1,0.3,0.3)
    end
end

local function parseArgs(args)
    args = string.lower(args) --decided to make args case insensitive
    a = string.gfind(args, '%S+')
    parsed_args = {}
    for i in a do
        table.insert(parsed_args,i)
    end
    l = getn(parsed_args)
    if (l > 0) then 
        doCommand(parsed_args)
    else
        DEFAULT_CHAT_FRAME:AddMessage(MH_SLASHUNKNOWN,1,0.3,0.3)
    end
end

-- chat inputs
local function TextMenu(arg)
	if arg == nil or arg == "" then
        for w in string.gfind(MH_SLASHHELP, "([^\r\n]+)") do
            DEFAULT_CHAT_FRAME:AddMessage(w,1,1,1)
        end
	else
        parseArgs(arg)
	end
end

SlashCmdList['MORPHHELPER'] = TextMenu

-- Mounting Morph Commands
-- Probably deprecated.
-- Not accessible through slash commands, need to /run them for now.
function MH_CheckBuff(buffName)
    local buff=strlower(buffName);
    local tooltip=MH_Tooltip;
    local textleft1=getglobal(tooltip:GetName().."TextLeft1");
    for i=1, 16 do
        tooltip:SetOwner(UIParent, "ANCHOR_NONE");
        tooltip:SetUnitBuff("player", i);
        b = textleft1:GetText();
        tooltip:Hide();
        if ( b and strfind(strlower(b), buff) ) then
            return true
        elseif ( b==nil ) then
            return false
        end
    end
end

function MH_Timer_OnUpdate()
    local t=this.events;
	if ( getn(t)==0 ) then
		MH_Timer:Hide();
	end
	for k,v in t do
		if ( k~='n' and k<=GetTime() ) then
			v.cmd()
            t[k]=nil;
            t.n=t.n-1;
		end
	end
end

function MH_MountCallBack(buffName, displayID)
    if MH_CheckBuff(buffName) then --if the cast succeeded
        SetUnitMountDisplayID("player", displayID)
        mountMorphed = true
        mountMorphBuff = buffName
    end
end

function MH_MountSpell(spellName, buffName, displayID)   
    CastSpellByName(spellName)
    mountDisplayID = displayID
    mountMorphBuff = buffName
    if not MH_CheckBuff(buffName)  then
        --wait, check buff again, then morph
        local t=MH_Timer.events;
        s=GetTime()+3.2;
        t[s]={};
        t[s].cmd=function() MH_MountCallBack(buffName, displayID) end;
        t[s].sec=seconds;
        t[s].rep="";
        t.n=t.n+1;
        MH_Timer:Show();
    end
end

function MH_MountItem(itemName, buffName, displayID)
    local f_slot = -1
    local f_bag = -1
    for slot=0, 4 do
		for index=1, GetContainerNumSlots(slot) do
			if(GetContainerItemLink(slot, index)) then
				local _, _, itemID = string.find(GetContainerItemLink(slot,index), "item:(%d+):%d+:%d+:%d+")
                local name, _, _, _, _, _, _, _, _, _, _ = GetItemInfo(itemID)
                if itemName == name then
                    f_slot = index
                    f_bag = slot
                    break
                end
            end
        end
    end

    if f_bag ~= -1 and f_slot ~= -1 then
        UseContainerItem(f_bag, f_slot)
        mountDisplayID = displayID
        mountMorphBuff = buffName
        --if not MH_CheckBuff(buffName) then
            --wait, check buff again, then morph
           	--local t=MH_Timer.events;
            --s=GetTime()+3.2;
            --t[s]={};
            --t[s].cmd=function() MH_MountCallBack(buffName, displayID) end;
            --t[s].sec=seconds;
            --t[s].rep="";
            --t.n=t.n+1;
            --MH_Timer:Show();
        --end
    else
        DEFAULT_CHAT_FRAME:AddMessage("Mount item not found.")
    end
end

-- UI CODE --
MH_NUM_DISPLAYS_SHOWN = 8

MH_CurrentList = 1
MH_OLDIDFOCUS = false
MH_NEWIDFOCUS = false
MH_PRESETMODE = false

MH_MorphButtons = {
    "MH_DisplayList_MorphPlayer",
    "MH_DisplayList_MorphTarget",
    "MH_DisplayList_MorphParty1",
    "MH_DisplayList_MorphParty2",
    "MH_DisplayList_MorphParty3",
    "MH_DisplayList_MorphParty4"
}

MH_MorphMountButtons = {
    "MH_DisplayList_MorphMountPlayer",
    "MH_DisplayList_MorphMountTarget",
    "MH_DisplayList_MorphMountParty1",
    "MH_DisplayList_MorphMountParty2",
    "MH_DisplayList_MorphMountParty3",
    "MH_DisplayList_MorphMountParty4"
}

MH_MorphResetButtons = {
    "MH_DisplayList_MorphResetPlayer",
    "MH_DisplayList_MorphResetTarget",
    "MH_DisplayList_MorphResetParty1",
    "MH_DisplayList_MorphResetParty2",
    "MH_DisplayList_MorphResetParty3",
    "MH_DisplayList_MorphResetParty4"
}

MH_MorphMountResetButtons = {
    "MH_DisplayList_MorphMountResetPlayer",
    "MH_DisplayList_MorphMountResetTarget",
    "MH_DisplayList_MorphMountResetParty1",
    "MH_DisplayList_MorphMountResetParty2",
    "MH_DisplayList_MorphMountResetParty3",
    "MH_DisplayList_MorphMountResetParty4"
}

MH_MorphInfoButtons = {
    "MH_DisplayList_MorphInfoPlayer",
    "MH_DisplayList_MorphInfoTarget",
    "MH_DisplayList_MorphInfoParty1",
    "MH_DisplayList_MorphInfoParty2",
    "MH_DisplayList_MorphInfoParty3",
    "MH_DisplayList_MorphInfoParty4"
}

MH_MountInfoButtons = {
    "MH_DisplayList_MountInfoPlayer",
    "MH_DisplayList_MountInfoTarget",
    "MH_DisplayList_MountInfoParty1",
    "MH_DisplayList_MountInfoParty2",
    "MH_DisplayList_MountInfoParty3",
    "MH_DisplayList_MountInfoParty4"
}

MH_UnitTokens = {
    "player",
    "target",
    "party1",
    "party2",
    "party3",
    "party4"
}

MH_UnitTokensLen = getn(MH_UnitTokens)

MH_CurrentPreset = ""
MH_AppliedPreset = ""
MH_AppliedPresetIndex = 0
MH_CurrentPresetIndex = 0

MH_AppliedPresetID = 0
MH_CurrentPresetID = 0 

--Utility Functions

function MH_GetMountMorph(token)
    for k, v in pairs(MH_UnitTokens) do
        if token == v then
            return MH_CurrentMorphs.Morphs[k].MID
        end
    end
end

function MH_ResetAll()
    for i=1,MH_UnitTokensLen do
        u = MH_UnitTokens[i]
        MH_CurrentMorphs.Morphs[i].ID = -1
        MH_CurrentMorphs.Morphs[i].MID = -1
        if MH_DisplayList:IsShown() then
            getglobal(MH_MorphButtons[i]):SetChecked(0)
            getglobal(MH_MorphMountButtons[i]):SetChecked(0)
        end
        if (UnitExists(u) and not MH_PRESETMODE) then
            SetUnitDisplayID(u, 13) 
            SetUnitDisplayID(u, 0)
            SetUnitMountDisplayID(u, 0)
        end
    end
    MH_CurrentMorphs.Dirty = false
    if (MH_DisplayList:IsShown()) then
        MH_DisplayList_UpdateButtons()
    end
end

function MH_SetCurrentPresetID(PresetID)
    MH_CurrentPresetID = PresetID
    MH_Presets_Dewdrop:Close()
    MH_DisplayList_UpdateButtons()
end


function MH_ApplyPresetID(PresetID)
    found = -1
    for i=1, getn(MH_Vars.Presets) do
        if MH_Vars.Presets[i].ID == PresetID then
            found = i
        end
    end
    if found ~= -1 then
        --MH_CurrentPresetIndex = found
        MH_CurrentPreset = MH_Vars.Presets[found].Name
        --MH_AppliedPresetID = MH_Vars.Presets[found].ID
        MH_CurrentPresetID = MH_Vars.Presets[found].ID
        MH_ApplyPresetButton_OnClick()
    else
        DEFAULT_CHAT_FRAME:AddMessage(format("PresetID: %s not found.", PresetID))
    end
    MH_Dewdrop:Close()
end

--DisplayList Functions
function MH_DisplayList_ResetPos()
    MH_DisplayList:ClearAllPoints()
    MH_DisplayList:SetPoint("CENTER", UIParent ,"CENTER", 0, 0)
end

function MH_DisplayList_Update()
	local numDisplays = MH_DISPLAY_LISTS[MH_CurrentList].len
    --DEFAULT_CHAT_FRAME:AddMessage(format("%s",numDisplays))
    local displays = MH_DISPLAY_LISTS[MH_CurrentList].list
	--local DeckBuilderFrame_DeckButtonText, DeckBuilderFrame_DeckButton;
	local Offset = FauxScrollFrame_GetOffset(MH_DisplayList_DisplayListScrollFrame);
	local index;
	for i=1, MH_NUM_DISPLAYS_SHOWN do
		MH_DisplayList_ListFaveButton = getglobal("MH_DisplayList_ListFaveButton"..i.."");
		MH_DisplayList_ListButtonName = getglobal("MH_DisplayList_ListButton"..i.."Name");
        MH_DisplayList_ListButtonID = getglobal("MH_DisplayList_ListButton"..i.."ID");
        MH_DisplayList_ListButtonTexture = getglobal("MH_DisplayList_ListButton"..i.."Texture");
		MH_DisplayList_ListButton = getglobal("MH_DisplayList_ListButton"..i);
		index = (Offset) + i;
		if ( index <= numDisplays) then
			MH_DisplayList_ListButton:Show();
            MH_DisplayList_ListFaveButton:Show();
            MH_DisplayList_ListButtonName:SetText(displays[index].ModelName)
            MH_DisplayList_ListButtonID:SetText(displays[index].ID)
            MH_DisplayList_ListButtonTexture:SetText(displays[index].TextureVariation1)
            found = 0
            for i=1, MH_Vars.FavoritesLen do
                a = MH_Vars.Favorites[i].ID
                if a == displays[index].ID then
                    found = i
                    break
                end
            end
            if found ~= 0 then
                MH_DisplayList_ListFaveButton:SetNormalTexture(MH_STARDISABLEDICO)
                MH_DisplayList_ListFaveButton:SetScript("OnEnter",MH_DisplayList_FavoriteDeleteTooltip);
            else
                MH_DisplayList_ListFaveButton:SetNormalTexture(MH_STARICO)
                MH_DisplayList_ListFaveButton:SetScript("OnEnter",MH_DisplayList_FavoriteTooltip);
            end
		else
			MH_DisplayList_ListButton:Hide();
            MH_DisplayList_ListFaveButton:Hide();
		end
		if ( index == MH_DisplayList.selectedIcon  ) then
			MH_DisplayList_ListButton:SetChecked(1);
		else
			MH_DisplayList_ListButton:SetChecked(nil);
		end
	end
	
	-- Scrollbar stuff
	FauxScrollFrame_Update(MH_DisplayList_DisplayListScrollFrame, numDisplays , MH_NUM_DISPLAYS_SHOWN, MH_NUM_DISPLAYS_SHOWN);
end

function MH_DisplayList_OnClick()
	MH_DisplayList.selectedIcon =  this:GetID() + (FauxScrollFrame_GetOffset(MH_DisplayList_DisplayListScrollFrame));
    MH_DisplayList_IDEditBox:SetText("")
    if (MH_NEWIDFOCUS) then 
        index = MH_DisplayList.selectedIcon
        displays = MH_DISPLAY_LISTS[MH_CurrentList].list
        MH_DisplayList_SwapFrame_NewIDEditBox:SetText(displays[index].ID)
        MH_DisplayList_SwapFrame_NewIDEditBox:ClearFocus()
        MH_NEWIDFOCUS = false
    elseif (MH_OLDIDFOCUS) then
        index = MH_DisplayList.selectedIcon
        displays = MH_DISPLAY_LISTS[MH_CurrentList].list
        MH_DisplayList_SwapFrame_OldIDEditBox:SetText(displays[index].ID)
        MH_DisplayList_SwapFrame_OldIDEditBox:ClearFocus()
        MH_OLDIDFOCUS = false
    end

    MH_DisplayList_Update()
    MH_DisplayList_UpdateButtons()
end

function MH_DisplayList_UpdateButtons()
    --Morph Buttons if no ID selected
    txtID = MH_DisplayList_IDEditBox:GetText()
    for i=1,MH_UnitTokensLen do
        u = MH_UnitTokens[i]
        if (UnitExists(u) or MH_PRESETMODE) then --hides invalid units, or shows if preset mode
            --disable morph buttons if no displayID is selected
            if MH_DisplayList.selectedIcon > 0 or string.len(txtID) > 0 then
                getglobal(MH_MorphButtons[i]):Enable()
                getglobal(MH_MorphMountButtons[i]):Enable()
            else
                getglobal(MH_MorphButtons[i]):Disable()
                getglobal(MH_MorphMountButtons[i]):Disable()
            end
            getglobal(MH_MorphResetButtons[i]):Enable()
            getglobal(MH_MorphMountResetButtons[i]):Enable()
            getglobal(MH_MorphInfoButtons[i]):Enable()
            getglobal(MH_MountInfoButtons[i]):Enable()
        else
            getglobal(MH_MorphButtons[i]):Disable()
            getglobal(MH_MorphMountButtons[i]):Disable()
            getglobal(MH_MorphResetButtons[i]):Disable()
            getglobal(MH_MorphMountResetButtons[i]):Disable()
            getglobal(MH_MorphInfoButtons[i]):Disable()
            getglobal(MH_MountInfoButtons[i]):Disable()
        end
    end
    --Preset Buttons
    if MH_CurrentMorphs.Dirty then --only offer to save if there's changes
        MH_DisplayList_AddPresetButton:Enable()
    else
        MH_DisplayList_AddPresetButton:Disable()
    end
    if MH_CurrentPresetIndex > 0 then -- only offer to apply or delete if a preset is selected
        MH_DisplayList_DeletePresetButton:Enable()
        MH_DisplayList_ApplyPresetButton:Enable()
    else
        MH_DisplayList_DeletePresetButton:Disable()
        MH_DisplayList_ApplyPresetButton:Disable()
    end
    --Swap Buttons
    txtID = MH_DisplayList_SwapFrame_NewIDEditBox:GetText()
    txtOID = MH_DisplayList_SwapFrame_OldIDEditBox:GetText()
    --only enable swap buttons if both displayID fields are filled

    if (string.len(txtID) > 0 and string.len(txtOID) > 0) then
        MH_DisplayList_IDSwapsButton:Enable()
        MH_DisplayList_MountIDSwapsButton:Enable()
    else
        MH_DisplayList_IDSwapsButton:Disable()
        MH_DisplayList_MountIDSwapsButton:Disable()
        MH_DisplayList_SwapFrame_SwapIDsButton:Disable()
    end
    if (string.len(txtID) > 0 or string.len(txtOID) > 0) then
        MH_DisplayList_SwapFrame_SwapIDsButton:Enable()
    end
end

function MH_DisplayList_OnShow()
    MH_DisplayList.selectedIcon = 0
    if (MH_PRESETMODE) then
        MH_DisplayList_PresetModeCheckButton:SetChecked(1)
    else
        MH_DisplayList_PresetModeCheckButton:SetChecked(0)
    end
    MH_DisplayList_Update()
    MH_DisplayList_UpdateButtons()
    if MorphHelper_Icon.hide then
        MH_DisplayList_MinimapToggleButton:SetChecked(0)
    else
        MH_DisplayList_MinimapToggleButton:SetChecked(1)
    end
end

function MH_DisplayList_MinimapToggleButton_OnClick()
    if MorphHelper_Icon.hide then
        MH_ShowMinimap()
    else
        MH_HideMinimap()
    end
end

--DisplayID List Scrolling Functions
function MH_DisplayList_OnMouseWheel()
    s = FauxScrollFrame_GetOffset(MH_DisplayList_DisplayListScrollFrame)
    if arg1 < 0 then 
        s = s + 2 
    else
        s = s - 2
    end
    local max = MH_DISPLAY_LISTS[MH_CurrentList].len-MH_NUM_DISPLAYS_SHOWN
    if(max < 0) then
        max = 0
    end
    if s < 0 then
        s=0
    elseif s > max then
        s=max
    end
    MH_DisplayList_DisplayListScrollFrame:SetVerticalScroll(s*8);
end

--Scrolls to the displayID in the big list, only scrolls through All folder
function MH_ScrollToDisplayID(displayID)
    found=0
    for i=1, MH_DISPLAY_LISTS[1].len do
        a = ((MH_DISPLAY_LISTS[1].list)[i]).ID
        if (a==displayID) then
            found = i
            break
        end
    end
    if found == 0 then
        DEFAULT_CHAT_FRAME:AddMessage(format("Couldn't find displayID: %s",displayID))
    else
        MH_CurrentList = 1
        DEFAULT_CHAT_FRAME:AddMessage(format("Found displayID: %s",displayID))
        MH_DisplayList_DisplayListScrollFrame:SetVerticalScroll((floor((found-1)*8)))
        MH_DisplayList_Update()
    end
end

--UI Morph functions
function MH_GetDisplayID()
    local manualID = MH_DisplayList_IDEditBox:GetText()
    if manualID ~= nil and string.len(manualID) > 0 then
        return tonumber(manualID)
    else
        index = MH_DisplayList.selectedIcon
        displays = MH_DISPLAY_LISTS[MH_CurrentList].list
        return displays[index].ID
    end
end

function MH_DisplayList_Morph_OnClick()
    this:SetChecked(1)
    --get getDisplayID
    local displayID = MH_GetDisplayID()
    --get unitToken
    local k = this:GetID();
    local u = MH_UnitTokens[k]
    MH_CurrentMorphs.Morphs[k].ID = displayID
    MH_CurrentMorphs.Dirty=true
    MH_DisplayList_UpdateButtons()
    if (not MH_PRESETMODE) then
        MH_AMSendMorph(u,MH_AMMORPHPLAYER, displayID)
        SetUnitDisplayID(u, displayID)  
    end
end

function MH_DisplayList_MorphMount_OnClick()
    this:SetChecked(1)
    --get getDisplayID
    local displayID = MH_GetDisplayID()
    --get unitToken
    local k = this:GetID();
    local u = MH_UnitTokens[k]
    MH_CurrentMorphs.Morphs[k].MID = displayID
    MH_CurrentMorphs.Dirty=true
    MH_DisplayList_UpdateButtons()
    if (not MH_PRESETMODE) then
        MH_AMSendMorph(u,MH_AMMORPHMOUNT, displayID)
        SetUnitMountDisplayID(u, displayID)
    end
end

function MH_CurrentDisplaysCheckDirty()
    found = 0
    for i=1, MH_UnitTokensLen do
        id = MH_CurrentMorphs.Morphs[i].ID
        mid = MH_CurrentMorphs.Morphs[i].MID
        if id > -1 or mid > -1 then
            found = i 
            break
        end
    end

    if found == 0 then
        MH_CurrentMorphs.Dirty = false
    end
    MH_DisplayList_UpdateButtons()
end

function MH_DisplayList_MorphReset_OnClick()
    --get unitToken
    local k = this:GetID();
    local u = MH_UnitTokens[k]
    MH_CurrentMorphs.Morphs[k].ID = -1
    MH_CurrentDisplaysCheckDirty()
    getglobal(MH_MorphButtons[k]):SetChecked(0)
    --Morphing to a creature after another race makes resetting possible
    --Resets native displayID or something
    if not MH_PRESETMODE then
        MH_AMSendMorph(u,MH_AMMORPHPLAYER, -1)
        SetUnitDisplayID(u, 13) 
        SetUnitDisplayID(u, 0)
    end
end

function MH_DisplayList_MorphMountReset_OnClick()
    --get unitToken
    local k = this:GetID();
    local u = MH_UnitTokens[k]
    MH_CurrentMorphs.Morphs[k].MID = -1
    MH_CurrentDisplaysCheckDirty()
    getglobal(MH_MorphMountButtons[k]):SetChecked(0)
    if not MH_PRESETMODE then
        MH_AMSendMorph(u,MH_AMMORPHMOUNT, -1)
        SetUnitMountDisplayID(u, 0)
    end
end

function MH_DisplayList_MorphInfo_OnClick()
    --get info about that unit, and then use that info
    --get unitToken
    local k = this:GetID()
    local u = MH_UnitTokens[k]
    local displayID, _, _ = UnitDisplayInfo(u)
    --Find DisplayID in the big list
    if (MH_NEWIDFOCUS) then 
        MH_DisplayList_SwapFrame_NewIDEditBox:SetText(displayID)
        MH_DisplayList_SwapFrame_NewIDEditBox:ClearFocus()
        MH_NEWIDFOCUS = false
        MH_DisplayList_UpdateButtons()
    elseif (MH_OLDIDFOCUS) then
        MH_DisplayList_SwapFrame_OldIDEditBox:SetText(displayID)
        MH_DisplayList_SwapFrame_OldIDEditBox:ClearFocus()
        MH_OLDIDFOCUS = false
        MH_DisplayList_UpdateButtons()
    end
    MH_ScrollToDisplayID(displayID)
end

function MH_DisplayList_MountInfo_OnClick()
    --get info about that unit, and then use that info
    --get unitToken
    local k = this:GetID()
    local u = MH_UnitTokens[k]
    local _, _, mountDisplayID = UnitDisplayInfo(u)
    --Find DisplayID in the big list
    if mountDisplayID == 0  then 
        DEFAULT_CHAT_FRAME:AddMessage(format("Unit isn't mounted"))
    else
       MH_ScrollToDisplayID(mountDisplayID)
        if (MH_NEWIDFOCUS) then 
            MH_DisplayList_SwapFrame_NewIDEditBox:SetText(mountDisplayID)
            MH_DisplayList_SwapFrame_NewIDEditBox:ClearFocus()
            MH_NEWIDFOCUS = false
            MH_DisplayList_UpdateButtons()
        elseif (MH_OLDIDFOCUS) then
            MH_DisplayList_SwapFrame_OldIDEditBox:SetText(mountDisplayID)
            MH_DisplayList_SwapFrame_OldIDEditBox:ClearFocus()
            MH_OLDIDFOCUS = false
            MH_DisplayList_UpdateButtons()
        end
    end
end

--Morph Button Tooltips
function MH_SetupTooltip(tip)
    local k = this:GetID()
    local u = MH_UnitTokens[k]
    if (MH_PRESETMODE) then
        name = GetUnitName(u)
        tooltip = format(tip,u)
    elseif (UnitExists(u)) then
        name = GetUnitName(u)
        tooltip = format(tip,name)
    else
        tooltip = MH_TOOLTIPNOUNIT
    end
    GameTooltip:SetOwner(this, "ANCHOR_BOTTOMRIGHT");
    GameTooltip:SetText(tooltip);
    GameTooltip:Show()
end

function MH_DisplayList_IDEditBox_OnEnter()
    MH_DisplayList_IDEditBox:ClearFocus()
    MH_DisplayList.selectedIcon = 0
    MH_DisplayList_Update()
    MH_DisplayList_UpdateButtons()
end

--favorites buttons
local function sort_ids(a,b)
    return a.ID < b.ID
end

function MH_DisplayListFave_OnClick()
    local manualID = MH_DisplayList_IDEditBox:GetText()
    local index =  this:GetID() + (FauxScrollFrame_GetOffset(MH_DisplayList_DisplayListScrollFrame));
    local displays = MH_DISPLAY_LISTS[MH_CurrentList].list
    local temp = {
        ID = displays[index].ID,
        ModelName= displays[index].ModelName,
        TextureVariation1 = displays[index].TextureVariation1;
    }
    local found = 0
    for i=1, MH_Vars.FavoritesLen do
        local a = MH_Vars.Favorites[i].ID
        if a == displays[index].ID then
            found = i
            break
        end
    end
    if found == 0 then
        table.insert(MH_Vars.Favorites,temp)
        table.sort(MH_Vars.Favorites,sort_ids)
        MH_Vars.FavoritesLen = MH_Vars.FavoritesLen + 1;
        MH_DISPLAY_LISTS[4].len = MH_DISPLAY_LISTS[4].len+1
        MH_DisplayList_Update()
    else
        table.remove(MH_Vars.Favorites, found)
        MH_Vars.FavoritesLen = MH_Vars.FavoritesLen - 1;
        MH_DISPLAY_LISTS[4].len = MH_DISPLAY_LISTS[4].len-1
        MH_DisplayList_Update()
    end

end

function MH_DisplayList_FavoriteTooltip()
    GameTooltip:SetOwner(this, "ANCHOR_BOTTOMRIGHT");
    GameTooltip:SetText(MH_TOOLTIPFAVORITES);
    GameTooltip:Show();
end

function MH_DisplayList_FavoriteDeleteTooltip()
    GameTooltip:SetOwner(this, "ANCHOR_BOTTOMRIGHT");
    GameTooltip:SetText(MH_TOOLTIPFAVORITESDELETE);
    GameTooltip:Show();
end

--Category Change
function MH_ChangeCategory()
    local cat = this:GetID()
    MH_CurrentList = cat
    MH_DisplayList.selectedIcon  = 0
    MH_DisplayList_DisplayListScrollFrame:SetVerticalScroll(0)
    MH_DisplayList_Update()
    MH_DisplayList_UpdateButtons()
end

--presets

function MH_PresetDropDownButton_OnClick()
    PlaySound("igCharacterInfoOpen");
    if MH_Dewdrop:IsOpen() then
        MH_Dewdrop:Close();
    else
        MH_Dewdrop:Open(this);
    end
end

function MH_AddPresetButton_OnClick()
	--prompt for a new name
    local accept = function()
        local editBox=getglobal(this:GetParent():GetName().."EditBox");
        local newPreset = editBox:GetText();
        --decided to let presets have duplicate names. Why not?
        --Need to duplicate the morphs table.
        local b = {}
        local c = {}
        for i=1, MH_UnitTokensLen do
            c = {ID=MH_CurrentMorphs.Morphs[i].ID, MID=MH_CurrentMorphs.Morphs[i].MID}
            table.insert(b,c)
        end
        if getn(MH_Vars.Presets) > 0 then
            tid = MH_Vars.Presets[getn(MH_Vars.Presets)].ID + 1
        else
            tid = 1
        end
        local a = {
            Name=newPreset, 
            ID = tid,
            Morphs = b
        }
        table.insert(MH_Vars.Presets,a)
        DEFAULT_CHAT_FRAME:AddMessage(format("Preset %s added successfully!",newPreset));
        this:GetParent():Hide();
        MH_UpdateWoWInitPresets()
    end
	StaticPopupDialogs["MH_ADDPRESET_DIALOG"]={
		text=TEXT(MH_NEWPRESET),
		button1=TEXT(ACCEPT),
		button2=TEXT(CANCEL),
		hasEditBox=1,
		maxLetters=32,
		OnAccept=accept,
		EditBoxOnEnterPressed=accept,
		EditBoxOnEscapePressed=function()
			this:GetParent():Hide();
		end,
		timeout=0,
		exclusive=1
	};
	StaticPopup_Show("MH_ADDPRESET_DIALOG");
	getglobal(getglobal(StaticPopup_Visible("MH_ADDPRESET_DIALOG")):GetName().."EditBox"):SetText("");
end

function MH_DisplayList_ApplyPresetButton_Tooltip()
    GameTooltip:SetOwner(this, "ANCHOR_BOTTOMRIGHT");
    --generate display info for current morphs
    local tooltip = MH_APPLYPRESETTOOLTIP .. "\nPreset Morphs:\n"
    local id = -1
    local mid = -1
    for i=1, MH_UnitTokensLen do
        id = MH_Vars.Presets[MH_CurrentPresetIndex].Morphs[i].ID
        mid = MH_Vars.Presets[MH_CurrentPresetIndex].Morphs[i].MID
        if id ~= -1 then
            tooltip = tooltip ..  MH_UnitTokens[i] .. " ID: " .. id .. "\n"
        end
        if mid ~= -1 then
            tooltip = tooltip ..  MH_UnitTokens[i] .. " MID: " .. mid .. "\n"
        end
    end
    GameTooltip:SetText(tooltip);
    GameTooltip:Show();
end

function MH_DisplayList_AddPresetButton_Tooltip()
    GameTooltip:SetOwner(this, "ANCHOR_BOTTOMRIGHT");
    --generate display info for current morphs
    local tooltip = MH_ADDPRESETSTOOLTIP .. "\nCurrent Morphs:\n"
    local id = -1
    local mid = -1
    for i=1, MH_UnitTokensLen do
        id = MH_CurrentMorphs.Morphs[i].ID
        mid = MH_CurrentMorphs.Morphs[i].MID
        if id ~= -1 then
            tooltip = tooltip ..  MH_UnitTokens[i] .. " ID: " .. id .. "\n"
        end
        if mid ~= -1 then
            tooltip = tooltip ..  MH_UnitTokens[i] .. " MID: " .. mid .. "\n"
        end
    end
    GameTooltip:SetText(tooltip);
    GameTooltip:Show();
end

function MH_DeletePresetButton_OnClick()
    --Confirmation dialog
    StaticPopupDialogs["MH_DELETEPRESET_CONFIRMATION"] = {
	text = "Do you want to delete the preset: " .. MH_CurrentPreset .. "?",
	button1 = "Yes",
	button2 = "No",
	OnAccept = function()
        table.remove(MH_Vars.Presets,MH_CurrentPresetIndex)
        MH_CurrentPresetIndex = 0
        MH_CurrentPreset = ""
        MH_DisplayList_UpdateButtons()
        MH_UpdateWoWInitPresets()
	    --ReloadUI();	
	end,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,  -- avoid some UI taint, see http://www.wowace.com/announcements/how-to-avoid-some-ui-taint/
	}
	StaticPopup_Show("MH_DELETEPRESET_CONFIRMATION")
end

function MH_ApplyPresetButton_OnClick()
    --MH_AppliedPresetIndex = MH_CurrentPresetIndex
    --MH_AppliedPreset = MH_Vars.Presets[MH_CurrentPresetIndex].Name
    found = -1
    for i=1, getn(MH_Vars.Presets) do
        if MH_Vars.Presets[i].ID == MH_CurrentPresetID then
            found = i
        end
    end
    MH_AppliedPresetID = MH_CurrentPresetID
    MH_CurrentPresetIndex = found
    local id = -1
    local mid = -1
    local u = ""
    for i=1, MH_UnitTokensLen do
        u = MH_UnitTokens[i]
        id = MH_Vars.Presets[MH_CurrentPresetIndex].Morphs[i].ID
        mid = MH_Vars.Presets[MH_CurrentPresetIndex].Morphs[i].MID
        if (UnitExists(u) or MH_PRESETMODE) then
            if id ~= -1 then
                if not MH_PRESETMODE then
                    SetUnitDisplayID(u, id)
                    DEFAULT_CHAT_FRAME:AddMessage(format("Morphed %s to %s", u, id))
                end
                MH_CurrentMorphs.Morphs[i].ID = id
                MH_CurrentMorphs.Dirty=true
                getglobal(MH_MorphButtons[i]):SetChecked(1)
            end
            if mid ~= -1 then
                if not MH_PRESETMODE then
                    SetUnitMountDisplayID(u, mid)
                    DEFAULT_CHAT_FRAME:AddMessage(format("Morphed %s's mount to %s", u, mid))
                end
                MH_CurrentMorphs.Morphs[i].MID = mid
                MH_CurrentMorphs.Dirty=true
                getglobal(MH_MorphMountButtons[i]):SetChecked(1)
            end
        end
    end
    if MH_DisplayList:IsShown() then
        MH_DisplayList_UpdateButtons()
    end
end

--Swap Functions

function MH_DisplayList_SwapFrame_NewIDEditBox_OnEnter()
    MH_DisplayList_SwapFrame_NewIDEditBox:ClearFocus()
    MH_NEWIDFOCUS = false
    MH_DisplayList_UpdateButtons()
end

function MH_DisplayList_SwapFrame_OldIDEditBox_OnEnter()
    MH_DisplayList_SwapFrame_OldIDEditBox:ClearFocus()
    MH_OLDIDFOCUS = false
    MH_DisplayList_UpdateButtons()
end

function MH_DisplayList_IDSwapsButton_OnClick()
    local newID = MH_DisplayList_SwapFrame_NewIDEditBox:GetText()
    local oldID = MH_DisplayList_SwapFrame_OldIDEditBox:GetText()
    RemapDisplayID(oldID, newID)
end

function MH_DisplayList_MountIDSwapsButton_OnClick()
    local newID = MH_DisplayList_SwapFrame_NewIDEditBox:GetText()
    local oldID = MH_DisplayList_SwapFrame_OldIDEditBox:GetText()
    RemapMountDisplayID(oldID, newID)
end

function MH_DisplayList_SwapFrame_SwapIDsButton_OnClick()
    local newID = MH_DisplayList_SwapFrame_NewIDEditBox:GetText()
    local oldID = MH_DisplayList_SwapFrame_OldIDEditBox:GetText()

    MH_DisplayList_SwapFrame_NewIDEditBox:SetText(oldID)
    MH_DisplayList_SwapFrame_OldIDEditBox:SetText(newID)

    MH_DisplayList_SwapFrame_NewIDEditBox:ClearFocus()
    MH_DisplayList_SwapFrame_OldIDEditBox:ClearFocus()
end

--AM Protocol: GUID:MOUNT/PLAYER:DISPALYID
--EG: 1:0:2001 -- player morph
--EG: 1:1:2001 -- mount morph
function MH_AMSendMorph(token, m, id)
    local msg = format("%s:%s:%s", GetUnitGUID(token), m, id)
    SendAddonMessage(MH_AMPREFIX, msg, "PARTY")
end

function MH_AMHandler(arg2, arg3, arg4)
    DEFAULT_CHAT_FRAME:AddMessage(arg2)
    local parsed_args = {}
    local a = string.gfind(arg2, '([^:]+)') --parses info after :
    for i in a do --need to translate it to a table, a is a function
        table.insert(parsed_args,i)
        --TubTalents_Out(i)
    end 
    local len = getn(parsed_args)
    if len == 3 then
        --find the unit token...
        local token = nil
        if GetUnitGUID("player") == parsed_args[1] then
            token = "player"
        else
            for i=1, 4 do
                if GetUnitGUID("party"..i) == parsed_args[1] then
                    token = "party"..i
                end
            end
        end
        --store then morph
        if token ~= nil then
            local tindex
            for k, v in pairs(MH_UnitTokens) do
                if token == v then
                    tindex = k
                end
            end
            DEFAULT_CHAT_FRAME:AddMessage(parsed_args[2])
            if tonumber(parsed_args[2]) == MH_AMMORPHPLAYER then
                MH_CurrentMorphs.Morphs[tindex].ID = tonumber(parsed_args[3])
                MH_CurrentMorphs.Dirty=true
                if tonumber(parsed_args[3]) == -1 then
                    SetUnitDisplayID(token, 0)
                else
                    SetUnitDisplayID(token, parsed_args[3])
                end
            elseif tonumber(parsed_args[2]) == MH_AMMORPHMOUNT then
                MH_CurrentMorphs.Morphs[tindex].MID = tonumber(parsed_args[3])
                MH_CurrentMorphs.Dirty=true
                SetUnitMountDisplayID(token, parsed_args[3])
            else
                DEFAULT_CHAT_FRAME:AddMessage("MH: Addon Message failure2")
            end
        end
    else
        DEFAULT_CHAT_FRAME:AddMessage("MH: Addon Message failure")
    end
end