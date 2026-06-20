param(
    [string]$WslDistro = "Ubuntu",
    [string]$WslProjectRoot = "~",
    [string]$WindowsProjectRoot = ""
)

function Quote-BashArg {
    param([string]$Value)
    return "'" + ($Value -replace "'", "'\''") + "'"
}

function ConvertTo-BashRootExpr {
    param([string]$Root)

    if (-not $Root -or $Root -eq "~") {
        return '${HOME}'
    }

    if ($Root.StartsWith("~/")) {
        return '${HOME}' + (Quote-BashArg $Root.Substring(1))
    }

    return Quote-BashArg $Root
}

if ($WindowsProjectRoot) {
    & code -r $WindowsProjectRoot
    exit
}

$rootExpr = ConvertTo-BashRootExpr $WslProjectRoot
$cmd = "cd $rootExpr && code -r ."
& wsl.exe -d $WslDistro -- bash -lc $cmd
