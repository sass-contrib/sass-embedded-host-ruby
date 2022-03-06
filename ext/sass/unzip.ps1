Param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$Archive,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$DestinationPath
)
if (Get-Command Expand-Archive -ErrorAction SilentlyContinue) {
    Get-Item $Archive | Expand-Archive -DestinationPath $DestinationPath -Force
} else {
    cscript.exe unzip.vbs $Archive $DestinationPath
}
