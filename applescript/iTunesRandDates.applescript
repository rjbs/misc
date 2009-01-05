
set earliestDate to date "Tuesday, March 1, 2005 00:00:0 "
set latestDate to date "Monday, May 30, 2005 00:00:0 "
set totalRange to latestDate - earliestDate

tell application "iTunes"
  set selectedSongs to selection
  repeat with song in selectedSongs
    set played date of song to earliestDate + (random number from 1 to totalRange)
  end repeat
end tell

