set StickiesRunning to Â
	(do shell script "ps ax | grep Stickies.app | grep -v grep | wc -l") + 0

if StickiesRunning > 0 then
	tell application "System Events"
		set stickies to some item of (get processes whose name = "Stickies")
		if (stickies's frontmost is true) then
			if (get visible of stickies) then
				set visible of stickies to false
			else
				set visible of stickies to true
				tell application "Stickies" to activate
			end if
		else
			set stickies's frontmost to true
			set stickies's visible to true
		end if
	end tell
else
	tell application "Stickies" to activate
end if