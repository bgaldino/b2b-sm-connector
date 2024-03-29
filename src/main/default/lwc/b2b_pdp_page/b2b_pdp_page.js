import { LightningElement, wire, api } from 'lwc';
import communityId from '@salesforce/community/Id';
import getProduct from '@salesforce/apex/B2BGetInfo.getProduct';
import getCartSummary from '@salesforce/apex/B2BGetInfo.getCartSummary';
import checkProductIsInStock from '@salesforce/apex/B2BGetInfo.checkProductIsInStock';
import addToCartWithSubscription from '@salesforce/apex/B2B_SubscriptionController.addToCart';
import createAndAddToList from '@salesforce/apex/B2BGetInfo.createAndAddToList';
import getProductPrice from '@salesforce/apex/B2BGetInfo.getProductPrice';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { resolve } from 'c/cmsResourceResolver';
import getActiveCartStatus from '@salesforce/apex/B2B_ProceedToCheckout.getActiveCartStatus';
import checkQueueStatus from '@salesforce/apex/B2B_CartController.checkQueueStatus';
import {publish, MessageContext} from 'lightning/messageService'
import { loadStyle } from 'lightning/platformResourceLoader';
import Colors from '@salesforce/resourceUrl/B2B_Colors';
import Fonts from '@salesforce/resourceUrl/B2B_Fonts';
import BoldFonts from '@salesforce/resourceUrl/B2B_Fonts_Bold';
import productWithPricingModel from '@salesforce/apex/B2BGetProducts.getProduct';

import getPrices from '@salesforce/apex/B2B_RelatedProductsController.getProductPrices';


export default class B2b_pdp_page extends LightningElement {

handleNavigateTo(event) {
    event.preventDefault();

    const name = event.target.name;

    if (this.breadCrumbsMap[name]) {
        window.location.assign(this.breadCrumbsMap[name]);
    }

    
}
activeSections = ['A'];
activeSectionsMessage = '';

handleSectionToggle(event) {
    const openSections = event.detail.openSections;

    if (openSections.length === 0) {
        this.activeSectionsMessage = 'All sections are closed';
    } else {
        this.activeSectionsMessage =
            'Open sections: ' + openSections.join(', ');
    }
}

 @api
 get effectiveAccountId() {
     return this._effectiveAccountId;
 }

 set effectiveAccountId(newId) {
     this._effectiveAccountId = newId;
 }

 @api
 recordId;

 @api
 customDisplayFields;
 addToCartDomain={};
 isSubscriptionSelected = false;
 @api
  isSubscriptionEnabled;
  pricingDomain={};
  showSpinner =false;
  addToCartMessageState = '';
  jobInterval;
 
 cartSummary;

 inStock = false;

 @wire(MessageContext)
 messageContext;

 publishCartCount(cartCount, _cartId) {
     let message = {messageText: cartCount,cartId:_cartId};

     publish(this.messageContext, message);
 }

 @wire(getProduct, {
     communityId: communityId,
     productId: '$recordId',
     effectiveAccountId: '$resolvedEffectiveAccountId'
 })
 product;

    @wire(productWithPricingModel, {
        productId: '$recordId',
        effAccId: '$resolvedEffectiveAccountId'
    })
    productPricingModel;


 @wire(getProductPrice, {
     communityId: communityId,
     productId: '$recordId',
     effectiveAccountId: '$resolvedEffectiveAccountId'
 })
 productPrice;

 connectedCallback() {
    this.setPrice();
    loadStyle( this, Fonts);
    loadStyle(this, BoldFonts);
    loadStyle(this, Colors);
 }

 get resolvedEffectiveAccountId() {
     const effectiveAccountId = this.effectiveAccountId || '';
     let resolved = null;

     if (
         effectiveAccountId.length > 0 &&
         effectiveAccountId !== '000000000000000'
     ) {
         resolved = effectiveAccountId;
     }
     this.pricingDomain.effectiveAccountId=effectiveAccountId;
     this.pricingDomain.productId=this.recordId;
     this.pricingDomain.communityId=communityId;
     return resolved;
 }

 get hasProduct() {
     return this.product.data !== undefined;
 }

    currentPrice;
    setPrice(){
        getPrices({productId : this.recordId})
                  .then(res => {
                  this.currentPrice = res[this.recordId];    
            })
            .catch((error) => {
                this.error = error;
                console.log(error);
            });
    }

