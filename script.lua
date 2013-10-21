-- TODO
-- Idiomas.

require('libf')

--[[

Global variables

--]]

APP_VERSION = "2.0.1"
BASE_MUSIC_DIR = 'ms0:/MUSIC/'
COMMON_DIR = 'common/'
LOGO = pge.texture.load(COMMON_DIR..'logo.png')
if not LOGO then
	error('Error cargando el logo')
end
local configfile = load_conf_file(COMMON_DIR..'config.dat')
local config = parse_file(configfile)
local langs = load_languages('langs/')
LANG = change_language(langs, config.LANG) --global
local skins = load_skins('skins/')
local currentSkin = skins[config.CURRSKIN]
local index = 1
local menuPrincipal = {LANG.MENU1,LANG.MENU2,LANG.MENU3,LANG.MENU4,LANG.MENU5,LANG.MENU6}
--[[

Functions

--]]

function draw_bg(title, small)
	if(title==nil) then
		title = ""
	end
	if (backImage) then
		backImage:activate()
		backImage:draweasy(0, 0)
	elseif (currentSkin.gradientBg) then
		pge.gfx.drawrectgrad(0, 0, 480, 272, color1, color1, color2, color2)
	elseif (currentSkin.bgColor) then
		pge.gfx.drawrect(0, 0, 480, 272, bgColor)
	end

	-- logo:activate()
	
	-- logo:draweasy(0, 0)
	pge.gfx.drawline(0, 255, 480, 255, color3)
	if(not small) then
		LOGO:activate()
		LOGO:draweasy(300, 10)
	end
	big:activate()
	big:print(15,15, fontColor, title)

end

function draw_footer(lftext, rftext)
	if lftext == nil then lftext = "" end
	if rftext == nil then rftext = "" end
	small:activate()
	small:print(200, 260, fontColor,  "Goear PSP "..APP_VERSION)
	small:print(375, 260, fontColor, rftext)
	small:print(15, 260, fontColor, lftext)
end

function draw_menu(menu_text, index)
	pge.gfx.startdrawing()
	pge.gfx.clearscreen()

	draw_bg()
	draw_footer(nil, LANG.MSC4.." : Select")
	big:activate()
	
	for i=1, #menu_text do
		if(index==i) then
			big:print(25, 40 + i*25, fontOverColor, menu_text[i])
		else
			big:print(25, 40 + i*25, fontColor, menu_text[i])
		end 
	end
	pge.gfx.enddrawing()
	pge.gfx.swapbuffers()
end

