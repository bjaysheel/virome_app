/**
 * This is a generated class and is not intended for modification.  To customize behavior
 * of this service wrapper you may modify the generated sub-class of this class - Library.as.
 */
package services.library
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
internal class _Super_Library extends com.adobe.fiber.services.wrapper.RemoteObjectServiceWrapper
{

    // Constructor
    public function _Super_Library()
    {
        // initialize service control
        _serviceControl = new mx.rpc.remoting.RemoteObject();

        // initialize RemoteClass alias for all entities returned by functions of this service

        var operations:Object = new Object();
        var operation:mx.rpc.remoting.Operation;

        operation = new mx.rpc.remoting.Operation(null, "getLibrary");
         operation.resultType = Object;
        operations["getLibrary"] = operation;
        operation = new mx.rpc.remoting.Operation(null, "getHistogram");
         operation.resultType = Object;
        operations["getHistogram"] = operation;
        operation = new mx.rpc.remoting.Operation(null, "getLibraryObject");
         operation.resultElementType = Object;
        operations["getLibraryObject"] = operation;
        operation = new mx.rpc.remoting.Operation(null, "getGeneralObject");
         operation.resultType = Object;
        operations["getGeneralObject"] = operation;
        operation = new mx.rpc.remoting.Operation(null, "getServerOverview");
         operation.resultElementType = Object;
        operations["getServerOverview"] = operation;
        operation = new mx.rpc.remoting.Operation(null, "getLibraryInfo");
         operation.resultType = Object;
        operations["getLibraryInfo"] = operation;
        operation = new mx.rpc.remoting.Operation(null, "getBLASTDBObject");
         operation.resultElementType = Object;
        operations["getBLASTDBObject"] = operation;
        operation = new mx.rpc.remoting.Operation(null, "getEnvironmentObject");
         operation.resultElementType = Object;
        operations["getEnvironmentObject"] = operation;
        operation = new mx.rpc.remoting.Operation(null, "add_library");
         operation.resultType = Object;
        operations["add_library"] = operation;
        operation = new mx.rpc.remoting.Operation(null, "delete_library");
         operation.resultType = Object;
        operations["delete_library"] = operation;
        operation = new mx.rpc.remoting.Operation(null, "edit_library");
         operation.resultType = Object;
        operations["edit_library"] = operation;

        _serviceControl.operations = operations;
        _serviceControl.convertResultHandler = com.adobe.serializers.utility.TypeUtility.convertResultHandler;
        _serviceControl.convertParametersHandler = com.adobe.serializers.utility.TypeUtility.convertCFAMFParametersHandler;
        _serviceControl.source = "cfc.Library";


         preInitializeService();
         model_internal::initialize();
    }
    
    //init initialization routine here, child class to override
    protected function preInitializeService():void
    {
        destination = "ColdFusion";
      
    }
    

    /**
      * This method is a generated wrapper used to call the 'getLibrary' operation. It returns an mx.rpc.AsyncToken whose 
      * result property will be populated with the result of the operation when the server response is received. 
      * To use this result from MXML code, define a CallResponder component and assign its token property to this method's return value. 
      * You can then bind to CallResponder.lastResult or listen for the CallResponder.result or fault events.
      *
      * @see mx.rpc.AsyncToken
      * @see mx.rpc.CallResponder 
      *
      * @return an mx.rpc.AsyncToken whose result property will be populated with the result of the operation when the server response is received.
      */
    public function getLibrary(id:Number, libraryIdList:String, publish:Number, environment:String) : mx.rpc.AsyncToken
    {
        var _internal_operation:mx.rpc.AbstractOperation = _serviceControl.getOperation("getLibrary");
		var _internal_token:mx.rpc.AsyncToken = _internal_operation.send(id,libraryIdList,publish,environment) ;
        return _internal_token;
    }
     
    /**
      * This method is a generated wrapper used to call the 'getHistogram' operation. It returns an mx.rpc.AsyncToken whose 
      * result property will be populated with the result of the operation when the server response is received. 
      * To use this result from MXML code, define a CallResponder component and assign its token property to this method's return value. 
      * You can then bind to CallResponder.lastResult or listen for the CallResponder.result or fault events.
      *
      * @see mx.rpc.AsyncToken
      * @see mx.rpc.CallResponder 
      *
      * @return an mx.rpc.AsyncToken whose result property will be populated with the result of the operation when the server response is received.
      */
    public function getHistogram(libraryId:Number, server:String, type:String) : mx.rpc.AsyncToken
    {
        var _internal_operation:mx.rpc.AbstractOperation = _serviceControl.getOperation("getHistogram");
		var _internal_token:mx.rpc.AsyncToken = _internal_operation.send(libraryId,server,type) ;
        return _internal_token;
    }
     
