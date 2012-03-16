package com.events
{
	import flash.events.Event;

	public class UpdateHitEvent extends Event
	{
		public static const UPDATE_HIT_EVENT:String = "UpdateHitEvent";
		
		private var _selIdx:Number;
		
		public function UpdateHitEvent(){
			super(UPDATE_HIT_EVENT, false, true);
			_selIdx = 0;
		}
		
		override public function clone() : Event{
			return new UpdateHitEvent();
		}
		
		public function set selIdx(v:Number):void{
			_selIdx = v;
		}
		public function get selIdx():Number{
			return _selIdx;
		}
		
		public function get struct():Object{
			var obj:Object = new Object();
			obj['SELECTEDIDX'] = _selIdx;
			
			return obj;
		}
	}
}