//This file was auto-corrected by findeclaration.exe on 25.5.2012 20:42:33


/* --- Traffic Control Scripting Language --- */
	// NanoTrasen TCS Language - Made by Doohl

/n_Interpreter/TCS_Interpreter
	var/datum/TCS_Compiler/Compiler

/n_Interpreter/TCS_Interpreter/HandleError(runtimeError/e)
	Compiler.Holder.add_entry(e.ToString(), "Execution Error")

/datum/TCS_Compiler
	var/n_Interpreter/TCS_Interpreter/interpreter
	var/obj/machinery/telecomms/server/Holder	// the server that is running the code
	var/ready = 1 // 1 if ready to run code

	/** Proc: Compile
	 * Compile a raw block of text into a program
	 * Returns: List of errors
	*/

/datum/TCS_Compiler/proc/Compile(code as message)
	var/n_scriptOptions/nS_Options/options = new()
	var/n_Scanner/nS_Scanner/scanner       = new(code, options)
	var/list/tokens                        = scanner.Scan()
	var/n_Parser/nS_Parser/parser          = new(tokens, options)
	var/node/BlockDefinition/GlobalBlock/program   	 = parser.Parse()

	var/list/returnerrors = list()

	returnerrors += scanner.errors
	returnerrors += parser.errors

	if(returnerrors.len)
		return returnerrors

	interpreter 		= new(program)
	interpreter.persist	= 1
	interpreter.Compiler= src

	return returnerrors

	/* -- Execute the compiled code -- */
/** Proc: Run
 * Executes the compiled code.
 * Arguments:
 *   var/datum/signal/signal - a telecomms signal
 * Returns: None
 */
/datum/TCS_Compiler/proc/Run(var/datum/signal/signal)

	if(!ready)
		return

	if(!interpreter)
		return

	interpreter.container = src

	interpreter.SetVar("PI"		, 	3.141592653)	// value of pi
	interpreter.SetVar("E" 		, 	2.718281828)	// value of e
	interpreter.SetVar("SQURT2" , 	1.414213562)	// value of the square root of 2
	interpreter.SetVar("FALSE"  , 	0)				// boolean shortcut to 0
	interpreter.SetVar("TRUE"	,	1)				// boolean shortcut to 1

	interpreter.SetVar("NORTH" 	, 	NORTH)			// NORTH (1)
	interpreter.SetVar("SOUTH" 	, 	SOUTH)			// SOUTH (2)
	interpreter.SetVar("EAST" 	, 	EAST)			// EAST  (4)
	interpreter.SetVar("WEST" 	, 	WEST)			// WEST  (8)

	// Channel macros
	interpreter.SetVar("$common",	PUB_FREQ)
	interpreter.SetVar("$science",	SCI_FREQ)
	interpreter.SetVar("$command",	COMM_FREQ)
	interpreter.SetVar("$medical",	MED_FREQ)
	interpreter.SetVar("$engineering",ENG_FREQ)
	interpreter.SetVar("$security",	SEC_FREQ)
	interpreter.SetVar("$supply",	SUP_FREQ)
	interpreter.SetVar("$explorer", EXP_FREQ)

	// Signal data

	interpreter.SetVar("$content", 	signal.data["message"])
	interpreter.SetVar("$freq"   , 	signal.frequency)
	interpreter.SetVar("$source" , 	signal.data["name"])
	interpreter.SetVar("$job"    , 	signal.data["job"])
	interpreter.SetVar("$sign"   ,	signal)
	interpreter.SetVar("$pass"	 ,  !(signal.data["reject"])) // if the signal isn't rejected, pass = 1; if the signal IS rejected, pass = 0

	// Set up the script procs

	/*
		-> Send another signal to a server
				@format: broadcast(content, frequency, source, job)

				@param content:		Message to broadcast
				@param frequency:	Frequency to broadcast to
				@param source:		The name of the source you wish to imitate. Must be stored in stored_names list.
				@param job:			The name of the job.
	*/
	interpreter.SetProc("broadcast", "tcombroadcast", signal, list("message", "freq", "source", "job"))

	/*
		-> Store a value permanently to the server machine (not the actual game hosting machine, the ingame machine)
				@format: mem(address, value)

				@param address:		The memory address (string index) to store a value to
				@param value:		The value to store to the memory address
	*/
	interpreter.SetProc("mem", "mem", signal, list("address", "value"))

	/*
		-> Delay code for a given amount of deciseconds
				@format: sleep(time)

				@param time: 		time to sleep in deciseconds (1/10th second)
	*/
	interpreter.SetProc("sleep", GLOBAL_PROC_REF(delay))

	/*
		-> Replaces a string with another string
				@format: replace(string, substring, replacestring)

				@param string: 			the string to search for substrings (best used with $content$ constant)
				@param substring: 		the substring to search for
				@param replacestring: 	the string to replace the substring with

	*/
	interpreter.SetProc("replace", GLOBAL_PROC_REF(string_replacetext))

	/*
		-> Locates an element/substring inside of a list or string
				@format: find(haystack, needle, start = 1, end = 0)

				@param haystack:	the container to search
				@param needle:		the element to search for
				@param start:		the position to start in
				@param end:			the position to end in

	*/
	interpreter.SetProc("find", GLOBAL_PROC_REF(smartfind))

	/*
		-> Finds the length of a string or list
				@format: length(container)

				@param container: the list or container to measure

	*/
	interpreter.SetProc("length", GLOBAL_PROC_REF(smartlength))

	/* -- Clone functions, carried from default BYOND procs --- */

	// vector namespace
	interpreter.SetProc("vector", GLOBAL_PROC_REF(n_list))
	interpreter.SetProc("at", GLOBAL_PROC_REF(n_listpos))
	interpreter.SetProc("copy", GLOBAL_PROC_REF(n_listcopy))
	interpreter.SetProc("push_back", GLOBAL_PROC_REF(n_listadd))
	interpreter.SetProc("remove", GLOBAL_PROC_REF(n_listremove))
	interpreter.SetProc("cut", GLOBAL_PROC_REF(n_listcut))
	interpreter.SetProc("swap", GLOBAL_PROC_REF(n_listswap))
	interpreter.SetProc("insert", GLOBAL_PROC_REF(n_listinsert))

	interpreter.SetProc("pick", GLOBAL_PROC_REF(n_pick))
	interpreter.SetProc("prob", GLOBAL_PROC_REF(prob_chance))
	interpreter.SetProc("substr", GLOBAL_PROC_REF(docopytext_char))

	// Donkie~
	// Strings
	interpreter.SetProc("lower", GLOBAL_PROC_REF(n_lower))
	interpreter.SetProc("upper", GLOBAL_PROC_REF(n_upper))
	interpreter.SetProc("explode", GLOBAL_PROC_REF(string_explode))
	interpreter.SetProc("repeat", GLOBAL_PROC_REF(n_repeat))
	interpreter.SetProc("reverse", GLOBAL_PROC_REF(n_reverse))
	interpreter.SetProc("tonum", GLOBAL_PROC_REF(n_str2num))

	// Numbers
	interpreter.SetProc("tostring", GLOBAL_PROC_REF(n_num2str))
	interpreter.SetProc("sqrt", GLOBAL_PROC_REF(n_sqrt))
	interpreter.SetProc("abs", GLOBAL_PROC_REF(n_abs))
	interpreter.SetProc("floor", GLOBAL_PROC_REF(n_floor))
	interpreter.SetProc("ceil", GLOBAL_PROC_REF(n_ceil))
	interpreter.SetProc("round", GLOBAL_PROC_REF(n_round))
	interpreter.SetProc("clamp", GLOBAL_PROC_REF(n_clamp))
	interpreter.SetProc("inrange", GLOBAL_PROC_REF(n_inrange))
	// End of Donkie~


	// Run the compiled code
	interpreter.Run()

	// Backwards-apply variables onto signal data
	/* sanitize EVERYTHING. fucking players can't be trusted with SHIT */

	signal.data["message"] 	= interpreter.GetVar("$content")
	signal.frequency 		= interpreter.GetVar("$freq")

	var/setname = ""
	var/obj/machinery/telecomms/server/S = signal.data["server"]
	if(interpreter.GetVar("$source") in S.stored_names)
		setname = interpreter.GetVar("$source")
	else
		setname = "<i>[interpreter.GetVar("$source")]</i>"

	if(signal.data["name"] != setname)
		signal.data["realname"] = setname
	signal.data["name"]		= setname
	signal.data["job"]		= interpreter.GetVar("$job")
	signal.data["reject"]	= !(interpreter.GetVar("$pass")) // set reject to the opposite of $pass

	// If the message is invalid, just don't broadcast it!
	if(signal.data["message"] == "" || !signal.data["message"])
		signal.data["reject"] = 1

