------------------------------------
-- HPCustomer Beta (3/11/2020)
------------------------------------

-- Create local vars
local DB -- assigned during ADDON_LOADED
local Main = _G.HPCustomerMain
local GUI = _G.HPCustomerGUI

-- Init functions
function GUI:Init()
  DB = _G.HPCustomerDB
  GUI.created = false
end

-- Local functions

local function RequestButtonOnClick(self, button, down)
  Main:RequestSummon(GUI.characterSelectVal, GUI.locationSelectVal)
end

local function CancelButtonOnClick(self, button, down)
  Main:CancelSummon()
end

local function CharacterSelectOnClick(self, arg1, arg2, checked)
  GUI.characterSelectVal = arg1
  UIDropDownMenu_SetText(GUI.mainFrame.characterSelect, arg1)
end

local function CharacterSelectMenu(self, level, menuList)
  local info = UIDropDownMenu_CreateInfo()

  info.func = CharacterSelectOnClick
  info.text = "Current Character"
  info.arg1, info.checked = info.text, GUI.characterSelectVal == info.text
  UIDropDownMenu_AddButton(info)

  local chars = DB.Main.characterList
  for i=1,#chars do
    info.text = chars[i]
    info.arg1, info.checked = info.text, GUI.characterSelectVal == info.text
    UIDropDownMenu_AddButton(info)
  end
end

local function LocationSelectOnClick(self, arg1, arg2, checked)
  GUI.locationSelectVal = arg1
  UIDropDownMenu_SetText(GUI.mainFrame.locationSelect, arg1)
end

local function LocationSelectMenu(self, level, menuList)
  local info = UIDropDownMenu_CreateInfo()

  info.func = LocationSelectOnClick

  local locs = Main.locationList or {}
  for i=1,#locs do
    info.text = locs[i]
    info.arg1, info.checked = info.text, GUI.locationSelectVal == info.text
    UIDropDownMenu_AddButton(info)
  end
end

