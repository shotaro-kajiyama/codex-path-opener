#Requires AutoHotkey v2.0
#SingleInstance Force

; CodexPathOpener
; Select text in a terminal/chat, then press Ctrl+Alt+O.
; It extracts the first path-like string and opens it in VS Code.
;
; Hotkeys:
;   Ctrl+Alt+O        Open first detected path
;   Ctrl+Alt+P        Search selected path/query in VS Code Quick Open
;   Ctrl+Alt+Shift+O  Open all detected paths
;   Alt+Left Click    Copy selection and open first detected path

global AppName := "CodexPathOpener"
global IniPath := A_ScriptDir "\CodexPathOpener.ini"

global WslDistro := IniRead(IniPath, "Settings", "WslDistro", "Ubuntu")
global WslProjectRoot := IniRead(IniPath, "Settings", "WslProjectRoot", "~")
global WindowsProjectRoot := IniRead(IniPath, "Settings", "WindowsProjectRoot", "")

TraySetIcon("shell32.dll", 3)
A_TrayMenu.Delete()
A_TrayMenu.Add("Open first path`tCtrl+Alt+O", (*) => OpenFromSelection(false))
A_TrayMenu.Add("Search in VS Code`tCtrl+Alt+P", (*) => QuickOpenFromSelection())
A_TrayMenu.Add("Open all paths`tCtrl+Alt+Shift+O", (*) => OpenFromSelection(true))
A_TrayMenu.Add()
A_TrayMenu.Add("Settings", (*) => ShowSettings())
A_TrayMenu.Add("Reload", (*) => Reload())
A_TrayMenu.Add("Exit", (*) => ExitApp())

^!o::OpenFromSelection(false)
^!p::QuickOpenFromSelection()
^!+o::OpenFromSelection(true)
!LButton::OpenFromSelection(false)

OpenFromSelection(openAll) {
    oldClipboard := ClipboardAll()
    A_Clipboard := ""
    Send("^c")

    if !ClipWait(0.35) {
        A_Clipboard := oldClipboard
        Toast("No selected text copied.")
        return
    }

    text := A_Clipboard
    A_Clipboard := oldClipboard

    paths := ExtractPaths(text)
    if paths.Length = 0 {
        Toast("No path found.")
        return
    }

    if openAll {
        OpenPaths(paths)
        Toast("Opened " paths.Length " path(s).")
    } else {
        OpenPath(paths[1])
        Toast("Opened: " paths[1])
    }
}

QuickOpenFromSelection() {
    text := GetSelectedText()
    if text = "" {
        Toast("No selected text copied.")
        return
    }

    query := BuildQuickOpenQuery(text)
    if query = "" {
        Toast("No search query found.")
        return
    }

    if !ActivateExistingVsCodeWindow() {
        OpenVsCodeRoot()
        if WinWait("ahk_exe Code.exe", , 5) {
            WinActivate("ahk_exe Code.exe")
            Sleep(400)
        }
    }

    oldClipboard := ClipboardAll()
    A_Clipboard := query
    ClipWait(0.3)
    Send("^p")
    Sleep(150)
    Send("^v")
    Sleep(150)
    A_Clipboard := oldClipboard

    Toast("VS Code search: " query)
}

GetSelectedText() {
    oldClipboard := ClipboardAll()
    A_Clipboard := ""
    Send("^c")

    if !ClipWait(0.35) {
        A_Clipboard := oldClipboard
        return ""
    }

    text := A_Clipboard
    A_Clipboard := oldClipboard
    return text
}

ExtractPaths(text) {
    paths := []
    seen := Map()

    ; Windows drive paths, UNC paths, WSL/Linux absolute paths, and relative paths with slashes.
    patterns := [
        "i)([A-Z]:\\[^\s<>|\*\?、。]+)",
        "i)(\\\\wsl(?:\.localhost)?\\[^\s<>|\*\?、。]+)",
        "(~?/[^\s<>|、。]+)",
        "((?:\.{1,2}|[A-Za-z0-9_.@+-]+)(?:/[A-Za-z0-9_.@+:{},-]+)+/?)"
    ]

    for pattern in patterns {
        pos := 1
        while pos := RegExMatch(text, pattern, &m, pos) {
            candidate := CleanPath(m[1])
            if IsUsefulPath(candidate) && !seen.Has(candidate) {
                seen[candidate] := true
                paths.Push(candidate)
            }
            pos += StrLen(m[0])
        }
    }

    return paths
}

