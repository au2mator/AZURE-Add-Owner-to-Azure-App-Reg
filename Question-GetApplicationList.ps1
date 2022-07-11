#########
# au2mator PS Services
# Type: PowerShell Question
#
# Title: Question-GetApplicationList
#
#
# URL: https://au2mator.com/documentation/configure-powershell-question-type/?utm_source=github&utm_medium=social&utm_campaign=Azure_AddOwnerAzureAppReg&utm_content=PS1
# Github: https://github.com/au2mator/au2mator-PS-Templates
#
# PreReq: au2mator 4.5 or higher required
#
#
#
# au2mator is happy to support you with your Automation
# Contact us here: https://au2mator.com/premier-services/?utm_source=github&utm_medium=social&utm_campaign=Azure_AddOwnerAzureAppReg&utm_content=PS1
#
#################


#region  InputParamaters
param ($au2matorhook)
$jsondata = $au2matorhook | ConvertFrom-Json


#endregion  InputParamaters

#region Variables

#Environment
[string]$CredentialStorePath = "C:\_SCOworkingDir\TFS\PS-Services\CredentialStore" #see for details: https://au2mator.com/documentation/powershell-credentials/?utm_source=github&utm_medium=social&utm_campaign=Azure_AddOwnerAzureAppReg&utm_content=PS1

[string]$LogPath = "C:\_SCOworkingDir\TFS\PS-Services\AZURE - Add Owner to Azure App Reg\Logs"
[string]$LogfileName = "Question-GetApplicationList"


#endregion Variables



#region CustomVariables


$MSGraphAPICred_File = "MSGraphAPICred.xml"
$MSGraphAPICred = Import-CliXml -Path (Get-ChildItem -Path $CredentialStorePath -Filter $MSGraphAPICred_File).FullName
$MSGraphAPI_clientId = $MSGraphAPICred.clientId
$MSGraphAPI_clientSecret = $MSGraphAPICred.clientSecret
$MSGraphAPI_tenantID = $MSGraphAPICred.tenantID

$MSGraphAPI_BaseURL = "https://graph.microsoft.com/v1.0"


#endregion CustomVariables





#region Functions
function Write-au2matorLog {
    [CmdletBinding()]
    param
    (
        [ValidateSet('DEBUG', 'INFO', 'WARNING', 'ERROR')]
        [string]$Type,
        [string]$Text
    )

    # Set logging path
    if (!(Test-Path -Path $logPath)) {
        try {
            $null = New-Item -Path $logPath -ItemType Directory
            Write-Verbose ("Path: ""{0}"" was created." -f $logPath)
        }
        catch {
            Write-Verbose ("Path: ""{0}"" couldn't be created." -f $logPath)
        }
    }
    else {
        Write-Verbose ("Path: ""{0}"" already exists." -f $logPath)
    }
    [string]$logFile = '{0}\{1}_{2}.log' -f $logPath, $(Get-Date -Format 'yyyyMMdd'), $LogfileName
    $logEntry = '{0}: <{1}> <{2}> <{3}> {4}' -f $(Get-Date -Format dd.MM.yyyy-HH:mm:ss), $Type, $RequestId, $Service, $Text
    Add-Content -Path $logFile -Value $logEntry
}

#endregion Functions



#region CustomFunctions

#
#
#
#


#endregion CustomFunctions


#region Script
Write-au2matorLog -Type INFO -Text "Start Script"

try {
    Write-au2matorLog -Type INFO -Text "TRY to authenticate with MS GRAPH API"
    #Auth MS Graph API and Get Header
    $MSGRAPHAPI_tokenBody = @{  
        Grant_Type    = "client_credentials"  
        Scope         = "https://graph.microsoft.com/.default"  
        Client_Id     = $MSGRAPHAPI_clientID  
        Client_Secret = $MSGRAPHAPI_Clientsecret  
    }   
    $MSGRAPHAPI_tokenResponse = Invoke-RestMethod -Uri "https://login.microsoftonline.com/$MSGRAPHAPI_tenantId/oauth2/v2.0/token" -Method POST -Body $MSGRAPHAPI_tokenBody  
    $MSGRAPHAPI_headers = @{
        "Authorization" = "Bearer $($MSGRAPHAPI_tokenResponse.access_token)"
        "Content-type"  = "application/json"
    }

    Write-au2matorLog -Type INFO -Text "Received our Bearer Token and built the Header"
    
    try {
        Write-au2matorLog -Type INFO -Text "TRY to get all Azure App Regs"


        $GetAzureAppRegs_Uri = "$MSGRAPHAPI_BaseURL/applications"
        $GetAzureAppRegs_Response = Invoke-RestMethod -Uri $GetAzureAppRegs_Uri -Headers $MSGRAPHAPI_headers -Method Get

        $GetAzureAppRegs_result = $GetAzureAppRegs_Response.value 
        $GetAzureAppRegs_NextLink = $GetAzureAppRegs_Response."@odata.nextLink"


        while ($SPNextLink -ne $null) {

            $GetAzureAppRegs_Response = (Invoke-RestMethod -Uri $GetAzureAppRegs_NextLink -Headers $MSGRAPHAPI_headers -Method Get)
            $GetAzureAppRegs_NextLink = $GetAzureAppRegs_Response."@odata.nextLink"
            $GetAzureAppRegs_result += $GetAzureAppRegs_Response.value

        }

        $GetAzureAppRegs_result.count

        $Return = $GetAzureAppRegs_result | Select-Object displayName, id, createdDateTime
        
    }
    catch {
        Write-au2matorLog -Type ERROR -Text "Error to get Azure App Regs"
        Write-au2matorLog -Type ERROR -Text $Error
    
        $au2matorReturn = "Error to get Azure App Regs, Error: $Error"
        $TeamsReturn = "Error to get Azure App Regs" #No Special Characters allowed
        $AdditionalHTML = "Error to get Azure App Regs
        <br>
        Error: $Error
            "
        $Status = "ERROR"
    }
}
catch {
    Write-au2matorLog -Type ERROR -Text "Failed to authenticate with MS GRAPH API"
    Write-au2matorLog -Type ERROR -Text $Error

    $au2matorReturn = "Failed to authenticate with MS GRAPH API, Error: $Error"
    $TeamsReturn = "Failed to authenticate with MS GRAPH API" #No Special Characters allowed
    $AdditionalHTML = "Failed to authenticate with MS GRAPH API
    <br>
    Error: $Error
        "
    $Status = "ERROR"
}

#endregion Script


return $Return
