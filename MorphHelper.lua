--[[
MorphHelper
Tubtubs


TODO:
UI 
-Presets dropdowns
-Disable buttons when no unit is available
Reset window position slash command
Readme

-manual displayID entry [CHECK]
-Tab buttons for categories [CHECK]
-Morph/MorphMount/Reset Buttons [CHECK]
--Apply, Add, Delete [CHECK]
-info button? [CHECK]
-Scrolling list [CHECK]
-Movable [CHECK]
-Tooltips[CHECK]

]]--

-- addon info
MH_NAME		= "MorphHelper";
MH_VERSION		= "1.0";

MH_NAMEVERSION	= MH_NAME.." v"..MH_VERSION;
MH_DISPLAY_LISTS ={}

function MH_VariablesLoaded()
    if (not MH_Vars) then
        MH_Vars = {
            Presets={},
            Favorites = {},
            FavoritesLen = 0;
        };
        MH_TestPresets()
    end
    DEFAULT_CHAT_FRAME:AddMessage(MH_NAMEVERSION .. " loaded.")
    DEFAULT_CHAT_FRAME:AddMessage(format("%s",MH_Vars.FavoritesLen))
    MH_DISPLAY_LISTS = {
        {
            list=MH_CreatureList,
            len=MH_CreatureListLen
        },
        {
            list=MH_RaceList,
            len=MH_RaceListLen
        },
        {
            list=MH_MountList,
            len=MH_MountListLen
        },
        {
            list=MH_Vars.Favorites,
            len=MH_Vars.FavoritesLen
        },
    }
end

