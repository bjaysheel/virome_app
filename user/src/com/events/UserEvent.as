package com.events
{
	import flash.events.Event;
	
	public class UserEvent extends Event
	{
		public static const USER_LOGIN_EVENT:String = "UserLoginEvent";
		
		private var _username:String;
		private var _password:String;
		private var _institute:String;
		private var _email:String;
		private var _firstname:String;
		private var _lastname:String;
		private var _errorcode:Number; //0=bad login, 1=login success
		private var _userId:Number;
		private var _annotation:Number;
		private var _viewdetail:Number;
		private var _god:Number;
		private var _noOfLogin:Number;
		private var _download:Number;
		private var _deleted:Number;
		private var _libraryId:String;
		private var _expire:String;
		private var _login:Boolean;
		
		public function UserEvent(){
			super (USER_LOGIN_EVENT,true,true);
			_userId = -1;
			_username = null;
			_password = null;
			_institute = null;
			_email = null;
			_firstname = null;
			_lastname = null;
			_errorcode = -1;
			_annotation = -1;
			_viewdetail = -1;
			_god = -1;
			_noOfLogin = -1;
			_download = -1;
			_deleted = -1;
			_libraryId = null;
			_expire = null;
			_login = false;
		}
		
		override public function clone():Event{
			return new UserEvent();
		}
		
		public function get username():String{
			return _username;
		}
		
		public function get password():String{
			return _password;
		}
		
		public function get institute():String{
			return _institute;
		}
		
		public function get email():String{
			return _email;
		}
		
		public function get firstname():String{
			return _firstname;
		}
		
		public function get lastname():String{
			return _lastname;
		}
		
		public function get errorCode():Number{
			return _errorcode;
		}
		
		public function get userId():Number{
			return _userId;
		}
		
		public function get annotation():Number{
			return _annotation;
		}
		
		public function get viewDetail():Number{
			return _viewdetail;
		}
		
		public function get god():Number{
			return _god;
		}
		
		public function get noOfLogin():Number{
			return _noOfLogin;
		}
		
		public function get download():Number{
			return _download;
		}
		
		public function get deleted():Number{
			return _deleted;
		}
		
		public function get libraryId():String{
			return _libraryId;
		}
		
		public function get expire():String{
			return _expire;
		}
		
		public function get login():Boolean{
			return _login;
		}
		
		public function set download(v:Number):void{
			_download = v;
		}
		
		public function set noOfLogin(v:Number):void{
			_noOfLogin = v;
		}
		
		public function set god(v:Number):void{
			_god = v;
		}
		
		public function set viewDetail(v:Number):void{
			_viewdetail = v;
		}
		
		public function set annotation(v:Number):void{
			_annotation = v;
		}
		
		public function set userId(v:Number):void{
			_userId = v;
		}
		
		public function set errorCode(v:Number):void{
			_errorcode = v;
		}
		
		public function set lastname(v:String):void{
			_lastname = v;
		}
		
		public function set firstname(v:String):void{
			_firstname = v;
		}
		
		public function set email(v:String):void{
			_email = v;
		}
		
		public function set institute(v:String):void{
			_institute = v;
		}
		
		public function set password(v:String):void{
			_password = v;
		}
		
		public function set username(v:String):void{
			_username = v;
		}
		
		public function set deleted(v:Number):void{
			_deleted = v;
		}
		
		public function set libraryId(v:String):void{
			_libraryId = v;
		}
		
		public function set expire(v:String):void{
			_expire = v;
		}
		
		public function set login(v:Boolean):void{
			_login = v;
		}
		
		public function get UserObj():Object{
			var obj:Object = new Object();
			
			obj['USERNAME'] = _username;
			obj['PASSWORD'] = _password;
			obj['FIRSTNAME'] = _firstname;
			obj['LASTNAME'] = _lastname;
			obj['USERID'] = _userId;
			obj['EMAIL'] = _email;
			obj['INSTITUTE'] = _institute;
			obj['ANNOTATION'] = _annotation;
			obj['VIEWDETAIL'] = _viewdetail;
			obj['GOD'] = _god;
			obj['NOOFLOGIN'] = _noOfLogin;
			obj['DOWNLOAD'] = _download;
			obj['DELETED'] = _deleted;
			obj['EXPIRE'] = _expire;
			obj['LIBRARYID'] = _libraryId;
			obj['LOGIN'] = _login;
			
			return obj;
		}
		
		public function copy(o:Object):void{
			username = o.USERNAME;
			password = o.PASSWORD;
			firstname = o.FIRSTNAME;
			lastname = o.LASTNAME;
			userId = o.USERID;
			email = o.EMAIL;
			institute = o.INSTITUTE;
			annotation = o.ANNOTATION;
			noOfLogin = o.NOOFLOGINS;
			libraryId = o.LIBRARYID;
			expire = o.EXPIRE;
		}
		
	}
}