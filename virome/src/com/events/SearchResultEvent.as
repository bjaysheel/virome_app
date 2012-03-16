package com.events
{
	import flash.events.Event;
	import mx.collections.ArrayCollection;

	public class SearchResultEvent extends Event
	{
		private var srch_rslt:Array;
		
		public static const SEARCH_RESULT_EVENT:String = "SearchResultEvent";
		
		public function SearchResultEvent(v:Array)
		{
			super(SEARCH_RESULT_EVENT,true,true);			
			srch_rslt = v;
		}
		
		public function setSearchResult(v:Array):void{
			srch_rslt = v;
		}
		
		public function getSearchResult():Array{
			return srch_rslt
		}
		
		override public function clone():Event{
			return new SearchResultEvent(srch_rslt);
		}
		
	}
}