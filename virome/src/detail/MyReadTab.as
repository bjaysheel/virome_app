package detail
{	
	import com.DownloadGrid;
	import com.MyBlastImager;
	import com.MyUtility;
	import com.component.MyGridItem;
	import com.component.MyGridRow;
	import com.events.UpdateORFViewEvent;
	
	import flash.display.DisplayObject;
	import flash.events.MouseEvent;
	
	import mx.collections.ArrayCollection;
	import mx.containers.Grid;
	import mx.containers.GridRow;
	import mx.containers.HBox;
	import mx.containers.VBox;
	import mx.controls.Alert;
	import mx.controls.DataGrid;
	import mx.controls.HRule;
	import mx.controls.Image;
	import mx.controls.Label;
	import mx.controls.LinkButton;
	import mx.controls.Text;
	import mx.controls.VRule;
	import mx.controls.dataGridClasses.DataGridColumn;
	import mx.core.ClassFactory;
	import mx.core.FlexGlobals;
	import mx.data.messages.PagedMessage;
	import mx.events.ListEvent;
	import mx.managers.PopUpManager;
	import mx.skins.halo.HaloBorder;
	
	public class MyReadTab extends VBox
	{
		private var object:Object;
		private var _util:MyUtility = new MyUtility();
		
		private static var MAX_BASE_COUNT:int = 60;
		private static var MAX_SEQ_SIZE:int = 240; //four lines of MAX_BASE_COUNT
		private static var MAX_ROW_COUNT:int = 5;
		
		public function MyReadTab(o:Object)
		{
			super();

			this.name = "Read";
			this.label = "Read";
			this.percentHeight = 100;
			this.percentWidth = 100;
			//this.maxWidth = 1245; //keep it smaller than 1280 to account for spacing and scrollbars
			
			object = new Object();
			object = o;
			
			showReadDetails();
		}		
		
		public function showReadDetails():void {
			
			// top box contains seq info on the left 
			// and blast image on the right.
			var tbox:HBox = new HBox();
			//tbox.percentHeight = 100;
			
				var lbox:VBox = new VBox();
				lbox.percentHeight = 100;
				
				//-----------------------------------------------------------
				// display sequence name
				lbox.addChild(displaySimpleValue("Name:", object.NAME));
				
				// display sequence length
				lbox.addChild(displaySimpleValue("Length:", object.SIZE));
				
				// display dna bases
				lbox.addChild(dnaBases(true));
				
				// display sequence length
				lbox.addChild(displaySimpleValue("Number of ORFs:", object.ORF_COUNT));

				// display sequence length
				lbox.addChild(displaySimpleValue("Number of TRNAs:", object.TRNA_COUNT));

				tbox.addChild(lbox);
				
				// add divider
				var vrule:VRule = new VRule();
				vrule.percentHeight = 100;
				
				tbox.addChild(vrule);
				
				//-----------------------------------------------------------
				// add blast imager.
				var rbox:VBox = new VBox();
				
				rbox.addChild(displayImage(object));
				tbox.addChild(rbox);
			
			this.addChild(tbox);
			
			var hrule:HRule = new HRule();
			hrule.percentWidth = 100;
			this.addChild(hrule);
			
			//-----------------------------------------------------------
			// display taxonomy and env detail grids at the bottom half.
			
			// display blast hits per database.
			if ((object.UNIREF100P != undefined) && (object.UNIREF100P as Array).length) {
				this.addChild(displayTophitsTable(true, "UNIREF100P"));
			}
			if ((object.ACLAME != undefined) && (object.ACLAME as Array).length) {
				this.addChild(displayTophitsTable(true, "ACLAME"));
			}
			if ((object.SEED != undefined) && (object.SEED as Array).length) {
				this.addChild(displayTophitsTable(true, "SEED"));
			}
			if ((object.KEGG != undefined) && (object.KEGG as Array).length) {
				this.addChild(displayTophitsTable(true, "KEGG"));
			}
			if ((object.COG != undefined) && (object.COG as Array).length) {
				this.addChild(displayTophitsTable(true, "COG"));
			}
			
			// displaly taxonomy and env details.
			if ((object.UNIREF100P != undefined) && (object.UNIREF100P as Array).length) {
				this.addChild(displayTaxonomyTable(true));
			}
			if ((object.METAGENOMES != undefined) && (object.METAGENOMES as Array).length) {
				this.addChild(displayTophitsTable(true, "METAGENOMES"));
			}
			
			// display environmental data grid
			if ((object.ORF_ENV_DETAIL != undefined) && (object.ORF_ENV_DETAIL as Array).length) {
				this.addChild(displayEnvironmentTable(true));
			}
		}
		
		private function dnaBases(limit:Boolean):VBox {
			var seq_label:Label  = new Label();
			seq_label.text = "DNA Sequence:";
			seq_label.styleName = "strong";
			
			var seq:Text = new Text();
			seq.styleName = "sequence";
			seq.setStyle("paddingLeft", "25");
			
			var str:String = object.BASEPAIR;
			
			if (limit && str.length > MAX_SEQ_SIZE){
				str = str.substr(0, MAX_SEQ_SIZE);
			}
				
			for (var i:int=0; i < str.length; i+=MAX_BASE_COUNT){
				seq.text += str.substr(i,MAX_BASE_COUNT)+"\n";
			}
			
			var vbox:VBox = new VBox();
			vbox.setStyle("verticalGap", "0");
			vbox.addChild(seq_label);
			vbox.addChild(seq);
			
			// add more button of seq was truncated
			if (limit && (object.BASEPAIR).length > MAX_SEQ_SIZE) {
				var more:LinkButton = new LinkButton();
				more.label = "...more";
				more.addEventListener(MouseEvent.CLICK, showCompleteSeq);
				
				vbox.addChild(more);
			}
			
			return vbox;
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
		
		private function displayTaxonomyTable(limit:Boolean):VBox {
			var label:Label = new Label();
			label.text = "Functional taxonomy of top UNIREF100P hits";
			label.styleName = "strong";
			
			var ac:Array = object.UNIREF100P as Array;
			
			var datagrid:DataGrid = new DataGrid();
			datagrid.addEventListener(ListEvent.ITEM_CLICK, switchToORF);
			datagrid.percentWidth = 100;
			
			var orf_num:DataGridColumn = new DataGridColumn();
			var t_domain:DataGridColumn = new DataGridColumn();
			var t_kingdom:DataGridColumn = new DataGridColumn();
			var t_phylum:DataGridColumn = new DataGridColumn();
			var t_class:DataGridColumn = new DataGridColumn();
			var t_order:DataGridColumn = new DataGridColumn();
			var t_family:DataGridColumn = new DataGridColumn();
			var t_genus:DataGridColumn = new DataGridColumn();
			var t_species:DataGridColumn = new DataGridColumn();
			var t_organism:DataGridColumn = new DataGridColumn();
			
			orf_num.dataField = "QUERY_NAME";
			var dg:ClassFactory = new ClassFactory(DownloadGrid);
			dg.properties = {dgAC:datagrid, environment:object.ENVIRONMENT, libraryId:object.LIBRARYID};
			orf_num.headerRenderer = dg;
			
			t_domain.dataField = "DOMAIN";
			t_kingdom.dataField = "KINGDOM";
			t_phylum.dataField = "PHYLUM";
			t_class.dataField = "CLASS";
			t_order.dataField = "ORDER";
			t_family.dataField = "FAMILY";
			t_genus.dataField = "GENUS";
			t_species.dataField = "SPECIES";
			t_organism.dataField = "ORGANISM";
			
			var cols:Array = new Array();
			cols.push(orf_num);
			cols.push(t_domain);
			cols.push(t_kingdom);
			cols.push(t_phylum);
			cols.push(t_class);
			cols.push(t_order);
			cols.push(t_family);
			cols.push(t_genus);
			cols.push(t_species);
			cols.push(t_organism);
			
			datagrid.columns = cols;
			datagrid.dataProvider = ac;
			
			var vbox:VBox = new VBox();
			vbox.percentWidth = 100;
			vbox.setStyle("paddingTop", "15");
			vbox.addChild(label);
			vbox.addChild(datagrid);
			
			if(limit) {
				datagrid.rowCount = MAX_ROW_COUNT;
				
				if  (ac.length > MAX_ROW_COUNT) {
					datagrid.horizontalScrollPolicy = "off";
					datagrid.verticalScrollPolicy = "off";
				
					var more:LinkButton = new LinkButton();
					more.label = "...more";
					more.addEventListener(MouseEvent.CLICK, showCompleteFuncGrid);
				
					vbox.addChild(more);
				}
			}
			
			return vbox;
		}
		
		private function displayEnvironmentTable(limit:Boolean):VBox {
			var label:Label = new Label();
			label.text = "Environmental summary of top hits";
			label.styleName = "strong";
			
			var datagrid:DataGrid = new DataGrid();
			datagrid.addEventListener(ListEvent.ITEM_CLICK, switchToORF);
			datagrid.percentWidth = 100;
			
			var orf_num:DataGridColumn = new DataGridColumn();
			var e_lib_type:DataGridColumn = new DataGridColumn();
			var e_seq_type:DataGridColumn = new DataGridColumn();
			var e_na_type:DataGridColumn = new DataGridColumn();
			var e_genesis:DataGridColumn = new DataGridColumn();
			var e_sphere:DataGridColumn = new DataGridColumn();
			var e_ecosystem:DataGridColumn = new DataGridColumn();
			var e_phys_subst:DataGridColumn = new DataGridColumn();
			var e_region:DataGridColumn = new DataGridColumn();
			
			orf_num.dataField = "QUERY_NAME";
			var dg:ClassFactory = new ClassFactory(DownloadGrid);
			dg.properties = {dgAC:datagrid, environment:object.ENVIRONMENT, libraryId:object.LIBRARYID};
			orf_num.headerRenderer = dg;
			
			e_lib_type.dataField = "LIB_TYPE";
			e_seq_type.dataField = "SEQ_TYPE";
			e_na_type.dataField = "NA_TYPE";
			e_genesis.dataField = "GENESIS";
			e_sphere.dataField = "SPHERE";
			e_ecosystem.dataField = "ECOSYSTEM";
			e_phys_subst.dataField = "PHYS_SUBST";
			e_region.dataField = "REGION";
			
			var cols:Array = new Array();
			cols.push(orf_num);
			cols.push(e_lib_type);
			cols.push(e_seq_type);
			cols.push(e_na_type);
			cols.push(e_genesis);
			cols.push(e_sphere);
			cols.push(e_ecosystem);
			cols.push(e_phys_subst);
			cols.push(e_region);
			
			var ac:Array = object.ORF_ENV_DETAIL as Array;
			
			datagrid.columns = cols;
			datagrid.dataProvider = ac;
			
			var vbox:VBox = new VBox();
			vbox.percentWidth = 100;
			vbox.setStyle("paddingTop", "15");
			vbox.addChild(label);
			vbox.addChild(datagrid);
			
			if(limit) {
				datagrid.rowCount = MAX_ROW_COUNT;
				
				if(ac.length > MAX_ROW_COUNT) {
					datagrid.horizontalScrollPolicy = "off";
					datagrid.verticalScrollPolicy = "off";
					
					var more:LinkButton = new LinkButton();
					more.label = "...more";
					more.addEventListener(MouseEvent.CLICK, showCompleteEnvGrid);
					
					vbox.addChild(more);
				}
			}
			
			return vbox;
		}
		
		private function displayTophitsTable(limit:Boolean, type:String):VBox {
			var label:Label = new Label();
			label.text = "BLAST summary of " + type + " top hits";
			label.styleName = "strong";
			
			var cols:Array = new Array();
			var datagrid:DataGrid = new DataGrid();
			datagrid.addEventListener(ListEvent.ITEM_CLICK, switchToORF);
			datagrid.percentWidth = 100;
			
			var qry_name:DataGridColumn = new DataGridColumn();
			var hit_name:DataGridColumn = new DataGridColumn();
			var hit_description:DataGridColumn = new DataGridColumn();
			var evalue:DataGridColumn = new DataGridColumn();
			var bit_score:DataGridColumn = new DataGridColumn();
			var qry_cov:DataGridColumn = new DataGridColumn();
			var prct_identity:DataGridColumn = new DataGridColumn();
			var prct_similarity:DataGridColumn = new DataGridColumn();
			
			qry_name.dataField = "QUERY_NAME";
			var dg:ClassFactory = new ClassFactory(DownloadGrid);
			dg.properties = {dgAC:datagrid, environment:object.ENVIRONMENT, libraryId:object.LIBRARYID};
			qry_name.headerRenderer = dg;
			
			hit_name.dataField = "HIT_NAME";
			hit_description.dataField = "HIT_DESCRIPTION";
			evalue.dataField = "E_VALUE";
			bit_score.dataField = "BIT_SCORE";
			qry_cov.dataField = "QRY_COVERAGE";
			prct_identity.dataField = "PERCENT_IDENTITY";
			prct_similarity.dataField = "PERCENT_SIMILARITY";
			
			cols.push(qry_name);
			cols.push(hit_name);
			cols.push(hit_description);
			cols.push(evalue);
			cols.push(bit_score);
			cols.push(qry_cov);
			cols.push(prct_identity);
			cols.push(prct_similarity);
			
			var ac:Array = object[type] as Array;
			
			datagrid.columns = cols;
			datagrid.dataProvider = ac;
			
			var vbox:VBox = new VBox();
			vbox.percentWidth = 100;
			vbox.setStyle("paddingTop", "15");
			vbox.addChild(label);
			vbox.addChild(datagrid);
			
			if(limit) {
				datagrid.rowCount = MAX_ROW_COUNT;
				
				if(ac.length > MAX_ROW_COUNT) {
					datagrid.horizontalScrollPolicy = "off";
					datagrid.verticalScrollPolicy = "off";
					
					var more:LinkButton = new LinkButton();
					more.label = "...more";
					more.addEventListener(MouseEvent.CLICK, function (e:MouseEvent):void { showCompleteTopHitGrid(e, type); });
					
					vbox.addChild(more);
				}
			}
			
			return vbox;
		}
		
		private function displayImage(obj:Object):MyBlastImager {
			var img:MyBlastImager = new MyBlastImager(obj);
			
			return img;
		}
		
		private function showCompleteSeq(e:MouseEvent):void {
			popup(dnaBases(false), "Complete DNA sequence");
		}
		
		private function showCompleteFuncGrid(e:MouseEvent):void{
			popup(displayTaxonomyTable(false), "Complete functional taxonomy");
		}
		
		private function showCompleteEnvGrid(e:MouseEvent):void{
			popup(displayEnvironmentTable(false), "Complete environment summary");
		}
		
		private function showCompleteTopHitGrid(e:MouseEvent, type:String):void{
			popup(displayTophitsTable(false, type), "BLAST hit summary");
		}
		
		private function popup(d:VBox, title:String):void {
			var my_popup:MyPopUp = MyPopUp(PopUpManager.createPopUp(DisplayObject(FlexGlobals.topLevelApplication), MyPopUp, true));
			my_popup.title = title;
			my_popup.display = d;
			
			PopUpManager.bringToFront(my_popup);
		}
		
		private function switchToORF(e:ListEvent):void {
			var orfview:UpdateORFViewEvent = new UpdateORFViewEvent();
			orfview.seqName = e.currentTarget.selectedItem.QUERY_NAME;
			
			this.dispatchEvent(orfview);
		}
	}
}