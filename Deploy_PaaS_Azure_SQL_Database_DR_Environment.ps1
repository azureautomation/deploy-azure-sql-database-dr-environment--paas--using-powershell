#Deploy_PaaS_Azure_SQL_Database_DR_Environment
<# 
.SYNOPSIS
    Use PowerShell to create cloud DR environment using Azure SQL Databases (PaaS) and send Email Report with the connection string details.
.DESCRIPTION
    Use PowerShell to deploy cloud service with Azure SQL Database (PaaS) with good resilience to outages (GEO Replications, Failover Groups).
.NOTES
     Author   : Zoran Barac 
     Email    : zoran.barac.zof@gmail.com  
     Date     : 28 Feb 2019
#>

#########################################################################
# Connect to Azure Account and select Subscription
#########################################################################
# Connect-AzureRmAccount
# Get-AzureRmSubscription
# Select-AzureRmSubscription -SubscriptionId xxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxx
# Get-AzureRmContext
#########################################################################
#########################################################################

param (
# Azure SQL DB Setup Replication Options
[string]$singledatabase = "YES",
[string]$replication = "YES",

# Log File Path
[string]$LogPath = "C:\ScriptLogs",

# Set the resource group name and location 
[string]$resourcegroupname = "test-rg",
[string]$location = "East US",

# Set an admin login and password for your server
[string]$adminlogin = "test_admin",
[string]$password = "P@ssw0rd",

# Set server name - the logical server name has to be unique
[string]$servername = "test-primary-sql-server",
[string]$serverlocation = "East US",

# Set failover server name - the logical failover server name has to be unique
[string]$failoverservername = "test-secondary-sql-server",
[string]$failoverserverlocation = "West US",

# Set failover group name
[string]$failovergroupname='test-failover-group',

# The database name
[string]$databasename = "test_database",
[string]$databasepricingtier="S0",

# SQL login and database user
[string]$sqllogin = "test_user",
[string]$sqlloginpassword = "P@ssw0rd",
[string]$databaseuser = "test_user",
[string]$databaseuserrole="db_owner",

# The ip address range that you want to allow to access your server
[string]$firewallrulename="Office",
[string]$startip = "",
[string]$endip = ""
)
cls


#########################################################################
# Create Lof File name based on the timestamp
#########################################################################
$dt = get-date -format yyyyMMddHHmm 
$LogFileName = $LogPath +"\"+$servername+"_"+$dt +".txt"
Start-Transcript -path $LogFileName -Append
#########################################################################
#########################################################################


#########################################################################
# Create a resource group
#########################################################################
Write-Output ((Get-Date -Format g)+ " >>> RESOURCE GROUP CREATING PROCESS >>>")
# Check if resource group already exist
if (Get-AzureRmResourceGroup | Where ResourceGroupName -eq $resourcegroupname)
{
Write-Output ((Get-Date -Format g)+ " - Resource Group "+$resourcegroupname+" already exist")
}
else
{
Write-Output ((Get-Date -Format g)+ " - Creating "+$resourcegroupname+" Resource Group")
New-AzureRmResourceGroup -Name $resourcegroupname -Location $location
Write-Output ((Get-Date -Format g)+ " - Resource Group "+$resourcegroupname+" successfuly created")
}
Write-Output ("")
#########################################################################
#########################################################################


#########################################################################
# Create a Azure SQL Server, adding admin credentials and firewall rules
#########################################################################
if ($singledatabase -eq "YES")
{
Write-Output ((Get-Date -Format g)+ " >>> AZURE LOGICAL SQL SERVER CREATING AND FIREWALL RULES ADDING PROCESS >>>")
# Check if Primary Azure SQL Server already exist
if (Get-AzureRmSqlServer -ResourceGroupName $resourcegroupname | where ServerName -eq $servername)
{
Write-Output ((Get-Date -Format g)+ " - Azure Logical SQL Server "+$servername+" already exist")
}
else
{
Write-Output ((Get-Date -Format g)+ " - Creating "+$servername+" Azure Logical SQL Server")
# Create a server with admin credentials
New-AzureRmSqlServer -ResourceGroupName $resourcegroupname -ServerName $servername -Location $serverlocation -SqlAdministratorCredentials $(New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $adminlogin, $(ConvertTo-SecureString -String $password -AsPlainText -Force))
Write-Output ((Get-Date -Format g)+ " - Azure Logical SQL Server "+$servername+" successfuly created")
Write-Output ((Get-Date -Format g)+ " - Adding firewall rules for "+$servername+" Azure SQL Server")
# Create a server firewall rule that allows access from the specified IP range
New-AzureRmSqlServerFirewallRule -ResourceGroupName $resourcegroupname -ServerName $servername -FirewallRuleName $firewallrulename -StartIpAddress $startip -EndIpAddress $endip
Write-Output ((Get-Date -Format g)+ " - Firewall rules for "+$servername+" Azure SQL Server successfuly added")
}
}
Write-Output ("")
#########################################################################
#########################################################################


