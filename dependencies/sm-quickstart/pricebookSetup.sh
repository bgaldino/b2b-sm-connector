#!/bin/sh
export SFDX_NPM_REGISTRY="http://platform-cli-registry.eng.sfdc.net:4880/"
export SFDX_S3_HOST="http://platform-cli-s3.eng.sfdc.net:9000/sfdx/media/salesforce-cli"

cd dependencies/sm-quickstart

# Activate Standard Pricebook
orgAlias=$1

echo "Getting Standard Pricebook for Pricebook Entries and replacing in data files"
pricebook1=$(sfdx force:data:soql:query -u $orgAlias -q "SELECT Id FROM Pricebook2 WHERE Name='Standard Price Book' AND IsStandard=true LIMIT 1" -r csv | tail -n +2)
sleep 1

if [ -n "$pricebook1" ]; then
  sed -e "s/\"Pricebook2Id\": \"PutStandardPricebookHere\"/\"Pricebook2Id\": \"${pricebook1}\"/g" data/PricebookEntry-template.json >data/PricebookEntry.json

  echo $pricebook1
else
  echo "Could not determine Standard Pricebook.  Exiting."
fi


echo "Activating Standard Pricebook"
if [ -n "$pricebook1" ]; then
  sfdx force:data:record:update -s Pricebook2 -i $pricebook1 -v "IsActive=true" -u $orgAlias
  sleep 1
else
  echo "Could not determine Standard Pricebook.  Exiting."
fi

echo "get proration"
proration=$(sfdx force:data:soql:query -u $orgAlias -q "select id from ProrationPolicy LIMIT 1" -r csv | tail -n +2)
sleep 1


#get existing proration and  do setup
if [ -n "$proration" ]; then
  sed -e "s/\"ProrationPolicyId\": \"INSERT_PORATION_ID\"/\"ProrationPolicyId\": \"${proration}\"/g" data/ProductSellingModelOption-template.json >data/ProductSellingModelOption.json

  echo $proration
else
  echo "Could not determine proration.  Exiting."
fi

#get existing catalog  andf do setup
catalog=$(sfdx force:data:soql:query -u $orgAlias -q "select Id from ProductCatalog LIMIT 1" -r csv | tail -n +2)
if [ -n "$catalog" ]; then
  sed -e "s/\"CatalogId\": \"INSERT_CATALOG\"/\"CatalogId\": \"${catalog}\"/g" data/ProductCategory-template.json >data/ProductCategory.json

  echo $catalog
else
  echo "Could not determine catalog.  Exiting."
fi

#get B2B catalog and do setup with with subscription product
policy=$(sfdx force:data:soql:query -u $orgAlias -q "select Id from CommerceEntitlementPolicy LIMIT 1" -r csv | tail -n +2)
if [ -n "$catalog" ]; then
  sed -e "s/\"PolicyId\": \"INSERT_ENTITLEMENT\"/\"PolicyId\": \"${policy}\"/g" data/CommerceEntitlementProducts-template.json >data/CommerceEntitlementProducts.json

  echo $catalog
else
  echo "Could not determine entitlement.  Exiting."
fi

#update apex class id in taxEngineProvider
apexClass=$(sfdx force:data:soql:query -u $orgAlias -q "select Id from ApexClass where Name = 'MockAdapter' LIMIT 1" -r csv | tail -n +2)
if [ -n "$apexClass" ]; then
  sed -e "s/\"ApexAdapterId\": \"INSERT_TAX_CLASS_ID_HERE\"/\"ApexAdapterId\": \"${apexClass}\"/g" data/TaxEngineProviderTemplate.json >data/TaxEngineProvider.json

  echo $apexClass
else
  echo "Could not determine mock tax apex class.  Exiting."
fi

#update Named Cred id in taxEngine
namedCred=$(sfdx force:data:soql:query -u $orgAlias -q "select Id from NamedCredential LIMIT 1" -r csv | tail -n +2)
if [ -n "$namedCred" ]; then
 sed  -e "s/\"MerchantCredentialId\": \"INSERT_NAMED_CRED_ID\"/\"MerchantCredentialId\": \"${namedCred}\"/g" data/TaxEngineTemplate.json >data/TaxEngine.json

  echo "anmed cred"$namedCred
else
  echo "Could not determine entitlement.  Exiting."
fi

echo "Pushing Tax & Billing Policy Data to the Org"
sfdx force:data:tree:import -p data/data-plan-1.json -u $orgAlias
echo ""

echo "Activating Tax & Billing Policies and Updating Product2 data records with Activated Policy Ids"
scripts/pilot-activate-tax-and-billing-policies.sh  $orgAlias
echo ""

echo "Pushing Product & Pricing Data to the Org" 
# Choose to seed data with all SM Product setup completed or choose the base option to not add PSMO and PBE for use in workshops
sfdx force:data:tree:import -p data/data-plan-2.json -u $orgAlias

#create Entry for custom priceList for subscription product
echo "Build Serach Index"
sfdx force:apex:execute -f scripts/createCustomPricebookEntry.apex -u $orgAlias
