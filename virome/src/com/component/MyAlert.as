package com.component
{
	import flash.display.DisplayObject;
	
	import mx.core.FlexGlobals;
	import mx.managers.PopUpManager;
	
	public class MyAlert extends PopUpManager
	{
		private var _error:Boolean = false;
		
		public function MyAlert()
		{
			super();
		}
		
		[Bindable] public function set error(v:Boolean):void{
			_error = v;
		}
		public function get error():Boolean{
			return _error;
		}
		
		public function show(str:String):void{
			var win:Notification = new Notification();
			win.msg = str;
			win.error = error;
			PopUpManager.addPopUp(win,DisplayObject(FlexGlobals.topLevelApplication),true);
			PopUpManager.centerPopUp(win);
			PopUpManager.bringToFront(win);
		}
	}
}