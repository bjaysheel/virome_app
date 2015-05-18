package com
{
	import flash.events.MouseEvent;
	import detail.MySequenceDetail;
	
	import mx.containers.*;
	import mx.controls.Alert;
	import mx.controls.LinkButton;
	import mx.controls.Text;
	import mx.managers.PopUpManager;
	import mx.core.FlexGlobals;
	import flash.display.DisplayObject;
	
	public class MyBlastResult extends VBox
	{
		public function MyBlastResult()
		{
			super();
			this.percentHeight = 100;
			this.percentWidth = 100;
			this.setStyle("verticalGap",-10);
		}
		
		public function formatResult(str:String):void{
			var txt:Text = new Text;
			
			// check if blast reported an error
	    	if (str.search(/Error/i) > -1){
	    		txt.styleName = "errorBlast";
	    		txt.text = str;
	    		this.addChild(txt);
	    	}
	    	else {
		    	// create regular expressions to find links.
		    	var regx_g:RegExp = /(.*)\[(\d+)_(\w+)\](.*)\[.*\](.*)/gi;
		    	var regx_l:RegExp = /(.*)\[(\d+)_(\w+)\](.*)\[.*\](.*)/;
		    	
		    	// get all link.
		    	var result:Array = str.match(regx_g);
		    	var start:int=0;
		    	
		    	// loop through all links
		    	for (var i:int=0; i<result.length; i++){
		    		
		    		txt.styleName = "sequence";
		    		
		    		// extract all regular text before a link, and add it to main stage.
		    		txt.text = str.substr(start,str.indexOf(result[i])-start);
		    		this.addChild(txt);
		    		
		    		// extract all parts of links
		    		var line:Array = result[i].match(regx_l);
		    		
		    		// create link button
		    		var link:LinkButton = new LinkButton();
		    		link.id = line[2] + "|" + line[3];
					link.label = line[1] + line[4];
					link.addEventListener(MouseEvent.CLICK, this.detailHandler);
					
					// disable link if needed
					if (line[3] == "null")
						link.enabled = false;
					
					// add link to the main stage along with the rest of the text on the line.
					var hbox:HBox = new HBox;
					hbox.addChild(link);
					txt = new Text;
					txt.text = line[5];
					hbox.addChild(txt);
					this.addChild(hbox);
					
					// reset start postion to end of link line
					start = str.indexOf(result[i]) + result[i].toString().length;
					txt = new Text;
		    	}
		    	
				txt.styleName = "sequence";
				
				// add what ever text is left from blast report
				txt.text = str.substr(start,str.length-start);	
		    	this.addChild(txt);
	    	}
		}
		
		public function detailHandler(event:MouseEvent):void {
			var vals:Array = (event.currentTarget.id as String).split("|");
			
			var sequence_detail:MySequenceDetail = MySequenceDetail(PopUpManager.createPopUp(DisplayObject(FlexGlobals.topLevelApplication), MySequenceDetail, true));
			sequence_detail.orfId = vals[0];
			sequence_detail.environment = vals[1];
			sequence_detail.seqname = ((event.currentTarget.label as String).substr(0,1) == ">") ? (event.currentTarget.label as String).substr(1,(event.currentTarget.label as String).length) : (event.currentTarget.label as String);
			
			PopUpManager.bringToFront(sequence_detail);
		}
	}
}