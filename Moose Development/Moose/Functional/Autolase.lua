--- **Functional** - Autolase targets in the field.
--
-- ===
-- 
-- **AUOTLASE** - Autolase targets in the field.
-- 
-- ===
-- 
-- ## Missions:
--
-- ### [Autolase](https://github.com/FlightControl-Master/MOOSE_MISSIONS/tree/develop/)
-- 
-- ===
-- 
-- **Main Features:**
--
--    * Detect and lase contacts automatically
--    * Targets are lased by threat priority order
--    * Use FSM events to link functionality into your scripts
--    * Easy setup
--
-- ===
-- 
--- Spot on!
-- 
-- ===
-- 
-- # 1 Autolase concept
-- 
-- * Detect and lase contacts automatically
-- * Targets are lased by threat priority order
-- * Use FSM events to link functionality into your scripts
-- * Easy set-up
-- * Targets are lased by threat priority order
-- 
-- # 2 Basic usage
-- 
-- ## 2.2 Set up a group of Recce Units:
-- 
--            local FoxSet = SET_GROUP:New():FilterPrefixes("Recce"):FilterCoalitions("blue"):FilterStart()
--            
-- ## 2.3 (Optional) Set up a group of pilots, this will drive who sees the F10 menu entry:
-- 
--            local Pilotset = SET_CLIENT:New():FilterCoalitions("blue"):FilterActive(true):FilterStart()
--            
-- ## 2.4 Set up and start Autolase:
-- 
--            local autolaser = AUTOLASE:New(FoxSet,coalition.side.BLUE,"Wolfpack",Pilotset)
--            
-- ## 2.5 Example - Using a fixed laser code for a specific Recce unit:
-- 
--            local recce = SPAWN:New("Reaper")
--              :InitDelayOff()
--              :OnSpawnGroup(
--                function (group)
--                  local unit = group:GetUnit(1)
--                  local name = unit:GetName()
--                  autolaser:SetRecceLaserCode(name,1688)
--                end
--              )
--              :InitCleanUp(60)
--              :InitLimit(1,0)
--              :SpawnScheduled(30,0.5)
--              
-- ## 2.6 Example - Inform pilots about events:
-- 
--            autolaser:SetNotifyPilots(true) -- defaults to true, also shown if debug == true
--            -- Note - message are shown to pilots in the #SET_CLIENT only if using the pilotset option, else to the coalition.
--
--
-- ### Author: **applevangelist**
-- @module Functional.Autolase
-- @image Designation.JPG

-- Date: Oct 2021

--- Class AUTOLASE
-- @type AUTOLASE
-- @field #string ClassName
-- @field #string lid
-- @field #number verbose
-- @field #string alias
-- @field #boolean debug
-- @field #string version
-- @extends Ops.Intel#INTEL

---
-- @field #AUTOLASE
AUTOLASE = {
  ClassName = "AUTOLASE",
  lid = "",
  verbose = 0,
  alias = "",
  debug = false,
}

--- Laser spot info
-- @type AUTOLASE.LaserSpot
-- @field Core.Spot#SPOT laserspot 
-- @field Wrapper.Unit#UNIT lasedunit
-- @field Wrapper.Unit#UNIT lasingunit
-- @field #number lasercode
-- @field #string location
-- @field #number timestamp
-- @field #string unitname
-- @field #string reccename
-- @field #string unittype

--- AUTOLASE class version.
-- @field #string version
AUTOLASE.version = "0.0.4"

-------------------------------------------------------------------
-- Begin Functional.Autolase.lua
-------------------------------------------------------------------

