package com.component
{
	import com.MyUtility;
	
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.ui.Mouse;
	
	import mx.containers.ControlBar;
	import mx.containers.Panel;
	import mx.containers.TitleWindow;
	import mx.controls.Alert;
	import mx.controls.Button;
	import mx.controls.Label;
	import mx.controls.Text;
	import mx.core.IFlexDisplayObject;
	import mx.events.CloseEvent;
	import mx.managers.PopUpManager;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	import mx.rpc.remoting.RemoteObject;
	
	public class Notification extends TitleWindow
	{
		private var _util:MyUtility = new MyUtility();
		private var _msg:String = "";
		private var _text:Text;
		private var buttons:ControlBar;
		private var _error:Boolean = false;
		private var _wTitle:String = "Message";
		
		public function Notification() {
			super();
			
			showCloseButton = true;
			addEventListener(CloseEvent.CLOSE,closeWindow);
			
			horizontalScrollPolicy = "false";
			verticalScrollPolicy = "false";
			
			minWidth=300;
			minHeight=200;
			maxWidth=700;
			maxHeight=500;
			
			invalidateSize();
		}
		
		public function get wTitle():String {
			return _wTitle;
		}
		public function get msg():String {
			return _msg;
		}
		public function get error():Boolean{
			return _error;
		}

		[Bindable] public function set wTitle(value:String):void {
			_wTitle = value;
		}
		[Bindable] public function set msg(value:String):void {
			_msg = value;			
		}
		[Bindable] public function set error(value:Boolean):void{
			_error = value;
		}

	 	public function closeWindow(e:CloseEvent):void {
			PopUpManager.removePopUp(e.target as IFlexDisplayObject);
		}
		
		private function emailErrorMessage(event:MouseEvent):void{
			var ro:RemoteObject  = new RemoteObject();
			ro.destination = "ColdFusion";
			ro.endpoint = _util.endpoint;
			ro.source = _util.cfcPath + ".Utility";
			ro.showBusyCursor = true;
			ro.addEventListener(FaultEvent.FAULT, function (event:FaultEvent):void{ Alert.show(event.toString()); });
			ro.addEventListener(ResultEvent.RESULT, emailErrorResultHandler);
			ro.reportFlexError(msg);
		}
		
		private function emailErrorResultHandler(event:ResultEvent):void{
			PopUpManager.removePopUp(this);
		}
		
		override protected function createChildren():void{
			super.createChildren();
			
			_text = new Text();
			_text.percentHeight = 100;
			_text.percentWidth = 100;
			_text.htmlText = _msg;
			
			addChild(_text);
			
			title = wTitle;
			
			if (error) {
				title = "Error";
				buttons = new ControlBar();
				
				var _sumbitButton:Button = new Button();
				_sumbitButton.label="Send Error";
				_sumbitButton.addEventListener(MouseEvent.CLICK, emailErrorMessage);
				buttons.addChild(_sumbitButton);
				
				addChild(buttons);
				controlBar=buttons;
			}
			
			percentHeight = 100;
			percentWidth = 100;
		}
	}
}