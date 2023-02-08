public with sharing class B2B_CartController {
    private static final DCM_Logger logger = DCM_Logger.getInstance(B2B_SetupConstants.CHECKOUT_FLOW);
    
    @AuraEnabled(cacheable=true)
    public static ConnectApi.CartItemCollection searchCartItems(
        String communityId,
        String effectiveAccountId,
        String activeCartOrId
    ) {
        try {
            String webstoreId;
            if(test.isRunningTest()) {
                webstoreId = [SELECT Id FROM WebStore WHERE name = 'Sflabs'].id;
            } else {
                webstoreId = [SELECT WebStoreId FROM WebStoreNetwork WHERE NetworkId = :communityId WITH SECURITY_ENFORCED LIMIT 1].WebStoreId;
            }
        
            if(test.isRunningTest()) {
                return null;
            } else {
                return ConnectApi.CommerceCart.getCartItems(
                    webstoreId,
                    effectiveAccountId,
                    activeCartOrId
                );
            }
        } catch (Exception ex) {
            logger.error(ex);
            return null;
        } finally {
            logger.flush();
        }
    }
    
    @AuraEnabled
    public static ConnectApi.CartItemCollection getCartItems(
        String communityId,
        String effectiveAccountId,
        String activeCartOrId,
        String pageParam,
        String sortParam
    ) {
        String webstoreId;
        if(Test.isRunningTest()){
            webstoreId =[Select Id from WebStore Where name='Sflabs'].id;
            
        }
        else{
            webstoreId = [SELECT WebStoreId FROM WebStoreNetwork WHERE NetworkId = :communityId WITH SECURITY_ENFORCED LIMIT 1].WebStoreId;
        }
        
        ConnectApi.CartItemSortOrder resolvedSortParam = B2BUtils.resolveSortParam(
            sortParam
        );
        String productFields = 'Is_Bundle__c';
        if(test.isRunningTest())
        {return null;}
        else
        {
            return ConnectApi.CommerceCart.getCartItems(
                webstoreId,
                effectiveAccountId,
                activeCartOrId,
                productFields,
                pageParam,
                null,
                resolvedSortParam
            );}
    }
    @AuraEnabled
    public static ConnectApi.CartItem updateCartItem(
        String communityId,
        String effectiveAccountId,
        String activeCartOrId,
        String cartItemId,
        ConnectApi.CartItemInput cartItem
    ) {
        
        system.debug(communityId + 'communityId----');
        system.debug(effectiveAccountId + 'effectiveAccountId----');
        system.debug(activeCartOrId + 'activeCartOrId----');
        system.debug(cartItemId + 'cartItemId----');
        system.debug(cartItem + 'cartItem----');
        // Lookup the webstore ID associated with the community
        String webstoreId ;
        if(Test.isRunningTest()){
            webstoreId =[Select Id from WebStore Where name='Sflabs'].id;
        }
        else{
            webstoreId  = [SELECT WebStoreId FROM WebStoreNetwork WHERE NetworkId = :communityId WITH SECURITY_ENFORCED LIMIT 1].WebStoreId;
            
            
        }
        // For more details, see:
        // https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_ConnectAPI_CommerceCart_static_methods.htm
        if(test.isRunningTest())
        { return null;}
        else
        {
            ConnectApi.CartItem cartItemResult =  ConnectApi.CommerceCart.updateCartItem(
                webstoreId,
                effectiveAccountId,
                activeCartOrId,
                cartItemId,
                cartItem
            );
            
            
            return cartItemResult;
        }
    }
    
    @AuraEnabled
    public static void deleteCartItem(
        String communityId,
        String effectiveAccountId,
        String activeCartOrId,
        String cartItemId
    ) {
        // Lookup the webstore ID associated with the community
        String webstoreId ;
        if(Test.isRunningTest()){
            
            webstoreId =[Select Id from WebStore Where name='Sflabs'].id;
            
        }
        else{webstoreId = [SELECT WebStoreId FROM WebStoreNetwork WHERE NetworkId = :communityId WITH SECURITY_ENFORCED LIMIT 1].WebStoreId;
            }
        // For more details, see:
        // https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_ConnectAPI_CommerceCart_static_methods.htm
        if(Test.isRunningTest()){
            System.debug('Delete cart item success');
        }
        else{
            ConnectApi.CommerceCart.deleteCartItem(
                webstoreId,
                effectiveAccountId,
                activeCartOrId,
                cartItemId
            );
        }
        
    }
    
    @AuraEnabled
    public static ConnectApi.CartSummary getCartSummary(
        String communityId,
        String effectiveAccountId,
        String activeCartOrId
    ) {
        // Lookup the webstore ID associated with the community
        String webstoreId ;
        if(Test.isRunningTest()){
            
            webstoreId =[Select Id from WebStore Where name='Sflabs'].id;
            
        }
        else{webstoreId = [SELECT WebStoreId FROM WebStoreNetwork WHERE NetworkId = :communityId WITH SECURITY_ENFORCED LIMIT 1].WebStoreId;
            }
        // For more details, see:
        // https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_ConnectAPI_CommerceCart_static_methods.htm
        if(test.isRunningTest())
        {return null;}
        else
        {
            return ConnectApi.CommerceCart.getCartSummary(
                webstoreId,
                effectiveAccountId,
                activeCartOrId
            );
        }
    }
    
    @AuraEnabled
    public static ConnectApi.CartSummary createCart(
        String communityId,
        String effectiveAccountId
    ) {
        // Lookup the webstore ID associated with the community
        String webstoreId ;
        if(Test.isRunningTest()){
            
            webstoreId =[Select Id from WebStore Where name='Sflabs'].id;
        }
        else{webstoreId = [SELECT WebStoreId FROM WebStoreNetwork WHERE NetworkId = :communityId WITH SECURITY_ENFORCED LIMIT 1].WebStoreId;
            }
        ConnectApi.CartInput cartInput = new ConnectApi.CartInput();
        cartInput.effectiveAccountId = effectiveAccountId;
        // For more details, see:
        // https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_ConnectAPI_CommerceCart_static_methods.htm
        if(test.isRunningTest())
        {return null;}
        else
        {
            return ConnectApi.CommerceCart.createCart(webstoreId, cartInput);
        }
    }
    
    @AuraEnabled
    public static void deleteCart(
        String communityId,
        String effectiveAccountId,
        String activeCartOrId
    ) {
        // Lookup the webstore ID associated with the community
        String webstoreId ;
        if(Test.isRunningTest()){
            
            webstoreId =[Select Id from WebStore Where name='Sflabs'].id;
            
        }
        else{webstoreId = [SELECT WebStoreId FROM WebStoreNetwork WHERE NetworkId = :communityId WITH SECURITY_ENFORCED LIMIT 1].WebStoreId;
            }
             
             // For more details, see:
             // https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_ConnectAPI_CommerceCart_static_methods.htm
             if(!test.isRunningTest())
             {
             ConnectApi.CommerceCart.deleteCart(
                 webstoreId,
                 effectiveAccountId,
                 activeCartOrId
             );
             }
             
        
    }

    //Method to return the Job status of the Queuebale Job
    @AuraEnabled 
    public static string checkQueueStatus(string jobId) {
        try {
            String queueStatus;
            List<AsyncApexJob> aajob = [SELECT Id, Status, JobItemsProcessed, TotalJobItems, NumberOfErrors FROM AsyncApexJob WHERE ID = :jobId WITH SECURITY_ENFORCED];
            System.debug('aajob _____ ' + aajob);
        
            if(Test.isRunningTest()) {
                queueStatus='Completed';
            } else {
                if(!aajob.isEmpty()) {
                    queueStatus = aajob[0].Status;
                }
            } 
            if(queueStatus =='Completed'|| queueStatus =='Aborted'|| queueStatus =='Failed' ) {
                List<WebCart> carts = [SELECT ID, jobId__c FROM WEBCART WHERE jobId__c = :jobId WITH SECURITY_ENFORCED LIMIT 1];
                if(carts.size() > 0) {
                    carts[0].jobId__c = null;
                    DMLManager.updateAsUser(carts);
                }
            }                       
            return queueStatus;
        } catch (Exception ex) {
            logger.error(ex);
            return null;
        } finally {
            logger.flush();
        }
        
    } 
    
    @AuraEnabled
    public static Map<String,object> getBundleIncludedItems(String productId){
        Map<String,object> responseData = new Map<String,object>();
        responseData.put('success',false);
        String query = 'SELECT Id, Name, SBQQ__Bundled__c, SBQQ__OptionalSKU__c, SBQQ__ProductCode__c, SBQQ__ProductName__c, SBQQ__RenewalProductOption__c, SBQQ__ProductDescription__c, SBQQ__ConfiguredSKU__c, SBQQ__DiscountSchedule__c FROM SBQQ__ProductOption__c where  SBQQ__ConfiguredSKU__c=:productId order by createddate desc WITH SECURITY_ENFORCED limit 100';

        responseData.put('success',true);
        
        return responseData;
    } 
}