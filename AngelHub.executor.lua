-- AngelHub executor edition | Build #1.01 Red Edition
-- Client features can be overridden by the game's server and character scripts.
local Players = game:GetService('Players')
local Run = game:GetService('RunService')
local UIS = game:GetService('UserInputService')
local TweenService = game:GetService('TweenService')
-- Optional permitted Roblox audio recording of the Russian greeting.
local GREETING_AUDIO_ID = '' -- Optional Roblox Audio ID instead of local audio.
local GREETING_URL = 'https://raw.githubusercontent.com/lclclav29-ux/AngelHub/angelhub-build-1.01/assets/welcome-ru.ogg'
local player = Players.LocalPlayer
local parent = player:WaitForChild('PlayerGui')
local old = parent:FindFirstChild('AngelHubExecutor')
if old then old:Destroy() end
local connections, highlights = {}, {}
local active = true
local authorized = false
local pendingTweens = {}
local greetingSound
local shutdown
local bindGeneration = 0
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
local accent=Color3.fromRGB(244,61,77)
local white=Color3.fromRGB(240,240,250)
local gui=make('ScreenGui',parent,{Name='AngelHubExecutor',ResetOnSpawn=false,ZIndexBehavior=Enum.ZIndexBehavior.Sibling})
local win=make('Frame',gui,{Size=UDim2.fromOffset(540,500),Position=UDim2.fromScale(.5,.5),AnchorPoint=Vector2.new(.5,.5),BackgroundColor3=Color3.fromRGB(19,16,19),BackgroundTransparency=1,BorderSizePixel=0})
round(win)
for _,layer in ipairs({{12,.88},{24,.94}}) do
 local shadow=make('Frame',win,{Position=UDim2.fromOffset(-layer[1]/2,4),Size=UDim2.new(1,layer[1],1,layer[1]),BackgroundTransparency=1,BorderSizePixel=0,ZIndex=0})
 round(shadow)
 make('UIStroke',shadow,{Color=Color3.fromRGB(0,0,0),Thickness=layer[1],Transparency=layer[2]})
end
make('UIGradient',win,{Color=ColorSequence.new(Color3.fromRGB(40,20,27),Color3.fromRGB(15,15,18)),Rotation=100})
local function animate(o,props,duration)
 if not active then return end
 local previous=pendingTweens[o]
 if previous then previous:Cancel() end
 local tween=TweenService:Create(o,TweenInfo.new(duration or .18,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),props)
 pendingTweens[o]=tween
 tween:Play()
end
make('UIStroke',win,{Color=accent,Transparency=.4})
local scale=make('UIScale',win,{Scale=1})
local function text(parentObject,value,x,y,w,h,size)
 return make('TextLabel',parentObject,{Text=value,Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(w,h),BackgroundTransparency=1,TextColor3=white,TextSize=size or 14,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left})
end
local title=text(win,'ANGEL HUB   /   BUILD #1.01 • RED EDITION',18,10,430,40,20)
title.Active=true
local status=text(win,'RightShift / AH — меню • End / OFF — отключить',18,461,504,26,12)
local body=make('Frame',win,{Position=UDim2.fromOffset(18,118),Size=UDim2.fromOffset(504,332),BackgroundTransparency=1})
local function button(parentObject,value,x,y,w,h,fn)
 local b=make('TextButton',parentObject,{Text=value,Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(w,h),BackgroundColor3=Color3.fromRGB(48,25,31),TextColor3=white,TextSize=14,Font=Enum.Font.GothamMedium,BorderSizePixel=0})
 round(b)
 connect(b.MouseEnter,function() animate(b,{BackgroundColor3=Color3.fromRGB(88,29,40)}) end)
 connect(b.MouseLeave,function() animate(b,{BackgroundColor3=Color3.fromRGB(48,25,31)}) end)
 connect(b.Activated,function()
  if active then fn() end
 end)
 return b
end
local pages, navigation = {}, {}
for _,name in ipairs({'Движение','Визуал','Телепорт'}) do
 pages[name]=make('Frame',body,{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Visible=name=='Движение'})
