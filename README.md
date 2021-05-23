# bigfix-powershell
Integration module offering a consistent, simple, and streamlined approach to interacting with the BigFix suite of products and APIs directly from within PowerShell.

# Getting Started
Working with the BigFix PowerShell module starts with importing it into your PowerShell session. This is accomplished via the Import-Module command.

```powershell
Import-Module BigFix
```

# Commands
Commands provided in this module are broken up into functional groups.

## Web Reports Server
When working with the Web Reports Server SOAP API, you will need to define the Web Reports Servers you plan on interacting with. The following commands are used for this purpose.

### New-WebReportsServer
Creates a new Web Reports Server object to use when calling New-WebReportsSession, and [optionally] both registers and sets it as the default Web Reports Server object.

#### Parameters
**-Uri**       Specifies a well-formed absolute URI to the Web Reports Server.

**-Fqdn**      Specifies the Fully Qualified Domain Name (FQDN) of the Web Reports Server. 
               This can be entered either as just the hostname, IP address, or the FQDN (preferred).

**-Port**      Specifies the TCP port number of the Web Reports Server, if a non-standard (80/443)
               port is being used.
**-Ssl**       Switch specifying if SSL (HTTPS) is to be used when connecting to the Web Reports Server.

**-NoPersist** Switch specifying that the Web Reports Server object created not be persisted to the 
               registry nor set as the default.
               
#### Examples
Create a new Web Reports Server object to the server 'webreports' over HTTPS, using URI nomenclature.
```powershell
New-WebReportsServer -Uri 'https://webreports/'
```
Output:
```
Uri                 Wsdl
---                 ----
https://webreports/ https://webreports/?wsdl
```

Create a new Web Reports Server object to the server 'webreports' over HTTPS, using URI nomenclature, and requesting it be non-persisted.
```powershell
New-WebReportsServer -Uri 'https://webreports/' -NoPersist
```
Output:
```
Uri                 Wsdl
---                 ----
https://webreports/ https://webreports/?wsdl
```

Create a new Web Reports Server object to the server 'webreports' over HTTP on the default HTTP port (80).
```powershell
New-WebReportsServer -Fqdn 'webreports'
```
Output:
```
Uri                Wsdl
---                ----
http://webreports/ http://webreports/?wsdl
```

Create a new Web Reports Server object to the server 'webreports' over HTTPS on the non-standard TCP port (8443) and request it to be non-persisted.
```powershell
New-WebReportsServer -Fqdn 'webreports' -Port 8443 -Ssl -NoPersist
```
Output:
```
Uri                      Wsdl
---                      ----
https://webreports:8443/ https://webreports:8443/?wsdl
```

### Get-WebReportsServer
Gets registered Web Reports Server objects. When called without parameters, a listing of all registered Web Reports Server objects will be returned. If a URI is provided, attempt to return the matching Web Reports Server object. If called with the -Default switch, the registered default Web Reports Server object will be returned (if found).

#### Parameters
**-Uri**     Specifies the well-formed absolute URI of the registered Web Reports Server object 
             to return.

**-Default** Switch specifying that the default registered Web Reports Server object is to be returned.
               
#### Examples
Get a listing of all registered Web Reports Server objects.
```powershell
Get-WebReportsServer
```
Output:
```
Uri                 Wsdl
---                 ----
https://webreports/ https://webreports/?wsdl
http://webreports/  http://webreports/?wsdl
```

Get the registered Web Reports Server object matching the Web Reports Server URI 'https://webreports/'
```powershell
Get-WebReportsServer -Uri 'https://webreports/'
```
Output:
```
Uri                 Wsdl
---                 ----
https://webreports/ https://webreports/?wsdl

```

Get the default registered Web Reports Server object.
```powershell
Get-WebReportsServer -Default
```
Output:
```
Uri                Wsdl
---                ----
http://webreports/ http://webreports/?wsdl
```

### Set-WebReportsServer
Sets the default Web Reports Server object to use when calling New-WebReportsSession with the -Default switch. If the Web Reports Server object does not yet exist in the registry, then it will also be added.

#### Parameters
**-Server** Specifies the Web Reports Server object (created using New-WebReportsServer
            or returned from Get-WebReportsServer) to set as default.
**-Uri**    Specifies a well-formed absolute URI to the Web Reports Server to be set as the
            default. A new Web Reports Server object will be registered if one is not 
            already found matching the URI.
               
#### Examples
Sets the default Web Reports Session object to the Web Reports Server defined in the $MyServer variable.
```powershell
$MyServer = New-WebReportsServer -Uri 'https://webreports/'

Set-WebReportsServer -Server $MyServer
```
Output:
```
Uri                 Wsdl
---                 ----
https://webreports/ https://webreports/?wsdl
```

