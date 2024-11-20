<#
Date:  June, 2021
Written by Jacob Collinson
Summary:  

This script can be used to do the following things.

1.  Change the hostname of a computer.
2.  Join the computer to the domain.
3.  Put the computer into the specified domain organizational unit (OU).
#> 

[CmdletBinding(SupportsShouldProcess=$true)]

# Get the ID and security principal of the current user account
$myWindowsID=[System.Security.Principal.WindowsIdentity]::GetCurrent()
$myWindowsPrincipal=new-object System.Security.Principal.WindowsPrincipal($myWindowsID)
 
# Get the security principal for the Administrator role
$adminRole=[System.Security.Principal.WindowsBuiltInRole]::Administrator
 
# Check to see if we are currently running "as Administrator"
if ($myWindowsPrincipal.IsInRole($adminRole))
   {
   # We are running "as Administrator" - so change the title and background color to indicate this
   $Host.UI.RawUI.WindowTitle = $myInvocation.MyCommand.Definition + "(Elevated)"
   $Host.UI.RawUI.BackgroundColor = "DarkGreen"
   clear-host
   }
else
   {
   # We are not running "as Administrator" - so relaunch as administrator
   
   # Create a new process object that starts PowerShell
   $newProcess = new-object System.Diagnostics.ProcessStartInfo "PowerShell";
   
   # Specify the current script path and name as a parameter
   $newProcess.Arguments = $myInvocation.MyCommand.Definition;
   
   # Indicate that the process should be elevated
   $newProcess.Verb = "runas";
   
   # Start the new process
   [System.Diagnostics.Process]::Start($newProcess);
   
   # Exit from the current, unelevated, process
   exit
   }
   
# Define the variables
# Get if this is a desktop or a laptop, default is for work station.
# more option could be added if using on workstation, servers, etc.
$hardwaretype = (Get-wmiobject Win32_Computersystem).PCSystemType
switch ($hardwaretype){
    1     {$hardware = "DT"}
    2     {$hardware = "LT"}
    default {$hardware = "WS"}
}



# get the serial number
$compSN = (Get-wmiobject win32_bios).SerialNumber


$beginningofSN = {
$x = "0"
$y = "4"
$firstprtofSN = $compSN[$y..$x] -join''
}

# uses only the last 4 characters of the serialnumber meant for Lenovo
$endofSN = {
$x = $compSN.length
$y = $x-4
$lastprtofSN = $compSN[$y..$x] -join''
}


Write-Host 
write-host $lastprtofSN
# get the default gateway IP information
$sitegateway =  Get-NetRoute -DestinationPrefix "0.0.0.0/0" | Select-Object -ExpandProperty "NextHop"

# Use the default gateway information to get the site organization code
switch ($sitegateway){ 
    10.64.24.1  {$sitecode = ""} # 
    10.64.200.1  {$sitecode = "LSS"} # 
    10.69.112.1  {$sitecode = "ROS"} # 
    10.69.120.1  {$sitecode = "ROS"} # 
    10.68.152.1  {$sitecode = "ROS"} # 
    10.64.64.1  {$sitecode = "FPF"} # 
    10.86.64.1  {$sitecode = "FPF"} # 
    10.86.72.1  {$sitecode = "FPF"} # 
    10.64.32.1  {$sitecode = "FSF"} # 
    default     {$sitecode = "NOTFOUND"}
    }


If($sitecode -eq "NOTFOUND"){
    $sitecode = Read-Host "Enter site code FPF, ROS, FSF, or LSS:  "
    $sitecode = $sitecode.ToUpper()
    }
    else {continue}

    

# 1.  Specify the new computer name combining the information gathered above.
$NewHostName = $sitecode+'-'+$hardware.ToUpper()+'-'+$lastprtofSN

# 2.  Specify the domain to join.
switch ($sitecode){
    FSF  {$DomainToJoin = "corp.freedomsquarefl.com"}
    LSS  {$DomainToJoin  = "corp.lakeseminoleseniorliving.com"}
    FPF  {$DomainToJoin  = "corp.freedomplazafl.com"}
    ROS  {$DomainToJoin  = "corp.regencyoaksseniorliving.com"}
    default     {$DomainToJoin = "NOTFOUND"}
                       }

# 3.  Specify the OU where to put the computer account in the domain.  Use the OU's distinguished name.
switch ($sitecode){
    FSF  {$orgunit = "Site1"}
    LSS  {$orgunit = "site2"}
    FPF  {$orgunit = "site3"}
    default     {$orgunit = "NOTFOUND"}
                       }

#testing section to verify variable data
write-host $sitegateway
write-host $NewHostName

# organizational unit based on active directory and your company
# The add-computer command can not be inside of a variable
# copy and paste as needed based on information above.
 if ($sitecode -eq "site1") {
        #OU path in acitve directory to computer location
    $OUnit ="OU=Workstations,OU=Computers,DC=domain,DC=com" 
    $user = "domain\admin"
    $pass = "password" | ConvertTo-SecureString -AsPlainText -Force 
    $cred = New-Object System.Management.Automation.PsCredential($user,$pass)
    # Join the computer to the domain, rename it, and restart it.
    Add-Computer -DomainName $DomainToJoin -Credential $cred -OUPath $OUnit -NewName $NewHostName -restart -force

    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
 }
  if ($sitecode -eq "site2") {
        #OU path in acitve directory to computer location
    $OUnit ="OU=Workstations,OU=Computers,DC=domain,DC=com" 
    $user = "domain\admin"
    $pass = "password" | ConvertTo-SecureString -AsPlainText -Force 
    $cred = New-Object System.Management.Automation.PsCredential($user,$pass)
    # Join the computer to the domain, rename it, and restart it.
    Add-Computer -DomainName $DomainToJoin -Credential $cred -OUPath $OUnit -NewName $NewHostName -restart -force

    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
 }