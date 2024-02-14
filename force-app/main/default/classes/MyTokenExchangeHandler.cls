public class MyTokenExchangeHandler extends Auth.Oauth2TokenExchangeHandler{

    public override Auth.TokenValidationResult validateIncomingToken(
            String appDeveloperName, 
            Auth.IntegratingAppType appType, 
            String incomingToken, 
            Auth.OAuth2TokenExchangeType tokenType) {
        
        // ensure JWT
        if (tokenType != Auth.OAuth2TokenExchangeType.JWT) {
            return new Auth.TokenValidationResult(false, null, null, incomingToken, tokenType, 'Expected a JWT token');
        }

        // validate the signature
        String sub; 
        String iss;
        try {
            final Auth.JWT jwt = Auth.JWTUtil.validateJWTWithCert(incomingToken, 'Demo_Certificate');
            sub = jwt.getSub();
            iss = jwt.getIss();
            if (iss != 'demoapp.example.com') {
                return new Auth.TokenValidationResult(false, null, null, incomingToken, tokenType, 'Invalid issuer in JWT token');    
            }

        } catch (Exception e) {
            //return new Auth.TokenValidationResult(false, null, null, incomingToken, tokenType, 'Invalid JWT token received');
        }
        
        // coming here means we validated the JWT
        final Auth.UserData userdata = new Auth.UserData(
            null,
            null,
            null, 
            null, 
            null, 
            null, 
            sub,
            null,
            iss,
            null, 
            null);
        return new Auth.TokenValidationResult(true, null, userdata, incomingToken, tokenType, null);
    }

    public override User getUserForTokenSubject(
        Id networkId, 
        Auth.TokenValidationResult result, 
        Boolean canCreateUser, 
        String appDeveloperName, 
        Auth.IntegratingAppType appType) {

        // get username and find user
        final Auth.UserData userdata = result.userData;
        final User user = [SELECT Id FROM User where Username =: userdata.username ] ?? NULL;
        return user;
    }
}

