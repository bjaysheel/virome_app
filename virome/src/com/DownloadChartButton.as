package com
{
	import com.events.FileSelectorEvent;
	
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.events.MouseEvent;
	import flash.net.FileReference;
	import flash.utils.ByteArray;
	
	import mx.charts.BarChart;
	import mx.charts.PieChart;
	import mx.controls.Button;
	import mx.core.FlexGlobals;
	import mx.graphics.codec.JPEGEncoder;
	import mx.managers.PopUpManager;
	
	public class DownloadChartButton extends Button
	{
		[Embed(source='/assets/icons/Download.png')] private var downloadIcon:Class;
		
		private var _piechart:PieChart;
		private var _barchart:BarChart;
		private var _chartName:String;
		
		public function DownloadChartButton()
		{
			super();
			this.label = "";
			this.toolTip = "Download chart";
			this.setStyle("icon", downloadIcon);
			this.addEventListener(MouseEvent.CLICK,downloadChart);
		}

		public function get chartName():String
		{
			return _chartName;
		}

		public function set chartName(value:String):void
		{
			_chartName = value;
		}

		public function get barchart():BarChart
		{
			return _barchart;
		}

		public function set barchart(value:BarChart):void
		{
			_barchart = value;
		}

		public function get piechart():PieChart
		{
			return _piechart;
		}

		public function set piechart(value:PieChart):void
		{
			_piechart = value;
		}

		private function downloadChart(event:MouseEvent):void{
			var filename:String = "VIROME";
			
			if (chartName.length > 0)
				filename = chartName;
			
			var bitmapData:BitmapData;
			if (_barchart != null){
				bitmapData = new BitmapData(_barchart.width,_barchart.height,true);
				bitmapData.draw(_barchart);
				filename += "_barchart.jpg";
			} else { 
				bitmapData = new BitmapData(_piechart.width,_piechart.height,true);
				bitmapData.draw(_piechart);
				filename += "_piechart.jpg";
			}
			
			var jpgEncoder:JPEGEncoder = new JPEGEncoder();
			var bytes:ByteArray = jpgEncoder.encode(bitmapData);
			
			var file:FileReference = new FileReference();
			file.save(bytes,filename);
		}
	}
}