 get displayableProduct() { 
     let productId = this.recordId.split('-')[0];

     return {
         categoryPath: this.product.data.primaryProductCategoryPath.path.map(
             (category) => ({
                 id: category.id,
                 name: category.name
             })
         ),
         description: this.product.data.fields.Description,
         image: {
             alternativeText: this.product.data.defaultImage.alternativeText,
             url: resolve(this.product.data.defaultImage.url)
         },
         inStock: this.inStock.data === true,
         name: this.product.data.fields.Name,
         id: productId,
         pricingModel : ((this.productPricingModel || {}).data || {}) ,
         price: {
             currency: ((this.productPrice || {}).data || {})
                 .currencyIsoCode,
             negotiated: ((this.productPrice || {}).data || {}).unitPrice,
             pricebookEntryId: ((this.productPrice || {}).data || {}).pricebookEntryId
         },
         sku: this.product.data.fields.StockKeepingUnit,
         isRecurringProduct:this.product.data.fields.RecurringProduct__c==='true'?true:false,
         customFields: Object.entries(
             this.product.data.fields || Object.create(null)
         )
             .filter(([key]) =>
                 (this.customDisplayFields || '').includes(key)
             )
             .map(([key, value]) => ({ name: key, value }))
     };
 }
 isSubscriptionPage;
 @api
 get isMySubscriptionPage() {
     return this.isSubscriptionPage;
 }

 set isMySubscriptionPage(response) {
     this.isSubscriptionPage = response;
 }
 isTrialProductRenwal;
 @api
 get isTrialProdRenwal() {
     return this.isTrialProductRenwal;
 }

 set isTrialProdRenwal(response) {
     this.isTrialProductRenwal = response;
 }
 
 
 @api
 get addOnContractNumber() {
     return this.contractNumber;
 }

 set addOnContractNumber(response) {
     this.contractNumber = response;
 }
 addOnSubscriptionId;
 @api
 get addOnSubId() {
     return this.addOnSubscriptionId;
 }

 set addOnSubId(response) {
     this.addOnSubscriptionId = response;
 }

 contractNumber;

 get _isCartLocked() {
     const cartStatus = (this.cartSummary || {}).status;
     return cartStatus === 'Processing' || cartStatus === 'Checkout';
 }

 updateAddToCartDomain(event){
     this.addToCartDomain= event.detail;
     
 }
 handleSubscriptionSelection(event){
     this.isSubscriptionSelected = event.detail.isSubscriptionSelected;
 }

  
 addToCart(event) {
     let addToCartDomain = {};
     this.showSpinner=true;
     let preserveCart = true;
     if(this.isTrialProductRenwal==='true'){
         preserveCart = false;
     }
     addToCartDomain.unitPrice = this.displayableProduct.price.negotiated;
     addToCartDomain.listPrice = addToCartDomain.unitPrice;
     addToCartDomain.contractNumber = this.addOnContractNumber;
     addToCartDomain.cartType = this.isTrialProductRenwal ==='true'? 'Renewal': '';
     addToCartDomain.productId  = this.recordId;
     addToCartDomain.pricebookId  = '';
     addToCartDomain.currencyCode  = this.displayableProduct.price.currency;
     addToCartDomain.communityId  = communityId;
     addToCartDomain.isProratedPrice = false;
     addToCartDomain.isRecurringProduct = false ;
     let cartItems = [];
     let cartItem = {};
     cartItem.unitPrice = addToCartDomain.unitPrice;
     cartItem.pricebookEntryId = this.displayableProduct.price.pricebookEntryId;
     cartItem.quantity = event.detail.quantity;
     cartItem.productId = this.recordId;
     let productIdToCartItem = {};
     productIdToCartItem[cartItem.productId] = cartItem;
     addToCartDomain.productIdToCartItem  = productIdToCartItem;
     
     cartItems.push(cartItem);
     
     addToCartDomain.cartItems  = cartItems;
     this.addToCartMessageState = ' Adding Product to cart.';

     addToCartWithSubscription({
         communityId: communityId,
         productId: this.recordId,
         quantity: event.detail.quantity,
         effectiveAccountId: this.resolvedEffectiveAccountId,
         addToCartDomain:addToCartDomain,
         preserveCart:preserveCart
     })
         .then(() => {

             this.addToCartMessageState = 'Please wait ';
                 this.getCartStatus();
                 // eslint-disable-next-line @lwc/lwc/no-async-operation
                 setTimeout(() => {

                     this.dispatchEvent(
                         new ShowToastEvent({
                             title: 'Success',
                             message: 'Your cart has been updated.',
                             variant: 'success',
                             mode: 'dismissable'
                         })
                     );

                    
                 
                 }, 5000);

             this.dispatchEvent(
                 new CustomEvent('cartchanged', {
                     bubbles: true,
                     composed: true
                 })
             );

             this.dispatchEvent(
                 new CustomEvent('closemodal', {
                     bubbles: true,
                     composed: true
                 })
             );
            
             
         })
         .catch(() => {
             this.dispatchEvent(
                 new ShowToastEvent({
                     title: 'Error',
                     message:
                         '{0} could not be added to your cart at this time. Please try again later.',
                     messageData: [this.displayableProduct.name],
                     variant: 'error',
                     mode: 'dismissable'
                 })
             );
         });
 }

