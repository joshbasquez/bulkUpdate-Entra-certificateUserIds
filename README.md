# bulkUpdate-Entra-certificateUserIds

script and csv to perform bulk update of certificate user IDs in Entra for cert based auth

Part 1 of the script performs a web based login to authenticate to Entra using the Azure AD Powershell Enterprise AppID

Part 2 of the script iterates thru the rows in the csv file (sample provided) for each userid, add the userCertificateID mappings
Note: mappings can contain multiple values, ensure multiple values are a comma separated string
i.e. X509:<SKI>1111111111111111,X509:<RFC822>testuser@yahoo.com

# Check certificate user id value for a given user:
(must run part 1 of script to authenticate and generate the token authheader)

$x =Invoke-RestMethod -headers $o365.authHeader -uri "https://graph.microsoft.com/v1.0/users/b9d9xxxxx-xxxxx-xxxxx?`$select=id,mail,authorizationInfo";
$x.authorizationInfo

example output:

certificateUserIds          
------------------          
{X509:<SKI>1111111111111111,X509:<RFC822>testuser@yahoo.com}

