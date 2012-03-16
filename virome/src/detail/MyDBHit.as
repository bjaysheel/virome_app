package detail
{
	import com.events.MyChgTabEvent;
	import com.component.MyGridItem;
	import com.component.MyGridRow;
	import com.component.MyNumberFormatter;
	import com.MyUtility;
	import com.events.UpdateHitEvent;
	
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	import mx.containers.Grid;
	import mx.controls.LinkButton;
	import mx.controls.Text;
	import mx.core.FlexGlobals;
	import mx.managers.PopUpManager;
	
	public class MyDBHit extends Grid
	{
		private var util:MyUtility = new MyUtility();
		private var nf:MyNumberFormatter = new MyNumberFormatter();
		private var _flag:Boolean = false;
		
		public function MyDBHit(){
			super();
			_flag = false;
			
			this.percentHeight=100;
			this.percentWidth=100;
			this.setStyle("verticalGap",0);
			this.setStyle("horizontalGap",3);
			this.setStyle("paddingBottom",0);
			this.setStyle("paddingTop",0);
		}
		
		public function set flag(v:Boolean):void{
			_flag = v;
		}
		public function get flag():Boolean{
			return _flag;
		}
		
		public function knownHeader():void{
			var head:Text;
			var gi:MyGridItem;
			var gr:MyGridRow = new MyGridRow;
			
			gr.header();

			//column for radio buttons.
			if (flag){
				gi = new MyGridItem;
				gr.addChild(gi);
			}
			
			head = new Text();
			gi = new MyGridItem;
			head.text = "Name";
			head.styleName = "header";
			head.width = 50;
			gi.addChild(head);
			gr.addChild(gi);
			
			head = new Text();
			gi = new MyGridItem;
			head.text = "Accession";
			head.styleName = "header";
			head.width = 100;
			gi.addChild(head);
			gr.addChild(gi);
			
			head = new Text();
			gi = new MyGridItem();
			head.text = "Hit Definition"
			head.styleName = "header";
			head.width = 110;
			gi.addChild(head);
			gr.addChild(gi);
			
			head = new Text();
			gi = new MyGridItem();
			head.text = "Evalue"
			head.styleName = "header";
			head.width = 59;
			gi.addChild(head);
			gr.addChild(gi);
			
			head = new Text();
			gi = new MyGridItem();
			head.text = "Bit Score"
			head.styleName = "header";
			head.width = 50;
			gi.addChild(head);
			gr.addChild(gi);
			
			head = new Text();
			gi = new MyGridItem();
			head.text = "% QRY Coverage";
			head.styleName = "header";
			head.width = 76;
			gi.addChild(head);
			gr.addChild(gi);
			
			head = new Text();
			gi = new MyGridItem();
			head.text = "% Identity";
			head.styleName = "header";
			head.width = 68;
			gi.addChild(head);
			gr.addChild(gi);
			
			head = new Text();
			gi = new MyGridItem();
			head.text = "% Similarity";
			head.styleName = "header";
			head.width = 80;
			gi.addChild(head);
			gr.addChild(gi);
			
			this.addChild(gr);
			this.validateNow();
		}
		
		public function showKnownHits(arr:Array, str:String, lstr:String):void{
			var t:Text;
			var _lb:LinkButton;
			var gi:MyGridItem;
			var gr:MyGridRow;
			var anno:Array;
			
			for (var i:int=0;i<arr.length;i++){
				t = new Text();
				gr = new MyGridRow;
				
				if ((i%2) == 0)
					gr.even();
				else gr.odd();
				
				// add name.
				gi = new MyGridItem;
				if (lstr.length == 0){
					_lb = new LinkButton();
					_lb.label = "ORF " + arr[i].QUERYNAME.substring(arr[i].QUERYNAME.search(/_\d+$/)+1,arr[i].QUERYNAME.length);
					_lb.name = arr[i].QUERYNAME.substring(arr[i].QUERYNAME.search(/_\d+$/)+1,arr[i].QUERYNAME.length);
					_lb.id = arr[i].SEQUENCEID;
					_lb.addEventListener(MouseEvent.CLICK,queryNameClickEvent);
					_lb.width=70;
					gi.addChild(_lb);
				} else {
					t = new Text();
					t.text = lstr;
					t.width = 70;
					gi.addChild(t);
				}
				gr.addChild(gi);
				
				// add hit name
				gi = new MyGridItem();
				_lb = new LinkButton;
				_lb.label = arr[i].HITNAME.split(/;/)[0];
				_lb.width=100;
				_lb.setStyle("textAlign","left");
				if ((str == "UNIREF100P") && (_lb.label.substr(0,2) == "UP"))
					_lb.addEventListener(MouseEvent.CLICK, util.followUNIPARC);
				else if (str == "UNIREF100P")
					_lb.addEventListener(MouseEvent.CLICK, util.followUNIREF);
				else if (str == "KEGG")
					_lb.addEventListener(MouseEvent.CLICK, util.followKEGG);
				else if (str == "COG")
					_lb.addEventListener(MouseEvent.CLICK, util.followCOG);
				else if (str == "ACLAME")
					_lb.addEventListener(MouseEvent.CLICK, util.followACLAME);
				else if (str == "SEED")
					_lb.addEventListener(MouseEvent.CLICK, util.followSEED);
				else _lb.enabled = false;
				gi.addChild(_lb);
				gr.addChild(gi);
				
				// add hit description
				gi = new MyGridItem();

				t = new Text();
				t.text = arr[i].HITDESCRIPTION;
				t.width = 200;
				gi.addChild(t);
					
				gr.addChild(gi);
				
				// add e-value
				t = new Text();
				gi = new MyGridItem();
				t.text = arr[i].EVALUE;
				t.width = 60;
				gi.addChild(t);
				gr.addChild(gi);
				
				// add bit score
				t = new Text();
				gi = new MyGridItem();
				t.text = arr[i].BITSCORE;
				t.width = 50;
				gi.addChild(t);
				gr.addChild(gi);
				
				// add qry coverage
				t = new Text();
				gi = new MyGridItem();
				t.text = nf.format((Math.abs(arr[i].QRYSTART-arr[i].QRYEND+1)/arr[i].SIZE)*100).toString();
				t.width = 70;
				gi.addChild(t);
				gr.addChild(gi);
				
				// add % identity
				t = new Text();
				gi = new MyGridItem();
				t.text = arr[i].IDENTITY;
				t.width = 70;
				gi.addChild(t);
				gr.addChild(gi);
				
				// add % similarity
				t = new Text();
				gi = new MyGridItem();
				t.text = arr[i].SIMILARITY;
				t.width = 80;
				gi.addChild(t);
				gr.addChild(gi);
				
				this.addChild(gr);
				
				//add seed functional evidence info.
				if ((str == "SEED") && (lstr == "Top FXNal Hit")){
					gr = new MyGridRow();
					gi = new MyGridItem();
					gr.addChild(gi);
					gi = new MyGridItem();
					gi.colSpan = 7;
					
					t = new Text();
					anno = arr[i].FXNANNO;
					t.htmlText = "<b>FXN 1:</b> " + anno[0].FXN1 + 
								 "<br/><b>FXN 2:</b> " + anno[0].FXN2 + 
								 "<br/><b>DESC:</b> " + anno[0].DESC + 
								 "<br/><b>SUBSYSTEM:</b> " + anno[0].SUBSYSTEM;
					t.percentWidth=100;
					gi.addChild(t);
					
					//if (anno.length > 1){
						_lb = new LinkButton();
						_lb.label = "more fxnal evidence...";
						_lb.addEventListener(MouseEvent.CLICK,function (e:MouseEvent):void{
							fxnEvidence(e,anno,str);
						});
						gi.addChild(_lb);
					//}
					
					gr.addChild(gi);
					this.addChild(gr);
				}
				
				//add kegg functional evidence
				if ((str == "KEGG") && (lstr == "Top FXNal Hit")){
					gr = new MyGridRow();
					gi = new MyGridItem();
					gr.addChild(gi);
					gi = new MyGridItem();
					gi.colSpan = 7;
					
					t = new Text();
					anno = arr[i].FXNANNO;
					t.htmlText = "<b>FXN 1:</b> " + anno[0].FXN1 + 
								 "<br/><b>FXN 2:</b> " + anno[0].FXN2 + 
								 "<br/><b>FXN 3:</b> " + anno[0].FXN3 + 
								 "<br/><b>EC. NO.:</b> " + anno[0].ECNO;
					t.percentWidth=100;
					gi.addChild(t);
					
					if (anno.length > 1){
						_lb = new LinkButton();
						_lb.label = "more fxnal evidence...";
						_lb.addEventListener(MouseEvent.CLICK,function (e:MouseEvent):void{
							fxnEvidence(e,anno,str);
						});
						gi.addChild(_lb);
					}
					
					gr.addChild(gi);
					this.addChild(gr);
				}
				
				//add cog functional evidence
				if ((str == "COG") && (lstr == "Top FXNal Hit")){
					gr = new MyGridRow();
					gi = new MyGridItem();
					gr.addChild(gi);
					gi = new MyGridItem();
					gi.colSpan = 7;
					
					t = new Text();
					anno = arr[i].FXNANNO;
					t.htmlText = "<b>FXN 1:</b> " + anno[0].FXN1 + 
								 "<br/><b>FXN 2:</b> " + anno[0].FXN2 + 
								 "<br/><b>FXN 3:</b> " + anno[0].FXN3;
					t.percentWidth=100;
					gi.addChild(t);
					
					if (anno.length > 1){
						_lb = new LinkButton();
						_lb.label = "more fxnal evidence...";
						_lb.addEventListener(MouseEvent.CLICK,function (e:MouseEvent):void{
							fxnEvidence(e,anno,str);
						});
						gi.addChild(_lb);
					}
					
					gr.addChild(gi);
					this.addChild(gr);
				}
				
				//add uniref functional evidence
				if ((str == "UNIREF100P") && (lstr == "Top FXNal Hit")){
					gr = new MyGridRow();
					gi = new MyGridItem();
					gr.addChild(gi);
					gi = new MyGridItem();
					gi.colSpan = 7;
					
					t = new Text();
					anno = arr[i].FXNANNO;
					t.htmlText = "<br/><b>GO SLIM DESC:</b> " + anno[0].GOSLIM_DESC;
					//"<b>GO SLIM ACC:</b> " + arr[i].GOSLIM_ACC + 
					t.percentWidth=100;
					gi.addChild(t);
					
					if (anno.length > 1){
						_lb = new LinkButton();
						//_lb.label = "more fxnal evidence...";
						//_lb.addEventListener(MouseEvent.CLICK,function (e:MouseEvent):void{
						//	fxnEvidence(e,anno,str);
						//});
						gi.addChild(_lb);
					}
					
					gr.addChild(gi);
					this.addChild(gr);
				}
				
				this.validateNow();
			}
		}
		
		private function queryNameClickEvent(event:MouseEvent):void{
			var _chgTab:MyChgTabEvent = new MyChgTabEvent();
			_chgTab.id = event.currentTarget.id;
			_chgTab.name = event.currentTarget.label;
			_chgTab.num = event.currentTarget.name;
			
			util.app.dispatchEvent(_chgTab);
		}
		
		private function blastDetailFunc(event:MouseEvent,db:String):void{
			//popup window to display all blast hits for a given database.
			var blstDetail:MyBlastDetails = MyBlastDetails(PopUpManager.createPopUp(DisplayObject(FlexGlobals.topLevelApplication), MyBlastDetails, true));
			blstDetail.sequence = event.currentTarget.id;
			blstDetail.database = db;
			blstDetail.environment = event.currentTarget.name;
			blstDetail.init();
			PopUpManager.bringToFront(blstDetail);
		}
		
		private function selectHit(event:Event):void{
			//set color for a selected hits.
			for (var i:int=0; i<this.numChildren; i++){
				if ((i%2) == 0)
					(this.getChildAt(i) as MyGridRow).odd();
				else (this.getChildAt(i) as MyGridRow).even();
			}
			(this.getChildAt(event.currentTarget.id) as MyGridRow).selected();
			this.validateNow();
			
			var updateevnt:UpdateHitEvent = new UpdateHitEvent;
			updateevnt.selIdx=event.currentTarget.id;
			
			util.app.dispatchEvent(updateevnt);
		}
		
		private function fxnEvidence(e:Event,a:Array,str:String):void{
			//popup window to display all funtional evidence.
			var fxnDetail:MyFxnDetails = MyFxnDetails(PopUpManager.createPopUp(DisplayObject(FlexGlobals.topLevelApplication), MyFxnDetails, true));
			fxnDetail.str = str;
			fxnDetail.fxnArray = a;
			fxnDetail.init();
			PopUpManager.bringToFront(fxnDetail);
		}
		
	}
}