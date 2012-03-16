package com.events
{
	import flash.events.Event;
	
	public class BrowseEnvEvent extends Event
	{
		public static const BROWSE_ENVIRONMENT_EVENT:String = "BrowseEnvironmentEvent";
		
		private var _environment:String;
		private var _pending:Boolean;
		
		public function BrowseEnvEvent(){
			super(BROWSE_ENVIRONMENT_EVENT, false, true);
			_environment=null;
			_pending=false;
		}
		
		override public function clone() : Event{
			return new BrowseEnvEvent();
		}
		
		public function get environment():String{
			return _environment;
		}
		public function get pending():Boolean{
			return _pending;
		}
		
		public function set environment(v:String):void{
			_environment = v;
		}
		public function set pending(v:Boolean):void{
			_pending = v;
		}
		
		public function get struct():Object{
			var obj:Object = new Object();
			
			obj['ENVIRONMENT'] = _environment;
			obj['PENDING'] = _pending;
			return obj;
		}
		
		public function duplicate(e:BrowseEnvEvent):void{
			environment = e.environment;
			pending = e.pending;
		}
	}
}