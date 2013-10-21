--[[

Pure Goear Core functions

--]]

function search(searchtext, currpage)
		success, postresult = pge.net.postform("http://77.67.11.180/reqsearch.php?q="..string.gsub(searchtext, " ","+").."&p="..currpage, "", 2048)
		--sleep for one and a half second
		pge.delay(500*500)
		return get_results(postresult)
end

function get_results(s)
	local tags =  { "<pre>","</pre>","/listen/","/","'>","</a>"}
	local lista = {}
	local item = {}
	local singleresult = ""
	local id = ""
	local nombre = ""
	local index = string.find(s,tags[1],0)
	local endix = string.find(s,tags[2],0)
	while(index~=nil and endix~=nil) do
  		-- Recorremos todo el texto buscando
  		be = index
  		en = endix
  		-- Buscamos 1 resultado
  		singleresult = string.sub(s,be+5,en-1)
  		-- Buscamos el ID
  		subindex = string.find(singleresult,tags[3],0)
  		if(subindex~=nil) then
			subindex = subindex+8
  			subendix = string.find(singleresult,tags[4],subindex)
  			-- Obtenemos id
  			id = string.sub(singleresult,subindex,subendix-1)
  			-- Buscamos el nombre
  			subindex = string.find(singleresult,tags[5],0)
  			subindex = subindex+2
  			subendix = string.find(singleresult,tags[6],subindex)
  			-- Obtenemos nombre
  			nombre = string.sub(singleresult, subindex,subendix-1)  
  			-- Insertamos en la tabla final
  			table.insert(item, nombre)
			table.insert(item, id)
			table.insert(lista, item)
			item = {}  
  			index = string.find(s,tags[1],be+5)
  			endix = string.find(s,tags[2],en+6)
		else
			lista[0] = -1
			break
		end
	end
return lista
end


function parse_xml(xmltext)
	xml = {artist = "", title = "", filename=""}
	index = string.find(xmltext,"<song path=",0)
	endix = string.find(xmltext,"bild=",index)
	xml.filename = string.sub(xmltext, index+12,endix-3)
	index = string.find(xmltext, "artist=",endix)
	endix = string.find(xmltext, "title=",index)
	xml.artist = string.sub(xmltext, index+8,endix-3)
	index = endix
	endix = string.find(xmltext, "/>", index)
	xml.title = string.sub(xmltext, index+7, endix-2)
	return xml
end

function download_song(id, prompt)
	local url = ""
	xml = {}
	--gen the url
	url = url.."http://www.goear.com/localtrackhost.php?f="..id
	success, postresult = pge.net.postform(url, "", 2048)
	--sleep for one and a half second
	pge.delay(500*500)
	xml = parse_xml(postresult)
	if(prompt==true) then
		local localfile = input_dialog(LANG.MSC6,xml.title.." - "..xml.artist)
		pge.http.getfile(xml.filename, BASE_MUSIC_DIR..localfile..".mp3")
	else
		pge.http.getfile(xml.filename, BASE_MUSIC_DIR..xml.title.." - "..xml.artist..".mp3")
	end
end

function download_list(downlist)
	local i
	for i=1, #downlist do
		currsong=i
		totalsong=#downlist
		download_song(downlist[i][2], false)
	end
end


--[[

Core functions

--]]

function truncate_string(s, lenght)
	if lenght == nil then lenght = 20 end
	return string.sub(s, 1, lenght-1)
end

function take_screenshot(prefix, path)
	if prefix==nil then prefix = "screenshot_" end
	if path==nil then path = "ms0:/PICTURE/" end
	local ssnumber = 1
	local screenshotfile = path..prefix..ssnumber..".png"
		if pge.file.exists(screenshotfile) then
			ssnumber = ssnumber + 1
		else
			pge.gfx.screenshot(screenshotfile)
		end
end

function check_update(quiet)
	if pge.net.isconnected()==false then
		msg_dialog(LANG.MSG12)
		return -1
	end
	if quiet==nil then
		quiet = false 
	else
		quiet = true
	end
	--http://www.cristianlizana.com/goearpsp/status.php
	local currversion = check_status("http://www.cristianlizana.com/goearpsp/status.php","checkversion=0")
	local a = string.find(currversion, "ENDVERSION")
	currversion = string.sub(currversion, 1, a-1)
	local result = -1
	local updatefile
	if(currversion~=APP_VERSION) then
		result = msg_dialog(LANG.MSG13A.."\n"..LANG.MSG13B, 1)
		if result==0 then
			updatefile = pge.net.getfile("http://www.cristianlizana.com/goearpsp/update.lua","update.lua")
			dofile("update.lua")
		end
	else
		if(quiet==false) then
			msg_dialog(LANG.MSG14)
		end
	end
