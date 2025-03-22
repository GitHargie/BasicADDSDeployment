# --- New Basic Active Directory Forest Deployment ---
# Created by Hargie J. Curato
# Created date: 03/21/2025
# -- Prerequisites ---
# - Clean install of Operating System. Example: You did not installed ADDS Role then uninstalled it before running this script!. You will never able to run Item #2 if this is the case!
# - Take notes of the Domain and Forest Functional Mode!
# - Able to browse "www.microsoft.com"
# - Network Interface & Firewall already configure properly
# - Server renamed properly
# - Volumes already configure properly
# - Best of all, Operating system is updated!
# - Run this

# -- Start --
Clear-Host

# 1. Set Variables:
$dom = "hcdom.local"  													#Replace the string of the actual name of your Domain.
$nb = "HCDOM"            												#Assuming your $domainName variable contains "hcdomain.local," you might use "hcdomain" as the NetBIOS name.
$dcmode = "WinThreshold"												#Specifies the domain functional level of the first domain in the creation of a new forest. 
$formode = "WinThreshold"												#Specifies the forest functional level for the new forest.

#Type in the administrator password secretly.
$cred = Get-Credential
$pass = $cred.Password  
$dns1 = "192.168.100.105"	 											#Replace the string of the actual primary dns address.
$dns2 = "127.0.0.1"			 											#Replace the string of the actual secondary dns address.
$netinterface = "Ethernet" 												#Replace the string of the actual name of your network interface. In this one, we assume that the network interface name has a string of "Ethernet".

# 2. Install the Active Directory Role:
Install-WindowsFeature AD-Domain-Services -IncludeManagementTools

# 3. Promote the Server to a Domain Controller (New Forest)
$domainName = $dom 																#Replace with your desired domain name.
#$unsafeModePassword = ConvertTo-SecureString "p@55idiot" -AsPlainText -Force 	#Replace with a strong, secure password, if you are a moron who likes to expose the password, uncomment and perform this instead.
$safeModePassword = $pass  														#Replace with a strong, secure password, if you are a chad/sigma do this, more secure because password is not expose!
$databasePath = "C:\Windows\NTDS" 												#Default, Adjust as needed
$logPath = "C:\Windows\NTDS" 													#Default, Adjust as needed
$sysvolPath = "C:\Windows\SYSVOL" 												#Default, Adjust as neededd
$dnsInstallation = $true 														#Install DNS server role

# 4. If you want to install AD Forest with DNS:
Install-ADDSForest -DomainName $domainName -SafeModeAdministratorPassword $safeModePassword -DatabasePath $databasePath -LogPath $logPath -SysvolPath $sysvolPath -InstallDns -DomainNetbiosName $nb -DomainMode $dcmode -Forestmode $formode -Force -NoRebootOnCompletion

# 5. Configure DNS Settings (Verify after installation
# DNS role is installed by Install-ADDSForest, verify settings.
Get-DnsClientServerAddress -InterfaceAlias (Get-NetAdapter | Where-Object {$_.Status -eq "Up"}).Name 							#Check current DNS settings.
# Set-DnsClientServerAddress -InterfaceAlias (Get-NetAdapter | Where-Object {$_.Status -eq "Up"}).Name -ServerAddresses ("127.0.0.1") #sets DNS to local only.

# 6. Get Network Interface Name
$EthernetAdapters = Get-NetAdapter | Where-Object {$_.Name -like "*$netinterface*"} | Select-Object -ExpandProperty Name

# 7. Define network settings
$InterfaceAlias = $EthernetAdapters
$PrimaryDNS = $dns1
$SecondaryDNS = $dns2

# 8. Set the DNS servers
Set-DnsClientServerAddress -InterfaceAlias $InterfaceAlias -ServerAddresses $PrimaryDNS, $SecondaryDNS
Clear-DnsClientCache
Register-DnsClient

# 9. Verify the configuration
Get-NetIPAddress -InterfaceAlias $InterfaceAlias
Get-DnsClientServerAddress -InterfaceAlias $InterfaceAlias


# 10. Create an Organizational Unit (OU) (Optional)
#New-ADOrganizationalUnit -Name "Servers" -Path "DC=example,DC=com" # Update domain components

# 11. Configure Time Synchronization
w32tm /query /status
#w32tm /config /syncfromflags:DOMHIER /reliable:yes /update #set time.

# 12. Verify DNS Records
Get-DnsClientCache
$zoneName = "_msdcs.$domainName"
Get-DnsServerResourceRecord -ZoneName $zoneName

# 13. Configure Firewall Rules (If not done already)
# (See previous port opening script)

# 14. DCDIAG test
dcdiag /v /c /d /e /s:$(hostname) > c:\dcdiag.txt

$response = Read-Host -Prompt "Deployment completed. Do you want to restart the computer now? (Y/N)"
if ($response -eq "Y") {
    Restart-Computer
} else {
    Write-Host "Restart skipped. Please remember to manually restart the computer later." -ForegroundColor Yellow
}



# -- Post Deployment --
# - Copy the commands below in a separate PowerShell instance.
# 15. Specify the domain (use the DN of your domain if needed; otherwise, it will target the current domain). Uncomment the commands below.
#Import-Module ActiveDirectory
#$Domain = (Get-ADDomain).DistinguishedName

# 16. After the server restarted, verify AD DS Installation and Replication.  Uncomment the commands below.
#Get-ADDomainController -Identity $env:COMPUTERNAME
#Repadmin /replsummary
#dcdiag /v /c /d /e /s:$(hostname) > c:\dcdiag.txt

# - Optional configuration
# 1.Disable password length and complexity requirements (optional, not recommended for production, don't be an idiot!)
#Import-Module ActiveDirectory
#Set-ADDefaultDomainPasswordPolicy -Identity $Domain -ComplexityEnabled $false -MinPasswordLength 0
#Write-Host "Password length and complexity requirements have been disabled for the domain: $Domain" -ForegroundColor Green

# 18. Verify the changes to the password policy
#$PasswordPolicy = Get-ADDefaultDomainPasswordPolicy -Identity $Domain
#Write-Host "Verification Results:" -ForegroundColor Cyan
#Write-Host "Minimum Password Length: $($PasswordPolicy.MinPasswordLength)" -ForegroundColor Yellow
#Write-Host "Password Complexity Enabled: $($PasswordPolicy.ComplexityEnabled)" -ForegroundColor Yellow