Sets the default Web Reports Server object to the server 'webreports' over HTTPS, creating and registering a new object if a matching one does not already exist.
```powershell
Set-WebReportsServer -Uri 'https://webreports/'
```
Output:
```
Uri                 Wsdl
---                 ----
https://webreports/ https://webreports/?wsdl
```

## Web Reports Session
In addition to defining the Web Reports Server(s) you wish to interact with, you will need to establish a Web Reports Session to that server. The session is the heart of all the SOAP API helper commands as it is the communications change over which all interactions with the SOAP API are performed. 

Each Web Reports Session is self-contained allowing you to create multiple sessions to either a single Web Reports Server (i.e. session 1 uses account 'test' and session 2 uses account 'api'), or to a totally different Web Reports Server (i.e. consolidating data from multiple BigFix installations).

### New-WebReportsSession
Creates a new Web Reports Session object exposing the BigFix Web Reports SOAP API. This session object is used by the other cmdlets in this module.

#### Parameters
**-Default**    Use the default Web Reports Server previously defined to establish the session
                with. The default Web Reports Server is the last one created using 
                New-WebReportsServer or Set-WebReportsServer. Get-WebReportsServer -Default will
                return the current default.

**-Server**     Specifies the Web Reports Server object (created using New-WebReportsServer
                or returned from Get-WebReportsServer) to establish the session with.

**-Uri**        Specifies a well-formed absolute URI to the Web Reports Server to establish 
                the session with. A new Web Reports Server object will be registered
                if one is not already found matching the URI.

**-Credential** Specifies the Web Reports account either as "myuser", "domain\myuser", or a 
                PSCredential object. Omitting or providing a $null or 
                [System.Management.Automation.PSCredential]::Empty will prompt the caller.

#### Examples
Create a Web Reports Session object to the default Web Reports Server, prompting for credentials.
```powershell
New-WebReportsSession -Default
```
Output:
```
Windows PowerShell credential request.
Please enter credentials for Web Reports Server 'https://webreports/'
User: TestUser
Password for user TestUser: ********

Server              State     Credential
------              -----     ----------
https://webreports/ Connected TestUser
```

Create a Web Reports Session object to the Web Reports Server defined in the $MyServer variable, prompting for credentials.
```powershell
$MyServer = New-WebReportsServer -Uri 'http://webreports/'

New-WebReportsSession -Server $MyServer
```
Output:
```
Windows PowerShell credential request.
Please enter credentials for Web Reports Server 'http://webreports/'
User: TestUser
Password for user TestUser: ********

Server             State     Credential
------             -----     ----------
http://webreports/ Connected TestUser
```

Create a Web Reports Session object to the server 'webreports' over HTTPS, using the [PSCredential] credential object in the variable $credential.
```powershell
$credential = Get-Credential

New-WebReportsSession -Uri 'https://webreports/' -Credential $credential
```
Output:
```
cmdlet Get-Credential at command pipeline position 1
Supply values for the following parameters:
User: TestUser
Password for user TestUser: ********

Server              State     Credential
------              -----     ----------
https://webreports/ Connected TestUser
```

### Get-WebReportsSession
Gets the Web Reports Session created during the last call to New-WebReportsSession.

#### Examples
```powershell
Get-WebReportsSession
```
Output:
```
Server              State     Credential
------              -----     ----------
https://webreports/ Connected TestUser
```

### Invoke-EvaluateSessionRelevance
Evaluates Session Relevance statements on the established Web Reports Session, parsing results into a more PowerShell-friendly format. Relevance Statements can be provided via the -Relevance parameter or the pipeline. Results are returned only after all Relevance Statements have completed.

This function is also exposed directly on the Web Reports Session object as 'evaluate' which you can call. This object-based shortcut allows you to always ensure you are evaluating using an expected Web Reports Session.

#### Parameters
**-Relevance**  Specifies the Session Relevance statement to evaluate on the Web Reports Session.

**-Session**    Specifies the Web Reports Session to evaluate the relevance on. If not provided,
                will attempt to use the last Web Reports Session created via
                New-WebReportsSession.

**-FieldNames** Specifies a listing of field names to translate the evaluation tuple results 
                into.

#### Examples
Evaluate the Session Relevance statement 'number of bes computers'.
```powershell
Invoke-EvaluateSessionRelevance -Relevance 'number of bes computers'
```
Output:
```
Relevance               Status  Execution Time   Evaluation Time Result Count Result
---------               ------  --------------   --------------- ------------ ------
number of bes computers Success 00:00:00.3917915 00:00:00        1            4
```

