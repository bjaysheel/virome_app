package com.events
{
	import com.events.SearchEvent;
	
	import flash.events.Event;
	
	public class SearchDBEvent extends SearchEvent
	{
		public static const SEARCH_DB_EVENT:String = "SearchDBEvent";
		
		private var _alias:String;
		private var _userId:Number;
		private var _username:String;
		
		public function SearchDBEvent(){
			super(SEARCH_DB_EVENT, false, true);
			
			_alias = null;
			_userId = 0;
			_username = null;
		}
		
		override public function clone() : Event{
			return new SearchDBEvent();
		}
		
	 	public function get alias():String{
			return _alias;
		}
		public function get userId():Number{
			return _userId;
		}
		public function get username():String{
			return _username;
		}
		
		public function set alias(s:String):void{
			_alias = s;
		}
		public function set userId(n:Number):void{
			_userId = n;
		}
		public function set username(s:String):void{
			_username = s;
		}
		
		override public function getStruct():Object{
			var obj:Object = new Object();
			
			obj['BLASTDB'] = super.blastDB;
			obj['ENVIRONMENT'] = super.environment;
			obj['LIBRARY'] = super.library;
			obj['SEQUENCEID'] = super.sequenceId;
			obj['SEQUENCE'] = super.sequence;
			obj['EVALUE'] = super.evalue;
			obj['ORFTYPE'] = super.orftype;
			obj['VIRCAT'] = super.vircat;
			obj['TERM'] = super.term;
			obj['INTERM'] = super.inTerm;
			obj['TAXONOMY'] = super.taxonomy;
			obj['INTAXONOMY'] = super.inTax;
			obj['ACCESSION'] = super.accession;
			obj['INACCESSION'] = super.inAcc;
			obj['PENDING'] = super.pending;
			obj['READID'] = super.readId;
			obj['TAG'] = super.tag;
			obj['IDFILE'] = super.idFile;
			obj['ALIAS'] = alias;
			obj['USERID'] = userId;
			obj['USERNAME'] = username;
			
			return obj;
		}
	}
}