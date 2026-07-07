local modelViewer = {}
modelViewer.__index = modelViewer

local runServ = game:GetService("RunService")

local uis = game:GetService("UserInputService")

export type modelViewerObj = {
	Yaw: number;
	Pitch: number;
	YawVelocity: number;
	PitchVelocity: number;
	Friction: number;
	Sensitivity: number;	
	LastMousePos: Vector2;
	CurrentMousePos: Vector2;
	
	
	CameraConnection: RBXScriptConnection;
	
	PlayerLoaded: string;
	ModelLoaded: Model;
	
	Camera: Camera;
	
	ViewPort: ViewportFrame;
	WorldModel: WorldModel;
	ModelCache: Model;
	
	StartLoop: (self: modelViewerObj) -> ();
	StopLoop: (self: modelViewerObj) -> ();
	LoadCharacter: (self: modelViewerObj, name: string) -> ();
	
	
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

function modelViewer.New(vpParent: GuiObject): modelViewerObj
	local self = setmetatable({}, modelViewer) :: modelViewerObj
	
	self.Yaw = 0
	self.Pitch = 0
	self.YawVelocity = 0
	self.PitchVelocity = 0
	self.Friction = 0
	self.Sensitivity = 0.001
	
	self.CameraConnection = nil
	self.VpButtonDown = nil
	self.VpButtonUp = nil

	self.PlayerLoaded = "Roblox"
	
	self.ModelLoaded = game.Players:CreateHumanoidModelFromUserIdAsync(game.Players:GetUserIdFromNameAsync(self.PlayerLoaded))
	
	self.ViewPort = Instance.new("ViewportFrame", vpParent)
	self.Camera = Instance.new("Camera", self.ViewPort)
	self.ViewPort.CurrentCamera = self.Camera
	
	self.WorldModel = Instance.new("WorldModel", self.ViewPort)
	
	self.ViewPort.Size = UDim2.fromScale(0.5,0.5)
	self.ViewPort.AnchorPoint = Vector2.new(0.5,0.5)
	self.ViewPort.Position = UDim2.fromScale(0.5,0.5)
	self.ViewPort.BackgroundColor3 = Color3.fromRGB(32, 127, 48)
	
	UpdateCam(self.Camera, Vector3.zero, self.Pitch, self.Yaw, -6, self.ViewPort)
	
	self.ModelLoaded.Parent = self.WorldModel
	
	return self
end

function modelViewer:StartLoop()
	
	print(self)
	
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

		self.YawVelocity *= 0.93
		self.PitchVelocity *= 0.93

		UpdateCam(self.Camera, Vector3.zero, self.Pitch, self.Yaw, -6, self.ViewPort)

			
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
	
	local ingame: Player = game.Players:FindFirstChild(Name)
	
	if not ingame then
		
		local success, plrID = pcall(function()
			return game.Players:GetUserIdFromNameAsync(Name)
		end)
		
		if success then
			local humDesc = game.Players:GetHumanoidDescriptionFromUserIdAsync(plrID)
			
			self.PlayerLoaded = Name
			self.ModelLoaded:FindFirstChildOfClass("Humanoid"):ApplyDescriptionResetAsync(humDesc)
		end
		
	else
		
	local humDesc = ingame.Character:FindFirstChildOfClass("Humanoid"):GetAppliedDescription()
	
	self.PlayerLoaded = Name
	self.ModelLoaded:FindFirstChildOfClass("Humanoid"):ApplyDescriptionResetAsync(humDesc)
	
	end
	
end


return modelViewer


