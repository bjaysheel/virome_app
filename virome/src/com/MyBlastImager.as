package com
{
	import com.component.MyNumberFormatter;
	import com.events.UpdateORFViewEvent;
	
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	import flash.text.TextFormat;
	
	import mx.containers.VBox;
	import mx.controls.Alert;
	import mx.controls.Text;
	import mx.core.UIComponent;
	
	public class MyBlastImager extends VBox
	{
		private var object:Object = new Object();
		private var features:Boolean = true;
		private var db_names:Array = new Array();
		private var scale:Number = 1;
		private var img_width:Number = 700;
		private var myTFormat:TextFormat = new TextFormat();
		private var myTFormat2:TextFormat = new TextFormat();
		private var myNumFormat:MyNumberFormatter = new MyNumberFormatter();
		
		private static var KB:Number = 2000;
		private static var DEFAULT_WIDTH:Number = 700;
		private static var DEFAULT_HEIGHT:Number = 410; //320
		private static var TRIG_SIZE:Number = 10;
		private static var FEATURE_X:Number = 18.75;
		private static var FEATURE_GAP:Number = 50; //37.5
		private static var READ_HEIGHT:int = 4;
		private static var FEATURE_HEIGHT:int = 8;
		
		private static var READ_COLOR:uint = 0x000000;
		private static var COMPLETE_COLOR:uint = 0x33FF00;
		private static var INCOMPLETE_COLOR:uint = 0xFF00CC;
		private static var LACK_STOP_COLOR:uint = 0xFF6600;
		private static var LACK_START_COLOR:uint = 0x0066FF;
		private static var TRNA_COLOR:uint = 0xFF6600;
		
		[Embed(source="/assets/MyriadWebPro.ttf", fontName="Myriad", mimeType="application/x-font", fontWeight="normal", fontStyle="normal", advancedAntiAliasing="true", embedAsCFF="false")]
		private var myEmbeddedFont:Class;
		
		public function MyBlastImager(obj:Object=null, features:Boolean=true)
		{
			super();
			
			this.setStyle("verticalGap","0");
			this.setStyle("horizontalGap", "0");
			
			this.width = DEFAULT_WIDTH;
			this.height = DEFAULT_HEIGHT;
			
			this.features = features;
			
			myTFormat.font = "Verdana";
			myTFormat.size = 10;
			myTFormat.align = "center";
			
			myTFormat2.font = "Verdana";
			myTFormat2.size = 10;
			myTFormat2.align = "left";
			
			myNumFormat.updatePrecision(0);
			
			db_names.push("UNIREF");
			db_names.push("ACLAME");
			db_names.push("SEED");
			db_names.push("KEGG");
			db_names.push("COG");
			db_names.push("METAGENOMES");
			
			if (obj == null) {
				object = new Object();
			} else {
				object = obj;
			}
			
			getImage(obj);
		}
		
		public function getImage(obj:Object):void {
			//draw read
			drawRead(obj);
			
			if (features) {
				drawReadGrid();
				
				//draw orf
				drawOrf(obj['ORF']);
				
				//draw tRNA
				drawtRNA(obj['TRNA']);
			} else {
				drawORFGrid();
				
				drawDB(obj['TOPHITS']);
			}
		}
		
		private function drawRead(obj:Object):void {
			var shape:Sprite = new Sprite();
			var c:UIComponent = new UIComponent();
			
			// take absolute value of numbers so that if start and stop in reverse direction
			// value are not negative
			img_width = Math.abs((parseInt(obj['STOP']) - parseInt(obj['START'])) + 1);
			if (img_width > KB) {
				img_width = (img_width/KB) * DEFAULT_WIDTH;
			} else {
				img_width = DEFAULT_WIDTH;
			}
			
			shape.graphics.beginFill(READ_COLOR, 1);
			shape.graphics.drawRect(0, FEATURE_X+FEATURE_GAP, img_width, READ_HEIGHT);
			shape.graphics.endFill();
			
			var lb:TextField = new TextField();
			lb.defaultTextFormat = myTFormat;
			lb.text = obj['NAME'];
			lb.selectable = false;
			lb.width = img_width;
			lb.height = READ_HEIGHT*4;
			lb.x = 0;
			lb.y = FEATURE_X+FEATURE_GAP+5;
			
			c.addChild(shape);
			c.addChild(lb);
			c.width = img_width;
			if (features)
				c.toolTip = getToolTip(obj, "read");
			else 
				c.toolTip = getToolTip(obj, "orf");
			this.addChild(c);
			
			// take absolute value of numbers so that if start and stop in reverse direction
			// value are not negative
			scale = (img_width / Math.abs((parseInt(obj['STOP']) - parseInt(obj['START'])) + 1) );
		}
		
		private function drawReadGrid():void{
			var s:Sprite = new Sprite();
			var c:UIComponent = new UIComponent();
			
			s.graphics.beginFill(0xCCCCCC, 0.1);
			s.graphics.drawRect(0, 0, img_width, FEATURE_GAP);
			s.graphics.endFill();
			
			var lb:TextField = new TextField();
			lb.defaultTextFormat = myTFormat2;
			lb.selectable = false;
			lb.height = FEATURE_HEIGHT*2;
			lb.text = "TRNA";
			
			s.addChild(lb);
			c.addChild(s);
			this.addChild(c);
			
			for (var i:int=2; i<=7; i++) {
				s = new Sprite();
				c = new UIComponent();
				
				if ((i % 2) == 0) {
					s.graphics.beginFill(0xCCCCCC, 0.1);
					s.graphics.drawRect(0, FEATURE_GAP*i, img_width, FEATURE_GAP);
					s.graphics.endFill();	
				}
			
				lb = new TextField();
				lb.defaultTextFormat = myTFormat2;
				lb.selectable = false;
				lb.height = FEATURE_HEIGHT*2;
				if (i < 5) {
					lb.text = "Frame +" + (i-1);
				} else {
					lb.text = "Frame -" + (i-4);
				}
				lb.y = FEATURE_GAP*i;
				
				s.addChild(lb);
				c.addChild(s);
				c.width = img_width;
				this.addChild(c);	
			}
			
			drawScale();
		}
		
		private function drawORFGrid():void{
			var s:Sprite = new Sprite();
			var c:UIComponent = new UIComponent();
			var lb:TextField = new TextField();
			
			for (var i:int=0; i<6; i++) {
				s = new Sprite();
				c = new UIComponent();
				
				if ((i % 2) == 0){
					s.graphics.beginFill(0xCCCCCC, 0.1);
					s.graphics.drawRect(0, FEATURE_GAP*(i+2), img_width, FEATURE_GAP);
					s.graphics.endFill();
				}
				
				lb = new TextField();
				lb.defaultTextFormat = myTFormat2;
				lb.selectable = false;
				lb.y = FEATURE_GAP*(i+2);
				lb.height = FEATURE_HEIGHT*2;
				lb.text = db_names[i];
				
				c.addChild(s);
				c.addChild(lb);
				c.width = img_width;
				this.addChild(c);	
			}
			
			drawScale();
		}
		
		private function drawScale():void{
			
			for (var i:int=100; i<img_width; i+=100) {
				var shape:Sprite = new Sprite();
				var c:UIComponent = new UIComponent();
				var lb:TextField = new TextField();
				
				shape.graphics.lineStyle(1, 0xCCCCCC, 0.3);
				shape.graphics.beginFill(0xCCCCCC, 0.3);
				shape.graphics.moveTo(i, 0);
				shape.graphics.lineTo(i, DEFAULT_HEIGHT);				
				shape.graphics.endFill();
				
				lb.selectable = false;
				lb.embedFonts = true;
				lb.defaultTextFormat = new TextFormat("Myriad", 10);
				lb.x = i;
				lb.width = 30;
				lb.height = FEATURE_HEIGHT*2;
				lb.rotation = 90;
				lb.text = myNumFormat.format((i/scale));
				
				c.addChild(shape);
				c.addChild(lb);
				this.addChild(c);
			}
		}
		
		private function drawOrf(ac:Array):void {
			
			for (var i:int=0; i<ac.length; i++) {
				var shape:Sprite = new Sprite();
				var c:UIComponent = new UIComponent();
				c.name = ac[i]['NAME'];
				
				var frame:int = parseInt(ac[i]['FRAME']) + 2;
				if (ac[i]['STRAND'] == "-") {
					frame += 3;
				}
				
				var y:Number = FEATURE_X + (FEATURE_GAP * frame);
				var x:Number = parseInt(ac[i]['START']) * scale;
				
				// x alway have to be the left most coordinate point.
				if (parseInt(ac[i]['START']) > parseInt(ac[i]['STOP'])) {
					x = parseInt(ac[i]['STOP']) * scale;
				}
				
				var w:Number = ( Math.abs( (parseInt(ac[i]['STOP']) - parseInt(ac[i]['START']) ) + 1 ) * scale);
				
				if (ac[i]['TYPE'] == "complete") {
					shape.graphics.beginFill(COMPLETE_COLOR, 1);
				} else if (ac[i]['TYPE'] == "lack_stop") {
					shape.graphics.beginFill(LACK_STOP_COLOR, 1);
				} else if (ac[i]['TYPE'] == "lack_start") {
					shape.graphics.beginFill(LACK_START_COLOR, 1);
				} else {
					shape.graphics.beginFill(INCOMPLETE_COLOR, 1);
				}
				
				shape.graphics.drawRect(x, y, w, FEATURE_HEIGHT);
				shape.graphics.endFill();
				
				var lb:TextField = new TextField();
				lb.defaultTextFormat = myTFormat;
				lb.text = "ORF " + (i+1);
				lb.selectable = false;
				lb.width = w;
				lb.height = FEATURE_HEIGHT*3;
				lb.x = x;
				lb.y = y+10;
				
				c.addChild(shape);
				c.addChild(lb);
				c.toolTip = getToolTip(ac[i], "orf");
				c.addEventListener(MouseEvent.CLICK, switchToORF);
				this.addChild(c);
				
				drawDirection(x, y, w, FEATURE_HEIGHT, ac[i]['STRAND']);
			}
		}
		
		private function drawDB(arr:Array):void{
			
			for (var i:int=0; i<arr.length; i++) {
				var shape:Sprite = new Sprite();
				var c:UIComponent = new UIComponent();
				
				var frame:int = 2;
				if (arr[i]['hsp']['DATABASE_NAME'] == "ACLAME") {
					frame = 3;
				} else if (arr[i]['hsp']['DATABASE_NAME'] == "SEED") {
					frame = 4;
				} else if (arr[i]['hsp']['DATABASE_NAME'] == "KEGG") {
					frame = 5;
				} else if (arr[i]['hsp']['DATABASE_NAME'] == "COG") {
					frame = 6;
				} else if (arr[i]['hsp']['DATABASE_NAME'] == "METAGENOMES") {
					frame = 7;
				}
				
				var y:Number = FEATURE_X + (FEATURE_GAP * frame);
				var x:Number = parseInt(arr[i]['hsp']['QRY_START']) * scale;
				
				if (parseInt(arr[i]['hsp']['QRY_START']) > parseInt(arr[i]['hsp']['QRY_STOP'])) {
					x = parseInt(arr[i]['hsp']['QRY_STOP']) * scale;
				}
				
				var w:Number = ( Math.abs( (parseInt(arr[i]['hsp']['QRY_END']) - parseInt(arr[i]['hsp']['QRY_START']) ) + 1 ) * scale ) * 3;
				
				shape.graphics.beginFill(READ_COLOR, 1);
				shape.graphics.drawRect(x, y, w, FEATURE_HEIGHT);
				shape.graphics.endFill();
				
				var lb:TextField = new TextField();
				lb.defaultTextFormat = myTFormat;
				lb.text = arr[i]['hsp']['HIT_NAME'];
				lb.selectable = false;
				lb.width = w;
				lb.height = FEATURE_HEIGHT*3;
				lb.x = x;
				lb.y = y+10;
				
				c.addChild(shape);
				c.addChild(lb);
				c.toolTip = getToolTip(arr[i]['hsp'], "db");
				this.addChild(c);
			}
		}
		
		private function drawtRNA(ac:Array):void {
			for (var i:int=0; i<ac.length; i++) {
				var shape:Sprite = new Sprite();
				var c:UIComponent = new UIComponent;
				
				var y:Number = FEATURE_X;
				var x:Number = parseInt(ac[i]['START'])*scale;
				
				// x alway have to be the left most coordinate point.
				if (parseInt(ac[i]['START']) > parseInt(ac[i]['STOP'])) {
					x = parseInt(ac[i]['STOP']) * scale;
				}
				
				var w:Number = ( Math.abs( (parseInt(ac[i]['STOP']) - parseInt(ac[i]['START']) ) + 1 ) * scale);
				
				shape.graphics.beginFill(TRNA_COLOR, 1);
				shape.graphics.drawRect(x, y, w, FEATURE_HEIGHT);
				shape.graphics.endFill();
				c.toolTip = getToolTip(ac[i], "trna");
				
				c.addChild(shape);
				this.addChild(c);
				
				drawDirection(x, y, w, FEATURE_HEIGHT, ac[i]['STRAND']);
			}
		}
		
		private function drawDirection(x:Number, y:Number, w:Number, h:Number, strand:String):void {
			var shape:Sprite = new Sprite();
			var c:UIComponent = new UIComponent;
			
			shape.graphics.beginFill(0xFFFFFF, 1);
			
			if (strand == "-") {
				shape.graphics.moveTo(x+(w/2), y);
				shape.graphics.lineTo(x+(w/2), y+h);
				shape.graphics.lineTo((x+(w/2))-TRIG_SIZE, y+(h/2));
				shape.graphics.lineTo(x+(w/2), y);
				
				shape.graphics.moveTo((x+(w/2))+TRIG_SIZE, y);
				shape.graphics.lineTo((x+(w/2))+TRIG_SIZE, y+h);
				shape.graphics.lineTo(x+(w/2), y+(h/2));
				shape.graphics.lineTo((x+(w/2))+TRIG_SIZE, y);	
			} else {
				shape.graphics.moveTo(x+(w/2), y);
				shape.graphics.lineTo(x+(w/2), y+h);
				shape.graphics.lineTo((x+(w/2))+TRIG_SIZE, y+(h/2));
				shape.graphics.lineTo(x+(w/2), y);
				
				shape.graphics.moveTo((x+(w/2))-TRIG_SIZE, y);
				shape.graphics.lineTo((x+(w/2))-TRIG_SIZE, y+h);
				shape.graphics.lineTo(x+(w/2), y+(h/2));
				shape.graphics.lineTo((x+(w/2))-TRIG_SIZE, y);
			}
			shape.graphics.endFill();
			c.addChild(shape);
			this.addChild(c);
		}
		
		private function getToolTip(obj:Object, src:String):String {
			var str:String = "";
			
			if (src == "db") {
				str += "Name: " + obj['QUERY_NAME'] + "\n";
				str += "Start: " + obj['QRY_START']*3 + "\n";
				str += "End: " + obj['QRY_END']*3 + "\n";
				str += "Size: " + ( Math.abs( (parseInt(obj['QRY_END']) - parseInt(obj['QRY_START'])) + 1 ) / scale ) * 3 + "\n";
				str += "E-value: " + obj['E_VALUE'] + "\n";
				str += "Hit Desc: " + obj['HIT_DESCRIPTION'] + "\n";
				str += "Domain: " + obj['DOMAIN'];
			} else {
				str += "Name: " + obj['NAME'] + "\n";
				str += "Start: " + obj['START'] + "\n";
				str += "End: " + obj['STOP'] + "\n";
				str += "Size: " + (Math.abs( parseInt(obj['STOP']) - parseInt(obj['START'])) + 1 ).toString() + "\n";
				
				if (src == "orf") {
					str += "Type: " + obj['TYPE'] + "\n";
					//str += "Strand: " + obj['STRAND'];
				} else if (src == "trna") {
					str += "Anti: " + obj['ANTI'] + "\n";
					str += "Intron: " + obj['INTRON'];
				} else if (src == "read") {
					str += "Num of ORF: " + obj['ORF_COUNT']+"\n";
					str += "Num of tRNA: " + obj['TRNA_COUNT'];
				}	
			}
			
			return str;
		}
		
		private function switchToORF(event:MouseEvent):void{
			var orfview:UpdateORFViewEvent = new UpdateORFViewEvent();
			orfview.seqName = event.currentTarget.name;
			
			this.dispatchEvent(orfview);
		}
	}
}