--Global Variables
main_text_input = nil
search_button = nil
rtAPI="http://api.rottentomatoes.com/api/public/v1.0/movies.json"
apiKey="8r7bpraeww74usffcwfhhqd5"
url="http://search.azlyrics.com/search.php?q="
resList=nil
response=nil
dlg=nil
fnameSupports="YIFY"
resultPage=1 -- to fetch first page
searchClicked=true
totalRes=0
--Core program

function descriptor()
	return {
				title = "RottenTomatoes Rating";
				version = "1.0";
				author = "Manoj K";
				--url = 'http://ale5000.altervista.org/vlc/extensions/subtitles-mod.lua';
--[[				description = "<center><b>Subtitles</b></center>"
						   .. "Get the subtitles of movies from the internet, currently only from OpenSubtitles.org<br /><br />"
						   .. "<img src='http://static.opensubtitles.org/favicon.ico' /> Subtitles service allowed by <a href='http://www.opensubtitles.org/'>www.OpenSubtitles.org</a><br />"
						   .. "<br /><b>(Based on the script made by Jean-Philippe André)</b>";
				shortdesc = "Get the subtitles of movies from the internet, currently only from OpenSubtitles.org";
]]				capabilities = { "menu"; "input-listener"--[[; "meta-listener"]] }

			}
end

function activate()
	vlc.msg.dbg("activate function is called...")
	vlc.msg.dbg("trigger_menu will be called with input 1")
	trigger_menu(1)
	return true
end

function trigger_menu(id)
	if id == 1 then
		new_dialog("Lyrics Finder")
		return show_dialog_download()
	end

	vlc.msg.err("[Subtitles] Invalid menu id: "..id)
	return false
end

function new_dialog(title)
	dlg = vlc.dialog(title)
end

function show_dialog_download()

	dlg:add_label("<right><b>Enter Track Title: </b></right>", 1, 3, 1, 1)
	main_text_input = dlg:add_text_input("", 2, 3, 1, 1)
	search_button = dlg:add_button("Fetch Lyrics", click_search, 3, 3, 1, 1)
	--backButton = dlg:add_button("Previous Result Set", backPage, 1, 4, 1, 1)
	--nextButton = dlg:add_button("Fetch Next Result Set", nextPage, 2, 4, 1, 1)
	currPage=dlg:add_label('<p style="color:green">Not searched yet!!</p></b>',3,4,1,1)
	--dlg:add_label('<right><b>File Name Convention Supported: <p style="color:green">'..fnameSupports..'</p></b></right>',1,5)
	update_title()

	dlg:update()
	return true
end

function update_title()

	local item = vlc.input.item()
	if item == nil then return false end
	
	local title = item:name()	-- It return the internal title or the filename if the first is missing
	if title ~= nil then
		title = string.gsub(title, "(.*)%.%w+$", "%1")	-- Removes file extension
		title = string.gsub(title,'%.'," ")
		title = string.gsub(title,'BluRay x264 YIFY',"")
		title = string.gsub(title,'720p',"")
		title = string.gsub(title,'1080p',"")
		title = string.gsub(title,'20%d%d',"")-- %d{2} this is not supported in lua so 2 times %d%d to make it work in same way
		title = string.gsub(title,'19%d%d',"")
		title = string.gsub(title,'%s*$',"")
		if title ~= "" then
			main_text_input:set_text(title)
			dlg:update()
			return true
		end
	end

	return false
end

function click_search()
	if searchClicked == true then
	resultPage=1
	totalRes=0
	end
	searchClicked=true
	if resList == nil then showResList() end
	if resList ~= nil then resList:clear() end
	dlg:update()
	local search_term = main_text_input:get_text()
	if(search_term == "") then
		resList:add_value("Can't keep empty search string...", 1)
		dlg:update()
		return false
	end

	local old_button_name = search_button:get_text()
	search_button:set_text("Fetch Lyrics")

	--search_term = string.gsub(search_term, "%%", "%%37")
	search_term = string.gsub(search_term, " ", "+")
	
