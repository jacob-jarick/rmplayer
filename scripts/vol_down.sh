#!/bin/bash

# Cross-platform volume down script
if command -v amixer >/dev/null 2>&1; then
    # Linux/Unix with ALSA
    amixer --quiet sset Master 5%- 2>/dev/null || amixer --quiet set Master 5%-
    amixer sget Master | grep -o '[0-9]*%' | head -1
elif command -v pactl >/dev/null 2>&1; then
    # Linux/Unix with PulseAudio
    pactl set-sink-volume @DEFAULT_SINK@ -5%
    echo "Volume -5% (PulseAudio)"
elif command -v osascript >/dev/null 2>&1; then
    # macOS
    osascript -e "set volume output volume (output volume of (get volume settings) - 7)"
    echo "Volume -7% (macOS)"
elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]] || [[ "$OS" == "Windows_NT" ]]; then
    # Windows - use nircmd if available, otherwise PowerShell
    if command -v nircmd >/dev/null 2>&1; then
        nircmd changesysvolume -6553
        echo "Volume -10% (nircmd)"
    else
        # PowerShell method
        powershell -Command "
        Add-Type -TypeDefinition '
        using System.Runtime.InteropServices;
        [Guid(\"5CDF2C82-841E-4546-9722-0CF74078229A\"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
        interface IAudioEndpointVolume {
            int f(); int g(); int h(); int i();
            int SetMasterVolumeLevel(float fLevelDB, System.Guid pguidEventContext);
            int SetMasterVolumeLevelScalar(float fLevel, System.Guid pguidEventContext);
            int GetMasterVolumeLevel(out float pfLevelDB);
            int GetMasterVolumeLevelScalar(out float pfLevel);
        }
        [Guid(\"D666063F-1587-4E43-81F1-B948E807363F\"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
        interface IMMDevice {
            int Activate(ref System.Guid id, int clsCtx, int activationParams, out IAudioEndpointVolume aev);
        }
        [Guid(\"A95664D2-9614-4F35-A746-DE8DB63617E6\"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
        interface IMMDeviceEnumerator {
            int f(); int GetDefaultAudioEndpoint(int dataFlow, int role, out IMMDevice endpoint);
        }
        [ComImport, Guid(\"BCDE0395-E52F-467C-8E3D-C4579291692E\")] class MMDeviceEnumeratorComObject { }
        public class Audio {
            static IAudioEndpointVolume Vol() {
                var enumerator = new MMDeviceEnumeratorComObject() as IMMDeviceEnumerator;
                IMMDevice dev = null;
                Marshal.ThrowExceptionForHR(enumerator.GetDefaultAudioEndpoint(0, 1, out dev));
                IAudioEndpointVolume epv = null;
                var epvid = typeof(IAudioEndpointVolume).GUID;
                Marshal.ThrowExceptionForHR(dev.Activate(ref epvid, 4, 0, out epv));
                return epv;
            }
            public static float GetVolume() { float v = -1; Marshal.ThrowExceptionForHR(Vol().GetMasterVolumeLevelScalar(out v)); return v; }
            public static void SetVolume(float v) { Marshal.ThrowExceptionForHR(Vol().SetMasterVolumeLevelScalar(v, System.Guid.Empty)); }
        }';
        [Audio]::SetVolume([Math]::Max(0.0, [Audio]::GetVolume() - 0.05));
        Write-Host ('Volume: ' + [Math]::Round([Audio]::GetVolume() * 100) + '%')
        "
    fi
else
    echo "Volume control not supported on this system"
    exit 1
fi
