Deploy Azure SQL database DR environment (PaaS) using PowerShell
================================================================

            

**Use PowerShell to create cloud DR environment using **Azure SQL Databases (PaaS)** and send Email Report with the connection string details**


 


**Description:**


Use PowerShell to deploy cloud service with Azure SQL Database (PaaS) with good resilience to outages (GEO Replications, Failover Groups)


 


**PowerShell:**


  *  Connect to Azure Account, 
  *  Use existing or create new Resource Group,

  *  Create primary Azure Logical SQL Server,

  *  Set an admin login and password for your server,

  *  Set Firewall Settings (IP address range),

  *  Create Azure SQL Database, 
  *  Create a new login for the Azure SQL Server,

  *  Create a new DB user for the created login,

  *  Create failover Azure Logical SQL Server, including admin login, password and firewall rules (Optional),

  *  Create Failover Group Name (Optional), 
  *  Add Database to the existing Failover Group (Optional),

  *  Create a new login for the Failover Azure SQL Server with matching SID (Optional),

  *  Send Email notification with connection string parameters.






![Image](https://github.com/azureautomation/deploy-azure-sql-database-dr-environment-(paas)-using-powershell/raw/master/ha.png)


 


 


**Script usage example: **


*Note.*
*You can repeat the script multiple times. If the resource you are creating already exist script will just skip that part with a message. *



*
*

 


**Email Report Sample**


![Image](https://github.com/azureautomation/deploy-azure-sql-database-dr-environment-(paas)-using-powershell/raw/master/email.png)

*Note.*
You should use read/write listener endpoint within the connection string*. ** *

 


 


**Some code snippets:**

** **




 





        
    
TechNet gallery is retiring! This script was migrated from TechNet script center to GitHub by Microsoft Azure Automation product group. All the Script Center fields like Rating, RatingCount and DownloadCount have been carried over to Github as-is for the migrated scripts only. Note : The Script Center fields will not be applicable for the new repositories created in Github & hence those fields will not show up for new Github repositories.
