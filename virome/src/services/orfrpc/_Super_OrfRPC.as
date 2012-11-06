/**
 * This is a generated class and is not intended for modification.  To customize behavior
 * of this service wrapper you may modify the generated sub-class of this class - OrfRPC.as.
 */
package services.orfrpc
{
import com.adobe.fiber.core.model_internal;
import com.adobe.fiber.services.wrapper.RemoteObjectServiceWrapper;
import com.adobe.serializers.utility.TypeUtility;
import mx.rpc.AbstractOperation;
import mx.rpc.AsyncToken;
import mx.rpc.remoting.Operation;
import mx.rpc.remoting.RemoteObject;

import mx.collections.ItemResponder;
import com.adobe.fiber.valueobjects.AvailablePropertyIterator;

[ExcludeClass]
internal class _Super_OrfRPC extends com.adobe.fiber.services.wrapper.RemoteObjectServiceWrapper
{

    // Constructor
    public function _Super_OrfRPC()
    {
        // initialize service control
        _serviceControl = new mx.rpc.remoting.RemoteObject();

        // initialize RemoteClass alias for all entities returned by functions of this service

        var operations:Object = new Object();
        var operation:mx.rpc.remoting.Operation;

        operation = new mx.rpc.remoting.Operation(null, "orfBlastHit");
         operation.resultType = Object;
        operations["orfBlastHit"] = operation;
        operation = new mx.rpc.remoting.Operation(null, "getSequenceInfo");
         operation.resultElementType = Object;
        operations["getSequenceInfo"] = operation;
        operation = new mx.rpc.remoting.Operation(null, "getBlastHit");
         operation.resultType = Object;
        operations["getBlastHit"] = operation;
        operation = new mx.rpc.remoting.Operation(null, "orfBlastDetails");
         operation.resultElementType = Object;
        operations["orfBlastDetails"] = operation;

        _serviceControl.operations = operations;
        _serviceControl.convertResultHandler = com.adobe.serializers.utility.TypeUtility.convertResultHandler;
        _serviceControl.convertParametersHandler = com.adobe.serializers.utility.TypeUtility.convertCFAMFParametersHandler;
        _serviceControl.source = "cfc.OrfRPC";


         preInitializeService();
         model_internal::initialize();
    }
    
    //init initialization routine here, child class to override
    protected function preInitializeService():void
    {
        destination = "ColdFusion";
      
    }
    

    /**
      * This method is a generated wrapper used to call the 'orfBlastHit' operation. It returns an mx.rpc.AsyncToken whose 
      * result property will be populated with the result of the operation when the server response is received. 
      * To use this result from MXML code, define a CallResponder component and assign its token property to this method's return value. 
      * You can then bind to CallResponder.lastResult or listen for the CallResponder.result or fault events.
      *
      * @see mx.rpc.AsyncToken
      * @see mx.rpc.CallResponder 
      *
      * @return an mx.rpc.AsyncToken whose result property will be populated with the result of the operation when the server response is received.
      */
    public function orfBlastHit(id:Number, environment:String, tabindex:Number, database:String, topHit:Number) : mx.rpc.AsyncToken
    {
        var _internal_operation:mx.rpc.AbstractOperation = _serviceControl.getOperation("orfBlastHit");
		var _internal_token:mx.rpc.AsyncToken = _internal_operation.send(id,environment,tabindex,database,topHit) ;
        return _internal_token;
    }
     
    /**
      * This method is a generated wrapper used to call the 'getSequenceInfo' operation. It returns an mx.rpc.AsyncToken whose 
      * result property will be populated with the result of the operation when the server response is received. 
      * To use this result from MXML code, define a CallResponder component and assign its token property to this method's return value. 
      * You can then bind to CallResponder.lastResult or listen for the CallResponder.result or fault events.
      *
      * @see mx.rpc.AsyncToken
      * @see mx.rpc.CallResponder 
      *
      * @return an mx.rpc.AsyncToken whose result property will be populated with the result of the operation when the server response is received.
      */
    public function getSequenceInfo(orfId:Number, environment:String) : mx.rpc.AsyncToken
    {
        var _internal_operation:mx.rpc.AbstractOperation = _serviceControl.getOperation("getSequenceInfo");
		var _internal_token:mx.rpc.AsyncToken = _internal_operation.send(orfId,environment) ;
        return _internal_token;
    }
     
    /**
      * This method is a generated wrapper used to call the 'getBlastHit' operation. It returns an mx.rpc.AsyncToken whose 
      * result property will be populated with the result of the operation when the server response is received. 
      * To use this result from MXML code, define a CallResponder component and assign its token property to this method's return value. 
      * You can then bind to CallResponder.lastResult or listen for the CallResponder.result or fault events.
      *
      * @see mx.rpc.AsyncToken
      * @see mx.rpc.CallResponder 
      *
      * @return an mx.rpc.AsyncToken whose result property will be populated with the result of the operation when the server response is received.
      */
    public function getBlastHit(id:Number, server:String, database:String, topHit:Number, fxnHit:Number) : mx.rpc.AsyncToken
    {
        var _internal_operation:mx.rpc.AbstractOperation = _serviceControl.getOperation("getBlastHit");
		var _internal_token:mx.rpc.AsyncToken = _internal_operation.send(id,server,database,topHit,fxnHit) ;
        return _internal_token;
    }
     
    /**
      * This method is a generated wrapper used to call the 'orfBlastDetails' operation. It returns an mx.rpc.AsyncToken whose 
      * result property will be populated with the result of the operation when the server response is received. 
      * To use this result from MXML code, define a CallResponder component and assign its token property to this method's return value. 
      * You can then bind to CallResponder.lastResult or listen for the CallResponder.result or fault events.
      *
      * @see mx.rpc.AsyncToken
      * @see mx.rpc.CallResponder 
      *
      * @return an mx.rpc.AsyncToken whose result property will be populated with the result of the operation when the server response is received.
      */
    public function orfBlastDetails(id:Number, environment:String, database:String) : mx.rpc.AsyncToken
    {
        var _internal_operation:mx.rpc.AbstractOperation = _serviceControl.getOperation("orfBlastDetails");
		var _internal_token:mx.rpc.AsyncToken = _internal_operation.send(id,environment,database) ;
        return _internal_token;
    }
     
}

}