end
local function selectPage(name)
 if not authorized then return end
 for key,p in pairs(pages) do p.Visible=key==name end
 for key,b in pairs(navigation) do b.TextColor3=key==name and accent or white end
 animate(pages[name],{Position=UDim2.fromOffset(0,0)},.2)
end
local tabbar=make('Frame',win,{Position=UDim2.fromOffset(18,66),Size=UDim2.fromOffset(504,40),BackgroundTransparency=1,Visible=false})
for i,name in ipairs({'Движение','Визуал','Телепорт'}) do
 navigation[name]=button(tabbar,name,(i-1)*172,0,160,36,function()
  pages[name].Position=UDim2.fromOffset(0,8)
  selectPage(name)
 end)
end
local currentPage=pages['Движение']
local function field(value,x,y,w)
 local b=make('TextBox',currentPage,{Text=tostring(value),PlaceholderText='Число',Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(w,38),BackgroundColor3=Color3.fromRGB(30,23,28),TextColor3=white,TextSize=14,Font=Enum.Font.Gotham,ClearTextOnFocus=false,BorderSizePixel=0})
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
 velocity=make('LinearVelocity',root,{Attachment0=attachment,RelativeTo=Enum.ActuatorRelativeTo.World,MaxForce=math.clamp(root.AssemblyMass * 2500, 10000, 1000000),VectorVelocity=Vector3.zero})
 orientation=make('AlignOrientation',root,{Attachment0=attachment,Mode=Enum.OrientationAlignmentMode.OneAttachment,MaxTorque=1000000,Responsiveness=20})
 flightOn=true
 return true
end
local function applyMovement()
 if not authorized then return end
 if not human or not human.Parent then return end
 human.WalkSpeed=speedOn and speed or savedSpeed
 if human.UseJumpPower then human.JumpPower=jumpOn and jump or savedJump
 else human.JumpHeight=jumpOn and jump*jump/(2*math.max(workspace.Gravity,1)) or savedJumpHeight end