end

function check_status(url, value)
	local a, res = pge.net.postform(url.."?"..value, "", 1024)
	return res
end

function get_list_size(list)
local count = 0
	for i,j in pairs(list) do
		count = count + 1
	end
	return count
end

function save_config_file(list, filename)
	if filename==nil then filename = COMMON_DIR.."config.dat" end
	if pge.file.exists(filename)==true then 
		if(pge.file.remove(filename)==false) then
			return false
		end
	end 
	local filehandle = pge.file.open(filename, PGE_FILE_CREATE + PGE_FILE_WRONLY)
	for i = 1, #list do
		filehandle:write(list[i].."\n")
	end
	filehandle:close()
	return true
end

function round(what, precision)
   return math.floor(what*math.pow(10,precision)+0.5) / math.pow(10,precision)
end

function get_line(s, b, first_pattern, last_pattern)
	local x = 0
	local y = 0
	x = string.find(s, first_pattern, b)
	y = string.find(s, last_pattern, x)
	if(x~=nil and y~=nil) then
		return y, string.sub(s, x+1, y-1)
	end
	return nil, nil
end

function parse_file(s)
	local t = {}
	local a = 0
	local b = 0
	local l = ""
	local m = ""
	a, l = get_line(s, 0, "_", "=")
	b, m = get_line(s, 0, "=", "*")
	while (a~=nil or b~=nil) do
		t[l] = m
		a, l = get_line(s, a, "_", "=")
		b, m = get_line(s, b, "=", "*")
	end
	return t
end

function split_color(c)
	local colors = {}
	local a = 0
	local b = 0
	a = string.find(c,",",0)
	colors['red'] = string.sub(c, 0, a-1)
	b = string.find(c,",",a+1)
	colors['green'] = string.sub(c, a+1, b-1)
	colors['blue'] = string.sub(c, b+1)
	return colors
end

function get_path(filename)
	local a = 0
	local b = 0
	a = string.find(filename, '/')
	b = string.find(filename, '/', a+1)
	return string.sub(filename, 0, b)
end

--[[

File manipulation functions

--]]

function load_conf_file(fname)
	filehandle = pge.file.open(fname, PGE_FILE_RDONLY)
	if(filehandle~=nil) then
		f_size = filehandle:seek(0, PGE_FILE_END)
		filehandle:seek(0, PGE_FILE_SET)
		f_buffer = filehandle:read(f_size)
		filehandle:close()
		filehandle = nil
		return f_buffer
	end
end

function load_languages(path)
	local lang_list = {}
	local final_lang_list = {}
	local tmp_lang = {}
	local buffer = ""
	local lang_dir = pge.dir.open(path)
	local lang_files = lang_dir:read() --Nombres de archivos .lng
	lang_dir:close()
	for i = 1, #lang_files do
		if string.lower(string.sub(lang_files[i].name,-3)) == "lng" then
			table.insert(lang_list, lang_files[i].name)
		end
	end
	
	for i = 1, #lang_list do
		buffer = load_conf_file(path..lang_list[i])
		tmp_lang = parse_file(buffer)
		table.insert(final_lang_list, tmp_lang)
		buffer = nil
		tmp_lang = nil
	end
	return final_lang_list
end

function change_language(langs, newlang)
	if newlang then
		for i = 1, #langs do
			if langs[i].NAME == newlang then
				return langs[i]
			end
		end
	end
	error('Error cargando el idioma')
end

function load_skins(skinsDir)
	local dirList = {}
	local finalSkinList = {}
	local sknDir = pge.dir.open(skinsDir) --opens the directory "ms0:/MUSIC/"
	local currDir
	local currDir_files
	sknDir_files = sknDir:read() --reads the directory and returns it to music_files
	sknDir:close() --closes the directory
	-- We load all the skins folder
	for i = 1, #sknDir_files do --starts the for loop that checks all fields of the table music_files
		if(sknDir_files[i].dir) then
			table.insert(dirList, sknDir_files[i].name)
		end
	end
	
	for i = 1, #dirList do
		currDir = pge.dir.open(skinsDir..dirList[i].."/")
		currDir_files = currDir:read()
		currDir:close()
		for j = 1, #currDir_files do
			if(not currDir_files[j].dir) then
				if string.lower(string.sub(currDir_files[j].name,-3)) == "skn" then
					table.insert(finalSkinList, skinsDir..dirList[i].."/"..currDir_files[j].name)
				end
			end
		end
	end
	return parse_skins(finalSkinList)
