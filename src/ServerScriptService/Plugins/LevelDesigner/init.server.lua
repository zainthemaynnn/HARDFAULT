-- this is the most atrocious thing in the entire codebase
-- but it's a plugin, so who cares?
-- hopefully there aren't any mem leaks. there's probably a mem leak.
local RunService = game:GetService("RunService")

if not RunService:IsEdit() then return end

local ChangeHistoryService = game:GetService("ChangeHistoryService")
local CollectionService = game:GetService("CollectionService")
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Selection = game:GetService("Selection")
local ServerScriptService = game:GetService("ServerScriptService")

local Roact = require(ReplicatedStorage.Packages.Roact)
local Rodux = require(ReplicatedStorage.Packages.Rodux)
local RoactRodux = require(ReplicatedStorage.Packages.RoactRodux)

local camera = workspace.CurrentCamera
local mouse = plugin:GetMouse()
local toolbar = plugin:CreateToolbar("Level designer")
local spawnables = {}
for _, sc in pairs(ServerScriptService.AI.Enemy:GetChildren()) do
    pcall(function() print(sc.Name) spawnables[sc.Name] = require(sc) print(sc.Name, spawnables[sc.Name]) end)
end

spawnables["Assault"] = require(ServerScriptService.AI.Enemy.Assault)

local handles = Instance.new("Handles")
handles.Style = Enum.HandlesStyle.Resize
handles.Faces = Faces.new(Enum.NormalId.Left, Enum.NormalId.Right, Enum.NormalId.Front, Enum.NormalId.Back, Enum.NormalId.Top)
handles.Visible = false
handles.Parent = CoreGui
local current: Model? = nil
local prevDist = 0

local store = Rodux.Store.new(function(state: any, action: any)
    state = state or {
        Timeline = nil,
        CurrentEvent = nil,
    }

    if action.type == "SelectRoom" then
        return {
            Timeline = action.Room and action.Room:FindFirstChild("Timeline"),
            CurrentEvent = nil,
        }

    elseif action.type == "SelectEvent" then
        local curev
        if action.Index then
            for _, event in pairs(state.Timeline:GetChildren()) do
                if event.Index.Value == action.Index then
                    curev = event
                end
            end
        else
            curev = nil
        end

        return {
            Timeline = state.Timeline,
            CurrentEvent = curev,
        }

    elseif action.type == "AddEvent" then
        local tl = state.Timeline:GetChildren()
        for _, event in pairs(tl) do
            if event.Index.Value >= action.Index then
                event.Index.Value += 1
            end
        end

        local event = Instance.new("Folder", state.Timeline)
        event.Name = "Event"
        local idx = Instance.new("NumberValue", event)
        idx.Name = "Index"
        idx.Value = action.Index or #tl+1
        local spawns = Instance.new("Folder", event)
        spawns.Name = "Spawns"

        return {
            Timeline = state.Timeline,
            CurrentEvent = state.CurrentEvent,
        }

    elseif action.type == "RemoveEvent" then
        local idx = action.Index or state.CurrentEvent.Index.Value
        for _, event in pairs(state.Timeline:GetChildren()) do
            if event.Index.Value == idx then
                event:Destroy()
            elseif event.Index.Value >= idx then
                event.Index.Value -= 1
            end
        end

        return {
            Timeline = state.Timeline,
            CurrentEvent = if idx == state.CurrentEvent.Index.Value then nil else state.CurrentEvent,
        }

    elseif action.type == "AddSpawn" then
        if not state.CurrentEvent then return end
        local e = Instance.new("Folder", state.CurrentEvent.Spawns)
        e.Name = "Spawn"
        local typee = Instance.new("StringValue", e)
        typee.Value = action.Type
        typee.Name = "Type"
        local delay = Instance.new("NumberValue", e)
        delay.Value = action.Delay
        delay.Name = "Delay"
        local cf = Instance.new("CFrameValue", e)
        cf.Value = action.CFrame
        cf.Name = "CFrame"

        return {
            Timeline = state.Timeline,
            CurrentEvent = state.CurrentEvent,
        }

    elseif action.type == "RemoveSpawn" then
        if not state.CurrentEvent then return end
        for _, spawn in pairs(state.CurrentEvent.Spawns:GetChildren()) do
            if spawn == action.Spawn then
                spawn:Destroy()
            end
        end

        return {
            Timeline = state.Timeline,
            CurrentEvent = state.CurrentEvent,
        }
    end

    return state
end)

