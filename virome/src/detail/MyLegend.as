package detail
{
	import flash.display.GradientType;
	import flash.display.InterpolationMethod;
	import flash.display.Shape;
	import flash.display.SpreadMethod;
	import flash.display.Sprite;
	import flash.geom.Matrix;
	import mx.containers.HBox;
	
	public class MyLegend extends Sprite
	{
		private var _xcord:Number;
		private var _ycord:Number;
		private var _color1:Number;
		private var _color2:Number;
		
		public function set xcord(v:Number):void{
			_xcord = v;
		}
		public function set ycord(v:Number):void{
			_ycord = v;
		}
		public function set color1(v:Number):void{
			_color1 = v;
		}
		public function set color2(v:Number):void{
			_color2 = v;
		}
		public function get xcord():Number{
			return _xcord;
		}
		public function get ycord():Number{
			return _ycord;
		}
		public function get color1():Number{
			return _color1;
		}
		public function get color2():Number{
			return _color2;
		}
		
		public function MyLegend()
		{
			_xcord=0;
			_ycord=0;
			_color1=0xFF0000;
			_color2=0xFFFFFF;
			super();
		}
		
		public function drawLedgend():void{
			drawRect();
		}
		
		protected function drawRect():void{
			var type:String = GradientType.LINEAR;
			var colors:Array = [_color1, _color2];
			var alphas:Array = [1, 1];
			var ratios:Array = [0, 255];
			var spreadMethod:String = SpreadMethod.PAD;
			var interp:String = InterpolationMethod.LINEAR_RGB;
			var focalPtRatio:Number = 0;
			
			var matrix:Matrix = new Matrix();
			var boxWidth:Number = 185;
			var boxHeight:Number = 10;
			var boxRotation:Number = 0
			var tx:Number = 0;
			var ty:Number = 0;
			matrix.createGradientBox(boxWidth, boxHeight, boxRotation, tx, ty);
			
			var square:Shape = new Shape;
			square.graphics.lineStyle(1,0x000,1);
			square.graphics.beginGradientFill(type, 
											colors,
											alphas,
											ratios, 
											matrix, 
											spreadMethod);
			square.graphics.drawRect(_xcord, _ycord, boxWidth,boxHeight);
			
			this.addChild(square);
		}
	}
}