--To control result sets/pages
	local finalURL = url..search_term

	-- resList:add_value("Searching for track: "..main_text_input:get_text(), 1)
	currPage:set_text('<p style="color:blue">'.."Searching for track: "..main_text_input:get_text()..'</p></b>')
	
	local stream = vlc.stream(finalURL)
	
	if stream == nil then
		vlc.msg.err("site isn't reachable")
		search_button:set_text(old_button_name)
		resList:add_value("site isn't reachable", 1)
		currPage:set_text('<p style="color:red">'.."Not connected to the Internet!!!"..'</p></b>')
		dlg:update()
		return false
	end


	local buffer = "blah"
	local resJSON = ""
	while(buffer ~= nil and buffer ~= "") do
		buffer = stream:read(3316)
		if(buffer) then
			resJSON = resJSON .. buffer
		end
	end
	
	local temp1 = resJSON.match(resJSON, '1. <a href=.->')
	temp1 = string.sub(temp1, 13)
	local length1 = temp1:len()
	local lastb2 = length1 - 2
	temp1 = string.sub(temp1, 0, lastb2) 
	--temp1 = temp1.match(temp1, '<a href=.*')
	resJSON = ""

	local newurl = temp1

	local newstream = vlc.stream(newurl)

	local buffer1 = "blah"
	local resJSON1 = ""
	while(buffer1 ~= nil and buffer1 ~= "") do
		buffer1 = newstream:read(3316)
		if(buffer1) then
			resJSON1 = resJSON1 .. buffer1
		end
	end

	local temp2 = resJSON1.match(resJSON1, 'start of lyrics.-end of lyrics')
	temp2 = string.sub(temp2, 21)
	local length2 = temp2:len()
	local lastb20 = length2 - 20
	temp2 = string.sub(temp2, 0, lastb20) 
	resList:clear()

	temp2 = string.gsub(temp2,'<.->',"")

	temp2 = string.gsub(temp2, "^%s*(.*)+%s$", "%1")
	-- temp2 = string.gsub(temp2,'>',"")
	-- temp2 = string.gsub(temp2,'',"")


	currPage:set_text('<p style="color:green">'.."Lyrics Fetched from: "..newurl..'</p></b>')
	temp2 = "Track title: "..main_text_input:get_text().."\n"..temp2
	resList:add_value("\n"..temp2, 1)

	if resJSON == "" then
		search_button:set_text(old_button_name)
		-- resList:add_value("No response! Please refine search query.", 1)
		dlg:update()
		return false 
	end
	resJSON = ""
currPage:set_text('<p style="color:blue">'..resultPage..'</p></b>')

--total results
	matchTotal=string.format("%s",string.match(resJSON, '{"total":[%d]+'))
	mod1MatchTotal=string.format("%s",string.gsub(matchTotal,'^{"total":',""))
	totalRes = tonumber(mod1MatchTotal)

-- to set : what page result set is this !!
--this will show rating and all info on screen...
--	parseNDisplay() --didn't work so discarded'
----------------	
	--Title Name mandatory info-- so if it fails to parse name then it won't show whole result set.
----------------
-- if not string.match(resJSON, '"title":"[^"]+",') then
-- 	currPage:set_text('<p style="color:red">Debug you!!</p></b>')
-- 	resList:add_value('Warning: Failed to fetch name of Movie. Action: modify Regex pattern.', 1)
-- 	resList:add_value('URL to debug:     '..finalURL, 2)
-- 	search_button:set_text("Search")
-- 	dlg:update()
-- 	return false
-- end