end

-- Load valid skins, insert it into a table (with name of the skin as id), 
-- return the list. 

function parse_skins(skinList)
	local finalSkinList = {}
	local skinfile = ""
	local tempSkin = {}
	
	for i = 1, #skinList do
		skinfile = load_conf_file(skinList[i])
		tempSkin = parse_file(skinfile)
		tempSkin['path'] = skinList[i]
		finalSkinList[tempSkin.Name] = tempSkin
		tempSkin = nil
		skinfile = nil	
	end
	return finalSkinList
end

function change_skin(skin)
	local path = get_path(skin.path)
	small = nil
	medium = nil
	big = nil
	color1 = nil
	color2 = nil
	color3 = nil
	fontOverColor = nil
	bgColor = nil
	backImage = nil
	if(skin.font) then
		small = pge.font.load(path..skin.font, 9, PGE_RAM)
		medium = pge.font.load(path..skin.font, 12, PGE_RAM)
		big = pge.font.load(path..skin.font, 16, PGE_RAM)
		if not small or not medium or not big then
			error("Error cargando la fuente.")
		end
	else
		small = pge.font.load(COMMON_DIR.."verdana.ttf", 9, PGE_RAM)
		medium = pge.font.load(COMMON_DIR.."verdana.ttf", 12, PGE_RAM)
		big = pge.font.load(COMMON_DIR.."verdana.ttf", 16, PGE_RAM)
		if not small or not medium or not big then
			error("Error cargando la fuente.")
		end
	end
	if(skin.color1) then
		rgb = split_color(skin.color1)
		color1 = pge.gfx.createcolor(rgb.red, rgb.green, rgb.blue)
	else
		color1 = pge.gfx.createcolor(75, 155, 225)
	end
	
	if(skin.color2) then
		rgb = split_color(skin.color2)
		color2 = pge.gfx.createcolor(rgb.red, rgb.green, rgb.blue)
	else
		color2 = pge.gfx.createcolor(45, 90, 160)
	end
	
	if(skin.color3) then
		rgb = split_color(skin.color3)
		color3 = pge.gfx.createcolor(rgb.red, rgb.green, rgb.blue)
	else
		color3 = pge.gfx.createcolor(0, 0, 0)
	end
	
	if(skin.fontOverColor) then
		rgb = split_color(skin.fontOverColor)
		fontOverColor = pge.gfx.createcolor(rgb.red, rgb.green, rgb.blue)
	else
		fontOverColor = pge.gfx.createcolor(10, 10, 10)
	end
	
	if(skin.bgColor) then
		rgb = split_color(skin.bgColor)
		bgColor = pge.gfx.createcolor(rgb.red, rgb.green, rgb.blue)
	end
	
	if(skin.fontColor) then
		rgb = split_color(skin.fontColor)
		fontColor = pge.gfx.createcolor(rgb.red, rgb.green, rgb.blue)
	else
		fontColor = pge.gfx.createcolor(255, 255, 255)
	end
	
	if(skin.bgFile) then
		backImage = pge.texture.load(path..skin.bgFile)
	end
	
end

function readmp3dir(mp3path)
	
	-- Open the directory
	dir = pge.dir.open(mp3path)
	
	-- Check it opened correctly
	if dir then
	
		-- Read the contents of the directory
		dircontents = dir:read()
	
		-- Check we read the contents correctly
		if not dircontents then
			return nil
		end
	
		-- Close the directory
		dir:close()
		
		for i = 1, #dircontents do
			if not dircontents[i].dir then
				if string.lower(string.sub(dircontents[i].name, -3))~="mp3" then
					table.remove(dircontents, i)
				end
			else
				table.remove(dircontents, i)
			end
		end
		
		-- Return the directory contents
		return dircontents
	else
		error("Error abriendo directorio.")
	end

end


--[[

Dialog, display functions

--]]


