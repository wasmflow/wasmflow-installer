param (
  [string]$projectRoot = "C:\wasmflow",
  [string]$arch = "win64",
  [string]$release = "latest"
)

Write-Output ""
$ErrorActionPreference = 'stop'

#Escape spaces in $projectRoot path
$projectRoot = $projectRoot -replace ' ', '` '

$orgName = "wasmflow"
$projectName = "wasmflow"

$assetBasename = "${projectName}.${arch}"
$baseUrl = "https://github.com/${orgName}/${projectName}/releases"

$archiveExt = "zip"
$binExt = ".exe"
$archiveDir = $assetBasename
if (!($arch -like "*win*")) {
  $archiveExt = "tar.gz"
  $binExt = ""
  $archiveDir = "wasmflow"
}

$archiveFiles = "wafl${binExt}", "wasmflow${binExt}"
$cliFilepath = Join-Path ${projectRoot} $archiveFiles[0]
$cliZipExtracted = Join-Path $projectRoot $archiveDir

if ((Get-ExecutionPolicy) -gt 'RemoteSigned' -or (Get-ExecutionPolicy) -eq 'ByPass') {
  Write-Output "PowerShell requires an execution policy of 'RemoteSigned'."
  Write-Output "To make this change please run:"
  Write-Output "'Set-ExecutionPolicy RemoteSigned -scope CurrentUser'"
  break
}

# Change security protocol to support TLS 1.2 / 1.1 / 1.0 - old powershell uses TLS 1.0 as a default protocol
[Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls"

# Check if CLI is installed.
Write-Output "Installing $projectName..."

# Create project root directory
Write-Output "Creating $projectRoot directory"
New-Item -ErrorAction Ignore -Path $projectRoot -ItemType "directory"
if (!(Test-Path $projectRoot -PathType Container)) {
  throw "Cannot create $projectRoot"
}

$assetName = "${assetBasename}.${archiveExt}"
if ($release -eq "latest") {
  $zipFileUrl = "${baseUrl}/${release}/download/${assetName}"
}
else {
  $zipFileUrl = "${baseUrl}/download/${release}/${assetName}"
}

$zipFilePath = Join-Path $projectRoot $assetName
Write-Output "Downloading $zipFileUrl ..."

Invoke-WebRequest -Uri $zipFileUrl -OutFile $zipFilePath
if (!(Test-Path $zipFilePath -PathType Leaf)) {
  throw "Failed to download $projectName archive - $zipFilePath"
}

# Extract CLI to $projectRoot
Write-Output "Extracting $zipFilePath..."
if ($archiveExt -eq "zip") {
  Microsoft.Powershell.Archive\Expand-Archive -Force -Path $zipFilePath -DestinationPath $cliZipExtracted
}
else {
  tar -xzvf $zipFilePath --directory $projectRoot
}
if (!(Test-Path $cliZipExtracted -PathType Container)) {
  throw "Failed to extract $projectName archive - $cliZipExtracted"
}

foreach ($file in $archiveFiles) {
  $path = Join-Path ${cliZipExtracted} ${file}
  Copy-Item $path -Destination $projectRoot
}

Write-Output "Removing temporary directory $cliZipExtracted..."
Remove-Item $cliZipExtracted -Force -Recurse

# Clean up zipfile
Write-Output "Removing $zipFilePath..."
Remove-Item $zipFilePath -Force

# Add projectRoot directory to User Path environment variable
Write-Output "Trying to add $projectRoot to User Path Environment variable..."
$UserPathEnvironmentVar = [Environment]::GetEnvironmentVariable("PATH", "User")
if ($UserPathEnvironmentVar -like "*$projectRoot*") {
  Write-Output "Found what looks like $projectName in User Path, skipping..."
}
else {
  [System.Environment]::SetEnvironmentVariable("PATH", $UserPathEnvironmentVar + ";$projectRoot", "User")
  $UserPathEnvironmentVar = [Environment]::GetEnvironmentVariable("PATH", "User")
  Write-Output "Added $projectRoot to User Path..."
}

# Check versions
foreach ($file in $archiveFiles) {
  $path = Join-Path $projectRoot $file
  Write-Output "Invoking $path..."
  Invoke-Expression "$path --version"
}

Write-Output "`r`n$projectRoot is installed successfully."
Write-Output "`r`nYou will need to start a new shell for the updated PATH."
