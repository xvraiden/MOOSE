--- **Functional** -- Taking the lead of AI escorting your flight or of other AI.
-- 
-- ===
-- 
-- ## Features:
-- 
--   * Escort navigation commands.
--   * Escort hold at position commands.
--   * Escorts reporting detected targets.
--   * Escorts scanning targets in advance.
--   * Escorts attacking specific targets.
--   * Request assistance from other groups for attack.
--   * Manage rule of engagement of escorts.
--   * Manage the allowed evasion techniques of escorts.
--   * Make escort to execute a defined mission or path.
--   * Escort tactical situation reporting.
-- 
-- ===
-- 
-- ## Missions:
-- 
-- [ESC - Escorting](https://github.com/FlightControl-Master/MOOSE_MISSIONS/tree/master/ESC%20-%20Escorting)
-- 
-- ===
-- 
-- Allows you to interact with escorting AI on your flight and take the lead.
-- 
-- Each escorting group can be commanded with a whole set of radio commands (radio menu in your flight, and then F10).
--
-- The radio commands will vary according the category of the group. The richest set of commands are with Helicopters and AirPlanes.
-- Ships and Ground troops will have a more limited set, but they can provide support through the bombing of targets designated by the other escorts.
--
-- # RADIO MENUs that can be created:
-- 
-- Find a summary below of the current available commands:
--
-- ## Navigation ...:
-- 
-- Escort group navigation functions:
--
--   * **"Join-Up and Follow at x meters":** The escort group fill follow you at about x meters, and they will follow you.
--   * **"Flare":** Provides menu commands to let the escort group shoot a flare in the air in a color.
--   * **"Smoke":** Provides menu commands to let the escort group smoke the air in a color. Note that smoking is only available for ground and naval troops.
--
-- ## Hold position ...:
-- 
-- Escort group navigation functions:
--
--   * **"At current location":** Stops the escort group and they will hover 30 meters above the ground at the position they stopped.
--   * **"At client location":** Stops the escort group and they will hover 30 meters above the ground at the position they stopped.
--
-- ## Report targets ...:
-- 
-- Report targets will make the escort group to report any target that it identifies within a 8km range. Any detected target can be attacked using the 4. Attack nearby targets function. (see below).
--
--   * **"Report now":** Will report the current detected targets.
--   * **"Report targets on":** Will make the escort group to report detected targets and will fill the "Attack nearby targets" menu list.
--   * **"Report targets off":** Will stop detecting targets.
--
-- ## Scan targets ...:
-- 
-- Menu items to pop-up the escort group for target scanning. After scanning, the escort group will resume with the mission or defined task.
--
--   * **"Scan targets 30 seconds":** Scan 30 seconds for targets.
--   * **"Scan targets 60 seconds":** Scan 60 seconds for targets.
--
-- ## Attack targets ...:
-- 
-- This menu item will list all detected targets within a 15km range. Depending on the level of detection (known/unknown) and visuality, the targets type will also be listed.
--
-- ## Request assistance from ...:
-- 
-- This menu item will list all detected targets within a 15km range, as with the menu item **Attack Targets**.
-- This menu item allows to request attack support from other escorts supporting the current client group.
-- eg. the function allows a player to request support from the Ship escort to attack a target identified by the Plane escort with its Tomahawk missiles.
-- eg. the function allows a player to request support from other Planes escorting to bomb the unit with illumination missiles or bombs, so that the main plane escort can attack the area.
--
-- ## ROE ...:
-- 
-- Sets the Rules of Engagement (ROE) of the escort group when in flight.
--
--   * **"Hold Fire":** The escort group will hold fire.
--   * **"Return Fire":** The escort group will return fire.
--   * **"Open Fire":** The escort group will open fire on designated targets.
--   * **"Weapon Free":** The escort group will engage with any target.
--
-- ## Evasion ...:
-- 
-- Will define the evasion techniques that the escort group will perform during flight or combat.
--
--   * **"Fight until death":** The escort group will have no reaction to threats.
--   * **"Use flares, chaff and jammers":** The escort group will use passive defense using flares and jammers. No evasive manoeuvres are executed.
--   * **"Evade enemy fire":** The rescort group will evade enemy fire before firing.
--   * **"Go below radar and evade fire":** The escort group will perform evasive vertical manoeuvres.
--
-- ## Resume Mission ...:
-- 
-- Escort groups can have their own mission. This menu item will allow the escort group to resume their Mission from a given waypoint.
-- Note that this is really fantastic, as you now have the dynamic of taking control of the escort groups, and allowing them to resume their path or mission.
--
-- ===
-- 
-- ### Authors: **FlightControl** 
-- 
-- ===
--
-- @module AI.AI_Escort
-- @image Escorting.JPG



--- @type AI_ESCORT
-- @extends AI.AI_Formation#AI_FORMATION
-- @field Wrapper.Client#CLIENT EscortUnit
-- @field Wrapper.Group#GROUP EscortGroup
-- @field #string EscortName
-- @field #AI_ESCORT.MODE EscortMode The mode the escort is in.
-- @field Core.Scheduler#SCHEDULER FollowScheduler The instance of the SCHEDULER class.
-- @field #number FollowDistance The current follow distance.
-- @field #boolean ReportTargets If true, nearby targets are reported.
-- @Field DCS#AI.Option.Air.val.ROE OptionROE Which ROE is set to the EscortGroup.
-- @field DCS#AI.Option.Air.val.REACTION_ON_THREAT OptionReactionOnThreat Which REACTION_ON_THREAT is set to the EscortGroup.
-- @field FunctionalMENU_GROUPDETECTION_BASE Detection

--- AI_ESCORT class
-- 
-- # AI_ESCORT construction methods.
-- 
-- Create a new SPAWN object with the @{#AI_ESCORT.New} method:
--
--  * @{#AI_ESCORT.New}: Creates a new AI_ESCORT object from a @{Wrapper.Group#GROUP} for a @{Wrapper.Client#CLIENT}, with an optional briefing text.
--
-- @usage
-- -- Declare a new EscortPlanes object as follows:
-- 
-- -- First find the GROUP object and the CLIENT object.
-- local EscortUnit = CLIENT:FindByName( "Unit Name" ) -- The Unit Name is the name of the unit flagged with the skill Client in the mission editor.
-- local EscortGroup = GROUP:FindByName( "Group Name" ) -- The Group Name is the name of the group that will escort the Escort Client.
-- 
-- -- Now use these 2 objects to construct the new EscortPlanes object.
-- EscortPlanes = AI_ESCORT:New( EscortUnit, EscortGroup, "Desert", "Welcome to the mission. You are escorted by a plane with code name 'Desert', which can be instructed through the F10 radio menu." )
--
-- @field #AI_ESCORT
AI_ESCORT = {
  ClassName = "AI_ESCORT",
  EscortName = nil, -- The Escort Name
  EscortUnit = nil,
  EscortGroup = nil,
  EscortMode = 1,
  MODE = {
    FOLLOW = 1,
    MISSION = 2,
  },
  Targets = {}, -- The identified targets
  FollowScheduler = nil,
  ReportTargets = true,
  OptionROE = AI.Option.Air.val.ROE.OPEN_FIRE,
  OptionReactionOnThreat = AI.Option.Air.val.REACTION_ON_THREAT.ALLOW_ABORT_MISSION,
  SmokeDirectionVector = false,
  TaskPoints = {}
}

--- AI_ESCORT.Mode class
-- @type AI_ESCORT.MODE
-- @field #number FOLLOW
-- @field #number MISSION

--- MENUPARAM type
-- @type MENUPARAM
-- @field #AI_ESCORT ParamSelf
-- @field #Distance ParamDistance
-- @field #function ParamFunction
-- @field #string ParamMessage

--- AI_ESCORT class constructor for an AI group
-- @param #AI_ESCORT self
-- @param Wrapper.Client#CLIENT EscortUnit The client escorted by the EscortGroup.
-- @param Core.Set#SET_GROUP EscortGroupSet The set of group AI escorting the EscortUnit.
-- @param #string EscortName Name of the escort.
-- @param #string EscortBriefing A text showing the AI_ESCORT briefing to the player. Note that if no EscortBriefing is provided, the default briefing will be shown.
-- @return #AI_ESCORT self
-- @usage
-- -- Declare a new EscortPlanes object as follows:
-- 
-- -- First find the GROUP object and the CLIENT object.
-- local EscortUnit = CLIENT:FindByName( "Unit Name" ) -- The Unit Name is the name of the unit flagged with the skill Client in the mission editor.
-- local EscortGroup = GROUP:FindByName( "Group Name" ) -- The Group Name is the name of the group that will escort the Escort Client.
-- 
-- -- Now use these 2 objects to construct the new EscortPlanes object.
-- EscortPlanes = AI_ESCORT:New( EscortUnit, EscortGroup, "Desert", "Welcome to the mission. You are escorted by a plane with code name 'Desert', which can be instructed through the F10 radio menu." )
function AI_ESCORT:New( EscortUnit, EscortGroupSet, EscortName, EscortBriefing )
  
  local self = BASE:Inherit( self, AI_FORMATION:New( EscortUnit, EscortGroupSet, EscortName, EscortBriefing ) ) -- #AI_ESCORT
  self:F( { EscortUnit, EscortGroupSet } )

  self.EscortUnit = self.FollowUnit -- Wrapper.Unit#UNIT
  self.EscortGroupSet = EscortGroupSet
  self.EscortBriefing = EscortBriefing
 



  
--  if not EscortBriefing then
--    EscortGroup:MessageToClient( EscortGroup:GetCategoryName() .. " '" .. EscortName .. "' (" .. EscortGroup:GetCallsign() .. ") reporting! " ..
--      "We're escorting your flight. " ..
--      "Use the Radio Menu and F10 and use the options under + " .. EscortName .. "\n",
--      60, EscortUnit
--    )
--  else
--    EscortGroup:MessageToClient( EscortGroup:GetCategoryName() .. " '" .. EscortName .. "' (" .. EscortGroup:GetCallsign() .. ") " .. EscortBriefing,
--      60, EscortUnit
--    )
--  end

  self.FollowDistance = 100
  self.CT1 = 0
  self.GT1 = 0


  EscortGroupSet:ForEachGroup(
    --- @param Core.Group#GROUP EscortGroup
    function( EscortGroup )
      EscortGroup.EscortMenu = MENU_GROUP:New( self.EscortUnit:GetGroup(), EscortGroup:GetName() )
      
      -- Set EscortGroup known at EscortUnit.
      if not self.EscortUnit._EscortGroups then
        self.EscortUnit._EscortGroups = {}
      end
    
      if not self.EscortUnit._EscortGroups[EscortGroup:GetName()] then
        self.EscortUnit._EscortGroups[EscortGroup:GetName()] = {}
        self.EscortUnit._EscortGroups[EscortGroup:GetName()].EscortGroup = EscortGroup
        self.EscortUnit._EscortGroups[EscortGroup:GetName()].EscortName = self.EscortName
        self.EscortUnit._EscortGroups[EscortGroup:GetName()].Detection = self.Detection
      end  
  
    EscortGroup.EscortMode = AI_ESCORT.MODE.FOLLOW
    end
  )

  self.Detection = DETECTION_AREAS:New( EscortGroupSet, 5000 )

  self.Detection:Start()
 
  return self
end

function AI_ESCORT:onafterStart( EscortGroupSet )

  self:E("Start")

  EscortGroupSet:ForEachGroup(
    --- @param Core.Group#GROUP EscortGroup
    function( EscortGroup )
      EscortGroup.EscortMenu = MENU_GROUP:New( self.EscortUnit:GetGroup(), EscortGroup:GetName() )
      EscortGroup:WayPointInitialize( 1 )
    
      EscortGroup:OptionROTVertical()
      EscortGroup:OptionROEOpenFire()
    end
  )
    
end

--- Set a Detection method for the EscortUnit to be reported upon.
-- Detection methods are based on the derived classes from DETECTION_BASE.
-- @param #AI_ESCORT self
-- @param Function.Detection#DETECTION_BASE Detection
function AI_ESCORT:SetDetection( Detection )

  self.Detection = Detection
  self.EscortGroup.Detection = self.Detection
  self.EscortUnit._EscortGroups[self.EscortGroup:GetName()].Detection = self.EscortGroup.Detection
  
  Detection:__Start( 1 )
  
end

--- This function is for test, it will put on the frequency of the FollowScheduler a red smoke at the direction vector calculated for the escort to fly to.
-- This allows to visualize where the escort is flying to.
-- @param #AI_ESCORT self
-- @param #boolean SmokeDirection If true, then the direction vector will be smoked.
function AI_ESCORT:TestSmokeDirectionVector( SmokeDirection )
  self.SmokeDirectionVector = ( SmokeDirection == true ) and true or false
end


--- Defines the default menus
-- @param #AI_ESCORT self
-- @return #AI_ESCORT
function AI_ESCORT:Menus()
  self:F()

--  self:MenuScanForTargets( 100, 60 )

  self:MenuHoldAtEscortPosition( 1000, 500 )
  self:MenuHoldAtLeaderPosition( 1000, 500 )

  self:MenuFlare()
  self:MenuSmoke()

  self:MenuReportTargets( 60 )
  self:MenuAssistedAttack()
  self:MenuROE()
  self:MenuEvasion()

--  self:MenuResumeMission()


  return self
end




--- Defines a menu slot to let the escort hold at their current position and stay low with a specified height during a specified time in seconds.
-- This menu will appear under **Hold position**.
-- @param #AI_ESCORT self
-- @param DCS#Distance Height Optional parameter that sets the height in meters to let the escort orbit at the current location. The default value is 30 meters.
-- @param DCS#Time Speed Optional parameter that lets the escort orbit with a specified speed. The default value is a speed that is average for the type of airplane or helicopter.
-- @param #string MenuTextFormat Optional parameter that shows the menu option text. The text string is formatted, and should contain two %d tokens in the string. The first for the Height, the second for the Time (if given). If no text is given, the default text will be displayed.
-- @return #AI_ESCORT
function AI_ESCORT:MenuHoldAtEscortPosition( Height, Speed, MenuTextFormat )
  self:F( { Height, Speed, MenuTextFormat } )

  self.EscortGroupSet:ForEachGroupAlive(
    --- @param Core.Group#GROUP EscortGroup
    function( EscortGroup )
      if EscortGroup:IsAir() then
    
        if not EscortGroup.EscortMenuHold then
          EscortGroup.EscortMenuHold = MENU_GROUP:New( self.EscortUnit:GetGroup(), "Hold position", EscortGroup.EscortMenu )
        end
    
        if not Height then
          Height = 30
        end
    
        if not Speed then
          Speed = 0
        end
    
        local MenuText = ""
        if not MenuTextFormat then
          if Speed == 0 then
            MenuText = string.format( "Hold at %d meter", Height )
          else
            MenuText = string.format( "Hold at %d meter at %d", Height, Speed )
          end
        else
          if Speed == 0 then
            MenuText = string.format( MenuTextFormat, Height )
          else
            MenuText = string.format( MenuTextFormat, Height, Speed )
          end
        end
    
        if not EscortGroup.EscortMenuHoldPosition then
          EscortGroup.EscortMenuHoldPosition = {}
        end
    
        EscortGroup.EscortMenuHoldPosition[#EscortGroup.EscortMenuHoldPosition+1] = MENU_GROUP_COMMAND
          :New(
            self.EscortUnit:GetGroup(),
            MenuText,
            EscortGroup.EscortMenuHold,
            AI_ESCORT._HoldPosition,
            self,
            EscortGroup,
            EscortGroup,
            Height,
            Speed
          )
      end
    end
  )

  return self
end


--- Defines a menu slot to let the escort hold at the client position and stay low with a specified height during a specified time in seconds.
-- This menu will appear under **Navigation**.
-- @param #AI_ESCORT self
-- @param DCS#Distance Height Optional parameter that sets the height in meters to let the escort orbit at the current location. The default value is 30 meters.
-- @param DCS#Time Speed Optional parameter that lets the escort orbit at the current position for a specified time. (not implemented yet). The default value is 0 seconds, meaning, that the escort will orbit forever until a sequent command is given.
-- @param #string MenuTextFormat Optional parameter that shows the menu option text. The text string is formatted, and should contain one or two %d tokens in the string. The first for the Height, the second for the Time (if given). If no text is given, the default text will be displayed.
-- @return #AI_ESCORT
function AI_ESCORT:MenuHoldAtLeaderPosition( Height, Speed, MenuTextFormat )
  self:F( { Height, Speed, MenuTextFormat } )

  self.EscortGroupSet:ForEachGroupAlive(
    --- @param Core.Group#GROUP EscortGroup
    function( EscortGroup )
      if EscortGroup:IsAir() then
    
        if not self.EscortMenuHold then
          self.EscortMenuHold = MENU_GROUP:New( self.EscortUnit:GetGroup(), "Hold position", EscortGroup.EscortMenu )
        end
    
        if not Height then
          Height = 30
        end
    
        if not Speed then
          Speed = 0
        end
    
        local MenuText = ""
        if not MenuTextFormat then
          if Speed == 0 then
            MenuText = string.format( "Rejoin and hold at %d meter", Height )
          else
            MenuText = string.format( "Rejoin and hold at %d meter at %d", Height, Speed )
          end
        else
          if Speed == 0 then
            MenuText = string.format( MenuTextFormat, Height )
          else
            MenuText = string.format( MenuTextFormat, Height, Speed )
          end
        end
    
        if not self.EscortMenuHoldAtLeaderPosition then
          self.EscortMenuHoldAtLeaderPosition = {}
        end
    
        self.EscortMenuHoldAtLeaderPosition[#self.EscortMenuHoldAtLeaderPosition+1] = MENU_GROUP_COMMAND
          :New(
            self.EscortUnit:GetGroup(),
            MenuText,
            self.EscortMenuHold,
            AI_ESCORT._HoldPosition,
            self,
            self.EscortUnit:GetGroup(),
            EscortGroup,
            Height,
            Speed
          )
      end
    end
  )

  return self
end

--- Defines a menu slot to let the escort scan for targets at a certain height for a certain time in seconds.
-- This menu will appear under **Scan targets**.
-- @param #AI_ESCORT self
-- @param DCS#Distance Height Optional parameter that sets the height in meters to let the escort orbit at the current location. The default value is 30 meters.
-- @param DCS#Time Seconds Optional parameter that lets the escort orbit at the current position for a specified time. (not implemented yet). The default value is 0 seconds, meaning, that the escort will orbit forever until a sequent command is given.
-- @param #string MenuTextFormat Optional parameter that shows the menu option text. The text string is formatted, and should contain one or two %d tokens in the string. The first for the Height, the second for the Time (if given). If no text is given, the default text will be displayed.
-- @return #AI_ESCORT
function AI_ESCORT:MenuScanForTargets( Height, Seconds, MenuTextFormat )
  self:F( { Height, Seconds, MenuTextFormat } )

  if self.EscortGroup:IsAir() then
    if not self.EscortMenuScan then
      self.EscortMenuScan = MENU_GROUP:New( self.EscortUnit:GetGroup(), "Scan for targets", self.EscortMenu )
    end

    if not Height then
      Height = 100
    end

    if not Seconds then
      Seconds = 30
    end

    local MenuText = ""
    if not MenuTextFormat then
      if Seconds == 0 then
        MenuText = string.format( "At %d meter", Height )
      else
        MenuText = string.format( "At %d meter for %d seconds", Height, Seconds )
      end
    else
      if Seconds == 0 then
        MenuText = string.format( MenuTextFormat, Height )
      else
        MenuText = string.format( MenuTextFormat, Height, Seconds )
      end
    end

    if not self.EscortMenuScanForTargets then
      self.EscortMenuScanForTargets = {}
    end

    self.EscortMenuScanForTargets[#self.EscortMenuScanForTargets+1] = MENU_GROUP_COMMAND
      :New(
        self.EscortUnit:GetGroup(),
        MenuText,
        self.EscortMenuScan,
        AI_ESCORT._ScanTargets,
        self,
        30
      )
  end

  return self
end



--- Defines a menu slot to let the escort disperse a flare in a certain color.
-- This menu will appear under **Navigation**.
-- The flare will be fired from the first unit in the group.
-- @param #AI_ESCORT self
-- @param #string MenuTextFormat Optional parameter that shows the menu option text. If no text is given, the default text will be displayed.
-- @return #AI_ESCORT
function AI_ESCORT:MenuFlare( MenuTextFormat )
  self:F()

  self.EscortGroupSet:ForEachGroupAlive(
    --- @param Core.Group#GROUP EscortGroup
    function( EscortGroup )
      if not EscortGroup.EscortMenuReportNavigation then
        EscortGroup.EscortMenuReportNavigation = MENU_GROUP:New( self.EscortUnit:GetGroup(), "Navigation", EscortGroup.EscortMenu )
      end
    
      local MenuText = ""
      if not MenuTextFormat then
        MenuText = "Flare"
      else
        MenuText = MenuTextFormat
      end
    
      if not EscortGroup.EscortMenuFlare then
        EscortGroup.EscortMenuFlare = MENU_GROUP:New( self.EscortUnit:GetGroup(), MenuText, EscortGroup.EscortMenuReportNavigation )
        EscortGroup.EscortMenuFlareGreen  = MENU_GROUP_COMMAND:New( self.EscortUnit:GetGroup(), "Release green flare",  EscortGroup.EscortMenuFlare, AI_ESCORT._Flare, self, EscortGroup, FLARECOLOR.Green,  "Released a green flare!"   )
        EscortGroup.EscortMenuFlareRed    = MENU_GROUP_COMMAND:New( self.EscortUnit:GetGroup(), "Release red flare",    EscortGroup.EscortMenuFlare, AI_ESCORT._Flare, self, EscortGroup, FLARECOLOR.Red,    "Released a red flare!"     )
        EscortGroup.EscortMenuFlareWhite  = MENU_GROUP_COMMAND:New( self.EscortUnit:GetGroup(), "Release white flare",  EscortGroup.EscortMenuFlare, AI_ESCORT._Flare, self, EscortGroup, FLARECOLOR.White,  "Released a white flare!"   )
        EscortGroup.EscortMenuFlareYellow = MENU_GROUP_COMMAND:New( self.EscortUnit:GetGroup(), "Release yellow flare", EscortGroup.EscortMenuFlare, AI_ESCORT._Flare, self, EscortGroup, FLARECOLOR.Yellow, "Released a yellow flare!"  )
      end
    end
  )

  return self
end

--- Defines a menu slot to let the escort disperse a smoke in a certain color.
-- This menu will appear under **Navigation**.
-- Note that smoke menu options will only be displayed for ships and ground units. Not for air units.
-- The smoke will be fired from the first unit in the group.
-- @param #AI_ESCORT self
-- @param #string MenuTextFormat Optional parameter that shows the menu option text. If no text is given, the default text will be displayed.
-- @return #AI_ESCORT
function AI_ESCORT:MenuSmoke( MenuTextFormat )
  self:F()

  self.EscortGroupSet:ForEachGroupAlive(
    --- @param Core.Group#GROUP EscortGroup
    function( EscortGroup )
      if not EscortGroup:IsAir() then
        if not EscortGroup.EscortMenuReportNavigation then
          EscortGroup.EscortMenuReportNavigation = MENU_GROUP:New( self.EscortUnit:GetGroup(), "Navigation", EscortGroup.EscortMenu )
        end
    
        local MenuText = ""
        if not MenuTextFormat then
          MenuText = "Smoke"
        else
          MenuText = MenuTextFormat
        end
    
        if not EscortGroup.EscortMenuSmoke then
          EscortGroup.EscortMenuSmoke = MENU_GROUP:New( self.EscortUnit:GetGroup(), "Smoke", EscortGroup.EscortMenuReportNavigation )
          EscortGroup.EscortMenuSmokeGreen  = MENU_GROUP_COMMAND:New( self.EscortUnit:GetGroup(), "Release green smoke",  EscortGroup.EscortMenuSmoke, AI_ESCORT._Smoke, self, EscortGroup, SMOKECOLOR.Green,  "Releasing green smoke!"   )
          EscortGroup.EscortMenuSmokeRed    = MENU_GROUP_COMMAND:New( self.EscortUnit:GetGroup(), "Release red smoke",    EscortGroup.EscortMenuSmoke, AI_ESCORT._Smoke, self, EscortGroup, SMOKECOLOR.Red,    "Releasing red smoke!"     )
          EscortGroup.EscortMenuSmokeWhite  = MENU_GROUP_COMMAND:New( self.EscortUnit:GetGroup(), "Release white smoke",  EscortGroup.EscortMenuSmoke, AI_ESCORT._Smoke, self, EscortGroup, SMOKECOLOR.White,  "Releasing white smoke!"   )
          EscortGroup.EscortMenuSmokeOrange = MENU_GROUP_COMMAND:New( self.EscortUnit:GetGroup(), "Release orange smoke", EscortGroup.EscortMenuSmoke, AI_ESCORT._Smoke, self, EscortGroup, SMOKECOLOR.Orange, "Releasing orange smoke!"  )
          EscortGroup.EscortMenuSmokeBlue   = MENU_GROUP_COMMAND:New( self.EscortUnit:GetGroup(), "Release blue smoke",   EscortGroup.EscortMenuSmoke, AI_ESCORT._Smoke, self, EscortGroup, SMOKECOLOR.Blue,   "Releasing blue smoke!"    )
        end
      end
    end
  )

  return self
end

--- Defines a menu slot to let the escort report their current detected targets with a specified time interval in seconds.
-- This menu will appear under **Report targets**.
-- Note that if a report targets menu is not specified, no targets will be detected by the escort, and the attack and assisted attack menus will not be displayed.
-- @param #AI_ESCORT self
-- @param DCS#Time Seconds Optional parameter that lets the escort report their current detected targets after specified time interval in seconds. The default time is 30 seconds.
-- @return #AI_ESCORT
function AI_ESCORT:MenuReportTargets( Seconds )
  self:F( { Seconds } )

  self.EscortGroupSet:ForEachGroupAlive(
    --- @param Core.Group#GROUP EscortGroup
    function( EscortGroup )
      if not EscortGroup.EscortMenuReportNearbyTargets then
        EscortGroup.EscortMenuReportNearbyTargets = MENU_GROUP:New( self.EscortUnit:GetGroup(), "Report targets", EscortGroup.EscortMenu )
      end
    
      if not Seconds then
        Seconds = 30
      end
    
      -- Report Targets
      EscortGroup.EscortMenuReportNearbyTargetsNow = MENU_GROUP_COMMAND:New( self.EscortUnit:GetGroup(), "Report targets now!", EscortGroup.EscortMenuReportNearbyTargets, AI_ESCORT._ReportNearbyTargetsNow, self, EscortGroup )
      EscortGroup.EscortMenuReportNearbyTargetsOn = MENU_GROUP_COMMAND:New( self.EscortUnit:GetGroup(), "Report targets on", EscortGroup.EscortMenuReportNearbyTargets, AI_ESCORT._SwitchReportNearbyTargets, self, EscortGroup, true )
      EscortGroup.EscortMenuReportNearbyTargetsOff = MENU_GROUP_COMMAND:New( self.EscortUnit:GetGroup(), "Report targets off", EscortGroup.EscortMenuReportNearbyTargets, AI_ESCORT._SwitchReportNearbyTargets, self, EscortGroup, false )
    
      -- Attack Targets
      EscortGroup.EscortMenuAttackNearbyTargets = MENU_GROUP:New( self.EscortUnit:GetGroup(), "Attack targets", EscortGroup.EscortMenu )
    
    
      EscortGroup.ReportTargetsScheduler = SCHEDULER:New( self, self._ReportTargetsScheduler, { EscortGroup }, 1, Seconds )
    end
  )

  return self
end

--- Defines a menu slot to let the escort attack its detected targets using assisted attack from another escort joined also with the client.
-- This menu will appear under **Request assistance from**.
-- Note that this method needs to be preceded with the method MenuReportTargets.
-- @param #AI_ESCORT self
-- @return #AI_ESCORT
function AI_ESCORT:MenuAssistedAttack()
  self:F()

  -- Request assistance from other escorts.
  -- This is very useful to let f.e. an escorting ship attack a target detected by an escorting plane...
  self.EscortMenuTargetAssistance = MENU_GROUP:New( self.EscortUnit:GetGroup(), "Request assistance from", self.EscortMenu )

  return self
end

--- Defines a menu to let the escort set its rules of engagement.
-- All rules of engagement will appear under the menu **ROE**.
-- @param #AI_ESCORT self
-- @return #AI_ESCORT
function AI_ESCORT:MenuROE( MenuTextFormat )
  self:F( MenuTextFormat )

  self.EscortGroupSet:ForEachGroupAlive(
    --- @param Core.Group#GROUP EscortGroup
    function( EscortGroup )
      if not EscortGroup.EscortMenuROE then
        -- Rules of Engagement
        EscortGroup.EscortMenuROE = MENU_GROUP:New( self.EscortUnit:GetGroup(), "ROE", EscortGroup.EscortMenu )
        if EscortGroup:OptionROEHoldFirePossible() then
          EscortGroup.EscortMenuROEHoldFire = MENU_GROUP_COMMAND:New( self.EscortUnit:GetGroup(), "Hold Fire", EscortGroup.EscortMenuROE, AI_ESCORT._ROE, self, EscortGroup, EscortGroup:OptionROEHoldFire(), "Holding weapons!" )
        end
        if EscortGroup:OptionROEReturnFirePossible() then
          EscortGroup.EscortMenuROEReturnFire = MENU_GROUP_COMMAND:New( self.EscortUnit:GetGroup(), "Return Fire", EscortGroup.EscortMenuROE, AI_ESCORT._ROE, self, EscortGroup, EscortGroup:OptionROEReturnFire(), "Returning fire!" )
        end
        if EscortGroup:OptionROEOpenFirePossible() then
          EscortGroup.EscortMenuROEOpenFire = MENU_GROUP_COMMAND:New( self.EscortUnit:GetGroup(), "Open Fire", EscortGroup.EscortMenuROE, AI_ESCORT._ROE, self, EscortGroup, EscortGroup:OptionROEOpenFire(), "Opening fire on designated targets!!" )
        end
        if EscortGroup:OptionROEWeaponFreePossible() then
          EscortGroup.EscortMenuROEWeaponFree = MENU_GROUP_COMMAND:New( self.EscortUnit:GetGroup(), "Weapon Free", EscortGroup.EscortMenuROE, AI_ESCORT._ROE, self, EscortGroup, EscortGroup:OptionROEWeaponFree(), "Opening fire on targets of opportunity!" )
        end
      end
    end
  )

  return self
end


--- Defines a menu to let the escort set its evasion when under threat.
-- All rules of engagement will appear under the menu **Evasion**.
-- @param #AI_ESCORT self
-- @return #AI_ESCORT
function AI_ESCORT:MenuEvasion( MenuTextFormat )
  self:F( MenuTextFormat )

  self.EscortGroupSet:ForEachGroupAlive(
    --- @param Core.Group#GROUP EscortGroup
    function( EscortGroup )
      if EscortGroup:IsAir() then
        if not EscortGroup.EscortMenuEvasion then
          -- Reaction to Threats
          EscortGroup.EscortMenuEvasion = MENU_GROUP:New( self.EscortUnit:GetGroup(), "Evasion", EscortGroup.EscortMenu )
          if EscortGroup:OptionROTNoReactionPossible() then
            EscortGroup.EscortMenuEvasionNoReaction = MENU_GROUP_COMMAND:New( self.EscortUnit:GetGroup(), "Fight until death", EscortGroup.EscortMenuEvasion, AI_ESCORT._ROT, self, EscortGroup, EscortGroup:OptionROTNoReaction(), "Fighting until death!" )
          end
          if EscortGroup:OptionROTPassiveDefensePossible() then
            EscortGroup.EscortMenuEvasionPassiveDefense = MENU_GROUP_COMMAND:New( self.EscortUnit:GetGroup(), "Use flares, chaff and jammers", EscortGroup.EscortMenuEvasion, AI_ESCORT._ROT, self, EscortGroup, EscortGroup:OptionROTPassiveDefense(), "Defending using jammers, chaff and flares!" )
          end
          if EscortGroup:OptionROTEvadeFirePossible() then
            EscortGroup.EscortMenuEvasionEvadeFire = MENU_GROUP_COMMAND:New( self.EscortUnit:GetGroup(), "Evade enemy fire", EscortGroup.EscortMenuEvasion, AI_ESCORT._ROT, self, EscortGroup, EscortGroup:OptionROTEvadeFire(), "Evading on enemy fire!" )
          end
          if EscortGroup:OptionROTVerticalPossible() then
            EscortGroup.EscortMenuOptionEvasionVertical = MENU_GROUP_COMMAND:New( self.EscortUnit:GetGroup(), "Go below radar and evade fire", EscortGroup.EscortMenuEvasion, AI_ESCORT._ROT, self, EscortGroup, EscortGroup:OptionROTVertical(), "Evading on enemy fire with vertical manoeuvres!" )
          end
        end
      end
    end
  )

  return self
end

--- Defines a menu to let the escort resume its mission from a waypoint on its route.
-- All rules of engagement will appear under the menu **Resume mission from**.
-- @param #AI_ESCORT self
-- @return #AI_ESCORT
function AI_ESCORT:MenuResumeMission()
  self:F()

  if not self.EscortMenuResumeMission then
    -- Mission Resume Menu Root
    self.EscortMenuResumeMission = MENU_GROUP:New( self.EscortUnit:GetGroup(), "Resume mission from", self.EscortMenu )
  end

  return self
end


--- @param #AI_ESCORT self
-- @param Wrapper.Group#GROUP OrbitGroup
-- @param Wrapper.Group#GROUP EscortGroup
-- @param #number OrbitHeight
-- @param #number OrbitSeconds
function AI_ESCORT:_HoldPosition( OrbitGroup, EscortGroup, OrbitHeight, OrbitSeconds )

  local EscortUnit = self.EscortUnit

  local OrbitUnit = OrbitGroup:GetUnit(1) -- Wrapper.Unit#UNIT
  
  self:ReleaseFormation( EscortGroup )

  local PointFrom = {}
  local GroupVec3 = EscortGroup:GetUnit(1):GetVec3()
  PointFrom = {}
  PointFrom.x = GroupVec3.x
  PointFrom.y = GroupVec3.z
  PointFrom.speed = 250
  PointFrom.type = AI.Task.WaypointType.TURNING_POINT
  PointFrom.alt = GroupVec3.y
  PointFrom.alt_type = AI.Task.AltitudeType.BARO

  local OrbitPoint = OrbitUnit:GetVec2()
  local PointTo = {}
  PointTo.x = OrbitPoint.x
  PointTo.y = OrbitPoint.y
  PointTo.speed = 250
  PointTo.type = AI.Task.WaypointType.TURNING_POINT
  PointTo.alt = OrbitHeight
  PointTo.alt_type = AI.Task.AltitudeType.BARO
  PointTo.task = EscortGroup:TaskOrbitCircleAtVec2( OrbitPoint, OrbitHeight, 0 )

  local Points = { PointFrom, PointTo }

  EscortGroup:OptionROEHoldFire()
  EscortGroup:OptionROTPassiveDefense()

  EscortGroup:SetTask( EscortGroup:TaskRoute( Points ), 1 )
  EscortGroup:MessageTypeToGroup( "Orbiting at current location.", MESSAGE.Type.Information, EscortUnit:GetGroup() )

end

--- @param #MENUPARAM MenuParam
function AI_ESCORT:_JoinUpAndFollow( Distance )

  local EscortGroup = self.EscortGroup
  local EscortUnit = self.EscortUnit

  self.Distance = Distance

  self:JoinUpAndFollow( EscortGroup, EscortUnit, self.Distance )
end


--- @param #MENUPARAM MenuParam
function AI_ESCORT:_Flare( EscortGroup, Color, Message )

  local EscortUnit = self.EscortUnit

  EscortGroup:GetUnit(1):Flare( Color )
  EscortGroup:MessageTypeToGroup( Message, MESSAGE.Type.Information, EscortUnit:GetGroup() )
end

--- @param #MENUPARAM MenuParam
function AI_ESCORT:_Smoke( EscortGroup, Color, Message )

  local EscortUnit = self.EscortUnit

  EscortGroup:GetUnit(1):Smoke( Color )
  EscortGroup:MessageTypeToGroup( Message, MESSAGE.Type.Information, EscortUnit:GetGroup() )
end


--- @param #MENUPARAM MenuParam
function AI_ESCORT:_ReportNearbyTargetsNow( EscortGroup )

  local EscortUnit = self.EscortUnit

  self:_ReportTargetsScheduler( EscortGroup )

end

function AI_ESCORT:_SwitchReportNearbyTargets( EscortGroup, ReportTargets )

  local EscortUnit = self.EscortUnit

  self.ReportTargets = ReportTargets

  if self.ReportTargets then
    if not EscortGroup.ReportTargetsScheduler then
      EscortGroup.ReportTargetsScheduler:Schedule( self, self._ReportTargetsScheduler, {}, 1, 30 )
    end
  else
    routines.removeFunction( EscortGroup.ReportTargetsScheduler )
    EscortGroup.ReportTargetsScheduler = nil
  end
end

--- @param #MENUPARAM MenuParam
function AI_ESCORT:_ScanTargets( ScanDuration )

  local EscortGroup = self.EscortGroup -- Wrapper.Group#GROUP
  local EscortUnit = self.EscortUnit

  self.FollowScheduler:Stop( self.FollowSchedule )

  if EscortGroup:IsHelicopter() then
    EscortGroup:PushTask(
      EscortGroup:TaskControlled(
        EscortGroup:TaskOrbitCircle( 200, 20 ),
        EscortGroup:TaskCondition( nil, nil, nil, nil, ScanDuration, nil )
      ), 1 )
  elseif EscortGroup:IsAirPlane() then
    EscortGroup:PushTask(
      EscortGroup:TaskControlled(
        EscortGroup:TaskOrbitCircle( 1000, 500 ),
        EscortGroup:TaskCondition( nil, nil, nil, nil, ScanDuration, nil )
      ), 1 )
  end

  EscortGroup:MessageToClient( "Scanning targets for " .. ScanDuration .. " seconds.", ScanDuration, EscortUnit )

  if self.EscortMode == AI_ESCORT.MODE.FOLLOW then
    self.FollowScheduler:Start( self.FollowSchedule )
  end

end

--- @param #AI_ESCORT self
-- @param Wrapper.Group#GROUP EscortGroup
function AI_ESCORT.___Resume( EscortGroup, self )

  if EscortGroup.EscortMode == AI_ESCORT.MODE.FOLLOW then
    self:JoinFormation( EscortGroup )
  end

end

--- @param #AI_ESCORT self
-- @param Wrapper.Group#GROUP EscortGroup The escort group that will attack the detected item.
-- @param Functional.Detection#DETECTION_BASE.DetectedItem DetectedItem
function AI_ESCORT:_AttackTarget( EscortGroup, DetectedItem )

  self:F( EscortGroup )
  
  local EscortUnit = self.EscortUnit
  
  self:ReleaseFormation( EscortGroup )

  if EscortGroup:IsAir() then
    EscortGroup:OptionROEOpenFire()
    EscortGroup:OptionROTPassiveDefense()
    EscortGroup:SetState( EscortGroup, "Escort", self )

    local DetectedSet = self.Detection:GetDetectedItemSet( DetectedItem )
    
    local Tasks = {}
    local AttackUnitTasks = {}

    DetectedSet:ForEachUnit(
      --- @param Wrapper.Unit#UNIT DetectedUnit
      function( DetectedUnit, Tasks )
        if DetectedUnit:IsAlive() then
          AttackUnitTasks[#AttackUnitTasks+1] = EscortGroup:TaskAttackUnit( DetectedUnit )
        end
      end, Tasks
    )    

    Tasks[#Tasks+1] = EscortGroup:TaskCombo( AttackUnitTasks )
    Tasks[#Tasks+1] = EscortGroup:TaskFunction( "AI_ESCORT.___Resume", self, EscortGroup )
    
    EscortGroup:SetTask( 
      EscortGroup:TaskCombo(
        Tasks
      ), 1
    )
    
  else
  
    local DetectedSet = self.Detection:GetDetectedItemSet( DetectedItem )
    
    local Tasks = {}

    DetectedSet:ForEachUnit(
      --- @param Wrapper.Unit#UNIT DetectedUnit
      function( DetectedUnit, Tasks )
        if DetectedUnit:IsAlive() then
          Tasks[#Tasks+1] = EscortGroup:TaskFireAtPoint( DetectedUnit:GetVec2(), 50 )
        end
      end, Tasks
    )    

    EscortGroup:SetTask( 
      EscortGroup:TaskCombo(
        Tasks
      ), 1
    )

  end
  
  EscortGroup:MessageTypeToGroup( "Engaging Designated Unit!", MESSAGE.Type.Information, EscortUnit )

end

--- 
--- @param #AI_ESCORT self
-- @param Wrapper.Group#GROUP EscortGroup The escort group that will attack the detected item.
-- @param Functional.Detection#DETECTION_BASE.DetectedItem DetectedItem
function AI_ESCORT:_AssistTarget( EscortGroup, DetectedItem )

  local EscortUnit = self.EscortUnit

  local DetectedSet = self.Detection:GetDetectedItemSet( DetectedItem )
  
  local Tasks = {}

  DetectedSet:ForEachUnit(
    --- @param Wrapper.Unit#UNIT DetectedUnit
    function( DetectedUnit, Tasks )
      if DetectedUnit:IsAlive() then
        Tasks[#Tasks+1] = EscortGroup:TaskFireAtPoint( DetectedUnit:GetVec2(), 50 )
      end
    end, Tasks
  )    

  EscortGroup:SetTask( 
    EscortGroup:TaskCombo(
      Tasks
    ), 1
  )


  EscortGroup:MessageTypeToGroup( "Assisting with the destroying the enemy unit!", MESSAGE.Type.Information, EscortUnit:GetGroup() )

end

--- @param #MENUPARAM MenuParam
function AI_ESCORT:_ROE( EscortGroup, EscortROEFunction, EscortROEMessage )

  local EscortUnit = self.EscortUnit

  pcall( function() EscortROEFunction() end )
  EscortGroup:MessageTypeToGroup( EscortROEMessage, MESSAGE.Type.Information, EscortUnit:GetGroup() )
end

--- @param #MENUPARAM MenuParam
function AI_ESCORT:_ROT( EscortGroup, EscortROTFunction, EscortROTMessage )

  local EscortUnit = self.EscortUnit

  pcall( function() EscortROTFunction() end )
  EscortGroup:MessageTypeToGroup( EscortROTMessage, MESSAGE.Type.Information, EscortUnit:GetGroup() )
end

--- @param #MENUPARAM MenuParam
function AI_ESCORT:_ResumeMission( WayPoint )

  local EscortGroup = self.EscortGroup
  local EscortUnit = self.EscortUnit

  self.FollowScheduler:Stop( self.FollowSchedule )

  local WayPoints = EscortGroup:GetTaskRoute()
  self:T( WayPoint, WayPoints )

  for WayPointIgnore = 1, WayPoint do
    table.remove( WayPoints, 1 )
  end

  SCHEDULER:New( EscortGroup, EscortGroup.SetTask, { EscortGroup:TaskRoute( WayPoints ) }, 1 )

  EscortGroup:MessageToClient( "Resuming mission from waypoint " .. WayPoint .. ".", 10, EscortUnit )
end

--- Registers the waypoints
-- @param #AI_ESCORT self
-- @return #table
function AI_ESCORT:RegisterRoute()
  self:F()

  local EscortGroup = self.EscortGroup -- Wrapper.Group#GROUP

  local TaskPoints = EscortGroup:GetTaskRoute()

  self:T( TaskPoints )

  return TaskPoints
end



--- Report Targets Scheduler.
-- @param #AI_ESCORT self
-- @param Wrapper.Group#GROUP EscortGroup
function AI_ESCORT:_ReportTargetsScheduler( EscortGroup )
  self:F( EscortGroup:GetName() )

  if EscortGroup:IsAlive() and self.EscortUnit:IsAlive() then

    if true then

      local EscortGroupName = EscortGroup:GetName() 
    
      EscortGroup.EscortMenuAttackNearbyTargets:RemoveSubMenus()

      if EscortGroup.EscortMenuTargetAssistance then
        EscortGroup.EscortMenuTargetAssistance:RemoveSubMenus()
      end

      local DetectedItems = self.Detection:GetDetectedItems()
      self:F( DetectedItems )

      local DetectedTargets = false
  
      local DetectedMsgs = {}
      
      local ClientEscortTargets = self.Detection
      --local EscortUnit = EscortGroupData:GetUnit( 1 )

      for DetectedItemIndex, DetectedItem in pairs( DetectedItems ) do
        self:F( { DetectedItemIndex, DetectedItem } )

        local DetectedItemReportSummary = self.Detection:DetectedItemReportSummary( DetectedItem, EscortGroup, _DATABASE:GetPlayerSettings( self.EscortUnit:GetPlayerName() ) )

        if EscortGroup:IsAir() then
        
          local DetectedMsg = DetectedItemReportSummary:Text("\n")
          DetectedMsgs[#DetectedMsgs+1] = DetectedMsg

          self:T( DetectedMsg )

          MENU_GROUP_COMMAND:New( self.EscortUnit:GetGroup(),
            DetectedMsg,
            EscortGroup.EscortMenuAttackNearbyTargets,
            AI_ESCORT._AttackTarget,
            self,
            EscortGroup,
            DetectedItem
          )
        else
          if self.EscortMenuTargetAssistance then
          
            local DetectedMsg = DetectedItemReportSummary:Text("\n")
            self:T( DetectedMsg )

            local MenuTargetAssistance = MENU_GROUP:New( self.EscortUnit:GetGroup(), EscortGroupName, EscortGroup.EscortMenuTargetAssistance )
            MENU_GROUP_COMMAND:New( self.EscortUnit:GetGroup(),
              DetectedMsg,
              MenuTargetAssistance,
              AI_ESCORT._AssistTarget,
              self,
              EscortGroup,
              DetectedItem
            )
          end
          
        end
        DetectedTargets = true
      end
      self:F( DetectedMsgs )
      if DetectedTargets then
        EscortGroup:MessageTypeToGroup( "Reporting detected targets:\n" .. table.concat( DetectedMsgs, "\n" ), MESSAGE.Type.Information, self.EscortUnit:GetGroup() )
      else
        EscortGroup:MessageTypeToGroup( "No targets detected.", MESSAGE.Type.Information, self.EscortUnit:GetGroup() )
      end
      
      return true
    else
    end
  end
  
  return false
end
