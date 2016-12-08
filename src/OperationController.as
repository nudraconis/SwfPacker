package 
{
	import fastByteArray.IByteArray;
	import fastByteArray.SlowByteArray;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.BlendMode;
	import flash.display.Sprite;
	import flash.display3D.Context3DTextureFormat;
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.geom.Rectangle;
	import flash.net.FileFilter;
	import flash.text.TextField;
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	import flash.utils.Timer;
	import flash.utils.setTimeout;
	
	import mx.collections.ArrayCollection;
	import mx.collections.ArrayList;
	
	import swfDataExporter.GLSwfExporter;
	
	import swfdata.atlas.BitmapSubTexture;
	import swfdata.atlas.BitmapTextureAtlas;
	import swfdata.atlas.gl.GLTextureAtlas;
	import swfdata.dataTags.SwfPackerTag;
	
	import swfparser.SwfDataParser;
	import swfparser.SwfParserLight;
	
	import util.MaxRectPacker;
	import util.PackerRectangle;
	
	[Event(name="clear", type="flash.events.Event")]
	[Event(name="complete", type="flash.events.Event")]
	public class OperationController extends Sprite 
	{
		private var fileContent:ByteArray;
		private var swfDataParser:SwfDataParser;
		private var packedAtlas:BitmapTextureAtlas;
		private var maxRectPacker:MaxRectPacker = new MaxRectPacker(2048, 2048);
		private var data:IByteArray;
		//private var data:IByteArray = new FastByteArray(null, 1024*100000);
		private var swfExporter:GLSwfExporter;
		private var swfFile:File;
		
		private var scene:StarlingScene;
		private var aniFile:File;

		private var glTextureAtlas:GLTextureAtlas;

		private var swfParserLight:SwfParserLight;
		private var swfFiles:Array;
		private var errorFiles:Array;
		private var convertedFiles:Array;
		private var _bitmapData:BitmapData;
		
		[Bindable]
		public var aniList:ArrayList;
		
		[Bindable]
		public var unlock:Boolean = true;
		
		public function OperationController() 
		{
			super();
			
			DebugCanvas.current = graphics;
			addEventListener(Event.ADDED_TO_STAGE, addedToStageHandler);
		}
		

		public function get bitmapData():BitmapData
		{
			return _bitmapData;
		}

		protected function addedToStageHandler(event:Event):void {
			scene = new StarlingScene();
			stage.addChild(scene);
			/*
				var fileName:String = "biker";
				swfFile = File.documentsDirectory.resolvePath(fileName + ".swf");
				
				var t:Timer = new Timer(1000, 1);
				t.addEventListener(TimerEvent.TIMER_COMPLETE, onStartParse);
				t.start();
			*/
		}
		
		
		public function browseAniDir():void 
		{
			clear();
			var file:File = File.documentsDirectory;
			file.browseForDirectory("Select directory with swf files");
			file.addEventListener(Event.SELECT, onSelectedAniDir);
		}
		
		protected function onSelectedAniDir(event:Event):void {
			var aniFiles:Array = getDirectoryRecursiveListing(event.currentTarget as File,"ani");
			aniList = new ArrayList();
			for (var i:int = 0; i < aniFiles.length; i++) 
			{
				var file:File = aniFiles[i];
				aniList.addItem({label: file.name, value:file});
			}
			
		}
		
		public function browseBulkSWF():void 
		{
			clear();
			var file:File = File.documentsDirectory;
			file.browseForDirectory("Select directory with swf files");
			file.addEventListener(Event.SELECT, onSelectedBulkSWF);
		}
		
		protected function onSelectedBulkSWF(event:Event):void {
			swfFiles = getDirectoryRecursiveListing(event.currentTarget as File,"swf");
			unlock = false;
			errorFiles = [];
			convertedFiles = [];
			nextConvertSWF();
		}
		
		private function nextConvertSWF():void {
			swfFile = swfFiles.pop();
			if (swfFile) {
				clear();
				try
				{
					convertSWF(swfFile, false);
					convertedFiles.push(swfFile.nativePath);
					setTimeout(nextConvertSWF, 10);
					
				} 
				catch(error:*) 
				{
					errorFiles.push(swfFile.nativePath);
					trace("ERROR parsing file", swfFile.nativePath);
					trace (error);
					setTimeout(nextConvertSWF, 10);
				}
			} else {
				unlock = true;
				trace("ERROR", errorFiles);
				trace("COMPLETED",convertedFiles);
				dispatchEvent(new Event("batchConvertComplete"));
			}
		}
		
		private function convertSWF(swfFile:File, checkAni:Boolean = true):void {
			if (!checkAni || !swfFile.parent.resolvePath(swfFile.name.replace("swf","ani")).exists){
				openAndLoadContent(swfFile);
				parseSwfData();
				packRectangles();
				rebuildAtlas();
				packData();
				saveAnimation();
			}
		}
		
		public function browseSwf():void 
		{
			clear();
			swfFile = File.documentsDirectory;
			swfFile.browseForOpen("Select animation file", [new FileFilter("swf file with animation", "*.swf", "*.swf")]);
			swfFile.addEventListener(Event.SELECT, onSelectedSWF);
		}
		
		private function onSelectedSWF(e:Event):void 
		{
			openAndLoadContent(swfFile);
			parseSwfData();
			packRectangles();
			rebuildAtlas();
			packData();
			saveAnimation();
			loadAnimation();
		}
		
		public function browseAni():void 
		{
			clear();
			aniFile = File.documentsDirectory;
			aniFile.browseForOpen("Select animation file", [new FileFilter("ani file with animation", "*.ani", "*.ani")]);
			aniFile.addEventListener(Event.SELECT, onSelectedANI);
		}
		
		private function onSelectedANI(e:Event):void 
		{
			loadAnimation();
		}
		
		
		private function packData():void 
		{
			swfExporter = new GLSwfExporter();
			
			trace("### PACKED ATLAS ###");
			trace(packedAtlas.width, packedAtlas.height);
			
			data = new SlowByteArray(null, 1024*100000);

			swfExporter.exportAnimation(packedAtlas, swfDataParser.context.shapeLibrary, swfDataParser.packerTags, data);
			swfDataParser.clear();
			//тут можно скопировать packedAtlas.data для показа в окне текстур.
			packedAtlas.data.dispose();
			packedAtlas.clear();
		}
		
		private function saveAnimation():void
		{
			aniFile = swfFile.parent.resolvePath(swfFile.name.replace("swf","ani"));
			trace("OperationController.saveAnimation()",aniFile.nativePath);
			
			var fileStream:FileStream = new FileStream();
			fileStream.open(aniFile, FileMode.WRITE);
			
			fileContent = new ByteArray();
			data.position = 0;
			data.byteArray.endian = fileContent.endian = Endian.LITTLE_ENDIAN;
			fileStream.writeBytes(data.byteArray, 0, data.length);
			fileStream.close();
			
			//data.clear();
		}
		public function showAni(file:File):void
		{
			trace("OperationController.showAni(file)", file.nativePath);
			
			clear();
			aniFile = file;
			loadAnimation();
		}
		
		private function loadAnimation(e:Event = null):void {
			if (data) {
				data.clear();
				data = null;
			}
			if (fileContent) {
				fileContent.clear();
				fileContent = null;
			}
			openAndLoadContent(aniFile);
			fileContent.position = 0;
			fileContent.endian = Endian.LITTLE_ENDIAN;
			data = new SlowByteArray(fileContent);
			unpackData();
		}
		
		private function unpackData():void 
		{
			swfExporter = new GLSwfExporter();
			swfParserLight = new SwfParserLight();
			var swfTags:Vector.<SwfPackerTag> = new Vector.<SwfPackerTag>;
			
			data.position = 0;
			
			glTextureAtlas = swfExporter.importAnimation("noname", data, swfParserLight.context.shapeLibrary, swfTags, Context3DTextureFormat.BGRA) as GLTextureAtlas;
			
			swfParserLight.context.library.addShapes(swfParserLight.context.shapeLibrary);
			swfParserLight.processDisplayObject(swfTags);					
			data.clear();
			
			scene.show(swfParserLight.context.library, glTextureAtlas);
		}
		
		private function rebuildAtlas():void 
		{
			var atlasSource:BitmapData = maxRectPacker.drawAtlas(0);

			packedAtlas = new BitmapTextureAtlas(atlasSource.width, atlasSource.height, 4);
			packedAtlas.data = atlasSource;
			
			var rects:Vector.<PackerRectangle> = maxRectPacker.atlasDatas[0].rectangles;
			
			
			for (var i:int = 0; i < rects.length; i++)
			{
				var currentRegion:PackerRectangle = rects[i];
				
				var region:Rectangle = new Rectangle();
				region.setTo(currentRegion.x, currentRegion.y, currentRegion.width, currentRegion.height);
				
				packedAtlas.createSubTexture(currentRegion.id, region, currentRegion.scaleX, currentRegion.scaleY);
			}
			_bitmapData = atlasSource.clone();
			dispatchEvent(new Event(Event.COMPLETE));
		}
		
		private function packRectangles():void 
		{
			var rectangles:Vector.<PackerRectangle> = new Vector.<PackerRectangle>;
			
			var atlas:BitmapTextureAtlas = swfDataParser.context.atlasDrawer.targetAtlas;
			//WindowUtil.openWindowToReview(atlas.atlasData, "default atlas");
			
			for(var regionName:String in atlas.subTextures)
			{
				var subTexture:BitmapSubTexture = atlas.subTextures[int(regionName)];
				var region:Rectangle = subTexture.bounds;
				var packerRect:PackerRectangle = PackerRectangle.get(0, 0, region.width + atlas.padding * 2, region.height + atlas.padding * 2, subTexture.id, atlas.data, region.x - atlas.padding, region.y - atlas.padding);
				packerRect.scaleX = subTexture.transform.scaleX;
				packerRect.scaleY = subTexture.transform.scaleY;
				
				rectangles.push(packerRect);
			}
			
			maxRectPacker.clearData();
			maxRectPacker.packRectangles(rectangles, 0, 2);		
		}
		
		private function parseSwfData():void 
		{
			swfDataParser = new SwfDataParser();
			swfDataParser.parseSwf(fileContent, false);
			fileContent.clear();
		}
		
		private function openAndLoadContent(file:File):void 
		{
			var fileStream:FileStream = new FileStream();
			fileStream.open(file, FileMode.READ);
			
			fileContent = new ByteArray();
			fileStream.readBytes(fileContent, 0, fileStream.bytesAvailable);
			fileStream.close();
		}
		
		public function clear():void {
			if (_bitmapData) {
				dispatchEvent(new Event(Event.CLEAR));
				_bitmapData.dispose();
				_bitmapData = null;
			}
			if (fileContent) {
				fileContent.clear();
				fileContent = null;
			}
			if (data) {
				data.clear();
				data = null;
			}
			if (maxRectPacker){
				maxRectPacker.clearData();
			}
			
			if (swfParserLight) {
				swfParserLight.clear(true);
				swfParserLight = null;
			}
			
			if (swfExporter){
				swfExporter = null;
			}
			
			scene.clear();

			if (glTextureAtlas) {
				glTextureAtlas.gpuData.dispose();
				glTextureAtlas.dispose();
				glTextureAtlas = null;
			}
			
		}
	}
}