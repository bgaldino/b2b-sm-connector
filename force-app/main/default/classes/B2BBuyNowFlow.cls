/**
 * @description       : 
 * @author            : Raja Patnaik
 * @group             : 
 * @last modified on  : 03-03-2022
 * @last modified by  : Raja Patnaik
 * Modifications Log 
 * Ver   Date         Author        Modification
 * 1.0   03-03-2023   Raja Patnaik  Initial Version
**/
@RestResource(urlMapping='/B2B_BuyNowRestService/')
global class B2BBuyNowFlow {
    private static final DCM_Logger logger = DCM_Logger.getInstance(B2B_SetupConstants.CHECKOUT_FLOW);
 
    @HttpPost
    global static void startB2BBuyNowFlow(String smOrderId,String paymentGatewayId,String paymentMethodId){
    
        try{
            Map<String, Object> flowInput = new Map<String, Object>();
            flowInput.put('smOrderId', smOrderId);
            flowInput.put('paymentGatewayId', paymentGatewayId);
            flowInput.put('paymentMethodId', paymentMethodId);
           
            // Call  B2B BuyNow flow
            RSM_Utils.callFlow(B2B_Constants.B2BFlow.BUY_NOW_FLOW, flowInput);
        } catch (Exception ex) {
            logger.error(ex);
        } finally {
            logger.flush();
        }
       
    }
    
 
 }