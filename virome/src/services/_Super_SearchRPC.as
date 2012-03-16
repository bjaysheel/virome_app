/**
 * This is a generated class and is not intended for modification.  To customize behavior
 * of this service wrapper you may modify the generated sub-class of this class - SearchRPC.as.
 */
package services
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
internal class _Super_SearchRPC extends com.adobe.fiber.services.wrapper.RemoteObjectServiceWrapper
{

    // Constructor
    public function _Super_SearchRPC()
    {
        // initialize service control
        _serviceControl = new mx.rpc.remoting.RemoteObject();

        // initialize RemoteClass alias for all entities returned by functions of this service

        var operations:Object = new Object();
        var operation:mx.rpc.remoting.Operation;

        operation = new mx.rpc.remoting.Operation(null, "getSearchRSLT");
         operation.resultElementType = Object;
        operations["getSearchRSLT"] = operation;
        operation = new mx.rpc.remoting.Operation(null, "getSearchCount");
         operation.resultType = Number;
        operations["getSearchCount"] = operation;
        operation = new mx.rpc.remoting.Operation(null, "getBlastSearch");
         operation.resultType = String;
        operations["getBlastSearch"] = operation;
        operation = new mx.rpc.remoting.Operation(null, "getORFSeqIdFromRead");
         operation.resultType = String;
        operations["getORFSeqIdFromRead"] = operation;
        operation = new mx.rpc.remoting.Operation(null, "retrieveSequenceId_B");
         operation.resultType = Object;
        operations["retrieveSequenceId_B"] = operation;
        operation = new mx.rpc.remoting.Operation(null, "retrieveSequenceId_A");
         operation.resultType = String;
        operations["retrieveSequenceId_A"] = operation;

        _serviceControl.operations = operations;
        _serviceControl.convertResultHandler = com.adobe.serializers.utility.TypeUtility.convertResultHandler;
        _serviceControl.convertParametersHandler = com.adobe.serializers.utility.TypeUtility.convertCFAMFParametersHandler;
        _serviceControl.source = "VIROME.cfc.SearchRPC";


         preInitializeService();
         model_internal::initialize();
    }
    
    //init initialization routine here, child class to override
    protected function preInitializeService():void
    {
        destination = "ColdFusion";
      
    }
    

    /**
      * This method is a generated wrapper used to call the 'getSearchRSLT' operation. It returns an mx.rpc.AsyncToken whose 
      * result property will be populated with the result of the operation when the server response is received. 
      * To use this result from MXML code, define a CallResponder component and assign its token property to this method's return value. 
      * You can then bind to CallResponder.lastResult or listen for the CallResponder.result or fault events.
      *
      * @see mx.rpc.AsyncToken
      * @see mx.rpc.CallResponder 
      *
      * @return an mx.rpc.AsyncToken whose result property will be populated with the result of the operation when the server response is received.
      */
    public function getSearchRSLT(obj:Object) : mx.rpc.AsyncToken
    {
        var _internal_operation:mx.rpc.AbstractOperation = _serviceControl.getOperation("getSearchRSLT");
		var _internal_token:mx.rpc.AsyncToken = _internal_operation.send(obj) ;
        return _internal_token;
    }
     
    /**
      * This method is a generated wrapper used to call the 'getSearchCount' operation. It returns an mx.rpc.AsyncToken whose 
      * result property will be populated with the result of the operation when the server response is received. 
      * To use this result from MXML code, define a CallResponder component and assign its token property to this method's return value. 
      * You can then bind to CallResponder.lastResult or listen for the CallResponder.result or fault events.
      *
      * @see mx.rpc.AsyncToken
      * @see mx.rpc.CallResponder 
      *
      * @return an mx.rpc.AsyncToken whose result property will be populated with the result of the operation when the server response is received.
      */
    public function getSearchCount(obj:Object) : mx.rpc.AsyncToken
    {
        var _internal_operation:mx.rpc.AbstractOperation = _serviceControl.getOperation("getSearchCount");
		var _internal_token:mx.rpc.AsyncToken = _internal_operation.send(obj) ;
        return _internal_token;
    }
     
