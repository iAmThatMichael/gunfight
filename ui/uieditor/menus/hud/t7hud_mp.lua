-- The MP Hud Base, Rebuilt from the ground up by the D3V Team
require("ui.uieditor.widgets.gunfight_score_container")

require("ui.uieditor.widgets.HUD.SafeAreaContainers.T7Hud_MP_SafeAreaContainer")
require("ui.uieditor.widgets.MPHudWidgets.ReadyEvents.ReadyEvents")
require("ui.uieditor.widgets.MPHudWidgets.ScorePopup.MPScr")
require("ui.uieditor.widgets.DynamicContainerWidget")
require("ui.uieditor.widgets.MP.MPDamageFeedback")
require("ui.uieditor.widgets.HUD.Outcome.Outcome")
require("ui.uieditor.widgets.EndGameFlow.Top3PlayersScreenWidget")
require("ui.uieditor.widgets.Scoreboard.ScoreboardWidget")
require("ui.uieditor.widgets.Chat.inGame.IngameChatClientContainer")
require("ui.uieditor.widgets.Scorestreaks.CallingScorestreaks.ArmDeviceWidget")
require("ui.uieditor.widgets.Scorestreaks.CallingScorestreaks.GenericProjectedTablet")

local function PreLoadCallback(HudRef, InstanceRef)
    Engine.CreateModel(Engine.GetModelForController(InstanceRef), "hudItems.combat_efficiency_enabled")
end

