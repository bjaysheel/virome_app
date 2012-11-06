package com.events
{
	import flash.events.Event;

	public class UpdateORFViewEvent extends Event
	{
		public static const UPDATE_ORF_VIEW_EVENT:String = "UpdateORFViewEvent";
		
		private var _seqName:String;
		
		public function UpdateORFViewEvent()
		{
			super(UPDATE_ORF_VIEW_EVENT, true, true);
			_seqName=null;			
		}
		
		override public function clone() : Event{
			return new UpdateORFViewEvent();
		}
		
		public function get seqName():String{
			return _seqName;
		}
		
		public function set seqName(v: String):void{
			_seqName = v;
		}
		
		public function get struct():Object{
			var obj:Object = new Object();
			
			obj['SEQNAME'] = _seqName;
			return obj;
		}
		
		public function duplicate(e:UpdateORFViewEvent):void{
			seqName = e.seqName;
		}
	}
}