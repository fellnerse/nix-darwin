property openApps : {"Slack", "Microsoft Teams", "Microsoft Outlook", "Obsidian", "Script Editor", "Bitwarden", "WhatsApp", "Signal", "Mail", "Zed", "Claude", "Zen"}
property additionalCloseApps : {"Preview", "Sublime", "PowerPoint", "WhatsApp", "Signal", "Calendar", "Outlook", "Teams", "Script", "Finder", "Spotify", "Mail", "Monitor", "Word", "Excel", "Terminal", "Ghostty", "Microsoft Excel", "Herdr", "Tern", "TV", "Windows App", "Zed"}

on run
	repeat with a in openApps
		try
			do shell script "/usr/bin/open -ga " & quoted form of (a as text)
		end try
	end repeat
end run

on quit
	set targets to openApps & additionalCloseApps

	-- ask every app to quit without saving (non-blocking)
	repeat with a in targets
		ignoring application responses
			try
				tell application (a as text) to quit saving no
			end try
		end ignoring
	end repeat

	-- brief moment, then force-kill leftovers
	delay 0.3
	repeat with a in targets
		set pids to my pidsFor(a as text)
		repeat with pidVal in pids
			try
				do shell script "/bin/kill -9 " & pidVal
			end try
		end repeat
	end repeat

	continue quit
end quit

on pidsFor(appName)
	try
		try
			set bid to id of application appName
		on error
			set bid to missing value
		end try
		tell application "System Events"
			if bid is missing value then
				return unix id of (every process whose name is appName)
			else
				return unix id of (every process whose bundle identifier is bid)
			end if
		end tell
	on error
		return {}
	end try
end pidsFor
