#!/bin/bash

orgAlias=$1
devhubAlias=$2
durationDays=$3
echo ${orgAlias}

# Assign execute permission to all scripts
find . -type f -name '*.sh' -exec chmod +x {} \;
echo "Assigned Execute permissions to all the scripts"

if [[ "$orgAlias" =~ ^[[:alnum:]]*$ ]] && [[ ! "orgAlias" =~ ^[[:digit:]]+$ ]]
then
    if [ -z "$orgAlias" ]
    then
        echo "You must enter an alias for the scratch org"
        exit 1
    else
        if [ -z "$devhubAlias" ]
        then
          echo "You must enter a devhub for the scratch org."
          exit 1
        else
          if [ -z "$durationDays" ]
          then
            echo "Creating a Scratch Org with the specified devhub..."
            sfdx force:org:create -s -f config/project-scratch-def.json -a $orgAlias -v $devhubAlias  --apiversion "56.0"
          else
            echo "Creating a Scratch org with the specified Devhub and duration"
            sfdx force:org:create -s -f config/project-scratch-def.json -a $orgAlias -v $devhubAlias -d $durationDays --apiversion "56.0"
          fi
        fi

        echo "Navigate to B2B Commerce Lightning package..."
        cd ./dependencies/b2b-commerce-on-lightning-quickstart/sfdx/

        echo "Set new scratch org as a default for the B2B Commerce Lightning package..."
        sfdx force:config:set defaultusername="$orgAlias" defaultdevhubusername="$devhubAlias"

         echo "Create a new store in your new scratch org..."
        ./quickstart-create-and-setup-store.sh $orgAlias

        echo "Deploy B2B Commerce Lightning package with Metadata API..."
        #sfdx force:source:push -f -u $orgAlias

        echo "Navigate back to the project root folder..."
        cd ../../../

        echo "push mock tax class"
        sfdx force:source:deploy -p dependencies/ApexClass

        echo "Assign standard suscription permissions..."
        sfdx force:user:permset:assign -n "SubscriptionManagementCollectionsManager,SubscriptionManagementCollectionsAgent,SubscriptionManagementSalesRep ,SubscriptionManagementApplyCreditToInvoiceApi ,SubscriptionManagementBillingAdmin ,SubscriptionManagementBillingOperations ,SubscriptionManagementBillingSetup ,SubscriptionManagementBuyerIntegrationUser ,SubscriptionManagementCalculateInvoiceLatePaymentRiskFeature ,SubscriptionManagementCalculatePricesApi ,SubscriptionManagementCalculateTaxesApi ,SubscriptionManagementCollections ,SubscriptionManagementCreateBillingScheduleFromOrderItemApi ,SubscriptionManagementCreateInvoiceFromBillingScheduleApi ,SubscriptionManagementCreateInvoiceFromOrderApi ,SubscriptionManagementCreditAnInvoiceApi ,SubscriptionManagementCreditMemoAdjustmentsOperations ,SubscriptionManagementCreditMemoRecoveryApi ,SubscriptionManagementInitiateCancellationApi ,SubscriptionManagementInitiateRenewalApi ,SubscriptionManagementInvoiceErrorRecoveryApi ,SubscriptionManagementIssueStandaloneCreditApi ,SubscriptionManagementOrderToAssetApi ,SubscriptionManagementPaymentAdministrator ,SubscriptionManagementPaymentOperations ,SubscriptionManagementPaymentsConfiguration ,SubscriptionManagementPaymentsRuntimeApi ,SubscriptionManagementPlaceOrderApi ,SubscriptionManagementProductAndPriceConfigurationApi ,SubscriptionManagementProductAndPricingAdmin ,SubscriptionManagementProductImportApi ,SubscriptionManagementSalesOperationsRep ,SubscriptionManagementScheduledBatchInvoicingApi ,SubscriptionManagementScheduledBatchPaymentsApi ,SubscriptionManagementTaxAdmin ,SubscriptionManagementTaxConfiguration ,SubscriptionManagementUnapplyCreditToInvoiceApi ,SubscriptionManagementVoidPostedInvoiceApi"

        echo "Push custom metadata aka src..."
        sfdx force:source:deploy -p src

        echo "Assign Custom Permission..."
        sfdx force:user:permset:assign -n RSM_SF_User
        sfdx force:user:permset:assign -n RSM_Portal_User -o "buyer@scratch.org"

        echo "setup Sm specific product..."
        ./dependencies/sm-quickstart/pricebookSetup.sh $orgAlias

        echo "Build Serach Index..."
        sfdx force:apex:execute -f scripts/apex/buildIndex.apex -u $orgAlias

        echo "setup payment gateway..."
        paymentGatewayApexClassId=`sfdx force:data:soql:query -q "SELECT Id FROM ApexClass WHERE Name='B2BStripeAdapter' LIMIT 1" -r csv |tail -n +2`
        paymentGatewayProviderId=`sfdx force:data:soql:query -q "SELECT Id FROM PaymentGatewayProvider LIMIT 1" -r csv |tail -n +2`
        
        echo "Creating PaymentGatewayProvider record using ApexAdapterId=$paymentGatewayApexClassId."
        sfdx force:data:record:update -s PaymentGatewayProvider -i "$paymentGatewayProviderId" -v "ApexAdapterId=$paymentGatewayApexClassId"
        sfdx force:apex:execute -f scripts/apex/setupPaymentGateway.apex

    fi
else
    echo "You must enter an alias for the scratch org that contains only alphabetic characters!"
    exit 1
fi
