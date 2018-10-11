-- Creating dirs in case they do not exist
System.createDirectory("ux0:/data/TrackPlug")
System.createDirectory("ux0:/data/TrackPlugArchive")

-- Scanning TrackPlug folder
local tbl = System.listDirectory("ux0:/data/TrackPlug")
if tbl == nil then
	tbl = {}
end

-- Convert a 32 bit binary string to a integer
function bin2int(str)
	local b1, b2, b3, b4 = string.byte(str, 1, 4)
	return (b4 << 24) + (b3 << 16) + (b2 << 8) + b1
end

-- Format raw time data
function FormatTime(val)
	local minutes = math.floor(val/60)
	local seconds = val%60
	local hours = math.floor(minutes/60)
	local minutes = minutes%60
	local res = ""
	if hours > 0 then
		res = hours .. "h "
	end
	if minutes > 0 then
		res = res .. minutes .. "m "
	end
	res = res .. seconds .. "s "
	return res
end

-- Recover title from homebrew database
function recoverTitle(tid)
	local file = System.openFile("ux0:/data/TrackPlugArchive/" .. tid .. ".txt", FREAD)
	fsize = System.sizeFile(file)
	local title = System.readFile(file, fsize)
	System.closeFile(file)
	return title
end

-- Extracts title name from an SFO file
function extractTitle(file, tid)
	local data = System.extractSFO(file)
	if System.doesFileExist("ux0:/data/TrackPlugArchive/" .. tid .. ".txt") then
		System.deleteFile("ux0:/data/TrackPlugArchive/" .. tid .. ".txt")
	end
	local file = System.openFile("ux0:/data/TrackPlugArchive/" .. tid .. ".txt", FCREATE)
	System.writeFile(file, data.title, string.len(data.title))
	System.closeFile(file)
	return data.title
end

-- Loading unknown icon
local unk = Graphics.loadImage("app0:/unk.png")
		
-- Getting region, playtime, icon and title name for any game
for i, file in pairs(tbl) do
	if file.name == "config.lua" then
		dofile("ux0:/data/TrackPlug/"..file.name)
		cfg_idx = i
	else
		local titleid = string.sub(file.name,1,-5)
		local regioncode = string.sub(file.name,1,4)
		if regioncode == "PCSA" or regioncode == "PCSE" then
			file.region = "USA"
		elseif regioncode == "PCSB" then
			file.region = "EUR"
		elseif regioncode == "PCSF" then
			file.region = "AUS"
		elseif regioncode == "PCSG" then
			file.region = "JPN"
		elseif regioncode == "PCSH" then
			file.region = "ASN"
		else
			file.region = "UNK"
		end
		if System.doesFileExist("ur0:/appmeta/" .. titleid .. "/icon0.png") then
			file.icon = Graphics.loadImage("ur0:/appmeta/" .. titleid .. "/icon0.png")
		else
			file.icon = unk
		end
		if System.doesFileExist("ux0:/data/TrackPlugArchive/" .. titleid .. ".txt") then
			file.title = recoverTitle(titleid)
		elseif System.doesFileExist("ux0:/app/" .. titleid .. "/sce_sys/param.sfo") then
			file.title = extractTitle("ux0:/app/" .. titleid .. "/sce_sys/param.sfo", titleid)
		else
			file.title = "Unknown Title"
		end
		file.id = titleid
		fd = System.openFile("ux0:/data/TrackPlug/" .. file.name, FREAD)
		file.rtime = bin2int(System.readFile(fd, 4))
		file.ptime = FormatTime(file.rtime)
		System.closeFile(fd)
	end
end
if cfg_idx ~= nil then
	table.remove(tbl, cfg_idx)
end

-- Background wave effect
local colors = {
	{Color.new(0,132,255), Color.new(72,185,255), Color.new(0,132,255)},  -- Cyan
	{Color.new(255,132,0), Color.new(255,185,72), Color.new(255,132,0)},  -- Orange
	{Color.new(255,72,72), Color.new(255,132,132), Color.new(255,72,72)}, -- Pink
	{Color.new(255,0,0), Color.new(255,72,72), Color.new(255,0,0)}, 	  -- Red
	{Color.new(255,72,255), Color.new(255,185,255), Color.new(255,72,255)},	-- Magenta
	{Color.new(72,72,72), Color.new(0,0,0), Color.new(0,255,0)}	-- Black'N'Green
}
if col_idx == nil then
	col_idx = 6
