#Add the WSUS role and install the required roles/features
Install-WindowsFeature -Name UpdateServices -IncludeManagementTools

#Configure WSUS post install and Create a directory for WSUS
New-Item 'C:\WSUS' -ItemType Directory
& 'C:\Program Files\Update Services\Tools\WsusUtil.exe' postinstall CONTENT_DIR=C:\WSUS

$wsus = Get-WSUSServer
$wsusConfig = $wsus.GetConfiguration()
Set-WsusServerSynchronization –SyncFromMU
$wsusConfig.AllUpdateLanguagesEnabled = $false
$wsusConfig.SetEnabledUpdateLanguages("en")
$wsusConfig.Save()
$subscription = $wsus.GetSubscription()
$subscription.StartSynchronizationForCategoryOnly()
write-host 'Beginning first WSUS Sync to get available Products etc' -ForegroundColor Magenta
write-host 'Will take some time to complete'
While ($subscription.GetSynchronizationStatus() -ne 'NotProcessing') {
    Write-Host "." -NoNewline
    Start-Sleep -Seconds 10
}
Write-Host "initial Sync is done." -ForegroundColor Green
# Configure the Platforms that we want WSUS to receive updates
write-host 'Setting WSUS Products'
Get-WsusProduct | where-Object {
    $_.Product.Title -notin (
    'Visual Studio 2022',
    'ASP.NET Web Framework',
    'Microsoft 365 Apps/Office 2019/Office LTSC',
    'Windows Server 2012 R2',
    'Windows Server 2016',
    'Windows Server 2019 and later, Servicing Drivers'
    )
} | Set-WsusProduct -Disable

write-host 'Setting WSUS Products'
Get-WsusProduct | where-Object {
    $_.Product.Title -in (
    'Visual Studio 2022',
    'ASP.NET Web Framework',
    'Microsoft 365 Apps/Office 2019/Office LTSC',
    'Windows Server 2012 R2',
    'Windows Server 2016',
    'Windows Server 2019 and later, Servicing Drivers'
    )
} | Set-WsusProduct
Get-WsusProduct -TitleIncludes "ASP.NET Web Framework" | Set-WsusProduct
#Get only specific classifications
Get-WsusClassification | Where-Object { $_.Classification.Title -notin 'Update Rollups','Security Updates','Critical Updates'  } | Set-WsusClassification -Disable
Get-WsusClassification | Where-Object { $_.Classification.Title -in 'Update Rollups','Security Updates','Critical Updates'  } | Set-WsusClassification
# Configure Synchronizations
write-host 'Enabling WSUS Automatic Synchronisation'
$subscription.SynchronizeAutomatically=$true

# Set synchronization scheduled for midnight each 7 day night
$subscription.SynchronizeAutomaticallyTimeOfDay= (New-TimeSpan -Hours 0)
$subscription.NumberOfSynchronizationsPerDay=7
$subscription.Save()

Start-Sleep -Seconds 60 # Wait for sync to start before monitoring
while ($subscription.GetSynchronizationProgress().ProcessedItems -ne $subscription.GetSynchronizationProgress().TotalItems) {
    Write-Progress -PercentComplete (
    $subscription.GetSynchronizationProgress().ProcessedItems*100/($subscription.GetSynchronizationProgress().TotalItems)
    ) -Activity "WSUS Sync Progress"
}

#Enable reports
#Install .NET 3.5 using the installation iso mounted in the virtual DVD drive (in this case)
Install-WindowsFeature NET-Framework-Core -Source D:\sources\sxs
#Install Microsoft report viewer redistributable 2008
#Get it from: https://www.microsoft.com/en-us/download/confirmation.aspx?id=6576
Start-Process -FilePath '.\ReportViewer 2008.exe' -ArgumentList '/q' -Wait

# Configure Email Notifications
$email = $wsus.GetEmailNotificationConfiguration()
$ErrorActionPreference = 'Stop'

# Directly set the values for email notification configuration
$email.StatusNotificationTimeOfDay = (New-TimeSpan -Hours 0)
$email.SenderDisplayName = "WSUS"
$email.SenderEmailAddress = <SenderEmailAddress>
$email.SMTPHostname = <SMTPHostname>
$email.SMTPPort = 25
$email.SmtpServerRequiresAuthentication = $False
$email.StatusNotificationFrequency = [Microsoft.UpdateServices.Administration.EmailStatusNotificationFrequency]::Weekly
# Save Configuration Changes
try {
    $email.Save()
    Write-Host -Fore Green "Email settings changed"
} catch {
    Write-Warning "$($error[0])"
}

#Enable reports
#Install .NET 3.5 using the installation iso mounted in the virtual DVD drive (in this case)
Install-WindowsFeature NET-Framework-Core -Source D:\sources\sxs
#Install Microsoft CLR Types for SQL Server 2012
#Get it from: http://go.microsoft.com/fwlink/?LinkID=239644&clcid=0x409
Start-Process -FilePath 'msiexec.exe' -ArgumentList '/i C:\2012.msi','/qn','/norestart' -Wait
#Install Microsoft report viewer redistributable 2012
#Get it from: https://www.microsoft.com/en-us/download/confirmation.aspx?id=35747
Start-Process -FilePath 'msiexec.exe' -ArgumentList '/i "C:\ReportViewer 2012.msi"','/qn','/norestart','ALLUSERS=2' -Wait
			
