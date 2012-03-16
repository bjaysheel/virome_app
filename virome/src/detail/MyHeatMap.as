package detail
{
	import com.component.MyGridItem;
	import com.component.MyGridRow;
	import com.component.MyNumberFormatter;
	import com.component.MyToolTip;
	
	import flash.display.DisplayObject;
	import flash.events.MouseEvent;
	
	import mx.containers.Grid;
	import mx.containers.GridItem;
	import mx.containers.GridRow;
	import mx.containers.HBox;
	import mx.controls.Label;
	import mx.controls.Text;
	import mx.core.FlexGlobals;
	import mx.formatters.NumberFormatter;
	import mx.managers.PopUpManager;
	import mx.managers.ToolTipManager;
	
	public class MyHeatMap extends Grid
	{
		private var nf:NumberFormatter = new NumberFormatter();
		
		public function MyHeatMap()
		{
			super();
			nf.precision = 0;
			this.percentHeight=100;
			this.setStyle("verticalGap",0);
			this.setStyle("horizontalGap",0);
			header();
		}
		
		private function header():void{
			var gi:MyGridItem;
			var head:Label;
			var gr:MyGridRow = new MyGridRow();
			gr.header();
			
			head = new Label();
			head.text = "Num";
			head.styleName = "header";
			head.width = 50;
			gi = new MyGridItem();
			gi.addChild(head);
			gr.addChild(gi);
			
			head = new Label();
			head.text = "UNI";
			head.styleName = "header";
			head.width = 50;
			gi = new MyGridItem();
			gi.addChild(head);
			gr.addChild(gi);
			
			head = new Label();
			head.text = "SEED";
			head.styleName = "header";
			head.width = 50;
			gi = new MyGridItem();
			gi.addChild(head);
			gr.addChild(gi);

			head = new Label();
			head.text = "KEGG";
			head.styleName = "header";
			head.width = 50;
			gi = new MyGridItem();
			gi.addChild(head);
			gr.addChild(gi);
			
			head = new Label();
			head.text = "COG";
			head.styleName = "header";
			head.width = 50;
			gi = new MyGridItem();
			gi.addChild(head);
			gr.addChild(gi);
			
			head = new Label();
			head.text = "ACL";
			head.styleName = "header";
			head.width = 50;
			gi = new MyGridItem();
			gi.addChild(head);
			gr.addChild(gi);

			head = new Label();
			head.text = "META";
			head.styleName = "header";
			head.width = 50;
			gi = new MyGridItem();
			gi.addChild(head);
			gr.addChild(gi);
			
			this.addChild(gr);
		}
		
		public function makeMap(obj:Object):void{
			var gi:GridItem;
			var gr:GridRow;
			var head:Text;
			var emin:Number = 0;
			var emax:Number = 0;
			var cmin:Number = 0;
			var cmax:Number = 0;
			var id:Number;
			var db:String;
			var env:String;
			
			ToolTipManager.toolTipClass = MyToolTip;
			
			// add legend
			gr = new GridRow();
			gi = new GridItem();
			head = new Text();
			
			gi.colSpan = 7;
			head.percentWidth = 100;
			gi.addChild(head);
			head.text = "Legend"
			head.setStyle("textAlign","left");
			head.setStyle("fontWeight","bold");
			gr.addChild(gi);
			this.addChildAt(gr,0);
			
			var flag:Boolean;
			
			for (var i:int=0; i<10; i++){
				flag = false;
				
				gr = new GridRow();
					
				head = new Text();
				gi = new GridItem();
				gi.width=50;
				gi.height=50;
				head.percentWidth=100;
				gi.addChild(head);
				head.text = (i+1).toString();
				head.setStyle("textAlign","center");
				gr.addChild(gi);
					
				////////////////////////////////////
				// UNIREF map
				////////////////////////////////////
				gi = new GridItem();
				gi.width=50;
				gi.height=50;
				if ((obj.UNIREF100P != undefined) && (obj.UNIREF100P.length > i)){
					flag = true;
					
					gi.setStyle("backgroundColor",obj.UNIREF100P[i].COLOR);
					gi.toolTip = "Description: " + obj.UNIREF100P[i].HITDESCRIPTION + 
								"<br/>Evalue: " + obj.UNIREF100P[i].EVALUE + 
								"<br/>Qry Coverage: " + 
								new MyNumberFormatter().format(obj.UNIREF100P[i].QCOVER).toString() +
								"%";
					//get min max its the same value so if overwritten its not an issues
					//since we don't know right now which db has a hit and how many
					//we are sure to say that either uniref or metagene has hits.
					emin = obj.UNIREF100P[i].EMIN;
					emax = obj.UNIREF100P[i].EMAX;
					cmin = obj.UNIREF100P[i].CMIN;
					cmax = obj.UNIREF100P[i].CMAX;

					// since seq and env are the same for a heat map
					// overriding is not an issue.
					id = obj.UNIREF100P[i].SEQUENCEID;
					env = obj.UNIREF100P[i].ENVIRONMENT;

					gi.addEventListener(MouseEvent.CLICK,function(e:MouseEvent):void{
								blastDetailFunc(e,id,"UNIREF100P",env);
					});
				} else gi.setStyle("backgroundColor","#FFFFFF");
				gr.addChild(gi);
				
				////////////////////////////////////
				// SEED MAP
				////////////////////////////////////
				gi = new GridItem();
				gi.width=50;
				gi.height=50;
				if ((obj.SEED != undefined) && (obj.SEED.length > i)){
					flag = true;
					gi.setStyle("backgroundColor",obj.SEED[i].COLOR);
					gi.toolTip = "Description: " + obj.SEED[i].HITDESCRIPTION + 
						"<br/>Evalue: " + obj.SEED[i].EVALUE + 
						"<br/>Qry Coverage: " + 
						new MyNumberFormatter().format(obj.SEED[i].QCOVER).toString() +
						"%";
					
					// since seq and env are the same for a heat map
					// overriding is not an issue.
					id = obj.SEED[i].SEQUENCEID;
					env = obj.SEED[i].ENVIRONMENT;

					gi.addEventListener(MouseEvent.CLICK,function(e:MouseEvent):void{
						blastDetailFunc(e,id,"SEED",env);
					});
				} else gi.setStyle("backgroundColor","#FFFFFF");
				gr.addChild(gi);
					
				////////////////////////////////////////
				// KEGG map
				////////////////////////////////////////
				gi = new GridItem();
				gi.width=50;
				gi.height=50;
				if ((obj.KEGG != undefined) && (obj.KEGG.length > i)){
					flag = true;
					gi.setStyle("backgroundColor",obj.KEGG[i].COLOR);
					gi.toolTip = "Description: " + obj.KEGG[i].HITDESCRIPTION + 
						"<br/>Evalue: " + obj.KEGG[i].EVALUE + 
						"<br/>Qry Coverage: " + 
						new MyNumberFormatter().format(obj.KEGG[i].QCOVER).toString() +
						"%";
					
					// since seq and env are the same for a heat map
					// overriding is not an issue.
					id = obj.KEGG[i].SEQUENCEID;
					env = obj.KEGG[i].ENVIRONMENT;

					gi.addEventListener(MouseEvent.CLICK,function(e:MouseEvent):void{
						blastDetailFunc(e,id,"KEGG",env);
					});
				}
				else gi.setStyle("backgroundColor","#FFFFFF");
				gr.addChild(gi);
					
				//////////////////////////////////////////
				// COG map
				//////////////////////////////////////////
				gi = new GridItem();
				gi.width=50;
				gi.height=50;
				if ((obj.COG != undefined) && (obj.COG.length > i)){
					flag = true;
					gi.setStyle("backgroundColor",obj.COG[i].COLOR);
					gi.toolTip = "Description: " + obj.COG[i].HITDESCRIPTION +
						"<br/>Evalue: " + obj.COG[i].EVALUE + 
						"<br/>Qry Coverage: " + 
						new MyNumberFormatter().format(obj.COG[i].QCOVER).toString() +
						"%";
					
					// since seq and env are the same for a heat map
					// overriding is not an issue.
					id = obj.COG[i].SEQUENCEID;
					env = obj.COG[i].ENVIRONMENT;
					
					gi.addEventListener(MouseEvent.CLICK,function(e:MouseEvent):void{
						blastDetailFunc(e,id,"COG",env);
					});
				}
				else gi.setStyle("backgroundColor","#FFFFFF");
				gr.addChild(gi);					
					
				///////////////////////////////////////
				// ACLAME map
				///////////////////////////////////////
				gi = new GridItem();
				gi.width=50;
				gi.height=50;
				if ((obj.ACLAME != undefined) && (obj.ACLAME.length > i)){
					flag = true;
					gi.setStyle("backgroundColor",obj.ACLAME[i].COLOR);
					gi.toolTip = "Description: " + obj.ACLAME[i].HITDESCRIPTION +
						"Evalue: " + obj.ACLAME[i].EVALUE + 
						"<br/>Qry Coverage: " + 
						new MyNumberFormatter().format(obj.ACLAME[i].QCOVER).toString() +
						"%";
					
					// since seq and env are the same for a heat map
					// overriding is not an issue.
					id = obj.ACLAME[i].SEQUENCEID;
					env = obj.ACLAME[i].ENVIRONMENT;

					gi.addEventListener(MouseEvent.CLICK,function(e:MouseEvent):void{
						blastDetailFunc(e,id,"ACLAME",env);
					});

				}
				else gi.setStyle("backgroundColor","#FFFFFF");
				gr.addChild(gi);
					
				/////////////////////////////////////////
				// METAGENOMES map
				/////////////////////////////////////////
				gi = new GridItem();
				gi.width=50;
				gi.height=50;
				if ((obj.METAGENOMES != undefined) && (obj.METAGENOMES.length > i)){
					flag = true;
					gi.setStyle("backgroundColor",obj.METAGENOMES[i].COLOR);
					gi.toolTip = "Description: " + obj.METAGENOMES[i].HITDESCRIPTION + 
						"<br/>Evalue: " + obj.METAGENOMES[i].EVALUE + 
						"<br/>Qry Coverage: " + 
						new MyNumberFormatter().format(obj.METAGENOMES[i].QCOVER).toString() +
						"%";
					
					//get min max its the same value so if overwritten its not an issues
					// we are only getting min max values in uniref or metagenomes, because
					// we are guarantied to have either one of these or either. we can't 
					// anything for sure while looping 10 times over other db results
					emin = obj.METAGENOMES[i].EMIN;
					emax = obj.METAGENOMES[i].EMAX;
					cmin = obj.METAGENOMES[i].CMIN;
					cmax = obj.METAGENOMES[i].CMAX;
					
					// since seq and env are the same for a heat map
					// overriding is not an issue.
					id = obj.METAGENOMES[i].SEQUENCEID;
					env = obj.METAGENOMES[i].ENVIRONMENT;
					
					gi.addEventListener(MouseEvent.CLICK,function(e:MouseEvent):void{
						blastDetailFunc(e,id,"METAGENOMES",env);
					});
				}
				else gi.setStyle("backgroundColor","#FFFFFF");
				gr.addChild(gi);
				
				if (flag){
					this.addChild(gr);
				} //else i=10;
				
			} // end for loop
			
			makeLedgend(emin.toString(),emax.toString(),
						0xFF0000,0x0000FF,"evalue",1);


			//add empty row
			gr = new GridRow();
			gi= new GridItem();
			gi.colSpan=7;
			gi.height=20;
			gr.addChild(gi);
			this.addChildAt(gr,2);
		}

		protected function makeLedgend(min:String,max:String,color1:Number,color2:Number,str:String,r:Number):void{
			var hbox:HBox = new HBox();
			var gi:GridItem = new GridItem();			
			var gr:GridRow = new GridRow();
			var txt1:Text = new Text();
			var txt2:Text = new Text();
			var mld:MyLegend = new MyLegend();
			
			gi.colSpan=5;
			gi.addChild(hbox);
			gr.addChild(gi);
			
			txt1.width=50;
			txt1.text = min;
			txt1.setStyle("textAlign","right");
			hbox.addChild(txt1);
			
			mld.color1 = color1;
			mld.color2 = color2;
			mld.xcord = txt1.x + 50;
			mld.ycord = txt1.y + 3;
			mld.drawLedgend();
			hbox.rawChildren.addChild(mld);
			
			gi = new GridItem();
			gi.colSpan=2
			//txt2.width=100;
			txt2.text = max + " " + str;
			txt2.setStyle("textAlign","right");
			gi.addChild(txt2);
			gr.addChild(gi);
						
			this.addChildAt(gr,r);
			//this.addChild(gr);
		}
		
		protected function blastDetailFunc(event:MouseEvent,id:Number,db:String,env:String):void{
			var blstDetail:MyBlastDetails = MyBlastDetails(PopUpManager.createPopUp(DisplayObject(FlexGlobals.topLevelApplication), MyBlastDetails, true));
			blstDetail.sequence = id;
			blstDetail.database = db;
			blstDetail.environment = env;
			blstDetail.init();
			PopUpManager.bringToFront(blstDetail);
			//PopUpManager.centerPopUp(blstDetail);
		}
	}
}