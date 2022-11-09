#!/bin/sh
# This script will initialize the subscription management developer preview environment
#

orgAlias=$1

echo ${orgAlias}


defaultTaxTreatmentName="Default Tax Treatment"
defaultTaxPolicyName="Default Tax Policy"
defaultBillingTreatmentItemName="Default Billing Treatment Item"
defaultBillingTreatmentName="Default Billing Treatment"
defaultBillingPolicyName="Default Billing Policy"
defaultPaymentTermName="Default Payment Term"

function echo_attention() {
  local green='\033[0;32m'
  local no_color='\033[0m'
  echo "${green}$1${no_color}"
}

function error_and_exit() {
  echo "$1"
  exit 1
}

defaultTaxTreatmentId=$(sfdx force:data:soql:query -u $orgAlias -q "SELECT Id from TaxTreatment WHERE Name='$defaultTaxTreatmentName' LIMIT 1 " -r csv | tail -n +2)  
echo_attention defaultTaxTreatmentId=$defaultTaxTreatmentId
sleep 2

defaultTaxPolicyId=$(sfdx force:data:soql:query -u $orgAlias -q "SELECT Id from TaxPolicy WHERE Name='$defaultTaxPolicyName'  LIMIT 1" -r csv | tail -n +2) 
sleep 2

sfdx force:data:record:update -s TaxTreatment -i $defaultTaxTreatmentId -v "TaxPolicyId='$defaultTaxPolicyId' Status=Active" -u $orgAlias 
sleep 2

sfdx force:data:record:update -s TaxPolicy -i $defaultTaxPolicyId -v "DefaultTaxTreatmentId='$defaultTaxTreatmentId' Status=Active" -u $orgAlias 
sleep 2

defaultBillingTreatmentItemId=$(sfdx force:data:soql:query -u $orgAlias  -q "SELECT Id from BillingTreatmentItem WHERE Name='$defaultBillingTreatmentItemName'  LIMIT 1" -r csv | tail -n +2) 
echo_attention defaultBillingTreatmentItemId=$defaultBillingTreatmentItemId
sleep 2

defaultBillingTreatmentId=$(sfdx force:data:soql:query -u $orgAlias  -q "SELECT Id from BillingTreatment WHERE Name='$defaultBillingTreatmentName'   LIMIT 1" -r csv | tail -n +2) 
echo_attention defaultBillingTreatmentId=$defaultBillingTreatmentId
sleep 2

defaultBillingPolicyId=$(sfdx force:data:soql:query -u $orgAlias  -q "SELECT Id from BillingPolicy WHERE Name='$defaultBillingPolicyName' LIMIT 1" -r csv | tail -n +2) 
echo_attention defaultBillingPolicyId=$defaultBillingPolicyId
sleep 2

defaultPaymentTermId=$(sfdx force:data:soql:query -u $orgAlias -q  "SELECT Id from PaymentTerm WHERE Name='$defaultPaymentTermName' LIMIT 1" -r csv | tail -n +2) 
echo_attention defaultPaymentTermId=$defaultPaymentTermId
sleep 2

sfdx force:data:record:update -s PaymentTerm -i $defaultPaymentTermId -v "IsDefault=TRUE Status=Active" -u $orgAlias 
sleep 2

sfdx force:data:record:update -s BillingTreatment -i $defaultBillingTreatmentId -v "BillingPolicyId='$defaultBillingPolicyId' Status=Active" -u $orgAlias 
sleep 2

sfdx force:data:record:update -s BillingPolicy -i $defaultBillingPolicyId -v "DefaultBillingTreatmentId='$defaultBillingTreatmentId' Status=Active" -u $orgAlias 
sleep 2

sed -e "s/\"BillingPolicyId\": \"PutBillingPolicyHere\"/\"BillingPolicyId\": \"${defaultBillingPolicyId}\"/g;s/\"TaxPolicyId\": \"PutTaxPolicyHere\"/\"TaxPolicyId\": \"${defaultTaxPolicyId}\"/g" data/Product2-template.json > data/Product2.json 
