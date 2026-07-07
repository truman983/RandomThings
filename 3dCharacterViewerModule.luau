local modelViewer = {}
modelViewer.__index = modelViewer

local runServ = game:GetService("RunService")

local uis = game:GetService("UserInputService")

export type modelViewerObj = {
	Yaw: number;
	Pitch: number;
	YawVelocity: number;
	PitchVelocity: number;
	Damping: number;
	Sensitivity: number;	
	LastMousePos: Vector2;
	CurrentMousePos: Vector2;
	
	
	CameraConnection: RBXScriptConnection;
	
	PlayerLoaded: string;
	ModelLoaded: Model;
	
	Camera: Camera;
	
	ViewPort: ViewportFrame;
	WorldModel: WorldModel;
	
	StartLoop: (self: modelViewerObj) -> ();
	StopLoop: (self: modelViewerObj) -> ();
	LoadCharacter: (self: modelViewerObj, name: string) -> ();
	
	
}

export type ViewportConfig = {
	Size: UDim2;
	Position: UDim2;
	AnchorPoint: Vector2;
	BackgroundColor: Color3;
}



local function UpdateCam(camera:Camera, center: Vector3, pitch: number, yaw: number, dist: number, vp: ViewportFrame)
	
	local cent = center or Vector3.zero
	
	local horizontalDist = math.cos(pitch) * dist

	local x = math.sin(yaw) * horizontalDist
	local z = math.cos(yaw) * horizontalDist
	local y = math.sin(pitch) * dist

	local offset = Vector3.new(x, y, z)
	vp.LightDirection = -offset.Unit

	camera.CFrame = CFrame.new(cent + offset, cent)
end

local function PlrByUserOrDisplay(name: string): Player
	local plr
	for i,v in pairs(game.Players:GetPlayers()) do
		if string.lower(v.DisplayName) == string.lower(name) or string.lower(v.Name) == string.lower(name) then
			plr = v
			break
		end
	end

	return plr

end

function modelViewer.New(vpParent: GuiObject, config: ViewportConfig): modelViewerObj
	local self = setmetatable({}, modelViewer) :: modelViewerObj
	
	self.Yaw = 0
	self.Pitch = 0
	self.YawVelocity = 0
	self.PitchVelocity = 0
	self.Damping = 0.93
	self.Sensitivity = 0.001
	
	self.CameraConnection = nil
	self.VpButtonDown = nil
	self.VpButtonUp = nil

	self.PlayerLoaded = "Roblox"
	
	self.ModelLoaded = game.Players:CreateHumanoidModelFromUserIdAsync(game.Players:GetUserIdFromNameAsync("Roblox"))
	print(self.ModelLoaded)
	
	self.ViewPort = Instance.new("ViewportFrame", vpParent)
	self.Camera = Instance.new("Camera", self.ViewPort)
	self.ViewPort.CurrentCamera = self.Camera
	local stroke = Instance.new("UIStroke", self.ViewPort)
	stroke.Thickness = 0.7
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Color = Color3.fromRGB(0,0,0)
	
	self.WorldModel = Instance.new("WorldModel", self.ViewPort)
	
	self.ViewPort.Size = config.Size or UDim2.fromScale(0.5,0.5)
	self.ViewPort.AnchorPoint = config.AnchorPoint or Vector2.new(0.5,0.5)
	self.ViewPort.Position = config.Position or UDim2.fromScale(0.5,0.5)
	self.ViewPort.BackgroundColor3 = config.BackgroundColor or  Color3.fromRGB(32, 127, 48)
	
	UpdateCam(self.Camera, Vector3.zero, self.Pitch, self.Yaw, -7.5, self.ViewPort)
	
	self.ModelLoaded.Parent = self.WorldModel
	
	return self
end

function modelViewer:StartLoop()

	local dragging = false
	local lastMousePos
	
	local vp: ViewportFrame = self.ViewPort
	if self.CameraConnection then return end
	
	self.VpButtonDown =	vp.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 then
			lastMousePos = uis:GetMouseLocation()

			dragging = true
		end
	end)

	self.VpButtonUp = vp.InputEnded:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 then

			dragging = false
		end
	end)
	

		self.CameraConnection =	runServ.RenderStepped:Connect(function()

		if dragging then
			local currentPos = uis:GetMouseLocation()
			local delta = currentPos - lastMousePos

			self.YawVelocity -= delta.X * self.Sensitivity
			self.PitchVelocity -= delta.Y * self.Sensitivity


			lastMousePos = currentPos
		end

		self.Yaw += self.YawVelocity
		self.Pitch += self.PitchVelocity

		self.Pitch = math.clamp(self.Pitch, math.rad(-80), math.rad(80))

		self.YawVelocity *= self.Damping
		self.PitchVelocity *= self.Damping

		UpdateCam(self.Camera, Vector3.zero, self.Pitch, self.Yaw, -7.5, self.ViewPort)

			
		end)

end

function modelViewer:StopLoop()
	
	if self.CameraConnection then
		self.CameraConnection:Disconnect()
		self.CameraConnection = nil
	end
	
	if self.VpButtonUp then
		self.VpButtonUp:Disconnect()
		self.VpButtonUp = nil
	end
	
	if self.VpButtonDown then
		self.VpButtonDown:Disconnect()
		self.VpButtonDown = nil
	end
	
end

function modelViewer:LoadCharacter(Name: string)
	
	
	local ingame: Player = PlrByUserOrDisplay(Name)
	
	if not ingame then
		
		local success, plrID = pcall(function()
			return game.Players:GetUserIdFromNameAsync(Name)
		end)
		
		if success then
			local humDesc = game.Players:GetHumanoidDescriptionFromUserIdAsync(plrID)
			
			self.PlayerLoaded = Name
			self.ModelLoaded:FindFirstChildOfClass("Humanoid"):ApplyDescriptionResetAsync(humDesc)
		else
			self.PlayerLoaded = "Roblox"
			self.ModelLoaded:FindFirstChildOfClass("Humanoid"):ApplyDescriptionResetAsync(game.Players:GetHumanoidDescriptionFromUserIdAsync(game.Players:GetUserIdFromNameAsync("Roblox")))
		end
		
	else
		
	local humDesc = ingame.Character:FindFirstChildOfClass("Humanoid"):GetAppliedDescription()
	
	self.PlayerLoaded = Name
	self.ModelLoaded:FindFirstChildOfClass("Humanoid"):ApplyDescriptionResetAsync(humDesc)
	
	end
	
end


return modelViewer