#########################################################################
# Create a login for the SQL Server (Primary Server)
#########################################################################
# Create a login
$ConnStrMaster = @{
    'Database' = 'master'
    'ServerInstance' = $servername+'.database.windows.net'
    'Username' = $adminlogin
    'Password' = $password
    'Query' = "IF NOT EXISTS (SELECT * FROM sys.sql_logins WHERE name = N'$sqllogin')
               CREATE LOGIN $sqllogin WITH PASSWORD=N'$sqlloginpassword'"
}
Invoke-Sqlcmd @ConnStrMaster
Write-Output ((Get-Date -Format g)+ " - Login "+$sqllogin+" for "+$servername+" Azure SQL Server is successfuly created")
Write-Output ("")
#########################################################################
#########################################################################


#########################################################################
# Create a blank database with an S0 performance level
#########################################################################
Write-Output ((Get-Date -Format g)+ " >>> AZURE SQL DATABASE CREATING PROCESS >>>")
if (Get-AzureRmSqlDatabase -ResourceGroupName $resourcegroupname -ServerName $servername | where DatabaseName -eq $databasename)
{
Write-Output ((Get-Date -Format g)+ " - Azure SQL Database "+$databasename+" already exist")
}
else
{
Write-Output ((Get-Date -Format g)+ " - Creating "+$databasename+" Azure SQL Database")
New-AzureRmSqlDatabase  -ResourceGroupName $resourcegroupname -ServerName $servername -DatabaseName $databasename -RequestedServiceObjectiveName $databasepricingtier
Write-Output ((Get-Date -Format g)+ " - Azure SQL Database "+$databasename+" successfuly created")
}
Write-Output ("")
#########################################################################
#########################################################################


#########################################################################
# Create DB user and map created login to DB user (Primary Server)
#########################################################################
$ConnStrDB = @{
    'Database' = $databasename 
    'ServerInstance' = $servername+'.database.windows.net'
    'Username' = $adminlogin
    'Password' = $password
    'Query' =  "IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = N'$databaseuser')
                CREATE USER $databaseuser
                FOR LOGIN $sqllogin
                GO
                EXEC sp_addrolemember N'$databaseuserrole', N'$databaseuser'
                GO"
}
Invoke-Sqlcmd @ConnStrDB
Write-Output ((Get-Date -Format g)+ " - Database user "+$databaseuser+" for "+$sqllogin+" sql login with "+$databaseuserrole+" role for "+$databasename +" Azure sql database is successfuly created")
Write-Output ("")
#########################################################################
#########################################################################



