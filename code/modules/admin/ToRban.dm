//By Carnwennan
//fetches an external list and processes it into a list of ip addresses.
//It then stores the processed list into a savefile for later use
#define TORFILE "data/ToR_ban.bdb"
#define TOR_UPDATE_INTERVAL 216000	//~6 hours

/proc/ToRban_isbanned(var/ip_address)
	var/savefile/F = new(TORFILE)
	if(F)
		if( ip_address in F.dir )
			return 1
	return 0

/proc/ToRban_autoupdate()
	var/savefile/F = new(TORFILE)
	if(F)
		var/last_update
		F["last_update"] >> last_update
		if((last_update + TOR_UPDATE_INTERVAL) < world.realtime)	//we haven't updated for a while
			ToRban_update()
	return

/proc/ToRban_update()
	spawn(0)
		log_misc("Downloading updated ToR data...")
		var/http[] = world.Export("https://check.torproject.org/exit-addresses")

		var/list/rawlist = file2list(http["CONTENT"])
		if(rawlist.len)
			fdel(TORFILE)
			var/savefile/F = new(TORFILE)
			for( var/line in rawlist )
				if(!line)	continue
				if( copytext_char(line,1,12) == "ExitAddress" )
					var/cleaned = copytext_char(line,13,length(line)-19)
					if(!cleaned)	continue
					F[cleaned] << 1
			F["last_update"] << world.realtime
			log_misc("ToR data updated!")
			if(usr)
				to_chat(usr, "<span class='filter_adminlog'>ToRban updated.</span>")
			return
		log_misc("ToR data update aborted: no data.")
		return

/client/proc/ToRban(task in list("update","toggle","show","remove","remove all","find"))
	set name = "ToRban"
	set category = "Server"
	if(!holder)	return
	switch(task)
		if("update")
			ToRban_update()
		if("toggle")
			if(config)
				if(config.ToRban)
					config.ToRban = 0
					message_admins(span_red("ToR banning disabled."))
				else
					config.ToRban = 1
					message_admins(span_green("ToR banning enabled."))
		if("show")
			var/savefile/F = new(TORFILE)
			var/dat
			if( length(F.dir) )
				for( var/i=1, i<=length(F.dir), i++ )
					dat += "<tr><td>#[i]</td><td> [F.dir[i]]</td></tr>"
				dat = "<table width='100%'>[dat]</table>"
			else
				dat = "No addresses in list."
			src << browse(dat,"window=ToRban_show")
		if("remove")
			var/savefile/F = new(TORFILE)
			var/choice = tgui_input_list(src,"Please select an IP address to remove from the ToR banlist:","Remove ToR ban", F.dir)
			if(choice)
				F.dir.Remove(choice)
				to_chat(src, "<span class='filter_adminlog'><b>Address removed</b></span>")
		if("remove all")
			to_chat(src, "<span class='filter_adminlog'><b>[TORFILE] was [fdel(TORFILE)?"":"not "]removed.</b></span>")
		if("find")
			var/input = tgui_input_text(src,"Please input an IP address to search for:","Find ToR ban",null)
			if(input)
				if(ToRban_isbanned(input))
					to_chat(src, "<span class='filter_adminlog'>[span_orange("<b>Address is a known ToR address</b>")]</span>")
				else
					to_chat(src, "<span class='filter_adminlog danger'>Address is not a known ToR address</span>")
	return

#undef TORFILE
#undef TOR_UPDATE_INTERVAL
