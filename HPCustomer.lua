------------------------------------
-- HPCustomer Beta (3/11/2020)
------------------------------------

-- Create saved global vars
_G.HPCustomerDB = _G.HPCustomerDB or {}

-- Create global vars
_G.HPCustomerGUI = _G.HPCustomerGUI or {}
_G.HPCustomerMain = _G.HPCustomerMain or {}

-- Create local vars
local DB -- assigned during ADDON_LOADED
local Main = _G.HPCustomerMain
local GUI = _G.HPCustomerGUI

-- Hardcoded config vars
Main.MANAGER_NAME = "Hpmanager"
local SUPPORTED_SERVER = "Rattlegore"
local SUPPORTED_FACTION = "Horde"

-- Register for events
local HPCustomerEvent = CreateFrame("FRAME")
HPCustomerEvent:RegisterEvent("ADDON_LOADED")
HPCustomerEvent:RegisterEvent("CHAT_MSG_ADDON")
HPCustomerEvent:RegisterEvent("FRIENDLIST_UPDATE")

-- Main event handler function
local function eventHandler(self, event, arg1, arg2, ...)
  if ((event == "ADDON_LOADED") and (arg1 == "HPCustomer")) then
    if ((GetRealmName() == SUPPORTED_SERVER) and (UnitFactionGroup("player") == SUPPORTED_FACTION)) then
      print("HPCustomer Addon Loading - /hp to open")
      Main:Init()
    else
      HPCustomerEvent:UnregisterEvent("CHAT_MSG_ADDON")
      HPCustomerEvent:UnregisterEvent("FRIENDLIST_UPDATE")
    end
  elseif ((event == "CHAT_MSG_ADDON") and (arg1 == "HPSummons")) then
    local msg, _, sender = arg2, ...
    Main:HandleAddonMessage(msg, sender)
  elseif ((event == "FRIENDLIST_UPDATE") and Main.triggeredFriendListUpdate) then
    Main.triggeredFriendListUpdate = false
    Main:CheckManagerOnline()
  end
end

-- Register event handler
HPCustomerEvent:SetScript("OnEvent", eventHandler)

-- Slash commands
SLASH_HPCUSTOMER1 = "/hpcustomer"
SLASH_HPCUSTOMER2 = "/hp"
SlashCmdList["HPCUSTOMER"] = function(msg)
  Main:UpdateFields()
  GUI:Create()
  GUI:Show()
end

-- Init functions

function Main:Init()
  Main:CopyDBDefaults(_G.HPCustomerDB, _G.HPCustomerDBDefaults)
  DB = _G.HPCustomerDB.Main
  C_ChatInfo.RegisterAddonMessagePrefix("HPSummons")
  GUI:Init()
  Main:AddCharacter()
  Main:LoginSummonRequestCheck()
end

function Main:CopyDBDefaults(db, defaults)
  for k,v in pairs(defaults) do
    if (type(v) == "table") then
      if (type(db[k]) ~= "table") then db[k] = {} end
      HPCustomerMain:CopyDBDefaults(db[k], v)
    elseif (type(v) ~= type(db[k])) then
      db[k] = v
    end
  end
end

function Main:AddCharacter()
  local chars = DB.characterList
  local playerName = UnitName("player")
  local matched = false
  for i=1,#chars do
    if (chars[i] == playerName) then
      matched = true
      break
    end
  end
  if (not matched) then
    table.insert(chars, playerName)
  end
end

function Main:LoginSummonRequestCheck()
  if (DB.summonRequested) then
    if ((time() - 1800) > DB.summonRequestTime) then
      DB.summonRequested = false
    elseif (DB.inviteReady and (UnitName("player") == DB.summonTarget)) then
      GUI:ShowPopupFrame("LOGIN_INVITE_READY")
      DB.inviteReady = false
    else
      GUI:ShowPopupFrame("SUMMON_REQUESTED_PRIOR_TO_LOGIN")
    end
  else
    DB.inviteReady = false
  end
end

-- Field update functions

function Main:UpdateFields(avoidFriendsUpdate)
  if (avoidFriendsUpdate == nil) then
    Main.triggeredFriendListUpdate = true
    C_FriendList.ShowFriends()
  end
  Main.managerOnBreak = false
  Main:RequestActiveLocations()
  if (DB.summonRequested) then
    Main:RequestETAInfo()
    Main:StartETATicker()
  end
end