BuildQuickOpenQuery(text) {
    paths := ExtractPaths(text)
    query := paths.Length ? paths[1] : CleanPath(text)

    query := RegExReplace(query, "\\", "/")
    query := RegExReplace(query, "^[A-Za-z]:/", "")
    query := RegExReplace(query, "^//wsl(?:\.localhost)?/[^/]+/", "")

    if RegExMatch(query, "([^/]*?)\{[^}]+\}([^/]*)$", &m) {
        prefix := m[1]
        suffix := m[2]
        if prefix != ""
            return prefix
        return suffix
    }

    return query
}

CleanPath(path) {
    quote := Chr(34)
    path := Trim(path, " `t`r`n" quote "'()[]{}<>")

    ; Drop common trailing Japanese/English punctuation from prose.
    while RegExMatch(path, "[,.;:、。）」』】〕〉》]+$") {
        path := RegExReplace(path, "[,.;:、。）」』】〕〉》]+$")
    }

    ; Preserve file:line, but remove Markdown's closing paren if copied with a link.
    path := RegExReplace(path, "\)$")
    return path
}

IsUsefulPath(path) {
    if path = ""
        return false
    if RegExMatch(path, "i)^https?://")
        return false
    if RegExMatch(path, "^[A-Za-z]+/[A-Za-z]+$") && !RegExMatch(path, "\.")
        return true
    return InStr(path, "\") || InStr(path, "/")
}

OpenPath(path) {
    OpenPaths([path])
}

OpenPaths(paths) {
    global WslDistro, WslProjectRoot, WindowsProjectRoot

    tempFile := A_Temp "\CodexPathOpener-" A_TickCount ".txt"
    body := ""
    for path in paths {
        body .= path "`n"
    }
    FileAppend(body, tempFile, "UTF-8")

    ps1 := A_ScriptDir "\OpenCodexPath.ps1"
    cmd := "powershell.exe -NoProfile -ExecutionPolicy Bypass -File " Q(ps1)
        . " -PathFile " Q(tempFile)
        . " -WslDistro " Q(WslDistro)
        . " -WslProjectRoot " Q(WslProjectRoot)
        . " -WindowsProjectRoot " Q(WindowsProjectRoot)

    Run(cmd, , "Hide")
}

OpenVsCodeRoot() {
    global WslDistro, WslProjectRoot, WindowsProjectRoot

    ps1 := A_ScriptDir "\OpenVsCodeRoot.ps1"
    cmd := "powershell.exe -NoProfile -ExecutionPolicy Bypass -File " Q(ps1)
        . " -WslDistro " Q(WslDistro)
        . " -WslProjectRoot " Q(WslProjectRoot)
        . " -WindowsProjectRoot " Q(WindowsProjectRoot)

    Run(cmd, , "Hide")
}

ActivateExistingVsCodeWindow() {
    ; WinExist returns the topmost matching Code window, which normally tracks
    ; the most recently used VS Code window in the desktop z-order.
    hwnd := WinExist("ahk_exe Code.exe")
    if !hwnd {
        return false
    }

    WinActivate("ahk_id " hwnd)
    if !WinWaitActive("ahk_id " hwnd, , 2) {
        return false
    }

    Sleep(150)
    return true
}

Q(value) {
    quote := Chr(34)
    return quote StrReplace(value, quote, "\" quote) quote
}

ShowSettings() {
    global IniPath, WslDistro, WslProjectRoot, WindowsProjectRoot

    distro := InputBox("WSL distro name:", "CodexPathOpener Settings", "w420 h120", WslDistro)
    if distro.Result = "Cancel"
        return

    root := InputBox("WSL project root for relative paths:`nExample: ~/projects/sample-app", "CodexPathOpener Settings", "w520 h150", WslProjectRoot)
    if root.Result = "Cancel"
        return

    winRoot := InputBox("Optional Windows project root for relative paths:`nLeave empty if you mainly use WSL.", "CodexPathOpener Settings", "w520 h150", WindowsProjectRoot)
    if winRoot.Result = "Cancel"
        return

    IniWrite(distro.Value, IniPath, "Settings", "WslDistro")
    IniWrite(root.Value, IniPath, "Settings", "WslProjectRoot")
    IniWrite(winRoot.Value, IniPath, "Settings", "WindowsProjectRoot")

    WslDistro := distro.Value
    WslProjectRoot := root.Value
    WindowsProjectRoot := winRoot.Value

    Toast("Settings saved.")
}

Toast(message) {
    TrayTip(AppName, message, 1)
}
