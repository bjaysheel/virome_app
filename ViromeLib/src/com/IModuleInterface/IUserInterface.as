package com.IModuleInterface
{
	public interface IUserInterface extends IServiceInterface 
	{
		function getUserObject():Object;
		function setCookieObject(o:Object):void;
	}
}