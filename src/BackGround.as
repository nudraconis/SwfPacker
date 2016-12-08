package
{
	import flash.display.Bitmap;
	
	import starling.core.RenderSupport;
	import starling.display.Image;
	import starling.textures.Texture;
	
	public class BackGround extends Image
	{
		
		[Embed(source="back.jpg",mimeType="image/jpeg")]
		private static const Back:Class;
		private static const back:Bitmap = new Back();
		private static const tex:Texture = Texture.fromBitmap(back, false);
		
		public function BackGround()
		{
			super(tex);
		}
		
		override public function render(support:RenderSupport, parentAlpha:Number):void 
		{
			super.render(support, parentAlpha);
		}
	}
}