-- AngelHub executor edition | Build #1.01
-- Client features can be overridden by the game's server and character scripts.
local Players = game:GetService('Players')
local Run = game:GetService('RunService')
local UIS = game:GetService('UserInputService')
local player = Players.LocalPlayer
local parent = player:WaitForChild('PlayerGui')
local old = parent:FindFirstChild('AngelHubExecutor')
if old then old:Destroy() end
local connections, highlights = {}, {}
local speedOn, jumpOn, flightOn, espOn = false, false, false, false
local speed, jump, flightSpeed = 32, 75, 55
local root, human, savedSpeed, savedJump, savedJumpHeight, savedRotate
local attachment, velocity, orientation
local function connect(signal, fn)
 local c=signal:Connect(fn)
 table.insert(connections,c)
 return c
end
local function make(kind,parentObject,props)
 local o=Instance.new(kind)
 for k,v in pairs(props) do o[k]=v end
 o.Parent=parentObject
 return o
end
local function round(o) make('UICorner',o,{CornerRadius=UDim.new(0,10)}) end
local purple=Color3.fromRGB(157,113,255)
local white=Color3.fromRGB(240,240,250)
local gui=make('ScreenGui',parent,{Name='AngelHubExecutor',ResetOnSpawn=false,ZIndexBehavior=Enum.ZIndexBehavior.Sibling})
local win=make('Frame',gui,{Size=UDim2.fromOffset(540,440),Position=UDim2.fromScale(.5,.5),AnchorPoint=Vector2.new(.5,.5),BackgroundColor3=Color3.fromRGB(19,20,31),BorderSizePixel=0})
round(win)
make('UIStroke',win,{Color=purple,Transparency=.4})
local scale=make('UIScale',win,{Scale=1})
local function text(parentObject,value,x,y,w,h,size)
 return make('TextLabel',parentObject,{Text=value,Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(w,h),BackgroundTransparency=1,TextColor3=white,TextSize=size or 14,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left})
end
local title=text(win,'ANGEL HUB   /   BUILD #1.01',18,10,430,40,20)
title.Active=true
local status=text(win,'Готово • RightShift / AH — открыть меню',18,401,504,26,12)
local body=make('Frame',win,{Position=UDim2.fromOffset(18,60),Size=UDim2.fromOffset(504,332),BackgroundTransparency=1})
local function button(parentObject,value,x,y,w,h,fn)
 local b=make('TextButton',parentObject,{Text=value,Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(w,h),BackgroundColor3=Color3.fromRGB(42,36,66),TextColor3=white,TextSize=14,Font=Enum.Font.GothamMedium,BorderSizePixel=0})
 round(b)
 connect(b.Activated,fn)
 return b
end
local function field(value,x,y,w)
 local b=make('TextBox',body,{Text=tostring(value),PlaceholderText='Число',Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(w,38),BackgroundColor3=Color3.fromRGB(31,33,48),TextColor3=white,TextSize=14,Font=Enum.Font.Gotham,ClearTextOnFocus=false,BorderSizePixel=0})
 round(b)
 return b
end
local function stopFlight()
 flightOn=false
 if velocity then velocity:Destroy(); velocity=nil end
 if orientation then orientation:Destroy(); orientation=nil end
 if attachment then attachment:Destroy(); attachment=nil end
 if human and human.Parent and savedRotate~=nil then human.AutoRotate=savedRotate end
 savedRotate=nil
end
local function startFlight()
 if not root or not human or human.Health<=0 then status.Text='Персонаж ещё не готов'; return false end
 savedRotate=human.AutoRotate
 human.AutoRotate=false
 attachment=make('Attachment',root,{Name='AngelHubFlight'})
 velocity=make('LinearVelocity',root,{Attachment0=attachment,RelativeTo=Enum.ActuatorRelativeTo.World,MaxForce=math.huge,VectorVelocity=Vector3.zero})
 orientation=make('AlignOrientation',root,{Attachment0=attachment,Mode=Enum.OrientationAlignmentMode.OneAttachment,MaxTorque=math.huge,Responsiveness=20})
 flightOn=true
 return true
end
local function applyMovement()
 if not human or not human.Parent then return end
 human.WalkSpeed=speedOn and speed or savedSpeed
 if human.UseJumpPower then human.JumpPower=jumpOn and jump or savedJump
 else human.JumpHeight=jumpOn and jump*jump/(2*math.max(workspace.Gravity,1)) or savedJumpHeight end
end
local function toggle(value,x,y,w,fn,getState)
 local on=false
 local b
 b=button(body,value..': ВЫКЛ',x,y,w,40,function()
  local current=on
  if getState then current=getState() end
  local nextOn=not current
  if fn(nextOn)==false then return end
  on=nextOn
  b.Text=value..': '..(on and 'ВКЛ' or 'ВЫКЛ')
  b.TextColor3=on and purple or white
 end)
 return b
end
local speedField=field(speed,350,0,154)
local jumpField=field(jump,350,50,154)
toggle('Скорость',0,0,338,function(on) speedOn=on; applyMovement() end)
toggle('Прыжок',0,50,338,function(on) jumpOn=on; applyMovement() end)
local flyButton=toggle('Полёт (WASD / Space / Ctrl)',0,100,338,function(on)
 if on then return startFlight() end
 stopFlight()
end,function() return flightOn end)
local flyField=field(flightSpeed,350,100,154)
for _,item in ipairs({{speedField,1,150,function(v) speed=v; applyMovement() end},{jumpField,1,200,function(v) jump=v; applyMovement() end},{flyField,1,200,function(v) flightSpeed=v end}}) do
 connect(item[1].FocusLost,function()
  local v=tonumber(item[1].Text)
  if not v or v~=v then status.Text='Введи корректное число'; return end
  v=math.clamp(v,item[2],item[3])
  item[1].Text=tostring(v)
  item[4](v)
 end)
