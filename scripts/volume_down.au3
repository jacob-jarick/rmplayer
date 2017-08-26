Run ( "SndVol.exe", "", @SW_HIDE)

WinWaitActive ( "Volume Mixer")
send("{DOWN}{DOWN}{DOWN}")
ProcessClose ( "SndVol.exe" )