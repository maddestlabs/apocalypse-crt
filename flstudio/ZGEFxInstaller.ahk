#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases
#Warn   ; Enable warnings to assist with detecting common errors
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory

; Find FL Studio installation through registry
RegRead, FLStudioPath, HKEY_LOCAL_MACHINE\SOFTWARE\Image-Line\FL Studio, Install_Dir
if ErrorLevel ; If registry read failed, try the 64-bit registry
{
    RegRead, FLStudioPath, HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Image-Line\FL Studio, Install_Dir
    if ErrorLevel ; If both registry reads failed
    {
        ; Attempt to find FL Studio in common installation locations
        if FileExist("C:\Program Files\Image-Line\FL Studio\FL64.exe")
            FLStudioPath := "C:\Program Files\Image-Line\FL Studio"
        else if FileExist("C:\Program Files (x86)\Image-Line\FL Studio\FL64.exe")
            FLStudioPath := "C:\Program Files (x86)\Image-Line\FL Studio"
        else
        {
            MsgBox, Could not automatically find FL Studio installation.`nPlease select your main FL Studio folder (where FL64.exe is located).
            FileSelectFolder, SelectedPath, , 3, Select your FL Studio installation folder (containing FL64.exe)
            if !SelectedPath
            {
                MsgBox, No folder selected. Exiting script.
                ExitApp
            }
            
            ; Verify the selected folder contains FL64.exe
            if FileExist(SelectedPath . "\FL64.exe") || FileExist(SelectedPath . "\FL Studio.exe")
                FLStudioPath := SelectedPath
            else
            {
                MsgBox, The selected folder does not appear to be a valid FL Studio installation.`nFL64.exe or FL Studio.exe was not found. Exiting script.
                ExitApp
            }
        }
    }
}

; Make sure we have a valid path with trailing backslash
if (SubStr(FLStudioPath, 0, 1) != "\")
    FLStudioPath := FLStudioPath . "\"

; Define target directory
TargetDir := FLStudioPath . "Plugins\Fruity\Effects\ZGameEditor Visualizer\Effects\Postprocess\"

; Check if target directory exists
if !FileExist(TargetDir)
{
    ; Try to create the directory if it doesn't exist
    FileCreateDir, %TargetDir%
    
    if ErrorLevel
    {
        MsgBox, ZGameEditor Visualizer Effects folder not found and could not be created at:`n%TargetDir%`n`nPlease make sure FL Studio is installed correctly.
        ExitApp
    }
    MsgBox, Created ZGameEditor Visualizer Effects folder at:`n%TargetDir%
}

; Count files to copy
FileCount := 0
Loop, Files, %A_ScriptDir%\*.zgeproj
    FileCount++

if (FileCount = 0)
{
    MsgBox, No .zgeproj files found in the current directory.
    ExitApp
}

; Copy all .zgeproj files from current directory to target
FilesSuccess := 0
Loop, Files, %A_ScriptDir%\*.zgeproj
{
    FileCopy, %A_LoopFileFullPath%, %TargetDir%, 1
    if !ErrorLevel
        FilesSuccess++
}

; Show results
if (FilesSuccess = FileCount)
    MsgBox, Successfully copied all %FileCount% .zgeproj files to:`n%TargetDir%
else
    MsgBox, Copied %FilesSuccess% of %FileCount% .zgeproj files to:`n%TargetDir%

ExitApp
