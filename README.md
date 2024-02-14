# salesforce-tokenexchange-poc #
This repo describes how to configure Salesforce to use the token exchange flow and how to try it out against a user in an actual org. The token exchange flow works by having an Apex handler in Salesforce that is called to validate the supplied token and return - or optionally create - a user matching the token in Salesforce. The Apex handler for this example can be found at `force-app/main/default/MyTokenExchangeHandler.cls` in this repo. The implementation validates an incoming JWT minted and signed outside Salesforce with a public key from Certificate and Key Management.

## Requirements ##
Below I assume you have the following installed and you know how to work the terminal.

* The Salesforce CLI installed and a Dev Hub configured
* `jq` 
* `curl`
* `openssl`
* Java `keytool` (comes with a JDK)

## Configuration ## 
Create a scratch, and configure it to allow Experience Cloud users to be created.
```
sf org create scratch --set-default -f config/project-scratch-def.json
sf project deploy start -m Role
ROLE_ID=`sf data query --query "select Id from UserRole where Name='Dummy'" --json | jq ".result.records[0].Id" -r`
sf data update record -s User -w "Name='User User'" -v "LanguageLocaleKey=en_US TimeZoneSidKey=Europe/Paris LocaleSidKey=da UserPreferencesUserDebugModePref=true UserPreferencesApexPagesDeveloperMode=true UserPermissionsInteractionUser=true UserPermissionsKnowledgeUser=true UserRoleId=$ROLE_ID"
sf project deploy start -m ApexClass -m ApexComponent -m ApexPage -m Profile -m DigitalExperienceBundle -m DigitalExperienceConfig -m CustomSite -m Network -m Settings
```

In Salesforce Setup go to Certificate and Key Management and create a self-signed certificate in named `Demo Certificate` (API name: `Demo_Certificate`). From the list of certificates export the certificate and private key as a Java keystore and note the location. Below I assume it was saved as [org id].jks in `~/Downloads`.

Now and run the following commands to convert to PKCS12 format and extract the private key in PEM format from the PKCS12 file using OpenSSL (new file also saved in `~/Downloads`):
```
ORG_ID=` sf org display --json | jq .result.id -r | cut -c 1-15`
keytool -importkeystore -srckeystore ~/Downloads/$ORG_ID.jks -destkeystore ~/Downloads/$ORG_ID.p12 -srcstoretype jks -deststoretype pkcs12
openssl pkcs12 -in ~/Downloads/$ORG_ID.p12 -nodes -nocerts
```

In Salesforce Setup create a Connected App with API name `Test_Token_Exchange` and ensure enable `Enable Token Exchange Flow` and `Require Secret for Token Exchange Flow` and select appropriate scopes (I just selected `api` scope). Then save and edit the policy and set `Admin approved users are pre-authorized` for Permitted Users and check the `Enable Token Exchange Flow` here as well. If you forget that you'll get an `app not enabled for token exchange` error later. Also ensure you add the Connected App to the `CC Demo User` profile.

Now create a demo user in Salesforce with the below script.
```
sf apex run -f scripts/apex/create_demouser_johndoe.apex
```

Next edit the `metadata-deploy/oauthtokenexchangehandlers/MyTokenExchangeHandler.oauthtokenexchangehandler` file in this repo and specify the username to run the Apex class as before deploy. Now deploy the OAuth Token Exchange Handler metadata definition using the old school metadata API (as of February 2024 it's not supported by the new source format yet).
```
sf project deploy start --metadata-dir=./metadata-deploy
```

Using the Debugger on the [jwt.io](https://jwt.io) website create a new JWT. Set the algorithm to `RS256`, paste in the private key in PEM format you extracted above and sign a JWT with the following payload:
```
{
  "sub": "john.doe@example.com",
  "iss": "demoapp.example.com",
  "aud": "salesforce.example.com", 
  "iat": 1516239022
}
```

From the Connected App in Salesforce Setup get the `client_id` and the `client_secret` and craft a request to exchange your JWT for a Salesforce access_token. Below is an example of using `curl` to do the exchange. 
```
MYJWT=eyJhbGciOi...R9sTuAR9p8xY
MYCLIENT_ID=3MVG9L...mGgVtBU
MYCLIENT_SECRET=54FF...C870
MYDOMAIN=`sf org display --json | jq .result.instanceUrl -r`

curl -X POST $MYDOMAIN/services/oauth2/token -d "grant_type=urn:ietf:params:oauth:grant-type:token-exchange&subject_token=$MYJWT&subject_token_type=urn:ietf:params:oauth:token-type:jwt&client_id=$MYCLIENT_ID&client_secret=$MYCLIENT_SECRET&scope=api&token_handler=MyTokenExchangeHandler" -H "Content-Type: application/x-www-form-urlencoded" 
```