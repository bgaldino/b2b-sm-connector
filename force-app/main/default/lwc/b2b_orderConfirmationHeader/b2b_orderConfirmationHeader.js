import { LightningElement, api } from 'lwc';
import getOrderSummary from '@salesforce/apex/RSM_CartController.getOrderSummary';

export default class B2b_orderConfirmationHeader extends LightningElement {
    @api recordId;
    

    categPath = [{"id":"0ZG8Z000000GsRzWAK","name":"Order Confirmation"}];
    get path() {
        return {
            journey: this.categPath.map(
            (category) => ({
               // id: category.id,
                name: category.name
            })
        )
    };
    }
    
    orderNumber

    connectedCallback(){
        this.getOrder();
    }

    getOrder(){
        getOrderSummary({
            orderSummaryId: this.recordId
        })
            .then((orderSummary) => {
                this.orderNumber = orderSummary.OrderNumber;
              //  console.log('*** orderSummary ' + JSON.stringify(orderSummary));
            })
            .catch((e) => {
                console.log(e);
            });
    }

}