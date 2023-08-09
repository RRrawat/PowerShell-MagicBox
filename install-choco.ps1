####################3333
# 1
########################
# Installs Chocolatey (needs admin rights)
#Requires -RunAsAdministrator

try {
	[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
	iwr https://community.chocolatey.org/install.ps1 -UseBasicParsing | iex
	exit 0 # success
} catch {
	" Error in line $($_.InvocationInfo.ScriptLineNumber): $($Error[0])"
	exit 1
}


####################3333
# 1
########################
function InstallChocolatey {
  try {
      # Chocolatey is not installed, so proceed with installation
      Write-Host "Chocolatey is not installed. Installing now..."
      if (Test-Path -path "C:\ProgramData\chocolatey"){
        remove-item -path "C:\ProgramData\chocolatey" -Recurse -Force
      } 
      # Set the execution policy and download/install Chocolatey
      Set-ExecutionPolicy RemoteSigned -Scope Process -Force
      [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
      Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
      Write-Host "Chocolatey has been installed successfully."
  }
  catch {
    <#Do this if a terminating exception happens#>
    Write-Host "Failed to install Chocolatey."
    Throw $_
  }
}
InstallChocolatey
