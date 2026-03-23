# scratch-database
Every once in a while, you want to save a chunk of data somewhere "just in case" and you tell yourself you'll clean it up later. But then later never comes.  Save it to your `scratchdb` and automate the cleanup.

Why "`scratchdb`"? I modeled the name after the built-in `tempdb`.  

Retention is set to 90 days by the `DF_ObjectExpiration_KeepUntil` default constraint on `dbo.ObjectExpiration`. If you want to customize the retention, you can alter the default constraint or just modify expiration dates after they are inserted into the table. YOLO

Some of this code was never intended to be used by anyone else--it's primarily here for myself, but if you want to use it, make sure you know exactly what it's doing before using any of this code. 
Some of this code (including the installer!) assumes that the you know better than to save anything important to your scratchdb. 

### To install
By default, the installer will create a database named `scratchdb` (if it doesn't already exist), and install all objects in that `scratchdb` database. You can deploy to a database named something other than `scratchdb` by using the `-DatabaseName` parameter on the install script. This install script assumes that you have permission to create the database, or that it already exists. 

* Clone this repo.
* Open a PowerShell prompt & navigate (ie `Set-Location`) to the `scratch-database` folder you just cloned.
* From the scratch-database folder, run `Install-LatestScratchdb.ps1 -InstanceName "MyInstance"`
  * By default, the installer will use `scratchdb` as the database name. To use a different database name, specify that using the `-DatabaseName` parameter.
    * EX) `Install-LatestScratchdb.ps1 -InstanceName "MyInstance" -DatabaseName "💩db"`
  * The `-InstanceName` parameter will accept an array of server names, if you want to deploy to many servers.