function main()
	
	function write_results(texto, indice, pagina, lstatus, rstatus)
		local pg = ""
		if texto==nil then
			pg = ""
		else
			pg = LANG.MSC1.." "..pagina 
		end
		if lstatus == nil then lstatus = "" end
		if rstatus == nil then rstatus = "" end
		
		pge.gfx.startdrawing()
	
		pge.gfx.clearscreen()
		-- Activate the font
		draw_bg(pg)
		draw_footer(lstatus, rstatus)

		-- Print some text
		medium:activate()
		if texto~=nil then
			for i=1, #texto do
				if(indice==i) then
					medium:print(25, 80 + i*15, fontOverColor, texto[i][1])
				else
					medium:print(25, 80 + i*15, fontColor, texto[i][1])
				end 
			end
		end
		pge.gfx.enddrawing()
		pge.gfx.swapbuffers()
	end
	
	local index = nil
	local list = nil
	local searchtext = ""
	local currpage = 0
	local queuelist = {}
	pge.mp3.stop()
	while pge.running() do
		if pge.net.isconnected()==false then
			msg_dialog(LANG.MSG1)
			break
		end
		pge.controls.update()
		write_results(list, index, currpage)
		if pge.controls.pressed(PGE_CTRL_CIRCLE) then
			searchtext = input_dialog(LANG.MSG2)
			list = search(searchtext, currpage)
			if(list[0]==-1) then
				msg_dialog(LANG.MSG3)
				currpage = 0
				index = nil
				list = nil
				write_results()
			else
				if(searchtext~="") then
					index = 1
					currpage = 0
				else
					msg_dialog(LANG.MSG4)
					list = nil
					index = nil
				end
			end
		end
		
		if pge.controls.pressed(PGE_CTRL_UP) then
			if (index and index > 1) then
				index = index - 1
				write_results(list, index, currpage)
			end
		end

		if pge.controls.pressed(PGE_CTRL_DOWN) then
			if (index and list and index < #list) then
				index = index + 1
				write_results(list, index, currpage)
			end
		end
		
		if pge.controls.pressed(PGE_CTRL_LTRIGGER) then
			if (list and currpage > 0) then
				currpage = currpage - 1
				list = search(searchtext, currpage)
				if(list[0]==-1) then
					msg_dialog(LANG.MSG3)
					currpage = 0
					list = nil
					index = nil
					write_results()
				else
					index = 1
					write_results(list, index, currpage)
				end
			end
		end
		
		if pge.controls.pressed(PGE_CTRL_RTRIGGER) then
			if (list) then
				currpage = currpage + 1
				list = search(searchtext, currpage)
				if(list[0]==-1) then
					msg_dialog(LANG.MSG5)
					currpage = currpage - 1
					list = search(searchtext, currpage)
					index = 1
					write_results(list, index, currpage)
				else
					index = 1
					write_results(list, index, currpage)
				end
			end
		end
		
		if pge.controls.released(PGE_CTRL_SELECT) then
			if(#queuelist > 0) then
				show_queuelist(list, index, currpage, queuelist)
			end
		end
		
		if pge.controls.pressed(PGE_CTRL_TRIANGLE) then
			if(list) then
				qres = addQueue(list[index][1], list[index][2], queuelist)
				if qres==0 then
					msg_dialog(LANG.MSG6)
					write_results(list, index, currpage)	
				elseif qres==-1 then
					msg_dialog(LANG.MSG7)
				end
			end
		end
		
		if pge.controls.pressed(PGE_CTRL_SQUARE) then
			pge.mp3.stop()
			if(list) then
				if(#queuelist>0) then
					if( msg_dialog(LANG.MSG8A.." "..#queuelist.." "..LANG.MSG8B.."\n"..LANG.MSG8C, 1) == 0 ) then
						download_list(queuelist)
						queuelist = {}
						msg_dialog(LANG.MSG9)
					end
				else
					currsong = 1
					totalsong = 1
					download_song(list[index][2], true)
					msg_dialog(LANG.MSG9)
				end
				write_results(list, index, currpage) 
			end
		end
		
		if pge.controls.pressed(PGE_CTRL_CROSS) then
			if(list) then
				collectgarbage("collect")
				write_results(list, index, currpage, nil, LANG.MSC2)
				preview_mp3(list[index][2], nil, 10)
			end
		end
		
		if pge.controls.pressed(PGE_CTRL_START) then
			break
		end
		
		
	end
	
end

function options()
	function transformvalue(value)
		if(value=='1') then
			return LANG.YES
		elseif value=='0' then
			return LANG.NO
		end
	end
	
	function switchvalue(value)
		if(value=='1') then
			return '0'
		elseif value=='0' then
			return '1'
		end
	end
	
	function get_lang_names(langs)
		local t = {}
		for i = 1, #langs do
			table.insert(t, langs[i].NAME)
		end
		return t
	end
	
	function update_lang()
		opc = {
				{LANG.OPC1,"< "..LANG.NAME..">"}, 
				{LANG.OPC2, "< "..currentSkin.Name.." >"},
				{LANG.OPC3, "< "..transformvalue(config.CPMSG).." >"},
				{LANG.OPC4, "< "..transformvalue(config.NVRSN).." >"},
				{LANG.OPC5, LANG.OPC6},
				}
		
		menuPrincipal = {LANG.MENU1,LANG.MENU2,LANG.MENU3,LANG.MENU4,LANG.MENU5,LANG.MENU6}
				
	end
	
	local opc = {
				{LANG.OPC1,"< "..LANG.NAME..">"}, 
				{LANG.OPC2, "< "..currentSkin.Name.." >"},
				{LANG.OPC3, "< "..transformvalue(config.CPMSG).." >"},
				{LANG.OPC4, "< "..transformvalue(config.NVRSN).." >"},
				{LANG.OPC5, LANG.OPC6},
				}
	local index = 1
	local skinlist = {}
	local skinindex = nil
	local count = 1
	local langindex = 1
	local configlist = {}
	local langlist = {}
	
	for i,j in pairs(skins) do
		table.insert(skinlist, count, i)
		if(currentSkin==j) then
			skinindex = count
		end
		count = count + 1
	end
	langlist = get_lang_names(langs)
	for i = 1, #langlist do
		if langlist[i]==LANG.NAME then
			langindex = i
			break
		end
	end	
	while pge.running() do
		pge.controls.update()
		pge.gfx.startdrawing()
		pge.gfx.clearscreen()
		draw_bg(LANG.MSC3)
		draw_footer()
		small:activate()
		for i = 1, #opc do
			if(index==i) then
				small:print(15,100+(15*i), fontOverColor, opc[i][1])
				small:print(250,100+(15*i), fontOverColor, opc[i][2])
			else
				small:print(15,100+(15*i), fontColor, opc[i][1])
				small:print(250,100+(15*i), fontColor, opc[i][2])
			end
		end
		small:print(15,75, fontColor, LANG.SKNAU)
		small:print(250,75, fontColor, currentSkin.Author)
		small:print(15,90, fontColor, LANG.LNGAU)
		small:print(250,90, fontColor, LANG.AUTHOR)
		if pge.controls.pressed(PGE_CTRL_UP) then
			if (index > 1) then
				index = index - 1
			end
		end

		if pge.controls.pressed(PGE_CTRL_DOWN) then
			if (index < #opc) then
				index = index + 1
			end
		end
		
		if pge.controls.pressed(PGE_CTRL_CROSS) then
			 if(index==5) then
			 	table.insert(configlist, "//This file was auto generated, do not edit manually")
			 	table.insert(configlist, "[Config]")
				table.insert(configlist, "_CPMSG="..config.CPMSG.."*")
				table.insert(configlist, "_NVRSN="..config.NVRSN.."*")
				table.insert(configlist, "_CURRSKIN="..currentSkin.Name.."*")
				table.insert(configlist, "_LANG="..LANG.NAME.."*")
				if(save_config_file(configlist)==false) then
					msg_dialog(LANG.MSG10)
				end
				configlist = {}
				configfile = load_conf_file(COMMON_DIR..'config.dat')
				config = parse_file(configfile)
			 	break
			 end
		end
		
		if pge.controls.pressed(PGE_CTRL_RIGHT) then
			collectgarbage("collect")
			if(index==1) then
				if(langindex<#langlist) then
					langindex = langindex + 1
					LANG = change_language(langs, langlist[langindex])
					opc[1][2] = "< "..LANG.NAME.." >"
					update_lang()
				end
			end
			
			if(index==2) then
				if(skinindex<#skinlist) then
					skinindex = skinindex + 1
					currentSkin = skins[skinlist[skinindex]]
					change_skin(currentSkin)
					opc[2][2] = "< "..currentSkin.Name.." >"
				end
			end
			if(index==3) then
				config.CPMSG = switchvalue(config.CPMSG)
				opc[3][2] = "< "..transformvalue(config.CPMSG).." >"				
			end
			if(index==4) then
				config.NVRSN = switchvalue(config.NVRSN)
				opc[4][2] = "< "..transformvalue(config.NVRSN).." >"				
			end
		end
		
		if pge.controls.pressed(PGE_CTRL_LEFT) then
			collectgarbage("collect")
			if(index==1) then
				if(langindex>1) then
					langindex = langindex - 1
					LANG = change_language(langs, langlist[langindex])
					opc[1][2] = "< "..LANG.NAME.." >"
					update_lang()
				end
			end
			if(index==2) then
				if(skinindex>1) then
					skinindex = skinindex - 1
					currentSkin = skins[skinlist[skinindex]]
					change_skin(currentSkin)
					opc[2][2] = "< "..currentSkin.Name.." >"
				end
			end
			if(index==3) then
				config.CPMSG = switchvalue(config.CPMSG)
				opc[3][2] = "< "..transformvalue(config.CPMSG).." >"				
			end
			if(index==4) then
				config.NVRSN = switchvalue(config.NVRSN)
				opc[4][2] = "< "..transformvalue(config.NVRSN).." >"				
			end
		end
		
		pge.gfx.enddrawing()
		pge.gfx.swapbuffers()
		
	end
end

function mp3player(dir)
-- Reset the current selection to the first entry
local currentselection = 1
-- The file offset
local fileoffset = 0

local squarebtn = pge.texture.load(COMMON_DIR.."square.png")
local crossbtn = pge.texture.load(COMMON_DIR.."cross.png")
local playerskin = pge.texture.load(COMMON_DIR.."player.png")
local playing = false
-- The limit of number of files to show on screen at once
local filelimit = 6
local artist = ""
local album = ""
local title = ""

-- Initially read the contents of the initial directory
local dircontents = readmp3dir(dir)

local vertices = {}
-- Loop with exit requested

while pge.running() do
	-- Update controls
	pge.controls.update()
	
	-- End drawing
	-- If UP pressed and the directory has contents, select the entry above
	if pge.controls.pressed(PGE_CTRL_UP) and dircontents then
		if currentselection > 1 then
			currentselection = currentselection - 1
			
			if currentselection > filelimit - 2 then
				fileoffset = fileoffset - 1
			end
		end
	end
	
	-- If DOWN pressed and the directory has contents, select the entry below
	if pge.controls.pressed(PGE_CTRL_DOWN) and dircontents then
		if currentselection < #dircontents then
			currentselection = currentselection + 1
			
			if currentselection >= filelimit then
				fileoffset = fileoffset + 1
			end
		end
	end
	
	-- If CROSS pressed, the directory has contents and the selected item is a directory, move into the directory selected
	if pge.controls.pressed(PGE_CTRL_CROSS) and dircontents then
		pge.mp3.stop()
		pge.mp3.play("ms0:/MUSIC/"..dircontents[currentselection].name)
		mp3info = pge.mp3.getinfo()
		playing = true
	end
	
	if pge.controls.pressed(PGE_CTRL_SQUARE) then
		pge.mp3.stop()
		playing = false
	end
	
	-- If START pressed, end
	if pge.controls.pressed(PGE_CTRL_START) then
		pge.mp3.stop()
		break
	end
	
	if pge.controls.pressed(PGE_CTRL_SELECT) then
		msg_dialog(LANG.BTNCR..": "..LANG.MSG11A.."\n"..LANG.BTNSQ..": "..LANG.MSG11B.."\nStart: "..LANG.MSG11C)
	end
	
	pge.gfx.startdrawing()
	pge.gfx.clearscreen()	
	draw_bg("", 0)
	draw_footer(nil, LANG.MSC4..": Select")
	playerskin:activate()
	playerskin:draweasy(0 , 0)
	LOGO:activate()
	LOGO:draw(300, 105, 100, 34)
	if(playing==true) then
		squarebtn:activate()
		squarebtn:draweasy(220,100)
	else
		crossbtn:activate()
		crossbtn:draweasy(220,100)
	end
	-- Start drawing
	-- Activate the font for drawing
	small:activate()
	small:printcenter(15, fontColor, " Goear PSP Player ")
	if(pge.mp3.isplaying()) then
		for ind = 1, 200 do
			audiodata = pge.mp3.getaudiodata(ind * 2)
			vertices[ind] = {pge.gfx.createcolor(68, 255, 255), 74 + ind, ((audiodata + 32767) * 0.001) + 27.5, 0}
		end
		if (mp3info) then
			artist = truncate_string(pge.mp3.artist(mp3info))
			album = truncate_string(pge.mp3.album(mp3info))
			title = truncate_string(pge.mp3.title(mp3info))
		else
			artist = ""
			title = ""
			album = ""
		end
		small:print(280, 40, fontColor, LANG.ARTIST..": "..artist)
		small:print(280, 60, fontColor, LANG.TITLE..": "..title)
		small:print(280, 80, fontColor, LANG.ALBUM..": "..album)
		pge.gfx.drawcustom(PGE_PRIM_LINE_STRIP, PGE_VERT_CV, vertices)
	end
	-- Print the directory contents
	if dircontents then
		for index, entry in ipairs(dircontents) do	
			if index > fileoffset and index < (filelimit + fileoffset) then
				if currentselection == index then
					small:print(80, ((index - fileoffset) * 15) + 145, fontOverColor, index..". "..entry.name)
				else
					small:print(80, ((index - fileoffset) * 15) + 145, fontColor, index..". "..entry.name)
				end
			end
		end
	end
	
	-- End drawing
	pge.gfx.enddrawing()
	
	-- Swap buffers
	pge.gfx.swapbuffers()
	
end
end


function show_queuelist(gbllist, gblindex, gblpage, queuelist)
	local indice = 1
	while pge.running() do
		pge.controls.update()
		pge.gfx.startdrawing()
		pge.gfx.clearscreen()
		draw_bg(LANG.MSC5)
		draw_footer()
		medium:activate()

		for i=1, #queuelist do
			if(indice==i) then
				medium:print(25, 80 + i*15, fontOverColor, queuelist[i][1])
			else
				medium:print(25, 80 + i*15, fontColor, queuelist[i][1])
			end 
		end
		
		if pge.controls.pressed(PGE_CTRL_START) then
			if(gbllist) then
				write_results(gbllist, gblindex, gblpage)
			else
				write_results()
			end
			break
		end
		
		if pge.controls.pressed(PGE_CTRL_UP) then
			if (indice > 1) then
				indice = indice - 1
			end
		end

		if pge.controls.pressed(PGE_CTRL_DOWN) then
			if (indice < #queuelist) then
				indice = indice + 1
			end
		end
		
		if pge.controls.pressed(PGE_CTRL_TRIANGLE) then
			if(#queuelist==1) then
				removeQueue(indice, queuelist)
				write_results(gbllist, gblindex, gblpage)
				break
			else
				removeQueue(indice, queuelist)
				indice = 1
			end
		end
		pge.gfx.enddrawing()
		pge.gfx.swapbuffers()
	end
end


function addQueue(songtitle, songid, queuelist, limit)
	if limit == nil then limit = 10 end
	if #queuelist<limit then
		local templist = {}
		table.insert(templist, songtitle)
		table.insert(templist, songid)
		table.insert(queuelist, templist)
		return 0
	else
		return -1
	end
end

function removeQueue(index, queuelist)
	table.remove(queuelist, index)
end


--[[

End Functions

--]]

splash_screen(COMMON_DIR..'splash.png')
net_dialog() --connect to internet
change_skin(currentSkin)

if(config.CPMSG=='1') then
	msg_dialog(LANG.CRMSG1.."\n\n"..LANG.CRMSG2.."\n\n"..LANG.CRMSG3)
end

if(pge.net.isconnected()==true and config.NVRSN=='1') then
	check_update("silencioso")
end

while pge.running() do
	pge.controls.update()
	draw_menu(menuPrincipal, index)
	if pge.controls.pressed(PGE_CTRL_UP) then
		if (index > 1) then
			index = index - 1
		end
	end	

	if pge.controls.pressed(PGE_CTRL_DOWN) then
		if (index < #menuPrincipal) then
			index = index + 1
		end
	end
	
	if pge.controls.pressed(PGE_CTRL_SELECT) then
		msg_dialog("["..LANG.HLP1A.." - "..LANG.HLP1B.."]\n\n"..LANG.BTNCR.." : "..LANG.HLP1C.."\n"..LANG.BTNCI.." : "..LANG.HLP1D.."\n"..LANG.BTNTR.." : "..LANG.HLP1E.."\n"..LANG.BTNSQ.." : "..LANG.HLP1F.."\nL : "..LANG.HLP1G.."\nR : "..LANG.HLP1H.."\nSelect : "..LANG.HLP1I.."\nStart : "..LANG.OPC5)
	end
	
	if pge.controls.pressed(PGE_CTRL_CROSS) then
		if(index==1) then
			main()
		end
		if(index==2) then
			mp3player(BASE_MUSIC_DIR)
		end
		if(index==3) then
			options()
		end
		if(index==4) then
			check_update()
		end
		if(index==5) then
			msg_dialog("Goear PSP "..APP_VERSION.."\n"..LANG.HLP2A.." clizana, "..LANG.HLP2B.." \nhttp://dev.cristianlizana.com\n")
		end
		if (index==6) then
			pge.exit()
		end
	end
end
