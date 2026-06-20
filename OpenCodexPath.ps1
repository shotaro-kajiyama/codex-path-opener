param(
    [Parameter(Mandatory = $true)]
    [string]$PathFile,

    [string]$WslDistro = "Ubuntu",
    [string]$WslProjectRoot = "~",
    [string]$WindowsProjectRoot = ""
)

function Quote-BashArg {
    param([string]$Value)
    return "'" + ($Value -replace "'", "'\''") + "'"
}

function Open-WithCode {
    param([string]$Target)
    & code -g $Target
}

try {
    $paths = Get-Content -LiteralPath $PathFile -Encoding UTF8 | Where-Object { $_.Trim() -ne "" }

    foreach ($raw in $paths) {
        $path = $raw.Trim()

        if ($path -match "^[A-Za-z]:\\" -or $path -match "^\\\\") {
            Open-WithCode $path
            continue
        }

        if ($path.StartsWith("/") -or $path.StartsWith("~")) {
            $cmd = "code -g $(Quote-BashArg $path)"
            & wsl.exe -d $WslDistro -- bash -lc $cmd
            continue
        }

        if ($WslProjectRoot -and $WslProjectRoot -ne "~") {
            $cmd = "cd $(Quote-BashArg $WslProjectRoot) && code -g $(Quote-BashArg $path)"
            & wsl.exe -d $WslDistro -- bash -lc $cmd
            continue
        }

        if ($WindowsProjectRoot) {
            $windowsPath = Join-Path -Path $WindowsProjectRoot -ChildPath ($path -replace "/", "\")
            Open-WithCode $windowsPath
            continue
        }

        Open-WithCode $path
    }
}
finally {
    Remove-Item -LiteralPath $PathFile -ErrorAction SilentlyContinue
}
