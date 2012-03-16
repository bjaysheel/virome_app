package com.component
{
	import mx.controls.ToolTip;
	
	public class MyToolTip extends ToolTip
	{
		public function MyToolTip()
		{
			super();
			this.setStyle("backgroundColor","0x999999");
			this.setStyle("cornerRadius",5);
			this.setStyle("dropShadowEnabled",true);
			this.setStyle("dropShadowColor","0x333333");
			this.setStyle("color","0xFFFFFF");
		}
		
		override protected function commitProperties():void{
			super.commitProperties();
			textField.htmlText = text;
		}
	}
}