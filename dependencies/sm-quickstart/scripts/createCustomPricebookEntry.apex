List<String> productCodeList =new List<String> {'SUB-M','SUB-T-M','SUB-E-M','ONETIME'};
List<PricebookEntry> insertList = new List<PricebookEntry>();
Pricebook2 pb = [select Id,name from Pricebook2 where name = 'BASIC_PRICEBOOK_FROM_QUICKSTART' LIMIT 1];

for(PricebookEntry PBE : [select Id,name,ProductCode,UnitPrice, IsActive, Product2Id, Pricebook2Id, ProductSellingModelId  from PricebookEntry where productCode IN :productCodeList]){
    PricebookEntry clonePBE  = PBE.clone(false, false, false, false);
    clonePBE.Pricebook2Id = pb.Id;
    insertList.add(clonePBE);
}

insert insertList;


// List<String> productCodeList =new List<String> {'SUB-M','SUB-T-M','SUB-E-M','ONETIME'};
// Map<String,String> productCodeMap = new Map<String,String>();
// Map<String,String> PSMMap = new Map<String,String>();
// Pricebook2 pb = [select Id,name from Pricebook2 where name = 'BASIC_PRICEBOOK_FROM_QUICKSTART' LIMIT 1];


// for(product2 product : [select id,name,ProductCode from product2 where ProductCode=:productCodeList]){
//     productCodeMap.put(product.ProductCode,product.Id);
// }

// for(ProductSellingModel PSM : [select Id,name,PricingTerm from ProductSellingModel]){
//    PSMMap.put(PSM.name,PSM.id);
// }

// List<PricebookEntry> entry = new List<PricebookEntry>();
// entry.add(new PricebookEntry(IsActive= true,UnitPrice= 1000,UseStandardPrice= false, Product2Id=productCodeMap.get('ONETIME'),ProductSellingModelId= PSMMap.get('One-Time'),Pricebook2Id= pb.Id));
// entry.add(new PricebookEntry(IsActive= true,UnitPrice= 100,UseStandardPrice= false, Product2Id=productCodeMap.get('SUB-E-M'),ProductSellingModelId= PSMMap.get('Evergreen Monthly'),Pricebook2Id= pb.Id));
// entry.add(new PricebookEntry(IsActive= true,UnitPrice= 500,UseStandardPrice= false, Product2Id=productCodeMap.get('SUB-T-M'),ProductSellingModelId= PSMMap.get('Term Monthly'),Pricebook2Id= pb.Id));
//  entry.add(new PricebookEntry(IsActive= true,UnitPrice= 25,UseStandardPrice= false, Product2Id=productCodeMap.get('SUB-M'),ProductSellingModelId= PSMMap.get('Evergreen Monthly'),Pricebook2Id= pb.Id));
//  entry.add(new PricebookEntry(IsActive= true,UnitPrice= 35,UseStandardPrice= false, Product2Id=productCodeMap.get('SUB-M'),ProductSellingModelId= PSMMap.get('Term Monthly'),Pricebook2Id= pb.Id));

// system.debug(entry);

// insert entry;

