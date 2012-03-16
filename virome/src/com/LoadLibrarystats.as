package com
{
	import flash.events.Event;

	public class LoadLibrarystats extends Event
	{
		
		public static const LIBRARY_STAT_LOAD_EVENT:String = "LoadLibrarystats";
		
		private var _libName:String;
		
		public function LoadLibrarystats(){
			super(LIBRARY_STAT_LOAD_EVENT, false, true);
			_libName=null;
		}
		
		override public function clone() : Event{
			return new LoadLibrarystats();
		}
		
		public function getLibName():String{
			return _libName;
		}
		
		public function setLibName(v:String):void{
			_libName=v;
		}
		
		
		public function get struct():Object{
			var obj:Object = new Object();
			
			obj['LIBNAME'] = _libName;
			
			return obj;
		}
	}
}