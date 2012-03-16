package com.events
{
	import flash.events.Event;
	
	public class RecallBookmarkEvent extends BookmarkEvent
	{
		public static const RECALL_BOOKMARK_EVENT:String = "RecallBookmarkEvent";
		
		public function RecallBookmarkEvent()
		{
			super(RECALL_BOOKMARK_EVENT,true,true);
		}
		
		override public function clone():Event{
			return new RecallBookmarkEvent();
		}
	}
}