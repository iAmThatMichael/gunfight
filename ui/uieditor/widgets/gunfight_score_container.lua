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

	local GameModeIcon = LUI.UIImage.new(GFScoreBaseWidget, InstanceRef)
	GameModeIcon:setLeftRight(false, false, -30, 30)
	GameModeIcon:setTopBottom(true, false, 5, 65)
	GameModeIcon:setImage(RegisterImage("playlist_generic_03"))

	GFScoreBaseWidget:addElement(GameModeIcon)

	-- Friendly Team HUD

	local TeamFriendHealthBar = LUI.UIImage.new(GFScoreBaseWidget, InstanceRef)
	TeamFriendHealthBar:setLeftRight(false, false, -60, -157)
	TeamFriendHealthBar:setTopBottom(true, false, 28, 35)
	TeamFriendHealthBar:setImage(RegisterImage("$white"))
	TeamFriendHealthBar:setRGB(0.28, 0.72, 1)

	local TeamFriendHealthBarShadow = LUI.UIImage.new(GFScoreBaseWidget, InstanceRef)
	TeamFriendHealthBarShadow:setLeftRight(false, false, -58, -157)
	TeamFriendHealthBarShadow:setTopBottom(true, false, 28, 37)
	TeamFriendHealthBarShadow:setImage(RegisterImage("lui_bottomshadow"))

	local TeamFriendHealthBarGrid = LUI.UIImage.new(GFScoreBaseWidget, InstanceRef)
	TeamFriendHealthBarGrid:setLeftRight(false, false, -60, -157)
	TeamFriendHealthBarGrid:setTopBottom(true, false, 28, 35)
	TeamFriendHealthBarGrid:setImage(RegisterImage("uie_dots_gridframe"))

	GFScoreBaseWidget:addElement(TeamFriendHealthBarShadow)
	GFScoreBaseWidget:addElement(TeamFriendHealthBar)
	GFScoreBaseWidget:addElement(TeamFriendHealthBarGrid)

	local TeamFriendHealthPlus = LUI.UIImage.new(GFScoreBaseWidget, InstanceRef)
	TeamFriendHealthPlus:setLeftRight(false, false, -141, -157)
	TeamFriendHealthPlus:setTopBottom(true, false, 10, 26)
	TeamFriendHealthPlus:setImage(RegisterImage("uie_img_t7_menu_customclass_plus"))

	GFScoreBaseWidget:addElement(TeamFriendHealthPlus)

	local TeamFriendHealthText = LUI.UIText.new(GFScoreBaseWidget, InstanceRef)
	TeamFriendHealthText:setLeftRight(true, false, 505, 515)
	TeamFriendHealthText:setTopBottom(true, false, 11, 31)
	TeamFriendHealthText:setText("200")
	TeamFriendHealthText:setTTF("fonts/FoundryGridnik-Bold.ttf")

	local TeamFriendHealthTextShadow = LUI.UIImage.new(GFScoreBaseWidget, InstanceRef)
	TeamFriendHealthTextShadow:setLeftRight(true, false, 505, 535)
	TeamFriendHealthTextShadow:setTopBottom(true, false, 11, 26)
	TeamFriendHealthTextShadow:setImage(RegisterImage("lui_bottomshadow"))
	TeamFriendHealthTextShadow:setAlpha(0.5)

	GFScoreBaseWidget:addElement(TeamFriendHealthTextShadow)
	GFScoreBaseWidget:addElement(TeamFriendHealthText)

	local TeamFriendSize1 = LUI.UIImage.new(GFScoreBaseWidget, InstanceRef)
	TeamFriendSize1:setLeftRight(false, false, -60, -80)
	TeamFriendSize1:setTopBottom(true, false, 8, 28)
	TeamFriendSize1:setImage(RegisterImage("hud_obit_mannequin"))
	TeamFriendSize1:setRGB(0.28, 0.72, 1)

	GFScoreBaseWidget:addElement(TeamFriendSize1)

	local TeamFriendSize2 = LUI.UIImage.new(GFScoreBaseWidget, InstanceRef)
	TeamFriendSize2:setLeftRight(false, false, -75, -95)
	TeamFriendSize2:setTopBottom(true, false, 8, 28)
	TeamFriendSize2:setImage(RegisterImage("hud_obit_mannequin"))
	TeamFriendSize2:setRGB(0.28, 0.72, 1)

	GFScoreBaseWidget:addElement(TeamFriendSize2)

	local FriendlyHealth = Engine.GetModel(Engine.GetModelForController(InstanceRef), "hudItems.gffriendlyteam_health_num")
	local FriendlyTeamSize = Engine.GetModel(Engine.GetModelForController(InstanceRef), "hudItems.gffriendlyteam_size_num")

	local function TeamFriendlyFunc(ModelRef)
		if FriendlyHealth and FriendlyTeamSize and
		Engine.GetModelValue(FriendlyHealth) and Engine.GetModelValue(FriendlyTeamSize) then
			TeamFriendHealthText:setText(Engine.Localize(Engine.GetModelValue(FriendlyHealth)))

			if Engine.GetModelValue(FriendlyTeamSize) <= 0 then
				TeamFriendSize1:setAlpha(0)
				TeamFriendSize2:setAlpha(0)
			elseif Engine.GetModelValue(FriendlyTeamSize) == 1 then
				TeamFriendSize1:setAlpha(1)
				TeamFriendSize2:setAlpha(0)
			else
				TeamFriendSize1:setAlpha(1)
				TeamFriendSize2:setAlpha(1)
			end

			if Engine.GetModelValue(FriendlyHealth) <= 0 then
				TeamFriendHealthBar:setAlpha(0)
				return
			else
				TeamFriendHealthBar:setAlpha(1)
			end

			TeamFriendHealthBar:setLeftRight(false, false, -60 - (97 * (Engine.GetModelValue(FriendlyHealth) / 200)), -157)
		end
	end

	Engine.SetModelValue( Engine.CreateModel( Engine.GetModelForController(InstanceRef), "hudItems.gffriendlyteam_health_num" ), 0 )
	Engine.SetModelValue( Engine.CreateModel( Engine.GetModelForController(InstanceRef), "hudItems.gffriendlyteam_size_num" ), 0 )
	GFScoreBaseWidget:subscribeToModel(FriendlyHealth, TeamFriendlyFunc)
	GFScoreBaseWidget:subscribeToModel(FriendlyTeamSize, TeamFriendlyFunc)

	-- Enemy Team HUD

	local TeamEnemyHealthBar = LUI.UIImage.new(GFScoreBaseWidget, InstanceRef)
	TeamEnemyHealthBar:setLeftRight(false, false, 60, 157)
	TeamEnemyHealthBar:setTopBottom(true, false, 28, 35)
	TeamEnemyHealthBar:setImage(RegisterImage("$white"))
	TeamEnemyHealthBar:setRGB(1, 0.39, 0.30)

	local TeamEnemyHealthBarShadow = LUI.UIImage.new(GFScoreBaseWidget, InstanceRef)
	TeamEnemyHealthBarShadow:setLeftRight(false, false, 58, 157)
	TeamEnemyHealthBarShadow:setTopBottom(true, false, 28, 37)
	TeamEnemyHealthBarShadow:setImage(RegisterImage("lui_bottomshadow"))

	local TeamEnemyHealthBarGrid = LUI.UIImage.new(GFScoreBaseWidget, InstanceRef)
	TeamEnemyHealthBarGrid:setLeftRight(false, false, 60, 157)
	TeamEnemyHealthBarGrid:setTopBottom(true, false, 28, 35)
	TeamEnemyHealthBarGrid:setImage(RegisterImage("uie_dots_gridframe"))

	GFScoreBaseWidget:addElement(TeamEnemyHealthBarShadow)
	GFScoreBaseWidget:addElement(TeamEnemyHealthBar)
	GFScoreBaseWidget:addElement(TeamEnemyHealthBarGrid)

	local TeamEnemyHealthPlus = LUI.UIImage.new(GFScoreBaseWidget, InstanceRef)
	TeamEnemyHealthPlus:setLeftRight(false, false, 141, 157)
	TeamEnemyHealthPlus:setTopBottom(true, false, 10, 26)
	TeamEnemyHealthPlus:setImage(RegisterImage("uie_img_t7_menu_customclass_plus"))

	GFScoreBaseWidget:addElement(TeamEnemyHealthPlus)

	local TeamEnemyHealthText = LUI.UIText.new(GFScoreBaseWidget, InstanceRef)
	TeamEnemyHealthText:setLeftRight(false, true, -515, -505)
	TeamEnemyHealthText:setTopBottom(true, false, 11, 31)
	TeamEnemyHealthText:setText("200")
	TeamEnemyHealthText:setTTF("fonts/FoundryGridnik-Bold.ttf")

	local TeamEnemyHealthTextShadow = LUI.UIImage.new(GFScoreBaseWidget, InstanceRef)
	TeamEnemyHealthTextShadow:setLeftRight(false, true, -535, -505)
	TeamEnemyHealthTextShadow:setTopBottom(true, false, 11, 26)
	TeamEnemyHealthTextShadow:setImage(RegisterImage("lui_bottomshadow"))
	TeamEnemyHealthTextShadow:setAlpha(0.5)

	GFScoreBaseWidget:addElement(TeamEnemyHealthTextShadow)
	GFScoreBaseWidget:addElement(TeamEnemyHealthText)

	local TeamEnemySize1 = LUI.UIImage.new(GFScoreBaseWidget, InstanceRef)
	TeamEnemySize1:setLeftRight(false, false, 60, 80)
	TeamEnemySize1:setTopBottom(true, false, 8, 28)
	TeamEnemySize1:setImage(RegisterImage("hud_obit_mannequin"))
	TeamEnemySize1:setRGB(1, 0.39, 0.30)

	GFScoreBaseWidget:addElement(TeamEnemySize1)

	local TeamEnemySize2 = LUI.UIImage.new(GFScoreBaseWidget, InstanceRef)
	TeamEnemySize2:setLeftRight(false, false, 75, 95)
	TeamEnemySize2:setTopBottom(true, false, 8, 28)
	TeamEnemySize2:setImage(RegisterImage("hud_obit_mannequin"))
	TeamEnemySize2:setRGB(1, 0.39, 0.30)

	GFScoreBaseWidget:addElement(TeamEnemySize2)

	local EnemyHealth = Engine.GetModel(Engine.GetModelForController(InstanceRef), "hudItems.gfenemyteam_health_num")
	local EnemyTeamSize = Engine.GetModel(Engine.GetModelForController(InstanceRef), "hudItems.gfenemyteam_size_num")

	local function TeamEnemyFunc(ModelRef)
		if EnemyHealth and EnemyTeamSize and
		Engine.GetModelValue(EnemyHealth) and Engine.GetModelValue(EnemyTeamSize) then
			TeamEnemyHealthText:setText(Engine.Localize(Engine.GetModelValue(EnemyHealth)))

			if Engine.GetModelValue(EnemyTeamSize) <= 0 then
				TeamEnemySize1:setAlpha(0)
				TeamEnemySize2:setAlpha(0)
			elseif Engine.GetModelValue(EnemyTeamSize) == 1 then
				TeamEnemySize1:setAlpha(1)
				TeamEnemySize2:setAlpha(0)
			else
				TeamEnemySize1:setAlpha(1)
				TeamEnemySize2:setAlpha(1)
			end

			if Engine.GetModelValue(EnemyHealth) <= 0 then
				TeamEnemyHealthBar:setAlpha(0)
				return
			else
				TeamEnemyHealthBar:setAlpha(1)
			end

			TeamEnemyHealthBar:setLeftRight(false, false, 60 + (97 * (Engine.GetModelValue(EnemyHealth) / 200)), 157)
		end
	end

	Engine.SetModelValue( Engine.CreateModel( Engine.GetModelForController(InstanceRef), "hudItems.gfenemyteam_health_num" ), 0 )
	Engine.SetModelValue( Engine.CreateModel( Engine.GetModelForController(InstanceRef), "hudItems.gfenemyteam_size_num" ), 0 )
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
					Engine.IsVisibilityBitSet(InstanceRef, Enum.UIVisibilityBit.BIT_WEAPON_HUD_VISIBLE)
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

	LUI.OverrideFunction_CallOriginalSecond(GFScoreBaseWidget, "close", function(GFScoreBaseWidget) end)

	return GFScoreBaseWidget
end