local cmpt = Roact.Component:extend("WidgetUI")

local function roundVec(vec: Vector3): Vector3
    return Vector3.new(math.floor(vec.X+0.5), math.floor(vec.Y+0.5), math.floor(vec.Z+0.5))
end

function cmpt:init()
    self.TempFolder = workspace:FindFirstChild("_LevelDesignerStorage")
    if not self.TempFolder then
        self.TempFolder = Instance.new("Folder", workspace)
        self.TempFolder.Name = "_LevelDesignerStorage"
    end
    self.RenderedEvent = nil
    self.Textbox = Roact.createRef()
end

function cmpt:render()
    if self.props.Active then
        local enemyTiles = {}
        local placeConn, clickConn
        for name, enemy in pairs(spawnables) do
            enemyTiles[#enemyTiles+1] = Roact.createElement("TextButton", {
                Text = name,
                TextSize = 24,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextColor3 = BrickColor.new("White").Color,
                BackgroundColor3 = BrickColor.new("Black").Color,
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                LayoutOrder = enemy.BestiaryIndex,
                [Roact.Event.MouseButton1Click] = function()
                    if not self.props.CurrentEvent then return end
                    if placeConn then placeConn:Disconnect() end
                    if clickConn then clickConn:Disconnect() end
                    if ghost then ghost:Destroy() end

                    plugin:Activate(false)

                    ghost = enemy.BaseModel:Clone()
                    ghost.Parent = workspace
                    mouse.TargetFilter = ghost
                    Selection:Set({ghost})
                    local size = ghost:GetExtentsSize()
                    local cf = current.PrimaryPart.CFrame

                    placeConn = RunService.Heartbeat:Connect(function()
                        if ghost.Parent == nil then
                            clickConn:Disconnect()
                            placeConn:Disconnect()
                        end
                        if not mouse.Target:FindFirstAncestorWhichIsA("Model") == current then return end
                        ghost:SetPrimaryPartCFrame(
                            cf:ToWorldSpace(CFrame.new(
                                roundVec(cf:PointToObjectSpace(mouse.Hit.Position)) + Vector3.new(0, size.Y/2, 0)
                            ))
                        )
                    end)

                    clickConn = mouse.Button1Down:Connect(function()
                        clickConn:Disconnect()
                        placeConn:Disconnect()

                        self.props.AddSpawn(name, ghost.PrimaryPart.CFrame, 3.0)

                        ghost:Destroy()
                        ghost = nil
                        self.props.SelectEvent(self.props.CurrentEvent.Index.Value)
                        ChangeHistoryService:SetWaypoint("Added spawn")
                    end)

                    ChangeHistoryService:SetWaypoint("Adding spawn")
                end,
            })
        end
        enemyTiles["Layout"] = Roact.createElement("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            FillDirection = Enum.FillDirection.Vertical,
        })

        local eventTiles = {}
        for _, event in pairs(self.props.Timeline or {}) do
            eventTiles[#eventTiles+1] = Roact.createElement("TextButton", {
                Text = ("%d %s"):format(event.Index.Value, event.Name),
                TextSize = 24,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextColor3 = BrickColor.new("White").Color,
                Position = UDim2.new(0, 0, 0, 0),
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundColor3 = if event == self.props.CurrentEvent then BrickColor.new("Royal blue").Color else BrickColor.new("Black").Color,
                LayoutOrder = event.Index.Value,
                [Roact.Event.MouseButton1Click] = function()
                    self.props.SelectEvent(event.Index.Value)
                end,
            })
        end
        eventTiles["Layout"] = Roact.createElement("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            FillDirection = Enum.FillDirection.Vertical,
        })

        if self.props.CurrentEvent ~= self.RenderedEvent or self.props.Timeline ~= self.RenderedTimeline then
            for _, preview in pairs(self.TempFolder:GetChildren()) do
                preview:SetAttribute("SafeDestroy", true)
                preview:Destroy()
            end
        end

        if self.props.CurrentEvent ~= nil then
            for _, spawn in pairs(self.props.CurrentEvent.Spawns:GetChildren()) do
                local preview = spawnables[spawn.Type.Value].BaseModel:Clone()
                preview:SetAttribute("SafeDestroy", false)
                preview:SetPrimaryPartCFrame(spawn.CFrame.Value)
                preview.Parent = self.TempFolder

                preview.PrimaryPart:GetPropertyChangedSignal("CFrame"):Connect(function()
                    spawn.CFrame.Value = preview.PrimaryPart.CFrame
                end)
                preview.AncestryChanged:Connect(function()
                    if not preview:IsDescendantOf(game) then
                        if preview:GetAttribute("SafeDestroy") == false then
                            self.props.RemoveSpawn(spawn)
                        end
                    end
                end)
            end
        end

        return Roact.createElement("Frame", {
            BackgroundColor3 = BrickColor.new("Really black").Color,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 1, 0),
        }, {
            Name = Roact.createElement("TextBox", {
                Size = UDim2.new(1, 0, 0, 40),
                BackgroundColor3 = BrickColor.new("Really black").Color,
                BorderSizePixel = 0,
                Text = current.Name,
                TextSize = 24,
                TextColor3 = BrickColor.new("White").Color,
                TextXAlignment = Enum.TextXAlignment.Left,
                ClearTextOnFocus = false,
                [Roact.Event.Focused] = function()
                    ChangeHistoryService:SetWaypoint("Changing room name")
                end,
                [Roact.Event.FocusLost] = function()
                    current.Name = self.Textbox:getValue().Text
                    ChangeHistoryService:SetWaypoint("Changed room name")
                end,
                [Roact.Ref] = self.Textbox,
            }),
            EnemyChooser = Roact.createElement("ScrollingFrame", {
                Position = UDim2.new(0, 0, 0, 40),
                Size = UDim2.new(.5, 0, 1, -80),
                ScrollingDirection = Enum.ScrollingDirection.Y,
                BackgroundColor3 = BrickColor.new("Really black").Color,
                BorderSizePixel = 0,
            }, enemyTiles),
            EventChooser = Roact.createElement("ScrollingFrame", {
                Position = UDim2.new(.5, 0, 0, 40),
                Size = UDim2.new(.5, 0, 1, -80),
                ScrollingDirection = Enum.ScrollingDirection.Y,
                BackgroundColor3 = BrickColor.new("Really black").Color,
                BorderSizePixel = 0,
            }, eventTiles),
            Toolbar = Roact.createElement("Frame", {
                Position = UDim2.new(0, 0, 1, -40),
                Size = UDim2.new(1, 0, 0, 40),
                BackgroundColor3 = BrickColor.new("Really black").Color,
                BorderSizePixel = 0,
            }, {
                Add = Roact.createElement("TextButton", {
                    Position = UDim2.new(0, 0, 0, 0),
                    Size = UDim2.new(.5, 0, 1, 0),
                    Text = "Add event",
                    TextSize = 24,
                    TextColor3 = BrickColor.new("Bright green").Color,
                    BackgroundColor3 = BrickColor.new("Really black").Color,
                    BorderSizePixel = 0,
                    [Roact.Event.MouseButton1Click] = function()
                        ChangeHistoryService:SetWaypoint("Adding event")
                        local idx = if self.props.CurrentEvent then self.props.CurrentEvent.Index.Value+1 else #self.props.Timeline+1
                        self.props.AddEvent(idx)
                        self.props.SelectEvent(idx)
                        ChangeHistoryService:SetWaypoint("Added event")
                    end,
                }),
                Remove = Roact.createElement("TextButton", {
                    Position = UDim2.new(.5, 0, 0, 0),
                    Size = UDim2.new(.5, 0, 1, 0),
                    Text = "Remove event",
                    TextSize = 24,
                    TextColor3 = BrickColor.new("Bright red").Color,
                    BackgroundColor3 = BrickColor.new("Really black").Color,
                    BorderSizePixel = 0,
                    [Roact.Event.MouseButton1Click] = function()
                        if not self.props.CurrentEvent then return end
                        ChangeHistoryService:SetWaypoint("Removing event")
                        local idx = self.props.CurrentEvent.Index.Value
                        self.props.RemoveEvent(idx)
                        ChangeHistoryService:SetWaypoint("Removed event")
                    end,
                }),
            }),
        })
    else
        return Roact.createElement("Frame", {
            BackgroundColor3 = BrickColor.new("Really black").Color,
            Size = UDim2.new(1, 0, 1, 0),
        }, {
            Text = Roact.createElement("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 1, 0),
                TextColor3 = BrickColor.new("White").Color,
                TextSize = 32,
                TextXAlignment = Enum.TextXAlignment.Center,
                TextYAlignment = Enum.TextYAlignment.Center,
                Text = "Inactive",
            })
        })
    end
