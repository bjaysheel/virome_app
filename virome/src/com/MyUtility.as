package com
{
	import com.component.MyAlert;
	import com.events.SetSearchDBFormEvent;
	import com.google.analytics.AnalyticsTracker;
	import com.google.analytics.GATracker;
	
	import flash.display.DisplayObject;
	import flash.events.*;
	import flash.net.*;
	
	import mx.charts.*;
	import mx.charts.chartClasses.ChartBase;
	import mx.controls.Alert;
	import mx.core.FlexGlobals;
	import mx.events.ToolTipEvent;
	import mx.formatters.NumberFormatter;
	import mx.managers.ToolTipManager;
	import mx.rpc.events.FaultEvent;
	
	public class MyUtility
	{
		[Bindable] private var _app:virome = FlexGlobals.topLevelApplication as virome;
		private var _viromeLSO:SharedObject = SharedObject.getLocal("viromeLocalSharedObject");
		private var _endpoint:String = "";
		private var _cfcPath:String = "";
		private var _trackerId:String = "";
		private var _mapKey:String = "";
		private var _os:String = "";
		
		private var _contactEmail:String = "bjaysheel@gmail.com";
		private var _downloadChart:String = "SHIFT+Click = download chart";
		private var _viewRawNumbers:String = "CMD+Click = download raw numbers";
		private var _doubleClick:String = "Double Click = view data";
		private var _viewData:String = "Click = view data";
		private var _zoomIn:String = "Click = zoom in/drill down";
		
		private var tracker:AnalyticsTracker;
		
		private var parsing:Boolean = false;
		
		public function MyUtility(){
			app = FlexGlobals.topLevelApplication as virome;
			_viromeLSO = SharedObject.getLocal("viromeLocalSharedObject");
			
			//var from js
			endpoint = app.hostEndPoint;
			cfcPath = app.cfcObjectPath;
			trackerId = app.trackerId;
			mapKey = app.mapKey;
			os = app.os;
			
			if (os != "Mac"){
				viewRawNumbers = "CTRL+Click = download raw numbers";
			}
		}

		public function get zoomIn():String {
			return _zoomIn;
		}
		public function get doubleClick():String {
			return _doubleClick;
		}
		public function get viewData():String {
			return _viewData;
		}
		public function get viewRawNumbers():String {
			return _viewRawNumbers;
		}
		public function get downloadChart():String {
			return _downloadChart;
		}
		public function get contactEmail():String {
			return _contactEmail;
		}
		public function get app():virome{
			return _app;
		}
		public function get endpoint():String{
			return _endpoint;
		}
		public function get cfcPath():String{
			return _cfcPath;
		}
		public function get trackerId():String{
			return _trackerId;
		}
		public function get mapKey():String{
			return _mapKey;
		}
		public function get os():String{
			return _os;
		}

		public function set zoomIn(value:String):void {
			_zoomIn = value;
		}
		public function set viewData(value:String):void {
			_viewData = value;
		}
		public function set doubleClick(value:String):void {
			_doubleClick = value;
		}
		public function set viewRawNumbers(value:String):void {
			_viewRawNumbers = value;
		}
		public function set downloadChart(value:String):void {
			_downloadChart = value;
		}
		public function set contactEmail(value:String):void {
			_contactEmail = value;
		}
		[Bindable] public function set app(m:virome):void{
			_app = m;
		}
		[Bindable] public function set endpoint(s:String):void{
			_endpoint = s;
		}
		[Bindable] public function set cfcPath(s:String):void{
			_cfcPath = s;
		}
		[Bindable] public function set trackerId(s:String):void{
			_trackerId = s;
		}
		[Bindable] public function set mapKey(s:String):void{
			_mapKey = s;
		}
		[Bindable] public function set os(s:String):void{
			_os = s;
		}
		
		public function setTracker(str:String):void{
			_app.tracker.trackPageview( str );
			Alert.show("sending tracker " + str);
		}
		
		public function getViromeLSO():SharedObject{
			return _viromeLSO;
		}
		
		public function setViromeLSO(s:Object):void{
			_viromeLSO.clear();
			_viromeLSO = SharedObject.getLocal("viromeLocalSharedObject");
			_viromeLSO.data.name = "VIROME_COOKIE";
			_viromeLSO.data.text = s;
			_viromeLSO.flush(); //write cookie to disk
		}
		
		public function clearLSO():void{
			_viromeLSO.clear();
		}
		
		public function str_replace( replace_with:String, replace:String, original:String ):String
		{
			var array:Array = original.split(replace_with);
			return array.join(replace);
		}
		
		public function followUNIREF(event:MouseEvent):void{
			var url:URLRequest = new URLRequest("http://www.uniprot.org/uniprot/"+event.currentTarget.label);
			navigateToURL(url,"_blank");
		}
		
		public function followUNIPARC(event:MouseEvent):void{
			var url:URLRequest = new URLRequest("http://www.uniprot.org/uniparc/"+event.currentTarget.label);
			navigateToURL(url,"_blank");
		}
		
		public function followSEED(event:MouseEvent):void{
			var url:URLRequest = new URLRequest("http://seed-viewer.theseed.org/seedviewer.cgi?page=Annotation&feature="+event.currentTarget.label);
			navigateToURL(url,"_blank");
		}
		
		public function followKEGG(event:MouseEvent):void{
			var url:URLRequest = new URLRequest("http://www.genome.jp/dbget-bin/www_bget?"+event.currentTarget.label);
			navigateToURL(url,"_blank");
		}
		
		public function followCOG(event:MouseEvent):void{
			var url:URLRequest = new URLRequest("http://www.ncbi.nlm.nih.gov/COG/grace/blyz.cgi?cog="+event.currentTarget.label+"&"+event.currentTarget.label);
			navigateToURL(url,"_blank");
		}
		
		public function followACLAME(event:MouseEvent):void{
			var url:URLRequest = new URLRequest("http://aclame.ulb.ac.be/perl/Aclame/Genomes/prot_view.cgi?view=prot&id="+event.currentTarget.label);
			navigateToURL(url,"_blank");
		}
		
		public function followLink(event:MouseEvent):void{
			var url:URLRequest = new URLRequest(event.currentTarget.name);
			navigateToURL(url,"_blank");
		}
		
		public function faultHandler(event:FaultEvent):void{
			var myalert:MyAlert = new MyAlert();
			myalert.error = true;
			myalert.show(event.toString());
		}
		
		public function formatNum(n:Number):String{
			var formatter:NumberFormatter = new NumberFormatter;
			formatter.precision = 2;
			
			return formatter.format(n);
		}
		
		public function properCase(s:String):String{
			var arr:Array = s.split(" ");
			var t:String = null;
			
			for (var i:int=0; i<arr.length; i++){
				var str:String = arr[i].toLocaleLowerCase();

				if ((i > 0) && (t != null)){
					t = t.concat(" ");
					t = t.concat(str.substr(0,1).toLocaleUpperCase());
					t = t.concat(str.substr(1,str.length));
				} else {
					t = str.substr(0,1).toLocaleUpperCase();
					t = t.concat(str.substr(1,str.length));
				}
			}
			
			return t;
		}
		
		public function toScientific(num:String, sigDigs:Number):String {
			//deal with messy input values
			var n:Number = Number(num); //try to convert to a number
			if (isNaN(n)) return "NaN"; //garbage in, NaN out
			
			//find exponent using logarithm
			//e.g. log10(150) = 2.18 -- round down to 2 using floor()
			var exponent:Number = Math.floor(Math.log(Math.abs(n)) / Math.LN10); 
			if (n == 0) exponent = 0; //handle glitch if the number is zero
			
			//find mantissa (e.g. "3.47" is mantissa of 3470; need to divide by 1000)
			var tenToPower:Number = Math.pow(10, exponent);
			var mantissa:Number = n/tenToPower;
			
			//force significant digits in mantissa
			//e.g. 3 sig digs: 5 -> 5.00, 7.1 -> 7.10, 4.2791 -> 4.28
			var output:String = formatDecimals(mantissa, sigDigs-1); //use custom function
			//if exponent is zero, don't include e
			if (exponent != 0) {
				output += "e" + exponent;
			}
			return(output);
		}
		
		public function formatDecimals(num:Number, digits:Number):String {
			//if no decimal places needed, we're done
			if (digits <= 0) {
				return Math.round(num).toString(); 
			} 
			//round the number to specified decimal places
			//e.g. 12.3456 to 3 digits (12.346) -> mult. by 1000, round, div. by 1000
			var tenToPower:Number = Math.pow(10, digits);
			var cropped:String = String(Math.round(num * tenToPower) / tenToPower);
			
			//add decimal point if missing
			if (cropped.indexOf(".") == -1) {
				cropped += ".0";  //e.g. 5 -> 5.0 (at least one zero is needed)
			}
			
			//finally, force correct number of zeroes; add some if necessary
			var halves:Array = cropped.split("."); //grab numbers to the right of the decimal
			//compare digits in right half of string to digits wanted
			var zerosNeeded:Number = digits - halves[1].length; //number of zeros to add
			for (var i:int=1; i <= zerosNeeded; i++) {
				cropped += "0";
			}
			return(cropped);
		}
		
		public function simulateSearchClick(event:SetSearchDBFormEvent):void{
			this.app.simulateMenuClick('search');
			this.app.dispatchEvent(event);
		}
		
		public function chartNdataTip(event:ToolTipEvent):void{
			var str:String = "";
			str += downloadChart+"\n" + viewRawNumbers;

			ToolTipManager.currentToolTip.text = str;
		}

		public function allTips(event:ToolTipEvent):void{
			var str:String = "";
			str += downloadChart+"\n" + viewRawNumbers + "\n" + zoomIn + "\n" + doubleClick;
			
			ToolTipManager.currentToolTip.text = str;
		}
	}
	
}