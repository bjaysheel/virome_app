package com
{
	import flash.net.FileReference;
	
	import mx.charts.chartClasses.ChartBase;
	import mx.graphics.ImageSnapshot;
	import mx.graphics.codec.PNGEncoder;
	
	public class MyDownloadChart
	{
		private var _chart:ChartBase;
		private var _chartName:String;
		
		public function MyDownloadChart()
		{
			super();
		}

		public function get chart():ChartBase
		{
			return _chart;
		}

		public function set chart(value:ChartBase):void
		{
			_chart = value;
		}

		public function get chartName():String
		{
			return _chartName;
		}

		public function set chartName(value:String):void
		{
			_chartName = value;
		}

		public function download():void{
			var filename:String = "VIROME";
			
			if (chartName.length > 0)
				filename = chartName;
			
			filename += "_chart.png";
			var image:ImageSnapshot = ImageSnapshot.captureImage(chart ,300, new PNGEncoder());
			
			var file:FileReference = new FileReference();
			file.save(image.data,filename);
		}
	}
}