local module = {}

module.__index = module

local TweenService = game:GetService("TweenService")
local openTime = 0.3

local function CircleIfy(obj)
	local corner = Instance.new("UICorner", obj)
	corner.CornerRadius = UDim.new(1,0)
	local aspectConstraint = Instance.new("UIAspectRatioConstraint", obj)
	local stroke = Instance.new("UIStroke", obj)
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
end

local function ComputeOffsets(ObjParent, scale, step, angle)
	
	local xAbs, yAbs = ObjParent.AbsoluteSize.X, ObjParent.AbsoluteSize.Y
	
	local buttonSize = math.min(xAbs, yAbs) * scale

	
	
	local spacing = buttonSize * 0.25

	local minDist = buttonSize + spacing

	local padding = 1.2
	local computedRad = (minDist / (2 * math.sin(step / 2))) * padding

	local closest = buttonSize/3
	local furthest = (math.min(xAbs, yAbs) / 2) - (buttonSize / 2) - 5

	local rad = math.clamp(computedRad, closest, furthest)

	local xOffset = math.cos(angle) * rad
	local yOffset = math.sin(angle) * rad
	
	return xOffset, yOffset
	
end

export type NormalButton = {
	func: () -> ();
	ButtonNumber: number;
	ButtonText: string
}

export type ToggleButton = {
	func: (toggled: boolean) -> ();
	ButtonNumber: number;
	ButtonText: string;
	ActiveText: string;
	ActiveColor: Color3;
	InitialState: boolean
}

-- // page maker \\

local pageMaker = {}
pageMaker.__index = pageMaker

function pageMaker.Start(ref)
	local self = setmetatable({}, pageMaker)
	
	self.ButtonConnections = {}
	
	self.ParentToLoad = ref.TopCircle
	
	return self
end

function pageMaker:MakePage(PageName: string, AmountOfItems: number, buttonScale: number)
	
	local prnt = self.ParentToLoad
	local slf = self
	
	local Obj = {}

	local Folder = Instance.new("Folder")
	Folder.Name = PageName

	local step = (math.pi * 2) / AmountOfItems

	for i=1,AmountOfItems do
		local angle = (i - 1) * step - (math.pi / 2)
		
		local TextButton = Instance.new("TextButton")
		TextButton.AnchorPoint = Vector2.new(0.5,0.5)
		TextButton.Size = UDim2.fromScale(buttonScale, buttonScale)
		TextButton.Name = i
		TextButton.TextScaled = true
		CircleIfy(TextButton)
		
		
		
		local buttonSize = math.min(prnt.AbsoluteSize.X, prnt.AbsoluteSize.Y) * buttonScale

		local xOffset, yOffset = ComputeOffsets(prnt, buttonScale, step, angle)
		TextButton.Position = UDim2.new(0.5,xOffset, 0.5, yOffset)
		local const = Instance.new("UIPadding")
		local ButtonPadding = buttonSize/10
		
		const.PaddingTop = UDim.new(0, ButtonPadding)
		const.PaddingLeft = UDim.new(0, ButtonPadding)
		const.PaddingBottom = UDim.new(0, ButtonPadding)
		const.PaddingRight = UDim.new(0, ButtonPadding)
		
		const.Parent = TextButton
		
		TextButton.Parent = Folder

	end
	
	function Obj:Load()
		if prnt:FindFirstChildOfClass("Folder") then
			prnt:FindFirstChildOfClass("Folder").Parent = nil
		end
		Folder.Parent = prnt
	end
	
	function Obj:UnLoad()
		Folder.Parent = nil
	end
	
	function Obj:AssignButtonFunction(buttonTbl: NormalButton)
		
		local button: TextButton = Folder[buttonTbl.ButtonNumber]
		
		if button then
			
			button.Text = buttonTbl.ButtonText or "Button"
			
			slf.ButtonConnections["Button_"..buttonTbl.ButtonNumber] = button.MouseButton1Down:Connect(buttonTbl.func)
			
		end
		
	end
	
	function Obj:AssignButtonToggle(buttonTbl: ToggleButton)
		
		local button: TextButton = Folder[buttonTbl.ButtonNumber]
		local defaultColor = button.BackgroundColor3
		
		if button then
			
			button.Text = buttonTbl.ButtonText or "toggle button"
			
			local toggled = buttonTbl.InitialState or false
		
			
			slf.ButtonConnections["Button_"..buttonTbl.ButtonNumber] = button.MouseButton1Down:Connect(function()
				toggled = not toggled
				if toggled then
					
					button.BackgroundColor3 = buttonTbl.ActiveColor or Color3.fromRGB(0,255)
					button.Text = buttonTbl.ActiveText or "Active"
					
				else
					
					button.BackgroundColor3 = defaultColor
					button.Text = buttonTbl.ButtonText
					
				end
				
				buttonTbl.func(toggled)
			end)
			
		end

	end
	
	function Obj:DisconnectButton(ButtonNumber: number)
		if slf.ButtonConnections["Button_"..ButtonNumber] then
			
			slf.ButtonConnections["Button_"..ButtonNumber]:Disconnect()
			slf.ButtonConnections["Button_"..ButtonNumber] = nil
			
		end
	end
	
	function Obj:RecalcLocations()
		for i=1, AmountOfItems do
			local button: TextButton = Folder[i]
			
			local angle = (i - 1) * step - (math.pi / 2)
			
			local xOffset, yOffset = ComputeOffsets(prnt, buttonScale, step, angle)
			
			button.Position = UDim2.new(0.5, xOffset, 0.5, yOffset)
			
		end
	end
	
	return Obj
	
end

-- // main module \\


function module.New()
	local top = game.Players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("ScreenGui")
--[[
	local succ, result = pcall(gethui)
	if succ then
	top = result
	end
	
	unbracket this when putting in exec
]]	
	
	local self = setmetatable({}, module)
	self.TopCircle = Instance.new("CanvasGroup", top)
	CircleIfy(self.TopCircle)
	self.TopCircle.Size = UDim2.fromScale(0.5,0.5)
	self.TopCircle.Visible = false
	self.TopCircle.AnchorPoint = Vector2.new(0.5,0.5)
	self.TopCircle.Position = UDim2.fromScale(0.5,0.5)
	self.TopCircle.Transparency = 0.5
	
	
	self.PageManager = pageMaker.Start(self)
	

	return self
	
end


function module:Open()
	
	self.TopCircle.Size = UDim2.fromScale(0,0)
	self.TopCircle.Visible = true
	
	TweenService:Create(self.TopCircle, TweenInfo.new(
		openTime,
		Enum.EasingStyle.Quad, 
		Enum.EasingDirection.Out),
		{Size = UDim2.fromScale(0.5,0.5)}):Play()

end

function module:Close()
	
	local tween = TweenService:Create(self.TopCircle, TweenInfo.new(
		openTime,
		Enum.EasingStyle.Quad, 
		Enum.EasingDirection.In),
		{Size = UDim2.fromScale(0,0)})
	
	tween:Play()
	tween.Completed:Wait()
	
	self.TopCircle.Visible = false
end

return module
