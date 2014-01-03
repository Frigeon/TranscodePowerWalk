param(
    [string]$startPath = (Get-Variable MyInvocation).Value.MyCommand.Path,
    [Parameter(Mandatory=$true)][string]$fileExtension
)

$i = 0
Get-ChildItem -Path $startPath -Recurse -Include "*.$fileExtension" |
    ForEach-Object {
        $i = $i + 1
        write-host "[Next #$i] $_"
        $name = [io.path]::GetFileNameWithoutExtension("$_") #As the name of the method implies this is to Get the FileName without the File Extension using the Dot Net io path Library
        $dir = [io.path]::GetDirectoryName("$_") #As above, using the same library to get the directory name
        #write-host "[Debug] $name"
        #write-host "[Debug] $dir"
        #vlc has issues with any potential special characters, in particular I noted problems with ' and , thus the use of a temporary file and file move using powershell
        start-process "C:\Program Files (x86)\VideoLAN\VLC\vlc.exe" "-I dummy ""$_"" :sout=#transcode{vcodec=h264,venc=x264{profile=baseline},acodec=mpga,ab=192,channels=2,threads=6}:std{access=file,mux=ts,dst=""E:\transcodeTemp.mp4"" } vlc://quit" -wait
        IF (Test-Path "$dir\$name.mp4"){
            Remove-Item "$dir\$name.mp4"
        }
        Move-Item -Path "E:\transcodeTemp.mp4" -Destination "$dir\$name.mp4"
        #Remove-Item "$_" #Use this if you want 
    }