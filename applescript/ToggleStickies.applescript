-- This script hides AppleScript if it's the frontmost application and makes it
-- the frontmost application if it isn't.

-- On my copy of the script, the next line has a long-line-break character
-- but that character is wonky and never displays right outside of
-- ScriptEditor.

-- I could find out whether it's running by asking System Events, but this
-- actually seems faster.  What's actually more annoying is that if I write the
-- more reasonable commane "ps ax | grep -c '[S]tickies.app'" I get a useless
-- AppleScript error, "0"

set StickiesRunning to (do shell script "ps ax | grep Stickies.app | grep -v grep | wc -l") + 0

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