end
local function toggle(value,x,y,w,fn,getState)
 local on=false
 local b
 b=button(currentPage,value..': ВЫКЛ',x,y,w,40,function()
  if not authorized then return end
  local current=on
  if getState then current=getState() end
  local nextOn=not current
  if fn(nextOn)==false then return end
  on=nextOn
  b.Text=value..': '..(on and 'ВКЛ' or 'ВЫКЛ')
  b.TextColor3=on and accent or white
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
 if not active or not espOn then clearESP(); return end
 local targets = {}
 local count = 0
 for _,p in ipairs(Players:GetPlayers()) do
  if p~=player and p.Character and count<24 then
   count=count+1
   targets[p]=p.Character
   local h=highlights[p]
   if not h then
    h=make('Highlight',gui,{FillColor=accent,OutlineColor=white,FillTransparency=.75,OutlineTransparency=0,DepthMode=Enum.HighlightDepthMode.AlwaysOnTop})
    highlights[p]=h
   end
   h.Adornee=p.Character
  end
 end
 for p,h in pairs(highlights) do
  if not targets[p] then h:Destroy(); highlights[p]=nil end
 end
end
text(pages['Движение'],'Все функции выключены при входе. Включай по одной.',0,177,504,30,12)
currentPage=pages['Визуал']
toggle('ESP игроков',0,0,246,function(on) espOn=on; refreshESP() end)
local originalMode=player.CameraMode
toggle('Первое лицо',258,0,246,function(on) player.CameraMode=on and Enum.CameraMode.LockFirstPerson or originalMode end)
text(currentPage,'Красные контуры • до 24 игроков • экономный режим',0,65,504,36,12)
text(currentPage,'Приветствуем в ангелс хаб',0,120,504,36,20)
currentPage=pages['Телепорт']
text(currentPage,'Телепорт по координатам X / Y / Z',0,0,504,24)
local x,y,z=field(0,0,42,110),field(10,120,42,110),field(0,240,42,110)
button(currentPage,'Телепорт',360,42,144,38,function()
 if not authorized then return end
 local a,b,c=tonumber(x.Text),tonumber(y.Text),tonumber(z.Text)
 if not a or not b or not c or a~=a or b~=b or c~=c or math.abs(a)>1000000 or math.abs(b)>1000000 or math.abs(c)>1000000 then status.Text='Координаты: числа от −1000000 до 1000000'; return end
 if player.Character and root then player.Character:PivotTo(CFrame.new(a,b,c)); status.Text='Телепорт выполнен локально' end
end)
button(currentPage,'Запомнить позицию',0,100,246,40,function()
 if not authorized then return end
 if root then local p=root.Position; x.Text=tostring(math.round(p.X)); y.Text=tostring(math.round(p.Y)); z.Text=tostring(math.round(p.Z)) end
end)
button(body,'ОТКЛЮЧИТЬ СКРИПТ',0,282,504,40,function() shutdown() end)
local gate
local mini=false
button(win,'−',486,14,36,30,function()
 mini=not mini
 body.Visible=authorized and not mini; tabbar.Visible=authorized and not mini; status.Visible=not mini
 if gate then gate.Visible=not authorized and not mini end
 win.Size=UDim2.fromOffset(540,mini and 54 or 500)
end)
button(gui,'AH',14,14,46,40,function() win.Visible=not win.Visible end)
button(gui,'OFF',70,14,54,40,function() shutdown() end)
local drag,start,startPos,touch
connect(title.InputBegan,function(input)
 if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then drag=true; start=input.Position; startPos=win.Position; touch=input.UserInputType==Enum.UserInputType.Touch and input or nil end
end)
connect(UIS.InputChanged,function(input)
 if drag and (input==touch or (not touch and input.UserInputType==Enum.UserInputType.MouseMovement)) then local d=input.Position-start; win.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,startPos.Y.Scale,startPos.Y.Offset+d.Y) end
end)
connect(UIS.InputEnded,function(input) if input==touch or input.UserInputType==Enum.UserInputType.MouseButton1 then drag=false end end)
connect(UIS.InputBegan,function(input,processed)
 if processed then return end
 if input.KeyCode==Enum.KeyCode.End then shutdown(); return end
 if input.KeyCode==Enum.KeyCode.RightShift then win.Visible=not win.Visible end
end)
local function bind(character)
 if not active then return end
 bindGeneration=bindGeneration+1
 local generation=bindGeneration
 stopFlight()
 flyButton.Text='Полёт (WASD / Space / Ctrl): ВЫКЛ'
 flyButton.TextColor3=white
 human=nil; root=nil
 local h=character:WaitForChild('Humanoid',10)
 local r=character:WaitForChild('HumanoidRootPart',10)
 if not active or generation~=bindGeneration or not h or not r or character~=player.Character then return end
 human=h; root=r
 savedSpeed=h.WalkSpeed; savedJump=h.JumpPower; savedJumpHeight=h.JumpHeight
 applyMovement()
end
connect(player.CharacterAdded,function(c) task.spawn(bind,c) end)
if player.Character then task.spawn(bind,player.Character) end
local elapsed=0
local lastCamera, lastViewport
shutdown=function()
 if not active then return end
 active=false
 bindGeneration=bindGeneration+1
 for _,c in ipairs(connections) do c:Disconnect() end
 table.clear(connections)
 stopFlight()
 clearESP()
 speedOn=false; jumpOn=false
 for _,tween in pairs(pendingTweens) do tween:Cancel() end
 table.clear(pendingTweens)
 if greetingSound then greetingSound:Stop(); greetingSound:Destroy(); greetingSound=nil end
 if human and human.Parent then
  human.WalkSpeed=savedSpeed
  human.JumpPower=savedJump
  human.JumpHeight=savedJumpHeight
 end
 player.CameraMode=originalMode
 if gui.Parent then gui:Destroy() end
