package com.IModuleInterface
{
	public interface IBookmarkInterface extends IServiceInterface
	{
		function getBookmark():Object;
		function setUserId(n:Number):void;
		function addToBookmark(o:Object):void;
	}
}