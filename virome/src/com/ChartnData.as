package com
{
	import com.MyUtility;
	import com.component.MyAlert;
	
	import flash.events.MouseEvent;
	import flash.net.FileReference;
	
	import mx.charts.chartClasses.ChartBase;
	import mx.charts.events.ChartEvent;
	import mx.collections.ArrayCollection;
	import mx.collections.XMLListCollection;
	import mx.controls.Alert;

	public class ChartnData
	{
		private var _util:MyUtility = new MyUtility();
		
		public function ChartnData(event:MouseEvent, lib:String, str:String)
		{
			if (event.shiftKey){
				downloadChart(lib,str,event.currentTarget as ChartBase);
			}
			
			if (event.ctrlKey){
				downloadData(lib,str,event.currentTarget as ChartBase);
			}
			
		}
		
		public function downloadChart(lib:String, str:String, chart:ChartBase):void{
			var myPattern:RegExp = /\s+/g;
			var downloadChart:MyDownloadChart = new MyDownloadChart;
			
			if (chart != null) {
				downloadChart.chart = chart;
			} else {
				var alert:MyAlert = new MyAlert();
				alert.error = true;
				alert.show("Chart data is empty");
				return;
			}
			
			lib = lib.replace(myPattern,"_");
			
			downloadChart.chartName = lib+"_"+str;
			downloadChart.download();
		}
		
		public function downloadData(lib:String, str:String, chart:ChartBase):void{
			var filename:String = lib+"_"+str+".txt";
			var myPattern:RegExp = /_/g;
			var returnString:String = "\n";
			
			if (_util.os == "Windows"){
				returnString = "\r\n";
			}
			
			str = str.replace(myPattern," ");
			
			var content:String = "";			
			content = lib + " " + str + "" + returnString + "" + returnString;
			
			if (chart.dataProvider is ArrayCollection) {
				var dataSet_ac:ArrayCollection = chart.dataProvider as ArrayCollection;
				
				for (var i:int=0; i<dataSet_ac.length; i++){
					content += dataSet_ac.getItemAt(i).type + "\t" + dataSet_ac.getItemAt(i).count + "" + returnString;
				}
				
			} else if (chart.dataProvider is XMLListCollection) {
				var dataSet_xml:XMLListCollection = chart.dataProvider as XMLListCollection;
				var parent:XML = (dataSet_xml[0] as XML).parent();
				
				for (var j:int=0; j<parent.children().length(); j++){
					content += parent.children()[j].@LABEL + "\t" + parent.children()[j].@VALUE + "" + returnString;
				}
			} else {
				var alert:MyAlert = new MyAlert();
				alert.error = true;
				alert.show("Chart data type is incorrect");
				return;
			}
			
			var file:FileReference = new FileReference();
			file.save(content,filename);
		}
	}
}