local function PostLoadCallback(HudRef, InstanceRef)
    local function HudGainFocus(SenderObj, EventObj)
        HudRef.SafeAreaContainer.ScrStkContainer.ScrStkButtons:processEvent(EventObj)
    end

    HudRef:registerEventHandler("gain_focus", HudGainFocus)

    local function HudGamepadButton(SenderObj, EventObj)
        if SenderObj.ScoreboardWidget.m_inputDisabled == true then
            SenderObj.SafeAreaContainer.ScrStkContainer.ScrStkButtons:processEvent(EventObj)
        else
            SenderObj.ScoreboardWidget:processEvent(EventObj)
        end
    end

    HudRef:registerEventHandler("gamepad_button", HudGamepadButton)

    if Engine.IsVisibilityBitSet(InstanceRef, Enum.UIVisibilityBit.BIT_HUD_HARDCORE) then
        local function ScrStkFocusCallback(SenderObj, EventObj)
            if not SenderObj.gridInfoTable.zeroBasedIndex == nil then

                -- Adjust grid index based on killstreak count
                SenderObj.gridInfoTable.zeroBasedIndex = ((CoD.CACUtility.maxScorestreaks - 1.0) - SenderObj.gridInfoTable.zeroBasedIndex)

                -- Returns nil / "" when the model does not exist
                local RewardValue = CoD.SafeGetModelValue(Engine.GetModelForController(InstanceRef), ("killstreaks.killstreak" .. SenderObj.gridInfoTable.zeroBasedIndex .. ".rewardName"))
                -- Make sure we got a value
                if not RewardValue == nil and not RewardValue == "" then
                    SenderObj.SafeAreaContainer.MPHardcoreInventoryWidget.HardcoreScorestreakWidget.text:setText(RewardValue)
                    SenderObj.SafeAreaContainer.MPHardcoreInventoryWidget.HardcoreScorestreakWidget:playClip("Show")
                end
            end
        end

        -- Override the hardcore hud logic so we support showing killstreak rewards
        HudRef.SafeAreaContainer.ScrStkContainer.ScrStkButtons:registerEventHandler("list_item_gain_focus", ScrStkFocusCallback)
    end

    local function HudKeyPressed(HudObj, InstanceObj, Unk3, Unk4)
        if HudObj.ScoreboardWidget.m_inputDisabled == true then
            if not HudObj.SafeAreaContainer.ScrStkContainer.ScrStkButtons.m_disableNavigation then
                HudObj.SafeAreaContainer.ScrStkContainer:processEvent({name = "gain_focus", controller = InstanceObj})
            end
            if not HudObj.handlingScrStkPress then
                HudObj.handlingScrStkPress = true
                CoD.Menu.HandleButtonPress(HudObj, InstanceObj, Unk3, Unk4)
                HudObj.handlingScrStkPress = nil
            end
        end
    end

    local function HudKeyRight(Unk1, HudObj, InstanceObj, Unk4)
        HudKeyPressed(HudObj, InstanceObj, Unk4, Enum.LUIButton.LUI_KEY_RIGHT)
    end

    local function HudKeyUp(Unk1, HudObj, InstanceObj, Unk4)
        HudKeyPressed(HudObj, InstanceObj, Unk4, Enum.LUIButton.LUI_KEY_UP)
    end

    local function HudKeyDown(Unk1, HudObj, InstanceObj, Unk4)
        HudKeyPressed(HudObj, InstanceObj, Unk4, Enum.LUIButton.LUI_KEY_DOWN)
    end

    HudRef:AddButtonCallbackFunction(HudRef, InstanceRef, Enum.LUIButton.LUI_KEY_RIGHT, nil, HudKeyRight, AlwaysFalse, false)
    HudRef:AddButtonCallbackFunction(HudRef, InstanceRef, Enum.LUIButton.LUI_KEY_UP, nil, HudKeyUp, AlwaysFalse, false)
    HudRef:AddButtonCallbackFunction(HudRef, InstanceRef, Enum.LUIButton.LUI_KEY_DOWN, nil, HudKeyDown, AlwaysFalse, false)

    local function SafeAreaChanged()
        if not Engine.IsVisibilityBitSet(InstanceRef, Enum.UIVisibilityBit.BIT_SPECTATING_CLIENT) then
            HudRef.SafeAreaContainer.ScrStkContainer.ScrStkButtons.m_disableNavigation = Engine.IsVisibilityBitSet(InstanceRef, Enum.UIVisibilityBit.BIT_GAME_ENDED)
        end
    end

    local function HudBitSpectate(ModelRef)
        SafeAreaChanged()
    end

    local function HudBitEnded(ModelRef)
        SafeAreaChanged()
    end

    HudRef:subscribeToModel(Engine.GetModel(Engine.GetModelForController(InstanceRef), "UIVisibilityBit." .. Enum.UIVisibilityBit.BIT_SPECTATING_CLIENT), HudBitSpectate)
    HudRef:subscribeToModel(Engine.GetModel(Engine.GetModelForController(InstanceRef), "UIVisibilityBit." .. Enum.UIVisibilityBit.BIT_GAME_ENDED), HudBitEnded)

    local function RejackWindow(ModelRef)
        if ModelRef and Engine.GetModelValue(ModelRef) == 0.0 then
            if HudRef.rejackWidget then
                HudRef.rejackWidget:close()
                HudRef.rejackWidget = nil
            end
        end
    end

    local function RejackActivate(ModelRef)
        if ModelRef and Engine.GetModelValue(ModelRef) == 1.0 then
            if HudRef.rejackWidget then
                HudRef.rejackWidget.RejackInternal:startRejackAnimation(InstanceRef)
            end
        end
    end

    HudRef:subscribeToModel(Engine.CreateModel(Engine.GetModelForController(InstanceRef), "hudItems.rejack.activationWindowEntered"), RejackWindow)
    HudRef:subscribeToModel(Engine.CreateModel(Engine.GetModelForController(InstanceRef), "hudItems.rejack.rejackActivated"), RejackActivate)

    local function HudScriptNotif(ModelRef)
        if IsParamModelEqualToString(ModelRef, "create_rejack_timer") then
            CreateRejackTimer(HudRef, InstanceRef, ModelRef)
        end
    end

    HudRef:subscribeToGlobalModel(InstanceRef, "PerController", "scriptNotify", HudScriptNotif)

    local CurrentWeaponModel = DataSources.CurrentWeapon.getModel(InstanceRef)
    if CurrentWeaponModel then
        Engine.CreateModel(CurrentWeaponModel, "weaponPrestigeUI3DText")
    end

    local function WeaponPrestigeCallback(ModelRef)
        local PrestigeVal = Engine.GetModelValue(ModelRef)
        if PrestigeVal and not PrestigeVal == "" then
            HudRef.weaponPrestigeWidget = CoD.prestigeRewardWidget_v2.new(HudRef, InstanceRef)
            HudRef:addElement(HudRef.weaponPrestigeWidget)
        elseif HudRef.weaponPrestigeWidget then
            HudRef.weaponPrestigeWidget:close()
            HudRef.weaponPrestigeWidget = nil
        end
    end

    HudRef:subscribeToGlobalModel(InstanceRef, "CurrentWeapon", "weaponPrestigeUI3DText", WeaponPrestigeCallback)

    local function KillstreakActivated(ModelRef)
        if Engine.GetModelValue(ModelRef) == 1.0 and not HudRef.ArmDeviceWidget then
            local function TimerCallback()
                HudRef.delayUI3DTimer = nil
                HudRef.ArmDeviceWidget = CoD.ArmDeviceWidget.new(HudRef, TimerCallback)
                HudRef:addElement(HudRef.ArmDeviceWidget)
                HudRef.ArmDeviceWidget.ArmDeviceWidgetInternal:playClip("Activate")
            end

            HudRef.delayUI3DTimer = LUI.UITimer.newElementTimer(0.000000, true, TimerCallback)
            HudRef:addElement(HudRef.delayUI3DTimer)
        elseif HudRef.ArmDeviceWidget then
            local function ArmClipOver(SenderObj, EventObj)
                HudRef.ArmDeviceWidget:close()
                HudRef.ArmDeviceWidget = nil
            end

            HudRef.ArmDeviceWidget.ArmDeviceWidgetInternal:playClip("Deactivate")
            HudRef.ArmDeviceWidget.ArmDeviceWidgetInternal:registerEventHandler("clip_over", ArmClipOver)
        end
    end

    HudRef:subscribeToModel(Engine.CreateModel(Engine.GetModelForController(InstanceRef), "hudItems.killstreakActivated"), KillstreakActivated)

    local function RemoteKillstreakActivated(ModelRef)
        if Engine.GetModelValue(ModelRef) == 1.0 and not Engine.IsVisibilityBitSet(InstanceRef, Enum.UIVisibilityBit.BIT_SELECTING_LOCATION) then
            HudRef.genericProjectedTablet = CoD.GenericProjectedTablet.new(HudRef, InstanceRef)
            HudRef.genericProjectedTablet.GenericProjectedTabletInternal:setState("DefaultState")
            HudRef:addElement(HudRef.genericProjectedTablet)
        elseif HudRef.genericProjectedTablet then
            HudRef.genericProjectedTablet:close()
            HudRef.genericProjectedTablet = nil
        end
    end

    HudRef:subscribeToModel(Engine.CreateModel(Engine.GetModelForController(InstanceRef), "hudItems.remoteKillstreakActivated"), RemoteKillstreakActivated)

    -- Prepare to calculate team counts
    local ScoreTeamCount = 6.0

    if 1.0 < Engine.GetCurrentTeamCount() then
        ScoreTeamCount = math.max(Engine.GetScoreboardTeamClientCount(Enum.team_t.TEAM_ALLIES), Engine.GetScoreboardTeamClientCount(Enum.team_t.TEAM_AXIS))
    end

    if 6.0 < ScoreTeamCount then
        HudRef.ScoreboardWidget:setTopBottom(true, false, 120.000000, 684.000000)
    end

    local function UpdateTeamScore(ModelRef)
        CoD.ScoreboardUtility.UpdateScoreboardTeamScores(InstanceRef)
    end

    HudRef:subscribeToModel(Engine.CreateModel(Engine.GetModelForController(InstanceRef), "updateScoreboard"), UpdateTeamScore)

    HudRef.SafeAreaContainer.navigation = nil
    HudRef.ScoreboardWidget.navigation = nil

    local function ArmBladeCallback(ModelRef)
        if HudRef.armbladeOpenSubscription then
            HudRef:removeSubscription(HudRef.armbladeOpenSubscription)
            HudRef.armbladeOpenSubscription = nil
        end

        if HudRef.armbladeCloseSubscription then
            HudRef:removeSubscription(HudRef.armbladeCloseSubscription)
            HudRef.armbladeCloseSubscription = nil
            if HudRef.armbladeReticles then
                for i, v in ipairs(HudRef.armbladeReticles) do
                    v:close()
                end
                HudRef.armbladeReticles = nil
            end
        end

        if ModelRef and Engine.GetModelValue(ModelRef) == "WEAPON_HERO_ARMBLADE" then
            local function ArmBladeInUseCallback(ModelRef2)
                if not Engine.GetModelValue(ModelRef2) and HudRef.armbladeReticles then
                    for i, v in ipairs(HudRef.armbladeReticles) do
                        v:close()
                    end
                    HudRef.armbladeReticles = nil
                    local ArmbladeModel =  Engine.GetModel(Engine.GetModelForController(InstanceRef), "ArmbladeReticles")
                    if ArmbladeModel then
                        Engine.UnsubscribeAndFreeModel(ArmbladeModel)
                    end
                end
            end

            HudRef.armbladeCloseSubscription = HudRef:subscribeToGlobalModel(InstanceRef, "PerController", "playerAbilities.playerGadget3.isInUse", ArmBladeInUseCallback)

            local function ArmBladePowerCallback(ModelRef2)
                if 1.0 <= Engine.GetModelValue(ModelRef2) and not HudRef.armbladeReticles then
                    local RipperRetModel = Engine.CreateModel(Engine.GetModelForController(InstanceRef), "ArmbladeReticles")
                    HudRef.armbladeReticles = {}

                    local KeepAddingTargets = true

                    while KeepAddingTargets do
                        local RipperWidget = CoD.RipperLockReticle.new(HudRef, InstanceRef)
                        local RipperModel = Engine.CreateModel(RipperRetModel, #HudRef.armbladeReticles) -- # Syntax = length of object

                        LUI.CreateModelsAndInitialize(RipperModel, {status = 0.0})

                        RipperWidget:setModel(RipperModel)
                        RipperWidget:processEvent({name = "update_state", controller = InstanceRef, menu = HudRef})
                        KeepAddingTargets = RipperWidget:setupArmBladeTarget(HudRef, #HudRef.armbladeReticles)

                        table.insert(HudRef.armbladeReticles, RipperWidget)
                        HudRef.fullscreenContainer:addElement(RipperWidget)
                    end
                end
            end

            HudRef.armbladeOpenSubscription = HudRef:subscribeToGlobalModel(InstanceRef, "PerController", "playerAbilities.playerGadget3.powerRatio", ArmBladePowerCallback)
        end
    end

    HudRef.SafeAreaContainer.ScrStkContainer:hide()

    HudRef:subscribeToGlobalModel(InstanceRef, "PerController", "playerAbilities.playerGadget3.name", ArmBladeCallback)
end

function LUI.createMenu.T7Hud_MP(InstanceRef)
    local HudRef = CoD.Menu.NewForUIEditor("T7Hud_MP")

    if PreLoadCallback then
        PreLoadCallback(HudRef, InstanceRef)
    end

    HudRef.soundSet = "HUD"
    HudRef:setOwner(InstanceRef)
    HudRef:setLeftRight(true, true, 0, 0)
    HudRef:setTopBottom(true, true, 0, 0)
    HudRef:playSound("menu_open", InstanceRef)

    HudRef.buttonModel = Engine.CreateModel(Engine.GetModelForController(InstanceRef), "T7Hud_MP.buttonPrompts")
    HudRef.anyChildUsesUpdateState = true

    -- This actually houses most of the controls on the MP hud, including score, map, ammo, etc
    local SafeAreaWidget = CoD.T7Hud_MP_SafeAreaContainer.new(HudRef, InstanceRef)
    SafeAreaWidget:setLeftRight(false, false, -640.000000, 640.000000)
    SafeAreaWidget:setTopBottom(false, false, -360.000000, 360.000000)

    local function SafeAreaLoaded(SenderObj, EventObj)
        SizeToSafeArea(SenderObj, InstanceRef)
        return SenderObj:dispatchEventToChildren(EventObj)
    end

    SafeAreaWidget:registerEventHandler("menu_loaded", SafeAreaLoaded)

    HudRef:addElement(SafeAreaWidget)
    HudRef.SafeAreaContainer = SafeAreaWidget

    local ReadyEventsWidget = CoD.ReadyEvents.new(HudRef, InstanceRef)
    ReadyEventsWidget:setLeftRight(false, false, -200.000000, 200.000000)
    ReadyEventsWidget:setTopBottom(false, true, -178.000000, -58.000000)

    local function ReadyEventCallback(ModelRef)
        if IsParamModelEqualToString(ModelRef, "hero_weapon_received") then
            -- User has their special ability
            AddHeroAbilityReceivedNotification(HudRef, ReadyEventsWidget, InstanceRef, ModelRef)
        elseif IsParamModelEqualToString(ModelRef, "killstreak_received") then
            -- User has gotten a killstreak
            AddKillstreakReceivedNotification(HudRef, ReadyEventsWidget, InstanceRef, ModelRef)
        end
    end

    ReadyEventsWidget:subscribeToGlobalModel(InstanceRef, "PerController", "scriptNotify", ReadyEventCallback)

    HudRef:addElement(ReadyEventsWidget)
    HudRef.ReadyEvents = ReadyEventsWidget

    local MpScoreWidget = CoD.MPScr.new(HudRef, InstanceRef)
    MpScoreWidget:setLeftRight(false, false, -50.000000, 50.000000)
    MpScoreWidget:setTopBottom(true, false, 233.500000, 258.500000)

    local function MpScoreCallback(ModelRef)
        if IsParamModelEqualToString(ModelRef, "score_event") then
            if HasPerk(InstanceRef, "specialty_combat_efficiency") then
                PlayClipOnElement(HudRef, {elementName = "MPScore", clipName = "CombatEfficiencyScore"}, InstanceRef)
                SetMPScoreText(HudRef, MpScoreWidget, InstanceRef, ModelRef)
            else
                PlayClipOnElement(HudRef, {elementName = "MPScore", clipName = "NormalScore"}, InstanceRef)
                SetMPScoreText(HudRef, MpScoreWidget, InstanceRef, ModelRef)
            end
        end
    end

    MpScoreWidget:subscribeToGlobalModel(InstanceRef, "PerController", "scriptNotify", MpScoreCallback)

    HudRef:addElement(MpScoreWidget)
    HudRef.MPScore = MpScoreWidget

    local GFScoreWidget = CoD.GFScoreContainer.new(HudRef, InstanceRef)
    --GFScoreWidget:subscribeToGlobalModel(InstanceRef, "PerController", "scriptNotify", MpScoreCallback)

    HudRef:addElement(GFScoreWidget)
    HudRef.GFScore = GFScoreWidget


    local DynamicWidget = CoD.DynamicContainerWidget.new(HudRef, InstanceRef)
    DynamicWidget:setLeftRight(true, true, 0.000000, 0.000000)
    DynamicWidget:setTopBottom(true, true, 0.000000, 0.000000)

    HudRef:addElement(DynamicWidget)
    HudRef.fullscreenContainer = DynamicWidget

    local MpFeedbackWidget = CoD.MPDamageFeedback.new(HudRef, InstanceRef)
    MpFeedbackWidget:setLeftRight(false, false, -20.000000, 20.000000)
    MpFeedbackWidget:setTopBottom(false, false, -20.000000, 20.000000)

    local function MpFeedbackCallback(ModelRef)
        MpFeedbackWidget:setModel(ModelRef, InstanceRef)
    end

    MpFeedbackWidget:subscribeToGlobalModel(InstanceRef, "CurrentWeapon", nil, MpFeedbackCallback)

    HudRef:addElement(MpFeedbackWidget)
    HudRef.MPDamageFeedback0 = MpFeedbackWidget

    local OutcomeWidget = CoD.Outcome.new(HudRef, InstanceRef)
    OutcomeWidget:setLeftRight(true, true, 0.000000, 0.000000)
    OutcomeWidget:setTopBottom(true, true, 0.000000, 0.000000)
    OutcomeWidget:setAlpha(0.000000)

    HudRef:addElement(OutcomeWidget)
    HudRef.Outcome = OutcomeWidget

    local Top3Widget = CoD.Top3PlayersScreenWidget.new(HudRef, InstanceRef)
    Top3Widget:setLeftRight(true, true, 0.000000, 0.000000)
    Top3Widget:setTopBottom(true, true, 0.000000, 0.000000)
    Top3Widget:setAlpha(0.000000)

    HudRef:addElement(Top3Widget)
    HudRef.Top3PlayersScreenWidget = Top3Widget

    local ScoreWidget = CoD.ScoreboardWidget.new(HudRef, InstanceRef)
    ScoreWidget:setLeftRight(false, false, -518.000000, 488.000000)
    ScoreWidget:setTopBottom(true, false, 163.500000, 806.500000)

    HudRef:addElement(ScoreWidget)
    HudRef.ScoreboardWidget = ScoreWidget

    local ChatWidget = CoD.IngameChatClientContainer.new(HudRef, InstanceRef)
    ChatWidget:setLeftRight(true, false, 0.000000, 360.000000)
    ChatWidget:setTopBottom(true, false, -2.500000, 717.500000)

    HudRef:addElement(ChatWidget)
    HudRef.IngameChatClientContainer = ChatWidget

    -- Begin hud state conditions, used for various Mp States (Hides a lot of stuff)
    SafeAreaWidget.navigation = {left = ScoreWidget, down = ScoreWidget}
    Top3Widget.navigation = {left = ScoreWidget, down = ScoreWidget}
    ScoreWidget.navigation = {up = {SafeAreaWidget, Top3Widget}, right = {SafeAreaWidget, Top3Widget}}

    local DefaultStateClip = {
        DefaultClip = function()
            HudRef:setupElementClipCounter(2.000000)
            ReadyEventsWidget:completeAnimation()
            HudRef.ReadyEvents:setAlpha(1.000000)
            HudRef.clipFinished(ReadyEventsWidget, {})
            MpScoreWidget:completeAnimation()
            HudRef.MPScore:setAlpha(1.000000)
            HudRef.clipFinished(MpScoreWidget, {})
        end,
        SpeedBoost = function()
            HudRef:setupElementClipCounter(0.000000)
        end
    }

    local HideAllButScoreboardClip = {
        DefaultClip = function()
            HudRef:setupElementClipCounter(2.000000)
            ReadyEventsWidget:completeAnimation()
            HudRef.ReadyEvents:setAlpha(0.000000)
            HudRef.clipFinished(ReadyEventsWidget, {})
            MpScoreWidget:completeAnimation()
            HudRef.MPScore:setAlpha(0.000000)
            HudRef.clipFinished(MpScoreWidget, {})
        end
    }

    local SpeedBoostClip = {
        DefaultClip = function()
            HudRef:setupElementClipCounter(0.000000)
        end,
        DefaultState = function()
            HudRef:setupElementClipCounter(0.000000)
        end
    }

    local HideForCodCasterClip = {
        DefaultClip = function()
            HudRef:setupElementClipCounter(1.000000)
            MpScoreWidget:completeAnimation()
            HudRef.MPScore:setAlpha(0.000000)
            HudRef.clipFinished(MpScoreWidget, {})
        end
    }

    HudRef.clipsPerState = {DefaultState = DefaultStateClip, HideAllButScoreboard = HideAllButScoreboardClip, SpeedBoost = SpeedBoostClip, HideForCodCaster = HideForCodCasterClip}

    local function HideAllButScoreboardState(Unk1, Unk2, Unk3)
        if not Engine.IsVisibilityBitSet(InstanceRef, Enum.UIVisibilityBit.BIT_FINAL_KILLCAM) and not
        Engine.IsVisibilityBitSet(InstanceRef, Enum.UIVisibilityBit.BIT_ROUND_END_KILLCAM) and not
        Engine.IsVisibilityBitSet(InstanceRef, Enum.UIVisibilityBit.BIT_GAME_ENDED) then
            return Engine.IsVisibilityBitSet(InstanceRef, Enum.UIVisibilityBit.BIT_IN_KILLCAM)
        end
    end

    local function SpeedBoostState(Unk1, Unk2, Unk3)
        if IsHeroWeaponOrGadgetInUse(Unk1, InstanceRef) then
            return IsHeroWeaponSpeedBurst(Unk1, InstanceRef)
        end
    end

    local function HideForCodCasterState(Unk1, Unk2, Unk3)
        if IsCodCaster(InstanceRef) then
            return not IsCodCasterProfileValueEqualTo(InstanceRef, "shoutcaster_qs_playerhud", 1.000000)
        end
    end

    HudRef:mergeStateConditions({{stateName = "HideAllButScoreboard", condition = HideAllButScoreboardState}, {stateName = "SpeedBoost", condition = SpeedBoostState}, {stateName = "HideForCodCaster", condition = HideForCodCasterState}})

    local function HudBitFinalKillcam(ModelRef)
        HudRef:updateElementState(HudRef, {name = "model_validation",
            menu = HudRef, modelValue = Engine.GetModelValue(ModelRef),
            modelName = "UIVisibilityBit." .. Enum.UIVisibilityBit.BIT_FINAL_KILLCAM})
    end

    local function HudBitRoundEndKillcam(ModelRef)
        HudRef:updateElementState(HudRef, {name = "model_validation",
            menu = HudRef, modelValue = Engine.GetModelValue(ModelRef),
            modelName = "UIVisibilityBit." .. Enum.UIVisibilityBit.BIT_ROUND_END_KILLCAM})
    end

    local function HudBitGameEnded(ModelRef)
        HudRef:updateElementState(HudRef, {name = "model_validation",
            menu = HudRef, modelValue = Engine.GetModelValue(ModelRef),
            modelName = "UIVisibilityBit." .. Enum.UIVisibilityBit.BIT_GAME_ENDED})
    end

    local function HudBitInKillcam(ModelRef)
        HudRef:updateElementState(HudRef, {name = "model_validation",
            menu = HudRef, modelValue = Engine.GetModelValue(ModelRef),
            modelName = "UIVisibilityBit." .. Enum.UIVisibilityBit.BIT_IN_KILLCAM})
    end

    local function HudCurrentWeapon(ModelRef)
        HudRef:updateElementState(HudRef, {name = "model_validation",
            menu = HudRef, modelValue = Engine.GetModelValue(ModelRef),
            modelName = "currentWeapon.weapon"})
    end

    local function HudGadgetInUse(ModelRef)
        HudRef:updateElementState(HudRef, {name = "model_validation",
            menu = HudRef, modelValue = Engine.GetModelValue(ModelRef),
            modelName = "playerAbilities.playerGadget3.isInUse"})
    end

    local function HudGadgetName(ModelRef)
        HudRef:updateElementState(HudRef, {name = "model_validation",
            menu = HudRef, modelValue = Engine.GetModelValue(ModelRef),
            modelName = "playerAbilities.playerGadget3.name"})
    end

    local function HudIsCodCaster(ModelRef)
        HudRef:updateElementState(HudRef, {name = "model_validation",
            menu = HudRef, modelValue = Engine.GetModelValue(ModelRef),
            modelName = "factions.isCoDCaster"})
    end

    local function HudCodCasterProfile(ModelRef)
        HudRef:updateElementState(HudRef, {name = "model_validation",
            menu = HudRef, modelValue = Engine.GetModelValue(ModelRef),
            modelName = "CodCaster.profileSettingsUpdated"})
    end

    HudRef:subscribeToModel(Engine.GetModel(Engine.GetModelForController(InstanceRef), "UIVisibilityBit." .. Enum.UIVisibilityBit.BIT_FINAL_KILLCAM), HudBitFinalKillcam)
    HudRef:subscribeToModel(Engine.GetModel(Engine.GetModelForController(InstanceRef), "UIVisibilityBit." .. Enum.UIVisibilityBit.BIT_ROUND_END_KILLCAM), HudBitRoundEndKillcam)
    HudRef:subscribeToModel(Engine.GetModel(Engine.GetModelForController(InstanceRef), "UIVisibilityBit." .. Enum.UIVisibilityBit.BIT_GAME_ENDED), HudBitGameEnded)
    HudRef:subscribeToModel(Engine.GetModel(Engine.GetModelForController(InstanceRef), "UIVisibilityBit." .. Enum.UIVisibilityBit.BIT_IN_KILLCAM), HudBitInKillcam)
    HudRef:subscribeToModel(Engine.GetModel(Engine.GetModelForController(InstanceRef), "currentWeapon.weapon"), HudCurrentWeapon)
    HudRef:subscribeToModel(Engine.GetModel(Engine.GetModelForController(InstanceRef), "playerAbilities.playerGadget3.isInUse"), HudGadgetInUse)
    HudRef:subscribeToModel(Engine.GetModel(Engine.GetModelForController(InstanceRef), "playerAbilities.playerGadget3.name"), HudGadgetName)
    HudRef:subscribeToModel(Engine.GetModel(Engine.GetModelForController(InstanceRef), "factions.isCoDCaster"), HudIsCodCaster)
    HudRef:subscribeToModel(Engine.GetModel(Engine.GetModelForController(InstanceRef), "CodCaster.profileSettingsUpdated"), HudCodCasterProfile)

    CoD.Menu.AddNavigationHandler(HudRef, HudRef, InstanceRef)

    SafeAreaWidget.id = "SafeAreaContainer"
    Top3Widget:setModel(HudRef.buttonModel, InstanceRef)
    Top3Widget.id = "Top3PlayersScreenWidget"
    ScoreWidget:setModel(HudRef.buttonModel, InstanceRef)
    ScoreWidget.id = "ScoreboardWidget"

    HudRef:processEvent({name = "menu_loaded", controller = InstanceRef})
    HudRef:processEvent({name = "update_state", menu = HudRef})

    if not HudRef:restoreState() then
        HudRef.ScoreboardWidget:processEvent({name = "gain_focus", controller = InstanceRef})
    end

    local function HudCloseCallback(SenderObj)
		SenderObj.GFScore:close()
        SenderObj.SafeAreaContainer:close()
        SenderObj.ReadyEvents:close()
        SenderObj.MPScore:close()
        SenderObj.fullscreenContainer:close()
        SenderObj.MPDamageFeedback0:close()
        SenderObj.Top3PlayersScreenWidget:close()
        SenderObj.ScoreboardWidget:close()
        SenderObj.IngameChatClientContainer:close()

        Engine.GetModel(Engine.GetModelForController(InstanceRef), "T7Hud_MP.buttonPrompts")
        Engine.UnsubscribeAndFreeModel()
    end

    LUI.OverrideFunction_CallOriginalSecond(HudRef, "close", HudCloseCallback)

    if PostLoadCallback then
        PostLoadCallback(HudRef, InstanceRef)
    end

    return HudRef
end