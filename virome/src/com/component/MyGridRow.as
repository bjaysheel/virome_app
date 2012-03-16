package com.component
{
	import mx.containers.GridRow;

	public class MyGridRow extends GridRow
	{
		public function MyGridRow()
		{
			super();
			this.percentHeight=100;
			this.percentWidth=100;
			this.setStyle("verticalGap",0);
			this.setStyle("paddingBottom",0);
			this.setStyle("paddingTop",0);
		}
		
		public function header():void{
			this.setStyle("backgroundColor","0xF4FBFF");
		}
		
		public function even():void{
			this.setStyle("backgroundColor","0xFFFFFF");
		}
		
		public function odd():void{
			this.setStyle("backgroundColor","0xF4FBFF");
		}
		
		public function selected():void{
			this.setStyle("backgroundColor","0xC7F788");
		}
		
		//green
		public function fxnHit():void{
			selected();	
		}
		
		//dark dull cyan
		public function sysHit():void{
			this.setStyle("backgroundColor","0x339999");
		}
		
		//yellow color
		public function sameHit():void{
			this.setStyle("backgroundColor","0xFFFF66");
		}
		
	}
}