package com.events
{
	import flash.events.Event;
	
	public class BIOMSelectorEvent extends Event
	{
		private var _libraryIdList:String;
		private var _xtype:String;
		private var _output:String;
		
		public static const BIOM_SELECTOR_EVENT:String = "BIOMSelectorEvent";
		
		public function BIOMSelectorEvent()
		{
			super(BIOM_SELECTOR_EVENT,true,true);
			
			libraryIdList = "";
			xtype = "";
			output = "";
		}
		
		public function get libraryIdList():String
		{
			return _libraryIdList;
		}
		
		public function set libraryIdList(value:String):void
		{
			_libraryIdList = value;
		}
		
		public function get xtype():String
		{
			return _xtype;
		}
		
		public function set xtype(value:String):void
		{
			_xtype = value;
		}
		
		public function get output():String
		{
			return _output;
		}
		
		public function set output(value:String):void
		{
			_output = value;
		}
		
		override public function clone():Event{
			return new BIOMSelectorEvent();
		}
		
		public function getBIOMSelectorObject():Object{
			var obj:Object = new Object();
			obj['libraryIdList'] = libraryIdList;
			obj['xtype'] = xtype;
			obj['output'] = output;
			
			return obj;
		}
	}
}