-- Main GUI creation
function GUI:Create()
  if GUI.created then return end
  GUI.created = true

  -- Main Frame --------------------------
  local frameName = "HPCustomerGUI-Frame"
  local frame = CreateFrame("Frame", frameName, UIParent)
  frame:ClearAllPoints()
  frame:SetPoint(DB.GUI.points[1], DB.GUI.points[2], DB.GUI.points[3], DB.GUI.points[4], DB.GUI.points[5])
  frame:SetSize(500, 250)
  frame:SetMovable(true)
  frame:EnableMouse(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnMouseDown", frame.StartMoving)
  frame:SetScript("OnMouseUp", function(self)
    self:StopMovingOrSizing()
    local a,b,c,d,e = self:GetPoint()
    DB.GUI.points = {a, nil, c, d, e}
  end)
  frame:SetToplevel(true)
  frame:SetClampedToScreen(true)
  frame:SetBackdrop({ bgFile = "Interface/Tooltips/UI-Tooltip-Background" })
  frame:SetBackdropColor(0.2, 0.2, 0.2, 0.8)
  tinsert(UISpecialFrames, frameName) -- allow Escape button to close the frame
  frame:Hide()
  frame:SetScript("OnHide", function(self)
    GUI:HandleHide()
    Main:HandleGUIHide()
  end)
  GUI.mainFrame = frame

  -- Close Button ---------------------------
  frame.closeButton = CreateFrame("Button", frameName.."-CloseButton", frame, "UIPanelCloseButton")
  frame.closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)

  -- Title Frame ----------------------------
  frame.titleFrame = CreateFrame("Frame", frameName.."-TitleFrame", frame)
  frame.titleFrame:SetSize(10, 10)
  frame.titleFrame:SetBackdrop({bgFile = "Interface/Tooltips/UI-Tooltip-Background"})
  frame.titleFrame:SetBackdropColor(0, 0, 0, 1)
  frame.titleFrame.text = frame.titleFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  frame.titleFrame.text:SetAllPoints(frame.titleFrame)
  frame.titleFrame.text:SetJustifyH("CENTER")
  frame.titleFrame.text:SetText("Hewlett Packard Summons")
  frame.titleFrame:ClearAllPoints()
  frame.titleFrame:SetPoint("TOPLEFT", frame, 10, -7)
  frame.titleFrame:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", -30, -25)

  -- Request Button -------------------
  frame.requestButton = GUI:CreateButton(frameName.."-RequestButton", frame, "TOPLEFT", 415, -60)
  GUI:ConfigureButton(frame.requestButton, 128, 24, "Request Summon")
  frame.requestButton:RegisterForClicks("LeftButtonUp")
  frame.requestButton:SetScript("OnClick", RequestButtonOnClick)

  -- Cancel Button -------------------
  frame.cancelButton = GUI:CreateButton(frameName.."-CancelButton", frame, "TOPLEFT", 415, -60)
  GUI:ConfigureButton(frame.cancelButton, 128, 24, "Cancel Summon")
  frame.cancelButton:RegisterForClicks("LeftButtonUp")
  frame.cancelButton:SetScript("OnClick", CancelButtonOnClick)

  -- Location Drop Down ---------------
  GUI.locationSelectVal = ""
  frame.locationSelect = GUI:CreateDropDown(frameName.."-LocationSelect", frame, 267, -62)
  GUI:ConfigureDropDown(frame.locationSelect, 145, 24, GUI.locationSelectVal)
  UIDropDownMenu_Initialize(frame.locationSelect, LocationSelectMenu)

  -- Location Drop Down Text -----------
  frame.locationSelect.text = frame.locationSelect:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  frame.locationSelect.text:SetPoint("CENTER", frame.locationSelect, "CENTER", 0, 20)
  frame.locationSelect.text:SetJustifyH("CENTER")
  frame.locationSelect.text:SetText("Destination")

  -- Character Drop Down ---------------
  GUI.characterSelectVal = "Current Character"
  frame.characterSelect = GUI:CreateDropDown(frameName.."-CharacterSelect", frame, 100, -62)
  GUI:ConfigureDropDown(frame.characterSelect, 145, 24, GUI.characterSelectVal)
  UIDropDownMenu_Initialize(frame.characterSelect, CharacterSelectMenu)

  -- Character Drop Down Text -----------
  frame.characterSelect.text = frame.characterSelect:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  frame.characterSelect.text:SetPoint("CENTER", frame.characterSelect, "CENTER", 0, 20)
  frame.characterSelect.text:SetJustifyH("CENTER")
  frame.characterSelect.text:SetText("Character")

  -- Error Frame ------------------------
  frame.errorFrame = CreateFrame("Frame", frameName.."-ErrorFrame", frame)
  frame.errorFrame:SetSize(300, 100)
  frame.errorFrame:SetBackdrop({bgFile = "Interface/Tooltips/UI-Tooltip-Background"})
  frame.errorFrame:SetBackdropColor(0, 0, 0, 1)
  frame.errorFrame:SetToplevel(true)
  frame.errorFrame.text = frame.errorFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  frame.errorFrame.text:SetPoint("CENTER", frame.errorFrame, "CENTER", 0, 20)
  frame.errorFrame.text:SetJustifyH("CENTER")
  frame.errorFrame.text:SetText("Generic Error")
  frame.errorFrame:ClearAllPoints()
  frame.errorFrame:SetPoint("CENTER", frame, "CENTER", 0, 0)
  frame.errorFrame:Hide()

  -- Error Frame Button -----------------
  frame.errorFrame.button = GUI:CreateButton(frameName.."-ErrorFrameButton", frame.errorFrame, "CENTER", 0, -20)
  GUI:ConfigureButton(frame.errorFrame.button, 64, 24, "Ok")
  frame.errorFrame.button:RegisterForClicks("LeftButtonUp")
  frame.errorFrame.button:SetScript("OnClick", function(self, button, down)
    frame.errorFrame:Hide()
  end)

  -- Frame Top-section Text ------------
  frame.topText = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  frame.topText:SetPoint("TOPLEFT", frame, "TOPLEFT", 100, -60) 
  frame.topText:SetJustifyH("LEFT")
  frame.topText:Hide()

  -- ETA Viewing Frame -----------------
  frame.etaFrame = CreateFrame("Frame", frameName.."-ETAFrame", frame)
  frame.etaFrame:SetSize(1, 1)
  frame.etaFrame:SetToplevel(true)
  frame.etaFrame:SetBackdrop({bgFile = "Interface/Tooltips/UI-Tooltip-Background"})
  frame.etaFrame:SetBackdropColor(0.2, 0.2, 0.2, 0.8)
  frame.etaFrame:ClearAllPoints()
  frame.etaFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -80)
  frame.etaFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -10, 10)
  frame.etaFrame:Hide()

  -- ETA Line Spot Text ----------------
  frame.etaFrame.lineSpotText = frame.etaFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  frame.etaFrame.lineSpotText:SetPoint("CENTER", frame.etaFrame, "TOP", 0, -20) 
  frame.etaFrame.lineSpotText:SetJustifyH("CENTER")

  -- ETA Location Order Text ----------------
  frame.etaFrame.locOrderText = frame.etaFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  frame.etaFrame.locOrderText:SetPoint("TOP", frame.etaFrame, "TOP", 0, -50) 
  frame.etaFrame.locOrderText:SetJustifyH("CENTER")
