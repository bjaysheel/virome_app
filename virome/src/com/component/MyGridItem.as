package com.component
{
	import mx.containers.GridItem;

	public class MyGridItem extends GridItem
	{
		public function MyGridItem()
		{
			super();
			this.percentHeight = 100;
			this.percentWidth = 100;
			this.setStyle("verticalGap",0);
			this.setStyle("paddingBottom",0);
			this.setStyle("paddingTop",0);
			this.setStyle("verticalScrollPolicy","off");
			this.setStyle("horizontalScrollPolicy","off");
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void{
			super.updateDisplayList(unscaledWidth, unscaledHeight);  
			  
			this.graphics.clear();
			this.graphics.lineStyle(1, 0x808080, 1, true);
			this.graphics.moveTo(unscaledWidth,0);
			this.graphics.lineTo(unscaledWidth,unscaledHeight);
		}
		
		public function header():void{
			this.setStyle("horizontalAlign","center");
			this.setStyle("verticalAlign","middle");
		}
		
		public function v_center():void{
			this.setStyle("verticalAlign","middle");
		}
		
		public function h_center():void{
			this.setStyle("horizontalAlign","center");
		}

	}
}