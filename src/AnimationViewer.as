package 
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.geom.Matrix;
	
	import starling.AnimationRenderer;
	import starling.SWFView;
	import starling.core.Starling;
	import starling.display.DisplayObject;
	import starling.display.Image;
	import starling.display.Sprite;
	import starling.textures.Texture;
	
	import swfdata.MovieClipData;
	import swfdata.SpriteData;
	import swfdata.SymbolsLibrary;
	import swfdata.atlas.gl.GLTextureAtlas;
	
	public class AnimationViewer extends Sprite 
	{
		
		private var texture:GLTextureAtlas;
		private var library:SymbolsLibrary;
		public function AnimationViewer() 
		{
			super();
		}
		
		public function show(library:SymbolsLibrary, texture:GLTextureAtlas):void 
		{
			// тестовый бэк для проверки режимов наложения
			//addChild(new BackGround());
			
			this.texture = texture;
			this.library = library;

			var h:int = 200;
			var w:int = 100;
			var a:int = 100;
			for (var j:int = 0; j < 1; j++) 
			{
				for (var i:int = 0; i < library.spritesList.length; i++) 
				{
					var view:SWFView = new SWFView();
					view.alphaThreshold = 0.02;
					
					view.x = (i % 15 ) * w + a;
					view.y = int(i / 15) * h  + 300;
					addChild(view);
					
					var viewData:SpriteData = library.spritesList[i];
					
					var spriteAsTimeline:MovieClipData = viewData as MovieClipData;	
					
					if(spriteAsTimeline)
						spriteAsTimeline.play();
					view.show(viewData, texture);
				}
				a+=100;
			}
			
		}
		
		public function clear():void {
			removeChildren(0, -1, false);
			if (library){
				library.clear();
				library = null;
			}
			if (texture){
				texture.dispose();
				texture.gpuData.dispose();
				texture = null;
			}
		}
	}
}
