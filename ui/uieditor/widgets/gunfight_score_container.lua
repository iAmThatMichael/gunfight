CoD.GFScoreContainer = InheritFrom(LUI.UIElement)

function CoD.GFScoreContainer.new(HudRef, InstanceRef)
    local GFScoreBaseWidget = LUI.UIElement.new()
    GFScoreBaseWidget:setClass(CoD.GFScoreContainer)
    GFScoreBaseWidget.id = "GFScoreContainer"
    GFScoreBaseWidget.soundSet = "default"
	GFScoreBaseWidget:setLeftRight(true, true, 0, 0)
	GFScoreBaseWidget:setTopBottom(true, true, 0, 0)

	-- local SituationText = LUI.UIText.new(GFScoreBaseWidget, InstanceRef)
	-- SituationText:setLeftRight(false, false, -20, 20)
	-- SituationText:setTopBottom(true, false, 12, 37)
	-- SituationText:setText("TIED")
	-- SituationText:setTTF("fonts/FoundryGridnik-Bold.ttf")

	-- GFScoreBaseWidget:addElement(SituationText)

	local CACImage = RegisterImage("uie_img_t7_menu_customclass_plus")
	local PlayerImage = RegisterImage("hud_obit_mannequin")
	local ShadowImage = RegisterImage("lui_bottomshadow")
	local GridImage = RegisterImage("uie_dots_gridframe")
	local White = RegisterImage("$white")

	local TotalPlayers = 4 -- getdvar com_maxclients (?) or new value from script instead of seeing total players
	local PlayersPerTeam = TotalPlayers/2

	local GameModeIcon = LUI.UIImage.new(GFScoreBaseWidget, InstanceRef)
	GameModeIcon:setLeftRight(false, false, -30, 30)
	GameModeIcon:setTopBottom(true, false, 5, 65)
	GameModeIcon:setImage(RegisterImage("playlist_generic_03"))

	GFScoreBaseWidget:addElement(GameModeIcon)

	-- Friendly Team HUD

	local TeamFriendHealthBar = LUI.UIImage.new(GFScoreBaseWidget, InstanceRef)
	TeamFriendHealthBar:setLeftRight(false, false, -60, -157)
	TeamFriendHealthBar:setTopBottom(true, false, 28, 35)
	TeamFriendHealthBar:setImage(White)
	TeamFriendHealthBar:setRGB(0.28, 0.72, 1)

	local TeamFriendHealthBarShadow = LUI.UIImage.new(GFScoreBaseWidget, InstanceRef)
	TeamFriendHealthBarShadow:setLeftRight(false, false, -58, -157)
	TeamFriendHealthBarShadow:setTopBottom(true, false, 28, 37)
	TeamFriendHealthBarShadow:setImage(ShadowImage)

	local TeamFriendHealthBarGrid = LUI.UIImage.new(GFScoreBaseWidget, InstanceRef)
	TeamFriendHealthBarGrid:setLeftRight(false, false, -60, -157)
	TeamFriendHealthBarGrid:setTopBottom(true, false, 28, 35)
	TeamFriendHealthBarGrid:setImage(GridImage)

	GFScoreBaseWidget:addElement(TeamFriendHealthBarShadow)
	GFScoreBaseWidget:addElement(TeamFriendHealthBar)
	GFScoreBaseWidget:addElement(TeamFriendHealthBarGrid)

	local TeamFriendHealthPlus = LUI.UIImage.new(GFScoreBaseWidget, InstanceRef)
	TeamFriendHealthPlus:setLeftRight(false, false, -141, -157)
	TeamFriendHealthPlus:setTopBottom(true, false, 10, 26)
	TeamFriendHealthPlus:setImage(CACImage)

	GFScoreBaseWidget:addElement(TeamFriendHealthPlus)

	local TeamFriendHealthText = LUI.UIText.new(GFScoreBaseWidget, InstanceRef)
	TeamFriendHealthText:setLeftRight(true, false, 505, 515)
	TeamFriendHealthText:setTopBottom(true, false, 11, 31)
	TeamFriendHealthText:setText("200")
	TeamFriendHealthText:setTTF("fonts/FoundryGridnik-Bold.ttf")

	local TeamFriendHealthTextShadow = LUI.UIImage.new(GFScoreBaseWidget, InstanceRef)
	TeamFriendHealthTextShadow:setLeftRight(true, false, 505, 535)
	TeamFriendHealthTextShadow:setTopBottom(true, false, 11, 26)
	TeamFriendHealthTextShadow:setImage(ShadowImage)
	TeamFriendHealthTextShadow:setAlpha(0.5)

	GFScoreBaseWidget:addElement(TeamFriendHealthTextShadow)
	GFScoreBaseWidget:addElement(TeamFriendHealthText)

	-- TODO: clean up lives on both ends possibly make it one function somehow?
	GFScoreBaseWidget.FriendlyLives = {}

	for i = 0, PlayersPerTeam-1 do
		local PlayerIcon = LUI.UIImage.new(GFScoreBaseWidget, InstanceRef)
		PlayerIcon:setLeftRight(false, false, 0 - (60 + (15*i)), 0 - (80 + (15*i)))
		PlayerIcon:setTopBottom(true, false, 8, 28)
		PlayerIcon:setImage(PlayerImage)
		PlayerIcon:setRGB(0.28, 0.72, 1)
		PlayerIcon:setAlpha(1)
		-- add into the widget now
		GFScoreBaseWidget:addElement(PlayerIcon)
		GFScoreBaseWidget.FriendlyLives[i] = PlayerIcon
	end

	GFScoreBaseWidget.EnemyLives = {}

	for i = 0, PlayersPerTeam-1 do
		local PlayerIcon = LUI.UIImage.new(GFScoreBaseWidget, InstanceRef)
		PlayerIcon:setLeftRight(false, false, 60 + (15*i), 80 + (15*i))
		PlayerIcon:setTopBottom(true, false, 8, 28)
		PlayerIcon:setImage(PlayerImage)
		PlayerIcon:setRGB(1, 0.39, 0.30)
		PlayerIcon:setAlpha(1)
		-- add into the widget now
		GFScoreBaseWidget:addElement(PlayerIcon)
		GFScoreBaseWidget.EnemyLives[i] = PlayerIcon
	end

	local FriendlyHealth = Engine.CreateModel(Engine.GetModelForController(InstanceRef), "hudItems.gffriendlyteam_health_num")
	local FriendlyTeamSize = Engine.CreateModel(Engine.GetModelForController(InstanceRef), "hudItems.gffriendlyteam_size_num")

	local function TeamFriendlyFunc(ModelRef)
		-- store the updated values
		local HealthValue = Engine.GetModelValue(FriendlyHealth)
		local TeamValue = Engine.GetModelValue(FriendlyTeamSize)
		-- ensure hud exists
		if FriendlyHealth and FriendlyTeamSize then
			-- update text
			TeamFriendHealthText:setText(Engine.Localize(HealthValue))
			-- foreach of the player icons do stuff
			for i = 0, PlayersPerTeam-1 do
				if TeamValue > i  then
					GFScoreBaseWidget.FriendlyLives[i]:setAlpha(1)
				else
					GFScoreBaseWidget.FriendlyLives[i]:beginAnimation("keyframe", 250.000000, true, true, CoD.TweenType.Linear)
					GFScoreBaseWidget.FriendlyLives[i]:setAlpha(0)
				end
			end

			if HealthValue <= 0 then
				TeamFriendHealthBar:setAlpha(0)
				return
			else
				TeamFriendHealthBar:setAlpha(1)
			end

			TeamFriendHealthBar:setLeftRight(false, false, -157 + (97 * (HealthValue / 200)), -157)
		end
	end

	Engine.SetModelValue(FriendlyHealth, 0)
	Engine.SetModelValue(FriendlyTeamSize, 0)

	GFScoreBaseWidget:subscribeToModel(FriendlyHealth, TeamFriendlyFunc)
	GFScoreBaseWidget:subscribeToModel(FriendlyTeamSize, TeamFriendlyFunc)

	-- Enemy Team HUD

	local TeamEnemyHealthBar = LUI.UIImage.new(GFScoreBaseWidget, InstanceRef)
	TeamEnemyHealthBar:setLeftRight(false, false, 60, 157)
	TeamEnemyHealthBar:setTopBottom(true, false, 28, 35)
	TeamEnemyHealthBar:setImage(White)
	TeamEnemyHealthBar:setRGB(1, 0.39, 0.30)

	local TeamEnemyHealthBarShadow = LUI.UIImage.new(GFScoreBaseWidget, InstanceRef)
	TeamEnemyHealthBarShadow:setLeftRight(false, false, 58, 157)
	TeamEnemyHealthBarShadow:setTopBottom(true, false, 28, 37)
	TeamEnemyHealthBarShadow:setImage(ShadowImage)

	local TeamEnemyHealthBarGrid = LUI.UIImage.new(GFScoreBaseWidget, InstanceRef)
	TeamEnemyHealthBarGrid:setLeftRight(false, false, 60, 157)
	TeamEnemyHealthBarGrid:setTopBottom(true, false, 28, 35)
	TeamEnemyHealthBarGrid:setImage(GridImage)

	GFScoreBaseWidget:addElement(TeamEnemyHealthBarShadow)
	GFScoreBaseWidget:addElement(TeamEnemyHealthBar)
	GFScoreBaseWidget:addElement(TeamEnemyHealthBarGrid)

	local TeamEnemyHealthPlus = LUI.UIImage.new(GFScoreBaseWidget, InstanceRef)
	TeamEnemyHealthPlus:setLeftRight(false, false, 141, 157)
	TeamEnemyHealthPlus:setTopBottom(true, false, 10, 26)
	TeamEnemyHealthPlus:setImage(CACImage)

	GFScoreBaseWidget:addElement(TeamEnemyHealthPlus)

	local TeamEnemyHealthText = LUI.UIText.new(GFScoreBaseWidget, InstanceRef)
	TeamEnemyHealthText:setLeftRight(false, true, -515, -505)
	TeamEnemyHealthText:setTopBottom(true, false, 11, 31)
	TeamEnemyHealthText:setText("200")
	TeamEnemyHealthText:setTTF("fonts/FoundryGridnik-Bold.ttf")

	local TeamEnemyHealthTextShadow = LUI.UIImage.new(GFScoreBaseWidget, InstanceRef)
	TeamEnemyHealthTextShadow:setLeftRight(false, true, -535, -505)
	TeamEnemyHealthTextShadow:setTopBottom(true, false, 11, 26)
	TeamEnemyHealthTextShadow:setImage(ShadowImage)
	TeamEnemyHealthTextShadow:setAlpha(0.5)

	GFScoreBaseWidget:addElement(TeamEnemyHealthTextShadow)
	GFScoreBaseWidget:addElement(TeamEnemyHealthText)

	local EnemyHealth = Engine.CreateModel(Engine.GetModelForController(InstanceRef), "hudItems.gfenemyteam_health_num")
	local EnemyTeamSize = Engine.CreateModel(Engine.GetModelForController(InstanceRef), "hudItems.gfenemyteam_size_num")

	local function TeamEnemyFunc(ModelRef)
		-- store the updated values
		local HealthValue = Engine.GetModelValue(EnemyHealth)
		local TeamValue = Engine.GetModelValue(EnemyTeamSize)
		-- ensure hud exists
		if EnemyHealth and EnemyTeamSize then
			-- update text
			TeamEnemyHealthText:setText(Engine.Localize(HealthValue))
			-- foreach of the player icons do stuff
			for i = 0, PlayersPerTeam-1 do
				if TeamValue > i  then
					GFScoreBaseWidget.EnemyLives[i]:setAlpha(1)
				else
					GFScoreBaseWidget.EnemyLives[i]:beginAnimation("keyframe", 250.000000, true, true, CoD.TweenType.Linear)
					GFScoreBaseWidget.EnemyLives[i]:setAlpha(0)
				end
			end

			if HealthValue <= 0 then
				TeamEnemyHealthBar:setAlpha(0)
				return
			else
				TeamEnemyHealthBar:setAlpha(1)
			end

			TeamEnemyHealthBar:setLeftRight(false, false, 157 - (97 * (HealthValue / 200)), 157)
		end
	end

	Engine.SetModelValue(EnemyHealth, 0)
	Engine.SetModelValue(EnemyTeamSize, 0)

	GFScoreBaseWidget:subscribeToModel(EnemyHealth, TeamEnemyFunc)
	GFScoreBaseWidget:subscribeToModel(EnemyTeamSize, TeamEnemyFunc)

	GFScoreBaseWidget.StateTable = {
		{
			stateName = "Hidden",
				condition = function(arg0, InstanceRef, arg2)
				return Engine.IsVisibilityBitSet(InstanceRef, Enum.UIVisibilityBit.BIT_SCOREBOARD_OPEN) or
					Engine.IsVisibilityBitSet(InstanceRef, Enum.UIVisibilityBit.BIT_GAME_ENDED) or
					Engine.IsVisibilityBitSet(InstanceRef, Enum.UIVisibilityBit.BIT_UI_ACTIVE) or not
					Engine.IsVisibilityBitSet(InstanceRef, Enum.UIVisibilityBit.BIT_HUD_VISIBLE) or not
					Engine.IsVisibilityBitSet(InstanceRef, Enum.UIVisibilityBit.BIT_WEAPON_HUD_VISIBLE) or
					Engine.IsVisibilityBitSet(InstanceRef, Enum.UIVisibilityBit.BIT_FINAL_KILLCAM) or
					Engine.IsVisibilityBitSet(InstanceRef, Enum.UIVisibilityBit.BIT_ROUND_END_KILLCAM) or
					Engine.IsVisibilityBitSet(InstanceRef, Enum.UIVisibilityBit.BIT_IN_KILLCAM)
			end
		}
	}
	GFScoreBaseWidget:mergeStateConditions(GFScoreBaseWidget.StateTable)

	GFScoreBaseWidget.clipsPerState = {
		DefaultState = {
			DefaultClip = function()
				GFScoreBaseWidget:setupElementClipCounter(1)
				GFScoreBaseWidget:setAlpha(0)
				GFScoreBaseWidget:beginAnimation("keyframe", 100, false, false, CoD.TweenType.Linear)
				GFScoreBaseWidget:setAlpha(1)
			end
		},
		Hidden = {
			DefaultClip = function()
				GFScoreBaseWidget:setupElementClipCounter(1)
				GFScoreBaseWidget:setAlpha(1)
				GFScoreBaseWidget:beginAnimation("keyframe", 100, false, false, CoD.TweenType.Linear)
				GFScoreBaseWidget:setAlpha(0)
			end
		}
	}

    GFScoreBaseWidget:subscribeToModel(Engine.GetModel(Engine.GetModelForController(InstanceRef), "UIVisibilityBit." .. Enum.UIVisibilityBit.BIT_SCOREBOARD_OPEN), function()
        HudRef:updateElementState(GFScoreBaseWidget, {
            name = "model_validation",
            menu = HudRef,
            modelValue = Engine.GetModelValue(ModelRef),
            modelName = "UIVisibilityBit." .. Enum.UIVisibilityBit.BIT_SCOREBOARD_OPEN
        })
    end)

	GFScoreBaseWidget:subscribeToModel(Engine.GetModel(Engine.GetModelForController(InstanceRef), "UIVisibilityBit." .. Enum.UIVisibilityBit.BIT_GAME_ENDED), function(ModelRef)
		HudRef:updateElementState(GFScoreBaseWidget, {
			name = "model_validation",
			menu = HudRef,
			modelValue = Engine.GetModelValue(ModelRef),
			modelName = "UIVisibilityBit." .. Enum.UIVisibilityBit.BIT_GAME_ENDED
		})
	end)

	GFScoreBaseWidget:subscribeToModel(Engine.GetModel(Engine.GetModelForController(InstanceRef), "UIVisibilityBit." .. Enum.UIVisibilityBit.BIT_UI_ACTIVE), function(ModelRef)
		HudRef:updateElementState(GFScoreBaseWidget, {
			name = "model_validation",
			menu = HudRef,
			modelValue = Engine.GetModelValue(ModelRef),
			modelName = "UIVisibilityBit." .. Enum.UIVisibilityBit.BIT_UI_ACTIVE
		})
	end)

	GFScoreBaseWidget:subscribeToModel(Engine.GetModel(Engine.GetModelForController(InstanceRef), "UIVisibilityBit." .. Enum.UIVisibilityBit.BIT_WEAPON_HUD_VISIBLE), function(ModelRef)
		HudRef:updateElementState(GFScoreBaseWidget, {
			name = "model_validation",
			menu = HudRef,
			modelValue = Engine.GetModelValue(ModelRef),
			modelName = "UIVisibilityBit." .. Enum.UIVisibilityBit.BIT_WEAPON_HUD_VISIBLE
		})
	end)

	GFScoreBaseWidget:subscribeToModel(Engine.GetModel(Engine.GetModelForController(InstanceRef), "UIVisibilityBit." .. Enum.UIVisibilityBit.BIT_HUD_VISIBLE), function(ModelRef)
		HudRef:updateElementState(GFScoreBaseWidget, {
			name = "model_validation",
			menu = HudRef,
			modelValue = Engine.GetModelValue(ModelRef),
			modelName = "UIVisibilityBit." .. Enum.UIVisibilityBit.BIT_HUD_VISIBLE
		})
	end)

	GFScoreBaseWidget:subscribeToModel(Engine.GetModel(Engine.GetModelForController(InstanceRef), "UIVisibilityBit." .. Enum.UIVisibilityBit.BIT_FINAL_KILLCAM), function(ModelRef)
		HudRef:updateElementState(GFScoreBaseWidget, {
			name = "model_validation",
			menu = HudRef,
			modelValue = Engine.GetModelValue(ModelRef),
			modelName = "UIVisibilityBit." .. Enum.UIVisibilityBit.BIT_FINAL_KILLCAM
		})
	end)

	GFScoreBaseWidget:subscribeToModel(Engine.GetModel(Engine.GetModelForController(InstanceRef), "UIVisibilityBit." .. Enum.UIVisibilityBit.BIT_ROUND_END_KILLCAM), function(ModelRef)
		HudRef:updateElementState(GFScoreBaseWidget, {
			name = "model_validation",
			menu = HudRef,
			modelValue = Engine.GetModelValue(ModelRef),
			modelName = "UIVisibilityBit." .. Enum.UIVisibilityBit.BIT_ROUND_END_KILLCAM
		})
	end)

	GFScoreBaseWidget:subscribeToModel(Engine.GetModel(Engine.GetModelForController(InstanceRef), "UIVisibilityBit." .. Enum.UIVisibilityBit.BIT_IN_KILLCAM), function(ModelRef)
		HudRef:updateElementState(GFScoreBaseWidget, {
			name = "model_validation",
			menu = HudRef,
			modelValue = Engine.GetModelValue(ModelRef),
			modelName = "UIVisibilityBit." .. Enum.UIVisibilityBit.BIT_IN_KILLCAM
		})
	end)

	LUI.OverrideFunction_CallOriginalSecond(GFScoreBaseWidget, "close", function(GFScoreBaseWidget) end)

	return GFScoreBaseWidget
end