package com.events
{
	import flash.events.Event;
	import mx.utils.ObjectUtil;
	
	public class BookmarkEvent extends Event
	{		
		private var _jobId:Number;
		private var _userId:String;
		private var _jobName:String;
		private var _jobAlias:String;
		private var _searchParam:Object;
		
		public function BookmarkEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false){
			super (type,bubbles,cancelable);
			_jobId = -1;
			_userId = null;
			_jobName = null;
			_jobAlias = null;
			_searchParam = null;
		}
		
		public function get jobId():Number{
			return _jobId;
		}
		public function get userId():String{
			return _userId;
		}
		public function get jobName():String{
			return _jobName;
		}
		public function get jobAlias():String{
			return _jobAlias;
		}
		public function get searchParam():Object{
			return _searchParam;
		}
		
		public function set jobId(n:Number):void{
			_jobId = n;
		}
		public function set userId(n:String):void{
			_userId = n;
		}
		public function set jobName(s:String):void{
			_jobName = s;
		}
		public function set jobAlias(s:String):void{
			_jobAlias = s;
		}
		public function set searchParam(o:Object):void{
			_searchParam = ObjectUtil.copy(o);
		}
		
		/*override public function clone():Event{
			return new BookmarkEvent();
		}*/
		
		public function getObj():Object{
			var obj:Object = new Object();
			
			obj['USERID'] = userId;
			obj['JOBID'] = jobId;
			obj['JOBNAME'] = jobName;
			obj['JOBALIAS'] = jobAlias;
			obj['SEARCHPARAM'] = searchParam;
			
			return obj;
		}		
	}
}