function splash_screen(splash_file, pause_time)
	local delayAmmount = 1
	local bgImage = pge.texture.load(splash_file)
	bgImage:activate()
	if(pause_time == nil) then
		pause_time = 1
	end
	for i=0, 255 do
		pge.gfx.clearscreen()
		pge.gfx.startdrawing()
		bgImage:draweasy(0, 0, 0, i)
		pge.delay(delayAmmount)
		pge.gfx.swapbuffers()
		pge.gfx.enddrawing()
	end
	--pge.delay(pause_time*1000000)
	for i=0, 255 do
		pge.gfx.clearscreen()
		pge.gfx.startdrawing()
		bgImage:draweasy(0, 0, 0, 255-i)
		pge.delay(delayAmmount)
		pge.gfx.swapbuffers()
		pge.gfx.enddrawing()
	end	
end


function input_dialog(desc, intext)
	local done = false
	local enabled = true
	local text = ""
	if(intext==nil) then
		intext = ""
	end
	if not pge.utils.oskinit(desc, intext) then
		error("Error iniciando el osk.")
	end
	while pge.running() do
		-- Start drawing
		pge.gfx.startdrawing()
	
		-- Clear screen (to black)
		pge.gfx.clearscreen()
		if not enabled then
			return text
		end
		pge.gfx.enddrawing()
		if enabled then
		
			done, text = pge.utils.oskupdate()
			if done then 
				enabled = false
			end
		end
		pge.gfx.swapbuffers()
	end
end

function msg_dialog(txtmsg, tipo)
local enabled = true
local pressed = -1
local opciones
local result = ""
	if tipo==nil or tipo==0 then
		opciones = PGE_UTILS_MSG_DIALOG_DEFAULT_BUTTON_NO
	elseif tipo==1 then
		opciones = PGE_UTILS_MSG_DIALOG_YESNO_BUTTONS
	end
	if not pge.utils.msginit(txtmsg, opciones) then
		error("Error iniciando el msgdialog.")
	end
	while pge.running() do
		-- Start drawing
		pge.gfx.startdrawing()
		-- Clear screen (to black)
		pge.gfx.clearscreen()
		if not enabled then
			return result
		end
		
		pge.gfx.enddrawing()
		
		if enabled then
		-- pge.utils.msgupdate() must be called after pge.gfx.enddrawing(), but before pge.gfx.swapbuffers()
		pressed = pge.utils.msgupdate()
			if pressed == PGE_UTILS_MSG_DIALOG_RESULT_YES then
				result = 0
				enabled = false
			elseif pressed == PGE_UTILS_MSG_DIALOG_RESULT_NO then
				result = 1
				enabled = false
			elseif pressed == PGE_UTILS_MSG_DIALOG_RESULT_BACK then
				result = 2
				enabled = false
			elseif pressed ~= PGE_UTILS_DIALOG_RUNNING then
				result = -1
				enabled = false
			end			
		end
		pge.gfx.swapbuffers()
	end
end

function net_dialog()
	local enabled = true
	local state = -1

	if not pge.net.init() then
		error("Error iniciando el modulo net.")
	end

	if not pge.utils.netinit() then
		error("Error iniciando el dialogo net")
	end

	while pge.running() do
		pge.controls.update()
		pge.gfx.startdrawing()
		pge.gfx.clearscreen()
		if not enabled then
			return state
		end
		pge.gfx.enddrawing()
		if enabled then
			-- pge.utils.netupdate() must be called after pge.gfx.enddrawing(), but before pge.gfx.swapbuffers()
			state = pge.utils.netupdate()
			if state == 0 then
				enabled = false
			elseif state == 1 then
				enabled = false
				pge.net.shutdown()
			elseif state ~= PGE_UTILS_DIALOG_RUNNING then
				enabled = false
				pge.net.shutdown()
			end
		end
		pge.gfx.swapbuffers()
	end
	state = nil
	enabled = nil
end