 addToCartWithSubscription(event) {
    
     let preserveCart = true;
     if(this.isTrialProductRenwal==='true'){
         preserveCart = false;
         this.addToCartDomain.cartType = 'Renewal';
     }

     if(!this.isSubscriptionSelected ){
         this.dispatchEvent(
             new ShowToastEvent({
                 title: 'Error',
                 message:
                     'Please select subscription',
                 variant: 'error',
                 mode: 'dismissable'
             })
         );
         return;
     }
     this.showSpinner=true;
     this.addToCartDomain.quantity = event.detail.quantity;
     this.addToCartDomain.contractNumber = this.addOnContractNumber;
     this.addToCartMessageState = 'Adding Product to cart.';
     addToCartWithSubscription({
         communityId: communityId,
         productId: this.recordId,
         quantity: event.detail.quantity,
         effectiveAccountId: this.resolvedEffectiveAccountId,
         addToCartDomain:this.addToCartDomain,
         preserveCart:preserveCart
     })
         .then(() => {
                 this.addToCartMessageState = 'Please wait ';
                 this.getCartStatus();
                 // eslint-disable-next-line @lwc/lwc/no-async-operation
                 setTimeout(() => {
                     this.dispatchEvent(
                         new CustomEvent('cartchanged', {
                             bubbles: true,
                             composed: true
                         })
                     );
                     this.dispatchEvent(
                         new ShowToastEvent({
                             title: 'Success',
                             message: 'Your cart has been updated.',
                             variant: 'success',
                             mode: 'dismissable'
                         })
                     );
                 
                 }, 5000);

             this.dispatchEvent(
                 new CustomEvent('closemodal', {
                     bubbles: true,
                     composed: true
                 })
             );
             
         })
         .catch(() => {
             this.dispatchEvent(
                 new ShowToastEvent({
                     title: 'Error',
                     message:
                         '{0} could not be added to your cart at this time. Please try again later.',
                     messageData: [this.displayableProduct.name],
                     variant: 'error',
                     mode: 'dismissable'
                 })
             );
         }).finally(() => {

         });
 }
 getCartStatus() {
     getActiveCartStatus({}).then(data => {
         if (data) {
             let cartId = data.cartId;
             let cartType = data.cartType;
             this.cartId = cartId;
         }
     })
         .catch(error => {
            console.log(JSON.stringify(error));
         });

 }

 checkQuoteJob(jobId){
     this.showSpinner = true;
     checkQueueStatus({jobId:jobId})
         .then(result => {
             if(result != null){
                 if(result==='Completed'){
                     this.showSpinner = false;
                    
                     for (let  i = 1; i < this.jobInterval; i++){
                         clearInterval(this.jobInterval);
                     }

                 }else if(result==='Aborted'||result==='Failed'){
                     this.showSpinner = false;
                     for (let  i = 1; i < this.jobInterval; i++){
                         clearInterval(this.jobInterval);
                     }
                 }
             }
         })
         .catch(error => {
             console.log('Check Quote Job Error '+JSON.stringify(error));
         });
 }
 /**
  * Handles a user request to add the product to a newly created wishlist.
  * On success, a success toast is shown to let the user know the product was added to a new list
  * If there is an error, an error toast is shown with a message explaining that the product could not be added to a new list
  *
  * Toast documentation: https://developer.salesforce.com/docs/component-library/documentation/en/lwc/lwc.use_toast
  *
  * @private
  */
 createAndAddToList() {
     let listname = this.product.data.primaryProductCategoryPath.path[0]
         .name;
     createAndAddToList({
         communityId: communityId,
         productId: this.recordId,
         wishlistName: listname,
         effectiveAccountId: this.resolvedEffectiveAccountId
     })
         .then(() => {
             this.dispatchEvent(new CustomEvent('createandaddtolist'));
             this.dispatchEvent(
                 new ShowToastEvent({
                     title: 'Success',
                     message: '{0} was added to a new list called "{1}"',
                     messageData: [this.displayableProduct.name, listname],
                     variant: 'success',
                     mode: 'dismissable'
                 })
             );
         })
         .catch(() => {
             this.dispatchEvent(
                 new ShowToastEvent({
                     title: 'Error',
                     message:
                         '{0} could not be added to a new list. Please make sure you have fewer than 10 lists or try again later',
                     messageData: [this.displayableProduct.name],
                     variant: 'error',
                     mode: 'dismissable'
                 })
             );
         });
 }

 /**
  * Ensures cart information is up to date
  */
 updateCartInformation() {
     getCartSummary({
         communityId: communityId,
         effectiveAccountId: '0018c00002IMuGLAA1'
     })
         .then((result) => {
             this.cartSummary = result;
             this.publishCartCount(this.cartSummary.uniqueProductCount, this.cartSummary.cartId);
         })
         .catch((e) => {
             // Handle cart summary error properly
             // For this sample, we can just log the error
             console.log(e);
         });
 }
}