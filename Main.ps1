<#
.DESCRIPTION
Automated test for GH REST API Basic calls & responses

.AUTHOR
mzs

VERSION
N/A


.LINK
https://jira.vizrt.com/browse/QAT-3940
https://jira.vizrt.com/browse/QAT-3395

#>


# $DataDirectory = "C:\QAT-3395\TestData\QAT-3395"
# Install-Vgh -Version '3.0.1' -Is64Bit -DataDirectory $DataDirectory -Start
# Install-VghREST -Version '2.0.1' -Is64Bit 



# Creating credential object for the predefined user Admin

$username = "Admin"
$password = ConvertTo-SecureString -string "VizDb" -AsPlainText -Force
$Credential = New-Object –TypeName "System.Management.Automation.PSCredential" –ArgumentList $username, $password

# Removing all write permissions from user "Guest" to test the response of making a call with an unauthorized user 

 # Parsing the payload of predefined user "Guest" and assigning it to variable $Userpayload
 
 [xml]$GuestUserPayLoad = Invoke-RestMethod -Method Get -Credential $Credential -uri http://127.0.0.1:19398/metadata/user/9999
 
 # Removing write rights from "Guest" user

($GuestUserPayLoad.payload.field.field | Where-Object {$_.name -eq "user-rights"}).value = "false"
($GuestUserPayLoad.payload.field.field | Where-Object {$_.name -eq "group-rights"}).value = "false"
($GuestUserPayLoad.payload.field.field | Where-Object {$_.name -eq "world-rights"}).value = "false"

Invoke-WebRequest -Method Put -Credential $Credential -body $GuestUserPayLoad -ContentType application/vnd.vizrt.payload+xml -uri http://127.0.0.1:19398/metadata/user/9999

# Assigning the "Guest" user credentials to variable "$NotAuthorizedCredential"

$NotAuthorizedUsername = "Guest"
$NotAuthorizedCredential = New-Object System.Management.Automation.PSCredential ($NotAuthorizedUsername, (new-object System.Security.SecureString))

# Creating a folder for the results text file

New-Item C:\GH_Test_Results\QAT-3395 -ItemType directory -force
$Date = Get-Date -Format o | foreach {$_ -replace ":", "."}
$RESTBasicResources = "C:\GH_Test_Results\QAT-3395\$Date.txt"

# Parsing the data folder UUID

$GetFolders = Invoke-RestMethod -Method Get -Credential $Credential -uri http://127.0.0.1:19398/folders
[string]$DataFolderUUID = $GetFolders.id.remove(0,9)
[string]$WrongDataFolderUUID = $DataFolderUUID.Remove(2,1)

# Parsing the images folder UUID

$GetImagesFolder = Invoke-RestMethod -Method Get -Credential $Credential -uri http://127.0.0.1:19398/search?searchTerms=ImagesFolder`&category=project -ErrorVariable MyError 
[string]$ImageFolderUUID = $GetImagesFolder.id.remove(0,9)

$GetImageFile = Invoke-RestMethod -Method Get -Credential $Credential -uri http://127.0.0.1:19398/files/$ImageFolderUUID
[string]$imageUUID = $GetImageFile.id.remove(0,9)

Function StopGH 
    {
    [XML]$StopGHPayload = "<payload><field name=`"status`"><value>5</value><field name=`"vizdb`"><value>5</value></field><field name=`"vizdbnamingservice`"><value>5</value></field></field></payload>"
    Invoke-RestMethod -Method Put -Credential $Credential -ContentType application/vnd.vizrt.payload+xml -body $StopGHPayload -Uri http://127.0.0.1:19399/status/current.payload
    }