end

function GUI:CreatePopupFrame()
  -- Popup Frame --------------------------
  local frameName = "HPCustomerGUI-PopupFrame"
  local popupFrame = CreateFrame("Frame", frameName, UIParent)
  popupFrame:ClearAllPoints()
  popupFrame:SetPoint("CENTER", 0, 0)
  popupFrame:SetSize(450, 120)
  popupFrame:SetMovable(true)
  popupFrame:EnableMouse(true)
  popupFrame:RegisterForDrag("LeftButton")
  popupFrame:SetScript("OnMouseDown", popupFrame.StartMoving)
  popupFrame:SetScript("OnMouseUp", popupFrame.StopMovingOrSizing)
  popupFrame:SetToplevel(true)
  popupFrame:SetClampedToScreen(true)
  popupFrame:SetBackdrop({ bgFile = "Interface/Tooltips/UI-Tooltip-Background" })
  popupFrame:SetBackdropColor(0, 0, 0, 1)
  popupFrame:Hide()
  GUI.popupFrame = popupFrame

  -- Popup Title Frame ----------------------------
  popupFrame.titleFrame = CreateFrame("Frame", frameName.."-TitleFrame", popupFrame)
  popupFrame.titleFrame:SetSize(10, 10)
  popupFrame.titleFrame:SetBackdrop({bgFile = "Interface/Tooltips/UI-Tooltip-Background"})
  popupFrame.titleFrame:SetBackdropColor(0, 0, 0, 1)
  popupFrame.titleFrame.text = popupFrame.titleFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  popupFrame.titleFrame.text:SetAllPoints(popupFrame.titleFrame)
  popupFrame.titleFrame.text:SetJustifyH("CENTER")
  popupFrame.titleFrame.text:SetText("Hewlett Packard Summons")
  popupFrame.titleFrame:ClearAllPoints()
  popupFrame.titleFrame:SetPoint("TOPLEFT", popupFrame, 10, -7)
  popupFrame.titleFrame:SetPoint("BOTTOMRIGHT", popupFrame, "TOPRIGHT", -30, -25)

  -- Popup Frame Text ---------------------------
  popupFrame.text = popupFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  popupFrame.text:SetPoint("CENTER", popupFrame, "CENTER", 0, 0) 
  popupFrame.text:SetJustifyH("CENTER")

  -- Popup Left Button -------------------
  popupFrame.leftButton = GUI:CreateButton(frameName.."-LeftButton", popupFrame, "CENTER", -70, -40)
  GUI:ConfigureButton(popupFrame.leftButton, 128, 24, "Confirm")
  popupFrame.leftButton:RegisterForClicks("LeftButtonUp")

  -- Popup Right Button -------------------
  popupFrame.rightButton = GUI:CreateButton(frameName.."-RightButton", popupFrame, "CENTER", 70, -40)
  GUI:ConfigureButton(popupFrame.rightButton, 128, 24, "Cancel")
  popupFrame.rightButton:RegisterForClicks("LeftButtonUp")
end

-- Show / Hide functions
function GUI:Show()
  if (GUI.mainFrame ~= nil) then
    GUI:Update(true)
    GUI.mainFrame:Show()
  end
end

function GUI:HandleHide()
  GUI:ClearLocationSelect()
end

