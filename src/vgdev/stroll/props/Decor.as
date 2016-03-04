package vgdev.stroll.props 
{
	import flash.display.MovieClip;
	import vgdev.stroll.ContainerGame;
	
	/**
	 * A non-interactive decoration piece that removes itself once its animation is done
	 * @author Alexander Huynh
	 */
	public class Decor extends ABST_Object 
	{
		/* Supported labels
		 * explosion_small
		 * extinguish
		 * 
		 */
		
		public var dx:Number = 0;
		public var dy:Number = 0;
		
		public function Decor(_cg:ContainerGame, _mc_object:MovieClip = null, style:String = null)
		{
			super(_cg, _mc_object);
			mc_object.gotoAndStop(style);
		}
		
		override public function step():Boolean 
		{
			updatePosition(dx, dy);
			if (mc_object.base.currentFrame == mc_object.base.totalFrames)
				destroy();
			return completed;
		}
	}
}