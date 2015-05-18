package com.events
{
	import flash.events.Event;
	import mx.utils.ObjectUtil;
	
	public class SearchEvent extends Event
	{
		private var _blastDB:String;
		private var _environment:String;
		private var _library:Number;
		private var _sequenceId:String;
		private var _sequence:String;
		private var _evalue:Number;
		private var _orftype:String;
		private var _vircat:String;
		private var _term:String;
		private var _inTerm:String;
		private var _taxonomy:String;
		private var _inTax:String;
		private var _accession:String;
		private var _inAcc:String;
		private var _pending:Boolean;
		private var _readId:String;
		private var _recall:Object;
		private var _tag:String;
		private var _idFile:String;
		
		public function SearchEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
			
			_blastDB=null;
			_environment=null;
			_library=-1;
			_evalue=0.001;
			_orftype=null;
			_vircat=null;
			_sequenceId=null;
			_sequence=null;
			_term=null;
			_inTerm=null;
			_taxonomy=null;
			_inTax=null;
			_accession=null;
			_inAcc=null;
			_pending=false;
			_readId=null;
			_recall=null;
			_tag=null;
			_idFile=null;
		}
		
		public function get blastDB():String{
			return _blastDB;
		}
		public function get environment():String{
			return _environment;
		}
		public function get library():Number{
			return _library;
		}
		public function get sequenceId():String{
			return _sequenceId;
		}
		public function get sequence():String{
			return _sequence;
		}
		public function get evalue():Number{
			return _evalue;
		}
		public function get orftype():String{
			return _orftype;
		}
		public function get vircat():String{
			return _vircat;
		}
		public function get term():String{
			return _term;
		}
		public function get inTerm():String{
			return _inTerm;
		}
		public function get taxonomy():String{
			return _taxonomy;
		}
		public function get inTax():String{
			return _inTax;
		}
		public function get accession():String{
			return _accession;
		}
		public function get inAcc():String{
			return _inAcc;
		}
		public function get pending():Boolean{
			return _pending;
		}
		public function get readId():String{
			return _readId;
		}
		public function get recall():Object{
			return _recall;
		}
		public function get tag():String{
			return _tag;
		}
		public function get idFile():String{
			return _idFile;
		}
		
		public function set blastDB(v:String):void{
			_blastDB=v;
		}
		public function set environment(v:String):void{
			_environment=v;
		}
		public function set library(v:Number):void{
			_library=v;
		}
		public function set sequenceId(v:String):void{
			_sequenceId=v;
		}
		public function set sequence(v:String):void{
			_sequence=v;
		}
		public function set evalue(v:Number):void{
			_evalue=v;
		}
		public function set vircat(v:String):void{
			_vircat = v;
		}
		public function set orftype(v:String):void{
			_orftype = v;
		}
		public function set term(v:String):void{
			_term=v;
		}
		public function set inTerm(v:String):void{
			_inTerm=v;
		}
		public function set taxonomy(v:String):void{
			_taxonomy=v;
		}
		public function set inTax(v:String):void{
			_inTax=v;
		}
		public function set accession(v:String):void{
			_accession=v;
		}
		public function set inAcc(v:String):void{
			_inAcc=v;
		}
		public function set pending(v:Boolean):void{
			_pending=v;
		}
		public function set readId(v:String):void{
			_readId=v;
		}
		public function set recall(v:Object):void{
			_recall = ObjectUtil.copy(v);
		}
		public function set tag(v:String):void{
			_tag=v;
		}
		public function set idFile(v:String):void{
			_idFile=v;
		}
		
		public function getStruct():Object{
			var obj:Object = new Object();
			
			obj['BLASTDB'] = _blastDB;
			obj['ENVIRONMENT'] = _environment;
			obj['LIBRARY'] = _library;
			obj['SEQUENCEID'] = _sequenceId;
			obj['SEQUENCE'] = _sequence;
			obj['EVALUE'] = _evalue;
			obj['ORFTYPE'] = _orftype;
			obj['VIRCAT'] = _vircat;
			obj['TERM'] = _term;
			obj['INTERM'] = _inTerm;
			obj['TAXONOMY'] = _taxonomy;
			obj['INTAXONOMY'] = _inTax;
			obj['ACCESSION'] = _accession;
			obj['INACCESSION'] = _inAcc;
			obj['PENDING'] = _pending;
			obj['READID'] = _readId;
			obj['RECALL'] = _recall;
			obj['TAG'] = _tag;
			obj['IDFILE'] = _idFile;
			
			return obj;
		}
		
		public function duplicateEvent(o:Object):void{
			blastDB = o.BLASTDB;
			environment = o.ENVIRONMENT;
			library = o.LIBRARY;
			sequenceId = o.SEQUENCEID;
			sequence = o.SEQUENCE;
			evalue = o.EVALUE;
			orftype = o.ORFTYPE;
			vircat = o.VIRCAT;
			term = o.TERM;
			inTerm = o.INTERM;
			taxonomy = o.TAXONOMY;
			inTax = o.INTAXONOMY;
			accession = o.ACCESSION;
			inAcc = o.INACCESSION;
			pending = o.PENDING;
			readId = o.READID;
			recall = o.RECALL;
			tag = o.TAG;
			idFile = o.IDFILE;
		}
	}
}