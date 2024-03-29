/**
 * @description       : 
 * @author            : Prabhat Kumar
 * @group             : 
 * @last modified on  : 05-20-2022
 * Modifications Log 
 * This class is used to handle Billing and Shipping address and renewal payment.
**/

global with sharing class RSM_PaymentMethod {

    private static final DCM_Logger logger = DCM_Logger.getInstance(B2B_SetupConstants.BUYER_INFO_UPDATE);

    @AuraEnabled
    global static integer getAssetMonths(string assetId){

        integer numberOfMonths;
        try {


            List<Asset> assetList = [SELECT id, LifecycleStartDate, CurrentAmount, LifecycleEndDate, CurrentQuantity from asset where id =: assetId WITH SECURITY_ENFORCED limit 1];

            if(assetList.size() > 0){

                if(assetList[0].LifecycleEndDate != null){

                    date startDate = date.newinstance(assetList[0].LifecycleStartDate.year(), assetList[0].LifecycleStartDate.month(), assetList[0].LifecycleStartDate.day());

                    date endDate = date.newinstance(assetList[0].LifecycleEndDate.year(), assetList[0].LifecycleEndDate.month(), assetList[0].LifecycleEndDate.day());

                    numberOfMonths = startDate.monthsBetween(endDate); //(startDate - endDate) / 365 * 12;

                }

            }
           
            
        } catch(Exception e) {
            logger.error(e);
            throw new AuraHandledException(e.getMessage());
            
        } finally {
            logger.flush();
        }

        return numberOfMonths;
    }

    /**
     * This method is called from Manage Subscription page to udpate Shipping Address details.
     * 
    **/
    @AuraEnabled
    public static void updateShippingAddress(string shippingAddress){
       try {
   
           Map<String, Object> m =   (Map<String, Object>) JSON.deserializeUntyped(shippingAddress);
           string a =  (string)m.get('Id');
           string streetAdd =  (string)m.get('Street');
           string city = (string)m.get('City');
           string State = (string)m.get('State');
           string County = (string)m.get('Country');
           String ZipCode = (string)m.get('PostalCode');
           System.debug('item:' + a); 
           ContactPointAddress contactPointOfAddress = new ContactPointAddress(id=a, street = streetAdd, City = city, State = State, Country = County, PostalCode = zipCode);

           DMLManager.updateAsUser(contactPointOfAddress);

        } catch(Exception e) {
            logger.error(e);
            throw new AuraHandledException(e.getMessage());
        } finally {
            logger.flush();
        }
    }


/**
 * This method is called from Manage Subscription page to udpate Billing Address details.
 * 
**/
 @AuraEnabled
 public static void updateBillingAddress(string billingAddress){
    try {

        Map<String, Object> m =   (Map<String, Object>) JSON.deserializeUntyped(billingAddress);
        string a =  (string)m.get('Id');
        string streetAdd =  (string)m.get('Street');
        string city = (string)m.get('City');
        string State = (string)m.get('State');
        string County = (string)m.get('Country');
        String ZipCode = (string)m.get('PostalCode');
        System.debug('item:' + a); 
        ContactPointAddress contactPointOfAddress = new ContactPointAddress(id=a, street = streetAdd, City = city, State = State, Country = County, PostalCode = zipCode);

            DMLManager.updateAsUser(contactPointOfAddress);

        } catch(Exception e) {
            logger.error(e);
            throw new AuraHandledException(e.getMessage());
        } finally {
            logger.flush();
        }
 }

/**
 * This method is called from Manage Subscription page to show Addresses.
 * 
**/
 @AuraEnabled
 public static map<string, object> getBillingShippingAddress(){

    Map<String, Object> result = new map<String, Object>();
    try {

       
        id accountId = [ SELECT Id, accountId FROM User WHERE Id = : UserInfo.getUserId() WITH SECURITY_ENFORCED].accountId;
        
        list<ContactPointAddress> listContactAddress = [select id, name, AddressType, country, city, State, street, PostalCode from ContactPointAddress where parentId =: accountId and IsDefault = true WITH SECURITY_ENFORCED];

        if(listContactAddress.size() == 2){

            for(ContactPointAddress contactPoint : listContactAddress){

                if(contactPoint.AddressType == 'Billing'){

                    result.put('Billing', contactPoint);

                }else{

                    result.put('Shipping', contactPoint);

                }
            }

            }else{

                result.put('No Address Found for this user', null);

            }


        
        
    } catch(Exception e) {
        logger.error(e);
        throw new AuraHandledException(e.getMessage());
    } finally {
        logger.flush();
    }

    return result;
 }

    /**
     * This method is called from Manage Subscriptin page to renew the Asset.
     * 
    **/
    @AuraEnabled
    global static map<string, object> renewAssetMethod(string assetId){
       
        Map<String,object> resultData = new Map<String,object>();
        try {
            
            
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            if(test.isRunningTest()){
                request.setHeader('Authorization', 'Bearer ');
            }else{
                request.setHeader('Authorization', 'Bearer ' + B2B_CreateUserAccessToken.getAdminAccessToken());
            }
            //request.setHeader('Authorization', 'Bearer ' + B2B_CreateUserAccessToken.getAdminAccessToken());
            String baseUrl = String.valueOf(Url.getOrgDomainUrl().toExternalForm());
            String renewAsset = '/services/data/v55.0/asset-management/assets/collection/actions/initiate-renewal';
            request.setMethod('POST'); 
            request.setHeader('Content-Type', 'application/json; charset=UTF-8');
            request.setEndpoint(baseUrl+renewAsset);
            String requestBody = '{' +
                '"assetIds": {' +
                  '"assetIdArray": [' +
                    '"' + assetId + '"' +
                  ']' +
                '}' +
              '}';  

            request.setBody(requestBody);
           
            system.debug(requestBody + 'requestBody----');
            HttpResponse response = http.send(request);
            // Parse the JSON response
            resultData.put('response',response.getBody());
                 System.debug('response: ' + response.getBody());
                if (response.getStatusCode() != 201) {
                System.debug('The status code returned was not expected: ' +
                response.getStatusCode() + ' ' + response.getStatus());
            } else {
                System.debug(response.getBody());
            }
  
        } catch(Exception e) {
            logger.error(e);
            throw new AuraHandledException(e.getMessage());
        } finally {
            logger.flush();
        }

        return resultData;
    }

     /**
     * Check if the Product is Evergreen or Term Based.
     * 
    **/
    @AuraEnabled
    public static boolean isEverGreenProduct(id assetId){
        boolean isEverGreen;
        try {
            
            List<Asset> assetList = [SELECT id, CurrentAmount, LifecycleEndDate, CurrentQuantity from asset where id =: assetId WITH SECURITY_ENFORCED limit 1];

            if(assetList.size() > 0){

                if(assetList[0].LifecycleEndDate != null){

                    isEverGreen = false;

                }else{

                    isEverGreen = true;
                }

            }

           
 
        } catch(Exception e) {
            logger.error(e);
            throw new AuraHandledException(e.getMessage());
        } finally {
            logger.flush();
        }
        return isEverGreen;
    }

    /**
     * Update Buyer info from Manage Subscription Page.
     * 
    **/
    @AuraEnabled
     public static void updateBuyerInfo(string name, string email, string phone){
         try {
             string firstName;
             String lastName;
  
             id contactId;
             Contact con;
  
             if(!Test.isRunningTest()) {
                 contactId = [ SELECT Id, contactId FROM User WHERE Id = : UserInfo.getUserId() WITH SECURITY_ENFORCED].contactId;
                 con = [SELECT ID, EMAIL, PHONE, NAME, FirstName, LastName FROM CONTACT WHERE ID =: contactId WITH SECURITY_ENFORCED limit 1];
                 //con = [SELECT ID, EMAIL, PHONE, NAME FROM CONTACT WHERE ID =: contactId WITH SECURITY_ENFORCED limit 1];
             } else {
                 con = [SELECT ID, EMAIL, PHONE, NAME, FirstName, LastName FROM CONTACT WITH SECURITY_ENFORCED  limit 1];
                 //con = [SELECT ID, EMAIL, PHONE, NAME FROM CONTACT limit 1];
                 contactId = con.Id;
             }
  
            if(con != null){

               
            
                    if(name != null){
                    
                        List <String> strList = name.split(' ');
                         System.debug( 'List String is ' + strList );
                         if(strList.size() == 2){
  
                             firstName = strList[0];
                             lastName = strList[1];
  
                         }else{
  
                             lastName = strList[0];
  
                         }
  
                         con.FirstName = firstName;
                         con.LastName = lastName;
                     }
                    // buynowCallout(fristname,LastName,contactId,email,phone);
                     
                     if(email != null){
  
                         con.Email = email;
                    }

                    if(phone != null){
  
                         con.phone = phone;
                     }
                    buynowCallout(con);
  
             /*if(!test.isRunningTest()){   
             if(!test.isRunningTest()){   
              DMLManager.updateAsUser(con);
             }else{
  
                 DMLManager.updateAsSystem(con);  
             }
             }*/
  
         }
  
        } catch(Exception e) {
            logger.error(e);
            throw new AuraHandledException(e.getMessage());
        } finally {
            logger.flush();
        }
    }

    /**
     * Display Purchaser Info on Manage Subscription page..
     * 
    **/
    @AuraEnabled
    public static Contact getPurchaserInfo(){

        Contact con = new Contact();
        try {

     
            id contactId = [ SELECT Id, contactId FROM User WHERE Id = : UserInfo.getUserId() WITH SECURITY_ENFORCED].contactId;
            con = [SELECT ID, EMAIL, PHONE, NAME FROM CONTACT WHERE ID =: contactId WITH SECURITY_ENFORCED limit 1];

            


        } catch(Exception e) {
            logger.error(e);
            throw new AuraHandledException(e.getMessage());
        } finally {
            logger.flush();
        }
        return con;
    }
    
    public static void buynowCallout(Contact con) {
            try{
            // screen flows do not run in bulk
                Map<String,Object> reqData = new Map<String,Object>();
                Map<String,Object> responseData = new Map<String,Object>();
     
                reqData.put('firstName', con.FirstName);
                reqData.put('lastName', con.LastName);
                reqData.put('contactId', con.Id);
                reqData.put('email', con.Email);
                reqData.put('phoneNumber', con.phone);
     
                String baseUrl = String.valueOf(Url.getOrgDomainUrl().toExternalForm());
                String endPointUrl;
                if(String.isNotBlank(baseUrl)){
                    endPointUrl = baseUrl + '/services/apexrest/r1sm/B2B_updateBuyerInfo/';
                    //endPointUrl = baseUrl + '/services/apexrest/r1sm/B2B_updateBuyerInfo/';
                }
     
                String accessTokenVal;
               if(!test.isRunningTest()) {
                    accessTokenVal = B2B_CreateUserAccessToken.getAdminAccessToken();
               } else { 
                   accessTokenVal= 'accessToken';
               }
     
                String auth = B2B_SetupConstants.BEARER+' '+accessTokenVal;
                System.debug('endPointUrl '+ endPointUrl);
                System.debug('request----  '+ JSON.serialize(reqData));
                
                Map<String,String> request1 = new Map<String,String>();
                request1.put(B2B_SetupConstants.AUTHORIZATION,auth);
                request1.put(B2B_SetupConstants.ENDPOINT,endPointUrl);
                request1.put(B2B_SetupConstants.BODY,JSON.serialize(reqData));
                //request1.put(B2B_SetupConstants.BODY,JSON.serialize(obj));
                request1.put(B2B_SetupConstants.METHOD,B2B_SetupConstants.POST);
                request1.put(B2B_SetupConstants.CONTENT,B2B_SetupConstants.APPLICATION_JSON);
     
                System.debug('request1 '+ request1);
                //System.debug('endPointUrl '+ request1);
     
     
                String response = B2B_RestApiCalls.httpCallOut(request1);
           } catch (Exception ex) {
               logger.error(ex);
           } finally {
               logger.flush();
           }
       }
    
   
}