package com.events
{
	import flash.events.Event;
	
	public class MyChgTabEvent extends Event
	{
		public static const CHANGE_TAB_EVENT:String = "MyChgTabEvent";
		
		private var _num:Number;
		private var _name:String;
		private var _id:Number;
		
		public function MyChgTabEvent(){
			super(CHANGE_TAB_EVENT, false, true);
			_num = -1;
			_name = "";
			_id = -1;
		}
		
		override public function clone() : Event{
			return new MyChgTabEvent();
		}
		
		public function get id():Number{
			return _id;
		}
		public function get num():Number{
			return _num;
		}
		public function get name():String{
			return _name;
		}
		public function set id(value:Number):void{
			_id = value;
		}
		public function set name(value:String):void{
			_name = value;
		}
		public function set num(value:Number):void{
			_num = value;
		}

		public function get struct():Object{
			var obj:Object = new Object();
			
			obj['NAME'] = _name;
			obj['ID'] = _id;
			obj['NUM'] = _num;
			
			return obj;
		}		
	}
}