Function StartGH
    {
    $GHID = (invoke-restmethod -Method get -uri http://mazen:19399/status.feed).id[0]
    [XML]$StartGHPayload = "<payload xmlns='http://www.vizrt.com/types' model='http://mazen:19399/status/templates/54free.model'><field name='backup'><field name='automatic-backup'><field name='trigger-start-after-backup'><value>false</value></field></field><field name='external-backup'><field name='batch-file'/></field><field name='internal-backup'><field name='backup-directory'/><field name='cleanup-restore-points'><value>false</value></field><field name='max-restore-points'><value>10</value></field></field><field name='mode'><value>0</value></field></field><field name='graphic-hub'><field name='client-timeout'><value>2</value></field><field name='data-directory'><value>D:\DD1\</value></field><field name='journal-level'><value>3</value></field><field name='log-server-state'><value>true</value></field><field name='network-adapter'/><field name='process-priority'><value>2</value></field><field name='safe-mode'><value>false</value></field><field name='search-instances'><value>1</value></field><field name='server-name'><value>VizDbServer</value></field><field name='server-port'><value>19397</value></field></field><field name='mode'><value>2</value></field><field name='naming-service'><field name='host-name'><value>MAZEN</value></field><field name='port'><value>19396</value></field></field><field name='status'><field name='vizdb'><value>2</value></field><field name='vizdbnamingservice'><value>2</value></field></field><field name='vdf-version'><value>1</value></field></payload>"
    Invoke-RestMethod -Method Put -Credential $Credential -ContentType application/vnd.vizrt.payload+xml -body $StartGHPayload -Uri http://127.0.0.1:19399/status/$GHID.payload
    }


Function Response_200 
    {
    Param ($MyError, $WebRequestResults) 
        if ($Myerror.Count -eq 1)
           {
           "`t Responce Failed, response message: " + $MyError.message.Split(“`n”)[0] + " Instead of 200 OK" | out-file -FilePath $RESTBasicResources -Append
           }
        elseif ($WebRequestResults.StatusCode -eq "200") 
           {
           "`t Responce Passed, response message: " + $WebRequestResults.StatusCode + " " + $WebRequestResults.StatusDescription | out-file -FilePath $RESTBasicResources -Append
           }
        else 
           {
           "`t Responce Failed, response message: " + $WebRequestResults.StatusCode + " " + $WebRequestResults.StatusDescription + " Instead of 200 OK" | out-file -FilePath $RESTBasicResources -Append
           }
    }

Function Response_201 
    {
    Param ($MyError, $WebRequestResults) 
        if ($Myerror.Count -eq 1)
          {
            "`t Responce Failed, response message: " + $MyError.message.Split(“`n”)[0] + " Instead of 201 Created"| out-file -FilePath $RESTBasicResources -Append
          }
        elseif ($WebRequestResults.StatusCode -eq "201") 
          {
            "`t Responce Passed, response message: " + $WebRequestResults.StatusCode + " " + $WebRequestResults.StatusDescription | out-file -FilePath $RESTBasicResources -Append
          }
        else 
          {
            "`t Responce Failed, response message: " + $WebRequestResults.StatusCode + " " + $WebRequestResults.StatusDescription + " Instead of 201 Created" | out-file -FilePath $RESTBasicResources -Append
          }
       
    }


Function Response_502 
    {
    Param ($MyError, $WebRequestResults) 
        if ($MyError.message -like '*502*')
           {
           "`t Responce Passed, response message: " + $MyError.message.Split(“`n”)[0] | out-file -FilePath $RESTBasicResources -Append
           }
        elseif ($WebRequestResults.StatusCode -eq "200") 
           {
           "`t Responce Failed, response message: " + $WebRequestResults.StatusCode + " " + $WebRequestResults.StatusDescription + " Instead of 502 Bad gateway" | out-file -FilePath $RESTBasicResources -Append
           }
        else 
           {
           "`t Responce Failed, response message: " + $MyError.message.Split(“`n”)[0] + " Instead of 502 Bad gateway" | out-file -FilePath $RESTBasicResources -Append
           }
       
    }

Function Response_401_403 
    {
    Param ($MyError, $WebRequestResults) 
         if ($Myerror.message -like '*403*' -or $Myerror.message -like '*401*')
           {
           "`t Responce Passed, response message: " + $MyError.message.Split(“`n”)[0] | out-file -FilePath $RESTBasicResources -Append
           }
         elseif ($WebRequestResults.StatusCode -eq "201" -or $WebRequestResults.StatusCode -eq "200") 
           {
           "`t Responce Failed, response message: " + $WebRequestResults.StatusCode + " " + $WebRequestResults.StatusDescription + " Instead of 401 unauthorized or 403 Forbidden" | out-file -FilePath $RESTBasicResources -Append
           }
         else 
           {
           "`t Responce Failed, response message: " + $MyError.message.Split(“`n”)[0] + " " + $WebRequestResults.StatusDescription + " Instead of 401 unauthorized or 403 Forbidden" | out-file -FilePath $RESTBasicResources -Append
           }   
       
    }

Function Response_404 
    {
    Param ($MyError, $WebRequestResults) 
         if ($Myerror.message -like '*404*')
           {
           "`t Responce Passed, response message: " + $MyError.message.Split(“`n”)[0] | out-file -FilePath $RESTBasicResources -Append
           }
         elseif ($WebRequestResults.StatusCode -eq "201" -or $WebRequestResults.StatusCode -eq "200") 
           {
           "`t Responce Failed, response message: " + $WebRequestResults.StatusCode + " " + $WebRequestResults.StatusDescription + " Instead of 404 Not Found" | out-file -FilePath $RESTBasicResources -Append
           }
         else 
           {
           "`t Responce Failed, response message: " + $MyError.message.Split(“`n”)[0] + " " + $WebRequestResults.StatusDescription + " Instead of 404 Not Found" | out-file -FilePath $RESTBasicResources -Append
           }   
       
    }

Function Response_204 
    {
    Param ($MyError, $WebRequestResults)

     if ($Myerror.Count -eq 1)
        {
        "`t Responce Failed, response message: " + $MyError.message.Split(“`n”)[0] + " Instead of 200 OK or 204 No Content" | out-file -FilePath $RESTBasicResources -Append
        }
     elseif ($WebRequestResults.StatusCode -eq "204") 
        {
        "`t Responce Passed, response message: " + $WebRequestResults.StatusCode + " " + $WebRequestResults.StatusDescription | out-file -FilePath $RESTBasicResources -Append
        }
     else 
        {
        "`t Responce Failed, response message: " + $WebRequestResults.StatusCode + " " + $WebRequestResults.StatusDescription + " Instead of 200 OK or 204 No Content" | out-file -FilePath $RESTBasicResources -Append
        }
    }

"`t `t `t `t `t `t `t `t REST API Viz Graphic Hub Basic Resources Callas & responses Test Results" | Out-file $RESTBasicResources -Append
"`n `n `n" | Out-file $RESTBasicResources -Append

# Folders calls and responses 

">>Folders Callas & responses Test Results :" | Out-file $RESTBasicResources -Append
"`n" | Out-file $RESTBasicResources -Append
"- First Get responses test " | Out-file $RESTBasicResources -Append

#Response 1

$WebRequestResults = Invoke-webrequest -Method Get -Credential $Credential -uri http://127.0.0.1:19398/folders -ErrorVariable MyError 
Response_200 -MyError $MyError -WebRequestResults $WebRequestResults
clear-Variable -name WebRequestResults -force
 
#Response 3

$WebRequestResults = Invoke-webrequest -Method Get -uri http://127.0.0.1:19398/folders -ErrorVariable MyError
Response_401_403 -MyError $MyError -WebRequestResults $WebRequestResults
clear-Variable -name WebRequestResults -force

"`n" | Out-file $RESTBasicResources -Append
"- Second Get responses test " | Out-file $RESTBasicResources -Append

#Response 1

$WebRequestResults = Invoke-webrequest -Method Get -Credential $Credential -uri http://127.0.0.1:19398/metadata/folder/$DataFolderUUID -ErrorVariable MyError
Response_200 -MyError $MyError -WebRequestResults $WebRequestResults
clear-Variable -name WebRequestResults -force

#Response 3

$WebRequestResults = Invoke-webrequest -Method Get -uri http://127.0.0.1:19398/metadata/folder/$DataFolderUUID -ErrorVariable MyError
Response_401_403 -MyError $MyError -WebRequestResults $WebRequestResults
clear-Variable -name WebRequestResults -force

"`n" | Out-file $RESTBasicResources -Append
"- Post responses test " | Out-file $RESTBasicResources -Append

#Response 1

$GetMetadataFoldersPayload = Invoke-RestMethod -Method Get -Credential $Credential -uri http://127.0.0.1:19398/metadata/folder/$DataFolderUUID
($GetMetadataFoldersPayload.payload.field | Where-Object {$_.name -eq "id"}).value = ""
($GetMetadataFoldersPayload.payload.field | Where-Object {$_.name -eq "name"}).value = "Test"

$WebRequestResults = Invoke-webrequest -Method Post -Credential $Credential -Body $GetMetadataFoldersPayload -ContentType application/vnd.vizrt.payload+xml -uri http://127.0.0.1:19398/folder/$DataFolderUUID -ErrorVariable MyError 
If ((Invoke-RestMethod -Method Get -Credential $Credential -uri http://127.0.0.1:19398/search?searchTerms=Test).title -eq "Test")
    {Response_201 -MyError $MyError -WebRequestResults $WebRequestResults} 
Else
    {
    "`t Post Responce 1 Failed : No Folder was created" | out-file -FilePath $RESTBasicResources -Append
    }
clear-Variable -name WebRequestResults -force

#Response 3

($GetMetadataFoldersPayload.payload.field | Where-Object {$_.name -eq "name"}).value = "Test1"
$WebRequestResults = Invoke-webrequest -Method Post -Credential $NotAuthorizedCredential -Body $GetMetadataFoldersPayload -ContentType application/vnd.vizrt.payload+xml -uri http://127.0.0.1:19398/folder/$DataFolderUUID -ErrorVariable MyError 
 If ((Invoke-RestMethod -Method Get -Credential $Credential -uri http://127.0.0.1:19398/search?searchTerms=Test1).title -ne "Test1")
     {Response_401_403 -MyError $MyError -WebRequestResults $WebRequestResults}
else
     {
     "`t Post Responce 3 Failed : A Folder was created by an unauthorized user" | out-file -FilePath $RESTBasicResources -Append
     }
clear-Variable -name WebRequestResults -force

#Response 4

($GetMetadataFoldersPayload.payload.field | Where-Object {$_.name -eq "name"}).value = "Test2"
$WebRequestResults = Invoke-webrequest -Method Post -Credential $Credential  -Body $GetMetadataFoldersPayload -ContentType application/vnd.vizrt.payload+xml -uri http://127.0.0.1:19398/folder/$WrongDataFolderUUID -ErrorVariable MyError 
If ((Invoke-RestMethod -Method Get -Credential $Credential -uri http://127.0.0.1:19398/search?searchTerms=Test2).title -ne "Test2")
    {Response_404 -MyError $MyError -WebRequestResults $WebRequestResults}
else
    {
    "`t Post Responce 4 Failed : A Folder was created although the uuid of the parent folder is wrong" | out-file -FilePath $RESTBasicResources -Append
    }
clear-Variable -name WebRequestResults -force

#Put folder responses test

"`n" | Out-file $RESTBasicResources -Append
"- Put responses test " | Out-file $RESTBasicResources -Append

#Response 1

[xml]$GetMetadataFoldersPayload = Invoke-RestMethod -Method Get -Credential $Credential -uri http://127.0.0.1:19398/metadata/folder/$((Invoke-RestMethod -Method Get -Credential $Credential -uri http://127.0.0.1:19398/search?searchTerms=Test).id.remove(0,9)) -ErrorVariable MyError 
($GetMetadataFoldersPayload.payload.field | Where-Object {$_.name -eq "name"}).value = "TestRenamed"
$WebRequestResults = Invoke-webrequest -Method Put -Credential $Credential -body  $GetMetadataFoldersPayload -ContentType application/vnd.vizrt.payload+xml -uri http://127.0.0.1:19398/folder/$((Invoke-RestMethod -Method Get -Credential $Credential -uri http://127.0.0.1:19398/search?searchTerms=Test).id.remove(0,9)) -ErrorVariable MyError 
If ((Invoke-RestMethod -Method Get -Credential $Credential -uri http://127.0.0.1:19398/search?searchTerms=TestRenamed).title -eq "TestRenamed")
    {Response_200 -MyError $MyError -WebRequestResults $WebRequestResults}
else
    {
    "`t Put Responce 1 Failed : The Folder was not modified" | out-file -FilePath $RESTBasicResources -Append
    }
clear-Variable -name WebRequestResults -force

Start-Sleep 5
#Response 3

($GetMetadataFoldersPayload.payload.field | Where-Object {$_.name -eq "name"}).value = "TestRenamed1"
$WebRequestResults = Invoke-webrequest -Method Put -Credential $NotAuthorizedCredential -body  $GetMetadataFoldersPayload -ContentType application/vnd.vizrt.payload+xml -uri http://127.0.0.1:19398/folder/$((Invoke-RestMethod -Method Get -Credential $Credential -uri http://127.0.0.1:19398/search?searchTerms=TestRenamed).id.remove(0,9)) -ErrorVariable MyError 
 If ((Invoke-RestMethod -Method Get -Credential $Credential -uri http://127.0.0.1:19398/search?searchTerms=TestRenamed1).title -ne "TestRenamed1")
     {Response_401_403}
else
     {
     "`t Put Responce 3 Failed : A Folder was modified by an unauthorized user" | out-file -FilePath $RESTBasicResources -Append
     }
clear-Variable -name WebRequestResults -force

#Response 4

($GetMetadataFoldersPayload.payload.field | Where-Object {$_.name -eq "name"}).value = "TestRenamed2"
$WebRequestResults = Invoke-webrequest -Method Put -Credential $Credential -body  $GetMetadataFoldersPayload -ContentType application/vnd.vizrt.payload+xml -uri http://127.0.0.1:19398/folder/$((Invoke-RestMethod -Method Get -Credential $Credential -uri http://127.0.0.1:19398/search?searchTerms=TestRenamed).id.remove(0,9).Remove(2,1)) -ErrorVariable MyError 
If ((Invoke-RestMethod -Method Get -Credential $Credential -uri http://127.0.0.1:19398/search?searchTerms=TestRenamed2).title -ne "TestRenamed2")
    {Response_404 -MyError $MyError -WebRequestResults $WebRequestResults}
else
    {
    "`t PUT Responce 4 Failed : A Folder was modified although the uuid of targeted folder is wrong" | out-file -FilePath $RESTBasicResources -Append
    }
clear-Variable -name WebRequestResults -force



"`t Testing ticket VIZGH-4264" | out-file -FilePath $RESTBasicResources -Append

# Before the fix, when requesting a folder delete using a user with no write permissions the response is 200 OK and the folder is not deleted 

# Creating the user: 

# Parsing the payload of predefined user "Admin" 
 
 [xml]$AdminUserPayLoad = Invoke-RestMethod -Method Get -Credential $Credential -uri http://127.0.0.1:19398/metadata/user/1
 
 # Removing write permissions from "Admin" user payload

($AdminUserPayLoad.payload.field | Where-Object {$_.name -eq "id"}).value = "2"
($AdminUserPayLoad.payload.field | Where-Object {$_.name -eq "name"}).value = "Test"
($AdminUserPayLoad.payload.field | Where-Object {$_.name -eq "full-name"}).value = "Test"
($AdminUserPayLoad.payload.field.field | Where-Object {$_.name -eq "user-rights"}).value = "false"
($AdminUserPayLoad.payload.field.field | Where-Object {$_.name -eq "group-rights"}).value = "false"
($AdminUserPayLoad.payload.field.field | Where-Object {$_.name -eq "world-rights"}).value = "false"

# Creating Admin user with no write permission

Invoke-RestMethod -Method Post -Credential $Credential -ContentType application/vnd.vizrt.payload+xml -body $AdminUserPayLoad -uri http://127.0.0.1:19398/users -ErrorVariable MyError

# Creating credential object with user "Test"

$Testuser = "Test"
$TestCredential = New-Object System.Management.Automation.PSCredential ($Testuser, (new-object System.Security.SecureString))


# Creating a test folder and test deleting it with the newly created user 

($GetMetadataFoldersPayload.payload.field | Where-Object {$_.name -eq "name"}).value = "VIZGH-4264"
($GetMetadataFoldersPayload.payload.field | Where-Object {$_.name -eq "id"}).value = ""
$WebRequestResults = Invoke-webrequest -Method Post -Credential $Credential -Body $GetMetadataFoldersPayload -ContentType application/vnd.vizrt.payload+xml -uri http://127.0.0.1:19398/folder/$DataFolderUUID

$WebRequestResults = Invoke-webrequest -Method Delete -Credential $TestCredential -uri http://127.0.0.1:19398/folder/$((Invoke-RestMethod -Method Get -Credential $Credential -uri http://127.0.0.1:19398/search?searchTerms=VIZGH-4264).id.remove(0,9)) -ErrorVariable MyError 
Response_401_403 -MyError $MyError -WebRequestResults $WebRequestResults
clear-Variable -name WebRequestResults -force

# Delete the created folder 

Invoke-webrequest -Method Delete -Credential $Credential -uri http://127.0.0.1:19398/folder/$((Invoke-RestMethod -Method Get -Credential $Credential -uri http://127.0.0.1:19398/search?searchTerms=VIZGH-4264).id.remove(0,9))

# Delete the created user 

Invoke-webrequest -Method delete -Credential $Credential -uri http://127.0.0.1:19398/metadata/user/2

#Delete folder responses test

"- Delete responses test " | Out-file $RESTBasicResources -Append

#Response 1

$WebRequestResults = Invoke-webrequest -Method Delete -Credential $Credential -uri http://127.0.0.1:19398/folder/$((Invoke-RestMethod -Method Get -Credential $Credential -uri http://127.0.0.1:19398/search?searchTerms=TestRenamed).id.remove(0,9)) -ErrorVariable MyError 
If ((Invoke-RestMethod -Method Get -Credential $Credential -uri http://127.0.0.1:19398/search?searchTerms=TestRenamed).title -ne "TestRenamed")
    {Response_204 -MyError $MyError -WebRequestResults $WebRequestResults}
else
    {
    "`t Delete Responce Failed : The folder was not deleted" | out-file -FilePath $RESTBasicResources -Append
    }
clear-Variable -name WebRequestResults -force

#Response 3

$WebRequestResults = Invoke-webrequest -Method Delete -Credential $NotAuthorizedCredential -uri http://127.0.0.1:19398/folder/$((Invoke-RestMethod -Method Get -Credential $Credential -uri http://127.0.0.1:19398/search?searchTerms=data).id.remove(0,9)) -ErrorVariable MyError 
If ((Invoke-RestMethod -Method Get -Credential $Credential -uri http://127.0.0.1:19398/search?searchTerms=data).title -eq "data")
    {Response_401_403 -MyError $MyError -WebRequestResults $WebRequestResults}
else
     {
     "`t Delete Responce Failed : A Folder was deleted by an unauthorized user" | out-file -FilePath $RESTBasicResources -Append
     }
clear-Variable -name WebRequestResults -force

"`t Testing ticket VIZGH-4265" | out-file -FilePath $RESTBasicResources -Append


    # Creating a test folder and test deleting it using a wrong UUID 

($GetMetadataFoldersPayload.payload.field | Where-Object {$_.name -eq "name"}).value = "VIZGH-4265"
$TestFolderpayload = Invoke-RestMethod -Method Post -Credential $Credential -Body $GetMetadataFoldersPayload -ContentType application/vnd.vizrt.payload+xml -uri http://127.0.0.1:19398/folder/$DataFolderUUID
[String]$TestFolderUUID = $TestFolderpayload.entry.id.remove(0,9)
[String]$WrongUUID = $TestFolderUUID.Remove(2,1)

    # Trying to delete the test folder with a wrong UUID 

$WebRequestResults = Invoke-webrequest -Method Delete -Credential $Credential -uri http://127.0.0.1:19398/folder/$WrongUUID -ErrorVariable MyError 
If ((Invoke-RestMethod -Method Get -Credential $Credential -uri http://127.0.0.1:19398/search?searchTerms=VIZGH-4265).title -eq "VIZGH-4265")
    {Response_404 -MyError $MyError -WebRequestResults $WebRequestResults}
else
     {
     "`t delete Responce Failed : A Folder was deleted although the uuid of targeted folder is wrong" | out-file -FilePath $RESTBasicResources -Append
     }

# deleting the test folder  

Invoke-webrequest -Method Delete -Credential $Credential -uri http://127.0.0.1:19398/folder/$TestFolderUUID

clear-Variable -name WebRequestResults -force

"`n `n `n" | Out-file $RESTBasicResources -Append


# Files calls and responses 

">>Files Callas & responses Test Results :" | Out-file $RESTBasicResources -Append

"`n" | Out-file $RESTBasicResources -Append

"- First Get responses test " | Out-file $RESTBasicResources -Append

# Response 1

$WebRequestResults = Invoke-webrequest -Method Get -Credential $Credential -uri http://127.0.0.1:19398/files/$ImageFolderUUID -ErrorVariable MyError 
Response_200 -MyError $MyError -WebRequestResults $WebRequestResults
clear-Variable -name WebRequestResults -force
 
# Response 2

$WebRequestResults = Invoke-webrequest -Method Get -uri http://127.0.0.1:19398/files/$ImageFolderUUID -ErrorVariable MyError
Response_401_403 -MyError $MyError -WebRequestResults $WebRequestResults
clear-Variable -name WebRequestResults -force


"`n" | Out-file $RESTBasicResources -Append
"- Second Get responses test " | Out-file $RESTBasicResources -Append

# Response 1

$WebRequestResults = Invoke-webrequest -Method Get -Credential $Credential -uri http://127.0.0.1:19398/file/$imageUUID/$ImageFolderUUID -ErrorVariable MyError 
Response_200 -MyError $MyError -WebRequestResults $WebRequestResults
clear-Variable -name WebRequestResults -force
 
# Response 2

$WebRequestResults = Invoke-webrequest -Method Get -uri http://127.0.0.1:19398/file/$imageUUID/$ImageFolderUUID -ErrorVariable MyError
Response_401_403 -MyError $MyError -WebRequestResults $WebRequestResults
clear-Variable -name WebRequestResults -force

"`t Testing ticket VIZGH-4266" | out-file -FilePath $RESTBasicResources -Append


$WrongImageFolderUUID = $imageFolderUUID.Remove(2,1)
$WebRequestResults = Invoke-webrequest -Method Get -Credential $Credential -uri http://127.0.0.1:19398/file/$imageUUID/$WrongImageFolderUUID -ErrorVariable MyError
Response_404 -MyError $MyError -WebRequestResults $WebRequestResults

clear-Variable -name WebRequestResults -force


"`n" | Out-file $RESTBasicResources -Append
"- Third Get responses test " | Out-file $RESTBasicResources -Append

# Response 1
$WebRequestResults = Invoke-webrequest -Method Get -Credential $Credential -uri http://127.0.0.1:19398/files/$ImageFolderUUID/?Term=IMAGE -ErrorVariable MyError 
Response_200 -MyError $MyError -WebRequestResults $WebRequestResults
clear-Variable -name WebRequestResults -force
 
# Response 2

$WebRequestResults = Invoke-webrequest -Method Get -uri http://127.0.0.1:19398/files/$ImageFolderUUID/?Term=IMAGE -ErrorVariable MyError
Response_401_403 -MyError $MyError -WebRequestResults $WebRequestResults
clear-Variable -name WebRequestResults -force

"`n" | Out-file $RESTBasicResources -Append
"- Forth Get responses test " | Out-file $RESTBasicResources -Append

# Response 1

$WebRequestResults = Invoke-webrequest -Method Get -Credential $Credential -uri http://127.0.0.1:19398/metadata/file/$imageUUID -ErrorVariable MyError 
Response_200 -MyError $MyError -WebRequestResults $WebRequestResults
clear-Variable -name WebRequestResults -force
 
# Response 2

$WebRequestResults = Invoke-webrequest -Method Get -uri http://127.0.0.1:19398/metadata/file/$imageUUID -ErrorVariable MyError
Response_401_403 -MyError $MyError -WebRequestResults $WebRequestResults
clear-Variable -name WebRequestResults -force

"`n" | Out-file $RESTBasicResources -Append
"- Put responses test " | Out-file $RESTBasicResources -Append

# Response 1

[xml]$GetMetadataimagePayload = Invoke-RestMethod -Method Get -Credential $Credential -uri http://127.0.0.1:19398/metadata/file/$imageUUID -ErrorVariable MyError 
($GetMetadataimagePayload.payload.field | Where-Object {$_.name -eq "name"}).value = "ImageRenamed"
$WebRequestResults = Invoke-webrequest -Method Put -Credential $Credential -body  $GetMetadataimagePayload -ContentType application/vnd.vizrt.payload+xml -uri http://127.0.0.1:19398/metadata/file/$imageUUID -ErrorVariable MyError 
If ((Invoke-RestMethod -Method Get -Credential $Credential -uri http://127.0.0.1:19398/search?searchTerms=ImageRenamed).title -eq "ImageRenamed")
    {Response_200 -MyError $MyError -WebRequestResults $WebRequestResults}
else
    {
    "`t Put Responce 1 Failed : The file was not modified" | out-file -FilePath $RESTBasicResources -Append
    }
clear-Variable -name WebRequestResults -force

Start-Sleep 5

# Response 3

[xml]$GetMetadataimagePayload = Invoke-RestMethod -Method Get -Credential $Credential -uri http://127.0.0.1:19398/metadata/file/$imageUUID -ErrorVariable MyError 
($GetMetadataimagePayload.payload.field | Where-Object {$_.name -eq "name"}).value = "ImageRenamed1"
$WebRequestResults = Invoke-webrequest -Method Put -Credential $NotAuthorizedCredential -body  $GetMetadataimagePayload -ContentType application/vnd.vizrt.payload+xml -uri http://127.0.0.1:19398/metadata/file/$imageUUID -ErrorVariable MyError 
If ((Invoke-RestMethod -Method Get -Credential $Credential -uri http://127.0.0.1:19398/search?searchTerms=ImageRenamed1).title -ne "ImageRenamed1")
    {Response_401_403 -MyError $MyError -WebRequestResults $WebRequestResults}
else
    {
    "`t Put Responce 1 Failed : The file was modified using an unauthorized user" | out-file -FilePath $RESTBasicResources -Append
    }
clear-Variable -name WebRequestResults -force

"`t Testing ticket VIZGH-4279" | out-file -FilePath $RESTBasicResources -Append

    # Assiging the data folder UUID to the folder link id in the file payload 

    ($GetMetadataimagePayload.payload.field | Where-Object {$_.name -eq "folder-links"}).list.payload.field[0].value = $DataFolderUUID

    # Sending Put request to change the folder link for the targeted file
    
    $WebRequestResults = Invoke-webrequest -Method Put -Credential $Credential -body  $GetMetadataimagePayload -ContentType application/vnd.vizrt.payload+xml -uri http://127.0.0.1:19398/metadata/file/$imageUUID -ErrorVariable MyError 
    Response_200 -MyError $MyError -WebRequestResults $WebRequestResults
    clear-Variable -name WebRequestResults -force

    # return back the file to the image folder 

    ($GetMetadataimagePayload.payload.field | Where-Object {$_.name -eq "folder-links"}).list.payload.field[0].value = $ImageFolderUUID
    ($GetMetadataimagePayload.payload.field | Where-Object {$_.name -eq "name"}).value = "Image"
    $WebRequestResults = Invoke-webrequest -Method Put -Credential $Credential -body  $GetMetadataimagePayload -ContentType application/vnd.vizrt.payload+xml -uri http://127.0.0.1:19398/metadata/file/$imageUUID -ErrorVariable MyError 


"`n `n `n" | Out-file $RESTBasicResources -Append

">>Users Callas & responses Test Results :" | Out-file $RESTBasicResources -Append
"`n" | Out-file $RESTBasicResources -Append

"- First Get responses test " | Out-file $RESTBasicResources -Append

# Response 1

$WebRequestResults = Invoke-webrequest -Method Get -Credential $Credential -uri http://127.0.0.1:19398/users -ErrorVariable MyError
Response_200 -MyError $MyError -WebRequestResults $WebRequestResults 
clear-Variable -name WebRequestResults -force


# Response 2

$WebRequestResults = Invoke-webrequest -Method Get -uri http://127.0.0.1:19398/users -ErrorVariable MyError
Response_401_403 -MyError $MyError -WebRequestResults $WebRequestResults 
clear-Variable -name WebRequestResults -force

"`n" | Out-file $RESTBasicResources -Append
"- Second Get responses test " | Out-file $RESTBasicResources -Append

#Response 1

$WebRequestResults = Invoke-webrequest -Method Get -Credential $Credential -uri http://127.0.0.1:19398/metadata/user/1 -ErrorVariable MyError
Response_200 -MyError $MyError -WebRequestResults $WebRequestResults 
clear-Variable -name WebRequestResults -force

# Response 2

$WebRequestResults = Invoke-webrequest -Method Get -uri http://127.0.0.1:19398/metadata/user/1 -ErrorVariable MyError
Response_401_403 -MyError $MyError -WebRequestResults $WebRequestResults 
clear-Variable -name WebRequestResults -force

# Response 3

$WebRequestResults = Invoke-webrequest -Method Get -Credential $Credential -uri http://127.0.0.1:19398/metadata/user/10 -ErrorVariable MyError
Response_404 -MyError $MyError -WebRequestResults $WebRequestResults 
clear-Variable -name WebRequestResults -force

"`n" | Out-file $RESTBasicResources -Append
"- POST responses test " | Out-file $RESTBasicResources -Append

# Response 1

[xml]$AdminUserPayLoad = Invoke-RestMethod -Method Get -Credential $Credential -uri http://127.0.0.1:19398/metadata/user/1

($AdminUserPayload.payload.field | Where-Object {$_.name -eq "id"}).value = "2"
($AdminUserPayload.payload.field | Where-Object {$_.name -eq "name"}).value = "TestUser"
($AdminUserPayload.payload.field | Where-Object {$_.name -eq "full-name"}).value = "TestUser"

$WebRequestResults = Invoke-webrequest -Method post -Credential $Credential -Body $AdminUserPayload -ContentType application/vnd.vizrt.payload+xml -uri http://127.0.0.1:19398/users -ErrorVariable MyError
Start-sleep 3
Response_201 -MyError $MyError -WebRequestResults $WebRequestResults
clear-Variable -name WebRequestResults -force

# Response 3

($AdminUserPayload.payload.field | Where-Object {$_.name -eq "id"}).value = "3"
($AdminUserPayload.payload.field | Where-Object {$_.name -eq "name"}).value = "TestUser1"
($AdminUserPayload.payload.field | Where-Object {$_.name -eq "full-name"}).value = "TestUser1"

[INT32]$NumberofUsers = (Invoke-RestMethod -Method Get -Credential $Credential -uri http://127.0.0.1:19398/users).count
$WebRequestResults = Invoke-webrequest -Method post -Credential $NotAuthorizedCredential -Body $AdminUserPayload -ContentType application/vnd.vizrt.payload+xml -uri http://127.0.0.1:19398/users -ErrorVariable MyError
If ((Invoke-RestMethod -Method Get -Credential $Credential -uri http://127.0.0.1:19398/users).count -eq $NumberofUsers)
    {Response_401_403 -MyError $MyError -WebRequestResults $WebRequestResults}
else
    {
    "`t Responce 3 Failed : a user was created using an unauthorized user" | out-file -FilePath $RESTBasicResources -Append
    }
clear-Variable -name WebRequestResults -force

"`t Testing ticket VIZGH-4281" | out-file -FilePath $RESTBasicResources -Append
    
($AdminUserPayload.payload.field | Where-Object {$_.name -eq "id"}).value = "4279"
($AdminUserPayload.payload.field | Where-Object {$_.name -eq "name"}).value = "VIZGH-4279"
($AdminUserPayload.payload.field | Where-Object {$_.name -eq "full-name"}).value = "VIZGH-4279"
($AdminUserPayload.payload.field | Where-Object {$_.name -eq "group-id"}).value = "1982"

[INT32]$NumberofUsers = (Invoke-RestMethod -Method Get -Credential $Credential -uri http://127.0.0.1:19398/users).count

$WebRequestResults = Invoke-webrequest -Method post -Credential $Credential -Body $AdminUserPayload -ContentType application/vnd.vizrt.payload+xml -uri http://127.0.0.1:19398/users -ErrorVariable MyError
If ((Invoke-RestMethod -Method Get -Credential $Credential -uri http://127.0.0.1:19398/users).count -eq $NumberofUsers)
    {Response_404 -MyError $MyError -WebRequestResults $WebRequestResults}
else
    {
    "`t Responce Failed : a user was created using non-existing group" | out-file -FilePath $RESTBasicResources -Append
    }
clear-Variable -name WebRequestResults -force


"`n" | Out-file $RESTBasicResources -Append
"- PUT responses test " | Out-file $RESTBasicResources -Append

# Response 1

($AdminUserPayload.payload.field | Where-Object {$_.name -eq "id"}).value = "2"
($AdminUserPayload.payload.field | Where-Object {$_.name -eq "name"}).value = "TestUser2"
($AdminUserPayload.payload.field | Where-Object {$_.name -eq "full-name"}).value = "TestUser2"
($AdminUserPayload.payload.field | Where-Object {$_.name -eq "group-id"}).value = "1"

$WebRequestResults = Invoke-webrequest -Method put -Credential $Credential -Body $AdminUserPayload -ContentType application/vnd.vizrt.payload+xml -uri http://127.0.0.1:19398/user/2 -ErrorVariable MyError
If ((Invoke-RestMethod -Method Get -Credential $Credential -uri http://127.0.0.1:19398/metadata/user/2).payload.field.value[2] -eq "TestUser2")
    {Response_200 -MyError $MyError -WebRequestResults $WebRequestResults}
else
    {
    "`t Responce 1 Failed : The user name was not changed" | out-file -FilePath $RESTBasicResources -Append
    }
clear-Variable -name WebRequestResults -force

# Response 3

($AdminUserPayload.payload.field | Where-Object {$_.name -eq "id"}).value = "2"
($AdminUserPayload.payload.field | Where-Object {$_.name -eq "name"}).value = "TestUser3"
($AdminUserPayload.payload.field | Where-Object {$_.name -eq "full-name"}).value = "TestUser3"

$WebRequestResults = Invoke-webrequest -Method put -Credential $NotAuthorizedCredential -Body $AdminUserPayload -ContentType application/vnd.vizrt.payload+xml -uri http://127.0.0.1:19398/user/2 -ErrorVariable MyError
If ((Invoke-RestMethod -Method Get -Credential $Credential -uri http://127.0.0.1:19398/metadata/user/2).payload.field.value[2] -ne "TestUser3")
    {Response_401_403 -MyError $MyError -WebRequestResults $WebRequestResults}
else
    {
    "`t Responce 3 Failed : a user was modified using an unauthorized user" | out-file -FilePath $RESTBasicResources -Append
    }
clear-Variable -name WebRequestResults -force

"`t Testing ticket VIZGH-4282" | out-file -FilePath $RESTBasicResources -Append

($AdminUserPayload.payload.field | Where-Object {$_.name -eq "id"}).value = "1982"

$WebRequestResults = Invoke-webrequest -Method put -Credential $Credential -Body $AdminUserPayload -ContentType application/vnd.vizrt.payload+xml -uri http://127.0.0.1:19398/user/1982 -ErrorVariable MyError
Response_404 -MyError $MyError -WebRequestResults $WebRequestResults

($AdminUserPayload.payload.field | Where-Object {$_.name -eq "id"}).value = "1"
clear-Variable -name WebRequestResults -force


"`n" | Out-file $RESTBasicResources -Append
"- DELETE responses test " | Out-file $RESTBasicResources -Append

# Response 1

$WebRequestResults = Invoke-webrequest -Method delete -Credential $Credential -uri http://127.0.0.1:19398/metadata/user/2 -ErrorVariable MyError
Response_204 -MyError $MyError -WebRequestResults $WebRequestResults
clear-Variable -name WebRequestResults -force

# Response 3

# Recreating "TestUser" to check if it gets deleted by an unauthorized user 

"`t Testing ticket VIZGH-4283" | out-file -FilePath $RESTBasicResources -Append

    ($AdminUserPayload.payload.field | Where-Object {$_.name -eq "id"}).value = "4283"
    ($AdminUserPayload.payload.field | Where-Object {$_.name -eq "name"}).value = "VIZGH-4283"
    ($AdminUserPayload.payload.field | Where-Object {$_.name -eq "full-name"}).value = "VIZGH-4283"
    Invoke-webrequest -Method post -Credential $Credential -Body $AdminUserPayload -ContentType application/vnd.vizrt.payload+xml -uri http://127.0.0.1:19398/users


    $WebRequestResults = Invoke-webrequest -Method delete -Credential $NotAuthorizedCredential -uri http://127.0.0.1:19398/metadata/user/4283 -ErrorVariable MyError
    If ((Invoke-RestMethod -Method Get -Credential $Credential -uri http://127.0.0.1:19398/metadata/user/4283).payload.field[1].value -like "VIZGH-4283")
        {Response_401_403 -MyError $MyError -WebRequestResults $WebRequestResults}
    else
        {
        "`t Responce Failed : a user was deleted using an unauthorized user" | out-file -FilePath $RESTBasicResources -Append
        }
    clear-Variable -name WebRequestResults -force

    # Deleting the craeted user

    Invoke-webrequest -Method delete -Credential $Credential -uri http://127.0.0.1:19398/metadata/user/4283

"`t Testing ticket VIZGH-4284" | out-file -FilePath $RESTBasicResources -Append
    
    $WebRequestResults = Invoke-webrequest -Method delete -Credential $Credential -uri http://127.0.0.1:19398/metadata/user/1982 -ErrorVariable MyError
    Response_404 -MyError $MyError -WebRequestResults $WebRequestResults
    clear-Variable -name WebRequestResults -force


"`n `n `n" | Out-file $RESTBasicResources -Append

">>groups Callas & responses Test Results :" | Out-file $RESTBasicResources -Append
"`n" | Out-file $RESTBasicResources -Append

"- First Get responses test " | Out-file $RESTBasicResources -Append

# Response 1

$WebRequestResults = Invoke-webrequest -Method Get -Credential $Credential -uri http://127.0.0.1:19398/groups -ErrorVariable MyError
Response_200 -MyError $MyError -WebRequestResults $WebRequestResults 
clear-Variable -name WebRequestResults -force


# Response 2

$WebRequestResults = Invoke-webrequest -Method Get -uri http://127.0.0.1:19398/groups -ErrorVariable MyError
Response_401_403 -MyError $MyError -WebRequestResults $WebRequestResults 
clear-Variable -name WebRequestResults -force

"`n" | Out-file $RESTBasicResources -Append
"- Second Get  responses test " | Out-file $RESTBasicResources -Append

#Response 1

$WebRequestResults = Invoke-webrequest -Method Get -Credential $Credential -uri http://127.0.0.1:19398/metadata/group/1 -ErrorVariable MyError
Response_200 -MyError $MyError -WebRequestResults $WebRequestResults 
clear-Variable -name WebRequestResults -force

# Response 2

$WebRequestResults = Invoke-webrequest -Method Get -uri http://127.0.0.1:19398/metadata/group/1 -ErrorVariable MyError
Response_401_403 -MyError $MyError -WebRequestResults $WebRequestResults 
clear-Variable -name WebRequestResults -force

# Response 3

$WebRequestResults = Invoke-webrequest -Method Get -Credential $Credential -uri http://127.0.0.1:19398/metadata/group/10 -ErrorVariable MyError
Response_404 -MyError $MyError -WebRequestResults $WebRequestResults 
clear-Variable -name WebRequestResults -force

"`n" | Out-file $RESTBasicResources -Append
"- POST responses test " | Out-file $RESTBasicResources -Append

# Response 1

# Parsing "Admin" group payload to create a new group
[xml]$AdmingroupPayload = Invoke-RestMethod -Method Get -Credential $Credential -uri http://127.0.0.1:19398/metadata/group/1

($AdmingroupPayload.payload.field | Where-Object {$_.name -eq "id"}).value = "2"
($AdmingroupPayload.payload.field | Where-Object {$_.name -eq "name"}).value = "Testgroup"


$WebRequestResults = Invoke-webrequest -Method post -Credential $Credential -Body $AdmingroupPayload -ContentType application/vnd.vizrt.payload+xml -uri http://127.0.0.1:19398/groups -ErrorVariable MyError
Response_201 -MyError $MyError -WebRequestResults $WebRequestResults
clear-Variable -name WebRequestResults -force

# Response 3

"`t Testing ticket VIZGH-4286" | out-file -FilePath $RESTBasicResources -Append

$NumberofGroups = (Invoke-RestMethod -Method Get -Credential $Credential -uri http://127.0.0.1:19398/groups).count
($AdmingroupPayload.payload.field | Where-Object {$_.name -eq "id"}).value = "3"
($AdmingroupPayload.payload.field | Where-Object {$_.name -eq "name"}).value = "Testgroup1"

$WebRequestResults = Invoke-webrequest -Method post -Credential $NotAuthorizedCredential -Body $AdmingroupPayload -ContentType application/vnd.vizrt.payload+xml -uri http://127.0.0.1:19398/groups -ErrorVariable MyError
If ((Invoke-RestMethod -Method Get -Credential $Credential -uri http://127.0.0.1:19398/groups).count -eq $NumberofGroups)
    {Response_401_403 -MyError $MyError -WebRequestResults $WebRequestResults}
else
    {
    "`t Responce Failed : a group was created using an unauthorized user" | out-file -FilePath $RESTBasicResources -Append
    }
clear-Variable -name WebRequestResults -force

"`n" | Out-file $RESTBasicResources -Append
"- PUT responses test " | Out-file $RESTBasicResources -Append

# Response 1

($AdmingroupPayload.payload.field | Where-Object {$_.name -eq "id"}).value = "2"
($AdmingroupPayload.payload.field | Where-Object {$_.name -eq "name"}).value = "Testgroup2"


$WebRequestResults = Invoke-webrequest -Method put -Credential $Credential -Body $AdmingroupPayload -ContentType application/vnd.vizrt.payload+xml -uri http://127.0.0.1:19398/group/2 -ErrorVariable MyError
If ((Invoke-RestMethod -Method Get -Credential $Credential -uri http://127.0.0.1:19398/metadata/group/2).payload.field[1].value -eq "Testgroup2")
    {Response_200 -MyError $MyError -WebRequestResults $WebRequestResults}
else
    {
    "`t Responce 1 Failed : The group name was not changed" | out-file -FilePath $RESTBasicResources -Append
    }
clear-Variable -name WebRequestResults -force

"`t Testing ticket VIZGH-4288" | out-file -FilePath $RESTBasicResources -Append

($AdmingroupPayload.payload.field | Where-Object {$_.name -eq "id"}).value = "2"
($AdmingroupPayload.payload.field | Where-Object {$_.name -eq "name"}).value = "Testgroup3"


$WebRequestResults = Invoke-webrequest -Method put -Credential $NotAuthorizedCredential -Body $AdmingroupPayload -ContentType application/vnd.vizrt.payload+xml -uri http://127.0.0.1:19398/group/2 -ErrorVariable MyError
If ((Invoke-RestMethod -Method Get -Credential $Credential -uri http://127.0.0.1:19398/metadata/group/2).payload.field[1].value -ne "Testgroup3")
    {Response_401_403 -MyError $MyError -WebRequestResults $WebRequestResults}
else
    {
    "`t Responce Failed : a group was modified using an unauthorized user" | out-file -FilePath $RESTBasicResources -Append
    ($AdmingroupPayload.payload.field | Where-Object {$_.name -eq "name"}).value = "Testgroup2"
    Invoke-webrequest -Method put -Credential $Credential -Body $AdmingroupPayload -ContentType application/vnd.vizrt.payload+xml -uri http://127.0.0.1:19398/group/2
    }
clear-Variable -name WebRequestResults -force

"`t Testing ticket VIZGH-4287" | out-file -FilePath $RESTBasicResources -Append

    ($AdmingroupPayload.payload.field | Where-Object {$_.name -eq "id"}).value = "2"
    ($AdmingroupPayload.payload.field | Where-Object {$_.name -eq "name"}).value = "Testgroup2"
    ($AdmingroupPayload.payload.field | Where-Object {$_.name -eq "active"}).value = "false"

    $WebRequestResults = Invoke-webrequest -Method put -Credential $Credential -Body $AdmingroupPayload -ContentType application/vnd.vizrt.payload+xml -uri http://127.0.0.1:19398/group/2 -ErrorVariable MyError
    If ((Invoke-RestMethod -Method Get -Credential $Credential -uri http://127.0.0.1:19398/metadata/group/2).payload.field[2].value -eq "false")
        {
        Response_200 -MyError $MyError -WebRequestResults $WebRequestResults
        ($AdmingroupPayload.payload.field | Where-Object {$_.name -eq "active"}).value = "true"
        Invoke-webrequest -Method put -Credential $Credential -Body $AdmingroupPayload -ContentType application/vnd.vizrt.payload+xml -uri http://127.0.0.1:19398/group/2
        }
    Else 
        {
        "`t Responce Failed : a group is still active eventhough the put request was supposed to changed it to inactive" | out-file -FilePath $RESTBasicResources -Append
        }

    clear-Variable -name WebRequestResults -force



"`n" | Out-file $RESTBasicResources -Append
"- DELETE responses test " | Out-file $RESTBasicResources -Append

# Response 1

$WebRequestResults = Invoke-webrequest -Method delete -Credential $Credential -uri http://127.0.0.1:19398/metadata/group/2 -ErrorVariable MyError
Response_204 -MyError $MyError -WebRequestResults $WebRequestResults
clear-Variable -name WebRequestResults -force

"`t Testing ticket VIZGH-4289" | out-file -FilePath $RESTBasicResources -Append

    # Recreating "Testgroup" to check if it gets deleted by an unauthorized user 

    ($AdmingroupPayload.payload.field | Where-Object {$_.name -eq "id"}).value = "2"
    ($AdmingroupPayload.payload.field | Where-Object {$_.name -eq "name"}).value = "Testgroup"

    Invoke-webrequest -Method post -Credential $Credential -Body $AdmingroupPayload -ContentType application/vnd.vizrt.payload+xml -uri http://127.0.0.1:19398/groups

    $NumberofGroups = (Invoke-RestMethod -Method Get -Credential $Credential -uri http://127.0.0.1:19398/groups).count
    $WebRequestResults = Invoke-webrequest -Method delete -Credential $NotAuthorizedCredential -uri http://127.0.0.1:19398/metadata/group/2 -ErrorVariable MyError
    If ((Invoke-RestMethod -Method Get -Credential $Credential -uri http://127.0.0.1:19398/groups).count -eq $NumberofGroups)
        {
        Response_401_403 -MyError $MyError -WebRequestResults $WebRequestResults
        }
    else
        {
        "`t Responce Failed : a group was deleted using an unauthorized user" | out-file -FilePath $RESTBasicResources -Append
        }
    clear-Variable -name WebRequestResults -force
 
 "`t Testing ticket VIZGH-4290" | out-file -FilePath $RESTBasicResources -Append 
    
    $WebRequestResults = Invoke-webrequest -Method delete -Credential $Credential -uri http://127.0.0.1:19398/metadata/group/1982 -ErrorVariable MyError
    Response_404 -MyError $MyError -WebRequestResults $WebRequestResults
    clear-Variable -name WebRequestResults -force

 # Deleting the test group 
   Invoke-webrequest -Method delete -Credential $Credential -uri http://127.0.0.1:19398/metadata/group/2



"`n `n `n" | Out-file $RESTBasicResources -Append

">>Types Callas & responses Test Results :" | Out-file $RESTBasicResources -Append
"`n" | Out-file $RESTBasicResources -Append

"- First Get responses test " | Out-file $RESTBasicResources -Append

# Response 1

$WebRequestResults = Invoke-webrequest -Method Get -Credential $Credential -uri http://127.0.0.1:19398/types -ErrorVariable MyError
Response_200 -MyError $MyError -WebRequestResults $WebRequestResults 
clear-Variable -name WebRequestResults -force


# Response 2

$WebRequestResults = Invoke-webrequest -Method Get -uri http://127.0.0.1:19398/types -ErrorVariable MyError
Response_401_403 -MyError $MyError -WebRequestResults $WebRequestResults 
clear-Variable -name WebRequestResults -force

"`n" | Out-file $RESTBasicResources -Append
"- Second Get responses test " | Out-file $RESTBasicResources -Append

# Response 1

$WebRequestResults = Invoke-webrequest -Method Get -Credential $Credential -uri http://127.0.0.1:19398/metadata/type/1 -ErrorVariable MyError
Response_200 -MyError $MyError -WebRequestResults $WebRequestResults 
clear-Variable -name WebRequestResults -force


# Response 2

$WebRequestResults = Invoke-webrequest -Method Get -uri http://127.0.0.1:19398/metadata/type/1 -ErrorVariable MyError
Response_401_403 -MyError $MyError -WebRequestResults $WebRequestResults 
clear-Variable -name WebRequestResults -force

# Response 3

$WebRequestResults = Invoke-webrequest -Method Get -Credential $Credential -uri http://127.0.0.1:19398/metadata/type/90 -ErrorVariable MyError
Response_404 -MyError $MyError -WebRequestResults $WebRequestResults 
clear-Variable -name WebRequestResults -force

"`n `n `n" | Out-file $RESTBasicResources -Append

">>Keywords Callas & responses Test Results :" | Out-file $RESTBasicResources -Append
"`n" | Out-file $RESTBasicResources -Append

"- Post responses test " | Out-file $RESTBasicResources -Append

# Response 1

[xml]$KeywordPayload = "<payload><field name='id'><value>1</value></field><field name='name'><value>Testkeyword</value></field></payload>" 

$WebRequestResults = Invoke-webrequest -Method post -Credential $Credential -Body $KeywordPayload -ContentType application/vnd.vizrt.payload+xml -uri http://127.0.0.1:19398/keywords -ErrorVariable MyError
Response_201 -MyError $MyError -WebRequestResults $WebRequestResults
clear-Variable -name WebRequestResults -force

"`t Testing ticket VIZGH-4292" | out-file -FilePath $RESTBasicResources -Append

[xml]$KeywordPayload = "<payload><field name='id'><value>2</value></field><field name='name'><value>Testkeyword1</value></field></payload>"
$WebRequestResults = Invoke-webrequest -Method post -Credential $NotAuthorizedCredential -Body $KeywordPayload -ContentType application/vnd.vizrt.payload+xml -uri http://127.0.0.1:19398/keywords -ErrorVariable MyError

Response_401_403 -MyError $MyError -WebRequestResults $WebRequestResults
clear-Variable -name WebRequestResults -force

"`n" | Out-file $RESTBasicResources -Append
"- First Get responses test " | Out-file $RESTBasicResources -Append

# Response 1

$WebRequestResults = Invoke-webrequest -Method Get -Credential $Credential -uri http://127.0.0.1:19398/keywords -ErrorVariable MyError
Response_200 -MyError $MyError -WebRequestResults $WebRequestResults 
clear-Variable -name WebRequestResults -force


# Response 2

$WebRequestResults = Invoke-webrequest -Method Get -uri http://127.0.0.1:19398/keywords -ErrorVariable MyError
Response_401_403 -MyError $MyError -WebRequestResults $WebRequestResults 
clear-Variable -name WebRequestResults -force

"`n" | Out-file $RESTBasicResources -Append
"- Second Get responses test " | Out-file $RESTBasicResources -Append

# Response 1

$WebRequestResults = Invoke-webrequest -Method Get -Credential $Credential -uri http://127.0.0.1:19398/metadata/keyword/1 -ErrorVariable MyError
Response_200 -MyError $MyError -WebRequestResults $WebRequestResults 
clear-Variable -name WebRequestResults -force


# Response 2

$WebRequestResults = Invoke-webrequest -Method Get -uri http://127.0.0.1:19398/metadata/keyword/1 -ErrorVariable MyError
Response_401_403 -MyError $MyError -WebRequestResults $WebRequestResults 
clear-Variable -name WebRequestResults -force

# Response 3

$WebRequestResults = Invoke-webrequest -Method Get -Credential $Credential -uri http://127.0.0.1:19398/metadata/keyword/90 -ErrorVariable MyError
Response_404 -MyError $MyError -WebRequestResults $WebRequestResults 
clear-Variable -name WebRequestResults -force

"`n" | Out-file $RESTBasicResources -Append

"- Put responses test " | Out-file $RESTBasicResources -Append

# Response 1

[xml]$KeywordPayload = "<payload><field name='id'><value>1</value></field><field name='name'><value>Modifiedkeyword</value></field></payload>"
$WebRequestResults = Invoke-webrequest -Method put -Credential $Credential -Body $KeywordPayload -ContentType application/vnd.vizrt.payload+xml -uri http://127.0.0.1:19398/metadata/keyword/1 -ErrorVariable MyError
Response_200 -MyError $MyError -WebRequestResults $WebRequestResults
clear-Variable -name WebRequestResults -force

"`t Testing ticket VIZGH-4292" | out-file -FilePath $RESTBasicResources -Append

[xml]$KeywordPayload = "<payload><field name='id'><value>1</value></field><field name='name'><value>Modifiedkeyword1</value></field></payload>"
$WebRequestResults = Invoke-webrequest -Method put -Credential $NotAuthorizedCredential -Body $KeywordPayload -ContentType application/vnd.vizrt.payload+xml -uri http://127.0.0.1:19398/metadata/keyword/1 -ErrorVariable MyError
Response_401_403 -MyError $MyError -WebRequestResults $WebRequestResults
clear-Variable -name WebRequestResults -force

"`t Testing ticket VIZGH-4294" | out-file -FilePath $RESTBasicResources -Append

    [xml]$KeywordPayload = "<payload><field name='id'><value>1982</value></field><field name='name'><value>Modifiedkeyword</value></field></payload>"
    $WebRequestResults = Invoke-webrequest -Method put -Credential $Credential -Body $KeywordPayload -ContentType application/vnd.vizrt.payload+xml -uri http://127.0.0.1:19398/metadata/keyword/1982 -ErrorVariable MyError
    Response_404 -MyError $MyError -WebRequestResults $WebRequestResults
    clear-Variable -name WebRequestResults -force


"`n" | Out-file $RESTBasicResources -Append

"- Delete responses test " | Out-file $RESTBasicResources -Append

# Response 2

$WebRequestResults = Invoke-webrequest -Method delete -Credential $Credential -uri http://127.0.0.1:19398/metadata/keyword/1 -ErrorVariable MyError
Response_204 -MyError $MyError -WebRequestResults $WebRequestResults
clear-Variable -name WebRequestResults -force

"`t Testing ticket VIZGH-4295" | out-file -FilePath $RESTBasicResources -Append

    # Recreating the keyword to try to delete it with an unauthorized user 

    [xml]$KeywordPayload = "<payload><field name='id'><value>1</value></field><field name='name'><value>Testkeyword</value></field></payload>" 
    Invoke-webrequest -Method post -Credential $Credential -Body $KeywordPayload -ContentType application/vnd.vizrt.payload+xml -uri http://127.0.0.1:19398/keywords -ErrorVariable MyError

    $WebRequestResults = Invoke-webrequest -Method delete -Credential $NotAuthorizedCredential -uri http://127.0.0.1:19398/metadata/keyword/1 -ErrorVariable MyError
    Response_401_403 -MyError $MyError -WebRequestResults $WebRequestResults
    clear-Variable -name WebRequestResults -force

"`t Testing ticket VIZGH-4297" | out-file -FilePath $RESTBasicResources -Append

    $WebRequestResults = Invoke-webrequest -Method delete -Credential $Credential -uri http://127.0.0.1:19398/metadata/keyword/5 -ErrorVariable MyError
    Response_404 -MyError $MyError -WebRequestResults $WebRequestResults
    clear-Variable -name WebRequestResults -force


"`n `n `n" | Out-file $RESTBasicResources -Append

">>Thumbnails Callas & responses Test Results :" | Out-file $RESTBasicResources -Append
"`n" | Out-file $RESTBasicResources -Append

"- Get responses test " | Out-file $RESTBasicResources -Append

# Response 1

$WebRequestResults = Invoke-webrequest -Method get -Credential $Credential -uri http://127.0.0.1:19398/thumbnail/$imageUUID`?size=large -ErrorVariable MyError
Response_200 -MyError $MyError -WebRequestResults $WebRequestResults
clear-Variable -name WebRequestResults -force

"`n `n `n" | Out-file $RESTBasicResources -Append

">>Images Callas & responses Test Results :" | Out-file $RESTBasicResources -Append
"`n" | Out-file $RESTBasicResources -Append

"- First get responses test " | Out-file $RESTBasicResources -Append

# Response 1

$WebRequestResults = Invoke-webrequest -Method get -Credential $Credential -uri http://127.0.0.1:19398/image/$imageUUID -ErrorVariable MyError
Response_200 -MyError $MyError -WebRequestResults $WebRequestResults
clear-Variable -name WebRequestResults -force

# Response 2

$WebRequestResults = Invoke-webrequest -Method get -uri http://127.0.0.1:19398/image/$imageUUID -ErrorVariable MyError
Response_401_403 -MyError $MyError -WebRequestResults $WebRequestResults
clear-Variable -name WebRequestResults -force


"`n" | Out-file $RESTBasicResources -Append

"- Second get responses test " | Out-file $RESTBasicResources -Append

# Response 1

$WebRequestResults = Invoke-webrequest -Method get -Credential $Credential -uri http://127.0.0.1:19398/image/$imageUUID/`?mime_type=image/png -ErrorVariable MyError
Response_200 -MyError $MyError -WebRequestResults $WebRequestResults
clear-Variable -name WebRequestResults -force

# Response 2

$WebRequestResults = Invoke-webrequest -Method get -uri http://127.0.0.1:19398/image/$imageUUID/`?mime_type=image/png -ErrorVariable MyError
Response_401_403 -MyError $MyError -WebRequestResults $WebRequestResults
clear-Variable -name WebRequestResults -force

"`n" | Out-file $RESTBasicResources -Append

"- POST image test covered in another test " | Out-file $RESTBasicResources -Append

"`n" | Out-file $RESTBasicResources -Append

"- PUT responses test " | Out-file $RESTBasicResources -Append

$WebRequestResults = Invoke-webrequest -Method Put -Credential $Credential -ContentType image/png -uri http://127.0.0.1:19398/image/$imageUUID -ErrorVariable MyError
Response_200 -MyError $MyError -WebRequestResults $WebRequestResults
clear-Variable -name WebRequestResults -force