function download_callback(block, sizefinal)
	local percent
	if(curr==nil) then curr=0 end
	curr = curr + #block
	percent = ((curr * 100) / sizefinal)
	
	pge.gfx.startdrawing()
	pge.gfx.clearscreen()
	-- Activate the font
	
	draw_bg(LANG.MSC7.." "..currsong.."/"..totalsong)
	pge.gfx.drawline(0, 255, 480, 255, color3)
	draw_footer()
	medium:activate()
	--medium:print(25, 50, white, LANG[3])
	medium:print(25, 100, fontColor, LANG.ARTIST..": "..xml.artist)
	medium:print(25, 120, fontColor, LANG.TITLE..": "..xml.title)
	medium:print(25, 140, fontColor, LANG.MSC8..": "..round(sizefinal/1024,0).." kb")
	
	pge.gfx.drawrectgrad(40, 180, (round(percent,0)*4), 16, color1, color1, color2, color2, 0)
	medium:print(200, 184, fontColor, round(percent,0).." "..LANG.MSC9)
	pge.gfx.drawline(40, 180, 440, 180, color3)
	pge.gfx.drawline(40, 196, 440, 196, color3)
	pge.gfx.drawline(40, 180, 40, 196, color3)
	pge.gfx.drawline(440, 180, 440, 196, color3)
	
	pge.gfx.enddrawing()
	
	pge.gfx.swapbuffers()
	
	if(percent>=100) then 
		curr=nil 
		percent = 0
		end	
end

function preview_mp3(id, filename, chunkpercent)
	local url = ""
	local xml = {}
	collectgarbage("collect")
	--gen the url
	url = url.."http://www.goear.com/localtrackhost.php?f="..id
	success, postresult = pge.net.postform(url, "", 2048)
	--sleep for one and a half second
	pge.delay(500*500)
	xml = parse_xml(postresult)
	url = xml.filename
	pge.mp3.stop()
	if filename==nil then filename = COMMON_DIR.."temp.mp3" end
	if pge.file.exists(filename)==true then
		if(pge.file.remove(filename)==false) then
			return false
		end
	end
	
	pge.http.getfile(url, filename, chunkpercent)
	-- Start playing the MP3
	pge.mp3.play(filename)
	
end


--[[
pge.http
 
A more flexible HTTP module using pge.net.socket.
 
Provides the following functions:
   string = urlencode(string)
   string = urldecode(string)
      Respectively, encode and decode URL escape codes (%xx).
 
   scheme, host, port, path = parseurl(url)
      Tries to parse a URL; on success returns each segment.
      If no port was specified, tries to use a reasonable default.
 
   boolean, result = getstring(url)
      Retrieves a URL using HTTP GET, returning the contents as a string.
      On success, returns 'true' and the contents.
      On failure, returns 'false', an error code, and an error message.
 
   boolean, number, string = getfile(url, filename)
      Retrieves a URL using HTTP GET, saving the contents to a file.
      Returns 'true' or 'false', a result code, and a result message.
 
   boolean, result = postform(url, data, ...)
      Retrieves a URL using HTTP POST, returning the contents as a string.
      See getstring for return values.
 
Additionally, it can be customized by setting these values:
   useragent
      (string) Overrides the default "User-Agent" header value.
   keepalive
      (boolean) If 'true', each request will attempt to keep the connection
      open for later requests to the same host.
]]
 
--------------------------------------------------------------------------------
 
do
if not pge.http then pge.http = {} end
local _M = pge.http
 
local BLKSIZE = 4096
 
local DEFAULT = {
   useragent = 'Mozilla/4.0 (PSP (PlayStation Portable); 2.00)',
   keepalive = false,
}
 
local SETTING = setmetatable({}, { __index = DEFAULT })
 
--------------------------------------------------------------------------------
 
function _M.urlencode(s)
   return s:gsub('[^%w._-]', function(t) return ('%%%02X'):format(t:byte()) end)
end
function _M.urldecode(s)
   return s:gsub('%%(%x%x)', function(t) return string.char(tonumber(t,16)) end)
end
 
--------------------------------------------------------------------------------
 
-- List of common service ports. This library only supports HTTP, but
-- the parseurl function might be useful elsewhere.
local service_ports = {
   http = 80,
   https = 443,
   ftp = 21,
   pop3 = 110,
   smtp = 25,
   imap = 143,
}
function _M.parseurl(url)
   local scheme, host, port, path =
      url:match('^(%a[%w.+-]*)://([^/:])(:[^/]*)(.*)$')
 
   if port then
      port = port:sub(2)
   else
      scheme, host, path = url:match('^(%a[%w.+-]*)://([^/]+)(.*)$')
   end
 
   if scheme then
      scheme = scheme:lower()
 
      port = tonumber(port) or service_ports[scheme] or 80
 
      --print(scheme,host,port,path)
 
      return scheme, host, port, path
   end
end
 
--------------------------------------------------------------------------------
 
-- A simple connection manager to help implement keep-alive.
 
