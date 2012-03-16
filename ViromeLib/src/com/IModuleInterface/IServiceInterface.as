package com.IModuleInterface
{
	import flash.events.IEventDispatcher;
	
	public interface IServiceInterface extends IEventDispatcher
	{
		function setEndPoint(s:String):void;
		function setCFCSource(s:String):void;
	}
}