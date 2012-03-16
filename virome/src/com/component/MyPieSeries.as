package com.component
{
	import mx.charts.ChartItem;
	import mx.charts.series.PieSeries;
	import mx.charts.series.items.PieSeriesItem;
	import mx.graphics.IFill;
	import mx.graphics.SolidColor;

	public class MyPieSeries extends PieSeries
	{
		public function MyPieSeries()
		{
			super();
			
			this.nameField = "type";
			this.field = "count";
			
			//set style
			this.setStyle("labelPosition","inside");
            this.setStyle("explodeRadius","0.1");
            this.setStyle("calloutGap","3");
			this.setStyle("insideLabelSizeLimit","10");
            
            //remove filters
            this.filters = [];
            
            //custom label function
            this.labelFunction = displayLabel;
		}
		
		public function set Fills(arr:Array):void{
			this.setStyle("fills",arr);
		}
	
		protected function displayLabel(data:Object, field:String, index:Number, percentValue:Number):String {
			//var temp:String= (" " + percentValue).substr(0,6);
			return data.type;
	        //return data.type + ": " + '\n' + "Total Seq: " + data.count + '\n' + temp + "%";
		}
		
		protected function myFillFunc(item:ChartItem, index:Number):IFill{
			var curItem:PieSeriesItem = PieSeriesItem(item);
			switch (curItem.item.type){
				case "complete":
					return (new SolidColor(0xDC2321,1));
				case "lack both ends":
					return (new SolidColor(0xA3AFBF,1));
				case "lack start":
					return (new SolidColor(0x06BDDC,1));
				case "lack stop":
					return (new SolidColor(0xDEAB52,1));
				case "Bacteria":
					return (new SolidColor(0xE3722B,1));
				case "Archaea":
					return (new SolidColor(0xE3CA2B,1));
				case "Eukaryota":
					return (new SolidColor(0xCEE32B,1));
				case "Viruses":
					return (new SolidColor(0x93E32B,1));
				case "Unclassified":
					return (new SolidColor(0x74C240,1));
				case "ORFans":
					return (new SolidColor(0xBFBFC1,1));
				case "Top viral hit":
					return (new SolidColor(0x808080,1));
				case "Only viral hit":
					return (new SolidColor(0x7F99B2,1));
				case "Top microbial hit":
					return (new SolidColor(0xC6BE8D,1));
				case "Only microbial hit":
					return (new SolidColor(0xCC6601,1));
				case "rRNA":
					return (new SolidColor(0x990100,1));
				case "tRNA":
					return (new SolidColor(0xCCD6E0,1));
				case "Unassigned protein":
					return (new SolidColor(0xF7F0C6,1));
			}
			return (new SolidColor(0x9F73BF,1));
		}
	}
}