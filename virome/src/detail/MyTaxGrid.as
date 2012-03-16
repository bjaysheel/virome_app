package detail
{
	import com.events.MyChgTabEvent;
	import com.component.MyGridItem;
	import com.component.MyGridRow;
	import com.MyUtility;
	
	import flash.events.MouseEvent;
	
	import mx.containers.Grid;
	import mx.controls.Label;
	import mx.controls.LinkButton;
	import mx.controls.Text;
	
	public class MyTaxGrid extends Grid
	{
		private var _label:Array = new Array("Name","Domain","Kingdom","Phylum","Class","Order","Family","Genus","Species","Organism");
		private var util:MyUtility = new MyUtility();
		private var _lineage:String = "";
		
		public function get lineage():String{
			return _lineage;
		}
		
		public function MyTaxGrid(){
			super();
			this.percentHeight=100;
			this.percentWidth=100;
			this.setStyle("verticalGap",0);
			this.setStyle("horizontalGap",3);
			this.setStyle("paddingBottom",0);
			this.setStyle("paddingTop",0);
		}
		

		public function makeGrid(arr:Array):void{
			var t:Text;
			var lb:LinkButton;
			var head:Label;
			var gi:MyGridItem;
			var gr:MyGridRow;
			var flag:Number=1;
			
			for(var j:int=0;j<_label.length;j++){
				gr=new MyGridRow();
				gi = new MyGridItem();
				gi.width=150;
				head = new Label();
				
				if ((j%2) == 0)
					gr.even();
				else gr.odd();
				
				head.text = _label[j];
				head.styleName = "header";
				gi.addChild(head);
				gr.addChild(gi);
				
				var tax:String = "N/A";
				for (var i:int=0;i<arr.length;i++){
					t = new Text();					
					t.percentWidth = 100;
					lb = new LinkButton();
					gi = new MyGridItem();
					gi.width=150;
					
					switch (_label[j]){
						case "Name":
							lb.label = "ORF " + arr[i].QUERYNAME.substring(arr[i].QUERYNAME.search(/_\d+$/)+1,arr[i].QUERYNAME.length);
							lb.name = arr[i].QUERYNAME.substring(arr[i].QUERYNAME.search(/_\d+$/)+1,arr[i].QUERYNAME.length);
							lb.id = arr[i].SEQUENCEID;
							lb.addEventListener(MouseEvent.CLICK,queryNameClickEvent);
							break;
						case "Domain":
							t.text = arr[i].DOMAIN;
							break;
						case "Kingdom":
							t.text = arr[i].KINGDOM;
							break;
						case "Phylum":
							t.text = arr[i].PHYLUM;
							break;
						case "Class":
							t.text = arr[i].CLASS;
							break;
						case "Order":
							t.text = arr[i].ORDER;
							break;
						case "Family":
							t.text = arr[i].FAMILY;
							break;
						case "Genus":
							t.text = arr[i].GENUS;
							break;
						case "Species":
							t.text = arr[i].SPECIES;
							break;
						case "Organism":
							t.text = arr[i].ORGANISM;
							break;
					}
					
					if (_label[j] == "Name")
						gi.addChild(lb);
					else {
						gi.addChild(t);
						if (tax=="N/A")
							tax = t.text;
						else if (tax != t.text)
							tax = "";
					}
					
					gr.addChild(gi);
				}
				
				if (_label[j]!="Name")
					if (flag && tax!="N/A")
						if (_lineage.length)
							_lineage = _lineage + "; " + tax;
						else _lineage = tax;
					else flag=0;
				
				this.addChild(gr);
			}
		} // end make grid function
		
		public function queryNameClickEvent(event:MouseEvent):void{
			var _chgTab:MyChgTabEvent = new MyChgTabEvent();
			_chgTab.id = event.currentTarget.id;
			_chgTab.name = event.currentTarget.label;
			_chgTab.num = event.currentTarget.name;
			
			util.app.dispatchEvent(_chgTab);
		}

	}
}