    /**
      * This method is a generated wrapper used to call the 'getLibraryObject' operation. It returns an mx.rpc.AsyncToken whose 
      * result property will be populated with the result of the operation when the server response is received. 
      * To use this result from MXML code, define a CallResponder component and assign its token property to this method's return value. 
      * You can then bind to CallResponder.lastResult or listen for the CallResponder.result or fault events.
      *
      * @see mx.rpc.AsyncToken
      * @see mx.rpc.CallResponder 
      *
      * @return an mx.rpc.AsyncToken whose result property will be populated with the result of the operation when the server response is received.
      */
    public function getLibraryObject(environment:String, libraryIdList:String) : mx.rpc.AsyncToken
    {
        var _internal_operation:mx.rpc.AbstractOperation = _serviceControl.getOperation("getLibraryObject");
		var _internal_token:mx.rpc.AsyncToken = _internal_operation.send(environment,libraryIdList) ;
        return _internal_token;
    }
     
    /**
      * This method is a generated wrapper used to call the 'getGeneralObject' operation. It returns an mx.rpc.AsyncToken whose 
      * result property will be populated with the result of the operation when the server response is received. 
      * To use this result from MXML code, define a CallResponder component and assign its token property to this method's return value. 
      * You can then bind to CallResponder.lastResult or listen for the CallResponder.result or fault events.
      *
      * @see mx.rpc.AsyncToken
      * @see mx.rpc.CallResponder 
      *
      * @return an mx.rpc.AsyncToken whose result property will be populated with the result of the operation when the server response is received.
      */
    public function getGeneralObject(obj:Object) : mx.rpc.AsyncToken
    {
        var _internal_operation:mx.rpc.AbstractOperation = _serviceControl.getOperation("getGeneralObject");
		var _internal_token:mx.rpc.AsyncToken = _internal_operation.send(obj) ;
        return _internal_token;
    }
     
    /**
      * This method is a generated wrapper used to call the 'getServerOverview' operation. It returns an mx.rpc.AsyncToken whose 
      * result property will be populated with the result of the operation when the server response is received. 
      * To use this result from MXML code, define a CallResponder component and assign its token property to this method's return value. 
      * You can then bind to CallResponder.lastResult or listen for the CallResponder.result or fault events.
      *
      * @see mx.rpc.AsyncToken
      * @see mx.rpc.CallResponder 
      *
      * @return an mx.rpc.AsyncToken whose result property will be populated with the result of the operation when the server response is received.
      */
    public function getServerOverview(userId:Number, libraryIdList:String, privateOnly:Boolean) : mx.rpc.AsyncToken
    {
        var _internal_operation:mx.rpc.AbstractOperation = _serviceControl.getOperation("getServerOverview");
		var _internal_token:mx.rpc.AsyncToken = _internal_operation.send(userId,libraryIdList,privateOnly) ;
        return _internal_token;
    }
     
    /**
      * This method is a generated wrapper used to call the 'getLibraryInfo' operation. It returns an mx.rpc.AsyncToken whose 
      * result property will be populated with the result of the operation when the server response is received. 
      * To use this result from MXML code, define a CallResponder component and assign its token property to this method's return value. 
      * You can then bind to CallResponder.lastResult or listen for the CallResponder.result or fault events.
      *
      * @see mx.rpc.AsyncToken
      * @see mx.rpc.CallResponder 
      *
      * @return an mx.rpc.AsyncToken whose result property will be populated with the result of the operation when the server response is received.
      */
    public function getLibraryInfo(environment:String, libraryIdList:String, publish:Number) : mx.rpc.AsyncToken
    {
        var _internal_operation:mx.rpc.AbstractOperation = _serviceControl.getOperation("getLibraryInfo");
		var _internal_token:mx.rpc.AsyncToken = _internal_operation.send(environment,libraryIdList,publish) ;
        return _internal_token;
    }
     
