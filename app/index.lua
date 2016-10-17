-- Scanning TrackPlug folder
local tbl = System.listDirectory("ux0:/data/TrackPlug")

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
	if seconds > 0 then
		res = res .. seconds .. "s "
	end
	return res
end

-- Extracts title name from an SFO file descriptor
function extractTitle(handle)
	io.seek(handle, 0x0C, SET)
	local data_offs = bin2int(io.read(handle, 4))
	local title_idx = bin2int(io.read(handle, 4)) - 3 -- STITLE seems to be always the MAX-3 entry
	io.seek(handle, (title_idx << 4) + 0x04, CUR)
	local len = bin2int(io.read(handle, 4))
	local dummy = io.read(handle, 4)
	local offs = bin2int(io.read(handle, 4))
	io.seek(handle, data_offs + offs, SET)
	return io.read(handle, len)
end

-- Loading unknown icon
local unk = Graphics.loadImage("app0:/unk.png")

-- GekiHEN contest splashscreen
local splash = Graphics.loadImage("app0:/splash.png")
local tmr = Timer.new()
local spl = 0
local setup_finished = false
while Timer.getTime(tmr) < 3000 do
	Graphics.initBlend()
	Graphics.drawImage(0, 0, splash)
	Graphics.termBlend()
	Screen.flip()
	Screen.waitVblankStart()
	spl = spl + 1
	if not setup_finished and spl > 3 then
		setup_finished = true
		
		-- Getting region, playtime, icon and title name for any game
		for i, file in pairs(tbl) do
			System.wait(5000)
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
			if System.doesFileExist("ux0:/app/" .. titleid .. "/sce_sys/param.sfo") then
				fd = io.open("ux0:/app/" .. titleid .. "/sce_sys/param.sfo", FREAD)
				file.title = extractTitle(fd)
				io.close(fd)
			else
				file.title = "Unknown Title"
			end
			file.id = titleid
			fd = io.open("ux0:/data/TrackPlug/" .. file.name, FREAD)
			file.rtime = bin2int(io.read(fd, 4))
			file.ptime = FormatTime(file.rtime)
			io.close(fd)
		end
		
	end
end
Timer.destroy(tmr)
Graphics.freeImage(splash)

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
function RenderList()
	local y = 8
	local i = list_idx
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
	local sclr = Color.new(sel_val, sel_val, sel_val)
	Graphics.fillRect(0, 960, 4, 138, sclr)
	Graphics.debugPrint(800, 520, "Order: " .. orders[order_idx], white)
	while i <= list_idx + 3 do
		if i > #tbl then
			break
		end
		Graphics.drawImage(5, y, tbl[i].icon)
		Graphics.debugPrint(150, y + 25, tbl[i].title, yellow)
		Graphics.debugPrint(150, y + 45, "Title ID: " .. tbl[i].id, white)
		Graphics.debugPrint(150, y + 65, "Region: " .. tbl[i].region, white)
		Graphics.debugPrint(150, y + 85, "Playtime: " .. tbl[i].ptime, white)
		y = y + 132
		i = i + 1
	end
end

-- Main loop
local f_idx = 1
local oldpad = Controls.read()
while #tbl > 0 do
	Graphics.initBlend()
	Screen.clear()
	RenderList()
	if freeze then
		showAlarm("Do you want to delete this record permanently?", f_idx)
	end
	Graphics.termBlend()
	Screen.flip()
	Screen.waitVblankStart()
	local pad = Controls.read()
	if Controls.check(pad, SCE_CTRL_UP) and not Controls.check(oldpad, SCE_CTRL_UP) then
		if freeze then
			f_idx = 1
		else
			list_idx = list_idx - 1
			if list_idx == 0 then
				list_idx = #tbl
			end
		end
	elseif Controls.check(pad, SCE_CTRL_DOWN) and not Controls.check(oldpad, SCE_CTRL_DOWN) then
		if freeze then
			f_idx = 2
		else
			list_idx = list_idx + 1
			if list_idx > #tbl then
				list_idx = 1
			end
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