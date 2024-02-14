@RestResource(urlMapping='/code/extraction')
global class HeadlessIdentityCodeExtractor {
    @HttpGet
    global static CodeResponse doGet() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        try {
            res.statusCode = 200;
            return new CodeResponse(
                req.params.get('code'), 
                req.params.get('sfdc_community_url'), 
                req.params.get('sfdc_community_id'), 
                req.params.get('state')
            );
        } catch (Exception e) {
            res.statusCode = 500;
            return new CodeResponse('Could not parse auth code redirect URI');
        }
    }
  
   // Response Wrapper
   global class CodeResponse {
       String code;
       String sfdc_community_url;
       String sfdc_community_id;
       String state;
       Boolean success;
       String errMsg;
      
       public CodeResponse(String code, String sfdc_community_url, String sfdc_community_id, String state) {
           this.code = code;
           this.sfdc_community_url = sfdc_community_url;
           this.sfdc_community_id = sfdc_community_id;
           this.state = state;
           this.success = true;
       }
      
        public CodeResponse(String errMsg) {
           this.success = false;
           this.errMsg = this.errMsg;
       }       
   }
}