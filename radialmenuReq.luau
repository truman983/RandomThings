local module = {}

module.__index = module

local TweenService = game:GetService("TweenService")
local openTime = 0.3
local isOpen

local function CircleIfy(obj)
	local corner = Instance.new("UICorner", obj)
	corner.CornerRadius = UDim.new(1,0)
	local aspectConstraint = Instance.new("UIAspectRatioConstraint", obj)
end

local function ComputeOffsets(ObjParent, scale, step, angle, ClosestPixels: number)
	
	local xAbs, yAbs = ObjParent.AbsoluteSize.X, ObjParent.AbsoluteSize.Y
	
	local buttonSize = math.min(xAbs, yAbs) * scale

	
	
	local spacing = buttonSize * 0.25

	local minDist = buttonSize + spacing

	local padding = 1.2
	local computedRad = (minDist / (2 * math.sin(step / 2))) * padding

	local closest = 80
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
	self.PageTitle = ref.PageTitle
	
	return self
end

function pageMaker:MakePage(PageName: string, AmountOfItems: number, buttonScale: number)
	
	local prnt = self.ParentToLoad
	local slf = self
	
	
	local pageTitle: TextLabel = self.PageTitle
	
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
		local ButtonPadding = buttonSize/6.7
		
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
		pageTitle.Text = "Page: "..Folder.Name
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
				
				if buttonTbl.func then
					buttonTbl.func(toggled)
				else
					return
				end
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
		if isOpen then
			for i=1, AmountOfItems do
				local button: TextButton = Folder[i]

				local angle = (i - 1) * step - (math.pi / 2)

				local xOffset, yOffset = ComputeOffsets(prnt, buttonScale, step, angle)

				button.Position = UDim2.new(0.5, xOffset, 0.5, yOffset)

			end
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
	self.TopCircle.Transparency = 1
	
	self.PageTitle = Instance.new("TextLabel", self.TopCircle)
	self.PageTitle.AnchorPoint = Vector2.new(0.5,0.5)
	self.PageTitle.Size = UDim2.fromScale(0.23,0.2)
	self.PageTitle.BackgroundTransparency = 1
	self.PageTitle.Text = ""
	self.PageTitle.TextScaled = true
	self.PageTitle.TextXAlignment = Enum.TextXAlignment.Center
	self.PageTitle.TextYAlignment = Enum.TextYAlignment.Center
	self.PageTitle.Position = UDim2.fromScale(0.5,0.5)
	self.PageTitle.TextColor3 = Color3.fromRGB(53, 188, 203)
	
	self.BackgroundColoring = Instance.new("Frame", self.TopCircle)
	self.BackgroundColoring.ZIndex = 0
	self.BackgroundColoring.Size = UDim2.fromScale(1,1)
	self.BackgroundColoring.Transparency = 0.3
	local Grad = Instance.new("UIGradient", self.BackgroundColoring)
	Grad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(112, 41, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(74, 28, 173))
	})
	CircleIfy(self.BackgroundColoring)
	
	
	local const = Instance.new("UIPadding", self.PageTitle)
	
	const.PaddingTop = UDim.new(0,6)
	const.PaddingLeft = UDim.new(0,6)
	const.PaddingRight = UDim.new(0,6)
	const.PaddingBottom = UDim.new(0,6)
	
	self.PageManager = pageMaker.Start(self)
	
	return self
	
end


function module:Open()
	
	self.TopCircle.Size = UDim2.fromScale(0,0)
	self.TopCircle.Visible = true
	
local tween = TweenService:Create(self.TopCircle, TweenInfo.new(
		openTime,
		Enum.EasingStyle.Quad, 
		Enum.EasingDirection.Out),
		{Size = UDim2.fromScale(0.5,0.5)})
	tween:Play()
	tween.Completed:Wait()
	isOpen = true

end

function module:Close()
	isOpen = false
	local tween = TweenService:Create(self.TopCircle, TweenInfo.new(
		openTime,
		Enum.EasingStyle.Quad, 
		Enum.EasingDirection.In),
		{Size = UDim2.fromScale(0,0)})
	
	tween:Play()
	tween.Completed:Wait()
	
	self.TopCircle.Visible = isOpen
end

return module