end
connect(gui.Destroying,shutdown)
connect(Run.RenderStepped,function(dt)
 if not active then return end
 local camera=workspace.CurrentCamera
 if camera and (camera~=lastCamera or camera.ViewportSize~=lastViewport) then
  lastCamera=camera; lastViewport=camera.ViewportSize
  scale.Scale=math.max(.1,math.min(1,(lastViewport.X-24)/540,(lastViewport.Y-24)/500))
 end
 elapsed=elapsed+dt
 if elapsed>=2 then elapsed=0; if espOn then refreshESP() end end
 if flightOn and (not root or not root.Parent or not human or not human.Parent or human.Health<=0) then
  stopFlight()
  flyButton.Text='Полёт (WASD / Space / Ctrl): ВЫКЛ'
 end
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

-- Local key gate: a shared client-side key is an entry screen, not server authentication.
body.Visible=false
gate=make('Frame',win,{Position=UDim2.fromOffset(28,88),Size=UDim2.fromOffset(484,330),BackgroundTransparency=1})
text(gate,'ACCESS CONTROL',0,0,484,24,12).TextColor3=accent
text(gate,'Добро пожаловать',0,38,484,44,27)
text(gate,'Введи ключ доступа к Angels Hub',0,85,484,30,14)
local keyInput=make('TextBox',gate,{Name='AccessKey',PlaceholderText='Ключ доступа',Text='',ClearTextOnFocus=false,Position=UDim2.fromOffset(0,137),Size=UDim2.fromOffset(484,46),BackgroundColor3=Color3.fromRGB(30,23,28),TextColor3=white,TextSize=17,Font=Enum.Font.Gotham,BorderSizePixel=0})
round(keyInput)
local keyMessage=text(gate,'Ключ чувствителен к регистру.',0,251,484,52,12)
local function playGreeting()
 status.Text='Приветствуем в ангелс хаб • OFF / End — отключить'
 task.spawn(function()
  if not active then return end
  local ok,reason=pcall(function()
   local soundId
   if GREETING_AUDIO_ID~='' then
    soundId='rbxassetid://'..GREETING_AUDIO_ID
   else
    local assetFunction=getcustomasset or getsynasset
    if type(assetFunction)~='function' or type(writefile)~='function' then
     error('Локальное аудио не поддерживается executor')
    end
    local fileName='AngelHubWelcome_1_01_Red.ogg'
    if type(isfile)~='function' or not isfile(fileName) then
     local data=game:HttpGet(GREETING_URL)
     if not active then return end
     if type(data)~='string' or data:sub(1,4)~='OggS' or #data>1024*1024 then error('Некорректный аудиофайл') end
     writefile(fileName,data)
    end
    if not active then return end
    soundId=assetFunction(fileName)
   end
   if not active then return end
   greetingSound=make('Sound',gui,{SoundId=soundId,Volume=.65,Looped=false})
   greetingSound:Play()
  end)
  if active and not ok then
   status.Text='Добро пожаловать • голос недоступен • OFF / End'
   warn('AngelHub greeting: '..tostring(reason))
  end
 end)
end
local function unlock()
 if not active or authorized then return end
 local entered=keyInput.Text:match('^%s*(.-)%s*$')
 if entered~='Artur' then
  keyMessage.Text='Неверный ключ. Попробуй ещё раз.'
  keyMessage.TextColor3=accent
  animate(keyInput,{BackgroundColor3=Color3.fromRGB(95,26,36)})
  return
 end
 authorized=true
 gate.Visible=false
 body.Visible=not mini
 tabbar.Visible=not mini
 selectPage('Движение')
 animate(win,{BackgroundColor3=Color3.fromRGB(26,17,22)},.35)
 playGreeting()
end
button(gate,'ВОЙТИ В ANGELS HUB   →',0,199,484,44,unlock)
connect(keyInput.FocusLost,function(enterPressed) if enterPressed then unlock() end end)
text(gate,'RED EDITION  /  #1.01',0,308,484,22,11).TextColor3=accent
animate(win,{BackgroundTransparency=0},.3)
