// Configure Payment Gateway
PaymentGatewayProvider paymentGatewayProvider = [SELECT Id FROM PaymentGatewayProvider LIMIT 1];
NamedCredential namedCredential = [SELECT Id FROM NamedCredential WHERE DeveloperName = 'StripeAdapter_NC' LIMIT 1];
PaymentGateway paymentGateway = new PaymentGateway(
        PaymentGatewayName = 'SM Stripe Payment Gateway',
        MerchantCredentialId = namedCredential.Id,
        PaymentGatewayProviderId = paymentGatewayProvider.Id,
        Status = 'Active'
);

insert paymentGateway;

List<StoreIntegratedService> storeIntegratedServiceList = [SELECT Id FROM StoreIntegratedService WHERE ServiceProviderType = 'Payment'];
for(StoreIntegratedService storeintegration: storeIntegratedServiceList){
        storeintegration.Integration = paymentGateway.Id;
}

update storeIntegratedServiceList;