end

function cmpt:didUpdate()
    self.RenderedEvent = self.props.CurrentEvent
    self.RenderedTimeline = self.props.Timeline
end

cmpt = Roact.createElement(
    RoactRodux.connect(
        function(state, _)
            return {
                CurrentEvent = state.CurrentEvent,
                -- rodux users will be pissed. that's too bad.
                Timeline = state.Timeline and state.Timeline:GetChildren(),
                Active = state.Timeline ~= nil,
            }
        end,
        function(dispatch)
            return {
                SelectEvent = function(id: number)
                    dispatch({
                        type = "SelectEvent",
                        Index = id,
                    })
                end,
                AddEvent = function(id: number?)
                    dispatch({
                        type = "AddEvent",
                        Index = id,
                    })
                end,
                RemoveEvent = function(id: number)
                    dispatch({
                        type = "RemoveEvent",
                        Index = id,
                    })
                end,
                AddSpawn = function(name: string, cf: CFrame, delay: number)
                    dispatch({
                        type = "AddSpawn",
                        Type = name,
                        Delay = delay,
                        CFrame = cf,
                    })
                end,
                RemoveSpawn = function(spawn: Folder)
                    dispatch({
                        type = "RemoveSpawn",
                        Spawn = spawn,
                    })
                end,
            }
        end
    )(cmpt)
)