function Main:CheckManagerOnline()
  local info = C_FriendList.GetFriendInfo(Main.MANAGER_NAME)
  if (type(info) ~= "table") then
    if (not Main.managerAddedAsFriend) then
      C_FriendList.AddFriend(Main.MANAGER_NAME)
      Main.triggeredFriendListUpdate = true
      Main.managerAddedAsFriend = true
    end
  elseif (Main.managerOnline ~= info.connected) then
    Main.managerOnline = info.connected
    if (Main.managerOnline) then
      Main:UpdateFields(true)
    end
    GUI:Update()
  end
end

function Main:RequestActiveLocations()
  if (Main.managerOnline) then
    Main.locationList = {}
    C_ChatInfo.SendAddonMessage("HPSummons", "!locations", "WHISPER", Main.MANAGER_NAME)
  end
end

function Main:RequestETAInfo()
  if (Main.managerOnline) then
    C_ChatInfo.SendAddonMessage("HPSummons", "!eta", "WHISPER", Main.MANAGER_NAME)
  end
end

function Main:HandleGUIHide()
  Main:CancelETATicker()
end

-- Ticker functions

function Main:StartETATicker()
  if (Main.etaTicker == nil) then
    Main.etaTicker = C_Timer.NewTicker(30, function()
      Main:RequestETAInfo()
    end)
  end
end

function Main:CancelETATicker()
  if (Main.etaTicker ~= nil) then
    Main.etaTicker:Cancel()
    Main.etaTicker = nil
  end
end

-- Request functions

function Main:RequestSummon(character, location)
  if (location == "") then
    GUI:ShowErrorFrame("Please fill in a location.")
  else

    DB.summonRequested = true
    DB.summonDestination = location
    if (character == "Current Character") then
      DB.summonTarget = UnitName("player")
    else
      DB.summonTarget = character
    end
    DB.summonRequestTime = time()

    C_ChatInfo.SendAddonMessage("HPSummons", "!request_"..DB.summonTarget.."_"..DB.summonDestination, "WHISPER", Main.MANAGER_NAME)

    Main:RequestETAInfo()
    GUI:Update()
    Main:StartETATicker()
  end
end

function Main:CancelSummon(noMessage)
  DB.summonRequested = false
  GUI:Update()
  Main:CancelETATicker()

  if (noMessage == nil) then
    C_ChatInfo.SendAddonMessage("HPSummons", "!cancel_"..DB.summonTarget.."_"..DB.summonDestination, "WHISPER", Main.MANAGER_NAME)
  end
end

function Main:LoginConfirmSummon()
  C_ChatInfo.SendAddonMessage("HPSummons", "!loginconfirm_"..DB.summonTarget.."_"..DB.summonDestination, "WHISPER", Main.MANAGER_NAME)
end

function Main:SetManagerBreak(time)
  Main.managerOnBreak = true
  Main.managerBreakEndTime = time
  GUI:Update()
end

-- Group functions

function Main:HandleInviteFail(reason)
  local reason = string.upper(reason)
  GUI:ShowPopupFrame("INVITE_FAIL_"..reason)
end

function Main:RequestInvite()
  C_ChatInfo.SendAddonMessage("HPSummons", "!invite", "WHISPER", Main.MANAGER_NAME)
end

-- Message functions

function Main:HandleAddonMessage(msg, sender)
  local m = {strsplit("_", msg)}
  if (m[1] == "!locrsp") then
    for i=2,#m do
      table.insert(Main.locationList, m[i])
    end
  elseif (m[1] == "!etarsp") then
    Main.etaLineSpot = m[2]
    Main.etaLocOrder = {}
    local i = 3
    while (i < #m) do
      table.insert(Main.etaLocOrder, {m[i], m[i+1]})
      i = i + 2
    end
    GUI:ETAUpdate()
  elseif (m[1] == "!etarspcont") then
    local i = 2
    while (i < #m) do
      table.insert(Main.etaLocOrder, {m[i], m[i+1]})
      i = i + 2
    end
    GUI:ETAUpdate()
  elseif (m[1] == "!cancelrequest") then
    if (m[2] == "break") then
      Main:CancelSummon(true)
      Main:SetManagerBreak(m[3])
    elseif (m[2] == "location") then
      Main.locationList = {}
      GUI:ClearLocationSelect()
      Main:CancelSummon(true)
      GUI:ShowErrorFrame("Sorry, "..Main.MANAGER_NAME.." recently disabled this location.")
    end
  elseif (m[1] == "!break") then
    Main:SetManagerBreak(m[2])
  elseif (m[1] == "!inviteready") then
    DB.inviteReady = true
  elseif (m[1] == "!invitefail") then
    Main:HandleInviteFail(m[2])
  elseif (m[1] == "!arrived") then
    DB.summonRequested = false
    GUI:Update()
    Main:CancelETATicker()
  end
end

