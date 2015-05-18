package com.component
{
	import com.ChartnData;
	import com.MyUtility;
	import com.events.SetSearchDBFormEvent;
	
	import flash.events.MouseEvent;
	
	import mx.charts.HitData;
	import mx.charts.PieChart;
	import mx.charts.events.ChartEvent;
	import mx.charts.events.ChartItemEvent;
	import mx.charts.series.items.PieSeriesItem;
	import mx.collections.ArrayCollection;
	import mx.controls.Alert;
	import mx.managers.ToolTipManager;
	
	public class MyPieChart extends PieChart
	{
		private var _util:MyUtility = new MyUtility;
		public var _library:String = "";
		public var _title:String = "";
		
		public function MyPieChart()
		{
			super();
			
			//set style
			this.showDataTips = true;
			this.maxHeight = 300;
			this.maxWidth = 300;
			this.setStyle("paddingLeft",0);
			this.setStyle("paddingRight",0);
			this.setStyle("paddingTop",0);
			this.setStyle("paddingBottom",0);
			
			this.dataTipFunction = myDataTipFunction;
			
			ToolTipManager.toolTipClass = MyToolTip;
			
			//event listener
			this.addEventListener(ChartItemEvent.ITEM_CLICK,showSliceDetail);
			this.addEventListener(ChartItemEvent.ITEM_ROLL_OVER,chart_rollOver);
		}
		
		private function myDataTipFunction(item:HitData):String{
			var pSI:PieSeriesItem = item.chartItem as PieSeriesItem;
			return "<b>" + pSI.item.type + "</b><br/>" +
				pSI.item.count + " (<i>" +
				pSI.percentValue.toFixed(2) + "%</i>)<br/><br/>" +
				_util.viewData+"<br/>"+
				_util.downloadChart+"<br/>"+
				_util.viewRawNumbers;
		}
		
		private function chart_rollOver(event:ChartItemEvent):void{
			this.showDataTips = true;
		}
		
		private function chartClick(event:MouseEvent):void{
			new ChartnData(event,event.currentTarget._library,event.currentTarget._title);
		}
		
		private function showSliceDetail(event:ChartItemEvent):void{
			if (event.shiftKey || event.ctrlKey){
				chartClick(event as MouseEvent);
				return;
			}
			
			pieHighlight(event.hitData.chartItem.index);
			this.showDataTips = false;
			
			if (event.hitData.chartItem.item.idList == "NULL"){
				Alert.show ("There are no results for this selection.  If you need particular sequences please contact\n"+
							"Dr. K. E. Wommack via email at wommack@dbi.udel.edu, with a specific query.\n\n"+ 
							"Please be sure to attach the following information\n\n" +
							"	LibraryId: " + event.hitData.chartItem.item.library + "\n" +
							"	Environment: " + event.hitData.chartItem.item.environment + "\n\n" +
							"Thank you.", "", mx.controls.Alert.OK);
			} else {
				var setSearchEvent:SetSearchDBFormEvent = new SetSearchDBFormEvent();
				setSearchEvent.environment = event.hitData.chartItem.item.environment;
				setSearchEvent.library = event.hitData.chartItem.item.library;
				
				if (event.hitData.chartItem.item.database != undefined){
					setSearchEvent.blastDB = event.hitData.chartItem.item.database;
				}
				if (event.hitData.chartItem.item.type != undefined){
					if ((event.hitData.chartItem.item.type == "Archaea") || 
						(event.hitData.chartItem.item.type == "Bacteria") ||
						(event.hitData.chartItem.item.type == "Eukaryota") ||
						(event.hitData.chartItem.item.type == "Viruses") ||
						(event.hitData.chartItem.item.type == "Unclassified")){
							setSearchEvent.inTax = "domain";
							setSearchEvent.taxonomy = event.hitData.chartItem.item.type;
					}
					
					if (event.hitData.chartItem.item.type == "complete"){
						setSearchEvent.orftype = "complete";
						setSearchEvent.evalue = 0.1;
						setSearchEvent.blastDB = "";
					} else if ((event.hitData.chartItem.item.type == "lack_stop") || (event.hitData.chartItem.item.type == "lack stop")){
						setSearchEvent.orftype = "lackstop";
						setSearchEvent.evalue = 0.1;
						setSearchEvent.blastDB = "";
					} else if ((event.hitData.chartItem.item.type == "lack_start") || (event.hitData.chartItem.item.type == "lack start")){
						setSearchEvent.orftype = "lackstart";
						setSearchEvent.evalue = 0.1;
						setSearchEvent.blastDB = "";
					} else if (event.hitData.chartItem.item.type == "lack both ends"){
						setSearchEvent.orftype = "incomplete";
						setSearchEvent.evalue = 0.1;
						setSearchEvent.blastDB = "";
					}
						
					if (event.hitData.chartItem.item.type == "tRNA") {
						setSearchEvent.vircat = "tRNA";
						setSearchEvent.evalue = 0.1;
					} else if (event.hitData.chartItem.item.type == "rRNA") {
						setSearchEvent.vircat = "rRNA";
						setSearchEvent.evalue = 0.1;
					} else if (event.hitData.chartItem.item.type == "ORFans") {
						setSearchEvent.vircat = "orfan";
						setSearchEvent.evalue = 0.1;
						setSearchEvent.blastDB = "NOHIT";
					} else if (event.hitData.chartItem.item.type == "Top viral hit"){
						setSearchEvent.vircat = "topviral";
						setSearchEvent.blastDB = "METAGENOMES";
					} else if (event.hitData.chartItem.item.type == "Only viral hit"){
						setSearchEvent.vircat = "allviral";
						setSearchEvent.blastDB = "METAGENOMES";
					} else if (event.hitData.chartItem.item.type == "Top microbial hit"){
						setSearchEvent.vircat = "topmicrobial";
						setSearchEvent.blastDB = "METAGENOMES";
					} else if (event.hitData.chartItem.item.type == "Only microbial hit"){
						setSearchEvent.vircat = "allmicrobial";
						setSearchEvent.blastDB = "METAGENOMES";	
					}else if (event.hitData.chartItem.item.type == "Functional protein"){
						setSearchEvent.vircat = "fxn";
						setSearchEvent.blastDB = "";
					}else if (event.hitData.chartItem.item.type == "Unassigned protein"){
						setSearchEvent.vircat = "unassignfxn";
						setSearchEvent.blastDB = "";
					}
				} 
				
				_util.simulateSearchClick(setSearchEvent);
			}
		}
	
		/*
		* This function "explodes" a piece of pie from a pie chart
		* @param pieName  The name of the pie chart that is to be modified
		* @param pieIndex The index of the pie piece that is to be modified
		*/
		private function pieHighlight(pieIndex:int):void
		{
			 var explodeData:Array = [];  //create an empty array
			 explodeData[ pieIndex ] = 0.10; //Set the index of our pie piece to > 0
			 this.series[0].perWedgeExplodeRadius = explodeData;
			 /*
			 The pie's wedges can be "exploded" outward to highlight them. The amount is 
			 controlled by an array, so we just create a empty array (which would set 
			 everything to no padding) and add padding for the index that is to be 
			 highlighted. This has the added bonus of un-highlighting the piece that was last 
			 highlighted (if any). Sweet!
 			*/
		}
	}
}