-- if string.match(resJSON, '"title":"[^"]+",') then
-- 	matchTitle=string.format("%s",string.match(resJSON, '"title":"[^"]+",'))
-- 	--resList:add_value(matchTitle, 1)
-- 	mod1MatchTitle=string.format("%s",string.gsub(matchTitle,'"title":"',""))
-- 	--resList:add_value(mod1MatchTitle, 2)
-- 	title=string.format("%s",string.gsub(mod1MatchTitle,'",',""))
-- 	resList:add_value('Movie Title: '..title, 1)
-- end
-- ----------------	
-- 	--YEAR
-- ----------------	
-- if string.match(resJSON, '"year":[%d]+,') then
-- 	matchYear=string.format("%s",string.match(resJSON, '"year":[%d]+,'))
-- 	mod1MatchYear=string.format("%s",string.gsub(matchYear,'"year":',""))
-- 	year=string.format("%s",string.gsub(mod1MatchYear,',',""))
-- 	resList:add_value('Release Year: '..year, 2)
-- end
-- ----------------	
-- 	--Movie Duration
-- ----------------	
-- if string.match(resJSON, '"runtime":[%d]+,') then
-- 	matchRunTime=string.format("%s",string.match(resJSON, '"runtime":[%d]+,'))
-- 	mod1MatchRunTime=string.format("%s",string.gsub(matchRunTime,'"runtime":',""))
-- 	runTime=string.format("%s",string.gsub(mod1MatchRunTime,',',""))
-- 	resList:add_value('Run Time: '..runTime.." min", 3)
-- end
-- ----------------	
-- 	--Critics Score
-- ----------------
-- if string.match(resJSON, '"critics_score":[%d]+,') then	
-- 	matchCScore=string.format("%s",string.match(resJSON, '"critics_score":[%d]+,'))
-- 	mod1MatchCScore=string.format("%s",string.gsub(matchCScore,'"critics_score":',""))
-- 	CScore=string.format("%s",string.gsub(mod1MatchCScore,',',""))
-- 	resList:add_value('Critics Rotten Tomatoes: '..CScore.."%", 4)	
-- end
-- ----------------	
-- 	--Public Score
-- ----------------	
-- if string.match(resJSON, '"audience_score":[%d]+') then
-- 	matchPScore=string.format("%s",string.match(resJSON, '"audience_score":[%d]+'))
-- 	PScore=string.format("%s",string.gsub(matchPScore,'"audience_score":',""))
-- 	resList:add_value('Audience Rotten Tomatoes: '..PScore.."%", 5)	
-- end

-- --------------------------------	
-- 	search_button:set_text("Search")
-- 	dlg:update()

	return true
	
end

--reduce resultPage by 1to see previous page
function backPage()
	if resList == nil then showResList() end
		if resList ~= nil then resList:clear() end
	local search_term = main_text_input:get_text()
	if(search_term == "") then
		currPage:set_text('<p style="color:red">Stop!!</p></b>')
		resList:add_value("Can't keep empty search string... either play a media or manually type name of movie", 1)
		dlg:update()
		return false
	end
	
	if resultPage >=2 then 
		resultPage=resultPage-1
	else
		currPage:set_text('<p style="color:red">Stop!!</p></b>')
		resList:add_value("No more result could be fetched in backward direction. Press 'Next' button or change 'Movie Title'", 1)
		dlg:update()
		return false
	end
	
	searchClicked=false
	click_search()
	return true
end

--increase resultPage by 1, to see next page
function nextPage()
	if resList == nil then showResList() end
	if resList ~= nil then resList:clear() end	
	local search_term = main_text_input:get_text()
	if(search_term == "") then
		currPage:set_text('<p style="color:red">Stop!!</p></b>')
		resList:add_value("Can't keep empty search string... either play a media or manually type name of movie", 1)
		dlg:update()
		return false
	end
	if totalRes ~= 0 then
		if resultPage==totalRes then 
			currPage:set_text('<p style="color:red">Stop!!</p></b>')
			resList:add_value("All Results are fetched. Press 'Back' button or change 'Movie Title'", 1)
			dlg:update()
			return false		
		end
	end
	if resultPage <=24 then 
		resultPage=resultPage+1
	else
		currPage:set_text('<p style="color:red">Stop!!</p></b>')
		resList:add_value("No more result could be fetched. Press 'Back' button or change 'Movie Title'", 1)
		dlg:update()
		return false
	end
	searchClicked=false
	click_search()
	return true
end

function showResList()
	resList = dlg:add_list(1, 6, 3, 1)
	return true
end


--- Not using this function
function parseNDisplay()
--str1=resJSON.match('"title":"[%w%s]+",')
str1=string.match(resJSON, 'title')
	resList:add_value(string.format("%s",string.match(resJSON, 'title')), 1)
	search_button:set_text("Search")
	dlg:update()
	return true
	--[[
	str2=string.gsub(str1,'"title":"',"")
	resList:add_value(str2,2)
	dlg:update()
	str3=string.gsub(str2,'",',"")
	resList:add_value(str3,3)
	dlg:update()
	resList:add_value("Movie Name: "..string.gsub(string.gsub(resJSON:match('"title":"[a-zA-Z%d%w]+",'),'"title":"',""),'",',""), 4)
	
	search_button:set_text("Search")
	dlg:update()
	return true]]
end