function GUI:Update(preShowCall)
  local frame = GUI.mainFrame
  if ((frame == nil) or (not preShowCall and not frame:IsShown())) then
    return
  elseif (not Main.managerOnline) then
    frame.requestButton:Hide()
    frame.locationSelect:Hide()
    frame.characterSelect:Hide()
    frame.cancelButton:Hide()
    frame.etaFrame:Hide()

    frame.topText:ClearAllPoints()
    frame.topText:SetPoint("CENTER", frame, "BOTTOM", 0, 200) 
    frame.topText:SetJustifyH("CENTER")
    frame.topText:SetText(Main.MANAGER_NAME.." is not online right now. Please check back later.")
    frame.topText:Show()
  elseif (DB.Main.summonRequested) then
    frame.requestButton:Hide()
    frame.locationSelect:Hide()
    frame.characterSelect:Hide()
    frame.cancelButton:Show()
    GUI:ETAUpdate()
    frame.etaFrame:Show()

    frame.topText:ClearAllPoints()
    frame.topText:SetPoint("TOPLEFT", frame, "TOPLEFT", 25, -53) 
    frame.topText:SetJustifyH("CENTER")
    frame.topText:SetText("Requested "..DB.Main.summonDestination.." for "..DB.Main.summonTarget)
    frame.topText:Show()
  elseif (Main.managerOnBreak) then
    frame.requestButton:Hide()
    frame.locationSelect:Hide()
    frame.characterSelect:Hide()
    frame.cancelButton:Hide()
    frame.etaFrame:Hide()

    frame.topText:ClearAllPoints()
    frame.topText:SetPoint("CENTER", frame, "BOTTOM", 0, 200) 
    frame.topText:SetJustifyH("CENTER")
    frame.topText:SetText(Main.MANAGER_NAME.." is on break right now. Please check back around "..Main.managerBreakEndTime..".")
    frame.topText:Show()
  else
    frame.requestButton:Show()
    frame.locationSelect:Show()
    frame.characterSelect:Show()
    frame.cancelButton:Hide()
    frame.etaFrame:Hide()
    frame.topText:Hide()
  end
end