--- Constructor for a new Autolase instance.
-- @param #AUTOLASE self
-- @param Core.Set#SET_GROUP RecceSet Set of detecting and lasing units
-- @param #number Coalition Coalition side. Can also be passed as a string "red", "blue" or "neutral".
-- @param #string Alias (Optional) An alias how this object is called in the logs etc.
-- @param Core.Set#SET_CLIENT PilotSet (Optional) Set of clients for precision bombing, steering menu creation. Leave nil for a coalition-wide F10 entry and display.
-- @return #AUTOLASE self 
function AUTOLASE:New(RecceSet, Coalition, Alias, PilotSet)
  BASE:T({RecceSet, Coalition, Alias, PilotSet})
  
  -- Inherit everything from BASE class.
  local self=BASE:Inherit(self, BASE:New()) -- #AUTOLASE
  
  if Coalition and type(Coalition)=="string" then
    if Coalition=="blue" then
      self.coalition=coalition.side.BLUE
    elseif Coalition=="red" then
      self.coalition=coalition.side.RED
    elseif Coalition=="neutral" then
      self.coalition=coalition.side.NEUTRAL
    else
      self:E("ERROR: Unknown coalition in AUTOLASE!")
    end
  end
  
  -- Set alias.
  if Alias then
    self.alias=tostring(Alias)
  else
    self.alias="Lion"  
    if self.coalition then
      if self.coalition==coalition.side.RED then
        self.alias="Wolf"
      elseif self.coalition==coalition.side.BLUE then
        self.alias="Fox"
      end
    end
  end 
  
  -- inherit from INTEL
  local self=BASE:Inherit(self, INTEL:New(RecceSet, Coalition, Alias)) -- #AUTOLASE
  
  self.DetectVisual = true
  self.DetectOptical = true
  self.DetectRadar = true
  self.DetectIRST = true
  self.DetectRWR = true
  self.DetectDLINK = true
  self.LaserCodes = UTILS.GenerateLaserCodes()
  self.LaseDistance = 5000
  self.LaseDuration = 300
  self.GroupsByThreat = {}
  self.UnitsByThreat = {}
  self.RecceNames = {}
  self.RecceLaserCode = {}
  self.RecceUnitNames= {}
  self.maxlasing = 4
  self.CurrentLasing = {}
  self.lasingindex = 0
  self.deadunitnotes = {}
  self.usepilotset = false
  self.reporttimeshort = 10
  self.reporttimelong = 30
  self.smoketargets = false
  self.smokecolor = SMOKECOLOR.Red
  self.notifypilots = true
  --self.statusupdate = -28 -- for #INTEL
  self.targetsperrecce = {}
  
  -- Set some string id for output to DCS.log file.
  self.lid=string.format("AUTOLASE %s (%s) | ", self.alias, self.coalition and UTILS.GetCoalitionName(self.coalition) or "unknown")
  
  -- Add FSM transitions.
  --                 From State  -->   Event        -->     To State
  self:AddTransition("*",             "Monitor",              "*")     -- Start FSM
  self:AddTransition("*",             "Lasing",               "*")     -- Lasing target
  self:AddTransition("*",             "TargetLost",           "*")     -- Lost target
  self:AddTransition("*",             "TargetDestroyed",      "*")     -- Target destroyed
  self:AddTransition("*",             "RecceKIA",             "*")     -- Recce KIA
  self:AddTransition("*",             "LaserTimeout",         "*")     -- Laser timed out
  self:AddTransition("*",             "Cancel",               "*")     -- Stop Autolase
  
  -- Menu Entry
  if not PilotSet then
    self.Menu = MENU_COALITION_COMMAND:New(self.coalition,"Autolase",nil,self.ShowStatus,self)
  else
    self.usepilotset = true
    self.pilotset = PilotSet
    self:HandleEvent(EVENTS.PlayerEnterAircraft)
    self:SetPilotMenu()
  end
  
  self:SetClusterAnalysis(false, false)
  
  self:__Start(2)
  self:__Monitor(math.random(5,10))
  
  return self
  
  ------------------------
  --- Pseudo Functions ---
  ------------------------
  
  --- Triggers the FSM event "Monitor".
  -- @function [parent=#AUTOLASE] Status
  -- @param #AUTOLASE self

  --- Triggers the FSM event "Monitor" after a delay.
  -- @function [parent=#AUTOLASE] __Status
  -- @param #AUTOLASE self
  -- @param #number delay Delay in seconds.
  
  --- Triggers the FSM event "Cancel".
  -- @function [parent=#AUTOLASE] Cancel
  -- @param #AUTOLASE self

  --- Triggers the FSM event "Cancel" after a delay.
  -- @function [parent=#AUTOLASE] __Cancel
  -- @param #AUTOLASE self
  -- @param #number delay Delay in seconds.
  
  --- On After "RecceKIA" event.
  -- @function [parent=#AUTOLASE] OnAfterRecceKIA
  -- @param #AUTOLASE self
  -- @param #string From The from state
  -- @param #string Event The event
  -- @param #string To The to state
  -- @param #string RecceName The lost Recce
    
  --- On After "TargetDestroyed" event.
  -- @function [parent=#AUTOLASE] OnAfterTargetDestroyed
  -- @param #AUTOLASE self
  -- @param #string From The from state
  -- @param #string Event The event
  -- @param #string To The to state
  -- @param #string UnitName The destroyed unit\'s name
  -- @param #string RecceName The Recce name lasing
  
  --- On After "TargetLost" event.
  -- @function [parent=#AUTOLASE] OnAfterTargetLost
  -- @param #AUTOLASE self
  -- @param #string From The from state
  -- @param #string Event The event
  -- @param #string To The to state
  -- @param #string UnitName The lost unit\'s name
  -- @param #string RecceName The Recce name lasing
  
  --- On After "LaserTimeout" event.
  -- @function [parent=#AUTOLASE] OnAfterLaserTimeout
  -- @param #AUTOLASE self
  -- @param #string From The from state
  -- @param #string Event The event
  -- @param #string To The to state
  -- @param #string UnitName The lost unit\'s name
  -- @param #string RecceName The Recce name lasing
  
  --- On After "Lasing" event.
  -- @function [parent=#AUTOLASE] OnAfterLasing
  -- @param #AUTOLASE self
  -- @param #string From The from state
  -- @param #string Event The event
  -- @param #string To The to state
  -- @param Functional.Autolase#AUTOLASE.LaserSpot LaserSpot The LaserSpot data table
  
end

-------------------------------------------------------------------
-- Helper Functions
-------------------------------------------------------------------

--- (Internal) Function to set pilot menu.
-- @param #AUTOLASE self
-- @return #AUTOLASE self 
function AUTOLASE:SetPilotMenu()
  local pilottable = self.pilotset:GetSetObjects() or {}
  for _,_unit in pairs (pilottable) do
    local Unit = _unit -- Wrapper.Unit#UNIT
    if Unit and Unit:IsAlive() then
      local Group = Unit:GetGroup()
      local lasemenu = MENU_GROUP_COMMAND:New(Group,"Autolase Status",nil,self.ShowStatus,self,Group)
      lasemenu:Refresh()
    end
  end
  return self
end

--- (Internal) Event function for new pilots.
-- @param #AUTOLASE self
-- @param Core.Event#EVENTDATA EventData
-- @return #AUTOLASE self 
function AUTOLASE:OnEventPlayerEnterAircraft(EventData)
  self:SetPilotMenu()
  return self
end

--- Function to get a laser code by recce name
-- @param #AUTOLASE self
-- @param #string RecceName Unit(!) name of the Recce
-- @return #AUTOLASE self 
function AUTOLASE:GetLaserCode(RecceName)
  local code = 1688
  if self.RecceLaserCode[RecceName] == nil then
    code = self.LaserCodes[math.random(#self.LaserCodes)]
    self.RecceLaserCode[RecceName] = code
  else
    code = self.RecceLaserCode[RecceName]
  end
  return code
end

--- Function set max lasing targets
-- @param #AUTOLASE self
-- @param #number Number Max number of targets to lase at once
-- @return #AUTOLASE self 
function AUTOLASE:SetMaxLasingTargets(Number)
  self.maxlasing = Number or 4
  return self
end

--- Function set notify pilots on events
-- @param #AUTOLASE self
-- @param #boolean OnOff Switch messaging on (true) or off (false)
-- @return #AUTOLASE self 
function AUTOLASE:SetNotifyPilots(OnOff)
  self.notifypilots = OnOff and true
  return self
end

--- (User) Function to set a specific code to a Recce.
-- @param #AUTOLASE self
-- @param #string RecceName (Unit!) Name of the Recce
-- @param #number Code The lase code
-- @return #AUTOLASE self 
function AUTOLASE:SetRecceLaserCode(RecceName, Code)
  local code = Code or 1688
  self.RecceLaserCode[RecceName] = code
  return self
end

--- (User) Function to set message show times.
-- @param #AUTOLASE self
-- @param #number long Longer show time
-- @param #number short Shorter show time
-- @return #AUTOLASE self 
function AUTOLASE:SetReportingTimes(long, short)
  self.reporttimeshort = short or 10
  self.reporttimelong = long or 30
  return self
end

--- (User) Function to set lasing distance in meters and duration in seconds
-- @param #AUTOLASE self
-- @param #number Distance (Max) distance for lasing in meters
-- @param #number Duration (Max) duration for lasing in seconds
-- @return #AUTOLASE self 
function AUTOLASE:SetLasingParameters(Distance, Duration)
  self.LaseDistance = Distance or 5000
  self.LaseDuration = Duration or 300
  return self
end

--- (User) Function to set smoking of targets.
-- @param #AUTOLASE self
-- @param #boolean OnOff Switch smoking on or off
-- @param #number Color Smokecolor, e.g. SMOKECOLOR.Red
-- @return #AUTOLASE self 
function AUTOLASE:SetSmokeTargets(OnOff,Color)
  self.smoketargets = OnOff
  self.smokecolor = Color or SMOKECOLOR.Red
  return self
end

--- (Internal) Function to calculate line of sight.
-- @param #AUTOLASE self
-- @param Wrapper.Unit#UNIT Unit 
-- @return #number LOS Line of sight in meters
function AUTOLASE:GetLosFromUnit(Unit)
  local lasedistance = self.LaseDistance
  local unitheight = Unit:GetHeight()
  local coord = Unit:GetCoordinate()
  local landheight = coord:GetLandHeight()
  local asl = unitheight - landheight
  if asl > 100 then
    local absquare = lasedistance^2+asl^2
    lasedistance = math.sqrt(absquare)
  end
  --self:I({lasedistance=lasedistance})
  return lasedistance
end

--- (Internal) Function to check on lased targets.
-- @param #AUTOLASE self
-- @return #AUTOLASE self
function AUTOLASE:CleanCurrentLasing()
  local lasingtable = self.CurrentLasing
  local newtable = {}
  local newreccecount = {}
  local lasing = 0
  
  for _ind,_entry in pairs(lasingtable) do
    local entry = _entry -- #AUTOLASE.LaserSpot
    if not newreccecount[entry.reccename] then
      newreccecount[entry.reccename] = 0
    end
  end
  
  for _ind,_entry in pairs(lasingtable) do
    local entry = _entry -- #AUTOLASE.LaserSpot
    local valid = 0
    local reccedead = false
    local unitdead = false
    local lostsight = false
    local Tnow = timer.getAbsTime()
    -- check recce dead
    local recce = entry.lasingunit
    if recce and recce:IsAlive() then
      valid = valid + 1
    else
      reccedead = true
      --local text = string.format("Recce %s KIA!",entry.reccename)
      --local m = MESSAGE:New(text,15,"Autolase"):ToAll()
      self:__RecceKIA(2,entry.reccename)
    end
    -- check entry dead
    local unit = entry.lasedunit
    if unit and unit:IsAlive() == true then
      valid = valid + 1
    else
      unitdead = true
      if not self.deadunitnotes[entry.unitname] then
        --local text = string.format("Unit %s destroyed! Good job!",entry.unitname)
        --local m = MESSAGE:New(text,15,"Autolase"):ToAll()
        self.deadunitnotes[entry.unitname] = true
        self:__TargetDestroyed(2,entry.unitname,entry.reccename)
      end
    end
    -- check entry out of sight
    if not reccedead and not unitdead then
      local coord = unit:GetCoordinate() -- Core.Point#COORDINATE
      local coord2 = recce:GetCoordinate() -- Core.Point#COORDINATE
      local dist = coord2:Get3DDistance(coord)
      local lasedistance = self:GetLosFromUnit(recce)
      if dist <= lasedistance then
        valid = valid + 1
      else
        lostsight = true
        entry.laserspot:LaseOff()
        --local text = string.format("Lost sight of unit %s.",entry.unitname)
        --local m = MESSAGE:New(text,15,"Autolase"):ToAll()
        self:__TargetLost(2,entry.unitname,entry.reccename)
      end
    end
    -- check timed out
    local timestamp = entry.timestamp
    if Tnow - timestamp < self.LaseDuration then
      valid = valid + 1
    else
      lostsight = true
      entry.laserspot:LaseOff()
      --local text = string.format("Lost sight of unit %s.",entry.unitname)
      --local m = MESSAGE:New(text,15,"Autolase"):ToAll()
      self:__LaserTimeout(2,entry.unitname,entry.reccename)
    end
    if valid == 4 then
     self.lasingindex = self.lasingindex + 1
     newtable[self.lasingindex] = entry
     newreccecount[entry.reccename] = newreccecount[entry.reccename] + 1
     lasing = lasing + 1
    end
  end
  self.CurrentLasing = newtable
  self.targetsperrecce = newreccecount
  --self:I({newreccecount})
  return lasing
end

--- (Internal) Function to show status.
-- @param #AUTOLASE self
-- @param Wrapper.Group#GROUP Group (Optional) show to a certain group
-- @return #AUTOLASE self
function AUTOLASE:ShowStatus(Group)
  local report = REPORT:New("Autolase")
  local lines = 0
  for _ind,_entry in pairs(self.CurrentLasing) do
    local entry = _entry -- #AUTOLASE.LaserSpot
    local reccename = entry.reccename
    local typename = entry.unittype
    local code = entry.lasercode
    local locationstring = entry.location
    local text = string.format("%s lasing %s code %d\nat %s",reccename,typename,code,locationstring)
    report:AddIndent(text,"|")
    lines = lines + 1
  end
  if lines == 0 then
    report:AddIndent("No targets!","|")
  end
  local reporttime = self.reporttimelong
  if lines == 0 then reporttime = self.reporttimeshort end
  if Group and Group:IsAlive() then
    local m = MESSAGE:New(report:Text(),reporttime,"Info"):ToGroup(Group)
  else
    local m = MESSAGE:New(report:Text(),reporttime,"Info"):ToCoalition(self.coalition)
  end
  return self
end

--- (Internal) Function to show messages.
-- @param #AUTOLASE self
-- @param #string Message The message to be sent
-- @param #number Duration Duration in seconds
-- @return #AUTOLASE self
function AUTOLASE:NotifyPilots(Message,Duration)
  if self.usepilotset then
    local pilotset = self.pilotset:GetSetObjects() --#table
    for _,_pilot in pairs(pilotset) do
      local pilot = _pilot -- Wrapper.Unit#UNIT
      if pilot and pilot:IsAlive() then
       local Group = pilot:GetGroup()
       local m = MESSAGE:New(Message,Duration,"Autolase"):ToGroup(Group)
      end
    end
  elseif not self.debug then
    local m = MESSAGE:New(Message,Duration,"Autolase"):ToCoalition(self.coalition)
  else
    local m = MESSAGE:New(Message,Duration,"Autolase"):ToAll()
  end
  if self.debug then self:I(Message) end
  return self
end

--- (Internal) Function to check if a unit is already lased.
-- @param #AUTOLASE self
-- @param #string unitname Name of the unit to check
-- @return #boolean outcome True or false
function AUTOLASE:CheckIsLased(unitname)
  local outcome = false
  for _,_laserspot in pairs(self.CurrentLasing) do
    local spot = _laserspot -- #AUTOLASE.LaserSpot
    if spot.unitname == unitname then
      outcome = true
      break
    end
  end
  return outcome
end

-------------------------------------------------------------------
-- FSM Functions
-------------------------------------------------------------------

--- (Internal) FSM Function for monitoring
-- @param #AUTOLASE self
-- @param #string From The from state
-- @param #string Event The event
-- @param #string To The to state
-- @return #AUTOLASE self
function AUTOLASE:onbeforeMonitor(From, Event, To)
  self:T({From, Event, To})
  -- Check if group has detected any units.
  self:UpdateIntel()
  return self
end

--- (Internal) FSM Function for monitoring
-- @param #AUTOLASE self
-- @param #string From The from state
-- @param #string Event The event
-- @param #string To The to state
-- @return #AUTOLASE self
function AUTOLASE:onafterMonitor(From, Event, To)
  self:T({From, Event, To})

  -- Housekeeping
  local countlases = self:CleanCurrentLasing()
  
  self:SetPilotMenu()
  
  local detecteditems = self.Contacts or {} -- #table of Ops.Intelligence#INTEL.Contact
  local groupsbythreat = {}
  --self:T("Detected Items:")
  --self:T({detecteditems})
  local report = REPORT:New("Detections")
  local lines = 0
  for _,_contact in pairs(detecteditems) do
    local contact = _contact -- Ops.Intelligence#INTEL.Contact
    local grp = contact.group
    local coord = contact.position
    local reccename = contact.recce
    local reccegrp = UNIT:FindByName(reccename)
    local reccecoord = reccegrp:GetCoordinate()
    local distance = math.floor(reccecoord:Get3DDistance(coord))
    local text = string.format("%s of %s | Distance %d km | Threatlevel %d",contact.attribute, contact.groupname, math.floor(distance/1000), contact.threatlevel)
    report:Add(text)
    self:T(text)
    if self.debug then self:I(text) end
    lines = lines  +  1
    -- sort out groups beyond sight
    local lasedistance = self:GetLosFromUnit(reccegrp)
    if grp:IsGround() and lasedistance >= distance then
      table.insert(groupsbythreat,{contact.group,contact.threatlevel})
      self.RecceNames[contact.groupname] = contact.recce
    end
  end
  
  self.GroupsByThreat = groupsbythreat
  
  if self.verbose > 2 and lines > 0 then
    local m=MESSAGE:New(report:Text(),self.reporttimeshort,"Autolase"):ToAll()
  end
  
  table.sort(self.GroupsByThreat, function(a,b)
      local aNum = a[2] -- Coin value of a
      local bNum = b[2] -- Coin value of b
      return aNum > bNum -- Return their comparisons, < for ascending, > for descending
    end)
  
 -- self:T("Groups by Threat")
  --self:T({self.GroupsByThreat})
  
  -- build table of Units
  local unitsbythreat = {}
  for _,_entry in pairs(self.GroupsByThreat) do
    local group = _entry[1] -- Wrapper.Group#GROUP
    if group and group:IsAlive() then
      local units = group:GetUnits()
      local reccename = self.RecceNames[group:GetName()]
      --local recceunit  UNIT:FindByName(reccename)
      --local reccecoord = recceunit:GetCoordinate()
      for _,_unit in pairs(units) do
        local unit = _unit -- Wrapper.Unit#UNIT
        if unit and unit:IsAlive() then
          local threat = unit:GetThreatLevel()
          local coord = unit:GetCoordinate()
          --local distance = math.floor(reccecoord:Get3DDistance(coord))
          if threat > 0 then
            local unitname = unit:GetName()
            table.insert(unitsbythreat,{unit,threat})
            self.RecceUnitNames[unitname] = reccename
          end
        end
      end
    end
  end
  
  self.UnitsByThreat = unitsbythreat
  
  table.sort(self.UnitsByThreat, function(a,b)
      local aNum = a[2] -- Coin value of a
      local bNum = b[2] -- Coin value of b
      return aNum > bNum -- Return their comparisons, < for ascending, > for descending
    end)
  
 -- self:I("Units by Threat")
 -- self:I({self.UnitsByThreat})
  
  local unitreport = REPORT:New("Detected Units")
  
  local lines = 0 
  for _,_entry in pairs(self.UnitsByThreat) do
    local threat = _entry[2]
    local unit = _entry[1]
    local unitname = unit:GetName()
    local text = string.format("Unit %s | Threatlevel %d | Detected by %s",unitname,threat,self.RecceUnitNames[unitname])
    unitreport:Add(text)
    lines = lines + 1
    self:T(text)
    if self.debug then self:I(text) end
  end
  
  if self.verbose > 2 and lines > 0 then
    local m=MESSAGE:New(unitreport:Text(),self.reporttimeshort,"Autolase"):ToAll()
  end
  
  -- lase targets
  local targets = countlases or 0
    for _,_entry in pairs(self.UnitsByThreat) do
      local unit = _entry[1] -- Wrapper.Unit#UNIT
      local unitname = unit:GetName()
      local reccename = self.RecceUnitNames[unitname]
      local recce = UNIT:FindByName(reccename)
      local reccecount = self.targetsperrecce[reccename] or 0
      if (targets < self.maxlasing or reccecount < targets) and not self:CheckIsLased(unitname) and unit:IsAlive() == true then
        targets = targets + 1
        self.targetsperrecce[reccename] = reccecount + 1
        local code = self:GetLaserCode(reccename)
        local spot = SPOT:New(recce)
        spot:LaseOn(unit,code,self.LaseDuration)
        local locationstring = unit:GetCoordinate():ToStringLLDDM()
        --local text = string.format("%s is lasing %s code %d\nat %s",reccename,unit:GetTypeName(),code,locationstring)
        --local m = MESSAGE:New(text,15,"Autolase"):ToAllIf(self.debug)
        local laserspot = { -- #AUTOLASE.LaserSpot
          laserspot = spot,
          lasedunit = unit,
          lasingunit = recce,
          lasercode = code,
          location = locationstring,
          timestamp = timer.getAbsTime(),
          unitname = unitname,
          reccename = reccename,
          unittype = unit:GetTypeName(),
          }
       if self.smoketargets then
          local coord = unit:GetCoordinate()
          coord:Smoke(self.smokecolor)
       end
       self.lasingindex = self.lasingindex + 1 
       self.CurrentLasing[self.lasingindex] = laserspot
       self:__Lasing(2,laserspot)  
      end
    end

  self:__Monitor(-30)
  return self
end

--- (Internal) FSM Function onbeforeRecceKIA
-- @param #AUTOLASE self
-- @param #string From The from state
-- @param #string Event The event
-- @param #string To The to state
-- @param #string RecceName The lost Recce
-- @return #AUTOLASE self
function AUTOLASE:onbeforeRecceKIA(From,Event,To,RecceName)
  self:T({From, Event, To, RecceName})
  if self.notifypilots or self.debug then
    local text = string.format("Recce %s KIA!",RecceName)
    self:NotifyPilots(text,self.reporttimeshort)
  end
  return self
end

--- (Internal) FSM Function onbeforeTargetDestroyed
-- @param #AUTOLASE self
-- @param #string From The from state
-- @param #string Event The event
-- @param #string To The to state
-- @param #string UnitName The destroyed unit\'s name
-- @param #string RecceName The Recce name lasing
-- @return #AUTOLASE self
function AUTOLASE:onbeforeTargetDestroyed(From,Event,To,UnitName,RecceName)
  self:T({From, Event, To, UnitName, RecceName})
  if self.notifypilots or self.debug then
    local text = string.format("Unit %s destroyed! Good job!",UnitName)
    self:NotifyPilots(text,self.reporttimeshort)
  end
  return self
end

--- (Internal) FSM Function onbeforeTargetLost
-- @param #AUTOLASE self
-- @param #string From The from state
-- @param #string Event The event
-- @param #string To The to state
-- @param #string UnitName The lost unit\'s name
-- @param #string RecceName The Recce name lasing
-- @return #AUTOLASE self
function AUTOLASE:onbeforeTargetLost(From,Event,To,UnitName,RecceName)
  self:T({From, Event, To, UnitName,RecceName})
  if self.notifypilots or self.debug then
    local text = string.format("%s lost sight of unit %s.",RecceName,UnitName)
    self:NotifyPilots(text,self.reporttimeshort)
  end
  return self
end

--- (Internal) FSM Function onbeforeLaserTimeout
-- @param #AUTOLASE self
-- @param #string From The from state
-- @param #string Event The event
-- @param #string To The to state
-- @param #string UnitName The lost unit\'s name
-- @param #string RecceName The Recce name lasing
-- @return #AUTOLASE self
function AUTOLASE:onbeforeLaserTimeout(From,Event,To,UnitName,RecceName)
  self:T({From, Event, To, UnitName,RecceName})
  if self.notifypilots or self.debug then
    local text = string.format("%s laser timeout on unit %s.",RecceName,UnitName)
    self:NotifyPilots(text,self.reporttimeshort)
  end
  return self
end

--- (Internal) FSM Function onbeforeLasing
-- @param #AUTOLASE self
-- @param #string From The from state
-- @param #string Event The event
-- @param #string To The to state
-- @param Functional.Autolase#AUTOLASE.LaserSpot LaserSpot The LaserSpot data table
-- @return #AUTOLASE self
function AUTOLASE:onbeforeLasing(From,Event,To,LaserSpot)
  self:T({From, Event, To, LaserSpot.unittype})
  if self.notifypilots or self.debug then
    local laserspot = LaserSpot -- #AUTOLASE.LaserSpot
    local text = string.format("%s is lasing %s code %d\nat %s",laserspot.reccename,laserspot.unittype,laserspot.lasercode,laserspot.location)
    self:NotifyPilots(text,self.reporttimeshort)
  end
  return self
end

--- (Internal) FSM Function onbeforeCancel
-- @param #AUTOLASE self
-- @param #string From The from state
-- @param #string Event The event
-- @param #string To The to state
-- @return #AUTOLASE self
function AUTOLASE:onbeforeCancel(From,Event,To)
  self:UnHandleEvent(EVENTS.PlayerEnterAircraft)
  self:__Stop(2)
  return self
end

-------------------------------------------------------------------
-- End Functional.Autolase.lua
-------------------------------------------------------------------