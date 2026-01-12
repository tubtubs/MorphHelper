--[[
MorphHelper
Tubtubs


TODO:
UI 
-Tab buttons for categories
-manual displayID entry
-Presets dropdowns
-Disable buttons when no unit is available
Reset window position slash command
Readme


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
    if (l==2) then --info commands
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

--UI CODE--
MH_NUM_DISPLAYS_SHOWN = 8
MH_DISPLAY_LISTS = {
    {
        list=MH_CreatureList,
        len=MH_CreatureListLen
    },
    {
        list=MH_RaceList,
        len=MH_RaceListLen
    }
}
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

function MH_DisplayList_Update()
	local numDisplays = MH_DISPLAY_LISTS[MH_CurrentList].len
    --DEFAULT_CHAT_FRAME:AddMessage(format("%s",numDisplays))
    local displays = MH_DISPLAY_LISTS[MH_CurrentList].list
	--local DeckBuilderFrame_DeckButtonText, DeckBuilderFrame_DeckButton;
	local Offset = FauxScrollFrame_GetOffset(MH_DisplayList_DisplayListScrollFrame);
	local index;
		-- Deck list
	for i=1, MH_NUM_DISPLAYS_SHOWN do
		MH_DisplayList_ListButtonName = getglobal("MH_DisplayList_ListButton"..i.."Name");
        MH_DisplayList_ListButtonID = getglobal("MH_DisplayList_ListButton"..i.."ID");
        MH_DisplayList_ListButtonTexture = getglobal("MH_DisplayList_ListButton"..i.."Texture");
		MH_DisplayList_ListButton = getglobal("MH_DisplayList_ListButton"..i);
		index = (Offset) + i;
		if ( index <= numDisplays) then
			MH_DisplayList_ListButton:Show();
            MH_DisplayList_ListButtonName:SetText(displays[index].ModelName)
            MH_DisplayList_ListButtonID:SetText(displays[index].ID)
            MH_DisplayList_ListButtonTexture:SetText(displays[index].TextureVariation1)
			--DeckBuilderFrame_DeckButtonText:SetText(format("%s",EmoteButtons_DeckList[index]))
		else
			MH_DisplayList_ListButton:Hide();
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
    MH_DisplayList_Update()
    MH_DisplayList_UpdateButtons()
end

function MH_DisplayList_UpdateButtons()
    if MH_DisplayList.selectedIcon > 0 then
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
end

function MH_DisplayList_OnShow()
    MH_DisplayList.selectedIcon = 0
    MH_DisplayList_Update()
    MH_DisplayList_UpdateButtons()
   -- MH_DisplayList_Update()
end

function MH_DisplayList_OnMouseWheel()
    s = FauxScrollFrame_GetOffset(MH_DisplayList_DisplayListScrollFrame)
    if arg1 < 0 then 
        s = s + 2 
    else
        s = s - 2
    end
    local max = MH_DISPLAY_LISTS[MH_CurrentList].len
    if s < 0 then
        s=0
    elseif s > max then
        s=max
    end
    MH_DisplayList_DisplayListScrollFrame:SetVerticalScroll(s*8);
end

function MH_DisplayList_Morph_OnClick()
    --get getDisplayID
    local index = MH_DisplayList.selectedIcon
    local displays = MH_DISPLAY_LISTS[MH_CurrentList].list
    local displayID = displays[index].ID
    --get unitToken
    local k = this:GetID();
    local u = MH_UnitTokens[k]
    SetUnitDisplayID(u, displayID)
end

function MH_DisplayList_MorphMount_OnClick()
    --get getDisplayID
    local index = MH_DisplayList.selectedIcon
    local displays = MH_DISPLAY_LISTS[MH_CurrentList].list
    local displayID = displays[index].ID
    --get unitToken
    local k = this:GetID();
    local u = MH_UnitTokens[k]
    SetUnitMountDisplayID(u, displayID)
end

function MH_DisplayList_MorphReset_OnClick()
    --get info about that unit, and then use that info?
    --get unitToken
    local k = this:GetID();
    local u = MH_UnitTokens[k]
    SetUnitDisplayID(u, 0)
end

function MH_DisplayList_MorphMountReset_OnClick()
    --get info about that unit, and then use that info?
    --get unitToken
    local k = this:GetID();
    local u = MH_UnitTokens[k]
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