    /**
      * This method is a generated wrapper used to call the 'getBLASTDBObject' operation. It returns an mx.rpc.AsyncToken whose 
      * result property will be populated with the result of the operation when the server response is received. 
      * To use this result from MXML code, define a CallResponder component and assign its token property to this method's return value. 
      * You can then bind to CallResponder.lastResult or listen for the CallResponder.result or fault events.
      *
      * @see mx.rpc.AsyncToken
      * @see mx.rpc.CallResponder 
      *
      * @return an mx.rpc.AsyncToken whose result property will be populated with the result of the operation when the server response is received.
      */
    public function getBLASTDBObject() : mx.rpc.AsyncToken
    {
        var _internal_operation:mx.rpc.AbstractOperation = _serviceControl.getOperation("getBLASTDBObject");
		var _internal_token:mx.rpc.AsyncToken = _internal_operation.send() ;
        return _internal_token;
    }
     
    /**
      * This method is a generated wrapper used to call the 'getEnvironmentObject' operation. It returns an mx.rpc.AsyncToken whose 
      * result property will be populated with the result of the operation when the server response is received. 
      * To use this result from MXML code, define a CallResponder component and assign its token property to this method's return value. 
      * You can then bind to CallResponder.lastResult or listen for the CallResponder.result or fault events.
      *
      * @see mx.rpc.AsyncToken
      * @see mx.rpc.CallResponder 
      *
      * @return an mx.rpc.AsyncToken whose result property will be populated with the result of the operation when the server response is received.
      */
    public function getEnvironmentObject(libraryIdList:String) : mx.rpc.AsyncToken
    {
        var _internal_operation:mx.rpc.AbstractOperation = _serviceControl.getOperation("getEnvironmentObject");
		var _internal_token:mx.rpc.AsyncToken = _internal_operation.send(libraryIdList) ;
        return _internal_token;
    }
     
    /**
      * This method is a generated wrapper used to call the 'add_library' operation. It returns an mx.rpc.AsyncToken whose 
      * result property will be populated with the result of the operation when the server response is received. 
      * To use this result from MXML code, define a CallResponder component and assign its token property to this method's return value. 
      * You can then bind to CallResponder.lastResult or listen for the CallResponder.result or fault events.
      *
      * @see mx.rpc.AsyncToken
      * @see mx.rpc.CallResponder 
      *
      * @return an mx.rpc.AsyncToken whose result property will be populated with the result of the operation when the server response is received.
      */
    public function add_library(obj:Object) : mx.rpc.AsyncToken
    {
        var _internal_operation:mx.rpc.AbstractOperation = _serviceControl.getOperation("add_library");
		var _internal_token:mx.rpc.AsyncToken = _internal_operation.send(obj) ;
        return _internal_token;
    }
     
    /**
      * This method is a generated wrapper used to call the 'delete_library' operation. It returns an mx.rpc.AsyncToken whose 
      * result property will be populated with the result of the operation when the server response is received. 
      * To use this result from MXML code, define a CallResponder component and assign its token property to this method's return value. 
      * You can then bind to CallResponder.lastResult or listen for the CallResponder.result or fault events.
      *
      * @see mx.rpc.AsyncToken
      * @see mx.rpc.CallResponder 
      *
      * @return an mx.rpc.AsyncToken whose result property will be populated with the result of the operation when the server response is received.
      */
    public function delete_library(obj:Object) : mx.rpc.AsyncToken
    {
        var _internal_operation:mx.rpc.AbstractOperation = _serviceControl.getOperation("delete_library");
		var _internal_token:mx.rpc.AsyncToken = _internal_operation.send(obj) ;
        return _internal_token;
    }
     
    /**
      * This method is a generated wrapper used to call the 'edit_library' operation. It returns an mx.rpc.AsyncToken whose 
      * result property will be populated with the result of the operation when the server response is received. 
      * To use this result from MXML code, define a CallResponder component and assign its token property to this method's return value. 
      * You can then bind to CallResponder.lastResult or listen for the CallResponder.result or fault events.
      *
      * @see mx.rpc.AsyncToken
      * @see mx.rpc.CallResponder 
      *
      * @return an mx.rpc.AsyncToken whose result property will be populated with the result of the operation when the server response is received.
      */
    public function edit_library(obj:Object) : mx.rpc.AsyncToken
    {
        var _internal_operation:mx.rpc.AbstractOperation = _serviceControl.getOperation("edit_library");
		var _internal_token:mx.rpc.AsyncToken = _internal_operation.send(obj) ;
        return _internal_token;
    }
     
}

}
