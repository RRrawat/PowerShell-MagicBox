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
