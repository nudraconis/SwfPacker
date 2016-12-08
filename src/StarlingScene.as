package 
{
	import swfdata.atlas.gl.GLTextureAtlas;
	import flash.display.Sprite;
	import flash.events.Event;
	import starling.core.Starling;
	import swfdata.SymbolsLibrary;
	
	[Event(name="complete", type="flash.events.Event")]
	public class StarlingScene extends Sprite
	{
		public function StarlingScene() 
		{
			addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
		}
		
		public function show(library:SymbolsLibrary, texture:GLTextureAtlas):void 
		{
			(Starling.current.root as AnimationViewer).show(library, texture);
		}
		
		public function clear():void {
			(Starling.current.root as AnimationViewer).clear();
		}
		
		private function onAddedToStage(e:Event):void 
		{
			removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
			
			var starling:Starling = new Starling(AnimationViewer, stage);
			starling.addEventListener("rootCreated", onStarlingReady);
			starling.start();
		}
		
		private function onStarlingReady(e:Object):void 
		{
			dispatchEvent(new Event(Event.COMPLETE));
		}
	}
}