end
local function clearESP()
 for _,h in pairs(highlights) do h:Destroy() end
 table.clear(highlights)
end
local function refreshESP()
 clearESP()
 if not espOn then return end
 for _,p in ipairs(Players:GetPlayers()) do
  if p~=player and p.Character then
   highlights[p]=make('Highlight',gui,{Adornee=p.Character,FillColor=purple,OutlineColor=white,FillTransparency=.75,OutlineTransparency=0,DepthMode=Enum.HighlightDepthMode.AlwaysOnTop})
  end
 end
end
toggle('ESP игроков',0,150,246,function(on) espOn=on; refreshESP() end)
local originalMode=player.CameraMode
toggle('Первое лицо',258,150,246,function(on) player.CameraMode=on and Enum.CameraMode.LockFirstPerson or originalMode end)
text(body,'Телепорт по координатам X / Y / Z',0,200,504,24)
local x,y,z=field(0,0,231,110),field(10,120,231,110),field(0,240,231,110)
button(body,'Телепорт',360,231,144,38,function()
 local a,b,c=tonumber(x.Text),tonumber(y.Text),tonumber(z.Text)
 if not a or not b or not c or a~=a or b~=b or c~=c or math.abs(a)>1000000 or math.abs(b)>1000000 or math.abs(c)>1000000 then status.Text='Координаты: числа от −1000000 до 1000000'; return end
 if player.Character and root then player.Character:PivotTo(CFrame.new(a,b,c)); status.Text='Телепорт выполнен локально' end
end)
button(body,'Запомнить позицию',0,282,246,40,function()
 if root then local p=root.Position; x.Text=tostring(math.round(p.X)); y.Text=tostring(math.round(p.Y)); z.Text=tostring(math.round(p.Z)) end
end)
button(body,'Закрыть и восстановить',258,282,246,40,function() gui:Destroy() end)
local mini=false
button(win,'−',486,14,36,30,function()
 mini=not mini
 body.Visible=not mini; status.Visible=not mini
 win.Size=UDim2.fromOffset(540,mini and 54 or 440)
end)
button(gui,'AH',14,14,46,40,function() win.Visible=not win.Visible end)
local drag,start,startPos,touch
connect(title.InputBegan,function(input)
 if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then drag=true; start=input.Position; startPos=win.Position; touch=input.UserInputType==Enum.UserInputType.Touch and input or nil end
end)
connect(UIS.InputChanged,function(input)
 if drag and (input==touch or (not touch and input.UserInputType==Enum.UserInputType.MouseMovement)) then local d=input.Position-start; win.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,startPos.Y.Scale,startPos.Y.Offset+d.Y) end
end)
connect(UIS.InputEnded,function(input) if input==touch or input.UserInputType==Enum.UserInputType.MouseButton1 then drag=false end end)
connect(UIS.InputBegan,function(input,processed) if not processed and input.KeyCode==Enum.KeyCode.RightShift then win.Visible=not win.Visible end end)
local function bind(character)
 stopFlight()
 flyButton.Text='Полёт (WASD / Space / Ctrl): ВЫКЛ'
 flyButton.TextColor3=white
 human=nil; root=nil
 local h=character:WaitForChild('Humanoid',10)
 local r=character:WaitForChild('HumanoidRootPart',10)
 if not h or not r or character~=player.Character then return end
 human=h; root=r
 savedSpeed=h.WalkSpeed; savedJump=h.JumpPower; savedJumpHeight=h.JumpHeight
 applyMovement()
end
connect(player.CharacterAdded,function(c) task.spawn(bind,c) end)
if player.Character then task.spawn(bind,player.Character) end
local elapsed=0
connect(Run.RenderStepped,function(dt)
 local camera=workspace.CurrentCamera
 if camera then scale.Scale=math.max(.1,math.min(1,(camera.ViewportSize.X-24)/540,(camera.ViewportSize.Y-24)/440)) end
 elapsed=elapsed+dt
 if elapsed>=1 then elapsed=0; refreshESP() end
 if flightOn and velocity and orientation and camera then
  local direction=human.MoveDirection
  if not UIS:GetFocusedTextBox() then
   if UIS:IsKeyDown(Enum.KeyCode.W) then direction=direction+camera.CFrame.LookVector end
   if UIS:IsKeyDown(Enum.KeyCode.S) then direction=direction-camera.CFrame.LookVector end
   if UIS:IsKeyDown(Enum.KeyCode.A) then direction=direction-camera.CFrame.RightVector end
   if UIS:IsKeyDown(Enum.KeyCode.D) then direction=direction+camera.CFrame.RightVector end
   if UIS:IsKeyDown(Enum.KeyCode.Space) then direction=direction+Vector3.yAxis end
   if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then direction=direction-Vector3.yAxis end
  end
  velocity.VectorVelocity=direction.Magnitude>0 and direction.Unit*flightSpeed or Vector3.zero
  orientation.CFrame=camera.CFrame.Rotation
 end
end)
connect(gui.Destroying,function()
 stopFlight(); clearESP()
 speedOn=false; jumpOn=false; applyMovement()
 player.CameraMode=originalMode
 for _,c in ipairs(connections) do c:Disconnect() end
end)
