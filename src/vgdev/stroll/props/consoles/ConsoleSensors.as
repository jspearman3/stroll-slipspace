package vgdev.stroll.props.consoles 
{
	import flash.display.MovieClip;
	import flash.geom.Point;
	import vgdev.stroll.ContainerGame;
	
	/**
	 * Adjusts the view
	 * @author Alexander Huynh
	 */
	public class ConsoleSensors extends ABST_Console 
	{
		
		public function ConsoleSensors(_cg:ContainerGame, _mc_object:MovieClip, _players:Array, locked:Boolean = false) 
		{
			super(_cg, _mc_object, _players, locked);
			CONSOLE_NAME = "Sensors";
			TUT_SECTOR = 4;
			TUT_TITLE = "Sensors Module";
			TUT_MSG = "Adjust the ship's sensors to get a better view of outside."
		}
		
		override protected function updateHUD(isActive:Boolean):void 
		{
			if (isActive)
				holdKey([false, false, false, false]);
		}
		
		override public function holdKey(keys:Array):void
		{
			if (hp == 0) return;
			
			if (keys[0])
				cg.camera.moveCameraFocus(new Point(-1, 0));
			if (keys[1])
				cg.camera.moveCameraFocus(new Point(0, 1));
			if (keys[2])
				cg.camera.moveCameraFocus(new Point(1, 0));
			if (keys[3])
				cg.camera.moveCameraFocus(new Point(0, -1));
		
			var hud:MovieClip = getHUD();
				
			// set UI arrows to be faded out if the camera can't move any further in that direction
			hud.mc_arrowR.gotoAndStop(cg.camera.isAtLimit(0) ? 2 : 1);
			hud.mc_arrowL.gotoAndStop(cg.camera.isAtLimit(1) ? 2 : 1);
			hud.mc_arrowD.gotoAndStop(cg.camera.isAtLimit(2) ? 2 : 1);
			hud.mc_arrowU.gotoAndStop(cg.camera.isAtLimit(3) ? 2 : 1);
			
			hud.mc_limitX.visible = cg.camera.isAtLimit(0) || cg.camera.isAtLimit(1);
			hud.mc_limitY.visible = cg.camera.isAtLimit(2) || cg.camera.isAtLimit(3);
			
			hud.tf_x.text = Math.round(-cg.camera.focusTgt.x * .25).toString();
			hud.tf_y.text = Math.round(cg.camera.focusTgt.y * .25).toString();
			
			hud.mc_markerX.x = -71 + 48 * (-cg.camera.focusTgt.x / (cg.camera.lim_x_max - cg.camera.lim_x_min));
			hud.mc_markerY.x = 74 + 48 * (cg.camera.focusTgt.y / (cg.camera.lim_y_max - cg.camera.lim_y_min));
		}
	}
}