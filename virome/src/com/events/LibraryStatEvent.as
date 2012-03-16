package com.events
{
	import flash.events.Event;
	
	public class LibraryStatEvent extends Event
	{
		public static const LIBRARY_STAT_EVENT:String = "LibraryStatEvent";
		
		private var _library:Number;
		private var _environment:String;
		private var _pending:Boolean;
		
		public function LibraryStatEvent(){
			super(LIBRARY_STAT_EVENT, false, true);
			_library=0;
			_environment=null;
			_pending = false;
		}
		
		override public function clone() : Event{
			return new LibraryStatEvent();
		}
		
		public function get library():Number{
			return _library;
		}
		public function get environment():String{
			return _environment;
		}
		public function get pending():Boolean{
			return _pending;
		}
		
		public function set library(v:Number):void{
			_library=v;
		}
		public function set environment(v:String):void{
			_environment = v;
		}
		public function set pending(v:Boolean):void{
			_pending = v;
		}
				
		public function get struct():Object{
			var obj:Object = new Object();
			
			obj['LIBRARY'] = _library;
			obj['ENVIRONMENT'] = _environment;
			obj['PENDING'] = _pending;
			
			return obj;
		}
		
		public function duplicate(e:LibraryStatEvent):void{
			library = e.library;
			environment = e.environment;
			pending = e.pending;
		}
	}
}