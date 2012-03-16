package com
{
	public class GeneralObject
	{
		private var _libraryId:Number;  //library Id
		private var _libraryIdList:String; //list of library ids
		private var _groupId:String;  //group Id
		private var _userId:Number; //userId
		private var _environment:String; //environment
		private var _db:String; //database
		private var _sType:String; //stats type
		
		public function GeneralObject()
		{
			libraryId=-1;
			libraryIdList='';
			userId=-1;
			groupId='';
			environment = '';
			db = '';
			sType = '';
		}

		public function get libraryIdList():String
		{
			return _libraryIdList;
		}

		public function set libraryIdList(value:String):void
		{
			_libraryIdList = value;
		}

		public function get userId():Number
		{
			return _userId;
		}

		public function set userId(value:Number):void
		{
			_userId = value;
		}

		public function get sType():String
		{
			return _sType;
		}

		public function set sType(value:String):void
		{
			_sType = value;
		}

		public function get db():String
		{
			return _db;
		}

		public function set db(value:String):void
		{
			_db = value;
		}

		public function get environment():String
		{
			return _environment;
		}

		public function set environment(value:String):void
		{
			_environment = value;
		}

		public function get groupId():String
		{
			return _groupId;
		}

		public function set groupId(value:String):void
		{
			_groupId = value;
		}

		public function get libraryId():Number
		{
			return _libraryId;
		}

		public function set libraryId(value:Number):void
		{
			_libraryId = value;
		}
		
		public function get struct():Object{
			var obj:Object = new Object();
			
			obj['LIBRARYID'] = _libraryId;
			obj['LIBRARYIDLIST'] = _libraryIdList;
			obj['GROUPID'] = _groupId;
			obj['USERID'] = _userId;
			obj['ENVIRONMENT'] = _environment;
			obj['DB'] = _db;
			obj['STYPE'] = _sType;
			
			return obj;
		}
		
		public function duplicate(e:GeneralObject):void{
			libraryId = e.libraryId;
			libraryIdList = e.libraryIdList;
			environment = e.environment;
			groupId = e.groupId;
			userId = e.userId;
			db = e.db;
			sType = e.sType;
		}
	}
}