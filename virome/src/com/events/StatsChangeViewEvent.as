package com.events
{
	import flash.events.Event;
	
	public class StatsChangeViewEvent extends Event
	{
		public static const STATS_CHANGE_VIEW_EVENT:String = "StatsChangeViewEvent";
		
		private var _idx:Number;
		private var _name:String;
		
		public function StatsChangeViewEvent(){
			super(STATS_CHANGE_VIEW_EVENT, false, true);
			_name=null
			_idx=0;
		}
		
		override public function clone() : Event{
			return new StatsChangeViewEvent();
		}
		
		public function get idx():Number{
			return _idx;
		}
		public function get name():String{
			return _name;
		}
		public function set idx(v:Number):void{
			_idx=v;
		}
		public function set name(v:String):void{
			_name=v;
		}
	}
}