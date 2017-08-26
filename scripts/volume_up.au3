Run ( "SndVol.exe", "", @SW_HIDE)

WinWaitActive ( "Volume Mixer")
send("{UP}{UP}{UP}")
ProcessClose ( "SndVol.exe" )