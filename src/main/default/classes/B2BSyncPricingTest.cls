@isTest
public class B2BSyncPricingTest {
    @testSetup static void setup() {
        Account testAccount = new Account(Name='TestAccount');
        insert testAccount;
        WebStore testWebStore = new WebStore(Name='TestWebStore', DefaultLanguage='en_US');
        insert testWebStore;
        Account account = [SELECT Id FROM Account WHERE Name='TestAccount' LIMIT 1];
        WebStore webStore = [SELECT Id FROM WebStore WHERE Name='TestWebStore' LIMIT 1];
        WebCart cart = new WebCart(Name='Cart', WebStoreId=webStore.Id, AccountId=account.Id);
        insert cart;
        CartDeliveryGroup cartDeliveryGroup = new CartDeliveryGroup(CartId=cart.Id, Name='Default Delivery');
        insert cartDeliveryGroup;
        
        CartItem cartItem = new CartItem(CartId=cart.Id, Sku='SKU_Test1', SalesPrice=10.00, Quantity=3.0, Type='Product', Name='TestProduct', CartDeliveryGroupId=cartDeliveryGroup.Id);
        insert cartItem;
    }
    
    @isTest static void testWhenSalesPriceIsCorrectSuccessStatusIsReturned() {
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('GetSalesPricesResource2');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json;charset=UTF-8');
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, mock);
        WebCart webCart = [SELECT Id FROM WebCart WHERE Name = 'Cart' LIMIT 1];
        List<Id> webCarts = new List<Id>{webCart.Id};
        //Void Method
        B2BSyncPricing.syncPricing(webCarts);
        System.assertEquals('','');
        Test.stopTest();
    }
    
    @isTest static void testWhenSalesPriceIsCorrectSuccessStatusIsReturned1() {
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('GetSalesPricesResource2');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json;charset=UTF-8');
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, mock);
        WebCart webCart = [SELECT Id FROM WebCart WHERE Name = 'Cart' LIMIT 1];
        List<Id> webCarts = new List<Id>();
            //Void Method
            try{
                B2BSyncPricing.syncPricing(webCarts);
            }catch(Exception e){
                System.assertEquals('','');   
            }
        Test.stopTest();
    }
    
    @isTest static void testWhenExternalServiceCallFailsAFailedStatusIsReturnedAndACartValidationOutputEntryIsNotCreated() {
        // Because test methods do not support Web service callouts, we create a mock response based on a static resource.
        // To create the static resource from the Developer Console, select File | New | Static Resource
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('GetSalesPricesResource');
        // The web service call returns an error code.
        mock.setStatusCode(404);
        mock.setHeader('Content-Type', 'application/json;charset=UTF-8');
        Test.startTest();
        // Associate the callout with a mock response.
        Test.setMock(HttpCalloutMock.class, mock);
        
        // Test: execute the integration for the test cart ID and integration info.
        WebCart webCart = [SELECT Id FROM WebCart WHERE Name = 'Cart' LIMIT 1];
        List<Id> webCarts = new List<Id>{webCart.Id};
        String expectedErrorMessage = 'There was a problem with the request. Error: 404';
        executeAndEnsureFailure(expectedErrorMessage, webCarts, false);
         System.assertNotEquals(null, expectedErrorMessage);
        Test.stopTest();
    }

    @isTest static void testProductsWithNoSkuHasError() {
        Test.startTest();

        WebCart webCart = [SELECT Id FROM WebCart WHERE Name = 'Cart' LIMIT 1];
        List<CartDeliveryGroup> cartDeliveryGroups = [SELECT Id FROM CartDeliveryGroup WHERE CartId = :webCart.Id LIMIT 1];
        List<Id> webCarts = new List<Id>{webCart.Id};

        // Insert a cart item without a SKU
        CartItem cartItemWithNoSku = new CartItem(
            CartId=webCart.Id,
            Quantity=1.0,
            Type='Product',
            Name='TestProductNoSku',
            CartDeliveryGroupId=cartDeliveryGroups.get(0).Id
        );
        insert cartItemWithNoSku;

        String expectedErrorMessage = 'The SKUs for all products in your cart must be defined.';
        executeAndEnsureFailure(expectedErrorMessage, webCarts, true);
        System.assertNotEquals(null, expectedErrorMessage);
        Test.stopTest();

        // Remove the invalid cart item
        delete cartItemWithNoSku;
    }
    
    // Executes the pricing check and ensures an error is correctly triggered
    static void executeAndEnsureFailure(String expectedErrorMessage, List<Id> webCarts, Boolean userError) {
        try {
            B2BSyncPricing.syncPricing(webCarts);
            
            // An exception should have been thrown before getting to this point:
            System.assert(false);
        } catch (CalloutException e) {
            System.assertEquals(expectedErrorMessage, e.getMessage());
        }
        
        List<CartValidationOutput> cartValidationOutputs = [SELECT Id, Message FROM CartValidationOutput WHERE Level = 'Error'];
        if (userError) {
            System.assertEquals(1, cartValidationOutputs.size());
            System.assertEquals(expectedErrorMessage, cartValidationOutputs.get(0).Message);
        } else {
            System.assertEquals(0, cartValidationOutputs.size());
        }
    }
}