/*  -- Actual language proc code --  */

/datum/signal/proc/mem(var/address, var/value)

	if(istext(address))
		var/obj/machinery/telecomms/server/S = data["server"]

		if(!value && value != 0)
			return S.memory[address]

		else
			S.memory[address] = value


/datum/signal/proc/tcombroadcast(var/message, var/freq, var/source, var/job)

	var/datum/signal/newsign = new
	var/obj/machinery/telecomms/server/S = data["server"]
	var/obj/item/device/radio/hradio = S.server_radio

	if(!hradio)
		error("[src] has no radio.")
		return

	if((!message || message == "") && message != 0)
		message = "*beep*"
	if(!source)
		source = "[html_encode(uppertext(S.id))]"
		hradio = new // sets the hradio as a radio intercom
	if(!freq)
		freq = PUB_FREQ
	if(findtext(num2text(freq), ".")) // if the frequency has been set as a decimal
		freq *= 10 // shift the decimal one place

	if(!job)
		job = "?"

	newsign.data["mob"] = null
	newsign.data["mobtype"] = /mob/living/carbon/human
	if(source in S.stored_names)
		newsign.data["name"] = source
	else
		newsign.data["name"] = "<i>[html_encode(uppertext(source))]</i>"
	newsign.data["realname"] = newsign.data["name"]
	newsign.data["job"] = job
	newsign.data["compression"] = 0
	newsign.data["message"] = message
	newsign.data["type"] = 2 // artificial broadcast
	if(!isnum(freq))
		freq = text2num(freq)
	newsign.frequency = freq

	var/datum/radio_frequency/connection = radio_controller.return_frequency(freq)
	newsign.data["connection"] = connection


	newsign.data["radio"] = hradio
	newsign.data["vmessage"] = message
	newsign.data["vname"] = source
	newsign.data["vmask"] = 0
	newsign.data["level"] = list()

	var/pass = S.relay_information(newsign, /obj/machinery/telecomms/hub)
	if(!pass)
		S.relay_information(newsign, /obj/machinery/telecomms/broadcaster) // send this simple message to broadcasters