end
local function LoadWave(height,dim,f,style,x_dim)	
	if style == 1 then
		f=f or 0.1
		local onda={pi=math.pi,Frec=f,Long_onda=dim,Amplitud=height}
		function onda:color(a,b,c) self.a=a self.b=b self.c=c end
		function onda:init(desfase)
			desfase=desfase or 0
			if not self.contador then
				self.contador=Timer.new()
			end
			if not self.a or not self.b or not self.c then
				self.a = 0
				self.b = 0
				self.c = 255
			end
			local t,x,y,i
			t = Timer.getTime(self.contador)/1000+desfase
			for x = 0,x_dim,4 do
				y = 252+self.Amplitud*math.sin(2*self.pi*(t*self.Frec-x/self.Long_onda))
				i = self.Amplitud*(-2*self.pi/self.Long_onda)*math.cos(2*self.pi*(t*self.Frec-x/self.Long_onda))
				Graphics.drawLine(x-200,x+200,y-i*200,y+i*200,Color.new(self.a,self.b,self.c,math.floor(x/40)))
			end
			collectgarbage()
		end
		function onda:destroy()
			Timer.destroy(self.contador)
		end
		return onda
	end
	if style == 2 then
		f=f or 0.1
		local onda={pi=math.pi,Frec=f,Long_onda=dim,Amplitud=height}
		function onda:color(a,b,c) self.a=a self.b=b self.c=c end
		function onda:init(desfase)
			desfase=desfase or 0
			if not self.contador then
				self.contador=Timer.new()
			end
			if not self.a or not self.b or not self.c then
				self.a = 0
				self.b = 0
				self.c = 255
			end
			local t,x,y,i,a
			t = Timer.getTime(self.contador)/1000+desfase
			if self.Amplitud <= 5 then
				self.aumento = true
			elseif self.Amplitud >= 110 then
				self.aumento = false
			end
			if self.aumento then
				self.Amplitud = self.Amplitud+0.1
			else
				self.Amplitud = self.Amplitud-0.1
			end
			for x = 0,x_dim,10 do
				y = 272+self.Amplitud*math.sin(2*self.pi*(t*self.Frec-x/self.Long_onda))
				i = self.Amplitud*(-2*self.pi/self.Long_onda)*math.cos(2*self.pi*(t*self.Frec-x/self.Long_onda))
				for a = -3,3 do
					Graphics.drawLine(x-20,x+20,a+y-i*20,a+y+i*20,Color.new(self.a,self.b,self.c,25-math.abs(a*5)))
				end
			end
			collectgarbage()
		end
		function onda:destroy()
			Timer.destroy(self.contador)
		end
		return onda
	end
	if style == 3 then
		f=f or 0.1
		local onda={pi=math.pi,Frec=f,Long_onda=dim,Amplitud=height}
		function onda:color(a,b,c) self.Color=Color.new(a,b,c,40) end
		function onda:init(desfase)
			desfase=desfase or 0
			if not self.contador then
				self.contador=Timer.new()
			end
			if not self.Color then
				self.Color=Color.new(0,0,255,40)
			end
			local t,x,y,i
			t = Timer.getTime(self.contador)/1000+desfase
			for x = 0,x_dim do
				y = 252+self.Amplitud*math.sin(2*self.pi*(t*self.Frec-x/self.Long_onda))
				Graphics.drawLine(x,x,y,240,self.Color)
			end
			collectgarbage()
		end
		function onda:destroy()
			Timer.destroy(self.contador)
		end
		return onda
	end
end
wav = LoadWave(15,1160, 0.1, 2, 960)
wav:color(Color.getR(colors[col_idx][3]),Color.getG(colors[col_idx][3]),Color.getB(colors[col_idx][3]))

-- Internal stuffs
local list_idx = 1
local order_idx = 1
local orders = {"Name", "Playtime"}

-- Ordering titles
table.sort(tbl, function (a, b) return (a.title:lower() < b.title:lower() ) end)
function resortList(o_type, m_idx)
	local old_id = tbl[m_idx].id
	if o_type == 1 then -- Name
		table.sort(tbl, function (a, b) return (a.title:lower() < b.title:lower() ) end)
	elseif o_type == 2 then -- Playtime
		table.sort(tbl, function (a, b) return (a.rtime > b.rtime ) end)
	end
	for i, title in pairs(tbl) do
		if title.id == old_id then
			return i
		end
	end
end

-- Internal stuffs
local white = Color.new(255, 255, 255)
local yellow = Color.new(255, 255, 0)
local grey = Color.new(40, 40, 40)

-- Shows an alarm with selection on screen
local alarm_val = 128
local alarm_decrease = true
function showAlarm(title, select_idx)
	if alarm_decrease then
		alarm_val = alarm_val - 4
		if alarm_val == 40 then
			alarm_decrease = false
		end
	else
		alarm_val = alarm_val + 4
		if alarm_val == 128 then
			alarm_decrease = true
		end
	end
	local sclr = Color.new(alarm_val, alarm_val, alarm_val)
	Graphics.fillRect(200, 760, 200, 280, grey)
	Graphics.debugPrint(205, 205, title, yellow)
	Graphics.fillRect(200, 760, 215 + select_idx * 20, 235 + select_idx * 20, sclr)
	Graphics.debugPrint(205, 235, "Yes", white)
	Graphics.debugPrint(205, 255, "No", white)
end