function MH_TestPresets()
    --all orc party
    a = {
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
    };

    table.insert(MH_Vars.Presets,a)

    b = {
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

    table.insert(MH_Vars.Presets,b)
    DEFAULT_CHAT_FRAME:AddMessage("Loaded test pre-sets")
end

-- slashcommands
SLASH_MORPHHELPER1 = '/MorphHelper'
SLASH_MORPHHELPER2 = '/Morph'
SLASH_MORPHHELPER3 = '/MH'
MH_OPT1 = "morph"
MH_OPT2 = "morphMount"
MH_OPT3 = "remapDisplayID"
MH_OPT4 = "remapMountDisplayID"
MH_OPT5 = "remapItemDisplayID"
MH_OPT6 = "getUnitDisplay"
MH_OPT7 = "getItemDisplay"
MH_OPT8 = "morphUnitItem"
MH_OPT9 = "show"
MH_SLASHHELP0 = "|cFF00FF00" .. MH_NAME .. ":|r This is the help topic for |cFFFFFF00".. SLASH_MORPHHELPER1 .. " " ..
                    SLASH_MORPHHELPER2  .. SLASH_MORPHHELPER3 .. " .|r\n"
MH_SLASHHELP1 = "|cFFFFFF00 " ..SLASH_MORPHHELPER3.. " " .. MH_OPT1 ..
"|cFF00FF00 unitToken displayID|r - Morphs unit to a displayID.\n"
MH_SLASHHELP2 = "|cFFFFFF00 " ..SLASH_MORPHHELPER3.. " " .. MH_OPT2 ..
"|cFF00FF00 unitToken displayID|r - Morphs unit's mount to a displayID.\n"
MH_SLASHHELP3 = "|cFFFFFF00 " ..SLASH_MORPHHELPER3.. " " .. MH_OPT3 ..
"|cFF00FF00 oldDisplayID displayID|r - Swap a unit displayID for a new one.\n"
MH_SLASHHELP4 = "|cFFFFFF00 " ..SLASH_MORPHHELPER3.. " " .. MH_OPT4 ..
"|cFF00FF00 oldDisplayID displayID|r - Swap a mount displayID.\n"
MH_SLASHHELP5 = "|cFFFFFF00 " ..SLASH_MORPHHELPER3.. " " .. MH_OPT5 ..
"|cFF00FF00 itemID inventoryslot displayID|r - Morphs a itemID at a slot.\n"
MH_SLASHHELP6 = "|cFFFFFF00 " ..SLASH_MORPHHELPER3.. " " .. MH_OPT6 ..
"|cFF00FF00 unitToken|r - Displays a unit's display info in chat.\n"
MH_SLASHHELP7 = "|cFFFFFF00 " ..SLASH_MORPHHELPER3.. " " .. MH_OPT7 ..
"|cFF00FF00 itemID|r - Displays an item's display info in chat.\n"
MH_SLASHHELP8 = "|cFFFFFF00 " ..SLASH_MORPHHELPER3.. " " .. MH_OPT8 ..
"|cFF00FF00 unitToken inventorySlot displayID|r - Morphs a unit's item.\n"

MH_SLASHHELP = MH_SLASHHELP0 .. MH_SLASHHELP1 .. MH_SLASHHELP2 .. MH_SLASHHELP3 .. MH_SLASHHELP4 ..
                 MH_SLASHHELP5 .. MH_SLASHHELP8 .. MH_SLASHHELP6 .. MH_SLASHHELP7
MH_SLASHUNKNOWN = "|cFF00FF00".. MH_NAME .. ":|r unknown command"


local function doCommand(parsed_args)
    l = getn(parsed_args)
    if (l==1) then
        if parsed_args[1]==MH_OPT9 then
            MH_DisplayList:Show();
        else
            DEFAULT_CHAT_FRAME:AddMessage(MH_SLASHUNKNOWN,1,0.3,0.3)
        end
    elseif (l==2) then --info commands
        if parsed_args[1] == MH_OPT6 then 
            displayID, nativeDisplayID, mountDisplayID = UnitDisplayInfo(parsed_args[2])
            DEFAULT_CHAT_FRAME:AddMessage(format("DisplayID: %s nativeDisplayID: %s mountDisplayID: %s",
             displayID, nativeDisplayID, mountDisplayID))
        elseif parsed_args[1] == MH_OPT7 then
            itemDisplayID = GetItemDisplayID(parsed_args[2])
            DEFAULT_CHAT_FRAME:AddMessage(format("ItemID: %s DisplayID: %s",
             parsed_args[2], itemDisplayID))
        else
            DEFAULT_CHAT_FRAME:AddMessage(MH_SLASHUNKNOWN,1,0.3,0.3)
        end
    elseif (l==3) then -- morph commands
        if parsed_args[1] == MH_OPT1 then 
            SetUnitDisplayID(parsed_args[2], tonumber(parsed_args[3]))
        elseif parsed_args[1] == MH_OPT2 then
            SetUnitMountDisplayID(parsed_args[2], tonumber(parsed_args[3]))
        elseif parsed_args[1] == MH_OPT3 then
            RemapDisplayID(tonumber(parsed_args[2]), tonumber(parsed_args[3]))
        elseif parsed_args[1] == MH_OPT4 then
            RemapMountDisplayID(tonumber(parsed_args[2]), tonumber(parsed_args[3]))
        else
            DEFAULT_CHAT_FRAME:AddMessage(MH_SLASHUNKNOWN,1,0.3,0.3)
        end
    elseif (l==4) then -- item morph commands
        if parsed_args[1] == MH_OPT8 then
            SetUnitVisibleItemID(tonumber(parsed_args[2]), tonumber(parsed_args[3]),tonumber(parsed_args[4]))
        elseif parsed_args[1] == MH_OPT5 then 
            RemapVisibleItemID(tonumber(parsed_args[2]), tonumber(parsed_args[3]),tonumber(parsed_args[4]))
        else
            DEFAULT_CHAT_FRAME:AddMessage(MH_SLASHUNKNOWN,1,0.3,0.3)
        end
    else
        DEFAULT_CHAT_FRAME:AddMessage(MH_SLASHUNKNOWN,1,0.3,0.3)
    end
end

local function parseArgs(args)
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
		DEFAULT_CHAT_FRAME:AddMessage(MH_SLASHHELP,1,1,1)
	else
        parseArgs(arg)
	end
end

SlashCmdList['MORPHHELPER'] = TextMenu

-- UI CODE --
MH_NUM_DISPLAYS_SHOWN = 8

MH_CurrentList = 1

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
MH_CurrentPresetIndex= 0

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
                MH_DisplayList_ListFaveButton:SetNormalTexture("Interface\\AddOns\\MorphHelper\\star_disabled.tga")
                MH_DisplayList_ListFaveButton:SetScript("OnEnter",MH_DisplayList_FavoriteDeleteTooltip);
            else
                MH_DisplayList_ListFaveButton:SetNormalTexture("Interface\\AddOns\\MorphHelper\\star.tga")
                MH_DisplayList_ListFaveButton:SetScript("OnEnter",MH_DisplayList_FavoriteTooltip);
            end
			--DeckBuilderFrame_DeckButtonText:SetText(format("%s",EmoteButtons_DeckList[index]))
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
    MH_DisplayList_Update()
    MH_DisplayList_UpdateButtons()
end

function MH_DisplayList_UpdateButtons()
    --Morph Buttons if no ID selected
    txtID = MH_DisplayList_IDEditBox:GetText()
    if MH_DisplayList.selectedIcon > 0 or string.len(txtID) > 0 then
        for i=1,MH_UnitTokensLen do
            getglobal(MH_MorphButtons[i]):Enable()
            getglobal(MH_MorphMountButtons[i]):Enable()
        end
    else
        for i=1,MH_UnitTokensLen do
            getglobal(MH_MorphButtons[i]):Disable()
            getglobal(MH_MorphMountButtons[i]):Disable()
        end
    end
    --Preset Buttons
    if MH_CurrentMorphs.Dirty then
        MH_DisplayList_AddPresetButton:Enable()
    else
        MH_DisplayList_AddPresetButton:Disable()
    end
    if MH_CurrentPresetIndex > 0 then
        MH_DisplayList_DeletePresetButton:Enable()
        MH_DisplayList_ApplyPresetButton:Enable()
    else
        MH_DisplayList_DeletePresetButton:Disable()
        MH_DisplayList_ApplyPresetButton:Disable()
    end
end

function MH_DisplayList_OnShow()
    MH_DisplayList.selectedIcon = 0
    MH_DisplayList_Update()
    MH_DisplayList_UpdateButtons()
end

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
    --get getDisplayID
    local displayID = MH_GetDisplayID()
    --get unitToken
    local k = this:GetID();
    local u = MH_UnitTokens[k]
    MH_CurrentMorphs.Morphs[k].ID = displayID
    MH_CurrentMorphs.Dirty=true
    MH_DisplayList_UpdateButtons()
    SetUnitDisplayID(u, displayID)
end

function MH_DisplayList_MorphMount_OnClick()
    --get getDisplayID
    local displayID = MH_GetDisplayID()
    --get unitToken
    local k = this:GetID();
    local u = MH_UnitTokens[k]
    MH_CurrentMorphs.Morphs[k].MID = displayID
    MH_CurrentMorphs.Dirty=true
    MH_DisplayList_UpdateButtons()
    SetUnitMountDisplayID(u, displayID)
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
    --get info about that unit, and then use that info?
    --get unitToken
    local k = this:GetID();
    local u = MH_UnitTokens[k]
    MH_CurrentMorphs.Morphs[k].ID = -1
    MH_CurrentDisplaysCheckDirty()
    SetUnitDisplayID(u, 0)
end

function MH_DisplayList_MorphMountReset_OnClick()
    --get info about that unit, and then use that info?
    --get unitToken
    local k = this:GetID();
    local u = MH_UnitTokens[k]
    MH_CurrentMorphs.Morphs[k].MID = -1
    MH_CurrentDisplaysCheckDirty()
    SetUnitMountDisplayID(u, 0)
end

--Scrolls to the displayID in the big list, doesn't scroll to any prefab categories
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

function MH_DisplayList_MorphInfo_OnClick()
    --get info about that unit, and then use that info?
    --get unitToken
    local k = this:GetID()
    local u = MH_UnitTokens[k]
    displayID, nativeDisplayID, mountDisplayID = UnitDisplayInfo(u)
    --Find DisplayID in the big list?
    DEFAULT_CHAT_FRAME:AddMessage(format("Found nativeDisplayID: %s",nativeDisplayID))
    MH_ScrollToDisplayID(displayID)
end

function MH_DisplayList_MountInfo_OnClick()
    --get info about that unit, and then use that info?
    --get unitToken
    local k = this:GetID()
    local u = MH_UnitTokens[k]
    displayID, nativeDisplayID, mountDisplayID = UnitDisplayInfo(u)
    --Find DisplayID in the big list?
    if mountDisplayID == 0  then 
        DEFAULT_CHAT_FRAME:AddMessage(format("Unit isn't mounted, displayID: %s",mountDisplayID))
    else
       MH_ScrollToDisplayID(mountDisplayID)
    end
end

function MH_DisplayList_IDEditBox_OnEnter()
    MH_DisplayList_IDEditBox:ClearFocus()
    MH_DisplayList.selectedIcon = 0
    MH_DisplayList_Update()
    MH_DisplayList_UpdateButtons()
end
--Tooltips
function MH_SetupTooltip(tip)
    local k = this:GetID()
    local u = MH_UnitTokens[k]
    if (UnitExists(u)) then
        name = GetUnitName(u)
        tooltip = format(tip,name)
    else
        tooltip = MH_TOOLTIPNOUNIT
    end
    GameTooltip:SetOwner(this, "ANCHOR_BOTTOMRIGHT");
    GameTooltip:SetText(tooltip);
    GameTooltip:Show()
end

--Category Change
MH_CAT_ALL=1
MH_CAT_RACES=2
MH_CAT_MOUNTS=3
MH_CAT_FAVORITES=4

function MH_DisplayList_FavoriteTooltip()
    GameTooltip:SetOwner(this, "ANCHOR_BOTTOMRIGHT");
    GameTooltip:SetText(format(MH_TOOLTIPFAVORITES,EmoteButtons_ConfigDeck));
    GameTooltip:Show();
end

function MH_DisplayList_FavoriteDeleteTooltip()
    GameTooltip:SetOwner(this, "ANCHOR_BOTTOMRIGHT");
    GameTooltip:SetText(format(MH_TOOLTIPFAVORITESDELETE,EmoteButtons_ConfigDeck));
    GameTooltip:Show();
end

function MH_ChangeCategory()
    cat = this:GetID()
    MH_CurrentList = cat
    MH_DisplayList_DisplayListScrollFrame:SetVerticalScroll(0)
    MH_DisplayList_Update()
    MH_DisplayList_UpdateButtons()
end

local function sort_ids(a,b)
    return a.ID < b.ID
end

function MH_DisplayListFave_OnClick()
    local manualID = MH_DisplayList_IDEditBox:GetText()
    index =  this:GetID() + (FauxScrollFrame_GetOffset(MH_DisplayList_DisplayListScrollFrame));
    displays = MH_DISPLAY_LISTS[MH_CurrentList].list
    temp = {
        ID = displays[index].ID,
        ModelName= displays[index].ModelName,
        TextureVariation1 = displays[index].TextureVariation1;
    }
    found = 0
    for i=1, MH_Vars.FavoritesLen do
        a = MH_Vars.Favorites[i].ID
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

--presets

function MH_PresetDropDown_OnShow()
	for i=1, getn(MH_Vars.Presets) do
		info = {};
		info.text       = MH_Vars.Presets[i].Name;
		info.value      = i;
		--if (MH_Vars.Presets[i].Name == MH_CurrentPreset) then
        if (i == MH_CurrentPresetIndex) then
			info.checked =true;
		else
			info.checked=false;
		end
		info.func =  function()
            PlaySound("igCharacterInfoOpen"); 
            MH_CurrentPresetIndex = this.value
            MH_CurrentPreset = this.text
            MH_DisplayList_UpdateButtons()
			--EmoteButtons_SetProfile(this.value) 
		end
		UIDropDownMenu_AddButton(info);
	end
end

function MH_PresetDropDownButton_OnClick()
    PlaySound("igCharacterInfoOpen");
	ToggleDropDownMenu(1, nil, MH_DisplayList_PresetsButton, MH_DisplayList_PresetsButton, 0, 0);
end

function MH_AddPresetButton_OnClick()
	--prompt for a new name
    local accept = function()
        local editBox=getglobal(this:GetParent():GetName().."EditBox");
        local newPreset = editBox:GetText();
        --decided to let presets have duplicate names. Why not?
        a = {
            Name=newPreset, 
            Morphs = MH_CurrentMorphs.Morphs;
        }
        table.insert(MH_Vars.Presets,a)
        DEFAULT_CHAT_FRAME:AddMessage(format("Preset %s added successfully!",newPreset));
        this:GetParent():Hide();
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
    for i=1, MH_UnitTokensLen do
        u = MH_UnitTokens[i]
        id = MH_Vars.Presets[MH_CurrentPresetIndex].Morphs[i].ID
        mid = MH_Vars.Presets[MH_CurrentPresetIndex].Morphs[i].MID
        if (UnitExists(u)) then
            if id ~= -1 then
                SetUnitDisplayID(u, id)
                DEFAULT_CHAT_FRAME:AddMessage(format("Morphed %s to %s", u, id))
            end
            if mid ~= -1 then
                SetUnitMountDisplayID(u, mid)
                DEFAULT_CHAT_FRAME:AddMessage(format("Morphed %s to %s", u, mid))
            end
        else
            DEFAULT_CHAT_FRAME:AddMessage("Skipped " .. u .. " when applying preset.")
        end
    end
end