package com
{
	import com.google.maps.interfaces.INavigationControl;
	
	import flash.display.DisplayObject;
	
	import mx.collections.ArrayCollection;
	import mx.controls.Alert;
	import mx.controls.DataGrid;
	import mx.controls.dataGridClasses.DataGridColumn;
	import mx.core.ClassFactory;
	import mx.events.CollectionEvent;
	import mx.events.FlexEvent;
	import mx.events.ListEvent;
	import mx.events.ModuleEvent;
	import mx.modules.IModuleInfo;
	import mx.modules.ModuleManager;
	
	import search.EvalueRenderer;
	import search.SequenceNLenRenderer;
	
	public class MyDBResult extends DataGrid{
		
		[Bindable] private var _util:MyUtility = new MyUtility();
		private var _ncRNAFlag:Boolean = false;
		
		[Bindable] public function set ncRNAFlag(v:Boolean):void{
			_ncRNAFlag = v;
		}
		public function get ncRNAFlag():Boolean{
			return _ncRNAFlag;
		}
		
		private var _sd:Object = new Object();
		
		public function MyDBResult(){
			super();			
			this.percentHeight=100;
			this.percentWidth=100;
			this.setStyle("paddingLeft","-3");
			this.addEventListener(ListEvent.ITEM_CLICK,sequenceDetailRequest);
			this.dataProvider = new ArrayCollection();
			
			setColumns();
		}
		
		public function disableGrid():void{
			this.enabled=false;
			this.removeEventListener(ListEvent.ITEM_CLICK,sequenceDetailRequest);
		}
		
		public function enableGrid():void{
			this.enabled=true;
			this.addEventListener(ListEvent.ITEM_CLICK,sequenceDetailRequest);
		}
		
		protected function setColumns():void{
			var col1:DataGridColumn = new DataGridColumn;
			col1.dataField = "DATABASE_NAME";
			col1.headerText = "Blast DB";
			col1.width = 90;
			col1.visible = false;
			
			var col2:DataGridColumn = new DataGridColumn;
			col2.dataField = "NAME";
			col2.headerText = "Sequence Name";
			col2.itemRenderer = new ClassFactory(search.SequenceNLenRenderer);
			col2.width = 215;

			var col3:DataGridColumn = new DataGridColumn;
			col3.dataField = "HIT_NAME";
			col3.labelFunction = formatHitDef;
			col3.headerText = "Hit Name/Accession";
			col3.width=175;

			var col4:DataGridColumn = new DataGridColumn;
			col4.dataField = "HIT_DESCRIPTION";
			col4.headerText = "Description";
			col4.width=200;
			
			var col5:DataGridColumn = new DataGridColumn;
			col5.dataField = "E_VALUE";
			col5.headerText = "Evalue";
			//col5.itemRenderer = new ClassFactory(search.EvalueRenderer);
			//col5.sortCompareFunction = sortEvalueFunction;
			col5.width = 75;
			
			var col6:DataGridColumn = new DataGridColumn;
			col6.dataField = "BIT_SCORE";
			col6.headerText = "Bit Score";
			col6.width = 90;
			col6.visible = false;
			
			var col7:DataGridColumn = new DataGridColumn;
			col7.dataField = "QUERY_LENGTH";
			col7.headerText = "% QRY Coverage";
			col7.itemRenderer = new ClassFactory(search.QryCoverageRenderer);
			col7.width = 80;
			
			var col8:DataGridColumn = new DataGridColumn;
			col8.dataField = "PERCENT_SIMILARITY";
			col8.headerText = "% Similarity";
			col8.width = 90;
			
			var col9:DataGridColumn = new DataGridColumn;
			col9.dataField = "PERCENT_IDENTITY";
			col9.headerText = "% Identitiy";
			col9.width = 90;
			
			var col10:DataGridColumn = new DataGridColumn;
			col10.dataField = "DOMAIN";
			col10.headerText = "Domain";
			col10.visible = false;
			
			var col11:DataGridColumn = new DataGridColumn;
			col11.dataField = "KINGDOM";
			col11.headerText = "Kingdom";
			col11.visible = false;
			
			var col12:DataGridColumn = new DataGridColumn;
			col12.dataField = "PHYLUM";
			col12.headerText = "Phylum";
			col12.visible = false;
			
			var col13:DataGridColumn = new DataGridColumn;
			col13.dataField = "CLASS";
			col13.headerText = "Class";
			col13.visible = false;
			
			var col14:DataGridColumn = new DataGridColumn;
			col14.dataField = "ORDER";
			col14.headerText = "Order";
			col14.visible = false;
			
			var col15:DataGridColumn = new DataGridColumn;
			col15.dataField = "FAMILY";
			col15.headerText = "Family";
			col15.visible = false;
			
			var col16:DataGridColumn = new DataGridColumn;
			col16.dataField = "GENUS";
			col16.headerText = "Genus";
			col16.visible = false;
			
			var col17:DataGridColumn = new DataGridColumn;
			col17.dataField = "SPECIES";
			col17.headerText = "Species";
			col17.visible = false;
			
			var col18:DataGridColumn = new DataGridColumn;
			col18.dataField = "ORGANISM";
			col18.headerText = "Organism";
			col18.visible = true;
			
			this.columns = [col1,col2,col3,col4,col5,col6,col7,col8,col9,col10,col11,col12,col13,col14,col15,col16,col17,col18];
		}
		
		protected function sortEvalueFunction(obj1:Object, obj2:Object):int{
			var eval1:String = obj1.E_VALUE as String;
			var eval2:String = obj2.E_VALUE as String;
			var mantissa1:Number;
			var mantissa2:Number;
			var exponent1:Number;
			var exponent2:Number;
			
			var pattern:RegExp = /e/i;
			var idx:Number = eval1.search(pattern);
			if (idx < 0){
				eval1 = _util.toScientific(eval1,2);
			}
			idx = eval1.search(pattern);
			mantissa1 = Number(eval1.substring(0,idx));
			exponent1 = Number(eval1.substring(idx+1,eval1.length));
			exponent1 = Math.abs(exponent1);
			
			idx = eval2.search(pattern);
			if (idx < 0){
				eval2 = _util.toScientific(eval2,2);
			}
			idx = eval2.search(pattern);
			mantissa2 = Number(eval2.substring(0,idx));
			exponent2 = Number(eval2.substring(idx+1,eval2.length));
			exponent2 = Math.abs(exponent2);
			
			if (exponent1 > exponent2){
				return -1;
			} else {
				return 1;
			}
		}
		
		protected function formatHitDef(item:Object, hitName:DataGridColumn):String{
			return _util.str_replace("+", " ", unescape(item.HIT_NAME));
		}
		
		protected function sequenceDetailRequest(event:ListEvent):void{
			var DP:Object = _util.app.page.getChildByName("Sequenced");
			DP.sequenceId = event.currentTarget.selectedItem.SEQUENCEID;
			DP.environment = event.currentTarget.selectedItem.ENVIRONMENT;
			DP.seqname = event.currentTarget.selectedItem.NAME;
			DP.ncRNAFlag = ncRNAFlag;
			_util.app.simulateMenuClick('sequenced');
		}
	}
}