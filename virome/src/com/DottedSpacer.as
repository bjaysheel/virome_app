package com
{
	import mx.controls.Spacer;

	public class DottedSpacer extends Spacer
	{
		public function DottedSpacer()
		{
			super();
		}

		public var dotSize:Number = 2;
		public var spaceSize:Number = 2;
		public var lineThickness:Number = 1;
		public var lineColor:Number = 0xC90909;
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			var xPos:Number = 0;
			var isDot:Boolean = true;
			this.graphics.clear();
			this.graphics.lineStyle( lineThickness, lineColor );
		
			while( xPos <unscaledWidth )
			{
				if( isDot )
				{
					this.graphics.moveTo( xPos, unscaledHeight - lineThickness );
					this.graphics.lineTo( xPos + dotSize, unscaledHeight - lineThickness );
					xPos += dotSize;
				}
				else
				{
					xPos += spaceSize;
				}
				isDot = !isDot;
			}
		}
	}

}