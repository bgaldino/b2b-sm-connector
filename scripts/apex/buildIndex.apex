Webstore  store = [SELECT Id FROM WebStore LIMIT1];
system.debug(store.Id);
ConnectApi.CommerceSearchSettings.createCommerceSearchIndex(String.valueOf(store.Id));