local conns = {}
local connMRU = {}
local MAXCONNS = 8
 
-- Find a socket in the MRU list.
local function sock_find(sck)
   for i, v in ipairs(connMRU) do
      if v == sck then return i end
   end
end
 
-- Close a given socket.
local function sock_close(sck)
   if type(sck) == 'number' then
      sck = connMRU[sck]
   end
 
   local id = conns[sck]
   if id then
      table.remove(connMRU, sock_find(sck))
 
      print(('closing connection to %s'):format(id))
 
      conns[sck] = nil
      conns[id ] = nil
      sck:close()
   end
end
 
-- Get a socket connection to the given ip and port.
local function sock_connect(ip, port)
   if ip and port then
      local sck, id
 
      id = ('%s:%d'):format(ip, port)
 
      if SETTING.keepalive and conns[id] then
         -- Reuse an open connection.
 
         --print(('reusing connection to %s'):format(id))
 
         sck = conns[id]
         table.remove(connMRU, sock_find(sck))
      else
         -- Open a new connection.
 
         --print(('opening connection to %s'):format(id))
 
         sck = pge.net.socket.create()
 
         if sck and sck:connect(ip, port) then
            if #connMRU > MAXCONNS then
               -- close the LRU open socket
               sock_close(1)
            end
            conns[sck] = id
            conns[id] = sck
         end
 
         --print('connected.')
      end
 
      if sck then
         connMRU[#connMRU+1] = sck
         return sck
      --else
      --   error(('error connecting to %s'):format(id))
      end
   end
end
 
--------------------------------------------------------------------------------
 
-- Address resolution cache.
local resolve = setmetatable({}, {
   __index = function(t, k)
      if k:match('^%d+[.]%d+[.]%d+[.]%d+$') then
         return k
      else
         k = tostring(k):lower()
 
         --print(('resolving "%s"'):format(k))
 
         local r = pge.net.resolve(k)
 
         if r then
            t[k] = r
            return t[k]
         --else
         --   error('hostname not found')
         end
      end
   end,
   })
 
--------------------------------------------------------------------------------
 
-- Sends a request to the given URL, opening a new connection if necessary.
 
local function sendReq(verb, url, headers, content)
   if not pge.net.isconnected() then return end
 
   --print(('retrieving "%s"'):format(url))
 
   local scheme, host, port, path = _M.parseurl(url)
 
   -- can only handle HTTP requests
   if scheme ~= 'http' then
      --print(('invalid scheme "%s"'):format(scheme))
      return
   end
 
   if host then
      if #path == 0 then path = '/' end
 
      --print('connecting to: '..host)
 
      local sck, msg = sock_connect(resolve[host], port)
 
      if not sck then return nil end
 
      --print('connected, requesting '..path)
 
      sck:send(('%s %s HTTP/1.1\r\n'):format(verb, path:gsub(' ', '%%20')))
 
      local hdrs = {}
      for k, v in pairs(headers or {}) do
         hdrs[tostring(k):lower()] = v
      end
 
      --print('sending headers')
 
      hdrs['host'] = host
 
      if SETTING.keepalive then
         hdrs['connection'] = 'Keep-Alive'
      end
 
      if content then
         content = tostring(content)
         hdrs['content-length'] = #content
      else
         hdrs['content-length'] = 0
      end
 
      if not hdrs['user-agent'] then
         hdrs['user-agent'] = SETTING.useragent
      end
 
      for k, v in pairs(hdrs) do
         sck:send(('%s: %s\r\n'):format(tostring(k), tostring(v)))
      end
 
      sck:send('\r\n')
 
      if content then
         --print('sending content')
         sck:send(content)
      end
 
      return sck
   end
end
 
--------------------------------------------------------------------------------
 
-- Read an HTTP response from a socket, using the given handler to write the
-- data returned (content only, no headers).
local function readRsp(sck, handler, chunk)
   if not sck then
      return false, 999, 'invalid socket handle'
   end

   local rsp = sck:receive(BLKSIZE)
   --if not rsp then return false, 999, 'error reading socket' end
   local _, eoh = rsp:find('\r\n\r\n')
 
   while pge.net.isconnected() and t and not eoh do
      local t = sck:receive(BLKSIZE)
      --if not t then return false, 999, 'error reading socket' end
      if not t or #t == 0 then break end
      rsp = rsp .. t
      _, eoh = rsp:find('\r\n\r\n')
   end
 
   local stat = rsp:find('\r\n')
   local ver, code, msg
 
   if stat then
      ver, code, msg = rsp:sub(1, stat - 1):match('^(%S+) (%d+) (.*)')
      code = tonumber(code)
   else
      return false, 999, 'missing HTTP status-line'
   end
 
   if not eoh then
      return false, 999, 'missing end-of-headers?'
   end
 
   local headers = {}
   for name, value in rsp:sub(stat + 2, eoh - 2):gmatch('([%w-]+): *(.-)\r\n') do
      headers[name:lower()] = value
   end

   if chunk then
   	  bsize = headers['content-length'] * (chunk/100)
	  camount = 0
   end
 
   if code < 400 then
      if handler:open() then
 
         local t = rsp:sub(eoh + 1)
 
         --if not t then return false, 999, 'error reading socket' end
         while pge.net.isconnected() and t and #t > 0 do
            --print(('read %d bytes'):format(#t))
			if not chunk then 
				download_callback(t,headers['content-length'])
				handler:write(t)
            	t = sck:receive(BLKSIZE)
			else
				handler:write(t)
            	t = sck:receive(BLKSIZE)
				camount = camount + #t
				if(camount > bsize) then
					t = nil
					chunk = nil
					handler:close()
					return 0
				end
			end
            --if not t then return false, 999, 'error reading socket' end
         end
 
         handler:close()
      else
         return false, 999, 'error opening handler'
      end
   end
 
   if (headers['connection'] == 'close') or not SETTING.keepalive then
      sock_close(sck)
   end
 
   return code < 400, code, msg
end
 
--------------------------------------------------------------------------------
 
-- Basic data handlers for readRsp:
--    file_handler   - writes data to a file
--    string_handler - returns data as a string
 
-- Later versions might include a way to add custom handlers.
 
local file_handler = {
   __init = function(t, filename)
      t.filename = filename
   end,
 
   open = function(t, start)
      if not t.fh then
         --print(('opening "%s"'):format(t.filename))
         t.fh = pge.file.open(t.filename,
            PGE_FILE_WRONLY + PGE_FILE_CREATE)
         if not t.fh then
            print('error opening file!')
         end
      end
 
      if t.fh then
         if start then
            t.fh:seek(start, PGE_FILE_SET)
         end
         return true
      end
   end,
 
   getsize = function(t)
      if pge.file.exists(t.filename) and t:open() then
         local l = t.fh:size() - 1024
         if l > 0 then return l end
      end
      return 0
   end,
 
   close = function(t)
      if t.fh then
         print(('closing "%s"'):format(t.filename))
         t.fh:close()
         t.fh = nil
      end
   end,
 
   write = function(t, data)
      if t.fh then 
	     print(('writing %d bytes'):format(#data))
         t.fh:write(data)
         io.write(data)
      end
   end,
}
local string_handler = {
   open = function(t)
      t.data = {}
      return true
   end,
   getsize = function(t)
      return 0
   end,
   close = function(t)
      t.string = table.concat(t.data)
      t.data = nil
   end,
   write = function(t, data)
      t.data[#t.data+1] = data
   end,
}
local function createHandler(h, ...)
   local o = setmetatable({}, { __index = h, __metatable = h })
   if o.__init then o:__init(...) end
   return o
end
 
--------------------------------------------------------------------------------
 
function _M.getstring(url)
   local h = createHandler(string_handler)
   local ok, code, msg = readRsp(sendReq('GET', url), h)
 
   if ok then
      return ok, h.string
   else
      return ok, msg
   end
end
 
function _M.getfile(url, file, chunk)
   local h = createHandler(file_handler, file)
 
   local ok, code, msg = readRsp(sendReq('GET', url), h, chunk)
 
   return ok, msg
end
 
function _M.postform(url, data)
   local h = createHandler(string_handler)
   local ok, code, msg = readRsp(sendReq('POST', url, {}, data), h)
 
   if ok then
      return ok, h.string
   else
      return ok, msg
   end
end
 
-- Needs a better name.  Probably not as useful as 'getstring' anyway.
function _M.postfile(url, file, data)
   local h = createHandler(file_handler, file)
   local sck = sendReq('POST', url, {}, data)
 
   return readRsp(sck, h)
end
 
setmetatable(_M, {
   __index = SETTING,
   __newindex = function(t, k, v)
      SETTING[k] = v
   end})
 
end
