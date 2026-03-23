<#
.SYNOPSIS
Installs or updates Scratch database to the latest version
 
.DESCRIPTION
This function will create a scratchdb database if it does not already exist, and install the latest code. 

This depends on having the full, latest version of the full repo https://github.com/amtwo/scratch-database

All dependent .sql files are itempotent:
* Table.sql scripts are written to create if not exists. Changes are maintained similarly as conditional ALTERs.
* code.sql scripts are written using CREATE OR ALTER.

.PARAMETER InstanceName
An array of instance names

.PARAMETER DatabaseName
By default, this will be installed in a database called "scratchdb". If you want to install my DBA database with
a different name, specify it here.

 
.EXAMPLE
Install-LatestScratchdb AM2Prod
 

.NOTES
AUTHOR: Andy Mallon
DATE: 20260322
COPYRIGHT: This code is licensed as part of Andy Mallon's Scratch Database. https://github.com/amtwo/scratch-database/blob/master/LICENSE
©2026 ● Andy Mallon ● am2.co
#>
 
[CmdletBinding()]
param (
    [Parameter(Position=0,mandatory=$true)]
        [string[]]$InstanceName,
    [Parameter(Position=1,mandatory=$false)]
        [string]$DatabaseName = 'scratchdb'
    )

#Get Time Zone info from the OS. We'll use this to populate a table later
$TimeZoneInfo = Get-TimeZone -ListAvailable | 
    Add-Member -MemberType AliasProperty -Name TimeZoneId -Value Id -PassThru | Select-Object TimeZoneId, DisplayName, StandardName, DaylightName, SupportsDaylightSavingTime

# Process servers in a loop. I could do this parallel, but doing it this way is fast enough for me.
foreach($instance in $InstanceName) {
    Write-Verbose "**************************************************************"
    Write-Verbose "                           $instance"
    Write-Verbose "**************************************************************"
    #Create the database - SQL Script contains logic to be conditional & not clobber existing database
    Write-Verbose "`n        ***Creating Database if necessary `n"
    try{
        Invoke-Sqlcmd -ServerInstance $instance -Database master -InputFile .\create-database.sql -Variable "DbName=$($DatabaseName)"
    }
    catch{
        Write-Error -Message "Failed creating scratchdb Database" -ErrorAction Stop
    }

    #Create tables first
    Write-Verbose "`n        ***Creating/Updating Tables `n"
    $fileList = Get-ChildItem -Path .\tables -Recurse
    Foreach ($file in $fileList){
        Write-Verbose $file.FullName
        Invoke-Sqlcmd -ServerInstance $instance -Database $DatabaseName -InputFile $file.FullName -QueryTimeout 300
    }
    #Then Procedures
    Write-Verbose "`n        ***Creating/Updating Stored Procedures `n"
    $fileList = Get-ChildItem -Path .\stored-procedures -Recurse -Filter *.sql
    Foreach ($file in $fileList){
        Write-Verbose $file.FullName
        Invoke-Sqlcmd -ServerInstance $instance -Database $DatabaseName -InputFile $file.FullName
    }
    #Then Triggers
    Write-Verbose "`n        ***Creating/Updating Triggers `n"
    $fileList = Get-ChildItem -Path .\triggers -Recurse -Filter *.sql
    Foreach ($file in $fileList){
        Write-Verbose $file.FullName
        Invoke-Sqlcmd -ServerInstance $instance -Database $DatabaseName -InputFile $file.FullName
    }
    #Finally, data
    Write-Verbose "`n        ***Creating/Updating core data `n"
    $fileList = Get-ChildItem -Path .\data -Recurse -Filter *.sql
    Foreach ($file in $fileList){
        Write-Verbose $file.FullName
        Invoke-Sqlcmd -ServerInstance $instance -Database $DatabaseName -InputFile $file.FullName
    }
#That's it!
}
