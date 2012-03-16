package com.component
{
	import mx.formatters.NumberFormatter;
	
	public class MyNumberFormatter extends NumberFormatter
	{
		public function MyNumberFormatter()
		{
			super();
			this.decimalSeparatorFrom=".";
			this.decimalSeparatorTo=".";
			this.thousandsSeparatorFrom=",";
			this.thousandsSeparatorTo=",";
			this.precision="2";
			this.useNegativeSign="true";
			this.rounding="nearest";
		}
		
		public function updatePrecision(v:Number):void{
			this.precision = v;
		}
	}
}