    /**
      * This method is a generated wrapper used to call the 'getBlastSearch' operation. It returns an mx.rpc.AsyncToken whose 
      * result property will be populated with the result of the operation when the server response is received. 
      * To use this result from MXML code, define a CallResponder component and assign its token property to this method's return value. 
      * You can then bind to CallResponder.lastResult or listen for the CallResponder.result or fault events.
      *
      * @see mx.rpc.AsyncToken
      * @see mx.rpc.CallResponder 
      *
      * @return an mx.rpc.AsyncToken whose result property will be populated with the result of the operation when the server response is received.
      */
    public function getBlastSearch(obj:Object) : mx.rpc.AsyncToken
    {
        var _internal_operation:mx.rpc.AbstractOperation = _serviceControl.getOperation("getBlastSearch");
		var _internal_token:mx.rpc.AsyncToken = _internal_operation.send(obj) ;
        return _internal_token;
    }
     
    /**
      * This method is a generated wrapper used to call the 'getORFSeqIdFromRead' operation. It returns an mx.rpc.AsyncToken whose 
      * result property will be populated with the result of the operation when the server response is received. 
      * To use this result from MXML code, define a CallResponder component and assign its token property to this method's return value. 
      * You can then bind to CallResponder.lastResult or listen for the CallResponder.result or fault events.
      *
      * @see mx.rpc.AsyncToken
      * @see mx.rpc.CallResponder 
      *
      * @return an mx.rpc.AsyncToken whose result property will be populated with the result of the operation when the server response is received.
      */
    public function getORFSeqIdFromRead(readId:String, server:String) : mx.rpc.AsyncToken
    {
        var _internal_operation:mx.rpc.AbstractOperation = _serviceControl.getOperation("getORFSeqIdFromRead");
		var _internal_token:mx.rpc.AsyncToken = _internal_operation.send(readId,server) ;
        return _internal_token;
    }
     
    /**
      * This method is a generated wrapper used to call the 'retrieveSequenceId_B' operation. It returns an mx.rpc.AsyncToken whose 
      * result property will be populated with the result of the operation when the server response is received. 
      * To use this result from MXML code, define a CallResponder component and assign its token property to this method's return value. 
      * You can then bind to CallResponder.lastResult or listen for the CallResponder.result or fault events.
      *
      * @see mx.rpc.AsyncToken
      * @see mx.rpc.CallResponder 
      *
      * @return an mx.rpc.AsyncToken whose result property will be populated with the result of the operation when the server response is received.
      */
    public function retrieveSequenceId_B(str:String, server:String, library:String) : mx.rpc.AsyncToken
    {
        var _internal_operation:mx.rpc.AbstractOperation = _serviceControl.getOperation("retrieveSequenceId_B");
		var _internal_token:mx.rpc.AsyncToken = _internal_operation.send(str,server,library) ;
        return _internal_token;
    }
     
    /**
      * This method is a generated wrapper used to call the 'retrieveSequenceId_A' operation. It returns an mx.rpc.AsyncToken whose 
      * result property will be populated with the result of the operation when the server response is received. 
      * To use this result from MXML code, define a CallResponder component and assign its token property to this method's return value. 
      * You can then bind to CallResponder.lastResult or listen for the CallResponder.result or fault events.
      *
      * @see mx.rpc.AsyncToken
      * @see mx.rpc.CallResponder 
      *
      * @return an mx.rpc.AsyncToken whose result property will be populated with the result of the operation when the server response is received.
      */
    public function retrieveSequenceId_A(tag:String, file:String) : mx.rpc.AsyncToken
    {
        var _internal_operation:mx.rpc.AbstractOperation = _serviceControl.getOperation("retrieveSequenceId_A");
		var _internal_token:mx.rpc.AsyncToken = _internal_operation.send(tag,file) ;
        return _internal_token;
    }
     
}

}