-- Scroll-list Renderer
local sel_val = 128
local decrease = true
local freeze = false
local mov_y = 0
local mov_step = 0
local new_list_idx = nil
local real_i = 1
local big_tbl = {}
function RenderList()
	local r_max = 0
	local r = 0
	if #tbl < 4 then
		r_max = 8
	else
		r_max = 2
	end
	while r < r_max do
		for k, v in pairs(tbl) do
			table.insert(big_tbl, v)
		end
		r = r + 1
	end
	local y = -124
	local i = list_idx - 1
	if not freeze then
		if decrease then
			sel_val = sel_val - 4
			if sel_val == 0 then
				decrease = false
			end
		else
			sel_val = sel_val + 4
			if sel_val == 128 then
				decrease = true
			end
		end
	end
	local sclr = Color.new(sel_val, sel_val, sel_val, 100)
	Graphics.fillRect(0, 960, 4, 140, sclr)
	Graphics.debugPrint(800, 520, "Order: " .. orders[order_idx], white)
	if mov_y ~= 0 then
		mov_y = mov_y + mov_step
		if math.abs(mov_y) >= 132 then
			mov_y = 0
			list_idx = new_list_idx
			i = new_list_idx - 1
		end
	end
	while i <= list_idx + 4 do
		if i < 1 then
			real_i = i
			i = #big_tbl - math.abs(i)
		end
		if i ~= list_idx + 4 then
			Graphics.drawImage(5, y + mov_y, big_tbl[i].icon)
		end
		Graphics.debugPrint(150, y + 25 + mov_y, big_tbl[i].title, yellow)
		Graphics.debugPrint(150, y + 45 + mov_y, "Title ID: " .. big_tbl[i].id, white)
		Graphics.debugPrint(150, y + 65 + mov_y, "Region: " .. big_tbl[i].region, white)
		Graphics.debugPrint(150, y + 85 + mov_y, "Playtime: " .. big_tbl[i].ptime, white)
		local r_idx = i % #tbl
		if r_idx == 0 then
			r_idx = #tbl
		end
		Graphics.debugPrint(900, y + 85 + mov_y, "#" .. r_idx, white)
		y = y + 132
		if real_i <= 0 then
			i = real_i
			real_i = 1
		end
		i = i + 1
	end
end

-- Main loop
local f_idx = 1
local oldpad = Controls.read()
while #tbl > 0 do
	Graphics.initBlend()
	Graphics.fillRect(0,960,0,544,colors[col_idx][2])
	wav:init()
	RenderList()
	if freeze then
		showAlarm("Do you want to delete this record permanently?", f_idx)
	end
	Graphics.termBlend()
	Screen.flip()
	Screen.waitVblankStart()
	local pad = Controls.read()
	if Controls.check(pad, SCE_CTRL_UP) and mov_y == 0 then
		if freeze then
			f_idx = 1
		else
			new_list_idx = list_idx - 1
			if new_list_idx == 0 then
				new_list_idx = #tbl
			end
			mov_y = 1
			mov_step = 22
		end
	elseif Controls.check(pad, SCE_CTRL_DOWN) and mov_y == 0 then
		if freeze then
			f_idx = 2
		else
			new_list_idx = list_idx + 1
			if new_list_idx > #tbl then
				new_list_idx = 1
			end
			mov_y = -1
			mov_step = -22
		end
	elseif Controls.check(pad, SCE_CTRL_LTRIGGER) and not Controls.check(oldpad, SCE_CTRL_LTRIGGER) and not freeze then
		order_idx = order_idx - 1
		if order_idx == 0 then
			order_idx = #orders
		end
		list_idx = resortList(order_idx, list_idx)
	elseif Controls.check(pad, SCE_CTRL_RTRIGGER) and not Controls.check(oldpad, SCE_CTRL_RTRIGGER) and not freeze then
		order_idx = order_idx + 1
		if order_idx > #orders then
			order_idx = 1
		end
		list_idx = resortList(order_idx, list_idx)
	elseif Controls.check(pad, SCE_CTRL_TRIANGLE) and not Controls.check(oldpad, SCE_CTRL_TRIANGLE) and not freeze then
		freeze = true
		f_idx = 1
	elseif Controls.check(pad, SCE_CTRL_CROSS) and not Controls.check(oldpad, SCE_CTRL_CROSS) and freeze then
		freeze = false
		if f_idx == 1 then -- Delete
			System.deleteFile("ux0:/data/TrackPlug/" .. tbl[list_idx].name)
			table.remove(tbl, list_idx)
			if list_idx > #tbl then
				list_idx = list_idx - 1
			end
		end
	elseif Controls.check(pad, SCE_CTRL_SELECT) and not Controls.check(oldpad, SCE_CTRL_SELECT) then
		col_idx = col_idx + 1
		if col_idx > #colors then
			col_idx = 1
		end
		wav:color(Color.getR(colors[col_idx][3]),Color.getG(colors[col_idx][3]),Color.getB(colors[col_idx][3]))
		fd = System.openFile("ux0:/data/TrackPlug/config.lua", FCREATE)
		System.writeFile(fd, "col_idx="..col_idx, 9)
		System.closeFile(fd)
	end
	oldpad = pad
end

-- No games played yet apparently
while true do
	Graphics.initBlend()
	Screen.clear()
	Graphics.debugPrint(5, 5, "No games tracked yet.", white)
	Graphics.termBlend()
	Screen.flip()
	Screen.waitVblankStart()
end