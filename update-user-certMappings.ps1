# bulk update user certificate mappings
# Josh Basquez
# github.com/joshbasquez
# Disclaimer: For educational purposes only, no warranties expressed or implied.

# part 1 - web login for authentication to graph using azure ad powershell enterprise app
# part 2 - import list of users/cert mappings csv, loop thru each to update via graphAPI calls

# PART 1 - web login
# auth and connect to graph using deviceCode admin login to browser
# build auth token, login and enter powershell device code
 
$O365 = [PSCustomObject]@{ 
    version         = "1.2"
    startTime       = $null;
    startTimeDate   = $null;   
    logFileName     = "";
    logDirectory    = "";
    logFileTabCount = 0;
    tenant          = "common";
    clientId        = "1950a258-227b-4e31-a9cf-717495945fc2"; #Azure AD Powershell App GUID    
    token           = @{
 
## CONFIGURED FOR COMMERCIAL OR USGOV
        resourceURL  = " https://graph.microsoft.com";
        loginURL     = " https://login.microsoftonline.com";
#        resourceURL  = " https://dod-graph.microsoft.us";
#        loginURL     = " https://login.microsoftonline.us";

# uncomment for Azure Commercial
# loginUrl = " https://login.microsoftonline.com"
# resourceUrl = " https://graph.microsoft.com"
# uncomment for DoD
# loginUrl = " https://login.microsoftonline.us"  # for USGovDoD
# resourceUrl = " https://dod-graph.microsoft.us"    # for USGovDoD
# uncomment for AzureGov
# loginUrl = " https://login.microsoftonline.us"  # for AzureGov
# resourceUrl = " https://graph.microsoft.us"    # for AzureGov

        tokenExpires = $null;
        accessToken  = $null;
        refreshToken = $null;
        authContext  = $null;
    };    
    authHeader      = $null;
    pagingAmount    = 250;
}
 
 
$DeviceCodeRequestParams = @{
        Method = "POST"        
        Uri    = "$($O365.token.loginURL)/$($O365.tenant)/oauth2/devicecode"
        Body   = @{
            client_id = $O365.clientId            
            resource  = $O365.token.resourceURL
        }
    }
 
    $DeviceCodeRequest = Invoke-RestMethod @DeviceCodeRequestParams
    Write-Host $DeviceCodeRequest.message -ForegroundColor Yellow
PAUSE

# # PAUSE FOR LOGIN # #
$TokenRequestParams = @{
                Method = 'POST'
                Uri    = "$($O365.token.loginURL)/$($O365.tenant)/oauth2/token"
                Body   = @{
                    grant_type = "urn:ietf:params:oauth:grant-type:device_code"
                    code       = $DeviceCodeRequest.device_code
                    client_id  = $O365.clientId
                }
            }
        
            $TokenRequest = Invoke-RestMethod @TokenRequestParams
            $isAuthed = $true;
 
$O365.token.refreshToken = $TokenRequest.refresh_token;
    $O365.token.accessToken = $TokenRequest.access_token;
    $O365.token.tokenExpires = [DateTime]::Now.AddSeconds($TokenRequest.expires_in - 300); #give us a 5 min window to reauthenticate
    $O365.authHeader = @{
        "Authorization" = "Bearer $($O365.token.accessToken)" 
    }   

# login complete
if($o365.token.accessToken){"login complete"}else{"login failed"}

#############################################################################
# Part 2 - Update user certificate mappings
# begin cert mapping import

# import user mapping file, mappings comma separated
$userMappings = import-csv .\user-mappings.csv
# convert comma separated mappings to property array
foreach($user in $userMappings){$user.mappings = $user.mappings.split(",")}

# iterate each obj in csv
foreach($user in $userMappings){

	# load userid
	$userId = $user.userid
	$certUserIdObj = $user.mappings
	Write-host "Updating certificate user IDs for user: $userId" -f yellow

	# Prepare the request body
	$body = @{
		authorizationInfo = @{
			certificateUserIds = $certUserIdObj
		} }

	$jsonBody = ConvertTo-Json -InputObject $body -Depth 10

    $resourceURL = $o365.token.resourceURL
	
	# build apicall url, update for GCC/DOD endpoint 
	$apiCallUrl = "$resourceURL/v1.0/users/$userId"
	#$response = Invoke-RestMethod -Uri "$apiCallUrl" -Method PATCH -Headers $o365.authheader -erroraction stop -Body $jsonBody
    $response = Invoke-RestMethod -Uri "$apiCallUrl" -Method PATCH -Headers $o365.authheader -erroraction stop -Body $jsonbody -ContentType "application/json"

# close foreach user in csv
}
