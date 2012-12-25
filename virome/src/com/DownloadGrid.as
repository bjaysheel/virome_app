package com
{
	import com.events.FileSelectorEvent;
	import com.events.SearchDBEvent;
	
	import flash.events.MouseEvent;
	
	import mx.collections.ArrayCollection;
	import mx.containers.HBox;
	import mx.controls.Alert;
	import mx.controls.Button;
	import mx.controls.DataGrid;
	import mx.controls.Label;
	import mx.core.FlexGlobals;
	import mx.managers.PopUpManager;
	import flash.display.DisplayObject;
	
	
	public class DownloadGrid extends HBox
	{
		[Embed(source='/assets/icons/Download_mini.png')]
		private var DLIcon:Class;
		
		public var dgAC:DataGrid = new DataGrid();
		public var environment:String = new String();
		public var libraryId:Number = new Number();
		
		public function DownloadGrid()
		{
			super();
			this.horizontalScrollPolicy = "off";
			this.verticalScrollPolicy = "off";
		}
		
		override protected function createChildren():void {
			this.removeAllChildren();
			
			var button:Button = new Button();
			button.width = 20;
			button.height = 20;
			button.setStyle("icon", DLIcon);
			button.addEventListener(MouseEvent.CLICK, clickHandler);
			
			this.addChild(button);
			
			var label:Label = new Label();
			label.text = "QUERY_NAME";
			this.addChild(label);
		}
		
		private function clickHandler(event:MouseEvent):void {
			var gridContent:String = DataGridUtils.loadDataGridInExcel(dgAC);
			var downloadPanel:DownloadFile = DownloadFile(PopUpManager.createPopUp(DisplayObject(FlexGlobals.topLevelApplication), DownloadFile, true));
			
			var fileselector:FileSelectorEvent = new FileSelectorEvent();
			fileselector.csv = true;
			
			var generalObject:SearchDBEvent = new SearchDBEvent();
			generalObject.environment = environment; //string
			generalObject.library = libraryId; //number
			
			downloadPanel._fileSelector = fileselector.getFileSelectorObject();
			downloadPanel._searchDBObj = generalObject.getStruct();
			downloadPanel._content = gridContent;
			
			PopUpManager.bringToFront(downloadPanel);
			PopUpManager.centerPopUp(downloadPanel);
		}
	}
}