function GUI:ETAUpdate()
  if (GUI.mainFrame == nil) then return end

  local etaFrame = GUI.mainFrame.etaFrame
  if (not etaFrame:IsVisible()) then return end

  local lineSpot = Main.etaLineSpot or "100"
  local locOrder = Main.etaLocOrder or {}

  etaFrame.lineSpotText:SetText("You are overall "..GUI:GetCardinalNumber(lineSpot).." in line.")

  local locOrderText = ""
  local locSpecificLineSpot = lineSpot
  if (#locOrder > 0) then
    locOrderText = "Summoning Location Order:"
  end
  for i=1,#locOrder do
    locOrderText = locOrderText.."\n"..locOrder[i][1].." - "..locOrder[i][2].." summon"
    if (tonumber(locOrder[i][2]) > 1) then locOrderText = locOrderText.."s" end
    if (locOrder[i][1] == DB.Main.summonDestination) then
      locOrderText = locOrderText.." - "..GUI:GetCardinalNumber(locSpecificLineSpot).." in line"
    end
    locSpecificLineSpot = locSpecificLineSpot - locOrder[i][2]
  end
  etaFrame.locOrderText:SetText(locOrderText)
end

function GUI:ShowPopupFrame(reason)
  if (GUI.popupFrame == nil) then
    GUI:CreatePopupFrame()
  end

  if (reason == "SUMMON_REQUESTED_PRIOR_TO_LOGIN") then
    GUI.popupFrame.text:SetText("You have a summon requested for "..DB.Main.summonTarget.." to "..DB.Main.summonDestination.."\nDo you still want it?")
    GUI.popupFrame.leftButton:SetText("Confirm Summon")
    GUI.popupFrame.leftButton:SetScript("OnClick", function(self, button, down)
      Main:LoginConfirmSummon()
      GUI.popupFrame:Hide()
    end)
    GUI.popupFrame.rightButton:SetText("Cancel Summon")
    GUI.popupFrame.rightButton:SetScript("OnClick", function(self, button, down)
      Main:CancelSummon()
      GUI.popupFrame:Hide()
    end)
    GUI.popupFrame:Show()
  elseif (reason == "LOGIN_INVITE_READY") then
    GUI.popupFrame.text:SetText("Your summon will be ready shortly.")
    GUI.popupFrame.leftButton:SetText("Get Invite")
    GUI.popupFrame.leftButton:SetScript("OnClick", function(self, button, down)
      Main:RequestInvite()
      GUI.popupFrame:Hide()
    end)
    GUI.popupFrame.rightButton:SetText("Cancel Summon")
    GUI.popupFrame.rightButton:SetScript("OnClick", function(self, button, down)
      Main:CancelSummon()
      GUI.popupFrame:Hide()
    end)
    GUI.popupFrame:Show()
  elseif (reason == "INVITE_FAIL_INAGROUP") then
    GUI.popupFrame.text:SetText("You were invited for your summon to "..DB.Main.summonDestination..", but you were in a group.")
    GUI.popupFrame.leftButton:SetText("Leave Group")
    GUI.popupFrame.leftButton:SetScript("OnClick", function(self, button, down)
      LeaveParty()
      Main:RequestInvite()
      GUI.popupFrame:Hide()
    end)
    GUI.popupFrame.rightButton:SetText("Cancel Summon")
    GUI.popupFrame.rightButton:SetScript("OnClick", function(self, button, down)
      Main:CancelSummon()
      GUI.popupFrame:Hide()
    end)
    GUI.popupFrame:Show()
  elseif (reason == "INVITE_FAIL_DECLINED") then
    GUI.popupFrame.text:SetText("You were invited for your summon to "..DB.Main.summonDestination..", but you declined.")
    GUI.popupFrame.leftButton:SetText("Re-Invite")
    GUI.popupFrame.leftButton:SetScript("OnClick", function(self, button, down)
      Main:RequestInvite()
      GUI.popupFrame:Hide()
    end)
    GUI.popupFrame.rightButton:SetText("Cancel Summon")
    GUI.popupFrame.rightButton:SetScript("OnClick", function(self, button, down)
      Main:CancelSummon()
      GUI.popupFrame:Hide()
    end)
    GUI.popupFrame:Show()
  end
end

function GUI:ClearLocationSelect()
  GUI.locationSelectVal = ""
  UIDropDownMenu_SetText(GUI.mainFrame.locationSelect, GUI.locationSelectVal)
end

function GUI:ShowErrorFrame(msg)
  GUI.mainFrame.errorFrame.text:SetText(msg)
  GUI.mainFrame.errorFrame:Show()
end

-- Button functions
function GUI:CreateButton(name, parent, anchor, hpos, vpos)
  local button = CreateFrame("Button", name, parent)
  button:SetPoint("CENTER", parent, anchor, hpos, vpos)
  return button
end

function GUI:ConfigureButton(button, width, height, text)
  button:SetSize(width, height)
  button:SetText(text)
  button:SetNormalFontObject("GameFontNormal")

  local ntex = button:CreateTexture()
  ntex:SetTexture("Interface/Buttons/UI-Panel-Button-Up")
  ntex:SetTexCoord(0, 0.625, 0, 0.6875)
  ntex:SetAllPoints()
  button:SetNormalTexture(ntex)
  
  local htex = button:CreateTexture()
  htex:SetTexture("Interface/Buttons/UI-Panel-Button-Highlight")
  htex:SetTexCoord(0, 0.625, 0, 0.6875)
  htex:SetAllPoints()
  button:SetHighlightTexture(htex)
  
  local ptex = button:CreateTexture()
  ptex:SetTexture("Interface/Buttons/UI-Panel-Button-Down")
  ptex:SetTexCoord(0, 0.625, 0, 0.6875)
  ptex:SetAllPoints()
  button:SetPushedTexture(ptex)
end

-- Drop Down functions
function GUI:CreateDropDown(name, parent, hpos, vpos)
  local dropdown = CreateFrame("Frame", name, parent, "UIDropDownMenuTemplate")
  dropdown:SetPoint("CENTER", parent, "TOPLEFT", hpos, vpos)
  return dropdown
end

function GUI:ConfigureDropDown(dropdown, width, height, text)
  UIDropDownMenu_SetWidth(dropdown, width)
  UIDropDownMenu_SetText(dropdown, text)
  UIDropDownMenu_JustifyText(dropdown, "LEFT")
end

-- Helper functions

function GUI:GetCardinalNumber(num)
  if (type(num) == "string") then num = tonumber(num) end
  if (num == 1) then return "1st"
  elseif (num == 2) then return "2nd"
  elseif (num == 3) then return "3rd"
  else return num.."th" end
end


