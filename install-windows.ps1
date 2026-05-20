#requires -Version 5.1
& "$PSScriptRoot\setup.ps1" -Mode Install @args
exit $LASTEXITCODE
