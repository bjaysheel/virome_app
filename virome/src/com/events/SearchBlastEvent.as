package com.events
{
	import flash.events.Event;

	public class SearchBlastEvent extends Event
	{
		private var blastResult:String;
		
		public static const SEARCH_BLAST_EVENT:String = "SearchBlastEvent";
		
		public function SearchBlastEvent(str:String)
		{
			super(SEARCH_BLAST_EVENT,true,true);
			blastResult = str;
		}
		
		override public function clone():Event{
			return new SearchBlastEvent(blastResult);
		}
		
		public function setBlastResult(v:String):void{
			blastResult = v;
		}
		
		public function getBlastResult():String{
			return blastResult;
		}
		
	}
}