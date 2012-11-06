package detail
{
	import com.MyBlastImager;
	import com.MyUtility;
	import com.adobe.fiber.services.wrapper.RemoteObjectServiceWrapper;
	import com.events.UpdateORFViewEvent;
	
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	import mx.collections.ArrayCollection;
	import mx.containers.Canvas;
	import mx.containers.Grid;
	import mx.containers.GridRow;
	import mx.containers.HBox;
	import mx.containers.VBox;
	import mx.containers.ViewStack;
	import mx.controls.Alert;
	import mx.controls.Button;
	import mx.controls.DataGrid;
	import mx.controls.Image;
	import mx.controls.Label;
	import mx.controls.LinkButton;
	import mx.controls.Text;
	import mx.controls.TextInput;
	import mx.controls.VRule;
	import mx.controls.dataGridClasses.DataGridColumn;
	import mx.core.FlexGlobals;
	import mx.events.IndexChangedEvent;
	import mx.managers.PopUpManager;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	import mx.rpc.remoting.RemoteObject;
	
	import spark.effects.Wipe;
	
	public class MyOrfTab extends VBox
	{
		private var arrayCollection:ArrayCollection;
		private var vs:ViewStack;
		private var prev:Button;
		private var next:Button;
		private var jumpTo:TextInput;
		private var _util:MyUtility = new MyUtility();
		
		private static var MAX_SEQ_SIZE:int = 320;
		private static var MAX_BASE_COUNT:int = 80;
		private static var MAX_ROW_COUNT:int = 1;

		private var loadArray:Array = new Array();
		private var environment:String = null;

		//public function MyOrfTab(a:ArrayCollection, i:int)
		public function MyOrfTab(ac:ArrayCollection, env:String, sname:String)
		{
			super();
			_util.app.addEventListener(UpdateORFViewEvent.UPDATE_ORF_VIEW_EVENT, skipTo);
			this.name = "ORF";
			this.label = "ORF(s)";
			this.percentHeight = 100;
			//this.maxWidth = 1245; //keep it smaller than 1280 to account for spacing and scrollbars
			
			arrayCollection = new ArrayCollection();
			
			vs = new ViewStack();
			vs.horizontalScrollPolicy = "off";
			vs.percentWidth = 100;
			vs.percentHeight = 100;
			vs.selectedIndex = -1;
			
			environment = env;
			createShell(ac, sname);
			
			var vbox:VBox = new VBox();
			vbox.percentHeight = 100;
			vbox.percentWidth = 100;
			
			vbox.addChild(vs);
			this.addChild(vbox);
			
			addControlPanel();
			
			this.validateNow();
		}
		
		public function createShell(ac:ArrayCollection, sname:String):void {
			var idx:int = 0;
			for(var i:int=0; i<ac.length; i++) {
				var box:Canvas = new Canvas();
				box.percentHeight = 100;
				
				box.name = ac.getItemAt(i).NAME;
				box.id = ac.getItemAt(i).ID;
				
				vs.addChild(box);
				
				if (box.name == sname) {
					idx = i;
				}
				
				loadArray[i] = null;
			}
			
			vs.selectedIndex = idx;
			vs.addEventListener(IndexChangedEvent.CHANGE, orfViewChange);
			vs.dispatchEvent(new IndexChangedEvent("change", false, false, null, -1, idx, null));
		}
		
		private function orfViewChange(e:IndexChangedEvent):void {
			var orfDetailRPC:RemoteObject = new RemoteObject();
			orfDetailRPC.destination = "ColdFusion";
			orfDetailRPC.endpoint = _util.endpoint;
			orfDetailRPC.source = _util.cfcPath + ".OrfRPC";
			orfDetailRPC.addEventListener(FaultEvent.FAULT, _util.faultHandler);
			orfDetailRPC.addEventListener(ResultEvent.RESULT, showORFDetails);
			
			if (loadArray[e.newIndex] == null) {
				//var dp:HBox = vs.getChildAt(e.newIndex) as HBox;
				var dp:Canvas = vs.getChildAt(e.newIndex) as Canvas;
				
				orfDetailRPC.getSequenceInfo(dp.id, environment);
			}
		}
		
		public function showORFDetails(e:ResultEvent):void {
			arrayCollection = new ArrayCollection(e.result as Array);
			for (var i:int=0; i<arrayCollection.length; i++) {
				var object:Object = arrayCollection.getItemAt(i);
			
				// top box contains seq info on the left 
				// and blast image on the right.
				var tbox:Canvas = vs.getChildByName(object.NAME) as Canvas;
				tbox.removeAllChildren();
				//tbox.percentHeight = 100;
				
				var hbox:HBox = new HBox();
				var lbox:VBox = new VBox();
				
				//-----------------------------------------------------------
				// display sequence name
				lbox.addChild(displaySimpleValue("Name:", object.NAME));
				
				// display sequence length
				lbox.addChild(displaySimpleValue("Length (amino acid):", object.SIZE));
				
				// display ORF details
				lbox.addChild(displayORFDetail(object.HEADER, vs.getChildIndex(vs.getChildByName(object.NAME))));
				
				// display heatmap
				lbox.addChild(displayHeatMap(object.HEATMAP));
				
				//tbox.addChild(lbox);
				hbox.addChild(lbox);
				
				// add divider
				var vrule:VRule = new VRule();
				vrule.percentHeight = 100;
				
				//tbox.addChild(vrule);
				hbox.addChild(vrule);
				
				//-----------------------------------------------------------
				// add blast imager.
				var rbox:VBox = new VBox();
				rbox.percentWidth = 100;
				
				rbox.addChild(displayImage(object));
				
				// top fxn and sys blast hits per database.
				rbox.addChild(displayTopHits(object.TOPHITS));
				
				//tbox.addChild(rbox);
				hbox.addChild(rbox);
				
				tbox.addChild(hbox);
			}
		}
		
		private function displaySimpleValue(key:String, value:String):HBox {
			var label:Label = new Label();
			label.text = key;
			label.styleName = "strong";
			
			var text:Text = new Text();
			text.text = value;
			
			var hbox:HBox = new HBox();
			hbox.addChild(label);
			hbox.addChild(text);
			
			return hbox;
		}
		
		private function displayORFDetail(str:String, ldIdx:int):VBox {
			var vbox:VBox = new VBox();
			
			var object:Object = _util.seqHeaderToStruct(str);
			
			var hbox:HBox = new HBox();
			var label:Label = new Label();
			
			label.text = "Start:";
			label.styleName = "strong";
			hbox.addChild(label);
			
			label = new Label();
			label.text = object["start"].toString();
			hbox.addChild(label);
			
			label = new Label();
			label.text = "Stop:";
			label.styleName = "strong";
			hbox.addChild(label);
			
			label = new Label();
			label.text = object["stop"].toString();
			hbox.addChild(label);
			
			vbox.addChild(hbox);
			
			hbox = new HBox();
			label = new Label();			
			label.text = "Strand:";
			label.styleName = "strong";
			hbox.addChild(label);
			
			label = new Label();
			label.text = object["strand"].toString();
			hbox.addChild(label);
			
			label = new Label();
			label.text = "Type:";
			label.styleName = "strong";
			hbox.addChild(label);
			
			label = new Label();
			if (object["type"].toString().toLowerCase() == "lack_start") {
				label.text = "missing start codon";
				loadArray[ldIdx] = "#0066FF";
			} else if (object["type"].toString().toLowerCase() == "lack_stop") {
				label.text = "missing stop codon";
				loadArray[ldIdx] = "#FF6600";
			} else if (object["type"].toString().toLowerCase() == "incomplete") {
				label.text = "missing both codon";
				loadArray[ldIdx] = "#FF00CC";
			} else if (object["type"].toString().toLowerCase() == "complete") {
				label.text = "complete";
				loadArray[ldIdx] = "#33FF00";
			}
			
			hbox.addChild(label);
			
			vbox.addChild(hbox);
			
			hbox = new HBox();
			label = new Label();
			
			label.text = "Caller:";
			label.styleName = "strong";
			hbox.addChild(label);
			
			label = new Label();
			label.text = object["caller"];
			hbox.addChild(label);
			
			
			vbox.addChild(hbox);
			
			return vbox; 
		}
		
		private function displayHeatMap(o:Object):Grid{
			var hm:MyHeatMap = new MyHeatMap();
			
			hm.makeMap(o);
			
			return hm;
		}
		
		private function displayTopHits(a:Array):VBox {
			var vbox:VBox = new VBox();
			vbox.percentWidth = 100;
			
			for (var i:int=0; i<a.length; i++) {
				if (a[i].hsp != undefined)
					vbox.addChild(showTopHits(a[i], a[i].hsp.DATABASE_NAME));
			}
			
			return vbox;
		}
		
		private function showTopHits(obj:Object, str:String):VBox{
			var dbObj:MyDBHit = new MyDBHit();
			var vbox:VBox = new VBox();
			var top_arr:Array = new Array();
			var fxn_arr:Array = new Array();
			var lstr:String = new String();
			
			vbox.percentWidth = 100;
			
			// add subheading divider
			var headerbox:HBox = new HBox();
			var header:Label = new Label();
			//var _spacer:Spacer = new Spacer();
			
			headerbox.percentWidth = 100;
			headerbox.styleName = "subheading";
			header.text = str + " BLAST Hits";
			headerbox.addChild(header);
			
			//_spacer.height = 25;
			
			//vbox.addChild(_spacer);
			vbox.addChild(headerbox);
			
			top_arr.push(obj.hsp);
			if (obj.fxn != undefined)
				fxn_arr.push(obj.fxn);
			
			lstr = "Top BLAST Hit";
		
			if (str != "METAGENOMES"){
				dbObj.knownHeader();
				dbObj.showKnownHits(top_arr, str, lstr);
				
				//add top FXN hit
				lstr = "Top FXNal Hit";
				if (fxn_arr.length)
					dbObj.showKnownHits(fxn_arr, str, lstr);
			} else {
				//add top BLAST hit
				dbObj.knownHeader();
				dbObj.showKnownHits(top_arr, str, lstr);
			}
			
			vbox.addChild(dbObj);
			
			return vbox;
		}
		
		private function displayImage(obj:Object):MyBlastImager {
			var img:MyBlastImager = new MyBlastImager(obj, false);
			
			return img;
		}
		
		private function addControlPanel():void{
			var hbox:HBox = new HBox();
			hbox.percentWidth = 100;
			hbox.setStyle("horizontalAlign","center");
			hbox.setStyle("backgroundColor", 0xCCCCCC);
			hbox.setStyle("backgroundAlpha", 0.3);

			prev = new Button();
			prev.label = "Previous";
			prev.name = "Previous";
			prev.addEventListener(MouseEvent.CLICK, updateView);
			
			next = new Button();
			next.label = "Next";
			next.name = "Next";
			next.addEventListener(MouseEvent.CLICK, updateView);
			
			jumpTo = new TextInput;
			jumpTo.restrict = "0-9";
			jumpTo.text = (vs.selectedIndex+1).toString();
			jumpTo.maxWidth = 25;
			jumpTo.addEventListener(Event.CHANGE, jumpView);
			
			var lb:Label = new Label();
			lb.text = " of " + (vs.numChildren);
			
			toggleButton();
			
			hbox.addChild(prev);
			hbox.addChild(jumpTo);
			hbox.addChild(lb);
			hbox.addChild(next);
			
			this.addChild(hbox);
		}
		
		private function updateView(event:MouseEvent):void {
			if (event.currentTarget.name == "Previous") {
				jumpTo.text = ((vs.selectedIndex - 1)+1).toString();
				vs.selectedIndex = vs.selectedIndex - 1;
			} else if (event.currentTarget.name == "Next") {
				jumpTo.text = ((vs.selectedIndex + 1)+1).toString();;
				vs.selectedIndex = vs.selectedIndex + 1;
			}
			
			toggleButton();
		}
		
		private function jumpView(event:Event):void {
			var idx:int = parseInt(event.currentTarget.text);
			
			if ((idx <= vs.numChildren) && (idx > 0)){
				vs.selectedIndex = idx-1;
			}
			
			toggleButton();
		}
		
		private function skipTo(event:UpdateORFViewEvent):void {
			var idx:int = vs.getChildIndex(vs.getChildByName(event.seqName));
			
			vs.selectedIndex = idx;
			jumpTo.text = (idx+1).toString();
			
			toggleButton();
		}
		
		private function toggleButton():void{
			if (vs.selectedIndex == vs.numChildren-1) {
				next.enabled = false;
			} else { 
				next.enabled = true;
			}
			
			if (vs.selectedIndex == 0){
				prev.enabled = false;
			} else {
				prev.enabled = true;
			}
		}
	}
}