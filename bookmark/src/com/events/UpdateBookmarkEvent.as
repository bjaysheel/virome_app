package com.events
{
	import flash.events.Event;
	
	public class UpdateBookmarkEvent extends BookmarkEvent
	{
		public static const UPDATE_BOOKMARK_EVENT:String = "UpdateBookmarkEvent";

		public function UpdateBookmarkEvent()
		{
			super(UPDATE_BOOKMARK_EVENT,true,true);
		}
		
		override public function clone():Event{
			return new UpdateBookmarkEvent();
		}
	}
}