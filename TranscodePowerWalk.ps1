<#
.SYNOPSIS
Uses VLC Media Player to transcode all videos of a particular file extension to H264 format
.DESCRIPTION
This is a batch transcode script using VLC media player in the default location and presently a temporary file on drive D:\ to store the transcode with the option to delete the original file after transcode.
.PARAMETER fileExtension
This is a comma delimited list of the file extensions you want to transcode (eg. avi,mkv,mpg) //TODO - currently supports one extension at a time
.PARAMETER audioTracks
This is a comma seperated list of the audio track numbers to attempt to transcode //TODO - currently only works in handbrake
.PARAMETER startPath
This is the location of the folder you want to scan (defaults to the current folder)
.PARAMETER tempFolder
This is the folder location of the temporary transcode, make sure it does not end in a \
(suggestion - make sure if it is a removable drive that cached write is turned on otherwise the number of disk accesses may cause problems)
.PARAMETER delete
Tells the script whether or not to delete the original file (True/FALSE)
.PARAMETER transcoder
Tells the script whether you want to use vlc or handbrake as the transcoding software ("vlc"/"handbrake")
.EXAMPLE
TranscodePowerWalk -fileExtension "mkv" -audioTracks "1, 2" -startPath "D:\Video" -tempFolder "D:" -delete "false" -transcoder "vlc"
.LINK
jonathanhalls.gralindfarms.com
#>

param(
    [Parameter(Mandatory=$true)][string]$fileExtension,
    [string]$audioTracks = "1",
    [string]$startPath = (Get-Variable MyInvocation).Value.MyCommand.Path,
    [string]$tempFolder = "C:",
    [string]$delete = "false",
    [string]$transcoder = "handbrake"
)
$handbrake = "C:\Program Files\Handbrake\HandBrakeCLI.exe"
$vlc = "C:\Program Files (x86)\VideoLAN\VLC\vlc.exe"

$i = 0

IF (-Not([string]::Compare($transcoder, "handbrake", $True))){
    "[Now Using HandbrakeCLI] Located at $handbrake"
} else {
    "[Now Using VLC] Located at $vlc"
}

Get-ChildItem -Path $startPath -Recurse -Include "*.$fileExtension" |
    ForEach-Object {
        $i = $i + 1
        write-host "[Next #$i] $_"
        write-host "[Output] From #$i to $tempFolder\transcodeTemp.mp4"
        $name = [io.path]::GetFileNameWithoutExtension("$_") #As the name of the method implies this is to Get the FileName without the File Extension using the Dot Net io path Library
        $dir = [io.path]::GetDirectoryName("$_") #As above, using the same library to get the directory name
        #write-host "[Debug] $name"
        #write-host "[Debug] $dir"
        #vlc has issues with any potential special characters, in particular I noted problems with ' and , thus the use of a temporary file and file move using powershell
        IF (-Not([string]::Compare($transcoder, "handbrake", $True))){
            start-process "$handbrake" "-a $audioTracks -i `"$_`" -o `"$tempFolder\transcodeTemp.mp4`" -Z `"High Profile`" 2> `"$tempFolder\transcode-error.log`" >> $`"$tempFolder\transcode.log`"" -wait -WindowStyle Minimized 2> "$tempFolder\HBErrors.log"
        }
        else {
            start-process "$vlc" "-I dummy `"$_`" :sout=#transcode{vcodec=h264,venc=x264{profile=high10},acodec=mpga,ab=192,channels=2,threads=6}:std{access=file,mux=ts,dst=`"$tempFolder\transcodeTemp.mp4`" } vlc://quit" -wait -WindowStyle Minimized 2> "$tempFolder\VLCErrors.log"
        }
        
        IF (Test-Path "$dir\$name.mp4"){
            write-host "[File Exists] Removing existing MP4 @ $dir\$name.mp4"
            Remove-Item "$dir\$name.mp4"
        }
        write-host "[Moving] Moving from $tempFolder\transcodeTemp.mp4 to $dir\$name.mp4"
        Move-Item -Path "$tempFolder\transcodeTemp.mp4" -Destination "$dir\$name.mp4"
        IF (-Not([string]::Compare($delete, "True", $True))){
            Remove-Item "$_" #this is triggered via command line option
        }
    }