cmpt = Roact.createElement(RoactRodux.StoreProvider, {
    store = store,
}, { Main = cmpt })

local function buildCorner(floor: BasePart, ofst: Vector3, aofst: number, height: number): BasePart
    local corner = Instance.new("Part")
    corner.Size = Vector3.new(1.0, height, 1.0)
    corner.CFrame = floor.CFrame:ToWorldSpace(
        CFrame.new((floor.Size + corner.Size * Vector3.new(-1, 1, -1)) * (ofst + Vector3.yAxis)/2) * CFrame.Angles(0, aofst, 0)
    )
    return corner
end

local function buildCorners(model: Model, height: number): Folder
    local corners = Instance.new("Folder", model)
    corners.Name = "Corners"

    for i, ofst in pairs({
        Vector3.new(-1, 0, -1),
        Vector3.new( 1, 0, -1),
        Vector3.new( 1, 0,  1),
        Vector3.new(-1, 0,  1),
    }) do
        local corner = buildCorner(model.PrimaryPart, ofst, math.rad(90)*(i-1), height)
        corner.Parent = corners
    end

    return corners
end

local createRoom = toolbar:CreateButton("Room", "Create a new room", "rbxassetid://4458901886")
createRoom.Click:Connect(function()
    createRoom:SetActive(false)
    local res = workspace:Raycast(camera.CFrame.Position, camera.CFrame.LookVector * 999)
    if not res then return end

    ChangeHistoryService:SetWaypoint("Creating room")

    local model = Instance.new("Model")
    local floor = Instance.new("Part", model)
    floor.Size = Vector3.new(20.0, 1.0, 20.0)
    floor.Position = res.Position + Vector3.new(0, floor.Size/2, 0)
    floor.Name = "Floor"
    floor.Anchored = true
    model.PrimaryPart = floor

    buildCorners(model, 10.0)

    local timeline = Instance.new("Folder", model)
    timeline.Name = "Timeline"

    local doors = Instance.new("Folder", model)
    doors.Name = "Doors"

    model.Parent = workspace
    CollectionService:AddTag(model, "Room")
    Selection:Set({model})

    ChangeHistoryService:SetWaypoint("Created room")
end)