Evaluate the Session Relevance statement '(id of it, last report time of it) of bes computers', parsing results into objects with the field names 'Id' and 'LastReportTime'.
```powershell
Invoke-EvaluateSessionRelevance -Relevance '(id of it, last report time of it) of bes computers' -FieldNames @('Id', 'LastReportTime')

Invoke-EvaluateSessionRelevance -Relevance '(id of it, last report time of it) of bes computers' -FieldNames @('Id', 'LastReportTime') | Select-Object -ExpandProperty Results
```
Output:
```
Relevance                                           Status  Execution Time   Evaluation Time Result Count Result
---------                                           ------  --------------   --------------- ------------ ------
(id of it, last report time of it) of bes computers Success 00:00:00.1223545 00:00:00        4            {@{Id=1036828; Last...

        Id LastReportTime
        -- --------------
   1036828 3/19/2019 4:44:00 PM
 551884969 3/19/2019 4:45:28 PM
1614275947 3/19/2019 4:53:41 PM
1625012524 3/19/2019 4:38:53 PM
```

## Qna Session
Working with remote Web Reports Server(s) is great but sometimes you may want to evaluate client relevance directly on the computer you are currently connected to. This can be as simple as firing off simple relevance statements to obtain answers that would be otherwise more complicated to obtain, or as complex as building a full offline fixlet evaluation system to determine what fixlets the computer requires without requiring a network connection or even a full BigFix Client instance.  

Each Qna Session is self-contained allowing you to create multiple sessions to either a single qna.exe binary (for parallel query executions), or to a totally different qna.exe binary (testing queries for consistent results across multiple versions).

### New-QnaSession
Creates a new Qna Session object and expose it into the current scope. By default, it will attempt to link to the qna.exe utility application binary using the following search path order: 
  1. Directory defined within the environmental variable 'QnA'.
  2. Current working directory.
  3. Directory where the BigFix Client is registered 
  4. Every directory defined within the environmental variable 'PATH', in the order it is defined.

If called with the -ExecutablePath parameter and provided with the full path of the qna.exe utility, the session will attempt to link to that binary.

#### Parameters
**-ExecutablePath** Path to the BigFix Qna utility executable (i.e. qna.exe)
#### Examples
Create a new Qna Session using the qna.exe utility application installed as part of the BigFix Client installation.
```powershell
New-QnaSession
```
Output:
```
IdleTimeout EvaluationTimeout ExecutablePath                                              Version  
----------- ----------------- --------------                                              -------
        300                60 C:\Program Files (x86)\BigFix Enterprise\BES Client\qna.exe 9.5.12.68
```

Create a new Qna Session using the qna.exe utility application at the provided path.
```powershell
New-QnaSession -ExecutablePath 'C:\Tools\BigFix\qna.exe'
```
Output:
```
IdleTimeout EvaluationTimeout ExecutablePath          Version  
----------- ----------------- --------------          -------
        300                60 C:\Tools\BigFix\qna.exe 9.5.15.71
```

### Get-QnaSession
Gets the previously instantiated Qna Session object.

#### Examples
```powershell
Get-QnaSession
```
Output:
```
IdleTimeout EvaluationTimeout ExecutablePath                                              Version  
----------- ----------------- --------------                                              -------
        300                60 C:\Program Files (x86)\BigFix Enterprise\BES Client\qna.exe 9.5.12.68
```
### Invoke-EvaluateClientRelevance
Evaluates Client Relevance statements in the established Qna Session, parsing results into a more PowerShell-friendly format. Relevance Statements can be provided via the -Relevance parameter or the pipeline. Results are returned sequentially to the pipeline as they are evaluated in the Qna Session.

#### Parameters
**-Relevance**  Specifies the Client Relevance statement(s) to evaluate in the Qna Session.

**-Session**    Specifies the Qna Session to evaluate the relevance in. If not provided,
                will attempt to use the last Qna Session created via New-QnaSession, creating
                a new Qna Session in the event none exists.

#### Examples
Evaluate the Client Relevance statement 'computer name'.
```powershell
Invoke-EvaluateClientRelevance -Relevance 'computer name'
```
Output:
```
Relevance     Answer   Error EvalTime
---------     ------   ----- --------
computer name {bigfix}            169
```

Evaluate the Client Relevance statements 'now' and 'version of client' using the pipeline for input.
```powershell
'now','version of client' | Invoke-EvaluateClientRelevance
```
Output:
```
Relevance         Answer                            Error EvalTime
---------         ------                            ----- --------
now               {Sun, 23 May 2021 15:52:15 -0400}             89
version of client {9.5.12.68}                                  695
```

Evaluate the Client Relevance statement 'computer name' using a specific Qna Session.
```powershell
$QnaSession = New-QnaSession -ExecutablePath 'C:\Tools\BigFix\qna.exe'
Invoke-EvaluateClientRelevance -Relevance 'computer name' -Session $QnaSession
```
Output:
```
Relevance     Answer   Error EvalTime
---------     ------   ----- --------
computer name {bigfix}            188
```
