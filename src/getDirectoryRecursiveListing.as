package {
	import flash.filesystem.File;

		public function getDirectoryRecursiveListing(file:File, extention:String = null):Array	{
			var result:Array = [];
			
			if (file.isDirectory) {
				var temp:Array = file.getDirectoryListing();
				for (var i:int = 0; i < temp.length; i++) {
					var tempFile:File = File(temp[i]);
					result = result.concat(getDirectoryRecursiveListing(tempFile, extention));
				}	 
			} else if(!extention || file.extension == extention) {
				result.push(file);	
			}
			return result;
		}

}