local function fitModel(buf: BasePart, model: Model)
    local cf, size = model:GetBoundingBox()
    buf.CFrame = cf
    buf.Size = size
end

local followConn, sizeConn
Selection.SelectionChanged:Connect(function()
    if handles.Adornee then handles.Adornee:Destroy() end

    local selected = Selection:Get()
    local inst = selected[1]
    if #selected == 1 and CollectionService:HasTag(inst, "Room") and inst:IsA("Model") then
        handles.Adornee = Instance.new("Part", workspace)
        handles.Adornee.Anchored = true
        handles.Adornee.CanCollide = false
        handles.Adornee.Transparency = 1
        current = inst
        handles.Visible = true
        handles.Adornee.Position = current.PrimaryPart.Position
        handles.Adornee.Size = Vector3.new()

        fitModel(handles.Adornee, current)
        if followConn then followConn:Disconnect() end
        followConn = current.PrimaryPart:GetPropertyChangedSignal("CFrame"):Connect(function()
            fitModel(handles.Adornee, current)
        end)
        if sizeConn then sizeConn:Disconnect() end
        sizeConn = current.PrimaryPart:GetPropertyChangedSignal("Size"):Connect(function()
            fitModel(handles.Adornee, current)
        end)
        store:dispatch({
            type = "SelectRoom",
            Room = current,
        })
        store:dispatch({
            type = "SelectEvent",
            Index = 1,
        })

    elseif #selected == 1 and inst == handles.Adornee then
        Selection:Set({current})
    else
        handles.Visible = false
    end
end)

handles.MouseButton1Down:Connect(function()
    ChangeHistoryService:SetWaypoint("Scaling room")
end)

handles.MouseButton1Up:Connect(function()
    prevDist = 0
    ChangeHistoryService:SetWaypoint("Scaled room")
end)

local function assertMinThickness(vec: Vector3, min: number): Vector3
    return Vector3.new(math.max(vec.X, min), vec.Y, math.max(vec.Z, min))
end

handles.MouseDrag:Connect(function(normal: Enum.NormalId, dist: number)
    local inverted = normal == Enum.NormalId.Left or normal == Enum.NormalId.Front
    dist = math.floor(dist)

    local tmp = dist
    dist = dist - prevDist
    prevDist = tmp

    -- scale corners
    if normal == Enum.NormalId.Top then
        local ref = current.Corners:FindFirstChildWhichIsA("BasePart")
        current.Corners.Parent = nil
        buildCorners(current, if ref then ref.Size.Y + dist else 10.0 + dist)

    -- scale base
    else
        local axis = Vector3.fromNormalId(normal)
        local cf = current.PrimaryPart.CFrame
        current:SetPrimaryPartCFrame(cf:ToWorldSpace(CFrame.new(axis * dist/2)))
        current.PrimaryPart.Size = assertMinThickness(current.PrimaryPart.Size + axis * dist * if inverted then -1 else 1, 2.0)

        local ref = current.Corners:FindFirstChildWhichIsA("BasePart")
        current.Corners.Parent = nil
        buildCorners(current, if ref then ref.Size.Y else 10.0)
    end
end)

local widget = plugin:CreateDockWidgetPluginGui("LevelDesigner", DockWidgetPluginGuiInfo.new(
    Enum.InitialDockState.Float,
    false,
    false,
    200,
    300,
    150,
    150
))
widget.Title = "Level designer"

task.wait(1.0)

Roact.mount(cmpt, widget)
widget.Enabled = true
