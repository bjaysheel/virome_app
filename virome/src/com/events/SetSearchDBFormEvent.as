package com.events
{
	import com.events.SearchEvent;
	import flash.events.Event;
	
	public class SetSearchDBFormEvent extends SearchEvent
	{
		public static const SET_SEARCH_DB_FORM_EVENT:String = "SetSearchDBFormEvent";
		
		public function SetSearchDBFormEvent(){
			super(SET_SEARCH_DB_FORM_EVENT, false, true);		
		}
		
		override public function clone():Event{
			return new SetSearchDBFormEvent();
		}
		
		
	}
}