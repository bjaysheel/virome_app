package detail
{
	import mx.containers.HBox;
	import mx.containers.VBox;
	import mx.controls.Label;
	import mx.controls.Spacer;
	import mx.controls.Text;
	
	public class SeqDem extends VBox
	{
		private var _sid:Number;
		private var _sname:String;
		private var _readbasepair:String;
		private var _orfbasepair:String;
		private var _size:String;
		private var _start:Number;
		private var _end:Number;
		private var _model:String;
		private var _type:String;
		private var _strand:String;
		private var _frame:Number;
		private var _score:String;
		private var _image:String;
		private var _colorType:String;
		
		public function SeqDem(){
			super();
			_sid=0;
			_sname="";
			_readbasepair="";
			_orfbasepair="";
			_size="";
			_start=0;
			_end=0;
			_model="";
			_type="";
			_strand="";
			_frame=0;
			_score="";
			_image="";
			_colorType="";
			
			this.setStyle("verticalGap","10");
		}
		
		public function show():void{
			this.addChild(showSeqName());
			this.addChild(showSeqLen());
			
			if (_type.length){
				setSeqColor();
				this.addChild(showType());
			}
			if (start && end){
				this.addChild(showStartEnd());
				this.addChild(showCaller());
			}
			this.addChild(showSeq(_readbasepair));
			
			if (_orfbasepair.length){
				_start=1;
				_end=_orfbasepair.length;
				this.addChild(showSeq(_orfbasepair,true));
			}
		}
		
		public function get image():String{
			return _image;
		}
		public function set image(value:String):void{
			_image=value;
		}
		public function get strand():String{
			return _strand;
		}
		public function set strand(value:String):void{
			_strand = value;
		}
		public function get frame():Number{
			return _frame;
		}
		public function set frame(value:Number):void{
			_frame = value;
		}
		public function get score():String{
			return _score;
		}
		public function set score(value:String):void{
			_score = value;
		}
		public function get type():String{
			return _type;
		}
		public function set type(value:String):void{
			if (value == "incomplete")
				_type = "lack both ends"
			else
				_type = value;
		}
		public function get model():String{
			return _model;
		}
		public function set model(value:String):void{
			_model = value;
		}
		public function get end():Number{
			return _end;
		}
		public function set end(value:Number):void{
			_end = value;
		}
		public function get start():Number{
			return _start;
		}
		public function set start(value:Number):void{
			_start = value;
		}
		public function get size():String{
			return _size;
		}
		public function set size(value:String):void{
			_size = value;
		}
		public function get orfbasepair():String{
			return _orfbasepair;
		}
		public function set orfbasepair(value:String):void{
			_orfbasepair = value;
		}
		public function get readbasepair():String{
			return _readbasepair;
		}
		public function set readbasepair(value:String):void{
			_readbasepair = value;
		}
		public function get sname():String{
			return _sname;
		}
		public function set sname(value:String):void{
			_sname = value;
		}
		public function get sid():Number{
			return _sid;
		}
		public function set sid(v:Number):void{
			_sid = v;
		}
		
		
		protected function setSeqColor():void{
			if (_type.localeCompare("complete") == 0)
				_colorType = "completeSeq";
			else if (_type.localeCompare("lack both ends") == 0)
				_colorType = "incompleteSeq";
			else if (_type.localeCompare("lack stop") == 0)
				_colorType = "prime3Seq";
			else if (_type.localeCompare("lack start") == 0)
				_colorType = "prime5Seq";
		}

		protected function showSeqName():HBox{
			var lab:Label = new Label();
			var val:Text = new Text();
			var box:HBox = new HBox();
			
			if (_type.length)
				lab.text = "ORF Name: ";
			else
				lab.text = "Sequence Name: ";
			lab.styleName = "strong";
			val.text = sname;
			box.addChild(lab);
			box.addChild(val);
			
			return box;
		}
		
		protected function showSeqLen():HBox{
			var lab:Label = new Label();
			var val:Text = new Text();
			var box:HBox = new HBox();

			lab.text = "Sequence Length: ";
			lab.styleName = "strong";
			val.text = size;

			box.addChild(lab);
			box.addChild(val);

			if (_type.length){
				var lab2:Label = new Label();
				var val2:Text = new Text();
				var sp:Spacer = new Spacer();
				sp.width = 50;

				lab.text = "Translated ORF Length: ";
				val.text = val.text + "aa";
				lab2.text = "ORF Length: ";
				lab2.styleName = "strong";
				val2.text = (parseInt(size)*3).toString() + "bp";
				
				box.addChild(sp);
				box.addChild(lab2);
				box.addChild(val2);
			}
			
			return box;
		}
		
		protected function showSeq(bp:String,flag:Boolean=false):VBox{
			var lab:Label = new Label();
			var box:VBox = new VBox();
			
			box.percentHeight = 100;
			box.setStyle("verticalGap","0");
			lab.text = "Read Sequence:";
			lab.styleName="strong";
			
			var i:int;
			var len:int = bp.length;
			var mxL:int = 60;
			
			var s1:Text = new Text();
			var s2:Text = new Text();
			var s3:Text = new Text();
			
			var se1:String = new String();
			var se2:String = new String();
			var se3:String = new String();
			
			se1 = bp.substring(0, _start-1);
			se2 = bp.substring(_start-1, _end);
			se3 = bp.substring(_end, bp.length);
			
			len = se1.length;
			// if se1 has something then format s1.text, and 
			// add padding if need for s2
			if (len){
				//add spacing to indent the seq from left margin
				s1.text = "    ";
				for(i=0; i<len;i=i+60){
					if ((i+60) > len)
						mxL = (len - i);
					else mxL = 60;
					
					s1.text += se1.substr(i,mxL) + "\n    ";
				}

				if ((mxL<60) && (se2.length)){
					for (i=0; i<mxL; i++)
						s2.text += " ";
					
					se2 = s2.text + se2;
				}
		    }
			
			len = se2.length;
			if (len) {
				s2.text = "    ";
				for(i=0; i<len; i=i+60){
					if ((i+60) > len)
						mxL = (len - i);
					else mxL = 60;
					
					s2.text += se2.substr(i,mxL) + "\n    ";
				}
				
				if ((mxL<60) && (se3.length)){
					for (i=0; i<mxL; i++)
						s3.text += " ";
					se3 = s3.text + se3;
				}
			}
			
			
			len=se3.length;
			if (len){
				s3.text = "    ";
				for(i=0; i<len; i=i+60){
					if ((i+60) > len)
						mxL = (len - i);
					else mxL = 60;
					
					s3.text += se3.substr(i,mxL) + "\n    ";
				}
			}
			
			
			if ((s2.text.length) && (!flag))
				lab.text = "ORF Sequence:";
			else if ((s2.text.length) && (!s1.text.length) && (!s3.text.length))
				lab.text = "Translated ORF sequence";
			
			box.addChild(lab);
			s1.styleName = "sequence";
			s2.styleName = _colorType;
			s3.styleName = "sequence";
			if (s1.text.length > 4)
				box.addChild(s1);
			if (s2.text.length > 4)
				box.addChild(s2);
			if (s3.text.length > 4)
				box.addChild(s3);
			
			return box;
		}
		
		private function showType():HBox{
			var lab:Label = new Label();
			var val:Text = new Text();
			var box:HBox = new HBox();
			
			lab.text = "ORF Type: ";
			val.text = _type;
			val.styleName = _colorType;
			lab.styleName = "strong";
			
			box.addChild(lab);
			box.addChild(val);
			
			return box;
		}
				
		private function showCaller():HBox{
			var lab:Label = new Label();
			var val:Text = new Text();
			var lab2:Label = new Label();
			var val2:Text = new Text();
			var box:HBox = new HBox();
			
			lab2.text = "ORF Model: ";
			lab2.styleName="strong";
			val2.text = _model;
			
			lab.text = "ORF Caller: ";
			lab.styleName="strong";
			val.text = "METAGENE annotator";
			
			var sp:Spacer = new Spacer();
			sp.width=50;
			
			box.addChild(lab2);
			box.addChild(val2);
			box.addChild(sp);
			box.addChild(lab);
			box.addChild(val);
			
			return box;
		}
		
		private function showStartEnd():HBox{
			var lab1:Label = new Label();
			var lab2:Label = new Label();
			var lab3:Label = new Label();
			var val1:Text = new Text();
			var val2:Text = new Text();
			var val3:Text = new Text();
			var box:HBox = new HBox();
			
			lab1.text = "ORF Start: ";
			lab1.styleName="strong";
			val1.text = _start.toString();
			
			lab2.text = "ORF End: ";
			lab2.styleName="strong";
			val2.text = _end.toString();
						
			lab3.text = "Frame: ";
			val3.text = strand + (Math.abs(start-frame-1)%3).toString();
			lab3.styleName="strong";
			
			var sp:Spacer = new Spacer();
			sp.width = 50;

			var sp2:Spacer = new Spacer();
			sp2.width=50;

			box.addChild(lab1);
			box.addChild(val1);
			box.addChild(sp);
			box.addChild(lab2);
			box.addChild(val2);
			box.addChild(sp2);
			box.addChild(lab3);
			box.addChild(val3);
			
			return box;
		}
	}
}