#########################################################################
# Create a Failover Azure SQL Server, adding admin credentials, firewall rules, creating Failover Group and adding Azure SQL DB to the group
#########################################################################
if ($replication -eq "YES")
{
Write-Output ((Get-Date -Format g)+ " >>> AZURE LOGICAL FAILOVER SQL SERVER CREATING AND FIREWALL RULES ADDING PROCESS >>>")
# Check if Failover Azure SQL Server already exist
if (Get-AzureRmSqlServer -ResourceGroupName $resourcegroupname | where ServerName -eq $failoverservername)
{
Write-Output ((Get-Date -Format g)+ " - Azure Logical SQL Server "+$failoverservername+" already exist")
}
else
{
Write-Output ((Get-Date -Format g)+ " - Azure Logical SQL Failover Server "+$failoverservername+" creating")
# Create a failover server with admin credentials
New-AzureRmSqlServer -ResourceGroupName $resourcegroupname -ServerName $failoverservername -Location $failoverserverlocation -SqlAdministratorCredentials $(New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $adminlogin, $(ConvertTo-SecureString -String $password -AsPlainText -Force))
Write-Output ((Get-Date -Format g)+ " - Azure Logical SQL Failover Server "+$failoverservername+" successfuly created")
Write-Output ((Get-Date -Format g)+ " - Adding firewall rules for "+$failoverservername+" Azure SQL Failover Server")
# Create a server firewall rule that allows access from the specified IP range
New-AzureRmSqlServerFirewallRule -ResourceGroupName $resourcegroupname -ServerName $failoverservername -FirewallRuleName $firewallrulename -StartIpAddress $startip -EndIpAddress $endip
Write-Output ((Get-Date -Format g)+ " - Firewall rules for "+$failoverservername+" Azure SQL Failover Server successfuly added")
}
Write-Output ("")
#########################################################################
#########################################################################


#########################################################################
# Create failover group on the primary Azure Logical SQL Server
#########################################################################
Write-Output ((Get-Date -Format g)+ " >>> FAILOVER GROUP ON THE PRIMARY AZURE LOGICAL SQL SERVER CREATING PROCESS >>>")
if (Get-AzureRMSqlDatabaseFailoverGroup -ResourceGroupName $resourcegroupname -ServerName $servername | where FailoverGroupName -eq $failovergroupname)
{
Write-Output ((Get-Date -Format g)+ " - Azure Failover Group "+$failovergroupname+" already exist")
}
else
{
Write-Output ((Get-Date -Format g)+ " - Azure SQL Failover Group "+$failovergroupname+" creating")
New-AzureRMSqlDatabaseFailoverGroup –ResourceGroupName $resourcegroupname -ServerName $servername -PartnerServerName $failoverservername –FailoverGroupName $failovergroupname –FailoverPolicy Automatic -GracePeriodWithDataLossHours 1 
Write-Output ((Get-Date -Format g)+ " - Azure SQL Failover Group "+$failovergroupname+" successfuly created")
}

Write-Output ("")
#########################################################################
#########################################################################



#########################################################################
# Adding created database to existing Failover Group
#########################################################################
Write-Output ((Get-Date -Format g)+ " >>> ADDING THE DATABASE TO THE FAILOVER GROUP PROCESS >>>")
if (Get-AzureRmSqlDatabase -ResourceGroupName $resourcegroupname -ServerName $failoverservername | where DatabaseName -eq $databasename)
{
Write-Output ((Get-Date -Format g)+ " - Azure SQL Database "+$databasename+" already exist within "+$failovergroupname+" Failover Group")
}
else
{
Write-Output ((Get-Date -Format g)+ " - Adding the Azure SQL Database "+$databasename+" to the newly created "+$failovergroupname+" Failover Group") 
Get-AzureRmSqlDatabase -ResourceGroupName $resourcegroupname -ServerName $servername -DatabaseName $databasename | Add-AzureRmSqlDatabaseToFailoverGroup -ResourceGroupName $resourcegroupname -ServerName $servername -FailoverGroupName $failovergroupname 
Write-Output ((Get-Date -Format g)+ " - Azure SQL Database "+$databasename+" successfuly added to the "+$failovergroupname+" Failover Group") 
Write-Output ("")
}

#########################################################################
# Find SID for created user (match SID)
#########################################################################
$SIDMatch = @{
    'Database' = $databasename 
    'ServerInstance' = $servername+'.database.windows.net'
    'Username' = $adminlogin
    'Password' = $password
    'Query' =  "SELECT sid FROM sys.database_principals WHERE name = N'$databaseuser'"
                
}
$results=Invoke-Sqlcmd @SIDMatch
$sidBytes = $results.sid
$sidText = "0x"+ (($sidBytes|ForEach-Object ToString X2) -join '') 
$resultsNew=$sidText.Substring(0, 66)
#########################################################################
#########################################################################

#########################################################################
# Create a login for the SQL Server (Failover Server)
#########################################################################
$ConnStrMasterFailover = @{
    'Database' = 'master'
    'ServerInstance' = $failoverservername+'.database.windows.net'
    'Username' = $adminlogin
    'Password' = $password
    'Query' = "IF NOT EXISTS (SELECT * FROM sys.sql_logins WHERE name = N'$sqllogin')
               CREATE LOGIN $sqllogin WITH PASSWORD=N'$sqlloginpassword', SID =$resultsNew"
}
Invoke-Sqlcmd @ConnStrMasterFailover
Write-Output ((Get-Date -Format g)+ " - Login "+$sqllogin+" with matched SID for "+$failoverservername+" Azure SQL Server is successfuly created")
#########################################################################
#########################################################################


}
Write-Output ("")
#########################################################################
#########################################################################



#########################################################################
# Send LogFile in the email attachment
#########################################################################
$EmailFrom = "from@gmail.com"
$EmailTo = "to@gmail.com"
$EmailSubject = "Azure DB Deployment for '"+$databasename+"' Database"
$SMTPServer = ""
$SMTPAuthUsername = ""
$SMTPAuthPassword = ""
$mailmessage = New-Object system.net.mail.mailmessage 
$mailmessage.from = ($emailfrom) 
$mailmessage.To.add($emailto)
$mailmessage.Subject = $emailsubject
$mailmessage.Body = "Primary Logical SQL Server: "+$servername+".database.windows.net"+ "`n" + "`n"+"Failover Logical SQL Server: "+$failoverservername+".database.windows.net"+ "`n" + "`n"+"Read/write listener endpoint: "+$failovergroupname+".database.windows.net"+ "`n" + "`n"+ "Azure Database Name: "+$databasename+ "`n" + "`n"+ "Azure Database User: "+$databaseuser+ "`n" + "`n"+ "Azure Database Role: "+$databaseuserrole
#$attachment = New-Object System.Net.Mail.Attachment($emailattachment, 'text/plain')
#$mailmessage.Attachments.Add($attachment)
$SMTPClient = New-Object Net.Mail.SmtpClient($SmtpServer, 25)  
$SMTPClient.Credentials = New-Object System.Net.NetworkCredential("$SMTPAuthUsername", "$SMTPAuthPassword") 
$SMTPClient.Send($mailmessage)
#########################################################################
# End Sending Notification Email
#########################################################################


Stop-Transcript