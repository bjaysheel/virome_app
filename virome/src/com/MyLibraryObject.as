package com
{
	import com.component.MyGridItem;
	import com.component.MyGridRow;
	import com.component.MyNumberFormatter;
	import com.component.MyPieChart;
	import com.component.MyPieSeries;
	import com.component.MyToolTip;
	import com.events.LibraryStatEvent;
	
	import flash.events.MouseEvent;
	
	import mx.collections.ArrayCollection;
	import mx.containers.Grid;
	import mx.containers.HBox;
	import mx.containers.VBox;
	import mx.controls.Alert;
	import mx.controls.Button;
	import mx.controls.Label;
	import mx.controls.LinkButton;
	import mx.controls.Text;
	import mx.formatters.NumberFormatter;
	import mx.graphics.ImageSnapshot;
	import mx.graphics.SolidColor;
	import mx.managers.ToolTipManager;

	public class MyLibraryObject extends Grid{
		
		private var util:MyUtility = new MyUtility;
		private var _seriesColor:Array;
		private var nf:NumberFormatter = new NumberFormatter();
		[Embed(source='/assets/icons/Download.png')] [Bindable] private var dl:Class;
		
		public function MyLibraryObject(){
			super();
			_seriesColor = new Array();
			
			nf.precision=0;
			
			this.percentHeight=100;
			this.percentWidth=100;
			this.setStyle("verticalGap",0);
			this.setStyle("paddingBottom",0);
			this.setStyle("paddingTop",0);
			this.addChild(getHeader());
		}
						
		public function setSeriesColor(type:String):void{
			_seriesColor = new Array();
			
			if (type == "type"){
				_seriesColor.push(new SolidColor(0xEE2E01,1));
				_seriesColor.push(new SolidColor(0x008FEF,1));
				_seriesColor.push(new SolidColor(0x1AD001,1));
				_seriesColor.push(new SolidColor(0xECB500,1));
			}
			if (type == "domain"){
				_seriesColor.push(new SolidColor(0x3699D4,1));
				_seriesColor.push(new SolidColor(0xACB55B,1));
				_seriesColor.push(new SolidColor(0x6C94AE,1));
				_seriesColor.push(new SolidColor(0xCCC7A2,1));
				_seriesColor.push(new SolidColor(0xDB882E,1));
			}
			if (type == "vircat"){
				_seriesColor.push(new SolidColor(0xBFBFC1,1));
				_seriesColor.push(new SolidColor(0x808080,1));
				_seriesColor.push(new SolidColor(0x7F99B2,1));
				_seriesColor.push(new SolidColor(0xC6BE8D,1));
				_seriesColor.push(new SolidColor(0xCC6601,1));
				_seriesColor.push(new SolidColor(0x990100,1));
				_seriesColor.push(new SolidColor(0xCCD6E0,1));
				_seriesColor.push(new SolidColor(0xF7F0C6,1)); 
			}
		}


		public function getChart(dataSet:ArrayCollection,str:String,title:String,library:String):MyPieChart{
			var chart:MyPieChart = new MyPieChart;
			
			ToolTipManager.toolTipClass = MyToolTip;
			
			chart.dataProvider = dataSet;
			chart.height = 250;
			chart.width = 250;
			
			var mySeries:MyPieSeries = new MyPieSeries;
			setSeriesColor(str);
			if (_seriesColor.length)
				mySeries.Fills = _seriesColor;
			
			chart.series = [mySeries];	
			chart._library = library;
			chart._title = title;
			
			return chart;
		}
		
		protected function getHeader():MyGridRow{
			var gr:MyGridRow = new MyGridRow();
			var gi:MyGridItem = new MyGridItem();
			
			gr.header();
			
			var head:Label = new Label();
			head.text = "Library Summary";
			head.styleName = "header";
			gi.addChild(head);
			gr.addChild(gi);

			head = new Label();
			gi = new MyGridItem();
			head.text = "VIROME Categories"
			head.styleName = "header";
			gi.addChild(head);
			gr.addChild(gi);
			
			head = new Label();
			gi = new MyGridItem();
			head.text = "ORF Type"
			head.styleName = "header";
			gi.addChild(head);
			gr.addChild(gi);
			
			head = new Label();
			gi = new MyGridItem();
			head.text = "Taxonomy (domain)"
			head.styleName = "header";
			gi.addChild(head);
			gr.addChild(gi);
			
			return gr;
		}
		
		public function makeGrid(arr:Array):void{
			var gr:MyGridRow;
			var gi:MyGridItem;
			
			for (var i:int=0; i<arr.length; i++){
				gi = new MyGridItem();
				gr = new MyGridRow();
				
				if ((i%2) == 0)
					gr.even();
				else gr.odd();
				
				//add library name and prefix
				gi.v_center();
				gi.addChild(getSummary(arr[i]));
				gr.addChild(gi);
				
				//add virome categories.
				gi = new MyGridItem();
				gi.v_center();
				if (arr[i].DETAIL.VIRCAT != undefined)
					gi.addChild(getChart(new ArrayCollection(arr[i].DETAIL.VIRCAT as Array),"vircat","VIROME_Category",arr[i].LIBNAME));
				gr.addChild(gi);
				
				//add orf type.
				gi = new MyGridItem();
				gi.v_center();
				if (arr[i].DETAIL.ORFTYPE != undefined)
					gi.addChild(getChart(new ArrayCollection(arr[i].DETAIL.ORFTYPE as Array),"type","ORF_Type",arr[i].LIBNAME));
				gr.addChild(gi);
				
				//add orf Model.
				gi = new MyGridItem();
				gi.v_center();
				if (arr[i].DETAIL.DOMAIN != undefined)
					gi.addChild(getChart(new ArrayCollection(arr[i].DETAIL.DOMAIN as Array),"domain","Domain_Tax",arr[i].LIBNAME));
				gr.addChild(gi);
				
				this.addChild(gr);
			}
		}
		
		private function getSummary(obj:Object):VBox{
			var vbox:VBox = new VBox();
			var label:Label = new Label();
			var hbox:HBox = new HBox();
			var txt:Text = new Text();
			var rmbp:Number = 0;
			var ombp:Number = 0;
			var orf:Number = 0;
			
			
			hbox.setStyle("horizontalGap",0);
			vbox.setStyle("verticalGap",0);
			
			label.text = "Library:";
			hbox.addChild(label);
			
			if (obj.CITATION != undefined && obj.CITATION.length){
				var link:LinkButton=new LinkButton();
				//link.addEventListener();
				link.label = obj.LIBNAME + "  ( " + obj.CITATION.substr(0,10) + "..." +" ) ";
				link.toolTip = obj.CITATION;
				link.name = obj.CITATION.substr(0,10);
				//link.addEventListener(MouseEvent.CLICK,goToLink);
				
				/*if (link.name.length){
					link.enabled = true;
				}
				else link.enabled = false;*/
				
				//vbox.addChild(link);
				link.addEventListener(MouseEvent.CLICK,function (e:MouseEvent):void{
					displaylibstat_link(e,obj.LIBID,obj.ENVIRONMENT);
				});
				hbox.addChild(link);
			}
			else {
				var lib:Text = new Text();
				lib.styleName = "strong";
				lib.text = obj.LIBNAME;
				hbox.addChild(lib);
			}
			
			//add library name.
			vbox.addChild(hbox);
			
			//add prefix
			txt = new Text();
			txt.text = obj.PREFIX;
			
			label = new Label();
			label.text = "Prefix:";
			
			hbox = new HBox();
			hbox.addChild(label);
			hbox.addChild(txt);
			
			vbox.addChild(hbox);
			
			if (obj.DETAIL.READ != undefined && obj.DETAIL.ORFTYPE != undefined){
			//get mbp
				rmbp = parseFloat(obj.DETAIL.READ[0]['mbp'])/1000000;
				
				//loop through each type of orf (complete, incomplete, missing start/stop
				var _ot:Array = obj.DETAIL.ORFTYPE as Array;
				for (var i:int=0; i<_ot.length; i++){
					ombp += (parseFloat(_ot[i]['mbp'])*3)/1000000;
					orf += parseFloat(_ot[i]['count']);
				}
				
				label = new Label();
				label.text = "Reads:";
				txt = new Text();
				txt.text = nf.format(parseFloat(obj.DETAIL.READ[0]['count'])) + "   /   " + new MyNumberFormatter().format(rmbp) + "Mbp";
				
				hbox = new HBox();
				hbox.addChild(label);
				hbox.addChild(txt);
				vbox.addChild(hbox);
				
				//add orf mb
				label = new Label();
				label.text = "ORFs:";
				txt = new Text();
				txt.text = nf.format(orf) + "   /   " + new MyNumberFormatter().format(ombp) + "Mbp";
									  
				hbox = new HBox();
				hbox.addChild(label);
				hbox.addChild(txt);
				vbox.addChild(hbox);
				
				//add coding coverage
				if (rmbp > 0)
					vbox.addChild(getCodingDensity(rmbp,ombp));
			}
			
			return vbox;
		}
				
		protected function getLibSize(obj:Object):Text{
			var size:Text = new Text();
			size.text = obj.LIBSIZE;
			
			return size; 
		}
		
		protected function getCodingDensity(v1:Number,v2:Number):HBox{
			var label:Label = new Label();
			label.text = "Coding %: ";
			var t:Text = new Text();
			t.text = new MyNumberFormatter().format((v2/v1)*100) + "%";
			
			var hbox:HBox = new HBox();
			hbox.addChild(label);
			hbox.addChild(t);
			
			return hbox;
		}
				
		protected function displaylibstat_link(e:MouseEvent,id:Number,env:String):void{
			var util:MyUtility = new MyUtility();
			var _ls:LibraryStatEvent = new LibraryStatEvent();
			_ls.library = id;
			_ls.environment = env;
			util.app.simulateMenuClick('statistics');
			util.app.dispatchEvent(_ls);
		}
	}
}