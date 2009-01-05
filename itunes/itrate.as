tell application "iTunes"
  tell playlist "Library"
	repeat with song in (every track whose size is 866970)
	  set rating of song to 100
	end repeat
  end tell
end tell
